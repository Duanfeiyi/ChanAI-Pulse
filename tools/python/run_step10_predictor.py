#!/usr/bin/env python3
"""Command-line entry point for the Step 10 Predictor Adapter."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO_ROOT / "python"))

from chanai_predictor import (  # noqa: E402
    AdaptationPolicy,
    load_predictor_data_hdf5,
    predict_request_from_files,
    predict_from_files,
    train_model_family,
    write_request_from_dataset,
)


def _training(arguments: argparse.Namespace) -> dict:
    data = load_predictor_data_hdf5(arguments.data)
    registry_path, registry = train_model_family(
        data,
        arguments.output,
        seed=arguments.seed,
        max_epochs=arguments.max_epochs,
        patience=arguments.patience,
        device=arguments.device,
    )
    return {
        "status": "ok",
        "command": "train-family",
        "registry_path": str(registry_path),
        "task_type": data.task_type,
        "selected_model": registry["selection_policy"]["selected_model_type"],
        "models": [
            {
                "model_type": entry["model_type"],
                "validation_normalized_rmse": entry["validation_metrics"][
                    "normalized_rmse"
                ],
            }
            for entry in registry["entries"]
        ],
    }


def _prediction(arguments: argparse.Namespace) -> dict:
    policy = AdaptationPolicy(
        mode=arguments.adaptation,
        min_relative_improvement=arguments.minimum_adaptation_improvement,
    )
    result = predict_from_files(
        arguments.data,
        arguments.registry,
        arguments.output,
        selection_mode=arguments.selection,
        requested_model=arguments.model,
        partition=arguments.partition,
        adaptation_policy=policy,
        device=arguments.device,
    )
    return {
        "status": "ok",
        "command": "predict",
        "output_path": str(Path(arguments.output).resolve()),
        "task_type": result["task_type"],
        "selected_model": result["selection"]["selected_model"],
        "prediction_shape": result["prediction_shape"],
        "adaptation_status": result["adaptation"]["status"],
        "cir_available": result["cir_status"]["available"],
    }


def _make_request(arguments: argparse.Namespace) -> dict:
    output = write_request_from_dataset(
        load_predictor_data_hdf5(arguments.data),
        arguments.output,
        partition=arguments.partition,
    )
    return {
        "status": "ok",
        "command": "make-request",
        "output_path": str(output),
        "contains_target_ground_truth": False,
    }


def _request_prediction(arguments: argparse.Namespace) -> dict:
    policy = AdaptationPolicy(mode=arguments.adaptation)
    adaptation_data = (
        load_predictor_data_hdf5(arguments.adaptation_data)
        if arguments.adaptation_data is not None
        else None
    )
    result = predict_request_from_files(
        arguments.request,
        arguments.registry,
        arguments.output,
        selection_mode=arguments.selection,
        requested_model=arguments.model,
        adaptation_policy=policy,
        adaptation_data=adaptation_data,
        device=arguments.device,
    )
    return {
        "status": "ok",
        "command": "predict-request",
        "output_path": str(Path(arguments.output).resolve()),
        "task_type": result["task_type"],
        "selected_model": result["selection"]["selected_model"],
        "prediction_shape": result["prediction_shape"],
        "request_contains_target_ground_truth": False,
        "cir_available": result["cir_status"]["available"],
    }


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Train or run the ChanAI Pulse Step 10 Predictor Adapter."
    )
    subparsers = parser.add_subparsers(dest="command", required=True)

    training = subparsers.add_parser(
        "train-family", help="Train GRU/LSTM/TCN and create a frozen registry."
    )
    training.add_argument("--data", type=Path, required=True)
    training.add_argument("--output", type=Path, required=True)
    training.add_argument("--seed", type=int, default=20260730)
    training.add_argument("--max-epochs", type=int, default=80)
    training.add_argument("--patience", type=int, default=12)
    training.add_argument("--device", choices=("auto", "cpu", "cuda"), default="auto")
    training.set_defaults(handler=_training)

    prediction = subparsers.add_parser(
        "predict", help="Predict parameters through the registry contract."
    )
    prediction.add_argument("--data", type=Path, required=True)
    prediction.add_argument("--registry", type=Path, required=True)
    prediction.add_argument("--output", type=Path, required=True)
    prediction.add_argument(
        "--selection", choices=("auto", "manual"), default="auto"
    )
    prediction.add_argument("--model", choices=("gru", "lstm", "tcn"))
    prediction.add_argument(
        "--partition", choices=("train", "validation", "test", "all"), default="test"
    )
    prediction.add_argument(
        "--adaptation", choices=("off", "auto", "force"), default="off"
    )
    prediction.add_argument(
        "--minimum-adaptation-improvement", type=float, default=0.01
    )
    prediction.add_argument("--device", choices=("auto", "cpu", "cuda"), default="auto")
    prediction.set_defaults(handler=_prediction)

    request = subparsers.add_parser(
        "make-request",
        help="Export a target-free product request from one review partition.",
    )
    request.add_argument("--data", type=Path, required=True)
    request.add_argument("--output", type=Path, required=True)
    request.add_argument(
        "--partition", choices=("train", "validation", "test", "all"), default="test"
    )
    request.set_defaults(handler=_make_request)

    request_prediction = subparsers.add_parser(
        "predict-request",
        help="Predict from a product request that contains no target truth.",
    )
    request_prediction.add_argument("--request", type=Path, required=True)
    request_prediction.add_argument("--registry", type=Path, required=True)
    request_prediction.add_argument("--output", type=Path, required=True)
    request_prediction.add_argument(
        "--selection", choices=("auto", "manual"), default="auto"
    )
    request_prediction.add_argument("--model", choices=("gru", "lstm", "tcn"))
    request_prediction.add_argument(
        "--adaptation", choices=("off", "auto", "force"), default="off"
    )
    request_prediction.add_argument(
        "--adaptation-data",
        type=Path,
        help="Optional labeled known-region HDF5 used only for safe head adaptation.",
    )
    request_prediction.add_argument(
        "--device", choices=("auto", "cpu", "cuda"), default="auto"
    )
    request_prediction.set_defaults(handler=_request_prediction)
    return parser


def main() -> int:
    arguments = build_parser().parse_args()
    try:
        summary = arguments.handler(arguments)
    except Exception as error:  # Stable machine-readable failure for MATLAB.
        print(
            json.dumps(
                {
                    "status": "error",
                    "error_type": type(error).__name__,
                    "message": str(error),
                },
                ensure_ascii=False,
            ),
            file=sys.stderr,
        )
        return 1
    print(json.dumps(summary, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
