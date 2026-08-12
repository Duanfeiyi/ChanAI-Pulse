"""Small, path-free v3.1-6 summaries from external formal evidence."""

from __future__ import annotations

import csv
import hashlib
import json
from collections import defaultdict
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def summarize_parameter_rows(path: str | Path) -> list[dict[str, Any]]:
    path = Path(path)
    accumulators: dict[tuple[str, str], dict[str, Any]] = defaultdict(
        lambda: {"count": 0, "route_sum": defaultdict(float), "route_count": defaultdict(int),
                 "weighted_sum": 0.0, "inference_sum": 0.0,
                 "accepted": 0, "adaptation_rows": 0}
    )
    with path.open(newline="", encoding="utf-8") as stream:
        for row in csv.DictReader(stream):
            key = (row["task_type"], row["candidate_id"])
            item = accumulators[key]
            metric = float(row["parameter_nrmse"])
            item["count"] += 1
            item["weighted_sum"] += float(row["sensitivity_weighted_nrmse"])
            item["inference_sum"] += float(row["inference_seconds_per_example"])
            item["route_sum"][row["group_id"]] += metric
            item["route_count"][row["group_id"]] += 1
            if row["candidate_id"] == "auto_adapted_secondary":
                item["adaptation_rows"] += 1
                item["accepted"] += row["adaptation_accepted"].lower() == "true"
    output = []
    for (task, candidate), item in sorted(accumulators.items()):
        route_means = [
            item["route_sum"][route] / item["route_count"][route]
            for route in sorted(item["route_sum"])
        ]
        output.append({
            "task_type": task,
            "candidate_id": candidate,
            "row_count": item["count"],
            "route_count": len(route_means),
            "route_mean_parameter_nrmse": sum(route_means) / len(route_means),
            "mean_sensitivity_weighted_nrmse": item["weighted_sum"] / item["count"],
            "mean_inference_seconds_per_example": item["inference_sum"] / item["count"],
            "adaptation_acceptance_row_fraction": (
                item["accepted"] / item["adaptation_rows"]
                if item["adaptation_rows"] else None
            ),
        })
    return output


def read_csv(path: Path) -> list[dict[str, str]]:
    with path.open(newline="", encoding="utf-8") as stream:
        return list(csv.DictReader(stream))


def _best(rows: list[dict[str, str]], task: str, eligible_only: bool) -> dict[str, str]:
    selected = [row for row in rows if row["task_type"] == task]
    if eligible_only:
        selected = [
            row for row in selected
            if row["eligible_to_upgrade_auto_default"].lower() in {"1", "true"}
        ]
    return min(selected, key=lambda row: float(row["mean_complex_nmse"]))


