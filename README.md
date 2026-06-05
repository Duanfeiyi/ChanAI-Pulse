# ChanAI Pulse

**ChanAI Pulse** is an AI-driven universal channel characterization, generation and prediction platform for full-frequency and full-scenario wireless channel research, with 6G-oriented applications.

ChanAI Pulse is currently released as a MATLAB desktop research prototype and MATLAB App Package. It is designed to support channel research across Sub-6 GHz, mmWave, THz, optical wireless, satellite, UAV, maritime, RIS, industrial IoT, ISAC-oriented, and other emerging wireless scenarios.

> Current release: v1.0.0  
> Source code: [https://github.com/Duanfeiyi/ChanAI-Pulse](https://github.com/Duanfeiyi/ChanAI-Pulse)  
> Release page: [ChanAI Pulse v1.0.0](https://github.com/Duanfeiyi/ChanAI-Pulse/releases/tag/v1.0.0)

## Release Download

The v1.0.0 release provides a MATLAB App Package:

```text
ChanAI_Pulse_v1.0.0.mlappinstall
```

This package requires MATLAB and the required toolboxes. It is **not** a standalone executable and does not include MATLAB Runtime packaging.

Installation notes:

- Chinese installation guide: `release/github_release_assets/INSTALL_CN.md`
- Release README: `release/github_release_assets/README_RELEASE.md`
- Release description: `release/github_release_assets/RELEASE_DESCRIPTION.md`

## Key Features

- MATLAB desktop App with the original three-module GUI workflow.
- Bilingual English / Chinese interface support.
- Full-frequency and full-scenario research positioning with 6G-oriented applications.
- Channel characterization and visualization workflow.
- Stochastic channel generation and synthetic data workflow.
- Channel prediction and training workflow.
- TCN, LSTM, and GRU model selection support.
- Small public synthetic demo data for loading and visualization checks.
- Clear local measured dataset policy.
- Collaboration, release, and benchmark planning documents for student research teams.

## Core Modules

### Channel Characterization

Loads MATLAB channel-like data and supports characteristic analysis such as angular spectrum, delay-domain behavior, Doppler-related behavior, and spread distribution visualization.

### Channel Generation

Provides MATLAB-native stochastic channel generation and data augmentation workflows for controlled synthetic channel experiments.

### Channel Prediction & Training

Supports the existing MATLAB App prediction and training workflow with TCN, LSTM, and GRU model options. The v1.0.0 public release preserves the current training and prediction behavior.

## System Workflow

```text
Measured or synthetic channel-like data
  |
  v
Channel characterization
  |
  v
Channel generation and augmentation
  |
  v
AI training and prediction
  |
  v
Metric evaluation and validation
```

## MATLAB Requirements

Recommended MATLAB version:

- MATLAB R2022b or later

Required toolboxes:

- Deep Learning Toolbox
- Signal Processing Toolbox
- Statistics and Machine Learning Toolbox

Recommended toolboxes:

- Communications Toolbox
- 5G Toolbox

## Quick Start From Source

Clone the repository:

```bash
git clone https://github.com/Duanfeiyi/ChanAI-Pulse.git
cd ChanAI-Pulse
```

In MATLAB:

```matlab
addpath(genpath(pwd))
run("tests/smoke_test.m")
ChannelSimulatorApp
```

## Demo Data

The repository includes small synthetic demo files:

- `demo_data/demo_sub6_scenario1.mat`
- `demo_data/demo_mmwave_scenario2.mat`

These files are synthetic demo data for GUI loading and visualization checks only. They are not measured datasets and must not be used as formal scientific benchmark evidence.

To regenerate the demo data:

```matlab
run("demo_data/generate_demo_data.m")
```

## Dataset Policy

No private measured datasets are included in this public repository or v1.0.0 Release.

The GitHub repository only contains synthetic demo data. Private measured data, local raw archives, extracted previews, large experiment outputs, and legacy backups must not be uploaded.

See:

- `docs/DATASET_POLICY.md`
- `docs/CHANAIS_DATASET_PLAN.md`

## Project Showcase

A text-based project overview for supervisors, collaborators, and industry visitors is available in:

- `docs/PROJECT_SHOWCASE.md`

The current repository does not include GUI screenshots. Screenshots may be added later after a separate manual review and privacy check.

## Benchmark And Dataset Roadmap

ChanAI Pulse will be extended with a future ChanAIs Dataset and benchmark ecosystem after authorization, anonymization, schema unification, and task definition work is complete.

Planning documents:

- `docs/CHANAIS_DATASET_PLAN.md`
- `docs/BENCHMARK_PLAN.md`
- `ROADMAP.md`

## Project Structure

```text
app/                  MATLAB App entry point
core/                 Low-risk extracted helper functions
configs/              Public configuration notes
demo_data/            Public synthetic demo data
docs/                 User, collaboration, dataset, and planning docs
release/              Release notes and packaging workflow docs
tests/                Smoke tests and validation probes
```

Local-only directories such as `datasets/`, `legacy/`, `experiments/`, `models/`, and `results/` are ignored for public release unless explicitly reviewed and approved.

## Collaboration

Team workflow documentation is available in:

- `docs/GITHUB_WORKFLOW.md`
- `docs/CONTRIBUTING.md`
- `docs/GUI_MANUAL_TEST_CHECKLIST.md`
- `docs/RELEASE_CHECKLIST.md`

## Citation

If you use ChanAI Pulse in your research, please cite this repository and related publications.

See `CITATION.cff`.

## License

ChanAI Pulse is released under the Apache License 2.0. See `LICENSE`.

## Acknowledgements

ChanAI Pulse is developed as a research-oriented platform for full-frequency and full-scenario wireless channel modeling, generation, and AI-based prediction, with 6G-oriented applications.

