"""Verify MATLAB-generated Step 2 fixtures from Python.

Usage:
    python tests/python/verify_v3_matlab_exports.py <fixture-directory>
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

import numpy as np

REPO_ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO_ROOT / "tools" / "python"))

from generate_v3_standard_fixtures import (  # noqa: E402
    generate_pair,
    load_scenarios,
)
from read_channel_hdf5 import read_channel_hdf5  # noqa: E402


def verify(directory: Path) -> None:
    manifest = json.loads(
        (directory / "manifest.json").read_text(encoding="utf-8")
    )
    scenarios = {item["id"]: item for item in load_scenarios()}
    if len(manifest["entries"]) != 4:
        raise AssertionError("MATLAB manifest must contain four entries.")

    for entry in manifest["entries"]:
        scenario = scenarios[entry["id"]]
        expected = generate_pair(scenario)
        cir = read_channel_hdf5(directory / entry["cir_file"])
        ctf = read_channel_hdf5(directory / entry["ctf_file"])
        np.testing.assert_allclose(
            cir["cir"]["coefficient"],
            expected["cir"]["coefficient"],
            rtol=2e-5,
            atol=2e-6,
        )
        np.testing.assert_allclose(
            cir["cir"]["delay_s"],
            expected["cir"]["delay_s"],
            rtol=2e-5,
            atol=1e-12,
        )
        np.testing.assert_allclose(
            ctf["ctf"]["H"],
            expected["ctf"]["H"],
            rtol=3e-5,
            atol=3e-6,
        )
        np.testing.assert_allclose(
            cir["axes"]["sample_position_m"],
            expected["axes"]["sample_position_m"],
            rtol=0,
            atol=1e-12,
        )
    print("PASS: MATLAB exports match the Python Step 2 reference values.")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("fixture_directory", type=Path)
    args = parser.parse_args()
    verify(args.fixture_directory)


if __name__ == "__main__":
    main()
