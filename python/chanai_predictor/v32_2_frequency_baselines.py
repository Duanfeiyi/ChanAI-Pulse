"""v3.2-2b Frequency-axis baselines: linear interpolation and IDW.

Evaluates missing-subcarrier recovery on the exported Frequency corpus,
per missing pattern, using magnitude/phase reconstruction:
  - linear interpolation over known subcarriers (per channel)
  - inverse-distance-weighted (IDW) reconstruction
Metrics: per-channel normalized RMSE (magnitude/phase) and complex
(magnitude*exp(1j*phase)) NMSE, reported per pattern.
"""
from __future__ import annotations

import json
import sys
from pathlib import Path
from typing import Any

import numpy as np

REPO = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO / "python"))

from chanai_predictor.v32_2_frequency_data import (  # noqa: E402
    FrequencySpectrum,
    load_frequency_corpus,
    split_by_pattern,
)

CORPUS = Path(
    "D:/Codex_Feiyi/ChanAI-Pulse-v3.1-assets/corpora/"
    "chanaipulse-v3.2-corpus.1/frequency_inband_ctf.h5"
)


def linear_interpolate(spectrum: FrequencySpectrum) -> np.ndarray:
    """Linear interpolation on (magnitude, phase) over known subcarriers."""
    nf = spectrum.sequence.shape[0]
    out = np.zeros((nf, 2), dtype=np.float64)
    known = spectrum.known_index - 1  # 0-based
    for channel in range(2):
        values = spectrum.sequence[known, channel].astype(np.float64)
        out[:, channel] = np.interp(
            np.arange(nf), known.astype(np.float64), values
        )
    return out


def idw_reconstruct(spectrum: FrequencySpectrum, power: float = 2.0) -> np.ndarray:
    """Inverse-distance-weighted reconstruction from known subcarriers."""
    nf = spectrum.sequence.shape[0]
    known = (spectrum.known_index - 1).astype(np.float64)
    out = np.zeros((nf, 2), dtype=np.float64)
    for channel in range(2):
        values = spectrum.sequence[known.astype(np.int64), channel].astype(np.float64)
        for target in range(nf):
            if target in known:
                out[target, channel] = values[known == target][0]
                continue
            distance = np.abs(target - known)
            distance[distance < 1e-12] = 1e-12
            weight = 1.0 / distance**power
            out[target, channel] = np.sum(weight * values) / np.sum(weight)
    return out


def complex_nmse(truth_seq: np.ndarray, pred_seq: np.ndarray) -> float:
    truth = truth_seq[:, 0] * np.exp(1j * truth_seq[:, 1])
    pred = pred_seq[:, 0] * np.exp(1j * pred_seq[:, 1])
    return float(np.sqrt(np.mean(np.abs(pred - truth) ** 2)))


def evaluate(spectra: list[FrequencySpectrum], method: str) -> dict[str, Any]:
    mag_nrmse_list: list[float] = []
    phase_nrmse_list: list[float] = []
    complex_nmse_list: list[float] = []
    for spectrum in spectra:
        target_idx = spectrum.target_index - 1
        truth = spectrum.sequence[target_idx].astype(np.float64)
        full = (
            linear_interpolate(spectrum)
            if method == "linear"
            else idw_reconstruct(spectrum)
        )
        pred = full[target_idx]
        mag_nrmse = float(
            np.sqrt(np.mean(((pred[:, 0] - truth[:, 0])) ** 2))
        )
        phase_nrmse = float(
            np.sqrt(np.mean(((pred[:, 1] - truth[:, 1])) ** 2))
        )
        complex_nmse_list.append(
            complex_nmse(truth, pred)
        )
        mag_nrmse_list.append(mag_nrmse)
        phase_nrmse_list.append(phase_nrmse)
    return {
        "method": method,
        "example_count": len(spectra),
        "magnitude_rmse": float(np.mean(mag_nrmse_list)),
        "phase_rmse": float(np.mean(phase_nrmse_list)),
        "complex_nmse": float(np.mean(complex_nmse_list)),
    }


def main() -> None:
    spectra = load_frequency_corpus(CORPUS)
    by_pattern = split_by_pattern(spectra)
    report: dict[str, Any] = {"schema_version": "v3.2-2b-frequency-baselines.1"}
    for method in ("linear", "idw"):
        report[method] = {}
        for pattern, items in by_pattern.items():
            result = evaluate(items, method)
            report[method][pattern] = result
            print(f"{method} [{pattern}]: {result['example_count']} examples, "
                  f"mag_RMSE={result['magnitude_rmse']:.4f} "
                  f"phase_RMSE={result['phase_rmse']:.4f} "
                  f"complex_NMSE={result['complex_nmse']:.4f}")
    out = CORPUS.parent / "v32_2b_frequency_baselines.json"
    out.write_text(json.dumps(report, indent=2, ensure_ascii=False), encoding="utf-8")
    print("report:", out)


if __name__ == "__main__":
    main()
