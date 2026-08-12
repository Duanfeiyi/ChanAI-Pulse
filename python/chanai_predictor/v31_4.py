"""Leakage-safe v3.1-4 model study on the frozen P8 route corpus."""

from __future__ import annotations

import hashlib
import json
import platform
import subprocess
import sys
from dataclasses import asdict, dataclass, replace
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

import numpy as np
import torch

from .contracts import PredictorData, TrainingConfig
from .data import load_predictor_data_hdf5
from .models import BASELINE_PREDICTORS, ar_predict, kalman_predict
from .training import load_checkpoint, metric_bundle, predict_model, train_model


STUDY_SCHEMA = "v3.1-4-model-study.1"
MODEL_TYPES = ("gru", "lstm", "tcn", "dlinear", "nlinear")
BASELINE_TYPES = ("persistence", "linear", "ar", "kalman")
DEFAULT_SEEDS = (31401, 31402, 31403)
DEFAULT_SENSITIVITY_WEIGHTS = (
    0.8469573954643916,
    0.4749541908056322,
    0.4635136126948468,
    0.2803567405448548,
    0.3918137948670611,
    0.2784303768385839,
    0.6698246643175313,
    0.3061787532827122,
)


@dataclass(frozen=True)
class AdmissionRules:
    minimum_relative_improvement: float = 0.10
    minimum_route_win_rate: float = 0.60
    maximum_route_to_baseline_ratio: float = 2.0
    maximum_seed_relative_std: float = 0.10


def _sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def _utc_now() -> str:
    return datetime.now(timezone.utc).isoformat()


def _git_state(repository: Path) -> dict[str, Any]:
    def run(*arguments: str) -> str:
        return subprocess.check_output(
            ["git", "-C", str(repository), *arguments], text=True
        ).strip()

    try:
        revision = run("rev-parse", "HEAD")
        dirty = bool(run("status", "--porcelain"))
    except (OSError, subprocess.CalledProcessError):
        revision, dirty = "unknown", "unknown"
    return {"revision": revision, "dirty": dirty}


def _target_coordinates(data: PredictorData) -> tuple[np.ndarray, np.ndarray]:
    context = data.context_length
    if data.task_type == "extrapolation":
        known = np.arange(context, dtype=np.float64)
        target = context + np.arange(data.target_length, dtype=np.float64)
    else:
        left = context // 2
        known = np.concatenate(
            (
                np.arange(left, dtype=np.float64),
                left + data.target_length + np.arange(context - left, dtype=np.float64),
            )
        )
        target = left + np.arange(data.target_length, dtype=np.float64)
    return known, target


def route_nrmse(
    data: PredictorData, prediction: np.ndarray, indices: np.ndarray
) -> dict[str, float]:
    groups = np.asarray(data.example_group_ids, dtype=str)[indices]
    result: dict[str, float] = {}
    for group in sorted(set(groups.tolist())):
        positions = np.flatnonzero(groups == group)
        result[group] = float(
            metric_bundle(data, prediction[positions], indices[positions])["normalized_rmse"]
        )
    return result


def evaluate_prediction(
    data: PredictorData, prediction: np.ndarray, partition: str
) -> dict[str, Any]:
    indices = data.partition_indices(partition)
    return {
        "metrics": metric_bundle(data, prediction, indices),
        "route_nrmse": route_nrmse(data, prediction, indices),
    }


def _baseline_entries(data: PredictorData, partition: str) -> list[dict[str, Any]]:
    indices = data.partition_indices(partition)
    entries = []
    for name, predictor in BASELINE_PREDICTORS.items():
        prediction = predictor(data, data.inputs[indices])
        entries.append({"model_type": name, **evaluate_prediction(data, prediction, partition)})
    return entries


