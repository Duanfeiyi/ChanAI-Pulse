"""Reproducible training, evaluation, and checkpoint IO for Step 10."""

from __future__ import annotations

import copy
import hashlib
import json
import random
import sys
import time
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

import numpy as np
import torch
from torch import nn
from torch.utils.data import DataLoader, TensorDataset

from .contracts import MODEL_MANIFEST_SCHEMA_VERSION, PredictorData, TrainingConfig
from .models import SequenceRegressor, build_model, build_model_from_manifest


def set_reproducible_seed(seed: int, deterministic: bool = True) -> None:
    random.seed(seed)
    np.random.seed(seed)
    torch.manual_seed(seed)
    if torch.cuda.is_available():
        torch.cuda.manual_seed_all(seed)
    if deterministic:
        torch.use_deterministic_algorithms(True, warn_only=True)


def resolve_device(requested: str) -> torch.device:
    if requested == "auto":
        return torch.device("cuda" if torch.cuda.is_available() else "cpu")
    if requested == "cuda" and not torch.cuda.is_available():
        raise RuntimeError("CUDA was requested but is unavailable.")
    if requested not in ("cpu", "cuda"):
        raise ValueError(f"Unsupported device: {requested}")
    return torch.device(requested)


def _loader(
    data: PredictorData,
    indices: np.ndarray,
    batch_size: int,
    shuffle: bool,
    seed: int,
) -> DataLoader:
    dataset = TensorDataset(
        torch.from_numpy(data.inputs[indices]).float(),
        torch.from_numpy(data.targets[indices]).float(),
    )
    return DataLoader(
        dataset,
        batch_size=min(batch_size, max(1, len(indices))),
        shuffle=shuffle,
        generator=torch.Generator().manual_seed(seed),
    )


def predict_model(
    model: SequenceRegressor,
    inputs: np.ndarray,
    device: str | torch.device = "cpu",
    batch_size: int = 256,
) -> np.ndarray:
    target_device = torch.device(device)
    model = model.to(target_device)
    model.eval()
    values = torch.from_numpy(np.asarray(inputs, dtype=np.float32))
    outputs: list[np.ndarray] = []
    with torch.no_grad():
        for start in range(0, len(values), batch_size):
            batch = values[start : start + batch_size].to(target_device)
            outputs.append(model(batch).cpu().numpy())
    return np.concatenate(outputs, axis=0) if outputs else np.empty((0, 0, 0))


def metric_bundle(
    data: PredictorData, prediction_normalized: np.ndarray, indices: np.ndarray
) -> dict[str, Any]:
    truth = data.targets[indices].astype(np.float64)
    prediction = np.asarray(prediction_normalized, dtype=np.float64)
    if prediction.shape != truth.shape:
        raise ValueError(
            f"Prediction shape {prediction.shape} does not match truth {truth.shape}."
        )
    error = prediction - truth
    normalized_rmse = float(np.sqrt(np.mean(error**2)))
    per_parameter = np.sqrt(np.mean(error**2, axis=(0, 1)))
    truth_raw = data.denormalize(truth, project_bounds=False)
    prediction_raw = data.denormalize(prediction, project_bounds=False)
    raw_rmse = np.sqrt(np.mean((prediction_raw - truth_raw) ** 2, axis=(0, 1)))
    return {
        "normalized_rmse": normalized_rmse,
        "per_parameter_normalized_rmse": per_parameter.tolist(),
        "raw_rmse": {
            name: float(value)
            for name, value in zip(data.parameter_names, raw_rmse, strict=True)
        },
        "example_count": int(len(indices)),
    }


