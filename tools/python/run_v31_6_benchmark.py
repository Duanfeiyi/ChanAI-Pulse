#!/usr/bin/env python3
"""Create leakage-safe v3.1-6 parameter and Full-6GPCM pair exports."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

REPOSITORY = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPOSITORY / "python"))

from chanai_predictor.v31_6 import export_partition  # noqa: E402


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("partition", choices=("validation", "test"))
    parser.add_argument("--config", type=Path, required=True)
    parser.add_argument("--data-directory", type=Path, required=True)
    parser.add_argument("--registry-root", type=Path, required=True)
    parser.add_argument("--corpus-manifest", type=Path, required=True)
    parser.add_argument("--output-directory", type=Path, required=True)
    parser.add_argument("--validation-gate", type=Path)
    arguments = parser.parse_args()
    path, manifest = export_partition(
        config_path=arguments.config,
        data_directory=arguments.data_directory,
        registry_root=arguments.registry_root,
        corpus_manifest=arguments.corpus_manifest,
        output_directory=arguments.output_directory,
        partition=arguments.partition,
        validation_gate=arguments.validation_gate,
    )
    print(json.dumps({
        "status": "ok",
        "manifest": str(path),
        "partition": manifest["evaluation_partition"],
        "task_records": manifest["task_records"],
    }, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
