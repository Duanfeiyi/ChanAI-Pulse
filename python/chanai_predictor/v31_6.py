"""Leakage-safe v3.1-6 parameter exports for the independent Full-6GPCM gate."""

from __future__ import annotations

import csv
import hashlib
import json
import time
from dataclasses import replace
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

import numpy as np

from .contracts import AdaptationPolicy, PredictionRequest, PredictorData
from .data import load_predictor_data_hdf5
from .registry import load_registry
from .service_v2 import run_prediction_request_v2

P8_NAMES = (
    "DS_mu", "KF_mu", "DS_sigma", "KF_sigma", "r_DS", "LNS_ksi",
    "num_clusters", "num_rays",
)
P8_UNITS = (
    "log10_s", "dB", "log10_s_std", "dB", "dimensionless", "dB",
    "count", "count",
)
INTEGER_PARAMETERS = ("num_clusters", "num_rays")
EXPORT_SCHEMA = "v3.1-6-parameter-export.1"


def sha256_file(path: str | Path) -> str:
    path = Path(path)
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def load_config(path: str | Path) -> tuple[Path, dict[str, Any]]:
    path = Path(path).expanduser().resolve()
    config = json.loads(path.read_text(encoding="utf-8"))
    if config.get("schema_version") != "v3.1-6-end-to-end-config.1":
        raise ValueError("Unsupported v3.1-6 protocol configuration.")
    if tuple(config.get("tasks", [])) != ("interpolation", "extrapolation"):
        raise ValueError("v3.1-6 requires frozen interpolation and extrapolation tasks.")
    if tuple(config.get("registry_models", [])) != (
        "persistence", "linear", "ar", "kalman", "gru", "lstm", "tcn",
        "dlinear", "nlinear",
    ):
        raise ValueError("The frozen Registry v2 candidate order changed.")
    weights = config["parameter_evaluation"]["sensitivity_weights"]
    if len(weights) != len(P8_NAMES) or any(float(item) <= 0 for item in weights):
        raise ValueError("v3.1-6 sensitivity weights must contain eight positives.")
    generator = config["generator_evaluation"]
    if not generator.get("truth_and_prediction_share_seed", False):
        raise ValueError("Truth and prediction must share a generator seed.")
    if generator.get("representative_window") != "last_window_per_route":
        raise ValueError("The representative-window policy is not frozen.")
    return path, config


def _raw_inputs(data: PredictorData, indices: np.ndarray) -> np.ndarray:
    return (
        data.inputs[indices].astype(np.float64)
        * data.normalization_std.reshape(1, 1, -1)
        + data.normalization_mean.reshape(1, 1, -1)
    )


def _raw_targets(data: PredictorData, indices: np.ndarray) -> np.ndarray:
    return data.denormalize(data.targets[indices]).astype(np.float64)


def _input_sample_indices(data: PredictorData, target: np.ndarray) -> np.ndarray:
    start = target[:, :1].astype(np.float64)
    if data.task_type == "extrapolation":
        offsets = np.arange(-data.context_length, 0, dtype=np.float64)
    else:
        half = data.context_length // 2
        offsets = np.concatenate((
            np.arange(-half, 0, dtype=np.float64),
            np.arange(data.target_length, data.target_length + half, dtype=np.float64),
        ))
    return start + offsets.reshape(1, -1)


def _request(data: PredictorData, indices: np.ndarray, label: str) -> PredictionRequest:
    target = np.asarray(data.target_parameter_sample_index)[indices]
    request = PredictionRequest(
        path=Path(label),
        task_type=data.task_type,
        context_layout=data.context_layout,
        parameter_names=tuple(data.parameter_names),
        parameter_units=tuple(data.parameter_units),
        input_parameters=_raw_inputs(data, indices),
        input_parameter_sample_index=_input_sample_indices(data, target),
        target_parameter_sample_index=target.astype(np.float64),
        example_group_ids=tuple(data.example_group_ids[int(index)] for index in indices),
    )
    request.validate()
    return request