def train_model(
    data: PredictorData,
    config: TrainingConfig,
    output_directory: str | Path,
    *,
    evaluate_test: bool = True,
) -> tuple[Path, Path, dict[str, Any]]:
    """Train one neural model with train-only updates and validation stopping."""
    config.validate()
    train_indices = data.partition_indices("train")
    validation_indices = data.partition_indices("validation")
    if len(train_indices) == 0 or len(validation_indices) == 0:
        raise ValueError("Training and validation partitions must both be non-empty.")
    set_reproducible_seed(config.seed, config.deterministic)
    device = resolve_device(config.device)
    model = build_model(data, config).to(device)
    optimizer = torch.optim.Adam(
        model.parameters(),
        lr=config.learning_rate,
        weight_decay=config.weight_decay,
    )
    loss_function = nn.MSELoss()
    train_loader = _loader(
        data, train_indices, config.batch_size, True, config.seed
    )
    validation_inputs = torch.from_numpy(data.inputs[validation_indices]).float().to(
        device
    )
    validation_targets = torch.from_numpy(
        data.targets[validation_indices]
    ).float().to(device)
    best_state = copy.deepcopy(model.state_dict())
    best_validation_loss = float("inf")
    best_epoch = 0
    patience_count = 0
    history: list[dict[str, float | int]] = []
    started = time.perf_counter()
    for epoch in range(1, config.max_epochs + 1):
        model.train()
        train_loss_sum = 0.0
        train_example_count = 0
        for batch_inputs, batch_targets in train_loader:
            batch_inputs = batch_inputs.to(device)
            batch_targets = batch_targets.to(device)
            optimizer.zero_grad(set_to_none=True)
            loss = loss_function(model(batch_inputs), batch_targets)
            loss.backward()
            optimizer.step()
            train_loss_sum += float(loss.item()) * len(batch_inputs)
            train_example_count += len(batch_inputs)
        model.eval()
        with torch.no_grad():
            validation_loss = float(
                loss_function(model(validation_inputs), validation_targets).item()
            )
        train_loss = train_loss_sum / max(1, train_example_count)
        history.append(
            {
                "epoch": epoch,
                "train_mse": train_loss,
                "validation_mse": validation_loss,
            }
        )
        if validation_loss < best_validation_loss - config.min_delta:
            best_validation_loss = validation_loss
            best_epoch = epoch
            best_state = copy.deepcopy(model.state_dict())
            patience_count = 0
        else:
            patience_count += 1
            if patience_count >= config.patience:
                break
    elapsed = time.perf_counter() - started
    model.load_state_dict(best_state)
    validation_prediction = predict_model(model, data.inputs[validation_indices], device)
    metrics = {
        "validation": metric_bundle(data, validation_prediction, validation_indices)
    }
    if evaluate_test:
        test_indices = data.partition_indices("test")
        test_prediction = predict_model(model, data.inputs[test_indices], device)
        metrics["test"] = metric_bundle(data, test_prediction, test_indices)
    manifest = {
        "schema_version": MODEL_MANIFEST_SCHEMA_VERSION,
        "created_utc": datetime.now(timezone.utc).isoformat(),
        "dataset": {
            "file_name": data.path.name,
            "sha256": hashlib.sha256(data.path.read_bytes()).hexdigest(),
            "task_type": data.task_type,
            "context_layout": data.context_layout,
            "parameter_names": list(data.parameter_names),
            "parameter_units": list(data.parameter_units),
            "context_length": data.context_length,
            "target_length": data.target_length,
            "parameter_count": data.parameter_count,
        },
        "architecture": model.architecture_dict(),
        "training": {
            "best_epoch": best_epoch,
            "epochs_completed": len(history),
            "best_validation_mse": best_validation_loss,
            "elapsed_seconds": elapsed,
            "device": str(device),
            "runtime": {
                "python": sys.version.split()[0],
                "numpy": np.__version__,
                "torch": str(torch.__version__),
            },
            "history": history,
        },
        "metrics": metrics,
    }
    output_directory = Path(output_directory).expanduser().resolve()
    output_directory.mkdir(parents=True, exist_ok=True)
    stem = f"{data.task_type}_{config.model_type}_seed{config.seed}"
    checkpoint_path = output_directory / f"{stem}.pt"
    manifest_path = output_directory / f"{stem}.json"
    torch.save(
        {
            "schema_version": MODEL_MANIFEST_SCHEMA_VERSION,
            "state_dict": model.cpu().state_dict(),
            "manifest": manifest,
        },
        checkpoint_path,
    )
    manifest_path.write_text(
        json.dumps(manifest, indent=2, ensure_ascii=False), encoding="utf-8"
    )
    return checkpoint_path, manifest_path, manifest


def load_checkpoint(
    checkpoint_path: str | Path, device: str | torch.device = "cpu"
) -> tuple[SequenceRegressor, dict[str, Any]]:
    checkpoint_path = Path(checkpoint_path).expanduser().resolve()
    try:
        payload = torch.load(
            checkpoint_path, map_location=torch.device(device), weights_only=True
        )
    except TypeError:
        payload = torch.load(checkpoint_path, map_location=torch.device(device))
    manifest = payload["manifest"]
    if manifest["schema_version"] != MODEL_MANIFEST_SCHEMA_VERSION:
        raise ValueError(
            f"Unsupported model manifest schema: {manifest['schema_version']}"
        )
    model = build_model_from_manifest(manifest)
    model.load_state_dict(payload["state_dict"])
    model.to(torch.device(device))
    model.eval()
    return model, manifest


def evaluate_baseline(data: PredictorData, predictor: Any, partition: str) -> dict[str, Any]:
    indices = data.partition_indices(partition)
    return metric_bundle(data, predictor(data, data.inputs[indices]), indices)
