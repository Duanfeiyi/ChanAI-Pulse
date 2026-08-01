"""Step 11B multi-seed benchmark and conservative automatic selection.

This module deliberately leaves the Step 10 registry untouched.  It adds a
review-oriented registry which can fall back to a simple baseline when no
neural candidate passes the pre-agreed group-level safeguards.
"""

from __future__ import annotations

import hashlib
import json
import csv
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Callable

import numpy as np

from .contracts import SUPPORTED_NEURAL_MODELS, PredictorData, TrainingConfig
from .models import linear_predict, persistence_predict
from .registry import compatibility_signature
from .training import (
    evaluate_baseline,
    load_checkpoint,
    metric_bundle,
    predict_model,
    train_model,
)


STEP11ABC_REGISTRY_SCHEMA = "v3.0-step11abc-model-registry.1"
P8_PARAMETER_NAMES = (
    "DS_mu", "KF_mu", "DS_sigma", "KF_sigma", "r_DS", "LNS_ksi",
    "num_clusters", "num_rays",
)
P8_GENERATION_DEFAULTS = np.asarray(
    [-7.925, -0.39, 0.060, 2.4, 2.8, 3.0, 12.0, 20.0], dtype=np.float64
)


def _group_metrics(
    data: PredictorData, prediction: np.ndarray, indices: np.ndarray
) -> dict[str, float]:
    """Return one normalized RMSE for each independent route group."""
    result: dict[str, float] = {}
    group_ids = np.asarray(data.example_group_ids, dtype=object)
    for group in sorted(set(group_ids[indices].tolist())):
        local = indices[group_ids[indices] == group]
        # Prediction rows match INDICES order, not absolute row number.
        positions = np.flatnonzero(group_ids[indices] == group)
        result[str(group)] = float(
            metric_bundle(data, prediction[positions], local)["normalized_rmse"]
        )
    return result


def _baseline_entry(
    data: PredictorData, model_type: str, predictor: Callable[..., np.ndarray]
) -> dict[str, Any]:
    validation = data.partition_indices("validation")
    test = data.partition_indices("test")
    validation_prediction = predictor(data, data.inputs[validation])
    test_prediction = predictor(data, data.inputs[test])
    return {
        "model_type": model_type,
        "kind": "baseline",
        "checkpoint": None,
        "manifest": None,
        "compatibility": compatibility_signature(data),
        "validation_metrics": metric_bundle(data, validation_prediction, validation),
        "test_metrics": metric_bundle(data, test_prediction, test),
        "validation_group_nrmse": _group_metrics(data, validation_prediction, validation),
        "test_group_nrmse": _group_metrics(data, test_prediction, test),
    }


def _aggregate_neural(entries: list[dict[str, Any]]) -> dict[str, Any]:
    validation_scores = np.asarray(
        [entry["validation_metrics"]["normalized_rmse"] for entry in entries],
        dtype=np.float64,
    )
    test_scores = np.asarray(
        [entry["test_metrics"]["normalized_rmse"] for entry in entries],
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
        "test_normalized_rmse_mean": float(np.mean(test_scores)),
        "test_normalized_rmse_std": float(np.std(test_scores, ddof=0)),
        "validation_group_nrmse_mean": group_mean,
    }


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
    """Train GRU/LSTM/TCN across seeds and freeze a conservative choice."""
    if len(seeds) < 3:
        raise ValueError("Step 11ABC requires at least three random seeds.")
    output_directory = Path(output_directory).expanduser().resolve()
    output_directory.mkdir(parents=True, exist_ok=True)
    neural_runs: dict[str, list[dict[str, Any]]] = {
        model_type: [] for model_type in SUPPORTED_NEURAL_MODELS
    }
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
            )
            validation = data.partition_indices("validation")
            test = data.partition_indices("test")
            model, _ = load_checkpoint(checkpoint, device=device)
            validation_prediction = predict_model(model, data.inputs[validation], device)
            test_prediction = predict_model(model, data.inputs[test], device)
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
                    "test_metrics": manifest["metrics"]["test"],
                    "validation_group_nrmse": _group_metrics(
                        data, validation_prediction, validation
                    ),
                    "test_group_nrmse": _group_metrics(data, test_prediction, test),
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
        improvement = 1.0 - aggregate["validation_normalized_rmse_mean"] / max(1e-12, baseline_score)
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

    evaluation_prediction: np.ndarray
    test_indices = data.partition_indices("test")
    if selected["kind"] == "baseline":
        predictor = persistence_predict if selected["model_type"] == "persistence" else linear_predict
        evaluation_prediction = predictor(data, data.inputs[test_indices])
    else:
        checkpoint = output_directory / selected["selected_checkpoint"]
        model, _ = load_checkpoint(checkpoint, device=device)
        evaluation_prediction = predict_model(model, data.inputs[test_indices], device)
    prediction_file = output_directory / f"{data.task_type}_step11abc_test_evaluation.npz"
    np.savez_compressed(
        prediction_file,
        prediction_normalized=evaluation_prediction,
        target_normalized=data.targets[test_indices],
        target_raw=data.denormalize(data.targets[test_indices]),
        prediction_raw=data.denormalize(evaluation_prediction),
        example_group_id=np.asarray(data.example_group_ids, dtype=str)[test_indices],
        target_parameter_sample_index=data.target_parameter_sample_index[test_indices],
        parameter_names=np.asarray(data.parameter_names, dtype=str),
    )
    pair_file = None
    if reference_p8_data is not None:
        pair_file = write_end_to_end_pairs(
            data, reference_p8_data, test_indices, evaluation_prediction, output_directory
        )
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
            "end_to_end_bundle_choice": "pending_step11c",
        },
        "acceptance_rules": {
            "seed_count": len(seeds),
            "minimum_relative_nrmse_improvement": minimum_relative_improvement,
            "minimum_validation_group_win_rate": minimum_group_win_rate,
            "maximum_group_to_baseline_ratio": maximum_group_to_baseline_ratio,
        },
        "baseline_entries": baseline_entries,
        "neural_aggregates": aggregates,
        "selected": selected,
        "evaluation_prediction_file": prediction_file.name,
        "end_to_end_pair_file": None if pair_file is None else pair_file.name,
    }
    registry_path = output_directory / f"{data.task_type}_step11abc_registry.json"
    registry_path.write_text(json.dumps(registry, indent=2, ensure_ascii=False), encoding="utf-8")
    return registry_path, registry