def _candidate_configs(model_type: str, device: str, seed: int) -> tuple[TrainingConfig, ...]:
    max_epochs = 30 if model_type == "tcn" else 60
    patience = 5 if model_type == "tcn" else 8
    training_device = "cpu" if model_type == "tcn" else device
    common = dict(
        model_type=model_type,
        seed=seed,
        device=training_device,
        max_epochs=max_epochs,
        patience=patience,
        batch_size=128,
    )
    if model_type in ("gru", "lstm"):
        return (
            TrainingConfig(**common, hidden_size=32, num_layers=1, learning_rate=1e-3),
            TrainingConfig(
                **common,
                hidden_size=64,
                num_layers=2,
                dropout=0.1,
                learning_rate=5e-4,
            ),
        )
    if model_type == "tcn":
        return (
            TrainingConfig(**common, tcn_channels=32, kernel_size=3, learning_rate=1e-3),
            TrainingConfig(**common, tcn_channels=64, kernel_size=5, learning_rate=5e-4),
        )
    return (
        TrainingConfig(**common, learning_rate=1e-3),
        TrainingConfig(**common, learning_rate=5e-4, weight_decay=1e-5),
    )


def _config_id(config: TrainingConfig) -> str:
    payload = json.dumps(config.to_dict(), sort_keys=True, separators=(",", ":"))
    return hashlib.sha256(payload.encode()).hexdigest()[:12]


def _train_and_measure(
    data: PredictorData,
    config: TrainingConfig,
    output: Path,
    partition: str = "validation",
) -> dict[str, Any]:
    checkpoint, manifest_path, manifest = train_model(
        data, config, output, evaluate_test=False
    )
    model, _ = load_checkpoint(checkpoint, device=config.device)
    indices = data.partition_indices(partition)
    prediction = predict_model(model, data.inputs[indices], config.device)
    measured = evaluate_prediction(data, prediction, partition)
    return {
        "seed": config.seed,
        "config": config.to_dict(),
        "checkpoint": str(checkpoint),
        "checkpoint_sha256": _sha256(checkpoint),
        "manifest": str(manifest_path),
        "training": {
            "best_epoch": manifest["training"]["best_epoch"],
            "epochs_completed": manifest["training"]["epochs_completed"],
            "elapsed_seconds": manifest["training"]["elapsed_seconds"],
        },
        **measured,
    }


def _aggregate_runs(
    model_type: str,
    runs: list[dict[str, Any]],
    baseline: dict[str, Any],
    rules: AdmissionRules,
) -> dict[str, Any]:
    scores = np.asarray([run["metrics"]["normalized_rmse"] for run in runs])
    groups = sorted(runs[0]["route_nrmse"])
    group_mean = {
        group: float(np.mean([run["route_nrmse"][group] for run in runs]))
        for group in groups
    }
    ratios = {
        group: value / max(1e-12, baseline["route_nrmse"][group])
        for group, value in group_mean.items()
    }
    mean_score = float(np.mean(scores))
    std_score = float(np.std(scores))
    improvement = 1 - mean_score / max(
        1e-12, baseline["metrics"]["normalized_rmse"]
    )
    relative_std = std_score / max(1e-12, mean_score)
    qualification = {
        "baseline_model_type": baseline["model_type"],
        "relative_validation_nrmse_improvement": improvement,
        "validation_route_win_rate": float(np.mean([ratio < 1 for ratio in ratios.values()])),
        "maximum_route_to_baseline_ratio": float(max(ratios.values())),
        "seed_relative_std": relative_std,
    }
    qualification["passed_parameter_gate"] = bool(
        improvement >= rules.minimum_relative_improvement
        and qualification["validation_route_win_rate"] >= rules.minimum_route_win_rate
        and qualification["maximum_route_to_baseline_ratio"]
        <= rules.maximum_route_to_baseline_ratio
        and relative_std <= rules.maximum_seed_relative_std
    )
    best = min(runs, key=lambda run: run["metrics"]["normalized_rmse"])
    return {
        "model_type": model_type,
        "validation_normalized_rmse_mean": mean_score,
        "validation_normalized_rmse_std": std_score,
        "validation_route_nrmse_mean": group_mean,
        "qualification": qualification,
        "runs": runs,
        "selected_seed": best["seed"],
        "selected_checkpoint": best["checkpoint"],
        "selected_checkpoint_sha256": best["checkpoint_sha256"],
    }


