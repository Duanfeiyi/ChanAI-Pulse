from __future__ import annotations

import csv
import tempfile
import unittest
from pathlib import Path

import numpy as np

from chanai_predictor.contracts import PredictorData
from chanai_predictor.step11abc import P8_PARAMETER_NAMES, write_end_to_end_pairs


def _data(path: Path, names: tuple[str, ...]) -> PredictorData:
    example_count = 6
    context_length = 16
    target_length = 4
    parameter_count = len(names)
    targets = np.arange(
        example_count * target_length * parameter_count, dtype=np.float32
    ).reshape(example_count, target_length, parameter_count)
    return PredictorData(
        path=path,
        task_type="extrapolation",
        context_layout="past_context",
        parameter_names=names,
        parameter_units=tuple("unit" for _ in names),
        parameter_bounds=np.column_stack(
            (np.full(parameter_count, -1e6), np.full(parameter_count, 1e6))
        ),
        inputs=np.zeros((example_count, context_length, parameter_count), np.float32),
        targets=targets,
        target_parameter_sample_index=np.arange(
            example_count * target_length, dtype=np.int64
        ).reshape(example_count, target_length),
        partition_codes=np.asarray([1, 1, 2, 2, 3, 3], dtype=np.uint8),
        example_group_ids=("train-a", "train-b", "val-a", "val-b", "test-a", "test-b"),
        normalization_mean=np.zeros(parameter_count),
        normalization_std=np.ones(parameter_count),
        metadata={},
    )


class Step11AbcPairContractTests(unittest.TestCase):
    def test_validation_pair_contains_predictions_but_no_filled_defaults(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            p2 = _data(root / "p2.h5", P8_PARAMETER_NAMES[:2])
            p8 = _data(root / "p8.h5", P8_PARAMETER_NAMES)
            indices = p2.partition_indices("validation")
            prediction = p2.targets[indices]
            path = write_end_to_end_pairs(
                p2,
                p8,
                indices,
                prediction,
                root,
                partition="validation",
            )
            with path.open(newline="", encoding="utf-8") as handle:
                row = next(csv.DictReader(handle))
            self.assertEqual(row["partition"], "validation")
            self.assertIn("predicted_DS_mu", row)
            self.assertIn("predicted_KF_mu", row)
            self.assertNotIn("predicted_DS_sigma", row)
            self.assertFalse(any(name.startswith("generated_") for name in row))
            self.assertTrue(all(f"truth_{name}" in row for name in P8_PARAMETER_NAMES))


if __name__ == "__main__":
    unittest.main()
