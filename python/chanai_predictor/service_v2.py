"""ModelRegistry v2 inference, safe adaptation, and explicit fallback."""

from __future__ import annotations

import hashlib
from dataclasses import replace
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

import numpy as np

from .adaptation import adapt_prediction_head
from .contracts import (
    ADAPTATION_SCHEMA_VERSION,
    PREDICTION_SCHEMA_VERSION,
    AdaptationPolicy,
    PredictionRequest,
    PredictorData,
)
from .models import BASELINE_PREDICTORS
from .registry import assert_compatible, resolve_entry_checkpoint, select_registry_entry
from .training import load_checkpoint, metric_bundle, predict_model


def _preprocessing(registry: dict[str, Any]) -> tuple[np.ndarray, np.ndarray, np.ndarray]:
    preprocessing = registry["preprocessing"]
    mean = np.asarray(preprocessing["normalization_mean"], dtype=np.float64)
    std = np.asarray(preprocessing["normalization_std"], dtype=np.float64)
    bounds = np.asarray(preprocessing["parameter_bounds"], dtype=np.float64)
    if mean.ndim != 1 or std.shape != mean.shape or bounds.shape != (len(mean), 2):
        raise ValueError("ModelRegistry v2 preprocessing arrays are malformed.")
    if np.any(~np.isfinite(mean)) or np.any(~np.isfinite(std)) or np.any(std <= 0):
        raise ValueError("ModelRegistry v2 normalization is not finite and positive.")
    return mean, std, bounds


def _rebase_data(data: PredictorData, registry: dict[str, Any]) -> PredictorData:
    """Express uploaded known labels in the frozen Base Model normalization."""
    mean, std, bounds = _preprocessing(registry)
    raw_inputs = (
        data.inputs.astype(np.float64) * data.normalization_std.reshape(1, 1, -1)
        + data.normalization_mean.reshape(1, 1, -1)
    )
    raw_targets = (
        data.targets.astype(np.float64) * data.normalization_std.reshape(1, 1, -1)
        + data.normalization_mean.reshape(1, 1, -1)
    )
    return replace(
        data,
        inputs=((raw_inputs - mean.reshape(1, 1, -1)) / std.reshape(1, 1, -1)).astype(
            np.float32
        ),
        targets=(
            (raw_targets - mean.reshape(1, 1, -1)) / std.reshape(1, 1, -1)
        ).astype(np.float32),
        normalization_mean=mean,
        normalization_std=std,
        parameter_bounds=bounds,
    )


def _policy_with_target(
    policy: AdaptationPolicy,
    target_indices: np.ndarray,
    target_groups: tuple[str, ...] | list[str],
) -> AdaptationPolicy:
    values = dict(policy.__dict__)
    values["actual_target_sample_index"] = tuple(
        float(item) for item in np.asarray(target_indices).reshape(-1)
    )
    values["actual_target_group_id"] = tuple(
        group for group in target_groups for _ in range(target_indices.shape[1])
    )
    return AdaptationPolicy(**values)


def _skipped_adaptation(policy: AdaptationPolicy, reason: str) -> dict[str, Any]:
    return {
        "schema_version": ADAPTATION_SCHEMA_VERSION,
        "requested_mode": policy.mode,
        "status": "skipped",
        "accepted": False,
        "reason": reason,
        "updated_parameters": [],
    }


def _entry_by_model(registry: dict[str, Any], model_type: str) -> dict[str, Any]:
    entries = [entry for entry in registry["entries"] if entry["model_type"] == model_type]
    if not entries:
        raise ValueError(f"Model {model_type} is not present in ModelRegistry v2.")
    return entries[0]