def _write_generator_pairs(
    data: PredictorData,
    prediction: np.ndarray,
    indices: np.ndarray,
    output: Path,
    partition: str,
) -> Path:
    import csv

    output.mkdir(parents=True, exist_ok=True)
    raw_truth = data.denormalize(data.targets[indices])
    raw_prediction = data.denormalize(prediction)
    for name in ("num_clusters", "num_rays"):
        column = data.parameter_names.index(name)
        raw_truth[:, :, column] = np.rint(raw_truth[:, :, column])
        raw_prediction[:, :, column] = np.rint(raw_prediction[:, :, column])
    path = output / f"{data.task_type}_step11abc_{partition}_generator_pairs.csv"
    fields = ["partition", "example_index", "group_id", "target_step"]
    fields += [f"truth_{name}" for name in data.parameter_names]
    fields += [f"predicted_{name}" for name in data.parameter_names]
    with path.open("x", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=fields)
        writer.writeheader()
        groups = np.asarray(data.example_group_ids, dtype=str)[indices]
        target_steps = data.target_parameter_sample_index[indices]
        for local, original in enumerate(indices):
            for offset in range(data.target_length):
                row: dict[str, Any] = {
                    "partition": partition,
                    "example_index": int(original),
                    "group_id": groups[local],
                    "target_step": int(target_steps[local, offset]),
                }
                for column, name in enumerate(data.parameter_names):
                    row[f"truth_{name}"] = float(raw_truth[local, offset, column])
                    row[f"predicted_{name}"] = float(raw_prediction[local, offset, column])
                writer.writerow(row)
    return path


def _selected_prediction(
    data: PredictorData,
    selected: dict[str, Any],
    partition: str,
    device: str,
) -> np.ndarray:
    indices = data.partition_indices(partition)
    model_type = selected["model_type"]
    if model_type in BASELINE_PREDICTORS:
        return BASELINE_PREDICTORS[model_type](data, data.inputs[indices])
    checkpoint = Path(selected["selected_checkpoint"]).expanduser().resolve()
    expected_sha256 = selected.get("selected_checkpoint_sha256")
    if not expected_sha256:
        raise ValueError("The frozen neural selection is missing its checkpoint SHA-256.")
    if _sha256(checkpoint) != expected_sha256:
        raise ValueError("The frozen neural checkpoint SHA-256 does not match.")
    model, _ = load_checkpoint(checkpoint, device=device)
    return predict_model(model, data.inputs[indices], device)


