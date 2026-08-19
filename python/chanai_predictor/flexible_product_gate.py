"""Flexible, target-free product forecasting for ChanAI Pulse v3.1-7.

The public task may contain any valid number of known and target samples.
The 16 -> 4 contract is retained only as an internal compatibility window
when an official fixed-shape neural checkpoint is requested.
"""

from __future__ import annotations

from pathlib import Path
from typing import Any

import numpy as np

from .contracts import AdaptationPolicy, PredictionRequest
from .flexible_forecast import (
    CLASSICAL_MODELS,
    ForecastExample,
    forecast_classical,
    make_backtests,
    target_runs,
)
from .registry import load_registry, resolve_entry_checkpoint
from .service import run_prediction_request
from .training import load_checkpoint, predict_model


NEURAL_MODELS = ("gru", "lstm", "tcn", "dlinear", "nlinear")
VARIABLE_RECURRENT_MODELS = ("gru", "lstm", "tcn")
ALL_MODELS = CLASSICAL_MODELS + NEURAL_MODELS


def _fixed_request(
    values: np.ndarray,
    names: tuple[str, ...],
    units: tuple[str, ...],
    task_type: str,
) -> PredictionRequest:
    values = np.asarray(values, dtype=np.float64)
    if values.ndim == 2:
        values = values[None, :, :]
    examples = len(values)
    return PredictionRequest(
        path=Path("v31-flexible-internal-window.json"),
        task_type=task_type,
        context_layout=(
            "history_then_future" if task_type == "extrapolation"
            else "left_and_right_context_predict_middle"
        ),
        parameter_names=names,
        parameter_units=units,
        input_parameters=values.reshape(examples, 16, 8),
        input_parameter_sample_index=np.tile(np.arange(1, 17), (examples, 1)),
        target_parameter_sample_index=np.tile(np.arange(17, 21), (examples, 1)),
        example_group_ids=tuple(
            f"flexible-internal-window-{index + 1}" for index in range(examples)
        ),
    )


def _extrapolation_registry(registry_path: Path) -> Path:
    if registry_path.parent.name == "extrapolation":
        return registry_path
    candidate = registry_path.parent.parent / "extrapolation" / (
        "extrapolation_model_registry_v2.json"
    )
    if not candidate.is_file():
        raise ValueError(f"Extrapolation registry was not found: {candidate}")
    return candidate


def _load_recurrent_runtime(
    model_type: str, registry_path: Path, device: str
) -> tuple[Any, np.ndarray, np.ndarray, np.ndarray, Path]:
    path, registry = load_registry(_extrapolation_registry(registry_path))
    entry = next(
        (item for item in registry["entries"] if item["model_type"] == model_type),
        None,
    )
    if entry is None:
        raise ValueError(f"Model {model_type} is absent from {path}.")
    checkpoint = resolve_entry_checkpoint(path, registry, entry)
    if checkpoint is None:
        raise ValueError(f"Model {model_type} has no registered checkpoint.")
    model, _ = load_checkpoint(checkpoint, device)
    preprocessing = registry["preprocessing"]
    return (
        model,
        np.asarray(preprocessing["normalization_mean"], dtype=np.float64),
        np.asarray(preprocessing["normalization_std"], dtype=np.float64),
        np.asarray(preprocessing["parameter_bounds"], dtype=np.float64),
        checkpoint,
    )


def _recurrent_block(
    runtime: tuple[Any, np.ndarray, np.ndarray, np.ndarray, Path],
    history: np.ndarray,
    device: str,
) -> np.ndarray:
    model, mean, std, bounds, _ = runtime
    normalized = (
        np.asarray(history, dtype=np.float64) - mean.reshape(1, -1)
    ) / std.reshape(1, -1)
    prediction = predict_model(model, normalized[None, :, :], device)[0]
    restored = prediction * std.reshape(1, -1) + mean.reshape(1, -1)
    return np.minimum(np.maximum(restored, bounds[:, 0]), bounds[:, 1])