def _load_entry_model(
    registry_path: Path,
    registry: dict[str, Any],
    entry: dict[str, Any],
) -> tuple[Any | None, dict[str, Any] | None]:
    if entry["model_type"] in BASELINE_PREDICTORS:
        return None, None
    checkpoint = resolve_entry_checkpoint(registry_path, registry, entry)
    if checkpoint is None:
        raise ValueError(f"Neural model {entry['model_type']} has no checkpoint.")
    model, manifest = load_checkpoint(checkpoint, "cpu")
    if manifest["architecture"]["model_type"] != entry["model_type"]:
        raise ValueError("Checkpoint architecture does not match ModelRegistry v2.")
    dataset = manifest.get("dataset", {})
    compatibility = entry["compatibility"]
    embedded_signature = {
        "task_type": dataset.get("task_type"),
        "context_layout": dataset.get("context_layout"),
        "parameter_names": dataset.get("parameter_names"),
        "parameter_units": dataset.get("parameter_units"),
        "context_length": dataset.get("context_length"),
        "target_length": dataset.get("target_length"),
        "parameter_count": dataset.get("parameter_count"),
    }
    mismatches = [
        key
        for key, value in embedded_signature.items()
        if value != compatibility.get(key)
    ]
    if mismatches:
        raise ValueError(
            "Checkpoint dataset contract does not match ModelRegistry v2: "
            + ", ".join(mismatches)
        )
    return model, manifest


def _predict_entry(
    contract: PredictorData | PredictionRequest,
    entry: dict[str, Any],
    model: Any | None,
    inputs: np.ndarray,
    device: str,
) -> np.ndarray:
    model_type = entry["model_type"]
    if model_type in BASELINE_PREDICTORS:
        return BASELINE_PREDICTORS[model_type](contract, inputs)
    if model is None:
        raise ValueError(f"Neural model {model_type} was not loaded.")
    return predict_model(model, inputs, device)


def _distribution_check(
    normalized_inputs: np.ndarray, registry: dict[str, Any]
) -> dict[str, Any]:
    threshold = float(registry.get("distribution_guard", {}).get("max_abs_zscore", 8.0))
    maximum = float(np.max(np.abs(normalized_inputs))) if normalized_inputs.size else 0.0
    return {
        "method": "maximum_absolute_registry_zscore",
        "maximum_absolute_zscore": maximum,
        "warning_threshold": threshold,
        "status": "warning" if maximum > threshold else "within_declared_range",
        "decision_effect": "warning_only_manual_or_safe_baseline_auto",
    }


def _manual_selection(
    registry_path: Path,
    registry: dict[str, Any],
    contract: PredictorData | PredictionRequest,
    requested_model: str | None,
    policy: AdaptationPolicy,
    adaptation_data: PredictorData | None,
) -> tuple[dict[str, Any], Any | None, dict[str, Any] | None, dict[str, Any], list[dict[str, Any]]]:
    entry = select_registry_entry(
        registry, contract, "manual", requested_model=requested_model
    )
    model, manifest = _load_entry_model(registry_path, registry, entry)
    if policy.mode == "off":
        adaptation = _skipped_adaptation(policy, "adaptation_off")
    elif adaptation_data is None:
        if policy.mode == "force":
            raise ValueError("Forced adaptation requires separate labeled known-region data.")
        adaptation = _skipped_adaptation(
            policy, "no_labeled_known_region_adaptation_data"
        )
    elif not entry.get("adaptation", {}).get("supported", False):
        if policy.mode == "force":
            raise ValueError(
                f"Forced adaptation is unavailable for {entry['model_type']}."
            )
        adaptation = _skipped_adaptation(policy, "selected_model_not_adaptable")
    else:
        adapted_data = _rebase_data(adaptation_data, registry)
        assert_compatible(entry, adapted_data)
        model, adaptation = adapt_prediction_head(
            model, adapted_data, policy, device="cpu"
        )
    return entry, model, manifest, adaptation, []