def run_study(
    data_directory: str | Path,
    output_directory: str | Path,
    repository: str | Path,
    *,
    device: str = "auto",
    seeds: tuple[int, ...] = DEFAULT_SEEDS,
    sensitivity_loss_weights: tuple[float, ...] = DEFAULT_SENSITIVITY_WEIGHTS,
    rules: AdmissionRules = AdmissionRules(),
) -> tuple[Path, dict[str, Any]]:
    """Tune on validation and freeze finalists without opening test truth."""
    if len(seeds) < 3:
        raise ValueError("The formal v3.1-4 study requires at least three seeds.")
    data_directory = Path(data_directory).expanduser().resolve()
    output_directory = Path(output_directory).expanduser().resolve()
    repository = Path(repository).expanduser().resolve()
    if output_directory.exists():
        raise FileExistsError(f"Refusing to overwrite experiment: {output_directory}")
    output_directory.mkdir(parents=True)
    tasks: dict[str, Any] = {}
    for task in ("interpolation", "extrapolation"):
        data_path = data_directory / f"step11abc_{task}_p8.h5"
        data = load_predictor_data_hdf5(data_path)
        validation_baselines = _baseline_entries(data, "validation")
        best_baseline = min(
            validation_baselines,
            key=lambda entry: entry["metrics"]["normalized_rmse"],
        )
        aggregates = []
        for model_type in MODEL_TYPES:
            search_runs = []
            for candidate in _candidate_configs(model_type, device, seeds[0]):
                run_root = output_directory / task / "search" / model_type / _config_id(candidate)
                search_runs.append(_train_and_measure(data, candidate, run_root))
            best_search = min(
                search_runs, key=lambda run: run["metrics"]["normalized_rmse"]
            )
            locked = dict(best_search["config"])
            locked["loss_weights"] = tuple(locked.get("loss_weights", ()))
            formal_runs = [best_search]
            for seed in seeds[1:]:
                config = replace(TrainingConfig(**locked), seed=int(seed))
                run_root = output_directory / task / "formal" / model_type / f"seed{seed}"
                formal_runs.append(_train_and_measure(data, config, run_root))
            aggregate = _aggregate_runs(
                model_type, formal_runs, best_baseline, rules
            )
            aggregate["search_runs"] = search_runs
            aggregate["locked_config"] = best_search["config"]
            aggregates.append(aggregate)
        qualified = [
            item for item in aggregates if item["qualification"]["passed_parameter_gate"]
        ]
        if qualified:
            selected = min(
                qualified, key=lambda item: item["validation_normalized_rmse_mean"]
            )
            reason = "best_candidate_passing_parameter_admission_gate"
        else:
            selected = {
                "model_type": best_baseline["model_type"],
                "selected_checkpoint": None,
                "qualification": {"passed_parameter_gate": True},
            }
            reason = "safe_baseline_fallback_no_trainable_candidate_passed"
        ablation_base = min(
            aggregates, key=lambda item: item["validation_normalized_rmse_mean"]
        )
        ablation_config_values = dict(ablation_base["locked_config"])
        ablation_config_values["loss_weights"] = tuple(sensitivity_loss_weights)
        ablation_config = TrainingConfig(**ablation_config_values)
        ablation_run = _train_and_measure(
            data,
            ablation_config,
            output_directory / task / "ablation" / "sensitivity_weighted",
        )
        tasks[task] = {
            "dataset": {"file": data_path.name, "sha256": _sha256(data_path)},
            "validation_baselines": validation_baselines,
            "best_validation_baseline": best_baseline["model_type"],
            "candidate_aggregates": aggregates,
            "sensitivity_weighted_ablation": {
                "model_type": ablation_base["model_type"],
                "weights_source": "v3.1-3 Full 6GPCM sensitivity evidence .4",
                "selection_effect": "none_report_only",
                "run": ablation_run,
            },
            "selection": {
                "model_type": selected["model_type"],
                "reason": reason,
                "selected_checkpoint": selected.get("selected_checkpoint"),
                "full_6gpcm_validation_gate": "pending",
            },
        }
    frozen_at = _utc_now()
    for task, task_result in tasks.items():
        data = load_predictor_data_hdf5(
            data_directory / f"step11abc_{task}_p8.h5"
        )
        selected = next(
            (
                item
                for item in task_result["candidate_aggregates"]
                if item["model_type"] == task_result["selection"]["model_type"]
            ),
            task_result["selection"],
        )
        validation_indices = data.partition_indices("validation")
        validation_prediction = _selected_prediction(data, selected, "validation", device)
        pair_root = output_directory / "generator_gate" / f"step11abc_{task}_p8"
        pair_path = _write_generator_pairs(
            data, validation_prediction, validation_indices, pair_root, "validation"
        )
        registry = {
            "schema_version": "v3.1-4-validation-model-selection.1",
            "selection_policy": {
                "selection_partition": "validation",
                "test_partition_used": False,
                "selected_model_type": task_result["selection"]["model_type"],
            },
        }
        registry_path = pair_root / f"{task}_step11abc_registry.json"
        registry_path.write_text(json.dumps(registry, indent=2), encoding="utf-8")
        task_result["selection"]["validation_pair_file"] = str(pair_path)
        task_result["selection"]["validation_pair_sha256"] = _sha256(pair_path)
    manifest = {
        "schema_version": STUDY_SCHEMA,
        "created_utc": _utc_now(),
        "selection_frozen_utc": frozen_at,
        "test_partition_use": "not_opened_requires_successful_full_6gpcm_gate",
        "experiment_config": {
            "models": list(MODEL_TYPES),
            "baselines": list(BASELINE_TYPES),
            "seeds": list(seeds),
            "main_loss_weights": "equal_after_train_only_zscore_normalization",
            "sensitivity_ablation_weights": list(sensitivity_loss_weights),
            "admission_rules": asdict(rules),
            "parameter_bundle": "P8",
            "context_to_target": "16_to_4",
        },
        "runtime": {
            "python": sys.version.split()[0],
            "numpy": np.__version__,
            "torch": str(torch.__version__),
            "cuda_available": torch.cuda.is_available(),
            "cuda_device": torch.cuda.get_device_name(0) if torch.cuda.is_available() else None,
            "platform": platform.platform(),
        },
        "code": _git_state(repository),
        "tasks": tasks,
        "full_6gpcm_core_modified": False,
        "full_6gpcm_validation_gate": "requires_matlab_gate_command",
    }
    path = output_directory / "v31_4_model_study_manifest.json"
    path.write_text(json.dumps(manifest, indent=2, ensure_ascii=False), encoding="utf-8")
    return path, manifest