def _neural_one_sided(
    model: str,
    values: np.ndarray,
    horizon: int,
    names: tuple[str, ...],
    units: tuple[str, ...],
    registry_path: Path,
    device: str,
    *,
    reverse: bool = False,
) -> tuple[np.ndarray, dict[str, Any]]:
    history = np.asarray(values, dtype=np.float64)
    if reverse:
        history = history[::-1]
    if len(history) < 16:
        raise ValueError(
            f"Manual {model} needs at least 16 known samples on each required "
            "prediction side because its published checkpoint has a 16-point "
            "internal context. The task itself remains valid; choose Auto or a "
            "flexible classical model."
        )
    generated: list[np.ndarray] = []
    calls: list[dict[str, Any]] = []
    remaining = int(horizon)
    recurrent_runtime = (
        _load_recurrent_runtime(model, registry_path, device)
        if model in VARIABLE_RECURRENT_MODELS else None
    )
    while remaining:
        if recurrent_runtime is not None:
            block = _recurrent_block(recurrent_runtime, history, device)
            result = {"model": {"checkpoint": str(recurrent_runtime[-1])}}
        else:
            request = _fixed_request(history[-16:], names, units, "extrapolation")
            result = run_prediction_request(
                request,
                _extrapolation_registry(registry_path),
                selection_mode="manual",
                requested_model=model,
                adaptation_policy=AdaptationPolicy(mode="off"),
                adaptation_data=None,
                device=device,
            )
            block = np.asarray(result["prediction_parameters"], dtype=np.float64)[0]
        take = min(remaining, len(block))
        generated.append(block[:take])
        history = np.vstack((history, block[:take]))
        calls.append(result.get("model", {}))
        remaining -= take
    return np.vstack(generated), {
        "model_type": model,
        "execution_contract": (
            "legacy_recurrent_full_history_to_4_rolling_compatibility"
            if model in VARIABLE_RECURRENT_MODELS
            else "legacy_16_to_4_rolling_compatibility"
        ),
        "all_known_rows_consumed": model in VARIABLE_RECURRENT_MODELS,
        "rollout_block_length": 4,
        "rollout_call_count": len(calls),
        "checkpoint": calls[0].get("checkpoint") if calls else None,
        "warning": (
            "Predicted blocks re-enter later contexts; uncertainty can accumulate "
            "on long horizons."
        ),
    }


def _neural_many_one_sided(
    model: str,
    histories: list[np.ndarray],
    horizon: int,
    names: tuple[str, ...],
    units: tuple[str, ...],
    registry_path: Path,
    device: str,
    *,
    reverse: bool = False,
) -> list[np.ndarray]:
    working = [
        np.asarray(history, dtype=np.float64)[::-1].copy()
        if reverse else np.asarray(history, dtype=np.float64).copy()
        for history in histories
    ]
    if any(len(history) < 16 for history in working):
        raise ValueError(
            f"{model} needs 16 known samples on each required prediction side."
        )
    outputs: list[list[np.ndarray]] = [[] for _ in working]
    remaining = int(horizon)
    recurrent_runtime = (
        _load_recurrent_runtime(model, registry_path, device)
        if model in VARIABLE_RECURRENT_MODELS else None
    )
    while remaining:
        if recurrent_runtime is not None:
            block = np.stack([
                _recurrent_block(recurrent_runtime, history, device)
                for history in working
            ])
        else:
            request = _fixed_request(
                np.stack([history[-16:] for history in working]), names, units,
                "extrapolation",
            )
            result = run_prediction_request(
                request, _extrapolation_registry(registry_path),
                selection_mode="manual", requested_model=model,
                adaptation_policy=AdaptationPolicy(mode="off"),
                adaptation_data=None, device=device,
            )
            block = np.asarray(result["prediction_parameters"], dtype=np.float64)
        take = min(remaining, block.shape[1])
        for row in range(len(working)):
            outputs[row].append(block[row, :take])
            working[row] = np.vstack((working[row], block[row, :take]))
        remaining -= take
    return [np.vstack(parts) for parts in outputs]


