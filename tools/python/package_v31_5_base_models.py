#!/usr/bin/env python3
"""Package the frozen v3.1-4 finalists as path-free v3.1-5 Base Models."""

from __future__ import annotations

import argparse
import hashlib
import json
import shutil
import sys
from pathlib import Path
from typing import Any

REPOSITORY = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPOSITORY / "python"))

import torch  # noqa: E402

from chanai_predictor.contracts import REGISTRY_V2_SCHEMA_VERSION  # noqa: E402
from chanai_predictor.data import load_predictor_data_hdf5  # noqa: E402


TASKS = ("interpolation", "extrapolation")
BASELINES = ("persistence", "linear", "ar", "kalman")
TRAINABLE = ("gru", "lstm", "tcn", "dlinear", "nlinear")
ADAPTABLE = ("gru", "lstm", "tcn")


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def compatibility(data: Any) -> dict[str, Any]:
    return {
        "task_type": data.task_type,
        "context_layout": data.context_layout,
        "parameter_bundle": "P8",
        "parameter_names": list(data.parameter_names),
        "parameter_units": list(data.parameter_units),
        "context_length": data.context_length,
        "target_length": data.target_length,
        "parameter_count": data.parameter_count,
        "supported_product_axes": ["sample", "position"],
    }


def baseline_entry(
    task: str,
    baseline: dict[str, Any],
    recommended: str,
    signature: dict[str, Any],
) -> dict[str, Any]:
    model_type = baseline["model_type"]
    return {
        "model_id": f"chanaipulse-v3.1.0-{task}-{model_type}",
        "model_type": model_type,
        "model_family": "deterministic_baseline",
        "deployment_status": (
            "system_recommended" if model_type == recommended else "fallback_or_manual"
        ),
        "manual_selection_allowed": True,
        "checkpoint": None,
        "checkpoint_sha256": None,
        "compatibility": signature,
        "adaptation": {"supported": False, "reason": "parameter_free_baseline"},
        "validation_evidence": {
            "normalized_rmse": baseline["metrics"]["normalized_rmse"],
            "route_nrmse": baseline["route_nrmse"],
            "source_partition": "validation",
        },
    }


def trainable_entry(
    task: str,
    aggregate: dict[str, Any],
    signature: dict[str, Any],
    destination: Path,
) -> dict[str, Any]:
    model_type = aggregate["model_type"]
    source = Path(aggregate["selected_checkpoint"]).expanduser().resolve()
    if sha256(source) != aggregate["selected_checkpoint_sha256"]:
        raise ValueError(f"Frozen checkpoint hash mismatch: {source}")
    payload = torch.load(source, map_location="cpu", weights_only=True)
    embedded = payload["manifest"]
    architecture = embedded["architecture"]
    dataset = embedded["dataset"]
    if architecture["model_type"] != model_type or dataset["task_type"] != task:
        raise ValueError(f"Frozen checkpoint identity mismatch: {source}")
    file_name = f"{task}_{model_type}.pt"
    target = destination / file_name
    if target.exists():
        raise FileExistsError(f"Refusing to overwrite {target}")
    shutil.copy2(source, target)
    copied_hash = sha256(target)
    if copied_hash != aggregate["selected_checkpoint_sha256"]:
        raise ValueError(f"Copied checkpoint hash mismatch: {target}")
    qualification = aggregate["qualification"]
    return {
        "model_id": f"chanaipulse-v3.1.0-{task}-{model_type}",
        "model_type": model_type,
        "model_family": "official_pretrained_experimental",
        "deployment_status": "official_experimental_not_system_recommended",
        "manual_selection_allowed": True,
        "checkpoint": file_name,
        "checkpoint_sha256": copied_hash,
        "checkpoint_size_bytes": target.stat().st_size,
        "checkpoint_loader": "torch.load(weights_only=True)",
        "compatibility": signature,
        "adaptation": {
            "supported": model_type in ADAPTABLE,
            "method": "output_head_only" if model_type in ADAPTABLE else None,
            "automatic_candidate": model_type in ADAPTABLE,
        },
        "architecture": architecture,
        "training_dataset": {
            "file_name": dataset["file_name"],
            "sha256": dataset["sha256"],
            "corpus_id": "chanaipulse-v3.1-corpus.1",
        },
        "validation_evidence": {
            "normalized_rmse_mean": aggregate["validation_normalized_rmse_mean"],
            "normalized_rmse_std": aggregate["validation_normalized_rmse_std"],
            "route_nrmse_mean": aggregate["validation_route_nrmse_mean"],
            "qualification": qualification,
            "selected_seed": aggregate["selected_seed"],
            "source_partition": "validation",
        },
    }


