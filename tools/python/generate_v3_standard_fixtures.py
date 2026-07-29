"""Generate the four deterministic ChanAI Pulse v3 standard fixtures.

The public functions make the Step 2 input and output explicit:

``load_scenarios(path) -> list[dict]``
``generate_pair(scenario) -> {"cir": ..., "ctf": ..., "expected": ...}``
``write_all(output_dir, config_path) -> manifest dict``

The output uses the Step 1 HDF5 mapping: complex tensors are flattened in
MATLAB column-major order and accompanied by their canonical five-D shape.
Existing files are never overwritten.
"""

from __future__ import annotations

import argparse
import json
import math
from pathlib import Path
from typing import Any

import h5py
import numpy as np

REPO_ROOT = Path(__file__).resolve().parents[2]
DEFAULT_CONFIG = REPO_ROOT / "configs" / "v3_standard_scenarios.json"

STANDARD_PLOTS = {
    "narrowband_static_siso": ["power"],
    "wideband_static_siso": [
        "pdp",
        "frequency_autocorrelation",
        "delay_spread_cdf",
    ],
    "wideband_static_mimo": [
        "pdp",
        "frequency_autocorrelation",
        "delay_spread_cdf",
        "angular_power_spectrum",
        "spatial_correlation",
        "angular_spread_cdf",
    ],
    "wideband_dynamic_mimo": [
        "pdp",
        "frequency_autocorrelation",
        "delay_spread_cdf",
        "angular_power_spectrum",
        "spatial_correlation",
        "angular_spread_cdf",
        "doppler_power_spectrum",
        "time_autocorrelation",
        "doppler_spread_cdf",
    ],
}


def load_scenarios(config_path: Path = DEFAULT_CONFIG) -> list[dict[str, Any]]:
    """Load and expand the frozen Step 2 scenario configuration."""

    document = json.loads(config_path.read_text(encoding="utf-8"))
    scenarios: list[dict[str, Any]] = []
    for source in document["scenarios"]:
        scenario = dict(source)
        scenario["schema_version"] = document["schema_version"]
        scenario["sample_semantics"] = document["sample_semantics"]
        scenario["N_sample"] = int(document["sample_count"])
        scenario["route_spacing_m"] = float(document["route_spacing_m"])
        scenarios.append(scenario)
    return scenarios