def _auto_selection(
    registry_path: Path,
    registry: dict[str, Any],
    contract: PredictorData | PredictionRequest,
    policy: AdaptationPolicy,
    adaptation_data: PredictorData | None,
) -> tuple[dict[str, Any], Any | None, dict[str, Any] | None, dict[str, Any], list[dict[str, Any]]]:
    recommended = select_registry_entry(registry, contract, "auto")
    recommended_model, recommended_manifest = _load_entry_model(
        registry_path, registry, recommended
    )
    if policy.mode == "off":
        return (
            recommended,
            recommended_model,
            recommended_manifest,
            _skipped_adaptation(policy, "adaptation_off"),
            [],
        )
    if adaptation_data is None:
        if policy.mode == "force":
            raise ValueError("Forced adaptation requires separate labeled known-region data.")
        return (
            recommended,
            recommended_model,
            recommended_manifest,
            _skipped_adaptation(policy, "no_labeled_known_region_adaptation_data"),
            [],
        )

    adapted_data = _rebase_data(adaptation_data, registry)
    assert_compatible(recommended, adapted_data)
    validation_indices = adapted_data.partition_indices("validation")
    if len(validation_indices) < policy.min_validation_examples:
        if policy.mode == "force":
            raise ValueError("insufficient_validation_examples")
        return (
            recommended,
            recommended_model,
            recommended_manifest,
            _skipped_adaptation(policy, "insufficient_validation_examples"),
            [],
        )
    baseline_prediction = _predict_entry(
        adapted_data,
        recommended,
        recommended_model,
        adapted_data.inputs[validation_indices],
        "cpu",
    )
    baseline_rmse = metric_bundle(
        adapted_data, baseline_prediction, validation_indices
    )["normalized_rmse"]
    candidate_names = registry["selection_policy"].get(
        "auto_adaptation_candidates", []
    )
    attempts: list[dict[str, Any]] = []
    accepted: list[tuple[float, dict[str, Any], Any, dict[str, Any], dict[str, Any]]] = []
    for model_type in candidate_names:
        trial: dict[str, Any] = {"model_type": model_type, "accepted": False}
        try:
            entry = _entry_by_model(registry, model_type)
            assert_compatible(entry, adapted_data)
            if not entry.get("adaptation", {}).get("supported", False):
                trial["reason"] = "model_not_adaptable"
                attempts.append(trial)
                continue
            model, manifest = _load_entry_model(registry_path, registry, entry)
            adapted_model, adaptation = adapt_prediction_head(
                model, adapted_data, policy, device="cpu"
            )
            trial.update(
                {
                    "base_model_relative_improvement": adaptation.get(
                        "relative_improvement"
                    ),
                    "candidate_validation_normalized_rmse": adaptation.get(
                        "candidate_validation_normalized_rmse"
                    ),
                    "reason": adaptation["reason"],
                }
            )
            if not adaptation["accepted"]:
                attempts.append(trial)
                continue
            candidate_rmse = float(adaptation["candidate_validation_normalized_rmse"])
            baseline_improvement = (baseline_rmse - candidate_rmse) / max(
                baseline_rmse, np.finfo(float).eps
            )
            trial["registry_baseline_relative_improvement"] = baseline_improvement
            trial["accepted"] = baseline_improvement >= policy.min_relative_improvement
            trial["reason"] = (
                "beats_base_model_and_registry_baseline"
                if trial["accepted"]
                else "does_not_beat_registry_baseline"
            )
            if trial["accepted"]:
                adaptation["registry_baseline_model_type"] = recommended["model_type"]
                adaptation["registry_baseline_validation_normalized_rmse"] = baseline_rmse
                adaptation["registry_baseline_relative_improvement"] = baseline_improvement
                accepted.append(
                    (candidate_rmse, entry, adapted_model, manifest, adaptation)
                )
        except Exception as error:
            trial["reason"] = "candidate_failed"
            trial["error_type"] = type(error).__name__
            trial["message"] = str(error)
        attempts.append(trial)
    if not accepted:
        adaptation = {
            **_skipped_adaptation(
                policy, "no_adapted_neural_candidate_beats_registry_baseline"
            ),
            "status": "rolled_back",
            "registry_baseline_model_type": recommended["model_type"],
            "registry_baseline_validation_normalized_rmse": baseline_rmse,
            "candidate_attempts": attempts,
        }
        return recommended, recommended_model, recommended_manifest, adaptation, attempts
    _, entry, model, manifest, adaptation = min(accepted, key=lambda item: item[0])
    adaptation["candidate_attempts"] = attempts
    return entry, model, manifest, adaptation, attempts


