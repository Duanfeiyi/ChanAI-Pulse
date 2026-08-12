"""Binding and conclusion tests for the small v3.1-6 public report."""

from __future__ import annotations

import csv
import hashlib
import json
import sys
import tempfile
import unittest
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO_ROOT / "python"))

from chanai_predictor.v31_6_report import build_report  # noqa: E402


class V316ReportTests(unittest.TestCase):
    def test_report_keeps_registry_defaults_frozen(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            config = root / "config.json"
            config.write_text(json.dumps({"protocol_id": "demo.2"}), encoding="utf-8")
            config_hash = hashlib.sha256(config.read_bytes()).hexdigest()
            gate = root / "gate.json"
            gate.write_text(json.dumps({
                "passed": True, "test_partition_used": False,
                "protocol_config_sha256": config_hash,
            }), encoding="utf-8")
            export = root / "export.json"
            export.write_text(json.dumps({"protocol_config_sha256": config_hash}), encoding="utf-8")
            manifest = root / "channel.json"
            manifest.write_text(json.dumps({
                "evaluation_partition": "test", "registry_or_threshold_changed": False,
                "full_6gpcm_core_unchanged": True, "pair_count": 4,
            }), encoding="utf-8")
            details = root / "details.csv"
            self.write_csv(details, [{
                "task_type": task, "candidate_id": model,
                "group_id": "route", "is_stability_subset": "true", "complex_nmse": "1.0",
                "truth_generation_runtime_s": "0.2",
                "prediction_generation_runtime_s": "0.3", "metric_runtime_s": "0.01",
            } for task, model in (("interpolation", "persistence"),
                                  ("extrapolation", "kalman"))])
            parameters = root / "parameters.csv"
            self.write_csv(parameters, [{
                "task_type": task, "candidate_id": model, "group_id": "route",
                "parameter_nrmse": "0.1", "sensitivity_weighted_nrmse": "0.2",
                "inference_seconds_per_example": "0.001",
                "adaptation_accepted": "False",
            } for task, model in (("interpolation", "persistence"),
                                  ("extrapolation", "kalman"))])
            summary = root / "summary.csv"
            rows = []
            for task, default in (("interpolation", "persistence"),
                                  ("extrapolation", "kalman")):
                rows.extend([
                    {"task_type": task, "candidate_id": default,
                     "eligible_to_upgrade_auto_default": "true", "mean_complex_nmse": "1.0"},
                    {"task_type": task, "candidate_id": "lstm",
                     "eligible_to_upgrade_auto_default": "false", "mean_complex_nmse": "0.5"},
                ])
            self.write_csv(summary, rows)
            report = build_report(
                protocol_config=config, validation_gate=gate,
                test_export_manifest=export, test_parameter_rows=parameters,
                test_channel_manifest=manifest, test_channel_rows=details,
                test_channel_summary=summary,
                output_json=root / "report.json", output_markdown=root / "report.md",
            )
            self.assertEqual(report["conclusions"]["interpolation"]["descriptive_best_all_candidate"], "lstm")
            self.assertFalse(report["conclusions"]["interpolation"]["default_changed"])
            self.assertEqual(report["conclusions"]["extrapolation"]["frozen_registry_default"], "kalman")
            self.assertNotIn(str(root), (root / "report.json").read_text(encoding="utf-8"))

    @staticmethod
    def write_csv(path: Path, rows: list[dict[str, str]]) -> None:
        with path.open("w", newline="", encoding="utf-8") as stream:
            writer = csv.DictWriter(stream, fieldnames=list(rows[0]))
            writer.writeheader()
            writer.writerows(rows)


if __name__ == "__main__":
    unittest.main()