def finalize_test_once(
    study_manifest: str | Path,
    gate_manifest: str | Path,
    data_directory: str | Path,
    *,
    device: str = "auto",
) -> tuple[Path, dict[str, Any]]:
    """Open test once after the frozen selection passes the Full 6GPCM gate."""
    study_path = Path(study_manifest).expanduser().resolve()
    gate_path = Path(gate_manifest).expanduser().resolve()
    data_directory = Path(data_directory).expanduser().resolve()
    output_path = study_path.parent / "v31_4_test_once_results.json"
    if output_path.exists():
        raise FileExistsError(f"Refusing to reopen test: {output_path}")
    study = json.loads(study_path.read_text(encoding="utf-8"))
    gate = json.loads(gate_path.read_text(encoding="utf-8"))
    if study_path.parent not in gate_path.parents:
        raise ValueError("The Full 6GPCM gate does not belong to this experiment.")
    if study.get("schema_version") != STUDY_SCHEMA:
        raise ValueError("Unsupported v3.1-4 study manifest.")
    if gate.get("schema_version") != "v3.1-4-full-6gpcm-validation-gate.1":
        raise ValueError("Unsupported Full 6GPCM validation-gate manifest.")
    if gate.get("evaluation_partition") != "validation" or gate.get(
        "test_partition_used"
    ):
        raise ValueError("The Full 6GPCM gate is not validation-only.")
    if gate.get("full_6gpcm_core_modified"):
        raise ValueError("The Full 6GPCM gate reports a modified core.")
    if not gate.get("passed"):
        raise ValueError("The Full 6GPCM validation gate did not pass.")
    if gate.get("study_manifest_sha256") != _sha256(study_path):
        raise ValueError("The Full 6GPCM gate is not bound to this frozen study manifest.")
    if gate.get("full_6gpcm_tree_sha256_before") != gate.get(
        "full_6gpcm_tree_sha256_after"
    ):
        raise ValueError("The Full 6GPCM tree hash changed during the gate.")
    opened_utc = _utc_now()
    task_results: dict[str, Any] = {}
    for task, task_result in study["tasks"].items():
        data_path = data_directory / f"step11abc_{task}_p8.h5"
        dataset = task_result.get("dataset", {})
        if dataset.get("file") != data_path.name or not dataset.get("sha256"):
            raise ValueError(f"The frozen {task} dataset identity is incomplete.")
        if _sha256(data_path) != dataset["sha256"]:
            raise ValueError(f"The frozen {task} dataset SHA-256 does not match.")
        data = load_predictor_data_hdf5(data_path)
        selected = next(
            (
                item
                for item in task_result["candidate_aggregates"]
                if item["model_type"] == task_result["selection"]["model_type"]
            ),
            task_result["selection"],
        )
        prediction = _selected_prediction(data, selected, "test", device)
        task_results[task] = evaluate_prediction(data, prediction, "test")
        task_results[task]["selected_model_type"] = task_result["selection"][
            "model_type"
        ]
    result = {
        "schema_version": "v3.1-4-test-once-results.1",
        "created_utc": opened_utc,
        "selection_manifest": str(study_path),
        "selection_manifest_sha256": _sha256(study_path),
        "full_6gpcm_gate_manifest": str(gate_path),
        "full_6gpcm_gate_manifest_sha256": _sha256(gate_path),
        "test_truth_used_for_selection": False,
        "selection_changed_after_test": False,
        "tasks": task_results,
    }
    output_path.write_text(json.dumps(result, indent=2, ensure_ascii=False), encoding="utf-8")
    return output_path, result


def load_p8_pair(data_directory: str | Path) -> tuple[PredictorData, PredictorData]:
    root = Path(data_directory).expanduser().resolve()
    return (
        load_predictor_data_hdf5(root / "step11abc_interpolation_p8.h5"),
        load_predictor_data_hdf5(root / "step11abc_extrapolation_p8.h5"),
    )
