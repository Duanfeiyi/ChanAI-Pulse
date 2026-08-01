"""Step 11ABC model benchmarking and leakage-safe bundle finalization.

Model and bundle choices are made from validation routes only.  Test routes
are exported only after the P-bundle choice has been frozen by MATLAB's
Full-6GPCM validation stage.
"""

from __future__ import annotations

import csv
import hashlib
import json
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Callable

import numpy as np

from .contracts import SUPPORTED_NEURAL_MODELS, PredictorData, TrainingConfig
from .data import load_predictor_data_hdf5
from .models import linear_predict, persistence_predict
from .registry import compatibility_signature
from .training import load_checkpoint, metric_bundle, predict_model, train_model


STEP11ABC_REGISTRY_SCHEMA = "v3.0-step11abc-model-registry.2"
STEP11ABC_TEST_EXPORT_SCHEMA = "v3.0-step11abc-test-export.1"
P8_PARAMETER_NAMES = (
    "DS_mu", "KF_mu", "DS_sigma", "KF_sigma", "r_DS", "LNS_ksi",
    "num_clusters", "num_rays",
)


def _group_metrics(
    data: PredictorData, prediction: np.ndarray, indices: np.ndarray
) -> dict[str, float]:
    """Return one normalized RMSE for each independent route group."""
    result: dict[str, float] = {}
    group_ids = np.asarray(data.example_group_ids, dtype=object)
    for group in sorted(set(group_ids[indices].tolist())):
        positions = np.flatnonzero(group_ids[indices] == group)
        local = indices[positions]
        result[str(group)] = float(
            metric_bundle(data, prediction[positions], local)["normalized_rmse"]
        )
    return result


def _baseline_entry(
    data: PredictorData, model_type: str, predictor: Callable[..., np.ndarray]
) -> dict[str, Any]:
    validation = data.partition_indices("validation")
    prediction = predictor(data, data.inputs[validation])
    return {
        "model_type": model_type,
        "kind": "baseline",
        "checkpoint": None,
        "manifest": None,
        "compatibility": compatibility_signature(data),
        "validation_metrics": metric_bundle(data, prediction, validation),
        "validation_group_nrmse": _group_metrics(data, prediction, validation),
    }


def _aggregate_neural(entries: list[dict[str, Any]]) -> dict[str, Any]:
    validation_scores = np.asarray(
        [entry["validation_metrics"]["normalized_rmse"] for entry in entries],
        dtype=np.float64,
    )
    groups = sorted(
        set().union(*(set(entry["validation_group_nrmse"]) for entry in entries))
    )
    group_mean = {
        group: float(np.mean([entry["validation_group_nrmse"][group] for entry in entries]))
        for group in groups
    }
    best_seed_entry = min(
        entries, key=lambda item: item["validation_metrics"]["normalized_rmse"]
    )
    return {
        "model_type": entries[0]["model_type"],
        "kind": "neural_aggregate",
        "seed_runs": entries,
        "best_seed": int(best_seed_entry["seed"]),
        "selected_checkpoint": best_seed_entry["checkpoint"],
        "selected_manifest": best_seed_entry["manifest"],
        "compatibility": entries[0]["compatibility"],
        "validation_normalized_rmse_mean": float(np.mean(validation_scores)),
        "validation_normalized_rmse_std": float(np.std(validation_scores, ddof=0)),
        "validation_group_nrmse_mean": group_mean,
    }


def _predict_registry_choice(
    data: PredictorData,
    registry: dict[str, Any],
    output_directory: Path,
    partition: str,
    device: str,
) -> tuple[np.ndarray, np.ndarray]:
    indices = data.partition_indices(partition)
    selected = registry["selected"]
    if selected["kind"] == "baseline":
        predictors = {"persistence": persistence_predict, "linear": linear_predict}
        prediction = predictors[selected["model_type"]](data, data.inputs[indices])
    else:
        checkpoint = output_directory / selected["selected_checkpoint"]
        model, _ = load_checkpoint(checkpoint, device=device)
        prediction = predict_model(model, data.inputs[indices], device)
    return indices, prediction


