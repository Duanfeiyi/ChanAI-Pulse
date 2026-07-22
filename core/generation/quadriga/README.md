# QuaDRiGa Generation Pipeline (v2.0)

## Overview

This module wraps the official QuaDRiGa API to generate dynamic broadband SISO
Complex-H channel data `H(t,f)` with 3GPP-standard scenarios.

## Third-Party Dependency: QuaDRiGa

**This module requires QuaDRiGa, which is NOT covered by the project's Apache-2.0 license.**

QuaDRiGa is provided by Fraunhofer HHI under its own
[Software License for The QuaDRiGa Channel Model](https://quadriga-channel-model.de/).
Key terms:

- **Non-commercial use only** — academic research and education
- **No redistribution** — QuaDRiGa source code must NOT be included in this repository
- **Separate installation required** — users must obtain QuaDRiGa independently
- **License file** — see `QuaDriGa_2023.12.13_v2.8.1-0/QuaDRiGa_License.txt` (local reference only)

This repository contains ONLY the adapter code (`.m` files in `core/generation/quadriga/`),
NOT the QuaDRiGa source, config files, or binary artifacts.

## Prerequisites

- MATLAB R2022b+
- QuaDRiGa 2.6+ installed separately and on MATLAB path
- Deep Learning Toolbox

## Quick Start

```matlab
% Check environment
status = quadriga_check();
disp(status);

% Configure
config = default_quadriga_config();
config.scenario = "3GPP_38.901_UMi";
config.carrier_freq_ghz = 3.5;
config.bandwidth_mhz = 100;
config.snapshots = 100;
config.random_seed = 42;

% Generate
result = quadriga_adapter(config);

% Access H(t,f)
[complex_h, time_axis, freq_axis] = quadriga_result_to_complex_h(result);
```

## Supported Scenarios

| Scenario | BS Height | UE Speed | Type |
|---|---|---|---|
| 3GPP_38.901_UMi | 10m | 3 km/h | Urban Micro NLOS |
| 3GPP_38.901_UMi-LOS | 10m | 3 km/h | Urban Micro LOS |
| 3GPP_38.901_UMa | 25m | 3 km/h | Urban Macro NLOS |
| 3GPP_38.901_UMa-LOS | 25m | 3 km/h | Urban Macro LOS |
| 3GPP_38.901_RMa | 35m | 30 km/h | Rural Macro NLOS |
| 3GPP_38.901_RMa-LOS | 35m | 30 km/h | Rural Macro LOS |
| 3GPP_38.901_INH | 3m | 3 km/h | Indoor Hotspot |

## Multi-Band Support

- Sub-6 GHz (1-6 GHz)
- mmWave (24-40 GHz)
- THz (100-300 GHz)

## Testing

```matlab
results = test_quadriga_adapter();
```

## Data Safety

- This module generates synthetic data only
- No real measurement data is read, stored, or transmitted
- All outputs are clearly labeled as synthetic
