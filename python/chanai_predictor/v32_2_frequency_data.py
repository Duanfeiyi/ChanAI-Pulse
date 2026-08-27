"""v3.2-2b Frequency-axis data loader (plain-numeric HDF5).

Reads the exported `frequency_inband_ctf.h5` (no MATLAB cell arrays):
  /ctf_real, /ctf_imag  [360, Nf, Rx, Tx] double
  /pattern, /scenario   [360, W] uint8 utf-8
  /known_index, /target_index [360, K] double (NaN-padded)
  /frequency_hz         [360, Nf] double
Each spectrum's per-(tx,rx) spatial link becomes an [Nf, 2] (magnitude, phase)
sequence, keeping known/target subcarrier indices and the pattern label.
"""
from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path

import h5py
import numpy as np


@dataclass(frozen=True)
class FrequencySpectrum:
    """One in-band CTF spatial link with a labelled missing pattern."""

    sequence: np.ndarray          # [Nf, 2] float32 (magnitude, phase)
    known_index: np.ndarray       # int64 known subcarriers (1-based)
    target_index: np.ndarray      # int64 target subcarriers (1-based)
    frequency_hz: np.ndarray      # [Nf] float64
    pattern: str
    scenario: str
    tx: int
    rx: int
    spectrum_id: int


def _decode_strings(rows: np.ndarray) -> list[str]:
    """Decode a [N, W] uint8 utf-8 array into strings."""
    result = []
    for row in rows:
        raw = np.asarray(row, dtype=np.uint8).reshape(-1)
        result.append(raw.tobytes().decode("utf-8", errors="replace").rstrip("\x00"))
    return result


def load_frequency_corpus(
    h5_path: str | Path,
) -> list[FrequencySpectrum]:
    """Load the exported Frequency corpus into per-(tx,rx) sequences."""
    h5_path = Path(h5_path).expanduser().resolve()
    spectra: list[FrequencySpectrum] = []
    with h5py.File(str(h5_path), "r") as handle:
        real = np.asarray(handle["/ctf_real"], dtype=np.float64)
        imag = np.asarray(handle["/ctf_imag"], dtype=np.float64)
        ctf = real + 1j * imag                       # [N, Nf, Rx, Tx]
        known = np.asarray(handle["/known_index"], dtype=np.float64)
        target = np.asarray(handle["/target_index"], dtype=np.float64)
        freq = np.asarray(handle["/frequency_hz"], dtype=np.float64)
        patterns = _decode_strings(np.asarray(handle["/pattern"]))
        scenarios = _decode_strings(np.asarray(handle["/scenario"]))
        count, nf, rx_count, tx_count = ctf.shape
        for index in range(count):
            known_idx = known[index]
            target_idx = target[index]
            known_clean = known_idx[~np.isnan(known_idx)].astype(np.int64)
            target_clean = target_idx[~np.isnan(target_idx)].astype(np.int64)
            for tx in range(tx_count):
                for rx in range(rx_count):
                    values = ctf[index, :, rx, tx]
                    magnitude = np.abs(values)
                    phase = np.angle(values)
                    sequence = np.column_stack(
                        (magnitude, phase)
                    ).astype(np.float32)
                    spectra.append(FrequencySpectrum(
                        sequence=sequence,
                        known_index=known_clean,
                        target_index=target_clean,
                        frequency_hz=freq[index],
                        pattern=patterns[index],
                        scenario=scenarios[index],
                        tx=tx,
                        rx=rx,
                        spectrum_id=index,
                    ))
    return spectra


def split_by_pattern(
    spectra: list[FrequencySpectrum],
) -> dict[str, list[FrequencySpectrum]]:
    grouped: dict[str, list[FrequencySpectrum]] = {}
    for item in spectra:
        grouped.setdefault(item.pattern, []).append(item)
    return grouped


def main() -> None:
    path = Path(
        "D:/Codex_Feiyi/ChanAI-Pulse-v3.1-assets/corpora/"
        "chanaipulse-v3.2-corpus.1/frequency_inband_ctf.h5"
    )
    spectra = load_frequency_corpus(path)
    print(f"total per-(tx,rx) sequences: {len(spectra)}")
    by_pattern = split_by_pattern(spectra)
    for pattern, items in by_pattern.items():
        print(f"  {pattern}: {len(items)} sequences")
    first = spectra[0]
    print(f"example: tx={first.tx} rx={first.rx} pattern={first.pattern} "
          f"scenario={first.scenario}")
    print(f"  sequence shape: {first.sequence.shape} dtype={first.sequence.dtype}")
    print(f"  known count={len(first.known_index)} "
          f"target count={len(first.target_index)}")
    print(f"  magnitude range [{first.sequence[:, 0].min():.4f}, "
          f"{first.sequence[:, 0].max():.4f}]")
    print(f"  phase range [{first.sequence[:, 1].min():.3f}, "
          f"{first.sequence[:, 1].max():.3f}] rad")
    print("LOAD OK")


if __name__ == "__main__":
    main()