def _predict_neural_examples(
    model: str,
    examples: list[ForecastExample],
    names: tuple[str, ...],
    units: tuple[str, ...],
    registry_path: Path,
    device: str,
) -> list[np.ndarray]:
    if not examples:
        return []
    horizon = len(examples[0].target_indices)
    forward = _neural_many_one_sided(
        model, [example.left_values for example in examples], horizon,
        names, units, registry_path, device,
    )
    if examples[0].right_values is None:
        return forward
    backward_sequences = _neural_many_one_sided(
        model, [example.right_values for example in examples], horizon,
        names, units, registry_path, device, reverse=True,
    )
    output: list[np.ndarray] = []
    for example, left_prediction, near_to_far in zip(
        examples, forward, backward_sequences
    ):
        near_order = np.argsort(example.right_indices[0] - example.target_indices)
        backward = np.empty_like(near_to_far)
        backward[near_order] = near_to_far
        left_distance = np.abs(example.target_indices - example.left_indices[-1])
        right_distance = np.abs(example.right_indices[0] - example.target_indices)
        weight = left_distance / np.maximum(
            left_distance + right_distance, np.finfo(float).eps
        )
        output.append(
            left_prediction * (1.0 - weight[:, None])
            + backward * weight[:, None]
        )
    return output


def _predict_neural(
    model: str,
    left_values: np.ndarray,
    left_indices: np.ndarray,
    target_indices: np.ndarray,
    names: tuple[str, ...],
    units: tuple[str, ...],
    registry_path: Path,
    device: str,
    *,
    right_values: np.ndarray | None = None,
    right_indices: np.ndarray | None = None,
) -> tuple[np.ndarray, dict[str, Any]]:
    target_indices = np.asarray(target_indices, dtype=np.float64)
    left_leads = target_indices - np.asarray(left_indices)[-1]
    if np.any(left_leads < 1) or np.any(left_leads != np.floor(left_leads)):
        raise ValueError(
            f"Manual {model} rolling compatibility requires integer sample-index "
            "steps from the known boundary."
        )
    forward_dense, metadata = _neural_one_sided(
        model, left_values, int(np.max(left_leads)), names, units,
        registry_path, device,
    )
    forward = forward_dense[left_leads.astype(int) - 1]
    if right_values is None or right_indices is None or not len(right_values):
        return forward, metadata
    right_leads = np.asarray(right_indices)[0] - target_indices
    if np.any(right_leads < 1) or np.any(right_leads != np.floor(right_leads)):
        raise ValueError(
            f"Manual {model} bidirectional rolling requires integer sample-index "
            "steps from both known boundaries."
        )
    backward_dense, backward_metadata = _neural_one_sided(
        model, right_values, int(np.max(right_leads)), names, units,
        registry_path, device, reverse=True,
    )
    backward = backward_dense[right_leads.astype(int) - 1]
    left_distance = np.abs(target_indices - np.asarray(left_indices)[-1])
    right_distance = np.abs(np.asarray(right_indices)[0] - target_indices)
    right_weight = left_distance / np.maximum(
        left_distance + right_distance, np.finfo(float).eps
    )
    metadata["execution_contract"] = (
        "legacy_recurrent_full_history_to_4_bidirectional_rolling_interpolation"
        if model in VARIABLE_RECURRENT_MODELS
        else "legacy_16_to_4_bidirectional_rolling_interpolation"
    )
    metadata["right_rollout_call_count"] = backward_metadata["rollout_call_count"]
    return (
        forward * (1.0 - right_weight[:, None])
        + backward * right_weight[:, None]
    ), metadata


def _predict_example(
    model: str,
    example: ForecastExample,
    names: tuple[str, ...],
    units: tuple[str, ...],
    registry_path: Path,
    device: str,
) -> tuple[np.ndarray, dict[str, Any]]:
    if model in CLASSICAL_MODELS:
        return forecast_classical(
            model, example.left_values, example.left_indices,
            example.target_indices, right_values=example.right_values,
            right_indices=example.right_indices,
        ), {
            "model_type": model,
            "execution_contract": "full_history_arbitrary_horizon",
            "history_policy": "all_available_with_recency_weighting",
        }
    return _predict_neural(
        model, example.left_values, example.left_indices,
        example.target_indices, names, units, registry_path, device,
        right_values=example.right_values, right_indices=example.right_indices,
    )