def _route_catalog(corpus: dict[str, Any]) -> dict[str, dict[str, Any]]:
    catalog = {str(item["group_id"]): item for item in corpus["group_catalog"]}
    if len(catalog) != len(corpus["group_catalog"]):
        raise ValueError("The corpus route catalog contains duplicate group IDs.")
    return catalog


def _scenario_profiles(corpus: dict[str, Any]) -> dict[tuple[str, float], dict[str, Any]]:
    profiles: dict[tuple[str, float], dict[str, Any]] = {}
    source = corpus.get("scenario_profiles")
    if source is None:
        source = corpus.get("step11abc_write_manifest", {}).get("scenario_profiles")
    if not source:
        raise ValueError("The corpus manifest does not contain scenario profiles.")
    for item in source:
        key = (str(item["scenario_name"]), float(item["carrier_frequency_hz"]))
        profiles[key] = item
    return profiles


def _profile_values(
    route: dict[str, Any], profiles: dict[tuple[str, float], dict[str, Any]]
) -> np.ndarray:
    key = (str(route["scenario_name"]), float(route["carrier_frequency_hz"]))
    if key not in profiles:
        raise ValueError(f"No Full-6GPCM profile for route scenario {key!r}.")
    profile = profiles[key]
    if tuple(profile["parameter_names"]) != P8_NAMES:
        raise ValueError("Scenario profile does not use canonical P8 order.")
    return np.asarray(profile["values"], dtype=np.float64)


def _representative_indices(data: PredictorData, partition: str) -> np.ndarray:
    partition_indices = data.partition_indices(partition)
    groups = np.asarray(data.example_group_ids, dtype=object)
    selected = []
    for group in sorted(set(groups[partition_indices].tolist())):
        candidates = partition_indices[groups[partition_indices] == group]
        selected.append(int(candidates[-1]))
    return np.asarray(selected, dtype=np.int64)


def _ranked_stability_groups(groups: list[str], count: int) -> set[str]:
    ranked = sorted(groups, key=lambda value: hashlib.sha256(value.encode()).hexdigest())
    return set(ranked[: min(count, len(ranked))])


def _known_region_adaptation_data(
    data: PredictorData, actual_index: int
) -> PredictorData | None:
    group = data.example_group_ids[actual_index]
    actual_target = set(
        float(item) for item in np.asarray(data.target_parameter_sample_index)[actual_index]
    )
    candidates = []
    for index, candidate_group in enumerate(data.example_group_ids):
        if candidate_group != group or index == actual_index:
            continue
        target = np.asarray(data.target_parameter_sample_index)[index]
        if any(float(item) in actual_target for item in target):
            continue
        if float(np.max(target)) >= min(actual_target):
            continue
        candidates.append(index)
    if len(candidates) < 40:
        return None
    candidates = sorted(candidates, key=lambda index: float(
        np.max(np.asarray(data.target_parameter_sample_index)[index])
    ))
    split = max(32, int(np.floor(0.8 * len(candidates))))
    if len(candidates) - split < 8:
        split = len(candidates) - 8
    selected = np.asarray(candidates, dtype=np.int64)
    codes = np.concatenate((
        np.ones(split, dtype=np.uint8),
        np.full(len(selected) - split, 2, dtype=np.uint8),
    ))
    return replace(
        data,
        path=Path(f"known-region-{group}.h5"),
        inputs=data.inputs[selected].copy(),
        targets=data.targets[selected].copy(),
        target_parameter_sample_index=np.asarray(
            data.target_parameter_sample_index
        )[selected].copy(),
        partition_codes=codes,
        example_group_ids=tuple(data.example_group_ids[int(index)] for index in selected),
        metadata={**data.metadata, "known_region_only": True},
    )


