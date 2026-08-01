#!/usr/bin/env python3
"""Run the Step 11B multi-seed benchmark on one or all Step 11A HDF5 files."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO_ROOT / "python"))

from chanai_predictor.data import load_predictor_data_hdf5  # noqa: E402
from chanai_predictor.step11abc import (  # noqa: E402
    benchmark_model_family,
    export_frozen_selection_test_pairs,
    refresh_existing_validation_pairs,
)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--data-directory", type=Path, required=True)
    parser.add_argument("--output-directory", type=Path, required=True)
    parser.add_argument("--max-epochs", type=int, default=50)
    parser.add_argument("--patience", type=int, default=8)
    parser.add_argument("--device", choices=("auto", "cpu", "cuda"), default="auto")
    parser.add_argument("--seeds", type=int, nargs="+", default=(11011, 11012, 11013))
    parser.add_argument(
        "--selection-manifest",
        type=Path,
        help="Skip training and export test pairs only for frozen validation choices.",
    )
    parser.add_argument(
        "--refresh-validation-pairs",
        action="store_true",
        help="Skip training and recreate validation pair CSVs from existing registries.",
    )
    arguments = parser.parse_args()
    if arguments.refresh_validation_pairs and arguments.selection_manifest is not None:
        parser.error("--refresh-validation-pairs and --selection-manifest are mutually exclusive.")
    if arguments.refresh_validation_pairs:
        outputs = refresh_existing_validation_pairs(
            arguments.data_directory,
            arguments.output_directory,
            device=arguments.device,
        )
        print(json.dumps({"status": "ok", "validation_pair_files": [str(path) for path in outputs]}, ensure_ascii=False))
        return 0
    if arguments.selection_manifest is not None:
        manifest_path, manifest = export_frozen_selection_test_pairs(
            arguments.data_directory,
            arguments.output_directory,
            arguments.selection_manifest,
            device=arguments.device,
        )
        print(
            json.dumps(
                {"status": "ok", "test_export_manifest": str(manifest_path), "exports": manifest["exports"]},
                ensure_ascii=False,
            )
        )
        return 0
    paths = sorted(arguments.data_directory.glob("step11abc_*.h5"))
    if not paths:
        raise FileNotFoundError("No step11abc_*.h5 files found.")
    summaries = []
    for path in paths:
        data = load_predictor_data_hdf5(path)
        reference_path = arguments.data_directory / f"step11abc_{data.task_type}_p8.h5"
        reference = load_predictor_data_hdf5(reference_path)
        output = arguments.output_directory / path.stem
        registry_path, registry = benchmark_model_family(
            data,
            output,
            seeds=tuple(arguments.seeds),
            max_epochs=arguments.max_epochs,
            patience=arguments.patience,
            device=arguments.device,
            reference_p8_data=reference,
        )
        summaries.append(
            {
                "data": str(path),
                "registry": str(registry_path),
                "selected_model": registry["selection_policy"]["selected_model_type"],
                "reason": registry["selection_policy"]["selection_reason"],
            }
        )
    print(json.dumps({"status": "ok", "benchmarks": summaries}, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
