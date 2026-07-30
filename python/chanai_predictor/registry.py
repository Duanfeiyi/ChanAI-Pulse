"""Offline model registry and leakage-safe auto/manual selection."""

from __future__ import annotations

import json
import hashlib
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from .contracts import (
    REGISTRY_SCHEMA_VERSION,
    SUPPORTED_NEURAL_MODELS,
    PredictorData,
    PredictionRequest,
    TrainingConfig,
)
from .models import linear_predict, persistence_predict
from .training import evaluate_baseline, train_model


def compatibility_signature(data: PredictorData) -> dict[str, Any]:
    return {
        "task_type": data.task_type,
        "context_layout": data.context_layout,
        "parameter_names": list(data.parameter_names),
        "context_length": data.context_length,
        "target_length": data.target_length,
        "parameter_count": data.parameter_count,
    }


def request_compatibility_signature(request: PredictionRequest) -> dict[str, Any]:
    return {
        "task_type": request.task_type,
        "context_layout": request.context_layout,
        "parameter_names": list(request.parameter_names),
        "context_length": request.context_length,
        "target_length": request.target_length,
        "parameter_count": request.parameter_count,
    }


def assert_compatible(
    entry: dict[str, Any], data: PredictorData | PredictionRequest
) -> None:
    expected = (
        compatibility_signature(data)
        if isinstance(data, PredictorData)
        else request_compatibility_signature(data)
    )
    actual = entry["compatibility"]
    mismatches = [key for key, value in expected.items() if actual.get(key) != value]
    if mismatches:
        details = ", ".join(
            f"{key}: model={actual.get(key)!r}, data={expected[key]!r}"
            for key in mismatches
        )
        raise ValueError(f"Selected model is incompatible with input data ({details}).")


def train_model_family(
    data: PredictorData,
    output_directory: str | Path,
    *,
    seed: int = 20260730,
    max_epochs: int = 80,
    patience: int = 12,
    device: str = "auto",
) -> tuple[Path, dict[str, Any]]:
    """Train GRU/LSTM/TCN and freeze the ordinary-user auto choice offline."""
    output_directory = Path(output_directory).expanduser().resolve()
    output_directory.mkdir(parents=True, exist_ok=True)
    entries: list[dict[str, Any]] = []
    for model_type in SUPPORTED_NEURAL_MODELS:
        checkpoint, manifest_path, manifest = train_model(
            data,
            TrainingConfig(
                model_type=model_type,
                seed=seed,
                max_epochs=max_epochs,
                patience=patience,
                device=device,
            ),
            output_directory,
        )
        entries.append(
            {
                "model_type": model_type,
                "checkpoint": checkpoint.name,
                "manifest": manifest_path.name,
                "compatibility": compatibility_signature(data),
                "validation_metrics": manifest["metrics"]["validation"],
                "test_metrics": manifest["metrics"]["test"],
                "checkpoint_sha256": hashlib.sha256(
                    checkpoint.read_bytes()
                ).hexdigest(),
            }
        )
    for model_type, predictor in (
        ("persistence", persistence_predict),
        ("linear", linear_predict),
    ):
        entries.append(
            {
                "model_type": model_type,
                "checkpoint": None,
                "manifest": None,
                "compatibility": compatibility_signature(data),
                "validation_metrics": evaluate_baseline(data, predictor, "validation"),
                "test_metrics": evaluate_baseline(data, predictor, "test"),
            }
        )
    neural_entries = [
        entry for entry in entries if entry["model_type"] in SUPPORTED_NEURAL_MODELS
    ]
    selected = min(
        neural_entries,
        key=lambda entry: entry["validation_metrics"]["normalized_rmse"],
    )
    registry = {
        "schema_version": REGISTRY_SCHEMA_VERSION,
        "created_utc": datetime.now(timezone.utc).isoformat(),
        "selection_policy": {
            "ordinary_user": "auto",
            "metric": "validation_normalized_rmse",
            "candidate_models": list(SUPPORTED_NEURAL_MODELS),
            "target_ground_truth_used_at_prediction_time": False,
            "selected_model_type": selected["model_type"],
            "explanation": (
                "The choice was frozen from the validation partition during "
                "offline training; prediction-time target values are not read."
            ),
        },
        "compatibility": compatibility_signature(data),
        "preprocessing": {
            "method": "zscore_train_only",
            "normalization_mean": data.normalization_mean.tolist(),
            "normalization_std": data.normalization_std.tolist(),
            "parameter_bounds": data.parameter_bounds.tolist(),
        },
        "entries": entries,
    }
    path = output_directory / f"{data.task_type}_model_registry.json"
    path.write_text(
        json.dumps(registry, indent=2, ensure_ascii=False), encoding="utf-8"
    )
    return path, registry


def load_registry(path: str | Path) -> tuple[Path, dict[str, Any]]:
    path = Path(path).expanduser().resolve()
    registry = json.loads(path.read_text(encoding="utf-8"))
    if registry["schema_version"] != REGISTRY_SCHEMA_VERSION:
        raise ValueError(f"Unsupported registry schema: {registry['schema_version']}")
    return path, registry


def select_registry_entry(
    registry: dict[str, Any],
    data: PredictorData | PredictionRequest,
    selection_mode: str,
    requested_model: str | None = None,
) -> dict[str, Any]:
    if selection_mode == "auto":
        model_type = registry["selection_policy"]["selected_model_type"]
    elif selection_mode == "manual":
        if requested_model not in SUPPORTED_NEURAL_MODELS:
            raise ValueError(
                "Manual selection requires one of: "
                + ", ".join(SUPPORTED_NEURAL_MODELS)
            )
        model_type = requested_model
    else:
        raise ValueError(f"Unsupported selection mode: {selection_mode}")
    candidates = [
        entry for entry in registry["entries"] if entry["model_type"] == model_type
    ]
    if not candidates:
        raise ValueError(f"Model {model_type} is not present in this registry.")
    entry = candidates[0]
    assert_compatible(entry, data)
    return entry