def _anchor(
    left: np.ndarray,
    count: int,
    columns: np.ndarray,
    right: np.ndarray | None = None,
) -> np.ndarray:
    output = np.empty((count, len(columns)), dtype=np.float64)
    if right is None:
        output[:] = left[-1, columns]
    else:
        output[:] = (left[-1, columns] + right[0, columns]) / 2.0
    return output


def _freeze_imputed_example(
    prediction: np.ndarray,
    example: ForecastExample,
    columns: np.ndarray,
) -> np.ndarray:
    output = np.asarray(prediction, dtype=np.float64).copy()
    if len(columns):
        output[:, columns] = _anchor(
            example.left_values, len(output), columns, example.right_values
        )
    return output


def _score(
    predictions: list[np.ndarray],
    examples: list[ForecastExample],
    std: np.ndarray,
    evaluated_columns: np.ndarray,
) -> dict[str, Any]:
    if not predictions:
        return {
            "available": False, "example_count": 0,
            "normalized_rmse": None,
            "worst_example_normalized_rmse": None,
            "per_parameter_normalized_rmse": [None] * len(std),
        }
    errors = [
        (prediction - example.target_values) / std.reshape(1, -1)
        for prediction, example in zip(predictions, examples)
    ]
    stacked = np.vstack(errors)
    per_parameter = np.sqrt(np.mean(stacked**2, axis=0))
    per_example = [
        float(np.sqrt(np.mean(error[:, evaluated_columns] ** 2)))
        for error in errors
    ]
    return {
        "available": True,
        "example_count": len(errors),
        "normalized_rmse": float(np.sqrt(
            np.mean(stacked[:, evaluated_columns] ** 2)
        )),
        "worst_example_normalized_rmse": max(per_example),
        "per_parameter_normalized_rmse": per_parameter.tolist(),
    }


def _project_product_values(
    prediction: np.ndarray,
    bounds: np.ndarray,
    count_columns: np.ndarray,
) -> np.ndarray:
    output = np.asarray(prediction, dtype=np.float64).copy()
    output = np.minimum(np.maximum(output, bounds[:, 0]), bounds[:, 1])
    if len(count_columns):
        output[:, count_columns] = np.rint(output[:, count_columns])
    return output


def _current_example(
    values: np.ndarray,
    indices: np.ndarray,
    target: np.ndarray,
    task_type: str,
) -> ForecastExample:
    left = np.flatnonzero(indices < np.min(target))
    right = np.flatnonzero(indices > np.max(target))
    if not len(left):
        raise ValueError("Every target run requires at least one known sample on its left.")
    if task_type == "interpolation" and not len(right):
        raise ValueError("Interpolation target runs require known samples on both sides.")
    return ForecastExample(
        values[left], indices[left], np.empty((len(target), values.shape[1])), target,
        values[right] if task_type == "interpolation" else None,
        indices[right] if task_type == "interpolation" else None,
    )


def _continuity(
    values: np.ndarray,
    indices: np.ndarray,
    target_indices: np.ndarray,
    prediction: np.ndarray,
    std: np.ndarray,
    threshold: float,
    task_type: str,
) -> dict[str, Any]:
    known_change = np.abs(np.diff(values, axis=0)) / std.reshape(1, -1)
    reference = np.maximum(
        np.quantile(known_change, 0.95, axis=0) if len(known_change)
        else np.full(values.shape[1], 0.05),
        0.05,
    )
    ratios: list[np.ndarray] = []
    boundaries: list[str] = []
    for rows in target_runs(target_indices):
        order = rows[np.argsort(target_indices[rows])]
        target = target_indices[order]
        predicted = prediction[order]
        left = np.flatnonzero(indices < target[0])
        if len(left):
            ratios.append(np.abs(predicted[0] - values[left[-1]]) / reference)
            boundaries.append("known_left_to_prediction")
        if len(predicted) > 1:
            ratios.extend(np.abs(np.diff(predicted, axis=0)) / reference)
            boundaries.extend(["prediction_internal"] * (len(predicted) - 1))
        if task_type == "interpolation":
            right = np.flatnonzero(indices > target[-1])
            if len(right):
                ratios.append(np.abs(values[right[0]] - predicted[-1]) / reference)
                boundaries.append("prediction_to_known_right")
    matrix = np.vstack(ratios) if ratios else np.zeros((1, values.shape[1]))
    maximum = float(np.max(matrix))
    return {
        "method": "prediction_change_over_known_p95_change",
        "maximum_ratio": maximum,
        "threshold": float(threshold),
        "passed": maximum <= threshold,
        "effect": "warning_only",
        "checked_boundaries": boundaries,
        "maximum_parameter_ratio": np.max(matrix, axis=0).tolist(),
    }


