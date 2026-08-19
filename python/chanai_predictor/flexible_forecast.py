"""Full-history, arbitrary-horizon classical forecasting for v3.1 products."""

from __future__ import annotations

from dataclasses import dataclass
from typing import Any

import numpy as np


CLASSICAL_MODELS = (
    "persistence",
    "linear",
    "quadratic",
    "holt",
    "harmonic",
    "ar",
    "kalman",
)


@dataclass(frozen=True)
class ForecastExample:
    left_values: np.ndarray
    left_indices: np.ndarray
    target_values: np.ndarray
    target_indices: np.ndarray
    right_values: np.ndarray | None = None
    right_indices: np.ndarray | None = None


def contiguous_runs(indices: np.ndarray, groups: np.ndarray) -> list[np.ndarray]:
    indices = np.asarray(indices, dtype=np.float64)
    groups = np.asarray(groups, dtype=str)
    if not len(indices):
        return []
    starts = [0]
    for row in range(1, len(indices)):
        if groups[row] != groups[row - 1] or indices[row] != indices[row - 1] + 1:
            starts.append(row)
    starts.append(len(indices))
    return [np.arange(starts[i], starts[i + 1]) for i in range(len(starts) - 1)]


def target_runs(indices: np.ndarray) -> list[np.ndarray]:
    indices = np.asarray(indices, dtype=np.float64)
    if not len(indices):
        return []
    order = np.argsort(indices)
    sorted_indices = indices[order]
    starts = [0]
    for row in range(1, len(order)):
        if sorted_indices[row] != sorted_indices[row - 1] + 1:
            starts.append(row)
    starts.append(len(order))
    return [order[starts[i] : starts[i + 1]] for i in range(len(starts) - 1)]


def _weighted_design(
    history_axis: np.ndarray,
    degree: int,
    decay: float = 2.0,
) -> tuple[np.ndarray, np.ndarray]:
    axis = np.asarray(history_axis, dtype=np.float64)
    scale = max(float(np.ptp(axis)), 1.0)
    normalized = axis / scale
    design = np.column_stack([normalized**power for power in range(degree + 1)])
    age = np.max(axis) - axis
    weights = np.exp(-decay * age / scale)
    return design, np.sqrt(weights)


def _polynomial(
    history: np.ndarray,
    history_axis: np.ndarray,
    target_axis: np.ndarray,
    degree: int,
) -> np.ndarray:
    if len(history) <= degree:
        return np.repeat(history[-1], len(target_axis))
    design, root_weight = _weighted_design(history_axis, degree)
    regularizer = np.eye(design.shape[1]) * 1e-5
    regularizer[0, 0] = 0.0
    coefficients = np.linalg.solve(
        (design * root_weight[:, None]).T @ (design * root_weight[:, None])
        + regularizer,
        (design * root_weight[:, None]).T @ (history * root_weight),
    )
    scale = max(float(np.ptp(history_axis)), 1.0)
    normalized_target = np.asarray(target_axis, dtype=np.float64) / scale
    target_design = np.column_stack(
        [normalized_target**power for power in range(degree + 1)]
    )
    output = target_design @ coefficients
    if degree == 2:
        # Long quadratic extrapolation is gradually damped toward the
        # boundary tangent instead of being allowed to explode unchecked.
        linear = _polynomial(history, history_axis, target_axis, 1)
        horizon = np.maximum(np.asarray(target_axis, dtype=np.float64), 0.0)
        damping = np.exp(-horizon / max(len(history), 4))
        output = linear + damping * (output - linear)
    return output


def _holt(history: np.ndarray, horizon: int, damping: float = 0.92) -> np.ndarray:
    if len(history) < 2:
        return np.repeat(history[-1], horizon)
    alpha, beta = 0.45, 0.20
    level = float(history[0])
    trend = float(history[1] - history[0])
    for value in history[1:]:
        previous = level
        level = alpha * float(value) + (1 - alpha) * (level + damping * trend)
        trend = beta * (level - previous) + (1 - beta) * damping * trend
    return np.asarray(
        [level + sum(damping**step for step in range(1, lead + 1)) * trend
         for lead in range(1, horizon + 1)],
        dtype=np.float64,
    )


def _ar_coefficients(history: np.ndarray, order: int) -> np.ndarray:
    rows = np.asarray([history[i - order : i] for i in range(order, len(history))])
    target = history[order:]
    design = np.column_stack((rows, np.ones(len(rows))))
    regularizer = np.eye(design.shape[1]) * 1e-2
    regularizer[-1, -1] = 0.0
    return np.linalg.solve(
        design.T @ design + regularizer,
        design.T @ target,
    )