def _selection_and_model(
    registry_path: Path,
    registry: dict[str, Any],
    contract: PredictorData | PredictionRequest,
    selection_mode: str,
    requested_model: str | None,
    policy: AdaptationPolicy,
    adaptation_data: PredictorData | None,
    auto_block_reason: str | None = None,
) -> tuple[dict[str, Any], Any | None, dict[str, Any] | None, dict[str, Any], list[dict[str, Any]]]:
    if selection_mode == "manual":
        return _manual_selection(
            registry_path,
            registry,
            contract,
            requested_model,
            policy,
            adaptation_data,
        )
    if selection_mode != "auto":
        raise ValueError(f"Unsupported selection mode: {selection_mode}")
    if auto_block_reason is not None:
        recommended = select_registry_entry(registry, contract, "auto")
        model, manifest = _load_entry_model(registry_path, registry, recommended)
        return (
            recommended,
            model,
            manifest,
            _skipped_adaptation(policy, auto_block_reason),
            [],
        )
    return _auto_selection(
        registry_path, registry, contract, policy, adaptation_data
    )


def _result(
    *,
    registry_path: Path,
    registry: dict[str, Any],
    contract: PredictorData | PredictionRequest,
    entry: dict[str, Any],
    manifest: dict[str, Any] | None,
    prediction_normalized: np.ndarray,
    prediction_raw: np.ndarray,
    normalized_inputs: np.ndarray,
    target_indices: np.ndarray,
    selection_mode: str,
    requested_model: str | None,
    adaptation: dict[str, Any],
    attempts: list[dict[str, Any]],
    distribution_check: dict[str, Any],
    is_request: bool,
) -> dict[str, Any]:
    recommended = registry["selection_policy"]["selected_model_type"]
    fallback_reason = (
        adaptation.get("reason")
        if adaptation.get("status") == "rolled_back"
        or adaptation.get("reason") == "distribution_guard_safe_fallback"
        else None
    )
    return {
        "schema_version": PREDICTION_SCHEMA_VERSION,
        "created_utc": datetime.now(timezone.utc).isoformat(),
        "request_schema_version": (
            "v3.0-predictor-request.1" if is_request else None
        ),
        "request_contains_target_ground_truth": False if is_request else None,
        "task_type": contract.task_type,
        "context_layout": contract.context_layout,
        "parameter_names": list(contract.parameter_names),
        "parameter_units": list(contract.parameter_units),
        "input_shape": list(normalized_inputs.shape),
        "prediction_shape": list(prediction_raw.shape),
        "target_parameter_sample_index": target_indices.tolist(),
        "prediction_normalized": prediction_normalized.tolist(),
        "prediction_parameters": prediction_raw.tolist(),
        "selection": {
            "mode": selection_mode,
            "requested_model": requested_model,
            "selected_model": entry["model_type"],
            "recommended_model": recommended,
            "is_system_recommended": entry["model_type"] == recommended,
            "manual_non_recommended": (
                selection_mode == "manual" and entry["model_type"] != recommended
            ),
            "selection_basis": (
                "distribution_guard_safe_fallback"
                if adaptation.get("reason") == "distribution_guard_safe_fallback"
                else "known_region_adaptation_validation"
                if selection_mode == "auto" and entry["model_type"] != recommended
                else "offline_validation_registry"
                if selection_mode == "auto"
                else "advanced_user_manual_choice_non_recommended"
                if entry["model_type"] != recommended
                else "advanced_user_manual_choice_recommended"
            ),
            "target_ground_truth_read_for_selection": False,
            "fallback_applied": fallback_reason is not None,
            "fallback_reason": fallback_reason,
            "candidate_attempts": attempts,
        },
        "model": {
            "model_id": entry["model_id"],
            "deployment_status": entry["deployment_status"],
            "checkpoint": entry.get("checkpoint"),
            "checkpoint_sha256": entry.get("checkpoint_sha256"),
            "manifest_schema_version": manifest.get("schema_version") if manifest else None,
            "registry": registry_path.name,
            "registry_sha256": hashlib.sha256(registry_path.read_bytes()).hexdigest(),
            "registry_schema_version": registry["schema_version"],
            "validation_evidence": entry.get("validation_evidence"),
        },
        "distribution_check": distribution_check,
        "adaptation": adaptation,
        "cir_status": {
            "available": False,
            "reason": "Step 11 converts predicted parameters to CIR.",
        },
    }