def _prediction(
    request: PredictionRequest,
    registry_path: Path,
    registry: dict[str, Any],
    model: str,
) -> tuple[np.ndarray, dict[str, Any], float]:
    started = time.perf_counter()
    result = run_prediction_request_v2(
        request,
        registry_path,
        registry,
        selection_mode="manual",
        requested_model=model,
        adaptation_policy=AdaptationPolicy(mode="off"),
        adaptation_data=None,
        device="cpu",
    )
    elapsed = time.perf_counter() - started
    return np.asarray(result["prediction_parameters"], dtype=np.float64), result, elapsed


def _adapted_prediction(
    request: PredictionRequest,
    registry_path: Path,
    registry: dict[str, Any],
    adaptation_data: PredictorData,
    config: dict[str, Any],
) -> tuple[np.ndarray, dict[str, Any], float]:
    settings = config["adaptation_evaluation"]
    started = time.perf_counter()
    result = run_prediction_request_v2(
        request,
        registry_path,
        registry,
        selection_mode="auto",
        requested_model=None,
        adaptation_policy=AdaptationPolicy(
            mode="auto",
            min_relative_improvement=float(settings["minimum_relative_improvement"]),
            max_epochs=int(settings["maximum_epochs"]),
            patience=int(settings["patience"]),
            max_seconds=float(settings["maximum_seconds"]),
        ),
        adaptation_data=adaptation_data,
        device="cpu",
    )
    elapsed = time.perf_counter() - started
    return np.asarray(result["prediction_parameters"], dtype=np.float64), result, elapsed


def _project_integer_parameters(values: np.ndarray) -> np.ndarray:
    values = np.asarray(values, dtype=np.float64).copy()
    for name in INTEGER_PARAMETERS:
        values[..., P8_NAMES.index(name)] = np.rint(values[..., P8_NAMES.index(name)])
    return values


def _v3_baseline(
    data: PredictorData,
    indices: np.ndarray,
    catalog: dict[str, dict[str, Any]],
    profiles: dict[tuple[str, float], dict[str, Any]],
) -> tuple[np.ndarray, list[list[str]]]:
    raw_inputs = _raw_inputs(data, indices)
    if data.task_type == "interpolation":
        half = data.context_length // 2
        prediction = 0.5 * (
            raw_inputs[:, half - 1 : half, :] + raw_inputs[:, half : half + 1, :]
        )
    else:
        prediction = raw_inputs[:, -1:, :]
    prediction = np.repeat(prediction, data.target_length, axis=1)
    sources = [["predicted"] * len(P8_NAMES) for _ in indices]
    if data.task_type == "extrapolation":
        for local, index in enumerate(indices):
            profile = _profile_values(catalog[data.example_group_ids[int(index)]], profiles)
            prediction[local, :, 6:] = profile[6:]
            sources[local][6:] = ["scenario_config", "scenario_config"]
    return _project_integer_parameters(prediction), sources


