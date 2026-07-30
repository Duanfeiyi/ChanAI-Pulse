"""Stable Predictor Adapter used by Python, MATLAB, and the Step 10 demo."""

from __future__ import annotations

import json
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

import numpy as np

from .adaptation import adapt_prediction_head
from .contracts import (
    PREDICTION_SCHEMA_VERSION,
    AdaptationPolicy,
    PredictionRequest,
    PredictorData,
)
from .data import load_predictor_data_hdf5
from .registry import load_registry, select_registry_entry
from .training import load_checkpoint, predict_model


def run_prediction(
    data: PredictorData,
    registry_path: str | Path,
    *,
    selection_mode: str = "auto",
    requested_model: str | None = None,
    partition: str = "test",
    adaptation_policy: AdaptationPolicy | None = None,
    device: str = "auto",
) -> dict[str, Any]:
    registry_path, registry = load_registry(registry_path)
    entry = select_registry_entry(
        registry, data, selection_mode, requested_model=requested_model
    )
    checkpoint = registry_path.parent / entry["checkpoint"]
    model, manifest = load_checkpoint(checkpoint, "cpu")
    indices = data.partition_indices(partition)
    actual_target_indices = np.asarray(data.target_parameter_sample_index)
    if actual_target_indices.shape[0] == data.inputs.shape[0]:
        actual_target_indices = actual_target_indices[indices]
    policy = adaptation_policy or AdaptationPolicy(mode="off")
    policy_values = dict(policy.__dict__)
    target_groups = [
        data.example_group_ids[int(index)]
        for index in indices
        for _ in range(actual_target_indices.shape[1])
    ]
    policy_values["actual_target_sample_index"] = tuple(
        float(item) for item in actual_target_indices.reshape(-1)
    )
    policy_values["actual_target_group_id"] = tuple(target_groups)
    model, adaptation = adapt_prediction_head(
        model, data, AdaptationPolicy(**policy_values), device=device
    )
    prediction_normalized = predict_model(model, data.inputs[indices], device)
    prediction_raw = data.denormalize(prediction_normalized, project_bounds=True)
    return {
        "schema_version": PREDICTION_SCHEMA_VERSION,
        "created_utc": datetime.now(timezone.utc).isoformat(),
        "task_type": data.task_type,
        "context_layout": data.context_layout,
        "parameter_names": list(data.parameter_names),
        "parameter_units": list(data.parameter_units),
        "input_shape": list(data.inputs[indices].shape),
        "prediction_shape": list(prediction_raw.shape),
        "target_parameter_sample_index": actual_target_indices.tolist(),
        "prediction_normalized": prediction_normalized.tolist(),
        "prediction_parameters": prediction_raw.tolist(),
        "selection": {
            "mode": selection_mode,
            "requested_model": requested_model,
            "selected_model": entry["model_type"],
            "selection_basis": (
                "offline_validation_registry"
                if selection_mode == "auto"
                else "advanced_user_manual_choice"
            ),
            "target_ground_truth_read_for_selection": False,
        },
        "model": {
            "checkpoint": str(checkpoint),
            "manifest_schema_version": manifest["schema_version"],
            "validation_metrics": entry["validation_metrics"],
        },
        "adaptation": adaptation,
        "cir_status": {
            "available": False,
            "reason": "Step 11 converts predicted parameters to CIR.",
        },
    }


def predict_from_files(
    data_path: str | Path,
    registry_path: str | Path,
    output_path: str | Path,
    **kwargs: Any,
) -> dict[str, Any]:
    result = run_prediction(
        load_predictor_data_hdf5(data_path), registry_path, **kwargs
    )
    output_path = Path(output_path).expanduser().resolve()
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(
        json.dumps(result, indent=2, ensure_ascii=False), encoding="utf-8"
    )
    return result