def build_report(
    *,
    protocol_config: str | Path,
    validation_gate: str | Path,
    test_export_manifest: str | Path,
    test_parameter_rows: str | Path,
    test_channel_manifest: str | Path,
    test_channel_rows: str | Path,
    test_channel_summary: str | Path,
    output_json: str | Path,
    output_markdown: str | Path,
) -> dict[str, Any]:
    paths = {name: Path(value).resolve() for name, value in {
        "protocol_config": protocol_config,
        "validation_gate": validation_gate,
        "test_export_manifest": test_export_manifest,
        "test_parameter_rows": test_parameter_rows,
        "test_channel_manifest": test_channel_manifest,
        "test_channel_rows": test_channel_rows,
        "test_channel_summary": test_channel_summary,
    }.items()}
    config = json.loads(paths["protocol_config"].read_text(encoding="utf-8"))
    gate = json.loads(paths["validation_gate"].read_text(encoding="utf-8"))
    test_export = json.loads(paths["test_export_manifest"].read_text(encoding="utf-8"))
    channel_manifest = json.loads(paths["test_channel_manifest"].read_text(encoding="utf-8"))
    if not gate.get("passed") or gate.get("test_partition_used") is not False:
        raise ValueError("The report requires a passed, Test-free validation gate.")
    if gate["protocol_config_sha256"] != sha256_file(paths["protocol_config"]):
        raise ValueError("Validation gate and protocol config hashes differ.")
    if test_export["protocol_config_sha256"] != gate["protocol_config_sha256"]:
        raise ValueError("Test export is not bound to the validation protocol.")
    if channel_manifest["evaluation_partition"] != "test":
        raise ValueError("The supplied channel result is not the Test partition.")
    if channel_manifest.get("registry_or_threshold_changed") is not False:
        raise ValueError("The Test run claims a post-gate registry or threshold change.")
    channel_rows = read_csv(paths["test_channel_summary"])
    detail_rows = read_csv(paths["test_channel_rows"])
    parameter_summary = summarize_parameter_rows(paths["test_parameter_rows"])
    timing: dict[str, dict[str, float]] = {}
    stability: dict[str, dict[str, float]] = {}
    worst_routes: dict[str, dict[str, dict[str, Any]]] = {}
    for task in ("interpolation", "extrapolation"):
        task_rows = [row for row in detail_rows if row["task_type"] == task]
        timing[task] = {
            "mean_truth_generation_runtime_s": sum(
                float(row["truth_generation_runtime_s"]) for row in task_rows
            ) / len(task_rows),
            "mean_prediction_generation_runtime_s": sum(
                float(row["prediction_generation_runtime_s"]) for row in task_rows
            ) / len(task_rows),
            "mean_metric_runtime_s": sum(
                float(row["metric_runtime_s"]) for row in task_rows
            ) / len(task_rows),
        }
        stable_rows = [
            row for row in task_rows
            if row["is_stability_subset"].lower() in {"1", "true"}
        ]
        by_candidate_route: dict[tuple[str, str], list[float]] = defaultdict(list)
        for row in stable_rows:
            by_candidate_route[(row["candidate_id"], row["group_id"])].append(
                float(row["complex_nmse"])
            )
        candidate_ranges: dict[str, list[float]] = defaultdict(list)
        for (candidate, _), values in by_candidate_route.items():
            candidate_ranges[candidate].append(max(values) - min(values))
        stability[task] = {
            candidate: sum(ranges) / len(ranges)
            for candidate, ranges in sorted(candidate_ranges.items())
        }
        route_values: dict[tuple[str, str], list[float]] = defaultdict(list)
        for row in task_rows:
            route_values[(row["candidate_id"], row["group_id"])].append(
                float(row["complex_nmse"])
            )
        candidate_routes: dict[str, list[tuple[str, float]]] = defaultdict(list)
        for (candidate, group), values in route_values.items():
            candidate_routes[candidate].append((group, sum(values) / len(values)))
        worst_routes[task] = {}
        for candidate, values in sorted(candidate_routes.items()):
            group, metric = max(values, key=lambda item: item[1])
            worst_routes[task][candidate] = {
                "group_id": group, "route_mean_complex_nmse": metric,
            }
    tasks = ("interpolation", "extrapolation")
    defaults = {"interpolation": "persistence", "extrapolation": "kalman"}
    conclusions: dict[str, Any] = {}
    for task in tasks:
        best_all = _best(channel_rows, task, False)
        best_eligible = _best(channel_rows, task, True)
        default_row = next(
            row for row in channel_rows
            if row["task_type"] == task and row["candidate_id"] == defaults[task]
        )
        conclusions[task] = {
            "frozen_registry_default": defaults[task],
            "default_test_mean_complex_nmse": float(default_row["mean_complex_nmse"]),
            "descriptive_best_all_candidate": best_all["candidate_id"],
            "descriptive_best_all_mean_complex_nmse": float(best_all["mean_complex_nmse"]),
            "descriptive_best_classical_candidate": best_eligible["candidate_id"],
            "descriptive_best_classical_mean_complex_nmse": float(best_eligible["mean_complex_nmse"]),
            "default_changed": False,
            "reason": "Test is evaluation-only; Registry v2 remains frozen.",
        }
    payload = {
        "schema_version": "v3.1-6-public-evidence-summary.1",
        "created_utc": datetime.now(timezone.utc).isoformat(),
        "protocol_id": config["protocol_id"],
        "evaluation_partition": "test",
        "validation_gate_passed": True,
        "hidden_test_target_truth_used_for_registry_or_threshold_selection": False,
        "known_region_labels_used_for_secondary_online_adaptation": True,
        "full_6gpcm_core_unchanged": channel_manifest["full_6gpcm_core_unchanged"],
        "pair_count": channel_manifest["pair_count"],
        "parameter_summary": parameter_summary,
        "channel_summary": channel_rows,
        "runtime_summary": timing,
        "stability_complex_nmse_range": stability,
        "worst_route_by_candidate": worst_routes,
        "conclusions": conclusions,
        "limitations": [
            "Angular spectra are unavailable because the public adapter exposes no ray angles.",
            "Spatial-correlation delta is unavailable on SISO routes with only one Tx-Rx link.",
            "Nt=4 supports only a short-window temporal/Doppler diagnostic.",
            "A Test winner is descriptive and cannot retroactively change the frozen Registry.",
        ],
        "source_hashes": {name: sha256_file(path) for name, path in paths.items()},
    }
    output_json = Path(output_json)
    output_markdown = Path(output_markdown)
    output_json.parent.mkdir(parents=True, exist_ok=True)
    output_markdown.parent.mkdir(parents=True, exist_ok=True)
    output_json.write_text(json.dumps(payload, indent=2, ensure_ascii=False), encoding="utf-8")
    lines = [
        "# ChanAI Pulse v3.1-6 formal evidence summary", "",
        f"- Protocol: `{payload['protocol_id']}`",
        f"- Test Full-6GPCM parameter pairs: {payload['pair_count']}",
        "- Validation gate: PASS; Test was not used for model selection.",
        f"- Full 6GPCM core unchanged: `{str(payload['full_6gpcm_core_unchanged']).lower()}`", "",
        "## Frozen product conclusion", "",
        "| Task | Registry default | Test mean complex NMSE | Descriptive best classical | Descriptive best overall |",
        "|---|---:|---:|---:|---:|",
    ]
    for task in tasks:
        item = conclusions[task]
        lines.append(
            f"| {task} | {item['frozen_registry_default']} | "
            f"{item['default_test_mean_complex_nmse']:.6g} | "
            f"{item['descriptive_best_classical_candidate']} "
            f"({item['descriptive_best_classical_mean_complex_nmse']:.6g}) | "
            f"{item['descriptive_best_all_candidate']} "
            f"({item['descriptive_best_all_mean_complex_nmse']:.6g}) |"
        )
    lines += [
        "", "The Test set does not change the Registry v2 defaults. Neural results remain "
        "advanced/research evidence unless admitted by a future predeclared study.", "",
        "## Scope limits", "",
        "- Angular metrics are explicitly unavailable from the current public adapter.",
        "- Nt=4 temporal and Doppler outputs are short-window diagnostics, not a long-sequence study.",
        "- Large row-level CSV and generated channel caches remain outside Git; source hashes are in the JSON summary.", "",
    ]
    output_markdown.write_text("\n".join(lines), encoding="utf-8")
    return payload
