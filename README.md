# ChanAI Pulse

ChanAI Pulse is a MATLAB desktop research platform for capability-driven channel-data analysis, generator calibration, parameter prediction, and predicted CIR/CTF export. The public repository is intended for reproducible code review, synthetic demonstrations, and research collaboration; it does not claim that every band, scenario, generator, or prediction model has been scientifically validated.

## v3.0 public entries

The v3.0 release has two deliberately separate applications:

```matlab
ChannelSimulator   % import, characterize, calibrate, predict, generate and export
ChannelBenchmark   % independent ground-truth accuracy evaluation
```

`ChannelSimulator` does not read target-region ground truth for model selection and does not display prediction accuracy. `ChannelBenchmark` accepts the complete original standard HDF5 file plus a formal prediction-export directory, validates strict alignment, compares Persistence and Linear baselines, and exports CSV/Markdown/PNG/Manifest reports.

## v3.0 implemented workflow

- A formal three-page MATLAB UI with Chinese/English switching and normal/advanced user modes.
- Standard CIR/CTF HDF5 input with canonical dimensions `Tx × Rx × Npath/Nf × Nt × N_sample`.
- A source-preserving MAT conversion wizard for known structures and explicit user mappings, including MAT v7/v7.3, complex arrays, real/imaginary pairs, known SAGE folders, and legacy WiFo HDF5.
- Explicit interpolation/extrapolation tasks, including original-axis to MATLAB-index conversion.
- Capability-driven visualization: 1/3/6/9 standard channel-characteristic plots plus an optional delay–sample heatmap where supported.
- Generator-parameter calibration with Grid Search, simulated annealing (SA), automatic recommendation, and advanced manual override.
- Automatic generator compatibility evaluation across 6GPCM-Lite and the bundled Full 6GPCM adapter; an error is shown only after all formal candidates fail.
- A frozen v3.0 parameter-prediction product baseline using calibrated Persistence without target-ground-truth leakage.
- Predicted parameter-to-CIR generation and auditable CIR/CTF/Manifest export.
- An independent Benchmark application for complex NMSE/correlation, PDP/delay, spatial/angle, time/Doppler metrics and baseline comparison according to data capability.
- Focused and cumulative MATLAB/Python regression tests using public synthetic fixtures.

## Important scientific limits

- The v3.0 product registry deliberately falls back to **Persistence**. GRU/LSTM/TCN research code and adapters exist, but those models have not yet passed the frozen multi-dataset, multi-seed admission gate. Automatic neural-model recommendation and uploaded-data fine-tuning belong to v3.1.
- The formal target-generation path is currently frozen for sample/position-axis tasks. Time/frequency-axis import and plotting are supported, but their complete target-generation semantics remain future work.
- The current P6/P8 parameter bundles are engineering baselines, not proof that two, six, or eight predicted parameters are universally optimal.
- Full 6GPCM is bundled at `third_party/full_6gpcm/`. Its core files are kept unchanged; ChanAI Pulse calls it only through an adapter.
- QuaDRiGa is an optional conversion example, not a registered v3.0 production generator backend.
- “MAT support” means known formats or a user-confirmed explicit variable/dimension mapping. Power-only data without phase cannot be reconstructed as a complete complex CIR/CTF.
- Accuracy claims must come from `ChannelBenchmark` on an independent test set, not from the prediction UI or the public synthetic review fixtures.

## Requirements

- MATLAB. The v3.0 release is regression-tested locally with MATLAB R2024b.
- Python is optional for predictor-side and cross-language HDF5 tests; see `tools/python/requirements-v3-step10.txt` and the testing documentation.
- Full 6GPCM is included in the repository. Compatible SISO tasks keep 6GPCM-Lite as the first automatic choice; MIMO or Lite-incompatible tasks automatically use bundled Full 6GPCM when available. Advanced users may explicitly override `EngineRoot` or `CHANAI_FULL_6GPCM_ROOT` for a separate installation.

## Quick start

Open MATLAB in the repository root:

```matlab
addpath(genpath(pwd))
ChannelSimulator
```

To evaluate an exported prediction independently:

```matlab
ChannelBenchmark
```

To prepare public synthetic Step 14 review data:

```matlab
paths = prepare_step14_review_data();
```

The public `demo_data/` files are synthetic and may be used for workflow review. They are not prediction-accuracy evidence. Never add private measurements, local model checkpoints, or experiment outputs to the repository.

## Repository layout

```text
app/                 formal MATLAB applications and plotting UI
core/                GUI-independent contracts, ingestion, generation, optimization,
                     prediction, characterization and benchmark services
third_party/         bundled Full 6GPCM runtime, kept unchanged
configs/             public configuration
demo_data/           small public synthetic fixtures
docs/                maintained v3.0/v3.1 documentation and historical records
examples/            public review-data and optional integration examples
python/              predictor-side Python package and interfaces
release/             source-release and packaging notes
tests/               MATLAB/Python automated tests and local opt-in checks
tools/               conversion, audit and documentation utilities
```

## Documentation

- [v3.0 documentation index](docs/v3.0/README.md)
- [v3.0 data contract](docs/v3.0/DATA_CONTRACT.md)
- [MAT conversion guide](docs/v3.0/STEP_14_MAT_CONVERSION_GUIDE.md)
- [Step 14 manual review](docs/v3.0/STEP_14_MANUAL_REVIEW_GUIDE.md)
- [v3.1-1 bundled Full 6GPCM guide](docs/v3.1/V3_1_1_BUNDLED_FULL_6GPCM.md)
- [v3.1-2 corpus and Experiment Manager guide](docs/v3.1/V3_1_2_DATA_AND_EXPERIMENTS.md)
- [v3.1-3 parameter evidence and bundle freeze](docs/v3.1/V3_1_3_PARAMETER_EVIDENCE.md)
- [v3.1 prediction-accuracy plan](docs/v3.1/V3.1预测精度与准确性迭代计划.md)
- [v3.0--v3.2 master plan and status](docs/CHANAIPULSE_V3_0_TO_V3_2_MASTER_PLAN.md)

## Citation and license

See [CITATION.cff](CITATION.cff) for citation metadata and [LICENSE](LICENSE) for licensing information.
