# ChanAI Pulse

ChanAI Pulse is a MATLAB desktop research prototype for channel-data characterization, lightweight synthetic channel generation, and baseline time-series prediction. The public repository is intended for reproducible code review, synthetic demonstrations, and research-development collaboration; it is not a packaged end-user product or a validated all-band/all-scenario channel-prediction system.

**Current released baseline:** v1.1.0. The current `main` branch also contains v2.0 design documents; those documents are plans, not implemented v2.0 functionality.

## What is implemented

- A MATLAB App with three pages: **Characterization**, **Channel Generation**, and **Prediction & Training**.
- Loading one or more local MATLAB files, extracting a compatible numeric channel representation, and rendering four legacy characteristics: angular display, delay-power display, delay-spread CDF, and normalized Doppler display.
- The internal `6GPCM-lite` clustered synthetic generator, deterministic with a configured seed, plus conversion of its generated CIR output into the legacy DPSD training representation.
- Time-domain DPSD sequence experiments with chronological Train / Validation / Test partitions (default 70% / 15% / 15%), training-only normalization, and TCN, LSTM, or GRU baseline models.
- Generated samples may be appended to the training partition; validation and test use the real evaluation sequence.
- MATLAB-level dataset-contract validation, SAGE-compatible conversion helpers, automated tests, model export, and prediction-result export selected by the user at run time.

## Important current limits

- The current prediction workflow is a **legacy power/DPSD time-domain baseline**, not complex-valued channel-matrix \(H\) prediction.
- `Freq` and `Space` are interface selections only; they do not yet route to independent frequency- or spatial-domain prediction pipelines.
- The GUI directly loads compatible `.mat` files. ChanAIs dataset validation/loading helpers exist, but a ChanAIs dataset-root browser is not yet wired into the App.
- `6GPCM-lite` is an internal lightweight synthetic generator, not official 6GPCM or QuaDRiGa. It is suitable for engineering tests and controlled augmentation experiments, not standalone physical-validation claims.
- The legacy DS-CDF evaluation function uses a Gaussian approximation, not an empirical CDF. See [open issues](docs/OPEN_ISSUES_AND_REFACTOR_ROADMAP.md).
- Current band and scenario controls provide UI configuration and defaults; they are not evidence that every listed band or scenario has been scientifically validated.
- Complex-H, Base Model, online adaptation, QuaDRiGa integration, dynamic wideband MIMO, and space-time-frequency \(H\) tensor prediction are future v2.0 directions.

## Requirements

- MATLAB with Deep Learning Toolbox, Signal Processing Toolbox, and Statistics and Machine Learning Toolbox.
- MATLAB R2022b was used for the original baseline; compatibility with other releases should be verified locally.
- Communications Toolbox and 5G Toolbox are not required by the current automated smoke test, but may be useful for broader research work.

## Quick start

Clone the repository, open MATLAB in the repository root, and run:

```matlab
addpath(genpath(pwd))
run("tests/smoke_test.m")
ChannelSimulatorApp
```

`ChannelSimulatorApp` is the public App entry point. The App startup routine also registers `app/plotting/` and `core/` paths, but adding the repository tree explicitly is the supported development and test workflow.

The public `demo_data/` files are synthetic and may be used for a basic loading demonstration. They are not benchmark evidence. Never add private measurements, local model files, or experiment outputs to the repository.

## Current workflow

```text
Local compatible MAT files
  -> legacy characterization and visualization
  -> optional 6GPCM-lite synthetic generation
  -> DPSD sequence preparation
  -> chronological Train / Validation / Test experiment
  -> TCN / LSTM / GRU baseline training
  -> held-out evaluation and recursive future prediction
```

When generated data is selected, the App keeps it in the training-source path; held-out validation and test targets are drawn from the real/evaluation sequence.

## Repository layout

```text
app/                 MATLAB App and external plot renderers
core/                GUI-independent MATLAB logic
configs/             reserved public configuration area
demo_data/           small synthetic demonstration data only
docs/                current implementation docs, plans, and historical records
release/             source-release and packaging notes
tests/               MATLAB automated tests and opt-in local checks
tools/                dataset conversion and documentation utilities
```

See [Repository Structure](docs/REPOSITORY_STRUCTURE.md) for the complete, maintained directory guide.

## Documentation

Start with the [documentation index](docs/README.md).

- [API Reference](docs/API_REFERENCE.md)
- [Feature-to-Code Map](docs/FEATURE_TO_CODE_MAP.md)
- [Data Contracts](docs/DATA_CONTRACTS.md)
- [Testing Guide](docs/TESTING.md)
- [GUI Manual Test Checklist](docs/GUI_MANUAL_TEST_CHECKLIST.md)
- [Roadmap](ROADMAP.md)
- [v2.0 design notes and work plan](docs/ideas_and_todos/README.md) — future planning only

## Citation and license

See [CITATION.cff](CITATION.cff) for citation metadata and [LICENSE](LICENSE) for licensing information.
