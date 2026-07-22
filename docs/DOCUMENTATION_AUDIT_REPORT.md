# Documentation Audit Report

**Audit baseline:** `origin/main` revision `d68c4f1` (2026-07-20).
**Scope:** source, tests and tracked documentation only. No private measurements, local models, experiment outputs or local paths were inspected or copied.

## Conclusion

Documentation was materially out of date. The most serious issues were: broad platform claims presented as current validation, future Complex-H/Base Model/QuaDRiGa work mixed with the legacy implementation, obsolete branch/release guidance, stale Train/Test descriptions, and local absolute paths in manuals and packaging records.

The synchronized documents treat current code as the authority: the active App is a MATLAB, legacy DPSD/power, time-domain baseline. v2.0 documents are planning material.

## Current functionality facts

| Feature | Status | Main implementation | Test evidence |
| --- | --- | --- | --- |
| Three-page MATLAB App and bilingual labels | Implemented | `app/ChannelSimulatorApp.m` | smoke/runtime-path tests; manual GUI required |
| Compatible MAT loading and legacy characteristics | Implemented | `core/characterization/` | characterization tests |
| ChanAIs validation and SAGE converter helpers | Implemented | `core/dataset/`, `tools/dataset_converter/` | dataset-contract test |
| App ChanAIs dataset-root browsing | Not Implemented | — | — |
| 6GPCM-lite synthetic CIR generation | Implemented | `core/generation/` | generation tests |
| Official 6GPCM / QuaDRiGa | Not Implemented | — | — |
| Time-domain DPSD Train/Validation/Test | Implemented | `core/prediction/` | experiment test |
| TCN, LSTM and GRU baseline training | Implemented | `build_prediction_layers`, `train_prediction_model` | prediction-model test |
| Frequency / spatial task routing | Not Implemented | UI state only | manual code-path audit |
| Complex-H, Base Model, online adaptation, MIMO | Planned | v2.0 design docs only | — |

## Interface inventory

The public-core inventory currently covers 6 characterization, 7 dataset, 3 generation, 8 preprocessing, 8 prediction, 4 evaluation, 3 plotting and 4 axes-utility functions, plus three dataset converter entry points. The App's principal chain is:

```text
MAT load -> characterization -> optional 6GPCM-lite -> temporal experiment
-> selected TCN/LSTM/GRU -> held-out evaluation / recursive forecast -> renderer
```

Local helper functions inside individual MATLAB files remain internal and are intentionally not documented as stable public interfaces.

## Scientific and functional issues not changed in this documentation work

- `compute_ds_cdf` is Gaussian-approximation based, not empirical CDF.
- 6GPCM-lite delay-grid configuration and bandwidth-derived delay axis require reconciliation.
- Group-RMSE coverage and normalization-scale presentation need scientific review.
- Angle/Doppler displays are not independent prediction tasks.
- `Freq` and `Space` controls do not invoke distinct data/model paths.
- Dataset schema APIs are not yet connected to a GUI dataset-root loader.

## Verification status

Static source and link/path audit completed. MATLAB R2024b executed the following checks successfully: `smoke_test`, `test_app_runtime_paths`, `test_characterization_pipeline`, `test_characterization_rendering`, `test_generation_6gpcm_lite`, `test_generation_rendering`, `test_prediction_experiment`, `test_prediction_models`, `test_prediction_rendering`, `test_preprocessing`, and `test_experiment_split`.

`test_dataset_contract.m` failed: the repository's complete synthetic ChanAIs demo did not produce the `PASS` status asserted by the test. Direct validation shows the demo is `WARNING` because the recommended `data/features` folder is absent. This is a fixture/contract inconsistency outside the documentation-only scope and was not changed. Local measured-data probe/validation tests were intentionally not run because they can create local preview/audit artifacts from private inputs. Manual GUI acceptance remains required after any App-affecting change; this documentation change does not modify App code.

## Documentation classification

- **Current implementation:** README, API Reference, Repository Structure, Feature-to-Code Map, pipeline documents, contracts, testing, collaboration guides.
- **Planning:** ROADMAP, BENCHMARK_PLAN, `docs/ideas_and_todos/`.
- **Historical:** old release and refactor records; they should not override current implementation docs.
