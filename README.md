# ChanAI Pulse

**ChanAI Pulse** is an AI-based Predictive Channel Modeling Platform for 6G multi-band and multi-scenario communications.

This v1.0.0 Release Candidate is a MATLAB desktop research prototype. It focuses on keeping the existing MATLAB App runnable, preserving the original three-module workflow, and preparing the project for a clean public GitHub release.

## Overview

ChanAI Pulse is designed for integrated 6G channel research across bands and scenarios such as Sub-6 GHz, mmWave, THz, optical wireless, satellite, UAV, maritime, RIS, industrial IoT, and ISAC-oriented environments.

The current release centers on three workflows:

- Channel Characterization
- Channel Generation
- Channel Prediction & Training

The repository includes source code, documentation, tests, and small synthetic demo data. It does **not** include private measured datasets, thesis PDFs, defense slides, or installer binaries.

## Key Features

- MATLAB desktop App with a three-tab GUI.
- Bilingual UI support for English and Chinese.
- Multi-band and multi-scenario entry points.
- Channel characteristic visualization.
- Native stochastic channel generation workflow.
- AI prediction and training workflow.
- TCN, LSTM, and GRU model selection support.
- Low-risk extracted helper functions under `core/`.
- Small synthetic demo data for public loading and visualization checks.
- Local measured dataset audit and policy documentation.
- GitHub collaboration guides for student teams.

## System Architecture

```text
MATLAB App GUI
  |
  +-- Channel Characterization
  |     +-- raw data extraction
  |     +-- angular spectrum estimation
  |     +-- delay / Doppler / spread visualization
  |
  +-- Channel Generation
  |     +-- stochastic channel generation
  |     +-- synthetic channel tensor workflow
  |     +-- send-to-AI data path
  |
  +-- Channel Prediction & Training
        +-- TCN / LSTM / GRU selection
        +-- recursive prediction workflow
        +-- RMSE / NRMSE / capacity-oriented metrics
```

## Modules

### Channel Characterization

Loads channel-like MATLAB data and visualizes key channel characteristics such as angular power, delay power, Doppler behavior, and spread CDF.

### Channel Generation

Provides a MATLAB-native stochastic generation workflow for synthetic channel data and data augmentation experiments.

### Channel Prediction & Training

Supports TCN, LSTM, and GRU model selection in the existing MATLAB App workflow. The v1.0.0 RC preserves the current training and prediction behavior.

## Screenshots

Screenshots will be added after final manual GUI validation.

Recommended screenshots:

- Characterization page
- Channel Generation page
- Prediction & Training page
- English/Chinese UI switch

## Installation

Clone the repository and open MATLAB from the project root.

```bash
git clone https://github.com/your-org/ChanAI-Pulse.git
cd ChanAI-Pulse
```

In MATLAB:

```matlab
addpath(genpath(pwd))
run("tests/smoke_test.m")
ChannelSimulatorApp
```

## MATLAB Requirements

Validated local environment:

- MATLAB R2022b
- Deep Learning Toolbox
- Signal Processing Toolbox
- Statistics and Machine Learning Toolbox

MATLAB Compiler is not currently available in the validated local installation, so an installer is not provided in this RC.

## Quick Start

1. Open MATLAB.
2. Change directory to the repository root.
3. Run:

```matlab
addpath(genpath(pwd))
run("tests/smoke_test.m")
ChannelSimulatorApp
```

4. Use `demo_data/` for public synthetic loading and visualization checks.

## Demo Data

The repository includes small synthetic demo files:

- `demo_data/demo_sub6_scenario1.mat`
- `demo_data/demo_mmwave_scenario2.mat`

These files are generated data for GUI loading and visualization tests only. They are not measured datasets and must not be used as scientific benchmark evidence.

To regenerate:

```matlab
run("demo_data/generate_demo_data.m")
```

## Measured Dataset Policy

Private measured datasets are not included in this public repository.

Measured data under local paths such as `datasets/measured/raw_archives/` and `datasets/measured/extracted_preview/` are for internal validation only. They must not be committed, uploaded, copied into `demo_data/`, or published through GitHub.

Only synthetic demo data is included in this repository. A future ChanAIs Dataset release, if any, should be handled as a separate dataset project with independent authorization, metadata, versioning, and licensing.

See `docs/DATASET_POLICY.md`.

## Project Structure

```text
app/                  MATLAB App entry point
core/                 Low-risk extracted helper functions
datasets/measured/    Local-only measured dataset documentation
demo_data/            Public synthetic demo data
docs/                 User, release, dataset, and collaboration docs
legacy/               Original App backup
release/              Packaging and MATLAB Compiler diagnosis
tests/                Smoke tests and validation probes
```

## GitHub Collaboration

Team workflow documentation is available in:

- `docs/GITHUB_WORKFLOW.md`
- `docs/CONTRIBUTING.md`
- `docs/GUI_MANUAL_TEST_CHECKLIST.md`
- `docs/RELEASE_CHECKLIST.md`

Recommended future branch structure:

```text
main
dev
feature/ui
feature/data
feature/benchmark
feature/docs
feature/prediction
```

## Roadmap

See `ROADMAP.md`.

Short version:

- v1.0.0: MATLAB desktop Release Candidate
- v1.1.0: benchmark and experiment-management improvements
- v1.2.0: MATLAB installer after MATLAB Compiler issue is resolved
- v2.0.0: ChanAIs Dataset and possible Web/Python migration exploration

## Citation

If you use ChanAI Pulse in your research, please cite this repository and related publications.

See `CITATION.cff`.

## License

ChanAI Pulse is released under the Apache License 2.0. See `LICENSE`.

## Acknowledgements

ChanAI Pulse is developed as a research-oriented 6G channel modeling and AI prediction platform. The v1.0.0 RC prioritizes reproducibility, maintainability, and safe open-source project structure.

