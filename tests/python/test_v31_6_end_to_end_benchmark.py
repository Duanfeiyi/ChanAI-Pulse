"""Frozen protocol and leakage guards for the v3.1-6 benchmark."""

from __future__ import annotations

import hashlib
import json
import sys
import tempfile
import unittest
from pathlib import Path

import numpy as np

REPO_ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO_ROOT / "python"))

from chanai_predictor.contracts import PredictorData  # noqa: E402
from chanai_predictor.v31_6 import (  # noqa: E402
    P8_NAMES,
    P8_UNITS,
    _generator_rows,
    _known_region_adaptation_data,
    _scenario_profiles,
    _validate_gate,
    load_config,
)


class V316ProtocolTests(unittest.TestCase):
    def setUp(self) -> None:
        self.config_path = REPO_ROOT / "configs" / "v31_6_end_to_end_benchmark.json"
        self.config = load_config(self.config_path)[1]

    def make_data(self, task: str = "interpolation") -> PredictorData:
        examples = 60
        targets = np.asarray(
            [np.arange(index * 5 + 20, index * 5 + 24) for index in range(examples)],
            dtype=np.float64,
        )
        return PredictorData(
            path=Path("synthetic.h5"),
            task_type=task,
            context_layout=("left8_gap4_right8" if task == "interpolation" else "past16"),
            parameter_names=P8_NAMES,
            parameter_units=P8_UNITS,
            parameter_bounds=np.column_stack((np.full(8, -100), np.full(8, 100))),
            inputs=np.zeros((examples, 16, 8), dtype=np.float32),
            targets=np.zeros((examples, 4, 8), dtype=np.float32),
            target_parameter_sample_index=targets,
            partition_codes=np.full(examples, 3, dtype=np.uint8),
            example_group_ids=("route-a",) * examples,
            normalization_mean=np.zeros(8),
            normalization_std=np.ones(8),
            metadata={},
        )

    def test_protocol_freezes_models_routes_seeds_and_asset_policy(self) -> None:
        self.assertEqual(len(self.config["registry_models"]), 9)
        generator = self.config["generator_evaluation"]
        self.assertEqual(generator["validation_route_count"], 5)
        self.assertEqual(generator["test_route_count"], 18)
        self.assertEqual(generator["stability_seeds"], [31601, 31602, 31603])
        self.assertEqual(self.config["asset_policy"]["large_cir_ctf_cache"], "git_external")

    def test_scenario_profiles_support_versioned_nested_corpus_manifest(self) -> None:
        nested = {"step11abc_write_manifest": {"scenario_profiles": [{
            "scenario_name": "demo", "carrier_frequency_hz": 3.5e9,
            "parameter_names": list(P8_NAMES), "values": [0] * 8,
        }]}}
        profiles = _scenario_profiles(nested)
        self.assertIn(("demo", 3.5e9), profiles)

    def test_adaptation_examples_are_strictly_before_actual_target(self) -> None:
        data = self.make_data("interpolation")
        actual_index = 59
        adapted = _known_region_adaptation_data(data, actual_index)
        self.assertIsNotNone(adapted)
        self.assertLess(
            float(np.max(adapted.target_parameter_sample_index)),
            float(np.min(data.target_parameter_sample_index[actual_index])),
        )
        self.assertNotIn(3, set(adapted.partition_codes.tolist()))

    def test_validation_generator_uses_only_five_hash_ranked_routes(self) -> None:
        groups = [f"route-{index:02d}" for index in range(18)]
        rows = []
        representative = set()
        catalog = {}
        for index, group in enumerate(groups):
            representative.add((group, index))
            catalog[group] = {
                "scenario_name": "cmWave_Indoor_LoS",
                "carrier_frequency_hz": 16e9,
                "route_speed_mps": 1.0,
                "tx_count": 2,
                "rx_count": 2,
            }
            candidates = list(self.config["registry_models"]) + list(
                self.config["additional_baselines"]
            ) + ["auto_adapted_secondary"]
            for candidate in candidates:
                rows.append({
                    "candidate_id": candidate, "group_id": group,
                    "example_index": index, "target_offset": 0,
                    "target_step": 100, "task_type": "interpolation",
                })
        selected = _generator_rows(rows, representative, catalog, "validation", self.config)
        expected = set(sorted(groups, key=lambda value: hashlib.sha256(value.encode()).hexdigest())[:5])
        self.assertEqual({row["group_id"] for row in selected}, expected)
        self.assertEqual({row["protocol_seed"] for row in selected}, {31601})
        self.assertEqual(len(selected), 55)

    def test_generator_rejects_a_missing_frozen_candidate(self) -> None:
        rows = [{
            "candidate_id": "persistence", "group_id": "route-a",
            "example_index": 0, "target_offset": 0, "target_step": 100,
        }]
        catalog = {"route-a": {
            "scenario_name": "cmWave_Indoor_LoS", "carrier_frequency_hz": 16e9,
            "route_speed_mps": 1.0, "tx_count": 2, "rx_count": 2,
        }}
        with self.assertRaisesRegex(ValueError, "candidate matrix changed"):
            _generator_rows(rows, {("route-a", 0)}, catalog, "validation", self.config)

    def test_test_gate_is_bound_to_exact_protocol_and_claims_no_test_access(self) -> None:
        digest = hashlib.sha256(self.config_path.read_bytes()).hexdigest()
        payload = {
            "schema_version": "v3.1-6-validation-gate.1",
            "evaluation_partition": "validation",
            "passed": True,
            "protocol_config_sha256": digest,
            "test_partition_used": False,
        }
        with tempfile.TemporaryDirectory() as directory:
            gate = Path(directory) / "gate.json"
            gate.write_text(json.dumps(payload), encoding="utf-8")
            self.assertTrue(_validate_gate(gate, digest)["passed"])
            payload["test_partition_used"] = True
            gate.write_text(json.dumps(payload), encoding="utf-8")
            with self.assertRaisesRegex(ValueError, "Test access"):
                _validate_gate(gate, digest)


if __name__ == "__main__":
    unittest.main()