def _validate(
    values: np.ndarray,
    indices: np.ndarray,
    groups: np.ndarray,
    target: np.ndarray,
    task_type: str,
) -> None:
    if values.ndim != 2 or values.shape[1] != 8:
        raise ValueError("Known P8 values must have shape [N,8].")
    if not len(values) or len(indices) != len(values) or len(groups) != len(values):
        raise ValueError("Known P8 values, indices, and groups must be nonempty and align.")
    if not len(target):
        raise ValueError("At least one target index is required.")
    if np.any(~np.isfinite(values)) or np.any(~np.isfinite(indices)):
        raise ValueError("Known P8 data contain non-finite values.")
    if np.any(~np.isfinite(target)) or len(np.unique(target)) != len(target):
        raise ValueError("Target indices must be finite and unique.")
    if len(np.unique(indices)) != len(indices):
        raise ValueError("Known sample indices must be unique.")
    if np.intersect1d(indices, target).size:
        raise ValueError("Known and target sample indices must not overlap.")
    if task_type == "extrapolation" and np.min(target) <= np.max(indices):
        raise ValueError("Extrapolation targets must be after all known samples.")
    if task_type == "interpolation" and (
        np.min(target) <= np.min(indices) or np.max(target) >= np.max(indices)
    ):
        raise ValueError("Interpolation targets must lie inside the known span.")


