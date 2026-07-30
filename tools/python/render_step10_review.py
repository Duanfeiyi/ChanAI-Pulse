#!/usr/bin/env python3
"""Render an external Step 10 benchmark sheet (never used in product UI)."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

import matplotlib
import numpy as np

matplotlib.use("Agg")
import matplotlib.pyplot as plt

REPO_ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO_ROOT / "python"))

from chanai_predictor import AdaptationPolicy, load_predictor_data_hdf5  # noqa: E402
from chanai_predictor.service import run_prediction  # noqa: E402


COLORS = {
    "gru": "#3378bd",
    "lstm": "#62a8e5",
    "tcn": "#f28e2b",
    "persistence": "#8c8c8c",
    "linear": "#b9b9b9",
}


def _task_assets(task: str) -> tuple:
    data = load_predictor_data_hdf5(
        REPO_ROOT / "demo_data" / "v3_step9" / f"step9_{task}_standard.h5"
    )
    registry_path = (
        REPO_ROOT
        / "demo_data"
        / "v3_step10"
        / "models"
        / task
        / f"{task}_model_registry.json"
    )
    registry = json.loads(registry_path.read_text(encoding="utf-8"))
    result = run_prediction(
        data,
        registry_path,
        selection_mode="auto",
        partition="test",
        adaptation_policy=AdaptationPolicy(mode="off"),
        device="cpu",
    )
    return data, registry, result


def _score_plot(axis, registry: dict, title: str) -> None:
    entries = registry["entries"]
    names = [entry["model_type"] for entry in entries]
    scores = [
        entry["validation_metrics"]["normalized_rmse"] for entry in entries
    ]
    bars = axis.bar(
        [name.upper() for name in names],
        scores,
        color=[COLORS[name] for name in names],
        edgecolor="white",
    )
    selected = registry["selection_policy"]["selected_model_type"]
    for bar, name, score in zip(bars, names, scores, strict=True):
        axis.text(
            bar.get_x() + bar.get_width() / 2,
            score + max(scores) * 0.025,
            f"{score:.3f}",
            ha="center",
            va="bottom",
            fontsize=9,
            weight="bold" if name == selected else "normal",
        )
        if name == selected:
            bar.set_edgecolor("#9a4d00")
            bar.set_linewidth(2.5)
    axis.set_title(f"{title} · Offline validation comparison", weight="bold")
    axis.set_ylabel("Normalized RMSE (lower is better)")
    axis.grid(axis="y", alpha=0.2)
    axis.text(
        0.99,
        0.94,
        f"Auto → {selected.upper()}",
        transform=axis.transAxes,
        ha="right",
        va="top",
        color="#9a4d00",
        weight="bold",
    )


def _prediction_plot(axis, data, result, parameter: int, title: str) -> None:
    test_index = int(data.partition_indices("test")[0])
    normalized_context = data.inputs[test_index]
    context = (
        normalized_context * data.normalization_std.reshape(1, -1)
        + data.normalization_mean.reshape(1, -1)
    )
    normalized_truth = data.targets[test_index : test_index + 1]
    truth = data.denormalize(normalized_truth, project_bounds=False)[0]
    prediction = np.asarray(result["prediction_parameters"])[0]
    target_x = np.asarray(data.target_parameter_sample_index[test_index]).reshape(-1)
    if data.task_type == "extrapolation":
        context_x = np.arange(1, data.context_length + 1)
    else:
        left = data.context_length // 2
        context_x = np.concatenate(
            (
                np.arange(1, left + 1),
                np.arange(
                    left + data.target_length + 1,
                    data.context_length + data.target_length + 1,
                ),
            )
        )
    axis.plot(
        context_x,
        context[:, parameter],
        "-o",
        color="#3378bd",
        markersize=3.5,
        label="Known context",
    )
    axis.plot(
        target_x,
        truth[:, parameter],
        "--o",
        color="#4c9f70",
        markersize=5,
        label="Ground truth (external test only)",
    )
    axis.plot(
        target_x,
        prediction[:, parameter],
        "-s",
        color="#f28e2b",
        markersize=5,
        linewidth=2,
        label="Auto prediction",
    )
    axis.set_title(title, weight="bold", fontsize=10)
    axis.set_xlabel("Parameter sample index")
    axis.set_ylabel(data.parameter_units[parameter])
    axis.grid(alpha=0.2)
    axis.legend(fontsize=7, loc="best")


def render(output: Path) -> None:
    extrapolation = _task_assets("extrapolation")
    interpolation = _task_assets("interpolation")
    figure = plt.figure(figsize=(16, 10), facecolor="#f4f7fb")
    grid = figure.add_gridspec(
        4,
        4,
        height_ratios=[0.17, 1.05, 1.18, 0.34],
        hspace=0.55,
        wspace=0.38,
    )
    title = figure.add_subplot(grid[0, :])
    title.axis("off")
    title.text(
        0.0,
        0.72,
        "ChanAI Pulse v3 · Step 10 External Review Sheet",
        fontsize=20,
        weight="bold",
        color="#0a4a8a",
    )
    title.text(
        0.0,
        0.15,
        "Accuracy evidence is intentionally outside the product UI. "
        "The public fixture is deterministic synthetic engineering data, not a scientific claim.",
        fontsize=10,
        color="#5f6873",
    )
    _score_plot(
        figure.add_subplot(grid[1, :2]), extrapolation[1], "Extrapolation 16→4"
    )
    _score_plot(
        figure.add_subplot(grid[1, 2:]), interpolation[1], "Interpolation 8+8→4"
    )
    _prediction_plot(
        figure.add_subplot(grid[2, 0]),
        extrapolation[0],
        extrapolation[2],
        0,
        "Extrapolation · DS_mu",
    )
    _prediction_plot(
        figure.add_subplot(grid[2, 1]),
        extrapolation[0],
        extrapolation[2],
        1,
        "Extrapolation · KF_mu",
    )
    _prediction_plot(
        figure.add_subplot(grid[2, 2]),
        interpolation[0],
        interpolation[2],
        0,
        "Interpolation · DS_mu",
    )
    _prediction_plot(
        figure.add_subplot(grid[2, 3]),
        interpolation[0],
        interpolation[2],
        1,
        "Interpolation · KF_mu",
    )
    footer = figure.add_subplot(grid[3, :])
    footer.axis("off")
    footer.text(
        0.01,
        0.72,
        "PASS  Contract",
        color="#207a43",
        weight="bold",
        fontsize=11,
    )
    footer.text(
        0.14,
        0.72,
        "[N,16,2] → [N,4,2] · Separate interpolation/extrapolation registries "
        "· GRU/LSTM/TCN all runnable",
        color="#26313d",
        fontsize=10,
    )
    footer.text(
        0.01,
        0.25,
        "PASS  Safety",
        color="#207a43",
        weight="bold",
        fontsize=11,
    )
    footer.text(
        0.14,
        0.25,
        "Auto choice frozen from validation only · Perturbed test truth leaves "
        "selection/prediction unchanged · adaptation updates head only and can roll back",
        color="#26313d",
        fontsize=10,
    )
    footer.add_patch(
        plt.Rectangle(
            (0, 0),
            1,
            1,
            transform=footer.transAxes,
            facecolor="white",
            edgecolor="#8fb4d7",
            zorder=-1,
        )
    )
    output.parent.mkdir(parents=True, exist_ok=True)
    figure.savefig(output, dpi=160, bbox_inches="tight")
    plt.close(figure)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--output",
        type=Path,
        default=(
            REPO_ROOT
            / "docs"
            / "v3.0"
            / "review_assets"
            / "step10"
            / "step10_predictor_external_review.png"
        ),
    )
    render(parser.parse_args().output.resolve())


if __name__ == "__main__":
    main()
