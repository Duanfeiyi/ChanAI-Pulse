"""Minimal v3.2-2 smoke: train one GRU on the Time axis, verify the chain.

Runs a single model on a single seed to confirm the corpus loads and the
reused training machinery works end-to-end. Not a formal study.
"""

from __future__ import annotations

import json
import sys
import tempfile
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO / "python"))

from chanai_predictor.contracts import TrainingConfig  # noqa: E402
from chanai_predictor.data import load_predictor_data_hdf5  # noqa: E402
from chanai_predictor.v31_4 import _baseline_entries, _train_and_measure  # noqa: E402
from chanai_predictor.training import metric_bundle  # noqa: E402

CORPUS = Path(
    "D:/Codex_Feiyi/ChanAI-Pulse-v3.1-assets/corpora/chanaipulse-v3.2-corpus.1"
)


def main() -> int:
    data = load_predictor_data_hdf5(CORPUS / "time_extrapolation_ds_kf.h5")
    baselines = _baseline_entries(data, "validation")
    best = min(baselines, key=lambda e: e["metrics"]["normalized_rmse"])
    print(f"best baseline on validation: {best['model_type']} "
          f"NRMSE={best['metrics']['normalized_rmse']:.6f}")

    with tempfile.TemporaryDirectory() as temporary:
        root = Path(temporary)
        config = TrainingConfig(
            model_type="gru", seed=94101, device="cpu",
            hidden_size=16, num_layers=1, max_epochs=10, patience=3,
        )
        result = _train_and_measure(
            data, config, root / "time" / "search" / "gru"
        )
        checkpoint = Path(result["checkpoint"])
        print("result keys:", sorted(result.keys()))
        metrics = result["metrics"]
        training = result["training"]
        print(f"gru trained: best_epoch={training['best_epoch']}, "
              f"validation NRMSE={metrics['normalized_rmse']:.6f}")
        assert checkpoint.is_file(), "checkpoint missing"
        print("SMOKE PASS: corpus loads, baseline scores, GRU trains, "
              "checkpoint+manifest written.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