def _parameter_rows(
    *,
    data: PredictorData,
    indices: np.ndarray,
    truth: np.ndarray,
    prediction: np.ndarray,
    candidate: str,
    selected_model: str,
    recommended: str,
    inference_seconds: float,
    sources: list[list[str]] | None = None,
    adaptation: dict[str, Any] | None = None,
) -> list[dict[str, Any]]:
    std = data.normalization_std.astype(np.float64)
    weights = np.asarray(data.metadata.get("v31_6_sensitivity_weights", np.ones(8)))
    result = []
    for local, index in enumerate(indices):
        group = data.example_group_ids[int(index)]
        for offset in range(data.target_length):
            delta = prediction[local, offset] - truth[local, offset]
            normalized = delta / std
            row: dict[str, Any] = {
                "partition": "",
                "task_type": data.task_type,
                "candidate_id": candidate,
                "selected_model": selected_model,
                "registry_recommended_model": recommended,
                "is_registry_recommended": selected_model == recommended,
                "group_id": group,
                "example_index": int(index),
                "target_offset": offset,
                "target_step": float(np.asarray(data.target_parameter_sample_index)[index, offset]),
                "parameter_nrmse": float(np.sqrt(np.mean(normalized ** 2))),
                "sensitivity_weighted_nrmse": float(
                    np.sqrt(np.sum(weights * normalized ** 2) / np.sum(weights))
                ),
                "inference_seconds_per_example": float(inference_seconds / max(1, len(indices))),
                "adaptation_status": (adaptation or {}).get("status", "off"),
                "adaptation_accepted": bool((adaptation or {}).get("accepted", False)),
                "adaptation_reason": (adaptation or {}).get("reason", "adaptation_off"),
            }
            for column, name in enumerate(P8_NAMES):
                row[f"truth_{name}"] = float(truth[local, offset, column])
                row[f"predicted_{name}"] = float(prediction[local, offset, column])
                row[f"error_{name}"] = float(delta[column])
                row[f"abs_error_{name}"] = float(abs(delta[column]))
                row[f"source_{name}"] = (
                    sources[local][column] if sources is not None else "predicted"
                )
            result.append(row)
    return result


def _write_csv(path: Path, rows: list[dict[str, Any]]) -> None:
    if not rows:
        raise ValueError(f"No rows were produced for {path.name}.")
    with path.open("x", newline="", encoding="utf-8") as stream:
        writer = csv.DictWriter(stream, fieldnames=list(rows[0]))
        writer.writeheader()
        writer.writerows(rows)


def _generator_rows(
    rows: list[dict[str, Any]],
    representative: set[tuple[str, int]],
    catalog: dict[str, dict[str, Any]],
    partition: str,
    config: dict[str, Any],
) -> list[dict[str, Any]]:
    offset = int(config["generator_evaluation"]["representative_target_offset_zero_based"])
    groups = sorted({row["group_id"] for row in rows})
    if partition == "validation":
        if config["generator_evaluation"].get("validation_route_method") != (
            "lowest_sha256_ranked_group_ids"
        ):
            raise ValueError("The validation route selection method is not frozen.")
        allowed_groups = _ranked_stability_groups(
            groups, int(config["generator_evaluation"]["validation_route_count"])
        )
    else:
        expected = int(config["generator_evaluation"]["test_route_count"])
        if len(groups) != expected:
            raise ValueError(
                f"The Test generator route count changed: {len(groups)} != {expected}."
            )
        allowed_groups = set(groups)
    stability = _ranked_stability_groups(
        groups, int(config["generator_evaluation"]["stability_subset_route_count"])
    )
    primary = int(config["generator_evaluation"]["primary_seed"])
    seeds = [int(item) for item in config["generator_evaluation"]["stability_seeds"]]
    output: list[dict[str, Any]] = []
    seen: set[tuple[str, str, int, int]] = set()
    for row in rows:
        key = (row["group_id"], int(row["example_index"]))
        if (
            key not in representative
            or row["group_id"] not in allowed_groups
            or int(row["target_offset"]) != offset
        ):
            continue
        row_seeds = seeds if partition == "test" and row["group_id"] in stability else [primary]
        route = catalog[row["group_id"]]
        for seed in row_seeds:
            identity = (row["candidate_id"], row["group_id"], int(row["target_step"]), seed)
            if identity in seen:
                continue
            seen.add(identity)
            item = dict(row)
            item.update({
                "protocol_seed": seed,
                "is_stability_subset": row["group_id"] in stability,
                "scenario_name": route["scenario_name"],
                "carrier_frequency_hz": float(route["carrier_frequency_hz"]),
                "route_speed_mps": float(route["route_speed_mps"]),
                "tx_count": int(route["tx_count"]),
                "rx_count": int(route["rx_count"]),
            })
            output.append(item)
    candidates = {row["candidate_id"] for row in rows}
    expected_candidates = set(config["registry_models"]) | set(
        config["additional_baselines"]
    )
    if config["adaptation_evaluation"]["enabled"]:
        expected_candidates.add("auto_adapted_secondary")
    if candidates != expected_candidates:
        raise ValueError(
            "The frozen candidate matrix changed: "
            f"{sorted(candidates)} != {sorted(expected_candidates)}."
        )
    expected_pair_count = len(candidates) * len(allowed_groups)
    if partition == "test":
        expected_pair_count += (
            len(candidates)
            * len(stability)
            * (len(seeds) - 1)
        )
    if len(output) != expected_pair_count:
        raise ValueError(
            "The frozen generator-pair matrix is incomplete: "
            f"{len(output)} != {expected_pair_count}."
        )
    return output


