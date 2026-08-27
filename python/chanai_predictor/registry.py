"""Offline model registry and leakage-safe auto/manual selection."""

from __future__ import annotations

import hashlib
import json
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from .contracts import (
    REGISTRY_SCHEMA_VERSION,
    REGISTRY_V2_SCHEMA_VERSION,
    SUPPORTED_MODELS,
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
        "parameter_units": list(data.parameter_units),
        "context_length": data.context_length,
        "target_length": data.target_length,
        "parameter_count": data.parameter_count,
    }


def request_compatibility_signature(request: PredictionRequest) -> dict[str, Any]:
    return {
        "task_type": request.task_type,
        "context_layout": request.context_layout,
        "parameter_names": list(request.parameter_names),
        "parameter_units": list(request.parameter_units),
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
    required = (
        "task_type",
        "context_layout",
        "parameter_names",
        "context_length",
        "target_length",
        "parameter_count",
    )
    compared = list(required)
    if "parameter_units" in actual:
        compared.append("parameter_units")
    mismatches = [key for key in compared if actual.get(key) != expected[key]]
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
    if registry["schema_version"] not in (
        REGISTRY_SCHEMA_VERSION,
        REGISTRY_V2_SCHEMA_VERSION,
    ):
        raise ValueError(f"Unsupported registry schema: {registry['schema_version']}")
    if registry["schema_version"] == REGISTRY_V2_SCHEMA_VERSION:
        _validate_v2_registry(registry)
    return path, registry


def _validate_v2_registry(registry: dict[str, Any]) -> None:
    bundle = registry.get("parameter_bundle")
    if bundle not in ("P8", "V3_2_DS_KF"):
        raise ValueError(
            "ModelRegistry v2 requires a known parameter bundle "
            "(P8 or V3_2_DS_KF)."
        )
    compatibility = registry.get("compatibility", {})
    if compatibility.get("parameter_bundle") not in ("P8", "V3_2_DS_KF"):
        raise ValueError(
            "ModelRegistry v2 compatibility must declare a known bundle."
        )
    preprocessing = registry.get("preprocessing", {})
    parameter_count = compatibility.get("parameter_count")
    if not isinstance(parameter_count, int) or parameter_count < 1:
        raise ValueError("ModelRegistry v2 parameter count is invalid.")
    if any(
        len(preprocessing.get(name, [])) != parameter_count
        for name in ("normalization_mean", "normalization_std", "parameter_bounds")
    ):
        raise ValueError(
            "ModelRegistry v2 preprocessing does not match parameter count."
        )
    entries = registry.get("entries")
    if not isinstance(entries, list) or not entries:
        raise ValueError("ModelRegistry v2 must contain model entries.")
    model_types = [entry.get("model_type") for entry in entries]
    if len(model_types) != len(set(model_types)):
        raise ValueError("ModelRegistry v2 contains duplicate model types.")
    model_ids = [entry.get("model_id") for entry in entries]
    if len(model_ids) != len(set(model_ids)):
        raise ValueError("ModelRegistry v2 contains duplicate model IDs.")
    selected = registry.get("selection_policy", {}).get("selected_model_type")
    if selected not in model_types:
        raise ValueError("The recommended model is absent from ModelRegistry v2.")
    for entry in entries:
        model_type = entry.get("model_type")
        if model_type not in SUPPORTED_MODELS:
            raise ValueError(f"Unsupported ModelRegistry v2 model: {model_type}")
        if not entry.get("model_id") or "compatibility" not in entry:
            raise ValueError(f"Incomplete ModelRegistry v2 entry: {model_type}")
        if entry["compatibility"] != compatibility:
            raise ValueError(
                f"ModelRegistry v2 compatibility differs for {model_type}."
            )
        if entry.get("checkpoint") is not None and not entry.get("checkpoint_sha256"):
            raise ValueError(f"Checkpoint hash is missing for {model_type}.")
    policy = registry.get("selection_policy", {})
    if policy.get("target_ground_truth_used_at_prediction_time") is not False:
        raise ValueError("ModelRegistry v2 must prohibit target-truth selection.")
    unknown_fallbacks = set(policy.get("fallback_chain", [])) - set(model_types)
    if unknown_fallbacks:
        raise ValueError("ModelRegistry v2 fallback chain contains unknown models.")


def resolve_entry_checkpoint(
    registry_path: str | Path,
    registry: dict[str, Any],
    entry: dict[str, Any],
) -> Path | None:
    """Resolve and verify a registry-owned checkpoint without path traversal."""
    relative = entry.get("checkpoint")
    if relative is None:
        return None
    relative_path = Path(relative)
    if relative_path.is_absolute() or ".." in relative_path.parts:
        raise ValueError("Registry checkpoint paths must stay relative to the registry.")
    registry_path = Path(registry_path).expanduser().resolve()
    checkpoint = (registry_path.parent / relative_path).resolve()
    if registry_path.parent != checkpoint.parent and registry_path.parent not in checkpoint.parents:
        raise ValueError("Registry checkpoint path escapes the model package.")
    if not checkpoint.is_file():
        raise FileNotFoundError(f"Registered checkpoint is missing: {relative}")
    expected = entry.get("checkpoint_sha256")
    if registry.get("schema_version") == REGISTRY_V2_SCHEMA_VERSION and not expected:
        raise ValueError("ModelRegistry v2 requires a checkpoint SHA-256.")
    if expected:
        actual = hashlib.sha256(checkpoint.read_bytes()).hexdigest()
        if actual != expected:
            raise ValueError(
                f"Registered checkpoint SHA-256 mismatch for {entry['model_type']}."
            )
    return checkpoint


def select_registry_entry(
    registry: dict[str, Any],
    data: PredictorData | PredictionRequest,
    selection_mode: str,
    requested_model: str | None = None,
) -> dict[str, Any]:
    if selection_mode == "auto":
        model_type = registry["selection_policy"]["selected_model_type"]
    elif selection_mode == "manual":
        supported = (
            SUPPORTED_MODELS
            if registry["schema_version"] == REGISTRY_V2_SCHEMA_VERSION
            else SUPPORTED_NEURAL_MODELS
        )
        if requested_model not in supported:
            raise ValueError(
                "Manual selection requires one of: "
                + ", ".join(supported)
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
    if (
        registry["schema_version"] == REGISTRY_V2_SCHEMA_VERSION
        and selection_mode == "manual"
        and not entry.get("manual_selection_allowed", False)
    ):
        raise ValueError(f"Model {model_type} is not enabled for manual selection.")
    assert_compatible(entry, data)
    return entry