def benchmark_model_family(
    data: PredictorData,
    output_directory: str | Path,
    *,
    seeds: tuple[int, ...] = (11011, 11012, 11013),
    max_epochs: int = 50,
    patience: int = 8,
    device: str = "auto",
    minimum_relative_improvement: float = 0.10,
    minimum_group_win_rate: float = 0.60,
    maximum_group_to_baseline_ratio: float = 2.0,
    reference_p8_data: PredictorData | None = None,
) -> tuple[Path, dict[str, Any]]:
    """Train candidates and freeze one model using validation routes only."""
    if len(seeds) < 3:
        raise ValueError("Step 11ABC requires at least three random seeds.")
    output_directory = Path(output_directory).expanduser().resolve()
    output_directory.mkdir(parents=True, exist_ok=True)
    neural_runs: dict[str, list[dict[str, Any]]] = {
        model_type: [] for model_type in SUPPORTED_NEURAL_MODELS
    }
    validation = data.partition_indices("validation")
    for model_type in SUPPORTED_NEURAL_MODELS:
        for seed in seeds:
            checkpoint, manifest_path, manifest = train_model(
                data,
                TrainingConfig(
                    model_type=model_type,
                    seed=int(seed),
                    batch_size=64,
                    max_epochs=max_epochs,
                    patience=patience,
                    device=device,
                ),
                output_directory,
                evaluate_test=False,
            )
            model, _ = load_checkpoint(checkpoint, device=device)
            prediction = predict_model(model, data.inputs[validation], device)
            neural_runs[model_type].append(
                {
                    "model_type": model_type,
                    "kind": "neural_seed_run",
                    "seed": int(seed),
                    "checkpoint": checkpoint.name,
                    "manifest": manifest_path.name,
                    "checkpoint_sha256": hashlib.sha256(checkpoint.read_bytes()).hexdigest(),
                    "compatibility": compatibility_signature(data),
                    "validation_metrics": manifest["metrics"]["validation"],
                    "validation_group_nrmse": _group_metrics(
                        data, prediction, validation
                    ),
                }
            )
    baseline_entries = [
        _baseline_entry(data, "persistence", persistence_predict),
        _baseline_entry(data, "linear", linear_predict),
    ]
    baseline = min(
        baseline_entries, key=lambda item: item["validation_metrics"]["normalized_rmse"]
    )
    aggregates = [_aggregate_neural(neural_runs[name]) for name in SUPPORTED_NEURAL_MODELS]
    qualified: list[dict[str, Any]] = []
    baseline_score = baseline["validation_metrics"]["normalized_rmse"]
    for aggregate in aggregates:
        group_scores = aggregate["validation_group_nrmse_mean"]
        ratios = {
            group: score / max(1e-12, baseline["validation_group_nrmse"][group])
            for group, score in group_scores.items()
        }
        win_rate = float(np.mean([ratio < 1.0 for ratio in ratios.values()]))
        improvement = (
            1.0
            - aggregate["validation_normalized_rmse_mean"] / max(1e-12, baseline_score)
        )
        aggregate["qualification"] = {
            "baseline_model_type": baseline["model_type"],
            "relative_validation_nrmse_improvement": float(improvement),
            "validation_group_win_rate": win_rate,
            "maximum_group_to_baseline_ratio": float(max(ratios.values())),
            "passed": bool(
                improvement >= minimum_relative_improvement
                and win_rate >= minimum_group_win_rate
                and max(ratios.values()) <= maximum_group_to_baseline_ratio
            ),
        }
        if aggregate["qualification"]["passed"]:
            qualified.append(aggregate)
    if qualified:
        selected = min(qualified, key=lambda item: item["validation_normalized_rmse_mean"])
        selection_reason = "qualified_neural_model"
    else:
        selected = baseline
        selection_reason = "baseline_fallback_no_neural_candidate_passed_all_safeguards"

    registry = {
        "schema_version": STEP11ABC_REGISTRY_SCHEMA,
        "created_utc": datetime.now(timezone.utc).isoformat(),
        "compatibility": compatibility_signature(data),
        "selection_policy": {
            "ordinary_user": "auto_uses_offline_validated_smallest_eligible_bundle",
            "advanced_user": "manual_can_choose_compatible_gru_lstm_or_tcn",
            "selected_model_type": selected["model_type"],
            "selection_reason": selection_reason,
            "targets_read_at_prediction_time": False,
            "selection_partition": "validation",
            "test_partition_used": False,
            "end_to_end_bundle_choice": "resolved_by_system_registry_after_validation",
        },
        "acceptance_rules": {
            "seed_count": len(seeds),
            "minimum_relative_nrmse_improvement": minimum_relative_improvement,
            "minimum_validation_group_win_rate": minimum_group_win_rate,
            "maximum_group_to_baseline_ratio": maximum_group_to_baseline_ratio,
        },
        "prediction_projection": {
            "bounded_by_dataset_contract": True,
            "integer_parameters": ["num_clusters", "num_rays"],
            "integer_policy": "round_to_nearest_after_denormalization",
        },
        "baseline_entries": baseline_entries,
        "neural_aggregates": aggregates,
        "selected": selected,
    }
    validation_indices, validation_prediction = _predict_registry_choice(
        data, registry, output_directory, "validation", device
    )
    prediction_file = output_directory / f"{data.task_type}_step11abc_validation_evaluation.npz"
    np.savez_compressed(
        prediction_file,
        prediction_normalized=validation_prediction,
        target_normalized=data.targets[validation_indices],
        target_raw=data.denormalize(data.targets[validation_indices]),
        prediction_raw=data.denormalize(validation_prediction),
        example_group_id=np.asarray(data.example_group_ids, dtype=str)[validation_indices],
        target_parameter_sample_index=data.target_parameter_sample_index[validation_indices],
        parameter_names=np.asarray(data.parameter_names, dtype=str),
        partition="validation",
    )
    pair_file = None
    if reference_p8_data is not None:
        pair_file = write_end_to_end_pairs(
            data,
            reference_p8_data,
            validation_indices,
            validation_prediction,
            output_directory,
            partition="validation",
        )
    registry["validation_prediction_file"] = prediction_file.name
    registry["validation_end_to_end_pair_file"] = (
        None if pair_file is None else pair_file.name
    )
    registry_path = output_directory / f"{data.task_type}_step11abc_registry.json"
    registry_path.write_text(json.dumps(registry, indent=2, ensure_ascii=False), encoding="utf-8")
    return registry_path, registry


