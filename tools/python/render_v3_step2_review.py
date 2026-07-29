"""Render the Step 2 pre-PR visual review package.

These plots are data-quality previews, not the production Step 5
characteristic engine. They help a reviewer verify that each deterministic
fixture visibly contains the dimensions and physical variation it claims.
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import Any

import matplotlib.pyplot as plt
import numpy as np

REPO_ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO_ROOT / "tools" / "python"))

from read_channel_hdf5 import read_channel_hdf5  # noqa: E402

plt.rcParams["font.sans-serif"] = [
    "Microsoft YaHei",
    "SimHei",
    "DejaVu Sans",
]
plt.rcParams["axes.unicode_minus"] = False
COLORS = {
    "blue": "#2563EB",
    "green": "#059669",
    "orange": "#EA580C",
    "purple": "#7C3AED",
    "gray": "#64748B",
}


def _db(power: np.ndarray) -> np.ndarray:
    return 10.0 * np.log10(np.maximum(power, 1e-12))


def _empirical_cdf(values: np.ndarray) -> tuple[np.ndarray, np.ndarray]:
    x = np.sort(np.asarray(values).reshape(-1))
    y = np.arange(1, x.size + 1, dtype=float) / x.size
    return x, y


def _path_power(cir: dict[str, Any]) -> np.ndarray:
    return np.mean(np.abs(cir["coefficient"]) ** 2, axis=(0, 1))


def _delay_spread_ns(cir: dict[str, Any]) -> np.ndarray:
    power = _path_power(cir)
    delay = np.asarray(cir["delay_s"])[0, 0]
    total = np.maximum(np.sum(power, axis=0), 1e-12)
    mean = np.sum(power * delay, axis=0) / total
    variance = np.sum(power * (delay - mean[None, :, :]) ** 2, axis=0)
    spread = np.sqrt(np.maximum(variance / total, 0.0))
    return np.mean(spread, axis=0) * 1e9


def _angular_spread_deg(cir: dict[str, Any]) -> np.ndarray:
    power = _path_power(cir)
    angle = np.asarray(cir["aoa_rad"])[0, 0]
    total = np.maximum(np.sum(power, axis=0), 1e-12)
    mean = np.sum(power * angle, axis=0) / total
    variance = np.sum(power * (angle - mean[None, :, :]) ** 2, axis=0)
    spread = np.sqrt(np.maximum(variance / total, 0.0))
    return np.mean(spread, axis=0) * 180.0 / np.pi


def _doppler_spread_hz(cir: dict[str, Any]) -> np.ndarray:
    power = _path_power(cir)
    doppler = np.asarray(cir["doppler_hz"])[0, 0]
    total = np.maximum(np.sum(power, axis=0), 1e-12)
    mean = np.sum(power * doppler, axis=0) / total
    variance = np.sum(power * (doppler - mean[None, :, :]) ** 2, axis=0)
    spread = np.sqrt(np.maximum(variance / total, 0.0))
    return np.mean(spread, axis=0)


def _normalized_acf(
    value: np.ndarray, axis: int
) -> tuple[np.ndarray, np.ndarray]:
    moved = np.moveaxis(value, axis, 0)
    length = moved.shape[0]
    correlation = np.zeros(length, dtype=np.complex128)
    for lag in range(length):
        correlation[lag] = np.mean(
            moved[: length - lag] * np.conj(moved[lag:])
        )
    normalized = np.abs(correlation) / max(abs(correlation[0]), 1e-12)
    return np.arange(length), normalized


def _delay_heatmap(cir: dict[str, Any]) -> tuple[np.ndarray, np.ndarray]:
    power = _path_power(cir)
    delay_ns = np.asarray(cir["delay_s"])[0, 0] * 1e9
    sample_count = power.shape[-1]
    bins = np.linspace(0.0, max(300.0, float(delay_ns.max()) + 10.0), 65)
    heatmap = np.zeros((bins.size - 1, sample_count))
    for sample in range(sample_count):
        for time in range(power.shape[1]):
            indices = np.clip(
                np.digitize(delay_ns[:, time, sample], bins) - 1,
                0,
                bins.size - 2,
            )
            for path, bin_index in enumerate(indices):
                heatmap[bin_index, sample] += power[path, time, sample]
    return bins, _db(heatmap)


def _style_axis(axis: plt.Axes) -> None:
    axis.grid(True, color="#CBD5E1", alpha=0.45, linewidth=0.7)
    axis.spines["top"].set_visible(False)
    axis.spines["right"].set_visible(False)


def _plot_power(axis: plt.Axes, ctf: dict[str, Any]) -> None:
    power = np.mean(np.abs(ctf["H"]) ** 2, axis=(0, 1, 2, 3))
    axis.plot(np.arange(1, power.size + 1), _db(power), color=COLORS["blue"])
    axis.set(title="标准图：接收功率", xlabel="路线样本", ylabel="功率 (dB)")
    _style_axis(axis)


def _plot_pdp(axis: plt.Axes, cir: dict[str, Any]) -> None:
    power = _path_power(cir)
    delay = np.asarray(cir["delay_s"])[0, 0]
    axis.stem(
        np.mean(delay, axis=(1, 2)) * 1e9,
        _db(np.mean(power, axis=(1, 2))),
        linefmt=COLORS["blue"],
        markerfmt="o",
        basefmt=" ",
    )
    axis.set(title="标准图：平均 PDP", xlabel="时延 (ns)", ylabel="功率 (dB)")
    _style_axis(axis)


def _plot_frequency_acf(axis: plt.Axes, ctf: dict[str, Any]) -> None:
    lag, value = _normalized_acf(ctf["H"], axis=2)
    axis.plot(lag, value, color=COLORS["green"])
    axis.set(
        title="标准图：频率自相关",
        xlabel="子载波间隔（索引）",
        ylabel="归一化相关",
        ylim=(0, 1.05),
    )
    _style_axis(axis)


def _plot_delay_cdf(axis: plt.Axes, cir: dict[str, Any]) -> None:
    x, y = _empirical_cdf(_delay_spread_ns(cir))
    axis.plot(x, y, color=COLORS["orange"])
    axis.set(
        title="标准图：时延扩展 CDF",
        xlabel="RMS 时延扩展 (ns)",
        ylabel="累计概率",
        ylim=(0, 1.02),
    )
    _style_axis(axis)


def _plot_angle_spectrum(axis: plt.Axes, cir: dict[str, Any]) -> None:
    power = _path_power(cir)
    angle = np.asarray(cir["aoa_rad"])[0, 0] * 180.0 / np.pi
    axis.scatter(
        angle.reshape(-1),
        _db(power).reshape(-1),
        s=8,
        alpha=0.38,
        color=COLORS["purple"],
    )
    axis.set(title="标准图：角度功率谱", xlabel="到达角 (°)", ylabel="功率 (dB)")
    _style_axis(axis)


def _plot_spatial_correlation(axis: plt.Axes, ctf: dict[str, Any]) -> None:
    h = ctf["H"]
    center = h.shape[2] // 2
    value = h[:, :, center, :, :]
    rx_count = value.shape[1]
    correlation = np.ones(rx_count)
    for separation in range(1, rx_count):
        numerator = np.mean(
            value[:, : rx_count - separation]
            * np.conj(value[:, separation:])
        )
        correlation[separation] = abs(numerator) / max(
            float(np.mean(np.abs(value) ** 2)), 1e-12
        )
    axis.plot(
        np.arange(rx_count),
        correlation,
        marker="o",
        color=COLORS["blue"],
    )
    axis.set(
        title="标准图：空间相关",
        xlabel="接收天线间隔（阵元）",
        ylabel="归一化相关",
        ylim=(0, 1.05),
    )
    _style_axis(axis)


def _plot_angular_cdf(axis: plt.Axes, cir: dict[str, Any]) -> None:
    x, y = _empirical_cdf(_angular_spread_deg(cir))
    axis.plot(x, y, color=COLORS["purple"])
    axis.set(
        title="标准图：角度扩展 CDF",
        xlabel="RMS 角度扩展 (°)",
        ylabel="累计概率",
        ylim=(0, 1.02),
    )
    _style_axis(axis)


def _plot_doppler_spectrum(
    axis: plt.Axes, ctf: dict[str, Any], snapshot_interval_s: float
) -> None:
    h = ctf["H"]
    center = h.shape[2] // 2
    sequence = h[:, :, center, :, :]
    spectrum = np.fft.fftshift(np.fft.fft(sequence, axis=2), axes=2)
    power = np.mean(np.abs(spectrum) ** 2, axis=(0, 1, 3))
    frequency = np.fft.fftshift(
        np.fft.fftfreq(sequence.shape[2], d=snapshot_interval_s)
    )
    axis.plot(frequency, _db(power), color=COLORS["orange"])
    axis.set(title="标准图：多普勒功率谱", xlabel="多普勒 (Hz)", ylabel="功率 (dB)")
    _style_axis(axis)


def _plot_time_acf(axis: plt.Axes, ctf: dict[str, Any]) -> None:
    lag, value = _normalized_acf(ctf["H"], axis=3)
    axis.plot(lag, value, color=COLORS["green"])
    axis.set(
        title="标准图：时间自相关",
        xlabel="时间间隔（快照）",
        ylabel="归一化相关",
        ylim=(0, 1.05),
    )
    _style_axis(axis)


def _plot_doppler_cdf(axis: plt.Axes, cir: dict[str, Any]) -> None:
    x, y = _empirical_cdf(_doppler_spread_hz(cir))
    axis.plot(x, y, color=COLORS["orange"])
    axis.set(
        title="标准图：多普勒扩展 CDF",
        xlabel="RMS 多普勒扩展 (Hz)",
        ylabel="累计概率",
        ylim=(0, 1.02),
    )
    _style_axis(axis)


def _plot_heatmap(axis: plt.Axes, cir: dict[str, Any]) -> None:
    bins, heatmap = _delay_heatmap(cir)
    image = axis.imshow(
        heatmap,
        origin="lower",
        aspect="auto",
        extent=(1, heatmap.shape[1], bins[0], bins[-1]),
        cmap="viridis",
    )
    axis.set(
        title="附加图：路线—时延热力图",
        xlabel="有序路线样本",
        ylabel="时延 (ns)",
    )
    plt.colorbar(image, ax=axis, label="功率 (dB)", fraction=0.046)


def render_scenario(
    entry: dict[str, Any],
    data_dir: Path,
    output_dir: Path,
) -> Path:
    cir_data = read_channel_hdf5(data_dir / entry["cir_file"])
    ctf_data = read_channel_hdf5(data_dir / entry["ctf_file"])
    cir = cir_data["cir"]
    ctf = ctf_data["ctf"]
    plotters = {
        "power": lambda axis: _plot_power(axis, ctf),
        "pdp": lambda axis: _plot_pdp(axis, cir),
        "frequency_autocorrelation": lambda axis: _plot_frequency_acf(
            axis, ctf
        ),
        "delay_spread_cdf": lambda axis: _plot_delay_cdf(axis, cir),
        "angular_power_spectrum": lambda axis: _plot_angle_spectrum(
            axis, cir
        ),
        "spatial_correlation": lambda axis: _plot_spatial_correlation(
            axis, ctf
        ),
        "angular_spread_cdf": lambda axis: _plot_angular_cdf(axis, cir),
        "doppler_power_spectrum": lambda axis: _plot_doppler_spectrum(
            axis,
            ctf,
            float(ctf_data["metadata"]["snapshot_interval_s"]),
        ),
        "time_autocorrelation": lambda axis: _plot_time_acf(axis, ctf),
        "doppler_spread_cdf": lambda axis: _plot_doppler_cdf(axis, cir),
    }
    standard_plots = entry["standard_plots"]
    has_heatmap = bool(entry["delay_sample_heatmap"])
    total = len(standard_plots) + int(has_heatmap)
    columns = 1 if total == 1 else 2 if total <= 4 else 3 if total <= 7 else 5
    rows = int(np.ceil(total / columns))
    figure, axes = plt.subplots(
        rows,
        columns,
        figsize=(5.0 * columns, 3.7 * rows),
        constrained_layout=True,
    )
    axes_array = np.atleast_1d(axes).reshape(-1)
    for axis, plot_name in zip(axes_array, standard_plots, strict=False):
        plotters[plot_name](axis)
    if has_heatmap:
        _plot_heatmap(axes_array[len(standard_plots)], cir)
    for axis in axes_array[total:]:
        axis.axis("off")
    shape = " × ".join(str(value) for value in entry["ctf_shape"])
    heatmap_title = " + 1 张附加热力图" if has_heatmap else ""
    figure.suptitle(
        f"{entry['display_name_zh']}｜CTF {shape}\n"
        f"{entry['standard_plot_count']} 张标准图{heatmap_title}",
        fontsize=14,
        fontweight="bold",
    )
    output_path = output_dir / f"{entry['id']}_review.png"
    figure.savefig(output_path, dpi=150, facecolor="white")
    plt.close(figure)
    return output_path


def render_capability_matrix(
    entries: list[dict[str, Any]], output_dir: Path
) -> Path:
    columns = [
        "场景",
        "CTF维度：Tx×Rx×Nf×Nt×N_sample",
        "标准图",
        "路线热力图",
    ]
    rows = [
        [
            entry["display_name_zh"],
            "×".join(str(value) for value in entry["ctf_shape"]),
            str(entry["standard_plot_count"]),
            "附加支持" if entry["delay_sample_heatmap"] else "不支持",
        ]
        for entry in entries
    ]
    figure, axis = plt.subplots(figsize=(13, 3.8))
    axis.axis("off")
    table = axis.table(
        cellText=rows,
        colLabels=columns,
        cellLoc="center",
        loc="center",
        colWidths=[0.20, 0.42, 0.14, 0.18],
    )
    table.auto_set_font_size(False)
    table.set_fontsize(11)
    table.scale(1, 1.8)
    for (row, _), cell in table.get_celld().items():
        if row == 0:
            cell.set_facecolor("#1D4ED8")
            cell.set_text_props(color="white", weight="bold")
        elif row % 2 == 0:
            cell.set_facecolor("#EFF6FF")
        else:
            cell.set_facecolor("#F8FAFC")
    axis.set_title(
        "Step 2 四套标准数据能力总览（热力图不计入 1/3/6/9）",
        fontsize=15,
        fontweight="bold",
        pad=18,
    )
    output_path = output_dir / "capability_matrix.png"
    figure.savefig(output_path, dpi=160, bbox_inches="tight", facecolor="white")
    plt.close(figure)
    return output_path


def write_review_markdown(
    entries: list[dict[str, Any]], output_dir: Path
) -> Path:
    lines = [
        "# Step 2 PR 前可视化审阅",
        "",
        "> 这些图片是标准数据的质量检查预览，不是 Step 5 的正式平台绘图引擎。",
        "> 审阅重点是尺寸、能力分级和物理变化是否符合约定，不评价预测准确度。",
        "",
        "## 一眼看懂四套数据",
        "",
        "![四套数据能力总览](review_assets/step2/capability_matrix.png)",
        "",
    ]
    for index, entry in enumerate(entries, start=1):
        lines.extend(
            [
                f"## {index}. {entry['display_name_zh']}",
                "",
                f"- CTF：`{' × '.join(str(v) for v in entry['ctf_shape'])}`",
                f"- CIR：`{' × '.join(str(v) for v in entry['cir_shape'])}`",
                f"- 标准图：{entry['standard_plot_count']} 张",
                (
                    "- 热力图：1 张附加审阅图，不计入标准数量"
                    if entry["delay_sample_heatmap"]
                    else "- 热力图：窄带无可分辨时延轴，因此不提供"
                ),
                "",
                f"![{entry['display_name_zh']}审阅图]"
                f"(review_assets/step2/{entry['id']}_review.png)",
                "",
            ]
        )
    lines.extend(
        [
            "## 建议你的审阅顺序",
            "",
            "1. 先看总览表中的四个维度和 1/3/6/9 数量是否正确。",
            "2. 再看每张组合图是否随着数据维度增加而逐级增加。",
            "3. 检查所有场景的热力图横轴是否都是 32 个有序路线样本。",
            "4. 检查动态 MIMO 是否能明显看到时间和多普勒相关变化。",
            "5. 确认图片中没有 RMSE、NMSE、Ground Truth 或准确度对比。",
            "",
        ]
    )
    report_path = output_dir.parents[1] / "STEP_2_VISUAL_REVIEW.md"
    report_path.write_text("\n".join(lines), encoding="utf-8")
    return report_path


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--data-dir",
        type=Path,
        default=REPO_ROOT / "demo_data" / "v3_standard_fixtures",
    )
    parser.add_argument(
        "--output-dir",
        type=Path,
        default=REPO_ROOT
        / "docs"
        / "v3.0"
        / "review_assets"
        / "step2",
    )
    args = parser.parse_args()
    args.output_dir.mkdir(parents=True, exist_ok=True)
    manifest = json.loads(
        (args.data_dir / "manifest.json").read_text(encoding="utf-8")
    )
    entries = manifest["entries"]
    render_capability_matrix(entries, args.output_dir)
    for entry in entries:
        render_scenario(entry, args.data_dir, args.output_dir)
    report_path = write_review_markdown(entries, args.output_dir)
    print(f"Rendered Step 2 review package: {report_path}")


if __name__ == "__main__":
    main()
