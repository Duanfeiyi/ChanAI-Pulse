# Step V2-1: QuaDRiGa Minimal Reproducible Generation Pipeline

**Date:** 2026-07-21
**Status:** Design approved, ready for implementation
**Covers:** V2.0 Plan Step V2-1
**Related:** platform_function_design.md, v2.0 work plan

## [S1] Problem

The platform currently uses `6GPCM-Lite`, a self-written stochastic generator that does not call the official QuaDRiGa API. The v2.0 plan requires a genuine QuaDRiGa pipeline to produce dynamic broadband SISO Complex-H `H(t,f)` data with 3GPP-standard scenarios for training a Base Model.

Without this, no trustworthy Complex-H data contract, Benchmark, or Base Model can be established.

## [S2] Solution Overview

Create an Adapter-pattern pipeline that wraps the official QuaDRiGa API:

```
GenerationConfig → validate → quadriga_adapter → GenerationResult
                                                    ├→ complex_h [T, F]
                                                    ├→ path_coefficients, delays, Doppler
                                                    ├→ trajectory, BS position
                                                    └→ metadata (scenario, seed, axes)
```

Code lives in `core/generation/quadriga/`, parallel to existing `core/generation/` modules.

## [S3] File Structure

```
core/generation/quadriga/
├── default_quadriga_config.m          % Default config with all parameters
├── validate_quadriga_config.m         % Config validation
├── quadriga_adapter.m                 % Main entry: Config → QuaDRiGa → Result
├── quadriga_check.m                   % Environment check (QuaDRiGa installed/version)
├── quadriga_scenarios.m               % 3GPP scenario registry (6 scenarios)
├── quadriga_result_to_complex_h.m     % Convert Result to H(t,f) complex matrix
├── quadriga_result_to_dpsd.m          % Convert Result to DPSD for legacy compat
├── generate_quadriga_demo.m           % Generate small public demo dataset
└── test_quadriga_adapter.m            % Self-test suite

demo_data/quadriga_demo/               % Generated demo output
├── metadata.json
└── data/
    └── quadriga_demo_*.mat
```

## [S4] Configuration Design

```matlab
config = struct();
% Core
config.scenario = "3GPP_38.901_UMi";
config.carrier_freq_ghz = 3.5;
config.bandwidth_mhz = 100;
config.num_subcarriers = 64;
config.snapshots = 100;
config.snapshot_interval_s = 0.01;
config.random_seed = 42;
% Mobility
config.ue_speed_mps = 3;
config.bs_height_m = 25;
config.ue_height_m = 1.5;
config.ue_trajectory = [];    % Nx3, auto-gen if empty
% Antenna (SISO for v2.0)
config.bs_antenna_elements = 1;
config.ue_antenna_elements = 1;
% QuaDRiGa
config.quadriga_version = "2.6";
config.num_clusters = 12;
config.num_rays_per_cluster = 20;
config.output_format = "complex_h";
```

## [S5] Result Struct

```matlab
result.engine = "QuaDRiGa";
result.scenario = config.scenario;
result.complex_h = complex(zeros(T, F));  % H(t,f)
result.time_axis_s = (0:T-1) * dt;
result.freq_axis_hz = linspace(-bw/2, bw/2, F);
result.carrier_freq_hz = fc;
result.bandwidth_hz = bw;
result.path_coefficients = [];
result.path_delays_s = [];
result.path_doppler_hz = [];
result.ue_trajectory_m = [];
result.bs_position_m = [];
result.random_seed = config.random_seed;
result.generation_time_s = toc;
result.data_source = "quadriga_synthetic";
result.is_reproducible = true;
```

## [S6] 3GPP Scenario Registry

| ID | BS Height | UE Speed | Clusters | Rays | Notes |
|---|---|---|---|---|---|
| 3GPP_38.901_UMi | 10m | 3 km/h | 12 | 20 | Urban Micro NLOS |
| 3GPP_38.901_UMi-LOS | 10m | 3 km/h | 12 | 20 | Urban Micro LOS |
| 3GPP_38.901_UMa | 25m | 3 km/h | 12 | 20 | Urban Macro NLOS |
| 3GPP_38.901_UMa-LOS | 25m | 3 km/h | 12 | 20 | Urban Macro LOS |
| 3GPP_38.901_RMa | 35m | 30 km/h | 10 | 20 | Rural Macro |
| 3GPP_38.901_INH | 3m | 3 km/h | 12 | 20 | Indoor Hotspot |

Each scenario provides default physical parameters that can be overridden via config.

## [S7] Multi-Band Support

| Band | Carrier Freq Range | Bandwidth | Subcarriers | Notes |
|---|---|---|---|---|
| Sub-6 GHz | 1-6 GHz | 20-100 MHz | 64-256 | Most common deployment |
| mmWave | 24-40 GHz | 100-400 MHz | 128-512 | High capacity |
| THz | 100-300 GHz | 200-1000 MHz | 256-1024 | Future research band |

Carrier frequency affects path loss model, delay spread, and Doppler characteristics.

## [S8] H(t,f) Derivation

The adapter calls QuaDRiGa to obtain:
1. Path coefficients (complex gains per path per snapshot)
2. Path delays (per cluster)
3. Per-path Doppler frequencies

Then derives H(t,f) via:
```
H(t,f) = sum_l  a_l(t) * exp(-j*2*pi*f*tau_l) * exp(j*2*pi*f_D_l*t)
```
where `a_l` is the complex path gain, `tau_l` is the path delay, and `f_D_l` is the Doppler shift.

This is the standard OFDM channel model in the frequency domain.

## [S9] Test Strategy

1. **Seed reproducibility**: Same config + seed → identical `complex_h`
2. **Dimension consistency**: `size(complex_h) == [T, F]`
3. **Complex-valued**: `iscomplex(result.complex_h)`
4. **Time continuity**: Adjacent snapshots have bounded phase difference
5. **Coordinate completeness**: All axes non-empty and physically consistent
6. **Scenario coverage**: All 6 scenarios produce valid results
7. **Multi-band**: Sub-6, mmWave, THz configs produce correct frequency axes
8. **Cross-run reproducibility**: Two calls with same config → identical output

## [S10] Acceptance Criteria

- Same version, config, and random seed can reproduce results
- Generated results have clear time/frequency axes with physical units
- All 6 3GPP scenarios work without error
- Multi-band (Sub-6/mmWave/THz) produces correct frequency axes
- Small public synthetic demo can be generated and loaded
- Self-test suite passes
- No old "Quadriga 3D CSI" scripts mislabeled as real QuaDRiGa data
- Pipeline is independent of v1.0 code; does not break existing functionality