def run_prediction_v2(
    data: PredictorData,
    registry_path: Path,
    registry: dict[str, Any],
    *,
    selection_mode: str,
    requested_model: str | None,
    partition: str,
    adaptation_policy: AdaptationPolicy,
    device: str,
) -> dict[str, Any]:
    data.validate()
    adaptation_policy.validate()
    recommended = select_registry_entry(registry, data, "auto")
    assert_compatible(recommended, data)
    rebased = _rebase_data(data, registry)
    indices = rebased.partition_indices(partition)
    target_indices = np.asarray(rebased.target_parameter_sample_index)
    if target_indices.shape[0] == rebased.inputs.shape[0]:
        target_indices = target_indices[indices]
    groups = tuple(rebased.example_group_ids[int(index)] for index in indices)
    policy = _policy_with_target(adaptation_policy, target_indices, groups)
    normalized_inputs = rebased.inputs[indices]
    distribution_check = _distribution_check(normalized_inputs, registry)
    entry, model, manifest, adaptation, attempts = _selection_and_model(
        registry_path,
        registry,
        rebased,
        selection_mode,
        requested_model,
        policy,
        rebased if policy.mode != "off" else None,
        (
            "distribution_guard_safe_fallback"
            if selection_mode == "auto" and distribution_check["status"] == "warning"
            else None
        ),
    )
    prediction_normalized = _predict_entry(
        rebased, entry, model, normalized_inputs, device
    )
    mean, std, bounds = _preprocessing(registry)
    prediction_raw = prediction_normalized.astype(np.float64) * std.reshape(1, 1, -1)
    prediction_raw += mean.reshape(1, 1, -1)
    prediction_raw = np.minimum(
        np.maximum(prediction_raw, bounds[:, 0].reshape(1, 1, -1)),
        bounds[:, 1].reshape(1, 1, -1),
    )
    return _result(
        registry_path=registry_path,
        registry=registry,
        contract=rebased,
        entry=entry,
        manifest=manifest,
        prediction_normalized=prediction_normalized,
        prediction_raw=prediction_raw,
        normalized_inputs=normalized_inputs,
        target_indices=target_indices,
        selection_mode=selection_mode,
        requested_model=requested_model,
        adaptation=adaptation,
        attempts=attempts,
        distribution_check=distribution_check,
        is_request=False,
    )


def run_prediction_request_v2(
    request: PredictionRequest,
    registry_path: Path,
    registry: dict[str, Any],
    *,
    selection_mode: str,
    requested_model: str | None,
    adaptation_policy: AdaptationPolicy,
    adaptation_data: PredictorData | None,
    device: str,
) -> dict[str, Any]:
    request.validate()
    adaptation_policy.validate()
    recommended = select_registry_entry(registry, request, "auto")
    assert_compatible(recommended, request)
    mean, std, bounds = _preprocessing(registry)
    normalized_inputs = (
        request.input_parameters - mean.reshape(1, 1, -1)
    ) / std.reshape(1, 1, -1)
    distribution_check = _distribution_check(normalized_inputs, registry)
    policy = _policy_with_target(
        adaptation_policy,
        request.target_parameter_sample_index,
        request.example_group_ids,
    )
    entry, model, manifest, adaptation, attempts = _selection_and_model(
        registry_path,
        registry,
        request,
        selection_mode,
        requested_model,
        policy,
        adaptation_data,
        (
            "distribution_guard_safe_fallback"
            if selection_mode == "auto" and distribution_check["status"] == "warning"
            else None
        ),
    )
    prediction_normalized = _predict_entry(
        request, entry, model, normalized_inputs, device
    )
    prediction_raw = prediction_normalized.astype(np.float64) * std.reshape(1, 1, -1)
    prediction_raw += mean.reshape(1, 1, -1)
    prediction_raw = np.minimum(
        np.maximum(prediction_raw, bounds[:, 0].reshape(1, 1, -1)),
        bounds[:, 1].reshape(1, 1, -1),
    )
    return _result(
        registry_path=registry_path,
        registry=registry,
        contract=request,
        entry=entry,
        manifest=manifest,
        prediction_normalized=prediction_normalized,
        prediction_raw=prediction_raw,
        normalized_inputs=normalized_inputs,
        target_indices=request.target_parameter_sample_index,
        selection_mode=selection_mode,
        requested_model=requested_model,
        adaptation=adaptation,
        attempts=attempts,
        distribution_check=distribution_check,
        is_request=True,
    )
