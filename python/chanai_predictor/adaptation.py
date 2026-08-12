"""Leakage-safe optional adaptation of only the prediction head."""

from __future__ import annotations

import copy
import time
from typing import Any

import numpy as np
import torch
from torch import nn

from .contracts import ADAPTATION_SCHEMA_VERSION, AdaptationPolicy, PredictorData
from .models import SequenceRegressor
from .training import metric_bundle, predict_model, resolve_device, set_reproducible_seed


def _target_key_set(
    data: PredictorData, indices: np.ndarray
) -> set[tuple[str, float]]:
    values = np.asarray(data.target_parameter_sample_index)
    if values.shape[0] == data.inputs.shape[0]:
        values = values[indices]
    groups = [data.example_group_ids[int(index)] for index in indices]
    return {
        (group, float(sample_index))
        for group, row in zip(groups, values, strict=True)
        for sample_index in np.asarray(row).reshape(-1)
    }


def adapt_prediction_head(
    model: SequenceRegressor,
    data: PredictorData,
    policy: AdaptationPolicy,
    *,
    device: str = "auto",
) -> tuple[SequenceRegressor, dict[str, Any]]:
    """Adapt on known training examples and accept only validation improvement."""
    policy.validate()
    base_result: dict[str, Any] = {
        "schema_version": ADAPTATION_SCHEMA_VERSION,
        "requested_mode": policy.mode,
        "status": "skipped",
        "accepted": False,
        "reason": "adaptation_off",
        "updated_parameters": [],
    }
    if policy.mode == "off":
        return model, base_result
    adaptation_indices = data.partition_indices("train")
    validation_indices = data.partition_indices("validation")
    if len(adaptation_indices) < policy.min_adaptation_examples:
        base_result["reason"] = "insufficient_adaptation_examples"
        if policy.mode == "force":
            raise ValueError(base_result["reason"])
        return model, base_result
    if len(validation_indices) < policy.min_validation_examples:
        base_result["reason"] = "insufficient_validation_examples"
        if policy.mode == "force":
            raise ValueError(base_result["reason"])
        return model, base_result
    forbidden = {
        (group, float(sample_index))
        for group, sample_index in zip(
            policy.actual_target_group_id,
            policy.actual_target_sample_index,
            strict=True,
        )
    }
    used_for_adaptation = _target_key_set(data, adaptation_indices)
    used_for_validation = _target_key_set(data, validation_indices)
    overlap = sorted((used_for_adaptation | used_for_validation) & forbidden)
    if overlap:
        raise ValueError(
            "Adaptation data overlaps the actual prediction target region: "
            + ", ".join(f"{group}@{sample}" for group, sample in overlap[:8])
        )
    target_device = resolve_device(device)
    set_reproducible_seed(policy.seed, True)
    candidate = copy.deepcopy(model).to(target_device)
    for parameter in candidate.parameters():
        parameter.requires_grad = False
    for parameter in candidate.head.parameters():
        parameter.requires_grad = True
    optimizer = torch.optim.Adam(candidate.head.parameters(), lr=policy.learning_rate)
    loss_function = nn.MSELoss()
    adaptation_inputs = torch.from_numpy(data.inputs[adaptation_indices]).float().to(
        target_device
    )
    adaptation_targets = torch.from_numpy(data.targets[adaptation_indices]).float().to(
        target_device
    )
    validation_inputs = data.inputs[validation_indices]
    base_prediction = predict_model(model, validation_inputs, target_device)
    base_metric = metric_bundle(data, base_prediction, validation_indices)
    best_state = copy.deepcopy(candidate.head.state_dict())
    best_rmse = base_metric["normalized_rmse"]
    patience_count = 0
    started = time.perf_counter()
    epochs = 0
    for epoch in range(1, policy.max_epochs + 1):
        if time.perf_counter() - started > policy.max_seconds:
            break
        candidate.train()
        optimizer.zero_grad(set_to_none=True)
        loss = loss_function(candidate(adaptation_inputs), adaptation_targets)
        loss.backward()
        optimizer.step()
        epochs = epoch
        score = metric_bundle(
            data,
            predict_model(candidate, validation_inputs, target_device),
            validation_indices,
        )["normalized_rmse"]
        if score < best_rmse:
            best_rmse = score
            best_state = copy.deepcopy(candidate.head.state_dict())
            patience_count = 0
        else:
            patience_count += 1
            if patience_count >= policy.patience:
                break
    candidate.head.load_state_dict(best_state)
    base_rmse = base_metric["normalized_rmse"]
    relative_improvement = (base_rmse - best_rmse) / max(
        base_rmse, np.finfo(float).eps
    )
    accepted = relative_improvement >= policy.min_relative_improvement
    result = {
        **base_result,
        "status": "accepted" if accepted else "rolled_back",
        "accepted": accepted,
        "reason": (
            "validation_improved"
            if accepted
            else "minimum_validation_improvement_not_met"
        ),
        "base_validation_normalized_rmse": base_rmse,
        "candidate_validation_normalized_rmse": best_rmse,
        "relative_improvement": relative_improvement,
        "minimum_relative_improvement": policy.min_relative_improvement,
        "epochs_completed": epochs,
        "elapsed_seconds": time.perf_counter() - started,
        "adaptation_example_count": int(len(adaptation_indices)),
        "validation_example_count": int(len(validation_indices)),
        "updated_parameters": ["head.weight", "head.bias"],
        "actual_target_overlap_count": 0,
    }
    return (candidate if accepted else model), result
