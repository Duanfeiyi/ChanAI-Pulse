"""v3.1-7 product P8 safety-gate unit tests."""

from __future__ import annotations

import sys
import unittest
from pathlib import Path

import numpy as np

REPO_ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO_ROOT / "python"))

from chanai_predictor.product_gate import (  # noqa: E402
    _backtest_examples,
    _continuity,
    _freeze_imputed,
    _score,
)
from chanai_predictor.flexible_forecast import (  # noqa: E402
    forecast_classical,
    make_backtests,
)
from chanai_predictor.flexible_product_gate import run_product_gate  # noqa: E402


class V317ProductGateTests(unittest.TestCase):
    def test_twenty_four_known_rows_create_five_target_free_backtests(self) -> None:
        values = np.arange(24 * 8, dtype=np.float64).reshape(24, 8)
        indices = np.arange(2, 26, dtype=np.float64)
        groups = np.repeat("known-segment-1", 24)
        inputs, targets, input_indices, target_indices = _backtest_examples(
            values, indices, groups, "extrapolation"
        )
        self.assertEqual(inputs.shape, (5, 16, 8))
        self.assertEqual(targets.shape, (5, 4, 8))
        self.assertTrue(np.all(input_indices < target_indices[:, :1]))

    def test_imputed_parameters_are_frozen_to_known_anchor(self) -> None:
        inputs = np.arange(16 * 8, dtype=np.float64).reshape(1, 16, 8)
        prediction = np.full((1, 4, 8), 999.0)
        imputed = np.asarray([2, 3, 4, 5, 7])
        frozen = _freeze_imputed(
            prediction, inputs, "extrapolation", imputed
        )
        expected = np.repeat(inputs[:, -1:, imputed], 4, axis=1)
        np.testing.assert_allclose(frozen[:, :, imputed], expected)
        np.testing.assert_allclose(frozen[:, :, [0, 1, 6]], 999.0)

    def test_score_gate_evaluates_only_locally_identifiable_columns(self) -> None:
        truth = np.zeros((2, 4, 8))
        prediction = truth.copy()
        prediction[:, :, 2:] = 1000.0
        score = _score(
            prediction, truth, np.ones(8), np.asarray([0, 1])
        )
        self.assertEqual(score["normalized_rmse"], 0.0)
        self.assertGreater(score["per_parameter_normalized_rmse"][2], 0.0)

    def test_interpolation_checks_both_prediction_boundaries(self) -> None:
        context = np.zeros((16, 8))
        prediction = np.zeros((1, 4, 8))
        prediction[:, :, 0] = 1.0
        result = _continuity(
            context, prediction, np.ones(8), 4.0, "interpolation"
        )
        self.assertFalse(result["passed"])
        self.assertEqual(
            result["checked_boundaries"],
            ["known_left_to_prediction", "prediction_to_known_right"],
        )

    def test_arbitrary_horizon_harmonic_extrapolation_follows_curve(self) -> None:
        known_index = np.arange(60.0)
        target_index = np.arange(60.0, 72.0)
        known = np.column_stack([
            np.sin(known_index / 6 + phase) for phase in np.arange(8)
        ])
        truth = np.column_stack([
            np.sin(target_index / 6 + phase) for phase in np.arange(8)
        ])
        prediction = forecast_classical(
            "harmonic", known, known_index, target_index
        )
        self.assertEqual(prediction.shape, (12, 8))
        self.assertLess(float(np.sqrt(np.mean((prediction - truth) ** 2))), 0.25)

    def test_arbitrary_interpolation_uses_both_sides(self) -> None:
        target_index = np.arange(25.0, 35.0)
        left_index = np.arange(25.0)
        right_index = np.arange(35.0, 60.0)
        left = np.column_stack([
            np.sin(left_index / 6 + phase) for phase in np.arange(8)
        ])
        right = np.column_stack([
            np.sin(right_index / 6 + phase) for phase in np.arange(8)
        ])
        truth = np.column_stack([
            np.sin(target_index / 6 + phase) for phase in np.arange(8)
        ])
        prediction = forecast_classical(
            "harmonic", left, left_index, target_index,
            right_values=right, right_indices=right_index,
        )
        self.assertEqual(prediction.shape, (10, 8))
        self.assertLess(float(np.sqrt(np.mean((prediction - truth) ** 2))), 0.05)

    def test_backtest_uses_full_prefix_and_matches_requested_horizon(self) -> None:
        values = np.arange(60 * 8, dtype=np.float64).reshape(60, 8)
        indices = np.arange(1, 61, dtype=np.float64)
        examples, contract = make_backtests(
            values, indices, np.repeat("route", 60), "extrapolation", 9
        )
        self.assertTrue(contract["horizon_matched"])
        self.assertEqual(len(examples[-1].target_indices), 9)
        self.assertGreater(len(examples[-1].left_indices), 16)

    def test_manual_poor_performance_warns_but_arbitrary_horizon_runs(self) -> None:
        index = np.arange(1.0, 61.0)
        values = np.tile(
            np.asarray([-7.0, 5.0, 0.35, 1.6, 2.6, 3.3, 10.0, 20.0]),
            (60, 1),
        )
        values[:, 0] += 0.20 * np.sin(index / 6)
        values[:, 1] += 2.00 * np.sin(index / 6 + 0.5)
        values[:, 6] += np.round(2.00 * np.sin(index / 6 + 1.0))
        registry = REPO_ROOT / "models" / "official" / "v3.1.0" / (
            "extrapolation"
        ) / "extrapolation_model_registry_v2.json"
        result = run_product_gate({
            "task_type": "extrapolation",
            "parameter_names": [
                "DS_mu", "KF_mu", "DS_sigma", "KF_sigma", "r_DS",
                "LNS_ksi", "num_clusters", "num_rays",
            ],
            "parameter_units": [
                "log10_s", "dB", "log10_s_std", "dB", "dimensionless",
                "dB", "count", "count",
            ],
            "known_values": values.tolist(),
            "known_parameter_sample_index": index.tolist(),
            "known_group_id": ["route"] * len(index),
            "known_quality_status": ["PASS"] * len(index),
            "locally_observed_parameter_names": [
                "DS_mu", "KF_mu", "num_clusters",
            ],
            "imputed_parameter_names": [
                "DS_sigma", "KF_sigma", "r_DS", "LNS_ksi", "num_rays",
            ],
            "target_parameter_sample_index": np.arange(61, 74).tolist(),
            "selection_mode": "manual",
            "requested_model": "persistence",
            "device": "cpu",
            "registry_path": str(registry),
        })
        self.assertEqual(np.asarray(result["prediction_parameters"]).shape, (1, 13, 8))
        self.assertEqual(len(result["known_context_parameters"]), 60)
        self.assertTrue(any("worse than" in item for item in result["warnings"]))
        self.assertTrue(result["stabilization"]["applied"])
        self.assertTrue(result["backtest"]["stabilized_selected_score"]["available"])


if __name__ == "__main__":
    unittest.main()
