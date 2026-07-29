"""Cross-language-format tests for the Step 2 standard fixtures."""

from __future__ import annotations

import hashlib
import json
import sys
import tempfile
import unittest
from pathlib import Path

import numpy as np

REPO_ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO_ROOT / "tools" / "python"))

from generate_v3_standard_fixtures import (  # noqa: E402
    generate_pair,
    load_scenarios,
    write_all,
)
from read_channel_hdf5 import read_channel_hdf5  # noqa: E402


class V3StandardFixturesTest(unittest.TestCase):
    def test_dimensions_capabilities_and_repeatability(self) -> None:
        expected_ctf_shapes = [
            (1, 1, 1, 1, 32),
            (1, 1, 64, 1, 32),
            (2, 4, 64, 1, 32),
            (2, 4, 64, 16, 32),
        ]
        expected_cir_shapes = [
            (1, 1, 1, 1, 32),
            (1, 1, 4, 1, 32),
            (2, 4, 6, 1, 32),
            (2, 4, 6, 16, 32),
        ]
        expected_plot_counts = [1, 3, 6, 9]
        expected_heatmap = [False, True, True, True]

        for index, scenario in enumerate(load_scenarios()):
            first = generate_pair(scenario)
            second = generate_pair(scenario)
            self.assertEqual(
                first["ctf"]["H"].shape, expected_ctf_shapes[index]
            )
            self.assertEqual(
                first["cir"]["coefficient"].shape,
                expected_cir_shapes[index],
            )
            self.assertEqual(
                first["expected"]["standard_plot_count"],
                expected_plot_counts[index],
            )
            self.assertEqual(
                first["expected"]["delay_sample_heatmap"],
                expected_heatmap[index],
            )
            np.testing.assert_array_equal(
                first["cir"]["coefficient"],
                second["cir"]["coefficient"],
            )
            np.testing.assert_array_equal(
                first["ctf"]["H"], second["ctf"]["H"]
            )

    def test_portable_hdf5_and_file_hashes_repeat(self) -> None:
        with (
            tempfile.TemporaryDirectory() as first_dir,
            tempfile.TemporaryDirectory() as second_dir,
        ):
            first_manifest = write_all(Path(first_dir))
            second_manifest = write_all(Path(second_dir))
            self.assertEqual(first_manifest, second_manifest)

            for entry in first_manifest["entries"]:
                for key in ("cir_file", "ctf_file"):
                    first_path = Path(first_dir) / entry[key]
                    second_path = Path(second_dir) / entry[key]
                    self.assertEqual(
                        _sha256(first_path), _sha256(second_path)
                    )
                cir = read_channel_hdf5(Path(first_dir) / entry["cir_file"])
                ctf = read_channel_hdf5(Path(first_dir) / entry["ctf_file"])
                self.assertEqual(
                    cir["cir"]["coefficient"].shape,
                    tuple(entry["cir_shape"]),
                )
                self.assertEqual(
                    ctf["ctf"]["H"].shape,
                    tuple(entry["ctf_shape"]),
                )
                self.assertEqual(
                    cir["metadata"]["sample_semantics"], "ordered_route"
                )
                np.testing.assert_array_equal(
                    cir["axes"]["sample_position_m"],
                    ctf["axes"]["sample_position_m"],
                )

    def test_repository_fixtures_match_current_generator(self) -> None:
        fixture_dir = REPO_ROOT / "demo_data" / "v3_standard_fixtures"
        manifest = json.loads(
            (fixture_dir / "manifest.json").read_text(encoding="utf-8")
        )
        entries = {entry["id"]: entry for entry in manifest["entries"]}
        for scenario in load_scenarios():
            expected = generate_pair(scenario)
            entry = entries[scenario["id"]]
            cir = read_channel_hdf5(fixture_dir / entry["cir_file"])
            ctf = read_channel_hdf5(fixture_dir / entry["ctf_file"])
            np.testing.assert_array_equal(
                cir["cir"]["coefficient"],
                expected["cir"]["coefficient"],
            )
            np.testing.assert_array_equal(
                ctf["ctf"]["H"], expected["ctf"]["H"]
            )
            self.assertEqual(
                entry["delay_sample_heatmap"],
                expected["expected"]["delay_sample_heatmap"],
            )


def _sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


if __name__ == "__main__":
    unittest.main()
