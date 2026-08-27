"""Generate the v3.2-2c Time/Space parameter registries from study evidence.

Reads the v3.2-1 corpora for normalization/bounds/file identity and the
v3.2-2 study manifest for validation numbers, then writes two ModelRegistry
v2-compatible registries (time/space) under models/official/v3.2.0/.
"""
from __future__ import annotations

import hashlib
import json
from datetime import datetime, timezone
from pathlib import Path

import numpy as np

REPO = Path(__file__).resolve().parents[2]
CORPUS = Path(
    "D:/Codex_Feiyi/ChanAI-Pulse-v3.1-assets/corpora/chanaipulse-v3.2-corpus.1"
)
STUDY = (
    Path("D:/Codex_Feiyi/ChanAI-Pulse-v3.1-assets/experiments")
    / "v32_2_time_space_study.1" / "v32_2_study_manifest.json"
)
OUTPUT = REPO / "models" / "official" / "v3.2.0"

import h5py  # noqa: E402


def _read_flat(handle, base_path: str) -> np.ndarray:
    values = np.asarray(handle[f"{base_path}_values"])
    shape = tuple(int(item) for item in handle[f"{base_path}_shape"][...].ravel())
    return values.reshape(shape, order="F")


def corpus_identity(axis: str) -> dict:
    path = CORPUS / f"{axis}_extrapolation_ds_kf.h5"
    with h5py.File(str(path), "r") as handle:
        mean = _read_flat(handle, "/normalization/mean").reshape(-1)
        std = _read_flat(handle, "/normalization/standard_deviation").reshape(-1)
        bounds = _read_flat(handle, "/parameter_sequence/parameter_bounds")
    return {
        "file_name": path.name,
        "sha256": hashlib.sha256(path.read_bytes()).hexdigest(),
        "normalization_mean": mean.tolist(),
        "normalization_std": std.tolist(),
        "parameter_bounds": bounds.tolist(),
    }


def baseline_metrics(axis: str, model_type: str) -> dict:
    study = json.loads(STUDY.read_text(encoding="utf-8"))
    for baseline in study["axes"][axis]["validation_baselines"]:
        if baseline["model_type"] == model_type:
            return baseline["metrics"]
    raise KeyError(f"baseline {model_type} not found for {axis}")


def build_registry(axis: str, recommended: str) -> dict:
    identity = corpus_identity(axis)
    metrics = baseline_metrics(axis, recommended)
    compatibility = {
        "task_type": "extrapolation",
        "context_layout": "history_then_future",
        "parameter_bundle": "V3_2_DS_KF",
        "parameter_names": ["DS_mu", "KF_mu"],
        "parameter_units": ["log10_s", "dB"],
        "context_length": 16,
        "target_length": 4,
        "parameter_count": 2,
        "supported_product_axes": [axis],
        "axis": axis,
        "coordinate_semantics": (
            "seconds_slow_varying"
            if axis == "time"
            else "meters_along_route"
        ),
    }
    entry = {
        "model_id": f"chanaipulse-v3.2.0-{axis}-{recommended}",
        "model_type": recommended,
        "model_family": "deterministic_baseline",
        "deployment_status": "system_recommended",
        "manual_selection_allowed": True,
        "checkpoint": None,
        "checkpoint_sha256": None,
        "compatibility": compatibility,
        "adaptation": {"supported": False, "reason": "parameter_free_baseline"},
        "validation_evidence": {
            "normalized_rmse": metrics["normalized_rmse"],
            "per_parameter_normalized_rmse": metrics["per_parameter_normalized_rmse"],
            "source_partition": "validation",
        },
    }
    registry = {
        "schema_version": "v3.1-predictor-model-registry.2",
        "package_version": "v3.2.0-axes.1",
        "created_utc": datetime.now(timezone.utc).isoformat(),
        "parameter_bundle": "V3_2_DS_KF",
        "source_evidence": {
            "experiment_id": "v32_2_time_space_study.1",
            "study_schema_version": "v3.2-2-time-space-study.1",
            "code_revision": "cfc5c3b",
            "selection_partition": "validation",
            "test_truth_used_for_selection": False,
        },
        "selection_policy": {
            "ordinary_user": "registry_recommendation",
            "selected_model_type": recommended,
            "selected_model_reason": (
                "best_baseline_no_neural_candidate_passed_admission_gate"
            ),
            "fallback_chain": [recommended],
            "target_ground_truth_used_at_prediction_time": False,
        },
        "compatibility": compatibility,
        "preprocessing": {
            "method": "zscore_train_only",
            "normalization_mean": identity["normalization_mean"],
            "normalization_std": identity["normalization_std"],
            "parameter_bounds": identity["parameter_bounds"],
        },
        "entries": [entry],
        "artifact_policy": {
            "contains_private_measurements": False,
            "contains_search_or_intermediate_checkpoints": False,
            "binary_checkpoints_are_bound_by_sha256": True,
        },
    }
    return registry


def main() -> None:
    OUTPUT.mkdir(parents=True, exist_ok=True)
    registries = {
        "time": build_registry("time", "ar"),
        "space": build_registry("space", "persistence"),
    }
    for axis, registry in registries.items():
        path = OUTPUT / axis / f"{axis}_model_registry_v2.json"
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(
            json.dumps(registry, indent=2, ensure_ascii=False), encoding="utf-8"
        )
        print(f"wrote {path}")


if __name__ == "__main__":
    main()