def _validate_gate(path: Path, config_hash: str) -> dict[str, Any]:
    gate = json.loads(path.read_text(encoding="utf-8"))
    if gate.get("schema_version") != "v3.1-6-validation-gate.1":
        raise ValueError("The supplied v3.1-6 validation gate is unsupported.")
    if gate.get("evaluation_partition") != "validation" or not gate.get("passed"):
        raise ValueError("The v3.1-6 validation gate did not pass.")
    if gate.get("protocol_config_sha256") != config_hash:
        raise ValueError("The validation gate is bound to another protocol config.")
    if gate.get("test_partition_used") is not False:
        raise ValueError("The validation gate claims Test access.")
    return gate


def export_partition(
    *,
    config_path: str | Path,
    data_directory: str | Path,
    registry_root: str | Path,
    corpus_manifest: str | Path,
    output_directory: str | Path,
    partition: str,
    validation_gate: str | Path | None = None,
) -> tuple[Path, dict[str, Any]]:
    if partition not in {"validation", "test"}:
        raise ValueError("v3.1-6 exports only validation or test partitions.")
    config_path, config = load_config(config_path)
    config_hash = sha256_file(config_path)
    data_directory = Path(data_directory).expanduser().resolve()
    registry_root = Path(registry_root).expanduser().resolve()
    corpus_path = Path(corpus_manifest).expanduser().resolve()
    corpus = json.loads(corpus_path.read_text(encoding="utf-8"))
    catalog = _route_catalog(corpus)
    profiles = _scenario_profiles(corpus)
    output = Path(output_directory).expanduser().resolve()
    gate_record = None
    if partition == "test":
        if validation_gate is None:
            raise ValueError("Test export requires the frozen validation gate.")
        gate_path = Path(validation_gate).expanduser().resolve()
        gate_record = {
            "path_name": gate_path.name,
            "sha256": sha256_file(gate_path),
            "payload": _validate_gate(gate_path, config_hash),
        }
    output.mkdir(parents=True, exist_ok=False)

    all_parameter_rows: list[dict[str, Any]] = []
    all_generator_rows: list[dict[str, Any]] = []
    task_records: list[dict[str, Any]] = []
    for task in config["tasks"]:
        data_path = data_directory / f"step11abc_{task}_p8.h5"
        data = load_predictor_data_hdf5(data_path)
        data.metadata["v31_6_sensitivity_weights"] = config["parameter_evaluation"][
            "sensitivity_weights"
        ]
        indices = data.partition_indices(partition)
        truth = _project_integer_parameters(_raw_targets(data, indices))
        registry_path = registry_root / task / f"{task}_model_registry_v2.json"
        registry_path, registry = load_registry(registry_path)
        request = _request(data, indices, f"target-free-{partition}-{task}.json")
        representative_indices = _representative_indices(data, partition)
        representative = {
            (data.example_group_ids[int(index)], int(index))
            for index in representative_indices
        }
        task_rows: list[dict[str, Any]] = []
        for model in config["registry_models"]:
            prediction, result, elapsed = _prediction(
                request, registry_path, registry, model
            )
            prediction = _project_integer_parameters(prediction)
            rows = _parameter_rows(
                data=data, indices=indices, truth=truth, prediction=prediction,
                candidate=model, selected_model=model,
                recommended=registry["selection_policy"]["selected_model_type"],
                inference_seconds=elapsed,
            )
            for row in rows:
                row["partition"] = partition
            task_rows.extend(rows)

        baseline, sources = _v3_baseline(data, indices, catalog, profiles)
        rows = _parameter_rows(
            data=data, indices=indices, truth=truth, prediction=baseline,
            candidate="v3_0_official", selected_model="persistence",
            recommended=registry["selection_policy"]["selected_model_type"],
            inference_seconds=0.0, sources=sources,
        )
        for row in rows:
            row["partition"] = partition
        task_rows.extend(rows)

        if config["adaptation_evaluation"]["enabled"]:
            for actual_index in representative_indices:
                adaptation_data = _known_region_adaptation_data(data, int(actual_index))
                if adaptation_data is None:
                    continue
                local_request = _request(
                    data, np.asarray([actual_index], dtype=np.int64),
                    f"target-free-adapted-{partition}-{task}.json",
                )
                prediction, result, elapsed = _adapted_prediction(
                    local_request, registry_path, registry, adaptation_data, config
                )
                prediction = _project_integer_parameters(prediction)
                local_truth = _project_integer_parameters(
                    _raw_targets(data, np.asarray([actual_index], dtype=np.int64))
                )
                adapted_rows = _parameter_rows(
                    data=data,
                    indices=np.asarray([actual_index], dtype=np.int64),
                    truth=local_truth,
                    prediction=prediction,
                    candidate="auto_adapted_secondary",
                    selected_model=result["selection"]["selected_model"],
                    recommended=registry["selection_policy"]["selected_model_type"],
                    inference_seconds=elapsed,
                    adaptation=result["adaptation"],
                )
                for row in adapted_rows:
                    row["partition"] = partition
                task_rows.extend(adapted_rows)

        all_parameter_rows.extend(task_rows)
        all_generator_rows.extend(_generator_rows(
            task_rows, representative, catalog, partition, config
        ))
        task_records.append({
            "task_type": task,
            "dataset": data_path.name,
            "dataset_sha256": sha256_file(data_path),
            "registry": registry_path.name,
            "registry_sha256": sha256_file(registry_path),
            "partition_example_count": int(len(indices)),
            "route_count": int(len(representative_indices)),
            "prediction_target_truth_read": False,
        })

    parameter_path = output / f"v31_6_{partition}_parameter_rows.csv"
    generator_path = output / f"v31_6_{partition}_generator_pairs.csv"
    _write_csv(parameter_path, all_parameter_rows)
    _write_csv(generator_path, all_generator_rows)
    manifest = {
        "schema_version": EXPORT_SCHEMA,
        "created_utc": datetime.now(timezone.utc).isoformat(),
        "protocol_id": config["protocol_id"],
        "protocol_config": config_path.name,
        "protocol_config_sha256": config_hash,
        "evaluation_partition": partition,
        "selection_partition": "validation",
        "test_truth_used_for_model_selection": False,
        "prediction_requests_contained_target_truth": False,
        "parameter_rows": parameter_path.name,
        "parameter_rows_sha256": sha256_file(parameter_path),
        "generator_pairs": generator_path.name,
        "generator_pairs_sha256": sha256_file(generator_path),
        "corpus_manifest": corpus_path.name,
        "corpus_manifest_sha256": sha256_file(corpus_path),
        "task_records": task_records,
        "validation_gate": gate_record,
        "asset_policy": config["asset_policy"],
    }
    manifest_path = output / f"v31_6_{partition}_export_manifest.json"
    manifest_path.write_text(
        json.dumps(manifest, indent=2, ensure_ascii=False, allow_nan=False),
        encoding="utf-8",
    )
    return manifest_path, manifest