def write_end_to_end_pairs(
    data: PredictorData,
    reference_p8_data: PredictorData,
    indices: np.ndarray,
    prediction_normalized: np.ndarray,
    output_directory: Path,
    *,
    partition: str,
) -> Path:
    """Export predicted columns only; MATLAB resolves every missing source."""
    if partition not in {"validation", "test"}:
        raise ValueError("End-to-end pairs support validation or test only.")
    if tuple(reference_p8_data.parameter_names) != P8_PARAMETER_NAMES:
        raise ValueError("The reference data must use the canonical P8 parameter order.")
    reference_indices = reference_p8_data.partition_indices(partition)
    if not np.array_equal(
        data.target_parameter_sample_index[indices],
        reference_p8_data.target_parameter_sample_index[reference_indices],
    ):
        raise ValueError("P-bundle and P8 rows do not align by target sample index.")
    if np.asarray(data.example_group_ids, dtype=str)[indices].tolist() != np.asarray(
        reference_p8_data.example_group_ids, dtype=str
    )[reference_indices].tolist():
        raise ValueError("P-bundle and P8 rows do not align by group.")
    predicted = data.denormalize(prediction_normalized)
    truth = reference_p8_data.denormalize(reference_p8_data.targets[reference_indices])
    for name in ("num_clusters", "num_rays"):
        truth[:, :, P8_PARAMETER_NAMES.index(name)] = np.rint(
            truth[:, :, P8_PARAMETER_NAMES.index(name)]
        )
        if name in data.parameter_names:
            predicted[:, :, data.parameter_names.index(name)] = np.rint(
                predicted[:, :, data.parameter_names.index(name)]
            )
    path = output_directory / f"{data.task_type}_step11abc_{partition}_generator_pairs.csv"
    fieldnames = ["partition", "example_index", "group_id", "target_step"]
    fieldnames += [f"truth_{name}" for name in P8_PARAMETER_NAMES]
    fieldnames += [f"predicted_{name}" for name in data.parameter_names]
    with path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=fieldnames)
        writer.writeheader()
        for local_example, (group, target_steps) in enumerate(
            zip(
                np.asarray(data.example_group_ids, dtype=str)[indices],
                data.target_parameter_sample_index[indices],
                strict=True,
            )
        ):
            for target_offset in range(data.target_length):
                row: dict[str, Any] = {
                    "partition": partition,
                    "example_index": int(indices[local_example]),
                    "group_id": str(group),
                    "target_step": int(target_steps[target_offset]),
                }
                row.update(
                    {
                        f"truth_{name}": float(truth[local_example, target_offset, column])
                        for column, name in enumerate(P8_PARAMETER_NAMES)
                    }
                )
                row.update(
                    {
                        f"predicted_{name}": float(predicted[local_example, target_offset, column])
                        for column, name in enumerate(data.parameter_names)
                    }
                )
                writer.writerow(row)
    return path


