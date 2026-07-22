# Repository Structure

This document describes the repository as implemented on `main`. It does not describe a future web service, a released dataset, or a packaged standalone application.

```text
ChanAI-Pulse/
├─ app/                    MATLAB desktop App entry point
│  └─ plotting/            rendering functions extracted from the App
├─ core/                   GUI-independent computation
│  ├─ characterization/    legacy data extraction and characteristic displays
│  ├─ dataset/             ChanAIs metadata, SAGE and provenance helpers
│  ├─ evaluation/          legacy prediction metrics
│  ├─ generation/          6GPCM-lite generation and DPSD conversion
│  ├─ prediction/          experiment, model, prediction and evaluation flow
│  ├─ preprocessing/       sequence and split utilities
│  └─ utils/               shared axes utilities
├─ configs/                reserved for public configuration files
├─ demo_data/              small synthetic public examples only
├─ docs/                   maintained docs, plans and historical records
│  ├─ generated/           generated inventories; do not edit manually
│  ├─ ideas_and_todos/     future design and research planning
│  └─ templates/           reusable collaboration templates
├─ release/                source-release, packaging and historical release notes
├─ tests/                  automated MATLAB tests and opt-in local checks
└─ tools/                  dataset conversion and documentation utilities
```

## Entry points

| Location | Purpose | Change guidance |
| --- | --- | --- |
| `app/ChannelSimulatorApp.m` | Public MATLAB App class and GUI orchestration | Treat as integration code; keep algorithm changes out of UI-only work. |
| `app/plotting/` | Characterization, generation and prediction rendering | Accept axes handles and result structs; do not embed training logic. |
| `core/` | Reusable MATLAB business logic | New reusable computation belongs in the appropriate submodule. |
| `tests/` | Automated regression and contract checks | Add a focused test with each public-core behavior change. |
| `tools/` | Explicit helper workflows | Do not make tools auto-process private data. |

## Core-module boundaries

| Directory | Current responsibility | Boundary |
| --- | --- | --- |
| `core/characterization/` | Legacy numeric extraction, DPSD preparation, delay/angle/Doppler displays | Does not establish universal physical axis semantics for arbitrary source data. |
| `core/dataset/` | ChanAIs schema parsing/validation, SAGE reading, canonical CIR, provenance | Dataset-root helpers are not yet the App file-picker implementation. |
| `core/generation/` | Lightweight clustered synthetic CIR generation | Not QuaDRiGa and not an official 6GPCM implementation. |
| `core/preprocessing/` | Generic sequence/window/split/normalization helpers | Actual App experiment policy is in `core/prediction/prepare_temporal_prediction_experiment.m`. |
| `core/prediction/` | The current time-domain DPSD experiment and baseline models | Frequency and spatial prediction tasks are not implemented. |
| `core/evaluation/` | Legacy metrics used by prediction plots and reports | Some metrics have documented scientific limitations. |
| `core/utils/` | Axes styling and limits | No data or model behavior belongs here. |

## Data and local artifacts

- Only small synthetic files belong in `demo_data/`.
- Private measurements, converted local outputs, checkpoints, experiment results, archives and installers must remain untracked.
- New public dataset schemas, cards and converter documentation belong in `docs/` and `tools/dataset_converter/`; public datasets themselves require a separate approved release process.

## Where new work belongs

| Work type | Location |
| --- | --- |
| New App callback or component wiring | `app/ChannelSimulatorApp.m` |
| Reusable analysis/generation/model computation | matching `core/` subdirectory |
| Rendering logic | `app/plotting/` |
| Public configuration fixture | `configs/` |
| Synthetic demonstration fixture | `demo_data/` |
| Automated test | `tests/` |
| Data conversion utility | `tools/dataset_converter/` |
| Documentation helper | `tools/docs/` |
| Current implementation documentation | `docs/` |
| Future design decision | `docs/ideas_and_todos/` |