def run_prediction_request(
    request: PredictionRequest,
    registry_path: str | Path,
    *,
    selection_mode: str = "auto",
    requested_model: str | None = None,
    adaptation_policy: AdaptationPolicy | None = None,
    adaptation_data: PredictorData | None = None,
    device: str = "auto",
) -> dict[str, Any]:
    """Run a product prediction request that contains no target ground truth."""
    request.validate()
    registry_path, registry = load_registry(registry_path)
    entry = select_registry_entry(
        registry, request, selection_mode, requested_model=requested_model
    )
    model, manifest = load_checkpoint(
        registry_path.parent / entry["checkpoint"], "cpu"
    )
    preprocessing = registry["preprocessing"]
    mean = np.asarray(preprocessing["normalization_mean"], dtype=np.float64)
    std = np.asarray(preprocessing["normalization_std"], dtype=np.float64)
    bounds = np.asarray(preprocessing["parameter_bounds"], dtype=np.float64)
    normalized_inputs = (
        request.input_parameters - mean.reshape(1, 1, -1)
    ) / std.reshape(1, 1, -1)
    policy = adaptation_policy or AdaptationPolicy(mode="off")
    if adaptation_data is None:
        if policy.mode == "force":
            raise ValueError(
                "Forced adaptation requires a separate labeled known-region dataset."
            )
        adaptation = {
            "schema_version": "v3.0-predictor-adaptation-result.1",
            "requested_mode": policy.mode,
            "status": "skipped",
            "accepted": False,
            "reason": (
                "adaptation_off"
                if policy.mode == "off"
                else "no_labeled_known_region_adaptation_data"
            ),
            "updated_parameters": [],
        }
    else:
        target_groups = [
            group
            for group in request.example_group_ids
            for _ in range(request.target_length)
        ]
        policy_values = dict(policy.__dict__)
        policy_values["actual_target_sample_index"] = tuple(
            float(item)
            for item in request.target_parameter_sample_index.reshape(-1)
        )
        policy_values["actual_target_group_id"] = tuple(target_groups)
        model, adaptation = adapt_prediction_head(
            model,
            adaptation_data,
            AdaptationPolicy(**policy_values),
            device=device,
        )
    prediction_normalized = predict_model(model, normalized_inputs, device)
    prediction_raw = (
        prediction_normalized.astype(np.float64) * std.reshape(1, 1, -1)
        + mean.reshape(1, 1, -1)
    )
    prediction_raw = np.maximum(
        prediction_raw, bounds[:, 0].reshape(1, 1, -1)
    )
    prediction_raw = np.minimum(
        prediction_raw, bounds[:, 1].reshape(1, 1, -1)
    )
    return {
        "schema_version": PREDICTION_SCHEMA_VERSION,
        "created_utc": datetime.now(timezone.utc).isoformat(),
        "request_schema_version": "v3.0-predictor-request.1",
        "request_contains_target_ground_truth": False,
        "task_type": request.task_type,
        "context_layout": request.context_layout,
        "parameter_names": list(request.parameter_names),
        "parameter_units": list(request.parameter_units),
        "input_shape": list(normalized_inputs.shape),
        "prediction_shape": list(prediction_raw.shape),
        "target_parameter_sample_index": request.target_parameter_sample_index.tolist(),
        "prediction_normalized": prediction_normalized.tolist(),
        "prediction_parameters": prediction_raw.tolist(),
        "selection": {
            "mode": selection_mode,
            "requested_model": requested_model,
            "selected_model": entry["model_type"],
            "selection_basis": (
                "offline_validation_registry"
                if selection_mode == "auto"
                else "advanced_user_manual_choice"
            ),
            "target_ground_truth_read_for_selection": False,
        },
        "model": {
            "checkpoint": str(registry_path.parent / entry["checkpoint"]),
            "manifest_schema_version": manifest["schema_version"],
            "validation_metrics": entry["validation_metrics"],
        },
        "adaptation": adaptation,
        "cir_status": {
            "available": False,
            "reason": "Step 11 converts predicted parameters to CIR.",
        },
    }


def predict_request_from_files(
    request_path: str | Path,
    registry_path: str | Path,
    output_path: str | Path,
    **kwargs: Any,
) -> dict[str, Any]:
    from .request import load_prediction_request

    result = run_prediction_request(
        load_prediction_request(request_path), registry_path, **kwargs
    )
    output_path = Path(output_path).expanduser().resolve()
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(
        json.dumps(result, indent=2, ensure_ascii=False), encoding="utf-8"
    )
    return result