def _ar_forecast(history: np.ndarray, horizon: int) -> np.ndarray:
    if len(history) < 3:
        return _holt(history, horizon)
    maximum_order = min(12, max(1, len(history) // 3), len(history) - 2)
    validation = min(max(2, len(history) // 5), 6)
    train = history[:-validation]
    best_order, best_error = 1, np.inf
    for order in range(1, min(maximum_order, len(train) - 2) + 1):
        try:
            coefficients = _ar_coefficients(train, order)
            rolling = list(np.asarray(train, dtype=np.float64))
            guesses = []
            for _ in range(validation):
                row = np.asarray(rolling[-order:] + [1.0])
                guesses.append(float(row @ coefficients))
                rolling.append(guesses[-1])
            error = float(np.mean((np.asarray(guesses) - history[-validation:]) ** 2))
            if error < best_error:
                best_error, best_order = error, order
        except np.linalg.LinAlgError:
            continue
    coefficients = _ar_coefficients(history, best_order)
    rolling = list(np.asarray(history, dtype=np.float64))
    for _ in range(horizon):
        row = np.asarray(rolling[-best_order:] + [1.0])
        rolling.append(float(row @ coefficients))
    return np.asarray(rolling[-horizon:])


def _kalman(history: np.ndarray, horizon: int) -> np.ndarray:
    if len(history) < 2:
        return np.repeat(history[-1], horizon)
    state = np.asarray([history[0], history[1] - history[0]], dtype=np.float64)
    covariance = np.eye(2)
    transition = np.asarray([[1.0, 1.0], [0.0, 1.0]])
    observation = np.asarray([[1.0, 0.0]])
    process_noise = np.diag([1e-3, 1e-4])
    observation_noise = np.asarray([[5e-2]])
    for value in history:
        state = transition @ state
        covariance = transition @ covariance @ transition.T + process_noise
        innovation = float(value) - float((observation @ state)[0])
        residual = observation @ covariance @ observation.T + observation_noise
        gain = covariance @ observation.T @ np.linalg.inv(residual)
        state = state + gain[:, 0] * innovation
        covariance = (np.eye(2) - gain @ observation) @ covariance
    output = []
    for _ in range(horizon):
        state = transition @ state
        output.append(float(state[0]))
    return np.asarray(output)


def _harmonic(
    history: np.ndarray,
    history_axis: np.ndarray,
    target_axis: np.ndarray,
) -> np.ndarray:
    if len(history) < 8:
        return _polynomial(history, history_axis, target_axis, 2)
    age = np.max(history_axis) - history_axis
    root_weight = np.sqrt(np.exp(-age / max(float(np.ptp(history_axis)), 1.0)))
    regularizer = np.diag([0.0, 1e-4, 1e-3, 1e-3])
    spacing = max(float(np.median(np.diff(history_axis))), np.finfo(float).eps)
    span = max(float(np.ptp(history_axis)), spacing)
    candidates = np.linspace(2 * np.pi / (4 * span), np.pi / spacing, 256)
    best: tuple[float, float, np.ndarray] | None = None
    for omega in candidates:
        design = np.column_stack((
            np.ones(len(history)), history_axis,
            np.sin(omega * history_axis), np.cos(omega * history_axis),
        ))
        weighted = design * root_weight[:, None]
        try:
            coefficients = np.linalg.solve(
                weighted.T @ weighted + regularizer,
                weighted.T @ (history * root_weight),
            )
        except np.linalg.LinAlgError:
            continue
        residual = (design @ coefficients - history) * root_weight
        error = float(np.mean(residual**2))
        if best is None or error < best[0]:
            best = (error, float(omega), coefficients)
    if best is None:
        return _polynomial(history, history_axis, target_axis, 2)
    _, omega, coefficients = best
    target_design = np.column_stack((
        np.ones(len(target_axis)), target_axis,
        np.sin(omega * target_axis), np.cos(omega * target_axis),
    ))
    return target_design @ coefficients


def _relative_axes(
    history_indices: np.ndarray,
    target_indices: np.ndarray,
    side: str,
) -> tuple[np.ndarray, np.ndarray, np.ndarray]:
    history_indices = np.asarray(history_indices, dtype=np.float64)
    target_indices = np.asarray(target_indices, dtype=np.float64)
    if side == "left":
        boundary = history_indices[-1]
        return history_indices - boundary, target_indices - boundary, np.arange(len(history_indices))
    boundary = history_indices[0]
    order = np.arange(len(history_indices) - 1, -1, -1)
    return boundary - history_indices[order], boundary - target_indices, order


def forecast_one_sided(
    model: str,
    values: np.ndarray,
    indices: np.ndarray,
    target_indices: np.ndarray,
    *,
    side: str = "left",
) -> np.ndarray:
    """Forecast from all one-sided history, weighting near-boundary rows."""
    values = np.asarray(values, dtype=np.float64)
    history_axis, target_axis, order = _relative_axes(indices, target_indices, side)
    ordered = values[order]
    output = np.empty((len(target_indices), values.shape[1]), dtype=np.float64)
    for column in range(values.shape[1]):
        history = ordered[:, column]
        if model == "persistence":
            prediction = np.repeat(history[-1], len(target_indices))
        elif model == "linear":
            prediction = _polynomial(history, history_axis, target_axis, 1)
        elif model == "quadratic":
            prediction = _polynomial(history, history_axis, target_axis, 2)
        elif model == "holt":
            ordered_targets = np.argsort(target_axis)
            sequence = _holt(history, len(target_axis))
            prediction = np.empty_like(sequence)
            prediction[ordered_targets] = sequence
        elif model == "harmonic":
            prediction = _harmonic(history, history_axis, target_axis)
        elif model == "ar":
            ordered_targets = np.argsort(target_axis)
            sequence = _ar_forecast(history, len(target_axis))
            prediction = np.empty_like(sequence)
            prediction[ordered_targets] = sequence
        elif model == "kalman":
            ordered_targets = np.argsort(target_axis)
            sequence = _kalman(history, len(target_axis))
            prediction = np.empty_like(sequence)
            prediction[ordered_targets] = sequence
        else:
            raise ValueError(f"Unsupported classical model: {model}")
        output[:, column] = prediction
    return output


def forecast_classical(
    model: str,
    left_values: np.ndarray,
    left_indices: np.ndarray,
    target_indices: np.ndarray,
    *,
    right_values: np.ndarray | None = None,
    right_indices: np.ndarray | None = None,
) -> np.ndarray:
    forward = forecast_one_sided(
        model, left_values, left_indices, target_indices, side="left"
    )
    if right_values is None or right_indices is None or not len(right_values):
        return forward
    backward = forecast_one_sided(
        model, right_values, right_indices, target_indices, side="right"
    )
    left_distance = np.abs(target_indices - left_indices[-1])
    right_distance = np.abs(right_indices[0] - target_indices)
    denominator = np.maximum(left_distance + right_distance, np.finfo(float).eps)
    right_weight = left_distance / denominator
    return forward * (1 - right_weight[:, None]) + backward * right_weight[:, None]


def make_backtests(
    values: np.ndarray,
    indices: np.ndarray,
    groups: np.ndarray,
    task_type: str,
    requested_horizon: int,
    *,
    maximum_examples: int = 8,
) -> tuple[list[ForecastExample], dict[str, Any]]:
    """Create recent, horizon-matched examples using known rows only."""
    runs = contiguous_runs(indices, groups)
    examples: list[ForecastExample] = []
    evaluation_horizon = requested_horizon
    for run in runs:
        run_values, run_indices = values[run], indices[run]
        if task_type == "extrapolation":
            for start in range(16, len(run) - evaluation_horizon + 1):
                examples.append(ForecastExample(
                    run_values[:start], run_indices[:start],
                    run_values[start : start + evaluation_horizon],
                    run_indices[start : start + evaluation_horizon],
                ))
        else:
            for start in range(16, len(run) - evaluation_horizon - 15):
                end = start + evaluation_horizon
                examples.append(ForecastExample(
                    run_values[:start], run_indices[:start],
                    run_values[start:end], run_indices[start:end],
                    run_values[end:], run_indices[end:],
                ))
    if not examples and requested_horizon > 1:
        return make_backtests(
            values, indices, groups, task_type, 1,
            maximum_examples=maximum_examples,
        )[0], {
            "requested_horizon": requested_horizon,
            "evaluation_horizon": 1,
            "horizon_matched": False,
            "reason": "insufficient_known_history_for_requested_horizon",
        }
    examples = examples[-maximum_examples:]
    return examples, {
        "requested_horizon": requested_horizon,
        "evaluation_horizon": (
            len(examples[0].target_indices) if examples else 0
        ),
        "horizon_matched": bool(examples),
        "reason": "" if examples else "insufficient_known_history_for_backtest",
    }


def score_predictions(
    predictions: list[np.ndarray],
    examples: list[ForecastExample],
    normalization_std: np.ndarray,
) -> dict[str, Any]:
    if not predictions:
        return {
            "available": False,
            "example_count": 0,
            "normalized_rmse": float("nan"),
            "per_parameter_normalized_rmse": [],
            "worst_example_normalized_rmse": float("nan"),
        }
    errors = [
        (prediction - example.target_values)
        / normalization_std.reshape(1, -1)
        for prediction, example in zip(predictions, examples)
    ]
    per_example = np.asarray([np.sqrt(np.mean(error**2)) for error in errors])
    stacked = np.vstack(errors)
    return {
        "available": True,
        "example_count": len(errors),
        "normalized_rmse": float(np.sqrt(np.mean(stacked**2))),
        "per_parameter_normalized_rmse": np.sqrt(
            np.mean(stacked**2, axis=0)
        ).tolist(),
        "worst_example_normalized_rmse": float(np.max(per_example)),
    }
