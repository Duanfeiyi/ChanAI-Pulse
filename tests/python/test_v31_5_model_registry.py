"""v3.1-5 official Base Model package and safe-selection tests."""

from __future__ import annotations

import hashlib
import shutil
import sys
import tempfile
import unittest
from dataclasses import replace
from pathlib import Path

import numpy as np

REPO_ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO_ROOT / "python"))

from chanai_predictor import AdaptationPolicy, load_prediction_request  # noqa: E402
from chanai_predictor.contracts import PredictionRequest, PredictorData  # noqa: E402
from chanai_predictor.registry import (  # noqa: E402
    load_registry,
    resolve_entry_checkpoint,
)
from chanai_predictor.service import run_prediction_request  # noqa: E402
from chanai_predictor.training import load_checkpoint  # noqa: E402


class V315ModelRegistryTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.model_root = REPO_ROOT / "models" / "official" / "v3.1.0"
        cls.registry_paths = {
            task: cls.model_root / task / f"{task}_model_registry_v2.json"
            for task in ("interpolation", "extrapolation")
        }
        cls.registries = {
            task: load_registry(path)[1]
            for task, path in cls.registry_paths.items()
        }

    def make_request(
        self,
        task: str,
        *,
        normalized_value: float = 0.0,
        group: str = "request-region",
        target_indices: np.ndarray | None = None,
    ) -> PredictionRequest:
        registry = self.registries[task]
        signature = registry["compatibility"]
        preprocessing = registry["preprocessing"]
        mean = np.asarray(preprocessing["normalization_mean"], dtype=np.float64)
        std = np.asarray(preprocessing["normalization_std"], dtype=np.float64)
        inputs = mean.reshape(1, 1, -1) + normalized_value * std.reshape(1, 1, -1)
        inputs = np.repeat(inputs, signature["context_length"], axis=1)
        if target_indices is None:
            target_indices = np.arange(100, 104, dtype=np.float64).reshape(1, 4)
        return PredictionRequest(
            path=Path("synthetic_request.json"),
            task_type=task,
            context_layout=signature["context_layout"],
            parameter_names=tuple(signature["parameter_names"]),
            parameter_units=tuple(signature["parameter_units"]),
            input_parameters=inputs,
            input_parameter_sample_index=np.arange(16, dtype=np.float64).reshape(1, 16),
            target_parameter_sample_index=np.asarray(target_indices, dtype=np.float64),
            example_group_ids=(group,),
        )

    def make_adaptation_data(self, task: str) -> PredictorData:
        registry = self.registries[task]
        signature = registry["compatibility"]
        preprocessing = registry["preprocessing"]
        registry_mean = np.asarray(preprocessing["normalization_mean"], dtype=np.float64)
        registry_std = np.asarray(preprocessing["normalization_std"], dtype=np.float64)
        rng = np.random.default_rng(20260812)
        examples = 18
        raw_inputs = registry_mean.reshape(1, 1, -1) + registry_std.reshape(
            1, 1, -1
        ) * rng.normal(size=(examples, 16, 8))
        raw_targets = registry_mean.reshape(1, 1, -1) + registry_std.reshape(
            1, 1, -1
        ) * rng.normal(size=(examples, 4, 8))
        local_mean = registry_mean + 0.2 * registry_std
        local_std = 1.2 * registry_std
        inputs = (raw_inputs - local_mean.reshape(1, 1, -1)) / local_std.reshape(
            1, 1, -1
        )
        targets = (raw_targets - local_mean.reshape(1, 1, -1)) / local_std.reshape(
            1, 1, -1
        )
        target_indices = np.asarray(
            [np.arange(index * 10 + 20, index * 10 + 24) for index in range(examples)],
            dtype=np.float64,
        )
        return PredictorData(
            path=Path("synthetic_known_region.h5"),
            task_type=task,
            context_layout=signature["context_layout"],
            parameter_names=tuple(signature["parameter_names"]),
            parameter_units=tuple(signature["parameter_units"]),
            parameter_bounds=np.asarray(preprocessing["parameter_bounds"]),
            inputs=inputs.astype(np.float32),
            targets=targets.astype(np.float32),
            target_parameter_sample_index=target_indices,
            partition_codes=np.asarray([1] * 12 + [2] * 4 + [3] * 2),
            example_group_ids=tuple(f"known-{index}" for index in range(examples)),
            normalization_mean=local_mean,
            normalization_std=local_std,
            metadata={"synthetic": True},
        )

    def test_official_package_has_two_registries_and_ten_verified_checkpoints(self) -> None:
        checkpoint_count = 0
        for task, registry in self.registries.items():
            with self.subTest(task=task):
                self.assertEqual(registry["parameter_bundle"], "P8")
                self.assertEqual(len(registry["entries"]), 9)
                self.assertFalse(
                    registry["selection_policy"][
                        "target_ground_truth_used_at_prediction_time"
                    ]
                )
                for entry in registry["entries"]:
                    checkpoint = resolve_entry_checkpoint(
                        self.registry_paths[task], registry, entry
                    )
                    if checkpoint is None:
                        continue
                    checkpoint_count += 1
                    self.assertEqual(
                        hashlib.sha256(checkpoint.read_bytes()).hexdigest(),
                        entry["checkpoint_sha256"],
                    )
                    model, manifest = load_checkpoint(checkpoint, "cpu")
                    self.assertIsNotNone(model)
                    self.assertEqual(
                        manifest["architecture"]["model_type"], entry["model_type"]
                    )
        self.assertEqual(checkpoint_count, 10)

    def test_ordinary_auto_mode_uses_frozen_safe_recommendations(self) -> None:
        expected = {"interpolation": "persistence", "extrapolation": "kalman"}
        for task, model_type in expected.items():
            result = run_prediction_request(
                self.make_request(task),
                self.registry_paths[task],
                selection_mode="auto",
                adaptation_policy=AdaptationPolicy(mode="off"),
                device="cpu",
            )
            self.assertEqual(result["selection"]["selected_model"], model_type)
            self.assertTrue(result["selection"]["is_system_recommended"])
            self.assertEqual(result["prediction_shape"], [1, 4, 8])
            self.assertRegex(result["model"]["registry_sha256"], r"^[0-9a-f]{64}$")

    def test_public_target_free_requests_run_from_a_fresh_clone(self) -> None:
        expected = {"interpolation": "persistence", "extrapolation": "kalman"}
        for task, model_type in expected.items():
            request = load_prediction_request(
                REPO_ROOT
                / "demo_data"
                / "v31_5"
                / "requests"
                / f"{task}_neutral_p8_request.json"
            )
            result = run_prediction_request(
                request,
                self.registry_paths[task],
                adaptation_policy=AdaptationPolicy(mode="off"),
                device="cpu",
            )
            self.assertEqual(result["selection"]["selected_model"], model_type)
            self.assertFalse(result["request_contains_target_ground_truth"])

    def test_advanced_user_can_run_every_registered_model(self) -> None:
        task = "extrapolation"
        for model_type in (
            "persistence",
            "linear",
            "ar",
            "kalman",
            "gru",
            "lstm",
            "tcn",
            "dlinear",
            "nlinear",
        ):
            with self.subTest(model=model_type):
                result = run_prediction_request(
                    self.make_request(task),
                    self.registry_paths[task],
                    selection_mode="manual",
                    requested_model=model_type,
                    adaptation_policy=AdaptationPolicy(mode="off"),
                    device="cpu",
                )
                self.assertEqual(result["selection"]["selected_model"], model_type)
                self.assertEqual(result["prediction_shape"], [1, 4, 8])
                self.assertEqual(
                    result["selection"]["manual_non_recommended"],
                    model_type != "kalman",
                )

    def test_auto_adaptation_is_validated_or_rolled_back(self) -> None:
        task = "interpolation"
        result = run_prediction_request(
            self.make_request(task),
            self.registry_paths[task],
            selection_mode="auto",
            adaptation_policy=AdaptationPolicy(
                mode="auto",
                min_relative_improvement=0.0,
                max_epochs=1,
                patience=1,
                max_seconds=10.0,
            ),
            adaptation_data=self.make_adaptation_data(task),
            device="cpu",
        )
        self.assertIn(
            result["selection"]["selected_model"],
            ("persistence", "gru", "lstm", "tcn"),
        )
        self.assertIn(result["adaptation"]["status"], ("accepted", "rolled_back"))
        self.assertFalse(result["selection"]["target_ground_truth_read_for_selection"])
        self.assertEqual(len(result["selection"]["candidate_attempts"]), 3)

    def test_distribution_warning_forces_safe_auto_fallback(self) -> None:
        task = "extrapolation"
        result = run_prediction_request(
            self.make_request(task, normalized_value=20.0),
            self.registry_paths[task],
            selection_mode="auto",
            adaptation_policy=AdaptationPolicy(mode="auto"),
            adaptation_data=self.make_adaptation_data(task),
            device="cpu",
        )
        self.assertEqual(result["distribution_check"]["status"], "warning")
        self.assertEqual(result["selection"]["selected_model"], "kalman")
        self.assertEqual(
            result["adaptation"]["reason"], "distribution_guard_safe_fallback"
        )

    def test_force_adaptation_requires_labels_and_an_adaptable_model(self) -> None:
        task = "interpolation"
        with self.assertRaisesRegex(ValueError, "requires separate labeled"):
            run_prediction_request(
                self.make_request(task),
                self.registry_paths[task],
                selection_mode="manual",
                requested_model="gru",
                adaptation_policy=AdaptationPolicy(mode="force"),
                device="cpu",
            )
        with self.assertRaisesRegex(ValueError, "unavailable"):
            run_prediction_request(
                self.make_request(task),
                self.registry_paths[task],
                selection_mode="manual",
                requested_model="dlinear",
                adaptation_policy=AdaptationPolicy(mode="force"),
                adaptation_data=self.make_adaptation_data(task),
                device="cpu",
            )

    def test_adaptation_rejects_validation_overlap_with_prediction_target(self) -> None:
        task = "interpolation"
        data = self.make_adaptation_data(task)
        validation_index = int(data.partition_indices("validation")[0])
        request = self.make_request(
            task,
            group=data.example_group_ids[validation_index],
            target_indices=data.target_parameter_sample_index[
                validation_index : validation_index + 1
            ],
        )
        with self.assertRaisesRegex(ValueError, "overlaps"):
            run_prediction_request(
                request,
                self.registry_paths[task],
                selection_mode="manual",
                requested_model="gru",
                adaptation_policy=AdaptationPolicy(mode="force"),
                adaptation_data=data,
                device="cpu",
            )

    def test_parameter_unit_mismatch_is_rejected(self) -> None:
        request = self.make_request("interpolation")
        incompatible = replace(
            request,
            parameter_units=("wrong-unit",) + request.parameter_units[1:],
        )
        with self.assertRaisesRegex(ValueError, "parameter_units"):
            run_prediction_request(
                incompatible,
                self.registry_paths["interpolation"],
                adaptation_policy=AdaptationPolicy(mode="off"),
                device="cpu",
            )

    def test_checkpoint_tampering_is_rejected_before_load(self) -> None:
        source = self.registry_paths["interpolation"].parent
        with tempfile.TemporaryDirectory() as temporary:
            copied = Path(temporary) / "interpolation"
            shutil.copytree(source, copied)
            checkpoint = copied / "interpolation_gru.pt"
            with checkpoint.open("ab") as stream:
                stream.write(b"tampered")
            with self.assertRaisesRegex(ValueError, "SHA-256 mismatch"):
                run_prediction_request(
                    self.make_request("interpolation"),
                    copied / "interpolation_model_registry_v2.json",
                    selection_mode="manual",
                    requested_model="gru",
                    adaptation_policy=AdaptationPolicy(mode="off"),
                    device="cpu",
                )


if __name__ == "__main__":
    unittest.main()