def export_frozen_selection_test_pairs(
    data_directory: str | Path,
    benchmark_root: str | Path,
    selection_manifest: str | Path,
    *,
    device: str = "auto",
) -> tuple[Path, dict[str, Any]]:
    """Read a frozen validation decision and export test pairs for it only."""
    data_directory = Path(data_directory).expanduser().resolve()
    benchmark_root = Path(benchmark_root).expanduser().resolve()
    selection_path = Path(selection_manifest).expanduser().resolve()
    selection = json.loads(selection_path.read_text(encoding="utf-8"))
    exports: list[dict[str, Any]] = []
    for task in ("interpolation", "extrapolation"):
        decision = selection["decisions"][task]
        bundle = str(decision["selected_bundle"]).lower()
        data_path = data_directory / f"step11abc_{task}_{bundle}.h5"
        reference_path = data_directory / f"step11abc_{task}_p8.h5"
        output_directory = benchmark_root / data_path.stem
        registry_path = output_directory / f"{task}_step11abc_registry.json"
        data = load_predictor_data_hdf5(data_path)
        reference = load_predictor_data_hdf5(reference_path)
        registry = json.loads(registry_path.read_text(encoding="utf-8"))
        if registry["schema_version"] != STEP11ABC_REGISTRY_SCHEMA:
            raise ValueError(f"Unsupported Step 11ABC registry: {registry_path}")
        indices, prediction = _predict_registry_choice(
            data, registry, output_directory, "test", device
        )
        pair_path = write_end_to_end_pairs(
            data,
            reference,
            indices,
            prediction,
            output_directory,
            partition="test",
        )
        exports.append(
            {
                "task_type": task,
                "selected_bundle": bundle.upper(),
                "model_type": registry["selection_policy"]["selected_model_type"],
                "registry": str(registry_path),
                "registry_sha256": hashlib.sha256(registry_path.read_bytes()).hexdigest(),
                "test_pair_file": str(pair_path),
                "test_pair_sha256": hashlib.sha256(pair_path.read_bytes()).hexdigest(),
                "test_group_count": len(
                    set(np.asarray(data.example_group_ids, dtype=str)[indices].tolist())
                ),
            }
        )
    manifest = {
        "schema_version": STEP11ABC_TEST_EXPORT_SCHEMA,
        "created_utc": datetime.now(timezone.utc).isoformat(),
        "frozen_selection_manifest": str(selection_path),
        "frozen_selection_sha256": hashlib.sha256(selection_path.read_bytes()).hexdigest(),
        "test_truth_used_for_selection": False,
        "exports": exports,
    }
    output_path = benchmark_root / "step11abc_test_export_manifest.json"
    output_path.write_text(json.dumps(manifest, indent=2, ensure_ascii=False), encoding="utf-8")
    return output_path, manifest


def refresh_existing_validation_pairs(
    data_directory: str | Path,
    benchmark_root: str | Path,
    *,
    device: str = "auto",
) -> list[Path]:
    """Regenerate validation pair CSVs from already frozen model registries."""
    data_directory = Path(data_directory).expanduser().resolve()
    benchmark_root = Path(benchmark_root).expanduser().resolve()
    outputs: list[Path] = []
    for data_path in sorted(data_directory.glob("step11abc_*.h5")):
        data = load_predictor_data_hdf5(data_path)
        reference = load_predictor_data_hdf5(
            data_directory / f"step11abc_{data.task_type}_p8.h5"
        )
        output_directory = benchmark_root / data_path.stem
        registry_path = output_directory / f"{data.task_type}_step11abc_registry.json"
        registry = json.loads(registry_path.read_text(encoding="utf-8"))
        if registry["schema_version"] != STEP11ABC_REGISTRY_SCHEMA:
            raise ValueError(f"Unsupported Step 11ABC registry: {registry_path}")
        indices, prediction = _predict_registry_choice(
            data, registry, output_directory, "validation", device
        )
        outputs.append(
            write_end_to_end_pairs(
                data,
                reference,
                indices,
                prediction,
                output_directory,
                partition="validation",
            )
        )
    return outputs