def generate_pair(scenario: dict[str, Any]) -> dict[str, Any]:
    """Generate matching path-domain CIR and frequency-domain CTF arrays."""

    tx_count = int(scenario["Tx"])
    rx_count = int(scenario["Rx"])
    frequency_count = int(scenario["Nf"])
    time_count = int(scenario["Nt"])
    path_count = int(scenario["Npath"])
    sample_count = int(scenario["N_sample"])
    center_hz = float(scenario["center_frequency_hz"])
    spacing_hz = float(scenario["subcarrier_spacing_hz"])
    snapshot_interval_s = float(scenario["snapshot_interval_s"])
    wavelength_m = 299_792_458.0 / center_hz
    element_spacing_m = wavelength_m / 2.0

    sample_index = np.arange(1, sample_count + 1, dtype=np.float64)
    sample_zero = sample_index - 1.0
    positions = np.column_stack(
        (
            sample_zero * float(scenario["route_spacing_m"]),
            0.25 * np.sin(2.0 * np.pi * sample_zero / sample_count),
            np.zeros(sample_count),
        )
    )
    time_s = np.arange(time_count, dtype=np.float64) * snapshot_interval_s
    frequency_offsets_hz = (
        np.arange(frequency_count, dtype=np.float64)
        - (frequency_count - 1.0) / 2.0
    ) * spacing_hz
    frequency_hz = center_hz + frequency_offsets_hz

    base_delay_s = np.linspace(0.0, 260e-9, path_count)
    if path_count == 1:
        base_delay_s[0] = 0.0
    base_power = 10.0 ** (-np.arange(path_count) * 3.5 / 10.0)
    base_power /= base_power.sum()
    base_aoa = np.linspace(-0.75, 0.85, path_count)
    base_aod = np.linspace(0.65, -0.55, path_count)
    if time_count > 1:
        base_doppler_hz = np.linspace(-90.0, 110.0, path_count)
    else:
        base_doppler_hz = np.zeros(path_count)
    path_number = np.arange(1, path_count + 1, dtype=np.float64)
    initial_phase = np.mod(
        float(scenario["seed"]) * 0.0137
        + path_number * 1.61803398875,
        2.0 * np.pi,
    )

    coefficient = np.zeros(
        (tx_count, rx_count, path_count, time_count, sample_count),
        dtype=np.complex64,
        order="F",
    )
    path_shape = (1, 1, path_count, time_count, sample_count)
    delay_s = np.zeros(path_shape, dtype=np.float32, order="F")
    aoa_rad = np.zeros(path_shape, dtype=np.float32, order="F")
    aod_rad = np.zeros(path_shape, dtype=np.float32, order="F")
    doppler_hz = np.zeros(path_shape, dtype=np.float32, order="F")

    for sample in range(sample_count):
        route_phase = 2.0 * np.pi * sample / sample_count
        for time in range(time_count):
            time_value = time_s[time]
            for path in range(path_count):
                number = path + 1
                path_delay = base_delay_s[path] + (
                    4e-9 + number * 0.7e-9
                ) * math.sin(route_phase + 0.45 * number)
                path_delay += base_doppler_hz[path] * time_value * 2e-12
                path_delay = max(path_delay, 0.0)
                aoa = base_aoa[path] + 0.08 * math.sin(
                    route_phase + 0.3 * number
                )
                aod = base_aod[path] + 0.07 * math.cos(
                    route_phase + 0.2 * number
                )
                route_fading = 0.82 + 0.18 * math.cos(
                    route_phase * (1.0 + 0.08 * number) + 0.6 * number
                )
                amplitude = math.sqrt(
                    base_power[path] * max(route_fading, 0.05)
                )
                temporal_phase = (
                    2.0 * np.pi * base_doppler_hz[path] * time_value
                )
                route_phase_term = 0.24 * sample * number

                delay_s[0, 0, path, time, sample] = path_delay
                aoa_rad[0, 0, path, time, sample] = aoa
                aod_rad[0, 0, path, time, sample] = aod
                doppler_hz[0, 0, path, time, sample] = (
                    base_doppler_hz[path]
                )
                for tx in range(tx_count):
                    tx_phase = (
                        2.0
                        * np.pi
                        * tx
                        * element_spacing_m
                        * math.sin(aod)
                        / wavelength_m
                    )
                    for rx in range(rx_count):
                        rx_phase = (
                            2.0
                            * np.pi
                            * rx
                            * element_spacing_m
                            * math.sin(aoa)
                            / wavelength_m
                        )
                        phase = (
                            initial_phase[path]
                            + temporal_phase
                            + route_phase_term
                            + tx_phase
                            + rx_phase
                        )
                        coefficient[tx, rx, path, time, sample] = (
                            amplitude * np.exp(1j * phase)
                        )

    ctf = np.zeros(
        (tx_count, rx_count, frequency_count, time_count, sample_count),
        dtype=np.complex64,
        order="F",
    )
    for frequency, offset_hz in enumerate(frequency_offsets_hz):
        phase = np.exp(
            -1j * 2.0 * np.pi * np.float32(offset_hz) * delay_s
        )
        ctf[:, :, frequency, :, :] = np.sum(
            coefficient * phase, axis=2
        )

    metadata = {
        "source": "deterministic_v3_standard_fixture",
        "sample_semantics": scenario["sample_semantics"],
        "created_utc": "2026-07-29T00:00:00Z",
        "generator": "ChanAI Pulse deterministic fixture generator",
        "generator_version": "v3.0-step2.1",
        "random_seed": int(scenario["seed"]),
        "scenario_id": scenario["id"],
        "scenario_name_zh": scenario["display_name_zh"],
        "center_frequency_hz": center_hz,
        "subcarrier_spacing_hz": spacing_hz,
        "snapshot_interval_s": snapshot_interval_s,
        "tx_array": {
            "type": "ULA",
            "element_count": tx_count,
            "element_spacing_m": element_spacing_m,
        },
        "rx_array": {
            "type": "ULA",
            "element_count": rx_count,
            "element_spacing_m": element_spacing_m,
        },
        "config": scenario,
    }
    expected_plots = STANDARD_PLOTS[scenario["id"]]
    return {
        "scenario": scenario,
        "metadata": metadata,
        "axes": {
            "sample_index": sample_index.reshape(-1, 1),
            "sample_position_m": positions,
            "time_s": time_s.reshape(-1, 1),
            "frequency_hz": frequency_hz.reshape(-1, 1),
        },
        "cir": {
            "coefficient": coefficient,
            "delay_s": delay_s,
            "path_valid": np.ones(path_shape, dtype=np.uint8, order="F"),
            "aoa_rad": aoa_rad,
            "aod_rad": aod_rad,
            "doppler_hz": doppler_hz,
        },
        "ctf": {"H": ctf},
        "expected": {
            "classification": scenario["id"],
            "standard_plots": expected_plots,
            "standard_plot_count": len(expected_plots),
            "delay_sample_heatmap": scenario["id"]
            != "narrowband_static_siso",
            "heatmap_is_additional": True,
        },
    }


