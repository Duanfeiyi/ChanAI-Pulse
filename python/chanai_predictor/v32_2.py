"""v3.2-2 Time/Space DS/KF model study on the v3.2-1 corpus.

Reuses the v3.1-4 leakage-safe study machinery (baselines, candidate
configs, train-and-measure, aggregation, admission rules) but runs it on the
v3.2-1 Time/Space two-field (DS_mu, KF_mu) extrapolation corpora instead of
the v3.1 P8 step11abc bundles.
"""

from __future__ import annotations

import hashlib
import json
from dataclasses import asdict, replace
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from .contracts import TrainingConfig
from .data import load_predictor_data_hdf5
from .v31_4 import (
    AdmissionRules,
    _aggregate_runs,
    _baseline_entries,
    _candidate_configs,
    _train_and_measure,
)

STUDY_SCHEMA = "v3.2-2-time-space-study.1"
AXES = ("time", "space")
MODEL_TYPES = ("gru", "lstm", "tcn", "dlinear", "nlinear")
DEFAULT_SEEDS = (94101, 94102, 94103)


def _utc_now() -> str:
    return datetime.now(timezone.utc).isoformat()


def _sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def run_study(
    corpus_directory: str | Path,
    output_directory: str | Path,
    *,
    device: str = "auto",
    seeds: tuple[int, ...] = DEFAULT_SEEDS,
    rules: AdmissionRules = AdmissionRules(),
) -> tuple[Path, dict[str, Any]]:
    """Train Time/Space DS/KF models with validation-only selection."""
    if len(seeds) < 3:
        raise ValueError("The formal v3.2-2 study requires at least three seeds.")
    corpus_directory = Path(corpus_directory).expanduser().resolve()
    output_directory = Path(output_directory).expanduser().resolve()
    if output_directory.exists():
        raise FileExistsError(f"Refusing to overwrite experiment: {output_directory}")
    output_directory.mkdir(parents=True)

    axes: dict[str, Any] = {}
    for axis in AXES:
        data_path = corpus_directory / f"{axis}_extrapolation_ds_kf.h5"
        if not data_path.is_file():
            raise FileNotFoundError(data_path)
        data = load_predictor_data_hdf5(data_path)
        validation_baselines = _baseline_entries(data, "validation")
        best_baseline = min(
            validation_baselines,
            key=lambda entry: entry["metrics"]["normalized_rmse"],
        )
        aggregates = []
        for model_type in MODEL_TYPES:
            search_runs = []
            for candidate in _candidate_configs(model_type, device, seeds[0]):
                run_root = output_directory / axis / "search" / model_type
                run_root = run_root / _config_id(candidate)
                search_runs.append(_train_and_measure(data, candidate, run_root))
            best_search = min(
                search_runs, key=lambda run: run["metrics"]["normalized_rmse"]
            )
            formal_runs = [best_search]
            for seed in seeds[1:]:
                locked = TrainingConfig(**best_search["config"])
                config = replace(locked, seed=int(seed))
                run_root = output_directory / axis / "formal" / model_type / f"seed{seed}"
                formal_runs.append(_train_and_measure(data, config, run_root))
            aggregate = _aggregate_runs(model_type, formal_runs, best_baseline, rules)
            aggregate["search_runs"] = search_runs
            aggregate["locked_config"] = best_search["config"]
            aggregates.append(aggregate)
        qualified = [
            item for item in aggregates if item["qualification"]["passed_parameter_gate"]
        ]
        if qualified:
            selected = min(
                qualified, key=lambda item: item["validation_normalized_rmse_mean"]
            )
            reason = "best_candidate_passing_parameter_admission_gate"
        else:
            selected = {
                "model_type": best_baseline["model_type"],
                "selected_checkpoint": None,
                "qualification": {"passed_parameter_gate": True},
            }
            reason = "safe_baseline_fallback_no_trainable_candidate_passed"
        axes[axis] = {
            "dataset": {"file": data_path.name, "sha256": _sha256(data_path)},
            "validation_baselines": validation_baselines,
            "best_validation_baseline": best_baseline["model_type"],
            "candidate_aggregates": aggregates,
            "selection": {
                "model_type": selected["model_type"],
                "reason": reason,
                "selected_checkpoint": selected.get("selected_checkpoint"),
            },
        }
    manifest = {
        "schema_version": STUDY_SCHEMA,
        "created_utc": _utc_now(),
        "corpus": {
            "id": "chanaipulse-v3.2-corpus.1",
            "parameter_names": ["DS_mu", "KF_mu"],
            "context_to_target": "16_to_4",
            "task_type": "extrapolation",
        },
        "experiment_config": {
            "models": list(MODEL_TYPES),
            "baselines": ["persistence", "linear", "ar", "kalman"],
            "seeds": list(seeds),
            "admission_rules": asdict(rules),
        },
        "axes": axes,
        "full_6gpcm_core_modified": False,
    }
    path = output_directory / "v32_2_study_manifest.json"
    path.write_text(json.dumps(manifest, indent=2, ensure_ascii=False), encoding="utf-8")
    return path, manifest


def _config_id(config: Any) -> str:
    payload = json.dumps(config.to_dict(), sort_keys=True, separators=(",", ":"))
    return hashlib.sha256(payload.encode()).hexdigest()[:12]
