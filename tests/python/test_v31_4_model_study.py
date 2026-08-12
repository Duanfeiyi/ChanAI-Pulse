"""Regression tests for the v3.1-4 model-study primitives."""

from __future__ import annotations

import hashlib
import json
import sys
import tempfile
import unittest
from dataclasses import replace
from pathlib import Path

import numpy as np
import torch

REPOSITORY = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPOSITORY / "python"))

from chanai_predictor.contracts import PredictorData, TrainingConfig  # noqa: E402
from chanai_predictor.models import build_model  # noqa: E402
from chanai_predictor.training import load_checkpoint, predict_model, train_model  # noqa: E402
from chanai_predictor.v31_4 import (  # noqa: E402
    AdmissionRules,
    DEFAULT_SENSITIVITY_WEIGHTS,
    BASELINE_TYPES,
    MODEL_TYPES,
    _aggregate_runs,
    _selected_prediction,
    ar_predict,
    finalize_test_once,
    kalman_predict,
)


def fixture(task: str = "extrapolation") -> PredictorData:
    rng = np.random.default_rng(314)
    inputs = rng.normal(size=(12, 16, 8)).astype(np.float32)
    targets = rng.normal(size=(12, 4, 8)).astype(np.float32)
    groups = tuple(f"route-{index // 2:02d}" for index in range(12))
    return PredictorData(
        path=Path("synthetic.h5"),
        task_type=task,
        context_layout="past_only" if task == "extrapolation" else "left_right",
        parameter_names=(
            "DS_mu",
            "KF_mu",
            "DS_sigma",
            "KF_sigma",
            "r_DS",
            "LNS_ksi",
            "num_clusters",
            "num_rays",
        ),
        parameter_units=("1",) * 8,
        parameter_bounds=np.column_stack((np.full(8, -100.0), np.full(8, 100.0))),
        inputs=inputs,
        targets=targets,
        target_parameter_sample_index=np.tile(np.arange(16, 20), (12, 1)),
        partition_codes=np.asarray([1] * 6 + [2] * 4 + [3] * 2),
        example_group_ids=groups,
        normalization_mean=np.zeros(8),
        normalization_std=np.ones(8),
        metadata={},
    )