def write_end_to_end_pairs(
    data: PredictorData,
    reference_p8_data: PredictorData,
    test_indices: np.ndarray,
    prediction_normalized: np.ndarray,
    output_directory: Path,
) -> Path:
    """Export small, transparent generator inputs for MATLAB Full-6GPCM review.

    Test truth is included only in this *offline evaluation artifact*.  The
    generated columns use predictions for the currently trained bundle and
    calibrated defaults for all other P8 fields; the product request path
    never reads these truth columns.
    """
    if tuple(reference_p8_data.parameter_names) != P8_PARAMETER_NAMES:
        raise ValueError("The reference data must use the canonical P8 parameter order.")
    reference_indices = reference_p8_data.partition_indices("test")
    if not np.array_equal(
        data.target_parameter_sample_index[test_indices],
        reference_p8_data.target_parameter_sample_index[reference_indices]
    ):
        raise ValueError("P-bundle and P8 test rows do not align by target sample index.")
    if np.asarray(data.example_group_ids, dtype=str)[test_indices].tolist() != np.asarray(
        reference_p8_data.example_group_ids, dtype=str
    )[reference_indices].tolist():
        raise ValueError("P-bundle and P8 test rows do not align by group.")
    predicted = data.denormalize(prediction_normalized)
    truth = reference_p8_data.denormalize(reference_p8_data.targets[reference_indices])
    generated = np.repeat(P8_GENERATION_DEFAULTS.reshape(1, 1, -1), len(test_indices), axis=0)
    generated = np.repeat(generated, data.target_length, axis=1)
    for column, name in enumerate(data.parameter_names):
        generated[:, :, P8_PARAMETER_NAMES.index(name)] = predicted[:, :, column]
    path = output_directory / f"{data.task_type}_step11abc_full_generator_pairs.csv"
    fieldnames = ["example_index", "group_id", "target_step"]
    fieldnames += [f"truth_{name}" for name in P8_PARAMETER_NAMES]
    fieldnames += [f"generated_{name}" for name in P8_PARAMETER_NAMES]
    with path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=fieldnames)
        writer.writeheader()
        for local_example, (group, target_steps) in enumerate(
            zip(
                np.asarray(data.example_group_ids, dtype=str)[test_indices],
                data.target_parameter_sample_index[test_indices],
                strict=True,
            )
        ):
            for target_step in range(data.target_length):
                row: dict[str, Any] = {
                    "example_index": int(test_indices[local_example]),
                    "group_id": str(group),
                    "target_step": int(target_steps[target_step]),
                }
                row.update(
                    {
                        f"truth_{name}": float(truth[local_example, target_step, column])
                        for column, name in enumerate(P8_PARAMETER_NAMES)
                    }
                )
                row.update(
                    {
                        f"generated_{name}": float(generated[local_example, target_step, column])
                        for column, name in enumerate(P8_PARAMETER_NAMES)
                    }
                )
                writer.writerow(row)
    return path
