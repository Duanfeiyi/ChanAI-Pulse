"""v3.2-2b Frequency-axis neural study (full-sequence denoising, method A).

Input:  [N, 64, 2] magnitude/phase sequence with target subcarriers zeroed.
Output: [N, 64, 2] full recovered sequence; loss computed only on target
        subcarriers. Compares GRU/LSTM/TCN against the linear-interpolation
        baseline (per missing pattern), following the v3.1 admission rules.
"""
from __future__ import annotations

import hashlib
import json
import sys
from dataclasses import asdict
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

import numpy as np
import torch

REPO = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO / "python"))

from chanai_predictor.contracts import TrainingConfig  # noqa: E402
from chanai_predictor.data import load_predictor_data_hdf5  # noqa: E402
from chanai_predictor.training import (  # noqa: E402
    metric_bundle,
    predict_model,
    set_reproducible_seed,
    train_model,
)
from chanai_predictor.v32_2_frequency_data import (  # noqa: E402
    FrequencySpectrum,
    load_frequency_corpus,
    split_by_pattern,
)

CORPUS = Path(
    "D:/Codex_Feiyi/ChanAI-Pulse-v3.1-assets/corpora/"
    "chanaipulse-v3.2-corpus.1/frequency_inband_ctf.h5"
)

NF = 64
CHANNELS = 2
MODEL_TYPES = ("gru", "lstm", "tcn")
SEEDS = (95101, 95102, 95103)


class FrequencyDenoiseDataset:
    """Tensor dataset: input zeroed-at-target sequence, output full sequence."""

    def __init__(self, spectra: list[FrequencySpectrum]):
        self.inputs = np.zeros((len(spectra), NF, CHANNELS), dtype=np.float32)
        self.targets = np.zeros((len(spectra), NF, CHANNELS), dtype=np.float32)
        self.mask = np.zeros((len(spectra), NF), dtype=np.float32)
        self.groups = []
        for index, spectrum in enumerate(spectra):
            self.inputs[index] = spectrum.sequence
            self.targets[index] = spectrum.sequence
            target_idx = spectrum.target_index - 1
            self.inputs[index, target_idx, :] = 0.0
            self.mask[index, target_idx] = 1.0
            self.groups.append(f"{spectrum.pattern}-{spectrum.spectrum_id}")

    def split(self, fractions: tuple[float, float, float]) -> tuple[Any, Any, Any]:
        count = len(self.groups)
        n_train = int(count * fractions[0])
        n_val = int(count * fractions[1])
        indices = np.arange(count)
        return (
            self._slice(indices[:n_train]),
            self._slice(indices[n_train : n_train + n_val]),
            self._slice(indices[n_train + n_val :]),
        )

    def _slice(self, indices: np.ndarray) -> "FrequencyDenoiseDataset":
        subset = FrequencyDenoiseDataset.__new__(FrequencyDenoiseDataset)
        subset.inputs = self.inputs[indices]
        subset.targets = self.targets[indices]
        subset.mask = self.mask[indices]
        subset.groups = [self.groups[i] for i in indices]
        return subset


def complex_nmse(pred: np.ndarray, truth: np.ndarray, mask: np.ndarray) -> float:
    pred_c = pred[:, :, 0] * np.exp(1j * pred[:, :, 1])
    truth_c = truth[:, :, 0] * np.exp(1j * truth[:, :, 1])
    masked = np.abs(pred_c - truth_c) * mask
    return float(np.sqrt(np.sum(masked**2) / max(1e-12, np.sum(mask))))


def evaluate_denoise(
    model: torch.nn.Module,
    dataset: FrequencyDenoiseDataset,
    device: str,
) -> dict[str, Any]:
    prediction = predict_model(model, dataset.inputs, device)
    mag_rmse = float(np.sqrt(np.mean(
        ((prediction - dataset.targets) * dataset.mask[:, :, None]) ** 2
    ) * len(dataset.mask) / max(1e-12, np.sum(dataset.mask))))
    phase_error = (prediction - dataset.targets)[:, :, 1] * dataset.mask
    phase_rmse = float(np.sqrt(np.sum(phase_error**2) / max(
        1e-12, np.sum(dataset.mask)
    )))
    return {
        "magnitude_rmse": mag_rmse,
        "phase_rmse": phase_rmse,
        "complex_nmse": complex_nmse(prediction, dataset.targets, dataset.mask),
    }