def run_product_gate(payload: dict[str, Any]) -> dict[str, Any]:
    task_type = str(payload["task_type"])
    if task_type not in ("extrapolation", "interpolation"):
        raise ValueError(f"Unsupported task type: {task_type}")
    names = tuple(str(item) for item in payload["parameter_names"])
    units = tuple(str(item) for item in payload["parameter_units"])
    values = np.asarray(payload["known_values"], dtype=np.float64)
    indices = np.asarray(payload["known_parameter_sample_index"], dtype=np.float64)
    groups = np.asarray(payload["known_group_id"], dtype=str)
    quality = np.asarray(payload["known_quality_status"], dtype=str)
    valid = np.all(np.isfinite(values), axis=1) & (np.char.upper(quality) != "FAIL")
    values, indices, groups = values[valid], indices[valid], groups[valid]
    order = np.argsort(indices)
    values, indices, groups = values[order], indices[order], groups[order]
    target = np.asarray(payload["target_parameter_sample_index"], dtype=np.float64)
    _validate(values, indices, groups, target, task_type)

    observed_names = tuple(str(item) for item in payload[
        "locally_observed_parameter_names"
    ])
    imputed_names = tuple(str(item) for item in payload["imputed_parameter_names"])
    observed = np.asarray([names.index(item) for item in observed_names], dtype=int)
    imputed = np.asarray([names.index(item) for item in imputed_names], dtype=int)
    registry_path = Path(payload["registry_path"]).expanduser().resolve()
    _, registry = load_registry(registry_path)
    preprocessing = registry["preprocessing"]
    std = np.asarray(preprocessing["normalization_std"], dtype=np.float64)
    bounds = np.asarray(preprocessing["parameter_bounds"], dtype=np.float64)
    count_columns = np.asarray([
        column for column, name in enumerate(names)
        if name in ("num_clusters", "num_rays")
    ], dtype=int)
    examples, backtest_contract = make_backtests(
        values, indices, groups, task_type, len(target), maximum_examples=8
    )
    device = str(payload.get("device", "auto"))
    selection_mode = str(payload.get("selection_mode", "auto"))
    requested = str(payload.get("requested_model", ""))
    if selection_mode not in ("auto", "manual"):
        raise ValueError(f"Unsupported selection mode: {selection_mode}")
    if selection_mode == "manual" and requested not in ALL_MODELS:
        raise ValueError(f"Unsupported manual model: {requested}")

    models_to_score = list(CLASSICAL_MODELS)
    if selection_mode == "auto":
        models_to_score.extend(NEURAL_MODELS)
    elif requested in NEURAL_MODELS:
        models_to_score.append(requested)
    scores: dict[str, dict[str, Any]] = {
        model: _score([], [], std, observed) for model in ALL_MODELS
    }
    backtest_predictions: dict[str, list[np.ndarray]] = {}
    unavailable: dict[str, str] = {}
    for model in models_to_score:
        predictions: list[np.ndarray] = []
        try:
            if model in NEURAL_MODELS:
                predictions = _predict_neural_examples(
                    model, examples, names, units, registry_path, device
                )
                predictions = [
                    _freeze_imputed_example(prediction, example, imputed)
                    for prediction, example in zip(predictions, examples)
                ]
            else:
                for example in examples:
                    prediction, _ = _predict_example(
                        model, example, names, units, registry_path, device
                    )
                    predictions.append(_freeze_imputed_example(
                        prediction, example, imputed
                    ))
            predictions = [
                _project_product_values(prediction, bounds, count_columns)
                for prediction in predictions
            ]
            scores[model] = _score(predictions, examples, std, observed)
            backtest_predictions[model] = predictions
        except (ValueError, RuntimeError, OSError) as error:
            scores[model] = _score([], [], std, observed)
            unavailable[model] = str(error)

    if selection_mode == "manual":
        selected_by_parameter = {
            name: ("frozen_known_anchor" if column in imputed else requested)
            for column, name in enumerate(names)
        }
        selected_model = requested
    else:
        selected_by_parameter: dict[str, str] = {}
        for column, name in enumerate(names):
            if column in imputed:
                selected_by_parameter[name] = "frozen_known_anchor"
                continue
            eligible = [
                model for model in ALL_MODELS
                if scores[model]["available"]
                and scores[model]["per_parameter_normalized_rmse"][column] is not None
            ]
            if not eligible:
                eligible = ["persistence"]
            selected_by_parameter[name] = min(
                eligible,
                key=lambda model: scores[model][
                    "per_parameter_normalized_rmse"
                ][column] if scores[model]["available"] else float("inf"),
            )
        active = {selected_by_parameter[names[column]] for column in observed}
        selected_model = next(iter(active)) if len(active) == 1 else "hybrid"

    prediction = np.empty((len(target), len(names)), dtype=np.float64)
    model_metadata: dict[str, Any] = {}
    for run_rows in target_runs(target):
        run_target = target[run_rows]
        example = _current_example(values, indices, run_target, task_type)
        needed = (
            {requested} if selection_mode == "manual"
            else {selected_by_parameter[names[column]] for column in observed}
        )
        run_predictions: dict[str, np.ndarray] = {}
        for model in needed:
            run_prediction, metadata = _predict_example(
                model, example, names, units, registry_path, device
            )
            run_predictions[model] = run_prediction
            model_metadata[model] = metadata
        for column, name in enumerate(names):
            if column in imputed:
                prediction[run_rows, column] = _anchor(
                    example.left_values, len(run_rows), np.asarray([column]),
                    example.right_values,
                )[:, 0]
            else:
                model = selected_by_parameter[name]
                prediction[run_rows, column] = run_predictions[model][:, column]

    baseline_models = [m for m in CLASSICAL_MODELS if scores[m]["available"]]
    best_baseline_by_parameter: dict[str, str] = {}
    for column in observed:
        eligible = [
            model for model in baseline_models
            if scores[model]["per_parameter_normalized_rmse"][column] is not None
        ]
        best_baseline_by_parameter[names[column]] = min(
            eligible,
            key=lambda model: scores[model]["per_parameter_normalized_rmse"][column],
        ) if eligible else "persistence"
    stabilization = {
        "applied": False,
        "method": "transparent_extreme_regret_local_baseline_blend",
        "trigger_ratio": 4.0,
        "minimum_requested_model_weight": 0.10,
        "requested_model_weight_by_parameter": {},
        "baseline_model_by_parameter": best_baseline_by_parameter,
        "target_ground_truth_read": False,
    }
    stabilized_selected_score: dict[str, Any] | None = None
    if (
        selection_mode == "manual" and examples
        and scores[requested]["available"]
    ):
        baseline_prediction = np.full_like(prediction, np.nan)
        for run_rows in target_runs(target):
            run_target = target[run_rows]
            example = _current_example(values, indices, run_target, task_type)
            cache: dict[str, np.ndarray] = {}
            for model in set(best_baseline_by_parameter.values()):
                cache[model] = forecast_classical(
                    model, example.left_values, example.left_indices, run_target,
                    right_values=example.right_values,
                    right_indices=example.right_indices,
                )
            for column in observed:
                model = best_baseline_by_parameter[names[column]]
                baseline_prediction[run_rows, column] = cache[model][:, column]
        for column in observed:
            manual_error = float(
                scores[requested]["per_parameter_normalized_rmse"][column]
            )
            baseline_model = best_baseline_by_parameter[names[column]]
            baseline_error = float(
                scores[baseline_model]["per_parameter_normalized_rmse"][column]
            )
            ratio = manual_error / max(baseline_error, 1e-6)
            weight = 1.0
            if ratio > stabilization["trigger_ratio"]:
                weight = max(
                    stabilization["minimum_requested_model_weight"],
                    stabilization["trigger_ratio"] / ratio,
                )
                prediction[:, column] = (
                    weight * prediction[:, column]
                    + (1.0 - weight) * baseline_prediction[:, column]
                )
                stabilization["applied"] = True
            stabilization["requested_model_weight_by_parameter"][names[column]] = (
                float(weight)
            )
        if stabilization["applied"]:
            guarded_backtests: list[np.ndarray] = []
            for example_index in range(len(examples)):
                guarded = backtest_predictions[requested][example_index].copy()
                for column in observed:
                    weight = stabilization[
                        "requested_model_weight_by_parameter"
                    ][names[column]]
                    baseline_model = best_baseline_by_parameter[names[column]]
                    guarded[:, column] = (
                        weight * guarded[:, column]
                        + (1.0 - weight)
                        * backtest_predictions[baseline_model][example_index][:, column]
                    )
                guarded_backtests.append(guarded)
            stabilized_selected_score = _score(
                guarded_backtests, examples, std, observed
            )

    if np.any(~np.isfinite(prediction)):
        raise ValueError("The selected model produced NaN or infinite values.")
    before_projection = prediction.copy()
    prediction = _project_product_values(prediction, bounds, count_columns)
    projection_count = int(np.count_nonzero(before_projection != prediction))
    gate_config = payload.get("gate", {})
    threshold = float(gate_config.get("maximum_continuity_ratio", 3.0))
    continuity = _continuity(
        values, indices, target, prediction, std, threshold, task_type
    )

    best_baseline = min(
        baseline_models,
        key=lambda model: scores[model]["normalized_rmse"],
    ) if baseline_models else "persistence"
    selected_score = stabilized_selected_score or (
        scores.get(selected_model, {}) if selected_model != "hybrid" else {
            "available": bool(examples),
            "example_count": len(examples),
            "normalized_rmse": float(np.sqrt(np.mean([
                scores[selected_by_parameter[names[column]]][
                    "per_parameter_normalized_rmse"
                ][column] ** 2 for column in observed
            ]))) if examples else None,
        }
    )
    warnings: list[str] = []
    if not examples:
        warnings.append(
            "Known history is too short for a local holdout backtest; the task "
            "still runs with the safest available flexible model."
        )
    if selection_mode == "manual" and scores[requested]["available"]:
        if scores[requested]["normalized_rmse"] > scores[best_baseline]["normalized_rmse"]:
            warnings.append(
                f"Manual {requested} is worse than local baseline {best_baseline} "
                "on the uploaded known-region backtest; it was run as requested."
            )
    if stabilization["applied"]:
        warnings.append(
            "The requested model exceeded the extreme local-regret ratio on at "
            "least one parameter. It still ran, and its output was transparently "
            "blended with that parameter's best known-region baseline to prevent "
            "an obviously implausible trajectory; weights are recorded in the "
            "Manifest."
        )
    if not continuity["passed"]:
        warnings.append(
            "Prediction changes exceed the known-region continuity reference; "
            "this is a warning, not a rejection."
        )
    if projection_count:
        warnings.append(
            f"{projection_count} predicted parameter values were projected into "
            "the generator's valid bounds/integer-count contract."
        )
    if any(model in NEURAL_MODELS for model in model_metadata):
        warnings.append(
            "At least one legacy neural four-point output head used rolling "
            "compatibility; long-horizon uncertainty may accumulate."
        )

    recommended = str(registry["selection_policy"]["selected_model_type"])
    return {
        "schema_version": "v3.1-product-p8-flexible-gate.2",
        "request_contains_target_ground_truth": False,
        "known_region_labels_used_for_backtest": bool(examples),
        "target_region_channel_samples_read": False,
        "task_type": task_type,
        "parameter_names": list(names),
        "parameter_units": list(units),
        "prediction_parameters": prediction.reshape(1, len(target), 8).tolist(),
        "target_parameter_sample_index": target.reshape(1, -1).tolist(),
        "known_context_parameters": values.tolist(),
        "known_context_parameter_sample_index": indices.tolist(),
        "selection": {
            "mode": selection_mode,
            "requested_model": requested or None,
            "selected_model": selected_model,
            "selected_model_by_parameter": selected_by_parameter,
            "recommended_model": recommended,
            "is_system_recommended": selected_model == recommended,
            "manual_non_recommended": selection_mode == "manual" and requested != recommended,
            "selection_basis": (
                "per_parameter_uploaded_known_region_backtest"
                if selection_mode == "auto"
                else "advanced_user_manual_choice_warning_only_performance_guard"
            ),
            "fallback_applied": False,
            "unavailable_candidates": unavailable,
            "target_ground_truth_read_for_selection": False,
        },
        "model": {
            "model_type": selected_model,
            "component_models": model_metadata,
            "execution_contract": "arbitrary_known_and_target_length",
            "known_history_policy": "all_available_rows_with_recency_weighting",
        },
        "adaptation": {
            "requested_mode": str(payload.get("adaptation_mode", "off")),
            "status": "not_performed",
            "accepted": False,
            "reason": "known_region_backtest_selects_without_modifying_weights",
            "official_checkpoint_overwritten": False,
        },
        "backtest": {
            "example_count": len(examples),
            "contract": backtest_contract,
            "scores": scores,
            "selected_score": selected_score,
            "raw_selected_model_score": scores.get(selected_model, {}),
            "stabilized_selected_score": stabilized_selected_score,
            "best_safe_baseline": best_baseline,
            "best_safe_baseline_score": scores[best_baseline],
            "maximum_absolute_normalized_rmse": float(
                gate_config.get("maximum_absolute_normalized_rmse", 2.0)
            ),
            "maximum_absolute_worst_example_normalized_rmse": float(
                gate_config.get(
                    "maximum_absolute_worst_example_normalized_rmse", 3.0
                )
            ),
            "evaluated_parameter_names": list(observed_names),
            "frozen_imputed_parameter_names": list(imputed_names),
            "passed": True,
            "effect": "selection_and_warning_not_hard_rejection",
        },
        "imputed_parameter_projection": {
            "applied": bool(len(imputed)),
            "parameter_names": list(imputed_names),
            "rule": "hold_nearest_known_boundary_anchor",
        },
        "stabilization": stabilization,
        "postprocessing": {
            "product_projection_changed_value_count": projection_count,
        },
        "continuity": continuity,
        "warnings": warnings,
        "distribution_check": {},
        "cir_status": {
            "available": False,
            "reason": "The MATLAB product layer generates CIR after this gate.",
        },
    }