def package_task(
    task: str,
    study: dict[str, Any],
    data_directory: Path,
    output_root: Path,
) -> Path:
    destination = output_root / task
    if destination.exists():
        raise FileExistsError(f"Refusing to overwrite model package: {destination}")
    destination.mkdir(parents=True)
    data_path = data_directory / f"step11abc_{task}_p8.h5"
    data = load_predictor_data_hdf5(data_path)
    task_result = study["tasks"][task]
    if sha256(data_path) != task_result["dataset"]["sha256"]:
        raise ValueError(f"Corpus hash does not match the frozen {task} study.")
    signature = compatibility(data)
    recommended = task_result["selection"]["model_type"]
    baseline_by_name = {
        item["model_type"]: item for item in task_result["validation_baselines"]
    }
    aggregate_by_name = {
        item["model_type"]: item for item in task_result["candidate_aggregates"]
    }
    entries = [
        baseline_entry(task, baseline_by_name[name], recommended, signature)
        for name in BASELINES
    ]
    entries += [
        trainable_entry(task, aggregate_by_name[name], signature, destination)
        for name in TRAINABLE
    ]
    fallback_chain = (
        ["persistence", "linear"]
        if task == "interpolation"
        else ["kalman", "persistence", "linear"]
    )
    registry = {
        "schema_version": REGISTRY_V2_SCHEMA_VERSION,
        "package_version": "v3.1.0-base-models.1",
        "created_utc": study["selection_frozen_utc"],
        "parameter_bundle": "P8",
        "source_evidence": {
            "experiment_id": "v31_4_model_study.3",
            "study_schema_version": study["schema_version"],
            "code_revision": study["code"]["revision"],
            "code_dirty": study["code"]["dirty"],
            "selection_partition": "validation",
            "test_truth_used_for_selection": False,
        },
        "selection_policy": {
            "ordinary_user": "registry_recommendation_then_safe_known_region_adaptation",
            "selected_model_type": recommended,
            "selected_model_reason": task_result["selection"]["reason"],
            "fallback_chain": fallback_chain,
            "auto_adaptation_candidates": list(ADAPTABLE),
            "adapted_candidate_must_beat_base_model": True,
            "adapted_candidate_must_beat_registry_baseline": True,
            "minimum_relative_improvement": 0.01,
            "target_ground_truth_used_at_prediction_time": False,
        },
        "compatibility": signature,
        "distribution_guard": {
            "method": "maximum_absolute_registry_zscore",
            "max_abs_zscore": 8.0,
            "effect": "warning_and_safe_auto_fallback",
        },
        "preprocessing": {
            "method": "zscore_train_only",
            "normalization_mean": data.normalization_mean.tolist(),
            "normalization_std": data.normalization_std.tolist(),
            "parameter_bounds": data.parameter_bounds.tolist(),
        },
        "entries": entries,
        "artifact_policy": {
            "contains_private_measurements": False,
            "contains_search_or_intermediate_checkpoints": False,
            "binary_checkpoints_are_bound_by_sha256": True,
        },
    }
    path = destination / f"{task}_model_registry_v2.json"
    path.write_text(
        json.dumps(registry, indent=2, ensure_ascii=False, allow_nan=False),
        encoding="utf-8",
    )
    return path


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--study-manifest", type=Path, required=True)
    parser.add_argument("--data-directory", type=Path, required=True)
    parser.add_argument("--output-root", type=Path, required=True)
    arguments = parser.parse_args()
    study_path = arguments.study_manifest.expanduser().resolve()
    data_directory = arguments.data_directory.expanduser().resolve()
    output_root = arguments.output_root.expanduser().resolve()
    if output_root.exists():
        raise FileExistsError(f"Refusing to overwrite output root: {output_root}")
    output_root.mkdir(parents=True)
    study = json.loads(study_path.read_text(encoding="utf-8"))
    paths = [
        package_task(task, study, data_directory, output_root) for task in TASKS
    ]
    print(
        json.dumps(
            {
                "status": "ok",
                "registries": [str(path) for path in paths],
                "checkpoint_count": len(TASKS) * len(TRAINABLE),
            },
            ensure_ascii=False,
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