def _write_flat(
    handle: h5py.File, base_path: str, value: np.ndarray
) -> None:
    array = np.asarray(value)
    handle[f"{base_path}_values"] = array.reshape(-1, order="F")
    handle[f"{base_path}_shape"] = np.asarray(
        array.shape, dtype=np.uint64
    ).reshape(-1, 1)


def _write_complex(
    handle: h5py.File, base_path: str, value: np.ndarray
) -> None:
    _write_flat(handle, f"{base_path}_real", value.real)
    _write_flat(handle, f"{base_path}_imag", value.imag)


def _write_common_attributes(
    handle: h5py.File,
    domain: str,
    dimension_order: list[str],
    metadata: dict[str, Any],
) -> None:
    handle.attrs["schema_version"] = "v3.0-data-contract.1"
    handle.attrs["domain"] = domain
    handle.attrs["dimension_order_json"] = json.dumps(
        dimension_order, ensure_ascii=False
    )
    handle.attrs["units_json"] = json.dumps(
        {
            "frequency": "Hz",
            "time": "s",
            "delay": "s",
            "position": "m",
            "angle": "rad",
            "power": "linear",
        }
    )
    handle.attrs["metadata_json"] = json.dumps(
        metadata, ensure_ascii=False, sort_keys=True
    )
    handle.attrs["complex_storage"] = "separate_real_imag"
    handle.attrs["flatten_order"] = "MATLAB_column_major"


def write_pair(output_dir: Path, pair: dict[str, Any]) -> dict[str, Any]:
    """Write one fixture pair and return its manifest entry."""

    scenario = pair["scenario"]
    scenario_id = scenario["id"]
    cir_name = f"{scenario_id}_cir.h5"
    ctf_name = f"{scenario_id}_ctf.h5"
    cir_path = output_dir / cir_name
    ctf_path = output_dir / ctf_name
    for path in (cir_path, ctf_path):
        if path.exists():
            raise FileExistsError(f"Refusing to overwrite fixture: {path}")

    with h5py.File(cir_path, "w") as handle:
        _write_common_attributes(
            handle,
            "cir",
            ["Tx", "Rx", "Npath", "Nt", "N_sample"],
            pair["metadata"],
        )
        _write_complex(handle, "/cir/coefficient", pair["cir"]["coefficient"])
        for field in (
            "delay_s",
            "path_valid",
            "aoa_rad",
            "aod_rad",
            "doppler_hz",
        ):
            _write_flat(handle, f"/cir/{field}", pair["cir"][field])
        for field in ("sample_index", "sample_position_m", "time_s"):
            _write_flat(handle, f"/axes/{field}", pair["axes"][field])

    with h5py.File(ctf_path, "w") as handle:
        _write_common_attributes(
            handle,
            "ctf",
            ["Tx", "Rx", "Nf", "Nt", "N_sample"],
            pair["metadata"],
        )
        _write_complex(handle, "/ctf/H", pair["ctf"]["H"])
        for field in (
            "frequency_hz",
            "time_s",
            "sample_index",
            "sample_position_m",
        ):
            _write_flat(handle, f"/axes/{field}", pair["axes"][field])

    return {
        "id": scenario_id,
        "display_name_zh": scenario["display_name_zh"],
        "seed": int(scenario["seed"]),
        "cir_file": cir_name,
        "ctf_file": ctf_name,
        "cir_shape": list(pair["cir"]["coefficient"].shape),
        "ctf_shape": list(pair["ctf"]["H"].shape),
        **pair["expected"],
    }


def write_all(
    output_dir: Path, config_path: Path = DEFAULT_CONFIG
) -> dict[str, Any]:
    """Write all four fixture pairs and a deterministic manifest."""

    output_dir.mkdir(parents=True, exist_ok=True)
    manifest_path = output_dir / "manifest.json"
    if manifest_path.exists():
        raise FileExistsError(
            f"Refusing to overwrite existing manifest: {manifest_path}"
        )
    entries = [
        write_pair(output_dir, generate_pair(scenario))
        for scenario in load_scenarios(config_path)
    ]
    manifest = {
        "schema_version": "v3.0-standard-fixtures.1",
        "data_contract_version": "v3.0-data-contract.1",
        "generated_utc": "2026-07-29T00:00:00Z",
        "deterministic": True,
        "sample_semantics": "ordered_route",
        "heatmap_is_additional": True,
        "entries": entries,
    }
    manifest_path.write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    return manifest


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--output",
        type=Path,
        default=REPO_ROOT / "demo_data" / "v3_standard_fixtures",
    )
    parser.add_argument("--config", type=Path, default=DEFAULT_CONFIG)
    args = parser.parse_args()
    manifest = write_all(args.output, args.config)
    print(
        f"Generated {len(manifest['entries'])} deterministic "
        f"CIR/CTF fixture pairs in {args.output}"
    )


if __name__ == "__main__":
    main()