class V314ModelStudyTests(unittest.TestCase):
    def test_tracked_config_matches_executable_defaults(self) -> None:
        config = json.loads(
            (REPOSITORY / "configs" / "v31_4_model_study.json").read_text(
                encoding="utf-8"
            )
        )
        self.assertEqual(tuple(config["baselines"]), BASELINE_TYPES)
        self.assertEqual(tuple(config["trainable_models"]), MODEL_TYPES)
        self.assertEqual(
            tuple(config["sensitivity_weighted_ablation"]["weights"]),
            DEFAULT_SENSITIVITY_WEIGHTS,
        )

    def test_strong_baselines_are_finite_and_target_independent(self) -> None:
        for task in ("interpolation", "extrapolation"):
            data = fixture(task)
            changed = fixture(task)
            changed.targets[:] = 999
            for predictor in (ar_predict, kalman_predict):
                first = predictor(data, data.inputs)
                second = predictor(changed, changed.inputs)
                self.assertEqual(first.shape, data.targets.shape)
                self.assertTrue(np.all(np.isfinite(first)))
                np.testing.assert_allclose(first, second)

    def test_dlinear_and_nlinear_support_both_tasks(self) -> None:
        for task in ("interpolation", "extrapolation"):
            data = fixture(task)
            for model_type in ("dlinear", "nlinear"):
                config = TrainingConfig(
                    model_type=model_type,
                    loss_weights=(1.0,) * data.parameter_count,
                )
                model = build_model(data, config)
                output = model(torch.from_numpy(data.inputs))
                self.assertEqual(tuple(output.shape), tuple(data.targets.shape))
                self.assertEqual(
                    model.architecture_dict()["causal_extrapolation"],
                    task == "extrapolation",
                )

    def test_admission_requires_all_safeguards(self) -> None:
        groups = {"route-a": 1.0, "route-b": 1.0}
        baseline = {
            "model_type": "linear",
            "metrics": {"normalized_rmse": 1.0},
            "route_nrmse": groups,
        }
        runs = [
            {
                "seed": seed,
                "checkpoint": f"seed{seed}.pt",
                "checkpoint_sha256": str(seed),
                "metrics": {"normalized_rmse": score},
                "route_nrmse": {"route-a": score, "route-b": score},
            }
            for seed, score in enumerate((0.80, 0.81, 0.79), start=1)
        ]
        result = _aggregate_runs("gru", runs, baseline, AdmissionRules())
        self.assertTrue(result["qualification"]["passed_parameter_gate"])
        runs[0]["route_nrmse"]["route-b"] = 3.0
        failed = _aggregate_runs("gru", runs, baseline, AdmissionRules())
        self.assertFalse(failed["qualification"]["passed_parameter_gate"])

    def test_new_models_train_and_roundtrip_without_test_metrics(self) -> None:
        data = fixture()
        with tempfile.TemporaryDirectory() as temporary:
            data_path = Path(temporary) / "synthetic.h5"
            data_path.write_bytes(b"synthetic-v31-4-test")
            data = replace(data, path=data_path)
            for model_type in ("dlinear", "nlinear"):
                checkpoint, _, manifest = train_model(
                    data,
                    TrainingConfig(
                        model_type=model_type,
                        max_epochs=1,
                        patience=1,
                        batch_size=4,
                        device="cpu",
                    ),
                    Path(temporary) / model_type,
                    evaluate_test=False,
                )
                self.assertNotIn("test", manifest["metrics"])
                model, _ = load_checkpoint(checkpoint)
                prediction = predict_model(model, data.inputs[:2])
                self.assertEqual(prediction.shape, (2, 4, 8))
                frozen_prediction = _selected_prediction(
                    data,
                    {
                        "model_type": model_type,
                        "selected_checkpoint": str(checkpoint),
                        "selected_checkpoint_sha256": hashlib.sha256(
                            checkpoint.read_bytes()
                        ).hexdigest(),
                    },
                    "validation",
                    "cpu",
                )
                self.assertEqual(frozen_prediction.shape, (4, 4, 8))

    def test_selected_prediction_rejects_changed_checkpoint(self) -> None:
        data = fixture()
        with tempfile.TemporaryDirectory() as temporary:
            checkpoint = Path(temporary) / "changed.pt"
            checkpoint.write_bytes(b"not-the-frozen-checkpoint")
            selected = {
                "model_type": "dlinear",
                "selected_checkpoint": str(checkpoint),
                "selected_checkpoint_sha256": "0" * 64,
            }
            with self.assertRaisesRegex(ValueError, "checkpoint SHA-256"):
                _selected_prediction(data, selected, "validation", "cpu")

    def test_test_finalization_rejects_changed_dataset_before_loading(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            data_root = root / "data"
            data_root.mkdir()
            data_path = data_root / "step11abc_interpolation_p8.h5"
            data_path.write_bytes(b"changed-after-freeze")
            study = root / "v31_4_model_study_manifest.json"
            study.write_text(
                json.dumps(
                    {
                        "schema_version": "v3.1-4-model-study.1",
                        "tasks": {
                            "interpolation": {
                                "dataset": {
                                    "file": data_path.name,
                                    "sha256": "0" * 64,
                                },
                                "candidate_aggregates": [],
                                "selection": {"model_type": "persistence"},
                            }
                        },
                    }
                ),
                encoding="utf-8",
            )
            gate_root = root / "full_6gpcm_gate"
            gate_root.mkdir()
            gate = gate_root / "v31_4_full_6gpcm_gate.json"
            gate.write_text(
                json.dumps(
                    {
                        "schema_version": "v3.1-4-full-6gpcm-validation-gate.1",
                        "evaluation_partition": "validation",
                        "test_partition_used": False,
                        "full_6gpcm_core_modified": False,
                        "passed": True,
                        "full_6gpcm_tree_sha256_before": "same",
                        "full_6gpcm_tree_sha256_after": "same",
                        "study_manifest_sha256": hashlib.sha256(
                            study.read_bytes()
                        ).hexdigest(),
                    }
                ),
                encoding="utf-8",
            )
            with self.assertRaisesRegex(ValueError, "dataset SHA-256"):
                finalize_test_once(study, gate, data_root)

    def test_test_finalization_rejects_unbound_gate_before_reading_data(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            study = root / "v31_4_model_study_manifest.json"
            gate_root = root / "full_6gpcm_gate"
            gate_root.mkdir()
            gate = gate_root / "v31_4_full_6gpcm_gate.json"
            study.write_text(
                json.dumps({"schema_version": "v3.1-4-model-study.1", "tasks": {}}),
                encoding="utf-8",
            )
            gate.write_text(
                json.dumps(
                    {
                        "schema_version": "v3.1-4-full-6gpcm-validation-gate.1",
                        "evaluation_partition": "validation",
                        "test_partition_used": False,
                        "full_6gpcm_core_modified": False,
                        "passed": True,
                        "full_6gpcm_tree_sha256_before": "same",
                        "full_6gpcm_tree_sha256_after": "same",
                        "study_manifest_sha256": "wrong",
                    }
                ),
                encoding="utf-8",
            )
            with self.assertRaisesRegex(ValueError, "not bound"):
                finalize_test_once(study, gate, root)


if __name__ == "__main__":
    unittest.main()
