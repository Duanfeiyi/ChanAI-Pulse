#!/usr/bin/env python3
"""Build the small tracked v3.1-6 report from external formal evidence."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

REPOSITORY = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPOSITORY / "python"))

from chanai_predictor.v31_6_report import build_report  # noqa: E402


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    for name in (
        "protocol_config", "validation_gate", "test_export_manifest",
        "test_parameter_rows", "test_channel_manifest", "test_channel_rows", "test_channel_summary",
        "output_json", "output_markdown",
    ):
        parser.add_argument("--" + name.replace("_", "-"), type=Path, required=True)
    args = parser.parse_args()
    report = build_report(**vars(args))
    print(json.dumps({"status": "ok", "protocol_id": report["protocol_id"],
                      "pair_count": report["pair_count"]}))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
