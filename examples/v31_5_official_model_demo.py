#!/usr/bin/env python3
"""Run a target-free neutral P8 request through an official v3.1 model."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

import numpy as np

REPOSITORY = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(REPOSITORY / "python"))

from chanai_predictor import AdaptationPolicy, PredictionRequest  # noqa: E402
from chanai_predictor.registry import load_registry  # noqa: E402
from chanai_predictor.service import run_prediction_request  # noqa: E402


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--task", choices=("interpolation", "extrapolation"), default="extrapolation"
    )
    parser.add_argument(
        "--model",
        choices=(
            "auto",
            "persistence",
            "linear",
            "ar",
            "kalman",
            "gru",
            "lstm",
            "tcn",
            "dlinear",
            "nlinear",
        ),
        default="auto",
    )
    arguments = parser.parse_args()
    registry_path = (
        REPOSITORY
        / "models"
        / "official"
        / "v3.1.0"
        / arguments.task
        / f"{arguments.task}_model_registry_v2.json"
    )
    _, registry = load_registry(registry_path)
    signature = registry["compatibility"]
    mean = np.asarray(
        registry["preprocessing"]["normalization_mean"], dtype=np.float64
    )
    request = PredictionRequest(
        path=Path("in_memory_neutral_request.json"),
        task_type=arguments.task,
        context_layout=signature["context_layout"],
        parameter_names=tuple(signature["parameter_names"]),
        parameter_units=tuple(signature["parameter_units"]),
        input_parameters=np.repeat(mean.reshape(1, 1, -1), 16, axis=1),
        input_parameter_sample_index=np.arange(16, dtype=np.float64).reshape(1, 16),
        target_parameter_sample_index=np.arange(16, 20, dtype=np.float64).reshape(1, 4),
        example_group_ids=("public-neutral-demo",),
    )
    selection = "auto" if arguments.model == "auto" else "manual"
    requested = None if arguments.model == "auto" else arguments.model
    result = run_prediction_request(
        request,
        registry_path,
        selection_mode=selection,
        requested_model=requested,
        adaptation_policy=AdaptationPolicy(mode="off"),
        device="cpu",
    )
    print(
        json.dumps(
            {
                "selected_model": result["selection"]["selected_model"],
                "recommended_model": result["selection"]["recommended_model"],
                "manual_non_recommended": result["selection"][
                    "manual_non_recommended"
                ],
                "prediction_shape": result["prediction_shape"],
                "registry_sha256": result["model"]["registry_sha256"],
            },
            indent=2,
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
