"""Standard-library tests for the Step 9 Python HDF5 reader."""

from __future__ import annotations

import json
import sys
import tempfile
import unittest
from pathlib import Path

import h5py
import numpy as np


REPOSITORY_ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPOSITORY_ROOT / "tools" / "python"))

from read_predictor_data_hdf5 import read_predictor_data_hdf5  # noqa: E402


class PredictorDataHdf5ReaderTest(unittest.TestCase):
    def test_canonical_shapes_are_not_transposed(self) -> None:
        parameter_values = np.arange(48, dtype=np.float64).reshape(
            (24, 2), order="F"
        )
        inputs = np.arange(64, dtype=np.float64).reshape(
            (2, 16, 2), order="F"
        )
        targets = np.arange(16, dtype=np.float64).reshape(
            (2, 4, 2), order="F"
        )
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "predictor.h5"
            with h5py.File(path, "w") as handle:
                handle.attrs["schema_version"] = (
                    "v3.0-predictor-data-hdf5.1"
                )
                metadata = {
                    "parameter_names": ["DS_mu", "KF_mu"],
                    "task_type": "extrapolation",
                }
                handle["/metadata/json_utf8"] = np.frombuffer(
                    json.dumps(metadata).encode("utf-8"), dtype=np.uint8
                )
                self._write_flat(
                    handle, "/parameter_sequence/values", parameter_values
                )
                self._write_flat(
                    handle,
                    "/parameter_sequence/parameter_bounds",
                    np.asarray([[-9, -7], [-10, 20]], dtype=np.float64),
                )
                self._write_flat(handle, "/predictor/inputs", inputs)
                self._write_flat(handle, "/predictor/targets", targets)
                self._write_flat(
                    handle,
                    "/predictor/input_parameter_sample_index",
                    np.arange(32, dtype=np.float64).reshape((2, 16)),
                )
                self._write_flat(
                    handle,
                    "/predictor/target_parameter_sample_index",
                    np.arange(8, dtype=np.float64).reshape((2, 4)),
                )
                self._write_flat(
                    handle,
                    "/split/example_partition_code",
                    np.asarray([[1], [3]], dtype=np.uint8),
                )

            bundle = read_predictor_data_hdf5(path)

        self.assertEqual(bundle["inputs"].shape, (2, 16, 2))
        self.assertEqual(bundle["targets"].shape, (2, 4, 2))
        np.testing.assert_array_equal(bundle["inputs"], inputs)
        np.testing.assert_array_equal(bundle["targets"], targets)

    @staticmethod
    def _write_flat(
        handle: h5py.File, base_path: str, value: np.ndarray
    ) -> None:
        handle[f"{base_path}_values"] = value.reshape(-1, order="F")
        handle[f"{base_path}_shape"] = np.asarray(
            value.shape, dtype=np.uint64
        ).reshape(-1, 1)


if __name__ == "__main__":
    unittest.main()