def run_study(
    output_directory: str | Path,
    *,
    device: str = "cpu",
) -> tuple[Path, dict[str, Any]]:
    output_directory = Path(output_directory).expanduser().resolve()
    if output_directory.exists():
        raise FileExistsError(f"Refusing to overwrite: {output_directory}")
    output_directory.mkdir(parents=True)

    spectra = load_frequency_corpus(CORPUS)
    by_pattern = split_by_pattern(spectra)

    results: dict[str, Any] = {}
    for pattern, items in by_pattern.items():
        dataset = FrequencyDenoiseDataset(items)
        train_set, val_set, test_set = dataset.split((0.7, 0.15, 0.15))
        pattern_results: dict[str, Any] = {}
        for model_type in MODEL_TYPES:
            runs = []
            for seed in SEEDS:
                config = TrainingConfig(
                    model_type=model_type,
                    seed=int(seed),
                    hidden_size=32,
                    num_layers=1,
                    tcn_channels=32,
                    kernel_size=3,
                    learning_rate=1e-3,
                    batch_size=64,
                    max_epochs=60,
                    patience=10,
                    device=device,
                )
                run_root = output_directory / pattern / model_type / f"seed{seed}"
                run_root.mkdir(parents=True, exist_ok=True)
                run = _train_denoise(train_set, val_set, config, run_root)
                test_metrics = evaluate_denoise(run["model"], test_set, device)
                runs.append({**run["summary"], "test": test_metrics})
            pattern_results[model_type] = {
                "runs": runs,
                "mean_validation_complex_nmse": float(np.mean([
                    r["validation"]["complex_nmse"] for r in runs
                ])),
            }
        results[pattern] = pattern_results

    manifest = {
        "schema_version": "v3.2-2b-frequency-neural-study.1",
        "created_utc": datetime.now(timezone.utc).isoformat(),
        "corpus_file": str(CORPUS),
        "method": "full_sequence_denoising_missing_zeroed",
        "nf": NF,
        "channels": CHANNELS,
        "models": list(MODEL_TYPES),
        "seeds": list(SEEDS),
        "patterns": results,
    }
    path = output_directory / "v32_2b_frequency_study_manifest.json"
    path.write_text(json.dumps(manifest, indent=2, ensure_ascii=False), encoding="utf-8")
    return path, manifest


def _train_denoise(
    train_set: FrequencyDenoiseDataset,
    val_set: FrequencyDenoiseDataset,
    config: TrainingConfig,
    run_root: Path,
) -> dict[str, Any]:
    from chanai_predictor.models import SequenceRegressor

    set_reproducible_seed(config.seed, config.deterministic)
    device = torch.device(config.device)
    model = SequenceRegressor(
        config.model_type, "extrapolation", CHANNELS, NF, NF, config
    ).to(device)
    optimizer = torch.optim.Adam(
        model.parameters(), lr=config.learning_rate, weight_decay=config.weight_decay
    )
    loss_function = torch.nn.MSELoss(reduction="none")
    train_inputs = torch.from_numpy(train_set.inputs).float().to(device)
    train_targets = torch.from_numpy(train_set.targets).float().to(device)
    train_mask = torch.from_numpy(train_set.mask).float().to(device)
    val_inputs = torch.from_numpy(val_set.inputs).float().to(device)
    val_targets = torch.from_numpy(val_set.targets).float().to(device)
    val_mask = torch.from_numpy(val_set.mask).float().to(device)

    best_state = None
    best_val_loss = float("inf")
    patience_count = 0
    best_epoch = 0
    import time

    started = time.perf_counter()
    count = len(train_set.inputs)
    for epoch in range(1, config.max_epochs + 1):
        model.train()
        permutation = np.random.permutation(count)
        for start in range(0, count, config.batch_size):
            batch_idx = permutation[start : start + config.batch_size]
            inputs = train_inputs[batch_idx]
            targets = train_targets[batch_idx]
            mask = train_mask[batch_idx]
            optimizer.zero_grad(set_to_none=True)
            prediction = model(inputs)
            loss = (
                loss_function(prediction, targets).mean(dim=-1) * mask
            ).sum() / max(1.0, mask.sum())
            loss.backward()
            optimizer.step()
        model.eval()
        with torch.no_grad():
            val_pred = model(val_inputs)
            val_loss = (
                loss_function(val_pred, val_targets).mean(dim=-1) * val_mask
            ).sum() / max(1.0, val_mask.sum())
            val_loss = float(val_loss.item())
        if val_loss < best_val_loss - config.min_delta:
            best_val_loss = val_loss
            best_epoch = epoch
            best_state = {k: v.detach().cpu().clone() for k, v in model.state_dict().items()}
            patience_count = 0
        else:
            patience_count += 1
            if patience_count >= config.patience:
                break
    elapsed = time.perf_counter() - started
    model.load_state_dict(best_state)
    val_pred_np = predict_model(model, val_set.inputs, config.device)
    val_metrics = {
        "magnitude_rmse": float(np.sqrt(np.mean(
            ((val_pred_np - val_set.targets) * val_set.mask[:, :, None]) ** 2
        ) * len(val_set.mask) / max(1e-12, np.sum(val_set.mask)))),
        "phase_rmse": float(np.sqrt(np.sum(
            ((val_pred_np - val_set.targets)[:, :, 1] * val_set.mask) ** 2
        ) / max(1e-12, np.sum(val_set.mask)))),
        "complex_nmse": complex_nmse(val_pred_np, val_set.targets, val_set.mask),
    }
    checkpoint_path = run_root / f"extrapolation_{config.model_type}_seed{config.seed}.pt"
    torch.save(
        {"state_dict": model.cpu().state_dict(), "config": config.to_dict()},
        checkpoint_path,
    )
    return {
        "model": model,
        "summary": {
            "seed": config.seed,
            "config": config.to_dict(),
            "best_epoch": best_epoch,
            "elapsed_seconds": elapsed,
            "checkpoint": str(checkpoint_path),
            "checkpoint_sha256": hashlib.sha256(
                checkpoint_path.read_bytes()
            ).hexdigest(),
            "validation": val_metrics,
        },
    }


if __name__ == "__main__":
    out = Path(
        "D:/Codex_Feiyi/ChanAI-Pulse-v3.1-assets/experiments/"
        "v32_2b_frequency_study.1"
    )
    manifest_path, manifest = run_study(out, device="cpu")
    print("manifest:", manifest_path)
    for pattern, models in manifest["patterns"].items():
        for model_type, data in models.items():
            print(f"{pattern} {model_type}: "
                  f"val complex_NMSE={data['mean_validation_complex_nmse']:.4f}")
