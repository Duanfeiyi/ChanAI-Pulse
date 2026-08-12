#!/usr/bin/env python3
"""Run the formal v3.1-4 P8 model comparison outside Git."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

REPOSITORY = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPOSITORY / "python"))

from chanai_predictor.v31_4 import (  # noqa: E402
    AdmissionRules,
    DEFAULT_SENSITIVITY_WEIGHTS,
    finalize_test_once,
    run_study,
)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="command", required=True)
    study = commands.add_parser("study", help="Tune and freeze from validation only.")
    study.add_argument("--data-directory", type=Path, required=True)
    study.add_argument("--output-directory", type=Path, required=True)
    study.add_argument("--device", choices=("auto", "cpu", "cuda"), default="auto")
    study.add_argument("--seeds", nargs="+", type=int, default=(31401, 31402, 31403))
    study.add_argument(
        "--sensitivity-loss-weights",
        nargs=8,
        type=float,
        default=DEFAULT_SENSITIVITY_WEIGHTS,
    )
    final = commands.add_parser(
        "finalize-test", help="Open test once after the Full 6GPCM validation gate."
    )
    final.add_argument("--study-manifest", type=Path, required=True)
    final.add_argument("--gate-manifest", type=Path, required=True)
    final.add_argument("--data-directory", type=Path, required=True)
    final.add_argument("--device", choices=("auto", "cpu", "cuda"), default="auto")
    arguments = parser.parse_args()
    if arguments.command == "finalize-test":
        path, result = finalize_test_once(
            arguments.study_manifest,
            arguments.gate_manifest,
            arguments.data_directory,
            device=arguments.device,
        )
        print(
            json.dumps(
                {
                    "status": "ok",
                    "test_results": str(path),
                    "tasks": result["tasks"],
                },
                ensure_ascii=False,
            )
        )
        return 0
    path, manifest = run_study(
        arguments.data_directory,
        arguments.output_directory,
        REPOSITORY,
        device=arguments.device,
        seeds=tuple(arguments.seeds),
        sensitivity_loss_weights=tuple(arguments.sensitivity_loss_weights),
        rules=AdmissionRules(),
    )
    print(
        json.dumps(
            {
                "status": "ok",
                "manifest": str(path),
                "selection": {
                    task: result["selection"]
                    for task, result in manifest["tasks"].items()
                },
            },
            ensure_ascii=False,
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
