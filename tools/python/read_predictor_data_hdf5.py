"""Read ChanAI Pulse v3 Step 9 predictor-data HDF5 files."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any

import h5py
import numpy as np


SCHEMA_VERSION = "v3.0-predictor-data-hdf5.1"


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


def read_predictor_data_hdf5(path: str | Path) -> dict[str, Any]:
    """Return portable arrays and decoded metadata without transposing axes."""
    with h5py.File(path, "r") as handle:
        schema = _text(handle.attrs["schema_version"])
        if schema != SCHEMA_VERSION:
            raise ValueError(f"Unsupported schema: {schema}")
        metadata_bytes = bytes(
            np.asarray(handle["/metadata/json_utf8"], dtype=np.uint8).ravel()
        )
        metadata = json.loads(metadata_bytes.decode("utf-8"))
        result: dict[str, Any] = {
            "schema_version": schema,
            "metadata": metadata,
            "parameter_values": _read_flat(
                handle, "/parameter_sequence/values"
            ),
            "parameter_bounds": _read_flat(
                handle, "/parameter_sequence/parameter_bounds"
            ),
            "inputs": _read_flat(handle, "/predictor/inputs"),
            "targets": _read_flat(handle, "/predictor/targets"),
            "input_parameter_sample_index": _read_flat(
                handle, "/predictor/input_parameter_sample_index"
            ),
            "target_parameter_sample_index": _read_flat(
                handle, "/predictor/target_parameter_sample_index"
            ),
            "example_partition_code": _read_flat(
                handle, "/split/example_partition_code"
            ).astype(np.uint8),
        }
        if "/normalization/mean_values" in handle:
            result["normalization"] = {
                "mean": _read_flat(handle, "/normalization/mean"),
                "standard_deviation": _read_flat(
                    handle, "/normalization/standard_deviation"
                ),
                "raw_standard_deviation": _read_flat(
                    handle, "/normalization/raw_standard_deviation"
                ),
                "physical_bounds": _read_flat(
                    handle, "/normalization/physical_bounds"
                ),
                "zero_variance": _read_flat(
                    handle, "/normalization/zero_variance"
                ).astype(bool),
                "integer_parameter": _read_flat(
                    handle, "/normalization/integer_parameter"
                ).astype(bool),
            }
        return result


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Inspect a ChanAI Pulse Step 9 predictor-data HDF5 file."
    )
    parser.add_argument("path", type=Path)
    arguments = parser.parse_args()
    bundle = read_predictor_data_hdf5(arguments.path)
    summary = {
        "schema_version": bundle["schema_version"],
        "parameter_names": bundle["metadata"]["parameter_names"],
        "task_type": bundle["metadata"]["task_type"],
        "parameter_values_shape": list(bundle["parameter_values"].shape),
        "inputs_shape": list(bundle["inputs"].shape),
        "targets_shape": list(bundle["targets"].shape),
        "partition_counts": {
            name: int(np.sum(bundle["example_partition_code"] == code))
            for code, name in enumerate(("train", "validation", "test"), start=1)
        },
    }
    print(json.dumps(summary, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
