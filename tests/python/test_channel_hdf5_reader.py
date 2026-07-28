"""Standard-library tests for the Python v3 HDF5 reader."""

from __future__ import annotations

import json
import sys
import tempfile
import unittest
from pathlib import Path

import h5py
import numpy as np

REPO_ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO_ROOT / "tools" / "python"))

from read_channel_hdf5 import read_channel_hdf5  # noqa: E402


class ChannelHdf5ReaderTest(unittest.TestCase):
    def test_ctf_complex_shape_and_values(self) -> None:
        canonical_shape = (2, 1, 3, 2, 4)
        source = np.arange(np.prod(canonical_shape), dtype=np.float64)
        source = source.reshape(canonical_shape, order="F")
        expected = source + 1j * (source + 0.5)

        with tempfile.TemporaryDirectory() as temporary_directory:
            file_path = Path(temporary_directory) / "ctf.h5"
            with h5py.File(file_path, "w") as handle:
                handle["/ctf/H_real_values"] = expected.real.reshape(
                    -1, order="F"
                )
                handle["/ctf/H_real_shape"] = np.asarray(
                    canonical_shape, dtype=np.uint64
                ).reshape(-1, 1)
                handle["/ctf/H_imag_values"] = expected.imag.reshape(
                    -1, order="F"
                )
                handle["/ctf/H_imag_shape"] = np.asarray(
                    canonical_shape, dtype=np.uint64
                ).reshape(-1, 1)
                sample_index = np.arange(1, 5, dtype=np.float64)
                handle["/axes/sample_index_values"] = sample_index
                handle["/axes/sample_index_shape"] = np.asarray(
                    (4, 1), dtype=np.uint64
                ).reshape(-1, 1)
                handle.attrs["schema_version"] = "v3.0-data-contract.1"
                handle.attrs["domain"] = "ctf"
                handle.attrs["dimension_order_json"] = json.dumps(
                    ["Tx", "Rx", "Nf", "Nt", "N_sample"]
                )
                handle.attrs["units_json"] = json.dumps(
                    {
                        "frequency": "Hz",
                        "time": "s",
                        "delay": "s",
                        "position": "m",
                        "angle": "rad",
                        "power": "linear",
                    }
                )
                handle.attrs["metadata_json"] = json.dumps(
                    {"source": "python_contract_test"}
                )

            result = read_channel_hdf5(file_path)

        self.assertEqual(result["domain"], "ctf")
        self.assertEqual(result["ctf"]["H"].shape, canonical_shape)
        np.testing.assert_array_equal(result["ctf"]["H"], expected)
        self.assertEqual(
            result["dimension_order"],
            ["Tx", "Rx", "Nf", "Nt", "N_sample"],
        )

    def test_cir_fields_are_five_dimensional_but_axes_are_not(
        self,
    ) -> None:
        coefficient_shape = (1, 2, 3, 1, 2)
        delay_shape = (1, 1, 3, 1, 2)
        values = np.arange(
            np.prod(coefficient_shape), dtype=np.float64
        ).reshape(coefficient_shape, order="F")
        coefficient = values + 1j * (values + 0.25)
        delay = (
            np.arange(np.prod(delay_shape), dtype=np.float64)
            .reshape(delay_shape, order="F")
            * 1e-9
        )
        positions = np.array([[0.0, 0.0], [1.0, 0.0]])

        with tempfile.TemporaryDirectory() as temporary_directory:
            file_path = Path(temporary_directory) / "cir.h5"
            with h5py.File(file_path, "w") as handle:
                self._write_common_attributes(
                    handle,
                    "cir",
                    ["Tx", "Rx", "Npath", "Nt", "N_sample"],
                )
                self._write_complex(
                    handle, "/cir/coefficient", coefficient
                )
                self._write_flat(handle, "/cir/delay_s", delay)
                self._write_flat(
                    handle,
                    "/cir/path_valid",
                    np.ones(delay_shape, dtype=np.uint8),
                )
                self._write_flat(
                    handle, "/axes/sample_position_m", positions
                )

            result = read_channel_hdf5(file_path)

        self.assertEqual(
            result["cir"]["coefficient"].shape,
            coefficient_shape,
        )
        self.assertEqual(result["cir"]["delay_s"].shape, delay_shape)
        self.assertEqual(
            result["cir"]["path_valid"].shape,
            delay_shape,
        )
        self.assertEqual(
            result["axes"]["sample_position_m"].shape,
            (2, 2),
        )
        np.testing.assert_array_equal(
            result["axes"]["sample_position_m"],
            positions,
        )

    @staticmethod
    def _write_flat(
        handle: h5py.File,
        base_path: str,
        value: np.ndarray,
    ) -> None:
        handle[f"{base_path}_values"] = value.reshape(-1, order="F")
        handle[f"{base_path}_shape"] = np.asarray(
            value.shape, dtype=np.uint64
        ).reshape(-1, 1)

    @classmethod
    def _write_complex(
        cls,
        handle: h5py.File,
        base_path: str,
        value: np.ndarray,
    ) -> None:
        cls._write_flat(handle, f"{base_path}_real", value.real)
        cls._write_flat(handle, f"{base_path}_imag", value.imag)

    @staticmethod
    def _write_common_attributes(
        handle: h5py.File,
        domain: str,
        dimension_order: list[str],
    ) -> None:
        handle.attrs["schema_version"] = "v3.0-data-contract.1"
        handle.attrs["domain"] = domain
        handle.attrs["dimension_order_json"] = json.dumps(
            dimension_order
        )
        handle.attrs["units_json"] = json.dumps(
            {
                "frequency": "Hz",
                "time": "s",
                "delay": "s",
                "position": "m",
                "angle": "rad",
                "power": "linear",
            }
        )
        handle.attrs["metadata_json"] = json.dumps(
            {"source": "python_contract_test"}
        )


if __name__ == "__main__":
    unittest.main()
