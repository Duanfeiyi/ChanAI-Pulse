"""Target-free JSON prediction-request contract."""

from __future__ import annotations

import json
from pathlib import Path

import numpy as np

from .contracts import (
    PREDICTION_REQUEST_SCHEMA_VERSION,
    PredictionRequest,
    PredictorData,
)


def load_prediction_request(path: str | Path) -> PredictionRequest:
    path = Path(path).expanduser().resolve()
    payload = json.loads(path.read_text(encoding="utf-8"))
    if payload["schema_version"] != PREDICTION_REQUEST_SCHEMA_VERSION:
        raise ValueError(
            f"Unsupported prediction-request schema: {payload['schema_version']}"
        )
    request = PredictionRequest(
        path=path,
        task_type=str(payload["task_type"]),
        context_layout=str(payload["context_layout"]),
        parameter_names=tuple(str(item) for item in payload["parameter_names"]),
        parameter_units=tuple(str(item) for item in payload["parameter_units"]),
        input_parameters=np.asarray(payload["input_parameters"], dtype=np.float64),
        input_parameter_sample_index=np.asarray(
            payload["input_parameter_sample_index"], dtype=np.float64
        ),
        target_parameter_sample_index=np.asarray(
            payload["target_parameter_sample_index"], dtype=np.float64
        ),
        example_group_ids=tuple(str(item) for item in payload["example_group_id"]),
    )
    request.validate()
    return request


def write_request_from_dataset(
    data: PredictorData,
    output_path: str | Path,
    partition: str = "test",
) -> Path:
    """Create a product-style request without serializing target truth."""
    indices = data.partition_indices(partition)
    input_raw = (
        data.inputs[indices].astype(np.float64)
        * data.normalization_std.reshape(1, 1, -1)
        + data.normalization_mean.reshape(1, 1, -1)
    )
    target_indices = np.asarray(data.target_parameter_sample_index)
    if target_indices.shape[0] == data.inputs.shape[0]:
        target_indices = target_indices[indices]
    target_start = target_indices[:, :1]
    if data.task_type == "extrapolation":
        offsets = np.arange(
            -data.context_length, 0, dtype=np.float64
        ).reshape(1, -1)
    else:
        half = data.context_length // 2
        offsets = np.concatenate(
            (
                np.arange(-half, 0, dtype=np.float64),
                np.arange(
                    data.target_length,
                    data.target_length + half,
                    dtype=np.float64,
                ),
            )
        ).reshape(1, -1)
    input_indices = target_start + offsets
    payload = {
        "schema_version": PREDICTION_REQUEST_SCHEMA_VERSION,
        "task_type": data.task_type,
        "context_layout": data.context_layout,
        "parameter_names": list(data.parameter_names),
        "parameter_units": list(data.parameter_units),
        "input_parameters": input_raw.tolist(),
        "input_parameter_sample_index": input_indices.tolist(),
        "target_parameter_sample_index": target_indices.tolist(),
        "example_group_id": [data.example_group_ids[int(index)] for index in indices],
        "contains_target_ground_truth": False,
    }
    output_path = Path(output_path).expanduser().resolve()
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(
        json.dumps(payload, indent=2, ensure_ascii=False), encoding="utf-8"
    )
    return output_path
