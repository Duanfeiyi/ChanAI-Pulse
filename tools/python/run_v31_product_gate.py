#!/usr/bin/env python3
"""Run the v3.1 known-region product safety gate from JSON."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "python"))

from chanai_predictor.product_gate import run_product_gate  # noqa: E402


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    try:
        payload = json.loads(args.input.read_text(encoding="utf-8"))
        result = run_product_gate(payload)
        args.output.write_text(
            json.dumps(result, indent=2, ensure_ascii=False), encoding="utf-8"
        )
        print(json.dumps({
            "status": "ok",
            "selected_model": result["selection"]["selected_model"],
            "backtest_examples": result["backtest"]["example_count"],
        }, ensure_ascii=False))
        return 0
    except Exception as error:
        print(json.dumps({
            "status": "error",
            "error_type": type(error).__name__,
            "message": str(error),
        }, ensure_ascii=False), file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
