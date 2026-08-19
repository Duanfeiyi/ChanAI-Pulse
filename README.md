# ChanAI Pulse

ChanAI Pulse is a MATLAB desktop research platform for capability-driven channel-data analysis, generator calibration, parameter prediction, and predicted CIR/CTF export. The public repository is intended for reproducible code review, synthetic demonstrations, and research collaboration; it does not claim that every band, scenario, generator, or prediction model has been scientifically validated.

## v3.1 release-candidate entries

The v3.1 release candidate keeps two deliberately separate applications:

```matlab
ChannelSimulator   % import, characterize, calibrate, predict, generate and export
ChannelBenchmark   % independent ground-truth accuracy evaluation
```

`ChannelSimulator` does not read target-region ground truth for model selection and does not display prediction accuracy. `ChannelBenchmark` accepts the complete original standard HDF5 file plus a formal prediction-export directory, validates strict alignment, compares Persistence and Linear baselines, and exports CSV/Markdown/PNG/Manifest reports.

## Implemented workflow

- A formal three-page MATLAB UI with Chinese/English switching and normal/advanced user modes.
- Standard CIR/CTF HDF5 input with canonical dimensions `Tx × Rx × Npath/Nf × Nt × N_sample`.
- A source-preserving MAT conversion wizard for known structures and explicit user mappings, including MAT v7/v7.3, complex arrays, real/imaginary pairs, known SAGE folders, and legacy WiFo HDF5.
- Explicit interpolation/extrapolation tasks, including original-axis to MATLAB-index conversion.
- Capability-driven visualization: 1/3/6/9 standard channel-characteristic plots plus an optional delay–sample heatmap where supported.
- Generator-parameter calibration with Grid Search, simulated annealing (SA), automatic recommendation, and advanced manual override.
- Automatic generator compatibility evaluation across 6GPCM-Lite and the bundled Full 6GPCM adapter; an error is shown only after all formal candidates fail.
- Uploaded-known-region product selection: ordinary mode can choose a different locally backtested model for each observable P8 parameter. Advanced users can explicitly select Persistence, Linear, Quadratic Trend, Holt Damped Trend, Harmonic/Fourier, Adaptive AR, Kalman, GRU, LSTM, TCN, DLinear, or NLinear.
- Ten versioned P8 experimental checkpoints are shipped under `models/official/v3.1.0/`; each load is bound to the Registry by SHA-256.
- Automatic adaptation remains leakage-safe: without a separate labeled known-region parameter dataset it is explicitly skipped, and no official checkpoint is overwritten.
- Target-free local P8 observations, horizon-aware uploaded-known-region backtests, all-history/recency-weighted forecasting, bidirectional interpolation, warning-only performance guards, and hard rejection only for invalid tasks or technical failures.
- Predicted parameter-to-CIR generation and auditable CIR/CTF/Manifest export.
- An independent Benchmark application for complex NMSE/correlation, PDP/delay, spatial/angle, time/Doppler metrics and baseline comparison according to data capability.
- Focused and cumulative MATLAB/Python regression tests using public synthetic fixtures.

## Important scientific limits

- The original v3.1 Registry evidence recommends **Persistence for interpolation** and **Kalman for extrapolation**. Product auto mode now treats this as historical evidence and uses the uploaded known-region backtest to make a per-parameter choice. The shipped neural checkpoints remain experimental candidates, not universally best models.
- Public product tasks support arbitrary valid known and target lengths. The shipped neural checkpoints retain their legacy `[N,16,8] -> [N,4,8]` native contract internally; longer horizons use an explicitly recorded autoregressive rollout, so uncertainty can accumulate. Neural execution still needs at least 16 valid known observations on each required prediction side, while flexible classical models can serve shorter valid tasks.
- On capable wideband inputs, `DS_mu`, `KF_mu`, and `num_clusters` are derived as ordered local known-channel observations/proxies. Observability is capability-driven: for example, a narrowband single-path input cannot identify local delay spread, so `DS_mu` is also frozen. Every unavailable P8 field retains its calibrated/versioned value.
- Ordinary mode uses uploaded-known-region evidence independently for observable parameters. Advanced manual choices are respected and are never silently replaced. Worse backtest or continuity performance produces a visible warning and auditable Manifest entry. If a manual parameter is more than four times worse than its local baseline, a labelled `local_guard` keeps at least 10% of the requested model and blends the rest with that parameter's best known-region baseline; the exact weight is exported. Only invalid indices/schema, insufficient native model context, unavailable runtime/checkpoint, non-finite output, or generator failure blocks generation.
- The formal target-generation path is currently frozen for sample/position-axis tasks. Time/frequency-axis import and plotting are supported, but their complete target-generation semantics remain future work.
- The current P6/P8 parameter bundles are engineering baselines, not proof that two, six, or eight predicted parameters are universally optimal.
- Full 6GPCM is bundled at `third_party/full_6gpcm/`. Its core files are kept unchanged; ChanAI Pulse calls it only through an adapter.
- QuaDRiGa is an optional conversion example, not a registered v3.0 production generator backend.
- “MAT support” means known formats or a user-confirmed explicit variable/dimension mapping. Power-only data without phase cannot be reconstructed as a complete complex CIR/CTF.
- Accuracy claims must come from `ChannelBenchmark` on an independent test set, not from the prediction UI or the public synthetic review fixtures.

## Requirements

- MATLAB. The release candidate is regression-tested locally with MATLAB R2024b.
- Python/PyTorch is required for formal v3.1 product selection and its safety gate. Install `tools/python/requirements-v3-step10.txt`; optionally set `CHANAI_STEP10_PYTHON` to the intended interpreter. The App can still import and analyze data without it, but must not generate a target CIR by bypassing the gate.
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
- [v3.1-4 fair P8 model training and admission](docs/v3.1/V3_1_4_MODEL_TRAINING.md)
- [v3.1-5 official models, Registry v2 and safe adaptation](docs/v3.1/V3_1_5_MODEL_REGISTRY_AND_ADAPTATION.md)
- [v3.1-6 independent parameter-to-Full-6GPCM benchmark](docs/v3.1/V3_1_6_END_TO_END_BENCHMARK.md)
- [v3.1-6 formal Test result](docs/v3.1/V3_1_6_FORMAL_RESULT.md)
- [v3.1-7 product integration and release-candidate checklist](docs/v3.1/V3_1_7_PRODUCT_INTEGRATION.md)
- [v3.1-7 pre-PR manual UI review](docs/v3.1/V3_1_7_MANUAL_UI_REVIEW.md)
- [v3.1 prediction-accuracy plan](docs/v3.1/V3.1预测精度与准确性迭代计划.md)
- [v3.0--v3.3 master plan and status](docs/CHANAIPULSE_V3_0_TO_V3_2_MASTER_PLAN.md)

## Citation and license

See [CITATION.cff](CITATION.cff) for citation metadata and [LICENSE](LICENSE) for licensing information.
