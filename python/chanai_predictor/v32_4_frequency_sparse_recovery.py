"""v3.2-4a candidate evaluation: delay-domain sparse recovery (1A).

Recovers missing in-band subcarriers by exploiting the physical structure
that a CTF is a superposition of few multipath complex exponentials:
    h(f) = sum_p a_p exp(-j 2 pi f tau_p)
so the delay-domain (IFFT) representation is (approximately) sparse. Missing
subcarriers are frequency-domain puncturing, and the known samples are

    b = F_known x ,   x sparse in the delay domain.

We solve with orthogonal matching pursuit (OMP) and reconstruct the full CTF
as F_full x_hat. Evaluation follows the v3.2-2b protocol exactly (per missing
pattern, magnitude/phase RMSE and complex NMSE on target subcarriers), so the
results are directly comparable with the published baselines (linear mag/phase,
IDW). A complex-domain linear interpolation is included as an additional fair
baseline because the product chain interpolates on complex values.

This is offline research on the Git-external corpus; it never touches the
product chain or Full 6GPCM.
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

N_OMP_DEFAULT = 16  # delay-domain support size (multipath count proxy)


def to_complex(sequence: np.ndarray) -> np.ndarray:
    return sequence[:, 0].astype(np.float64) * np.exp(
        1j * sequence[:, 1].astype(np.float64)
    )


def linear_interpolate(spectrum: FrequencySpectrum) -> np.ndarray:
    """v3.2-2b baseline: linear interpolation on (magnitude, phase)."""
    nf = spectrum.sequence.shape[0]
    out = np.zeros((nf, 2), dtype=np.float64)
    known = spectrum.known_index - 1  # 0-based
    for channel in range(2):
        values = spectrum.sequence[known, channel].astype(np.float64)
        out[:, channel] = np.interp(
            np.arange(nf), known.astype(np.float64), values
        )
    return out


def linear_complex(spectrum: FrequencySpectrum) -> np.ndarray:
    """Product baseline: linear interpolation on the complex CTF."""
    nf = spectrum.sequence.shape[0]
    h = to_complex(spectrum.sequence)
    known = (spectrum.known_index - 1).astype(np.float64)
    h_full = np.interp(np.arange(nf), known, h[known.astype(np.int64)])
    return np.column_stack((np.abs(h_full), np.angle(h_full)))


def sparse_recover(
    spectrum: FrequencySpectrum, support: int = N_OMP_DEFAULT
) -> np.ndarray:
    """Delay-domain OMP recovery from the known subcarriers.

    Returns the full [Nf, 2] (magnitude, phase) reconstruction.
    """
    nf = spectrum.sequence.shape[0]
    known = (spectrum.known_index - 1).astype(np.int64)
    b = to_complex(spectrum.sequence)[known]          # [M]
    # Orthonormal DFT dictionary rows restricted to known frequencies.
    frequencies = np.arange(nf, dtype=np.float64)
    f_known = frequencies[known]                      # [M]
    def dft_matrix(rows: np.ndarray, cols: np.ndarray) -> np.ndarray:
        return np.exp(-2j * np.pi * np.outer(rows, cols) / nf) / np.sqrt(nf)
    dictionary = dft_matrix(f_known, frequencies)     # [M, N]
    residual = b.copy()
    support_set: list[int] = []
    for _ in range(min(support, known.size - 1)):
        correlation = np.abs(dictionary.conj().T @ residual)
        candidate = int(np.argmax(correlation))
        if candidate in support_set:
            break
        support_set.append(candidate)
        cols = dictionary[:, support_set]
        coefficients = np.linalg.lstsq(cols, b, rcond=None)[0]
        residual = b - cols @ coefficients
        if np.linalg.norm(residual) <= 1e-9 * np.linalg.norm(b):
            break
    delay_response = np.zeros(nf, dtype=np.complex128)
    if support_set:
        delay_response[support_set] = np.linalg.lstsq(
            dictionary[:, support_set], b, rcond=None
        )[0]
    h_full = dft_matrix(frequencies, frequencies) @ delay_response
    return np.column_stack((np.abs(h_full), np.angle(h_full)))


def complex_nmse(truth_seq: np.ndarray, pred_seq: np.ndarray) -> float:
    truth = truth_seq[:, 0] * np.exp(1j * truth_seq[:, 1])
    pred = pred_seq[:, 0] * np.exp(1j * pred_seq[:, 1])
    return float(np.sqrt(np.mean(np.abs(pred - truth) ** 2)))


def evaluate(
    spectra: list[FrequencySpectrum], method: str, support: int = N_OMP_DEFAULT
) -> dict[str, Any]:
    mag_list: list[float] = []
    phase_list: list[float] = []
    complex_list: list[float] = []
    for spectrum in spectra:
        target_idx = spectrum.target_index - 1
        truth = spectrum.sequence[target_idx].astype(np.float64)
        if method == "linear":
            full = linear_interpolate(spectrum)
        elif method == "linear_complex":
            full = linear_complex(spectrum)
        elif method == "sparse":
            full = sparse_recover(spectrum, support=support)
        else:
            raise ValueError(f"unknown method {method}")
        pred = full[target_idx]
        mag_list.append(
            float(np.sqrt(np.mean((pred[:, 0] - truth[:, 0]) ** 2)))
        )
        phase_list.append(
            float(np.sqrt(np.mean((pred[:, 1] - truth[:, 1]) ** 2)))
        )
        complex_list.append(complex_nmse(truth, pred))
    return {
        "method": method,
        "example_count": len(spectra),
        "magnitude_rmse": float(np.mean(mag_list)),
        "phase_rmse": float(np.mean(phase_list)),
        "complex_nmse": float(np.mean(complex_list)),
    }


def main() -> None:
    spectra = load_frequency_corpus(CORPUS)
    by_pattern = split_by_pattern(spectra)
    report: dict[str, Any] = {
        "schema_version": "v3.2-4a-frequency-delay-sparse.1",
        "note": (
            "Offline candidate evaluation; sparse = delay-domain OMP. "
            "Baselines: linear (v3.2-2b mag/phase), linear_complex (product "
            "chain), idw (v3.2-2b)."
        ),
    }
    for method in ("linear", "linear_complex", "sparse"):
        report[method] = {}
        for pattern, items in by_pattern.items():
            result = evaluate(items, method)
            report[method][pattern] = result
            print(
                f"{method:>14} [{pattern}]: {result['example_count']} examples, "
                f"mag_RMSE={result['magnitude_rmse']:.4f} "
                f"phase_RMSE={result['phase_rmse']:.4f} "
                f"complex_NMSE={result['complex_nmse']:.4f}"
            )
    # Support-size sensitivity for the sparse method.
    report["sparse_sensitivity"] = {}
    for support in (8, 16, 24, 32):
        report["sparse_sensitivity"][str(support)] = {}
        for pattern, items in by_pattern.items():
            result = evaluate(items, "sparse", support=support)
            report["sparse_sensitivity"][str(support)][pattern] = result
            print(
                f"sparse(OMP={support:>2}) [{pattern}]: "
                f"complex_NMSE={result['complex_nmse']:.4f}"
            )
    out = CORPUS.parent / "v32_4a_frequency_delay_sparse.json"
    out.write_text(json.dumps(report, indent=2, ensure_ascii=False), encoding="utf-8")
    print("report:", out)


if __name__ == "__main__":
    main()
