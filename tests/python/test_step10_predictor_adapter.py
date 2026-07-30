"""Step 10 model, registry, selection, and leakage-boundary tests."""

from __future__ import annotations

import copy
import json
import sys
import unittest
from dataclasses import replace
from pathlib import Path

import numpy as np

REPO_ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO_ROOT / "python"))

from chanai_predictor import (  # noqa: E402
    AdaptationPolicy,
    load_prediction_request,
    load_predictor_data_hdf5,
)
from chanai_predictor.adaptation import adapt_prediction_head  # noqa: E402
from chanai_predictor.contracts import TrainingConfig  # noqa: E402
from chanai_predictor.models import (  # noqa: E402
    build_model,
    linear_predict,
    persistence_predict,
)
from chanai_predictor.registry import (  # noqa: E402
    load_registry,
    select_registry_entry,
)
from chanai_predictor.service import run_prediction, run_prediction_request  # noqa: E402
from chanai_predictor.training import load_checkpoint  # noqa: E402


class Step10PredictorAdapterTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.data_directory = REPO_ROOT / "demo_data" / "v3_step9"
        cls.model_directory = REPO_ROOT / "demo_data" / "v3_step10" / "models"
        cls.extrapolation = load_predictor_data_hdf5(
            cls.data_directory / "step9_extrapolation_standard.h5"
        )
        cls.interpolation = load_predictor_data_hdf5(
            cls.data_directory / "step9_interpolation_standard.h5"
        )
        cls.extrapolation_registry = (
            cls.model_directory
            / "extrapolation"
            / "extrapolation_model_registry.json"
        )
        cls.interpolation_registry = (
            cls.model_directory
            / "interpolation"
            / "interpolation_model_registry.json"
        )
        cls.extrapolation_request_path = (
            REPO_ROOT
            / "demo_data"
            / "v3_step10"
            / "requests"
            / "extrapolation_request.json"
        )

    def test_all_neural_models_preserve_16_to_4_by_2_contract(self) -> None:
        for data in (self.extrapolation, self.interpolation):
            for model_type in ("gru", "lstm", "tcn"):
                with self.subTest(task=data.task_type, model=model_type):
                    model = build_model(data, TrainingConfig(model_type=model_type))
                    output = model(
                        __import__("torch").from_numpy(data.inputs[:3]).float()
                    )
                    self.assertEqual(tuple(output.shape), (3, 4, 2))

    def test_baselines_preserve_contract(self) -> None:
        for data in (self.extrapolation, self.interpolation):
            self.assertEqual(
                persistence_predict(data, data.inputs[:2]).shape, (2, 4, 2)
            )
            self.assertEqual(linear_predict(data, data.inputs[:2]).shape, (2, 4, 2))

    def test_auto_selection_is_frozen_in_offline_registry(self) -> None:
        _, registry = load_registry(self.extrapolation_registry)
        entry = select_registry_entry(registry, self.extrapolation, "auto")
        expected = registry["selection_policy"]["selected_model_type"]
        self.assertEqual(entry["model_type"], expected)
        self.assertFalse(
            registry["selection_policy"][
                "target_ground_truth_used_at_prediction_time"
            ]
        )

    def test_auto_prediction_does_not_change_when_test_truth_changes(self) -> None:
        original = run_prediction(
            self.extrapolation,
            self.extrapolation_registry,
            selection_mode="auto",
            partition="test",
            adaptation_policy=AdaptationPolicy(mode="off"),
            device="cpu",
        )
        changed_targets = self.extrapolation.targets.copy()
        test_indices = self.extrapolation.partition_indices("test")
        changed_targets[test_indices] += 1000.0
        perturbed = replace(self.extrapolation, targets=changed_targets)
        repeated = run_prediction(
            perturbed,
            self.extrapolation_registry,
            selection_mode="auto",
            partition="test",
            adaptation_policy=AdaptationPolicy(mode="off"),
            device="cpu",
        )
        self.assertEqual(
            original["selection"]["selected_model"],
            repeated["selection"]["selected_model"],
        )
        np.testing.assert_array_equal(
            original["prediction_normalized"], repeated["prediction_normalized"]
        )

    def test_product_request_contains_no_target_truth_and_matches_wrapper(self) -> None:
        payload = json.loads(
            self.extrapolation_request_path.read_text(encoding="utf-8")
        )
        self.assertNotIn("targets", payload)
        self.assertNotIn("target_parameters", payload)
        self.assertFalse(payload["contains_target_ground_truth"])
        request = load_prediction_request(self.extrapolation_request_path)
        product = run_prediction_request(
            request,
            self.extrapolation_registry,
            selection_mode="auto",
            adaptation_policy=AdaptationPolicy(mode="off"),
            device="cpu",
        )
        evaluation_wrapper = run_prediction(
            self.extrapolation,
            self.extrapolation_registry,
            selection_mode="auto",
            partition="test",
            adaptation_policy=AdaptationPolicy(mode="off"),
            device="cpu",
        )
        self.assertFalse(product["request_contains_target_ground_truth"])
        np.testing.assert_allclose(
            product["prediction_normalized"],
            evaluation_wrapper["prediction_normalized"],
            atol=1e-6,
            rtol=0,
        )

    def test_product_request_force_adaptation_needs_separate_labels(self) -> None:
        request = load_prediction_request(self.extrapolation_request_path)
        with self.assertRaisesRegex(ValueError, "separate labeled"):
            run_prediction_request(
                request,
                self.extrapolation_registry,
                adaptation_policy=AdaptationPolicy(mode="force"),
                device="cpu",
            )

    def test_product_request_can_use_separate_known_region_adaptation_data(self) -> None:
        request = load_prediction_request(self.extrapolation_request_path)
        result = run_prediction_request(
            request,
            self.extrapolation_registry,
            adaptation_policy=AdaptationPolicy(
                mode="auto",
                max_epochs=2,
                patience=1,
                min_relative_improvement=0.0,
            ),
            adaptation_data=self.extrapolation,
            device="cpu",
        )
        self.assertIn(result["adaptation"]["status"], ("accepted", "rolled_back"))
        self.assertEqual(result["adaptation"]["actual_target_overlap_count"], 0)

    def test_adaptation_ignores_test_partition_truth(self) -> None:
        request = load_prediction_request(self.extrapolation_request_path)
        policy = AdaptationPolicy(
            mode="auto",
            max_epochs=2,
            patience=1,
            min_relative_improvement=0.0,
        )
        original = run_prediction_request(
            request,
            self.extrapolation_registry,
            adaptation_policy=policy,
            adaptation_data=self.extrapolation,
            device="cpu",
        )
        changed_targets = self.extrapolation.targets.copy()
        changed_targets[self.extrapolation.partition_indices("test")] += 1000.0
        perturbed_data = replace(self.extrapolation, targets=changed_targets)
        repeated = run_prediction_request(
            request,
            self.extrapolation_registry,
            adaptation_policy=policy,
            adaptation_data=perturbed_data,
            device="cpu",
        )
        np.testing.assert_array_equal(
            original["prediction_normalized"], repeated["prediction_normalized"]
        )

    def test_advanced_user_manual_choice_is_respected(self) -> None:
        result = run_prediction(
            self.interpolation,
            self.interpolation_registry,
            selection_mode="manual",
            requested_model="gru",
            partition="test",
            adaptation_policy=AdaptationPolicy(mode="off"),
            device="cpu",
        )
        self.assertEqual(result["selection"]["selected_model"], "gru")
        self.assertEqual(result["selection"]["mode"], "manual")
        self.assertFalse(result["cir_status"]["available"])

    def test_incompatible_task_registry_is_rejected(self) -> None:
        _, registry = load_registry(self.interpolation_registry)
        with self.assertRaisesRegex(ValueError, "incompatible"):
            select_registry_entry(registry, self.extrapolation, "auto")

    def test_adaptation_rejects_known_target_overlap(self) -> None:
        _, registry = load_registry(self.extrapolation_registry)
        entry = select_registry_entry(registry, self.extrapolation, "auto")
        model, _ = load_checkpoint(
            self.extrapolation_registry.parent / entry["checkpoint"], "cpu"
        )
        train_index = int(self.extrapolation.partition_indices("train")[0])
        row = self.extrapolation.target_parameter_sample_index[train_index]
        policy = AdaptationPolicy(
            mode="force",
            actual_target_sample_index=tuple(float(item) for item in row),
            actual_target_group_id=tuple(
                self.extrapolation.example_group_ids[train_index] for _ in row
            ),
        )
        with self.assertRaisesRegex(ValueError, "overlaps"):
            adapt_prediction_head(
                model, self.extrapolation, policy, device="cpu"
            )

    def test_adaptation_never_updates_encoder(self) -> None:
        _, registry = load_registry(self.interpolation_registry)
        entry = select_registry_entry(registry, self.interpolation, "auto")
        model, _ = load_checkpoint(
            self.interpolation_registry.parent / entry["checkpoint"], "cpu"
        )
        encoder_before = copy.deepcopy(model.encoder.state_dict())
        _, result = adapt_prediction_head(
            model,
            self.interpolation,
            AdaptationPolicy(
                mode="auto",
                max_epochs=2,
                patience=1,
                min_relative_improvement=0.0,
            ),
            device="cpu",
        )
        self.assertEqual(result["updated_parameters"], ["head.weight", "head.bias"])
        for name, value in model.encoder.state_dict().items():
            np.testing.assert_array_equal(
                value.numpy(), encoder_before[name].numpy()
            )


if __name__ == "__main__":
    unittest.main()
