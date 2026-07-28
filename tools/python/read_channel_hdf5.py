"""Read ChanAI Pulse v3 portable CIR/CTF HDF5 files."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any

import h5py
import numpy as np


def _decode_attribute(value: Any) -> str:
    if isinstance(value, bytes):
        return value.decode("utf-8")
    return str(value)


def _read_flat(group: h5py.File, base_path: str) -> np.ndarray:
    values = np.asarray(group[f"{base_path}_values"])
    raw_shape = np.asarray(group[f"{base_path}_shape"][...])
    shape = tuple(
        int(value) for value in raw_shape.reshape(-1, order="F")
    )
    return values.reshape(shape, order="F")


def _read_complex(group: h5py.File, base_path: str) -> np.ndarray:
    real = _read_flat(group, f"{base_path}_real")
    imag = _read_flat(group, f"{base_path}_imag")
    if real.shape != imag.shape:
        raise ValueError("Real and imaginary datasets have different shapes.")
    return real + 1j * imag


def read_channel_hdf5(file_path: str | Path) -> dict[str, Any]:
    """Return a dictionary using the canonical MATLAB dimension order."""

    file_path = Path(file_path)
    with h5py.File(file_path, "r") as handle:
        domain = _decode_attribute(handle.attrs["domain"]).lower()
        result: dict[str, Any] = {
            "schema_version": _decode_attribute(
                handle.attrs["schema_version"]
            ),
            "domain": domain,
            "dimension_order": json.loads(
                _decode_attribute(handle.attrs["dimension_order_json"])
            ),
            "units": json.loads(_decode_attribute(handle.attrs["units_json"])),
            "metadata": json.loads(
                _decode_attribute(handle.attrs["metadata_json"])
            ),
            "axes": {},
        }

        for field_name in (
            "frequency_hz",
            "time_s",
            "sample_index",
            "sample_position_m",
        ):
            base_path = f"/axes/{field_name}"
            if f"{base_path}_values" in handle:
                result["axes"][field_name] = _read_flat(handle, base_path)

        if domain == "ctf":
            result["ctf"] = {"H": _read_complex(handle, "/ctf/H")}
        elif domain == "cir":
            cir = {
                "coefficient": _read_complex(handle, "/cir/coefficient"),
                "delay_s": _read_flat(handle, "/cir/delay_s"),
                "path_valid": _read_flat(
                    handle, "/cir/path_valid"
                ).astype(bool),
            }
            for field_name in ("aoa_rad", "aod_rad", "doppler_hz"):
                base_path = f"/cir/{field_name}"
                if f"{base_path}_values" in handle:
                    cir[field_name] = _read_flat(handle, base_path)
            result["cir"] = cir
        else:
            raise ValueError(f"Unsupported channel domain: {domain}")

    return result


def _summary(dataset: dict[str, Any]) -> dict[str, Any]:
    if dataset["domain"] == "ctf":
        shape = dataset["ctf"]["H"].shape
    else:
        shape = dataset["cir"]["coefficient"].shape
    return {
        "schema_version": dataset["schema_version"],
        "domain": dataset["domain"],
        "dimension_order": dataset["dimension_order"],
        "shape": list(shape),
        "source": dataset["metadata"].get("source", "unspecified"),
    }


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Inspect a ChanAI Pulse v3 channel HDF5 file."
    )
    parser.add_argument("file", type=Path)
    arguments = parser.parse_args()
    print(json.dumps(_summary(read_channel_hdf5(arguments.file)), indent=2))


if __name__ == "__main__":
    main()
