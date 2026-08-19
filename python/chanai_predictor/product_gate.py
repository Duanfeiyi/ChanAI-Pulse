"""Public entry point for the flexible v3.1 product gate.

The small underscore helpers remain only for regression comparisons with the
discarded fixed-window gate. Product execution is implemented by
``flexible_product_gate.run_product_gate``.
"""

from __future__ import annotations

from typing import Any

import numpy as np

from .flexible_product_gate import run_product_gate


def _contiguous_runs(indices: np.ndarray, groups: np.ndarray) -> list[np.ndarray]:
    runs: list[np.ndarray] = []
    start = 0
    for index in range(1, len(indices) + 1):
        boundary = index == len(indices)
        if not boundary:
            boundary = (
                groups[index] != groups[index - 1]
                or indices[index] != indices[index - 1] + 1
            )
        if boundary:
            runs.append(np.arange(start, index, dtype=np.int64))
            start = index
    return runs


def _backtest_examples(
    values: np.ndarray,
    indices: np.ndarray,
    groups: np.ndarray,
    task_type: str,
) -> tuple[np.ndarray, np.ndarray, np.ndarray, np.ndarray]:
    """Build historical 16-to-4 examples for legacy regression evidence."""
    inputs: list[np.ndarray] = []
    targets: list[np.ndarray] = []
    input_indices: list[np.ndarray] = []
    target_indices: list[np.ndarray] = []
    for run in _contiguous_runs(indices, groups):
        if len(run) < 20:
            continue
        for start in range(len(run) - 19):
            span = run[start : start + 20]
            if task_type == "extrapolation":
                input_rows = span[:16]
                target_rows = span[16:]
            else:
                input_rows = np.concatenate((span[:8], span[12:]))
                target_rows = span[8:12]
            inputs.append(values[input_rows])
            targets.append(values[target_rows])
            input_indices.append(indices[input_rows])
            target_indices.append(indices[target_rows])
    if not inputs:
        return (
            np.empty((0, 16, values.shape[1])),
            np.empty((0, 4, values.shape[1])),
            np.empty((0, 16)),
            np.empty((0, 4)),
        )
    return tuple(np.asarray(item) for item in (
        inputs, targets, input_indices, target_indices
    ))


def _score(
    prediction: np.ndarray,
    truth: np.ndarray,
    std: np.ndarray,
    evaluated_columns: np.ndarray,
) -> dict[str, Any]:
    error = (prediction - truth) / std.reshape(1, 1, -1)
    evaluated_error = error[:, :, evaluated_columns]
    per_example = np.sqrt(np.mean(evaluated_error**2, axis=(1, 2)))
    per_parameter = np.sqrt(np.mean(error**2, axis=(0, 1)))
    return {
        "normalized_rmse": float(np.sqrt(np.mean(evaluated_error**2))),
        "worst_example_normalized_rmse": float(np.max(per_example)),
        "per_parameter_normalized_rmse": per_parameter.tolist(),
        "example_count": int(len(per_example)),
    }


def _freeze_imputed(
    prediction: np.ndarray,
    inputs: np.ndarray,
    task_type: str,
    imputed_columns: np.ndarray,
) -> np.ndarray:
    output = np.asarray(prediction, dtype=np.float64).copy()
    if not len(imputed_columns):
        return output
    if task_type == "extrapolation":
        anchor = inputs[:, -1:, imputed_columns]
    else:
        anchor = (
            inputs[:, 7:8, imputed_columns]
            + inputs[:, 8:9, imputed_columns]
        ) / 2.0
    output[:, :, imputed_columns] = np.repeat(
        anchor, output.shape[1], axis=1
    )
    return output


def _continuity(
    context: np.ndarray,
    prediction: np.ndarray,
    std: np.ndarray,
    threshold: float,
    task_type: str,
) -> dict[str, Any]:
    if task_type == "extrapolation":
        known_change = np.abs(np.diff(context, axis=0)) / std.reshape(1, -1)
        predicted_sequence = np.vstack((context[-1:], prediction[0]))
        checked_boundaries = ["known_left_to_prediction"]
    else:
        known_change = np.vstack((
            np.abs(np.diff(context[:8], axis=0)),
            np.abs(np.diff(context[8:], axis=0)),
        )) / std.reshape(1, -1)
        predicted_sequence = np.vstack((
            context[7:8], prediction[0], context[8:9],
        ))
        checked_boundaries = [
            "known_left_to_prediction", "prediction_to_known_right",
        ]
    predicted_change = np.abs(np.diff(predicted_sequence, axis=0)) / std.reshape(1, -1)
    reference = np.maximum(np.quantile(known_change, 0.95, axis=0), 0.05)
    ratios = predicted_change / reference.reshape(1, -1)
    maximum = float(np.max(ratios))
    return {
        "method": "prediction_change_over_known_p95_change",
        "maximum_ratio": maximum,
        "threshold": threshold,
        "passed": maximum <= threshold,
        "checked_boundaries": checked_boundaries,
        "boundary_ratio": ratios[0].tolist(),
        "maximum_parameter_ratio": np.max(ratios, axis=0).tolist(),
    }


__all__ = ["run_product_gate"]
