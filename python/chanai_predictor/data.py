"""Load the portable Step 9 HDF5 contract without changing axis order."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any

import h5py
import numpy as np

from .contracts import PREDICTOR_DATA_SCHEMA_VERSION, PredictorData


def _text(value: Any) -> str:
    if isinstance(value, np.ndarray):
        if value.size != 1:
            raise ValueError("Expected a scalar HDF5 text attribute.")
        return _text(value.reshape(-1)[0])
    if isinstance(value, bytes):
        return value.decode("utf-8")
    return str(value)


def _read_flat(handle: h5py.File, base_path: str) -> np.ndarray:
    values = np.asarray(handle[f"{base_path}_values"])
    shape = tuple(int(item) for item in handle[f"{base_path}_shape"][...].ravel())
    return values.reshape(shape, order="F")


def load_predictor_data_hdf5(path: str | Path) -> PredictorData:
    """Load and validate a Step 9 predictor-data bundle."""
    path = Path(path).expanduser().resolve()
    if not path.is_file():
        raise FileNotFoundError(path)
    with h5py.File(path, "r") as handle:
        schema = _text(handle.attrs["schema_version"])
        if schema != PREDICTOR_DATA_SCHEMA_VERSION:
            raise ValueError(f"Unsupported predictor-data schema: {schema}")
        metadata_bytes = bytes(
            np.asarray(handle["/metadata/json_utf8"], dtype=np.uint8).ravel()
        )
        metadata = json.loads(metadata_bytes.decode("utf-8"))
        normalization_mean = _read_flat(
            handle, "/normalization/mean"
        ).astype(np.float64).reshape(-1)
        normalization_std = _read_flat(
            handle, "/normalization/standard_deviation"
        ).astype(np.float64).reshape(-1)
        bundle = PredictorData(
            path=path,
            task_type=str(metadata["task_type"]),
            context_layout=str(metadata["context_layout"]),
            parameter_names=tuple(str(item) for item in metadata["parameter_names"]),
            parameter_units=tuple(str(item) for item in metadata["parameter_units"]),
            parameter_bounds=_read_flat(
                handle, "/parameter_sequence/parameter_bounds"
            ).astype(np.float64),
            inputs=_read_flat(handle, "/predictor/inputs").astype(np.float32),
            targets=_read_flat(handle, "/predictor/targets").astype(np.float32),
            target_parameter_sample_index=_read_flat(
                handle, "/predictor/target_parameter_sample_index"
            ).astype(np.float64),
            partition_codes=_read_flat(
                handle, "/split/example_partition_code"
            ).astype(np.uint8).reshape(-1),
            example_group_ids=tuple(
                str(item) for item in metadata["example_group_id"]
            ),
            normalization_mean=normalization_mean,
            normalization_std=normalization_std,
            metadata=metadata,
        )
    bundle.validate()
    return bundle
