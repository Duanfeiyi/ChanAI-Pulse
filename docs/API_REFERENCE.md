# MATLAB API Reference

This is the maintained reference for public MATLAB interfaces in the current repository. It describes callable functions, not HTTP/REST APIs. Unless stated otherwise, `options` is a MATLAB name-value argument structure accepted by the function's `arguments` block. Shapes use `[rows x columns]` and preserve MATLAB's column-major convention.

## Characterization

| Function / path | Contract, inputs and outputs | Called by / tests / status |
| --- | --- | --- |
| `extract_raw_data(rawInput)`<br>`core/characterization/extract_raw_data.m` | Unwraps supported numeric, cell or struct containers (`DPSD_dB`, `DPSD_cut`, `sage`, `cir`, `CIRData`, `IRuse`, `input`). Returns numeric `double` data. | App load flow; `test_characterization_pipeline`. Implemented legacy extractor. |
| `prepare_dpsd_snapshot(data, scenarioName, targetLength)`<br>`core/characterization/prepare_dpsd_snapshot.m` | Converts one supported source representation to a `targetLength x 1` dBm display/training vector. Pads/trim with `-130`. Complex source handling follows legacy scenario branches. | App load flow; `test_characterization_pipeline`. Implemented legacy adapter; not a universal CIR-axis parser. |
| `calculate_angular_spectrum(rawData)`<br>`core/characterization/calculate_angular_spectrum.m` | Returns `angles` and normalized `aps_dB` vectors. Complex input may be FFT-processed; unsupported dimensions degrade to a display-safe result. | App load flow; characterization tests. Implemented display heuristic. |
| `compute_delay_spread(delayAxisSeconds, pdpLinear)`<br>`core/characterization/compute_delay_spread.m` | Returns scalar RMS delay spread in seconds from equal-length nonnegative PDP and delay vectors. | `analyze_channel_data`; characterization tests. Pure function. |
| `compute_doppler_spectrum(timeSeries)`<br>`core/characterization/compute_doppler_spectrum.m` | Returns a struct with normalized display spectrum and normalized frequency axis. Input is a numeric time series. | `analyze_channel_data`; characterization tests. Implemented display metric; axis is not metadata-derived physical Hz. |
| `analyze_channel_data(dpsd_dbm, B_hz)`<br>`core/characterization/analyze_channel_data.m` | Accepts DPSD `[delay bins x snapshots]` and scalar bandwidth. Returns plotting metrics including delay axis, PDP, delay-spread values/CDF, and Doppler display. | App load flow; `test_characterization_pipeline`, renderer test. |

## Dataset and ChanAIs helpers

| Function / path | Contract, inputs and outputs | Called by / tests / status |
| --- | --- | --- |
| `canonicalize_cir(cirInput)`<br>`core/dataset/canonicalize_cir.m` | Returns complex-preserving `cir` in conceptual `[antenna x delay_or_frequency x snapshot]` layout plus `info` with original shape. Up to three non-singleton dimensions are supported. | Dataset APIs; `test_dataset_contract`. Pure function. |
| `parse_dataset_metadata(metadataInput)`<br>`core/dataset/parse_dataset_metadata.m` | Parses JSON text/file or struct metadata into a MATLAB struct; validates basic representation only. | validator/loader; dataset contract test. |
| `validate_chanais_dataset(datasetRoot)`<br>`core/dataset/validate_chanais_dataset.m` | Reads dataset metadata and public file layout. Returns `result` with `status` (`PASS`, `WARNING`, `FAIL`), errors, warnings, metadata and files. | Programmatic API; `test_dataset_contract`. Not currently wired to App browse UI. |
| `load_chanais_dataset(datasetRoot)`<br>`core/dataset/load_chanais_dataset.m` | Validates then loads metadata and discovered data file references into `dataset`; it does not infer arbitrary App-ready DPSD matrices. | Programmatic API; dataset contract test. |
| `read_sage_mat(matFile)`<br>`core/dataset/read_sage_mat.m` | Reads a MAT file containing top-level `sage`; returns normalized records and a summary. Supports cell or struct SAGE containers. | Converter tools; dataset contract test. |
| `record_data_provenance(sourceType, sampleCount, options)`<br>`core/dataset/record_data_provenance.m` | Returns a provenance struct with source category, count and optional fields. No source data is copied. | Dataset workflows; dataset contract test. |
| `merge_training_sources(realTrain, generatedTrain, options)`<br>`core/dataset/merge_training_sources.m` | Validates source labels and concatenates compatible train partitions. Both partitions require aligned inputs/targets. | Augmentation policy tests; implemented train-only helper. |

## Generation

| Function / path | Contract, inputs and outputs | Called by / tests / status |
| --- | --- | --- |
| `default_6gpcm_lite_config()`<br>`core/generation/default_6gpcm_lite_config.m` | Returns a configuration struct with bandwidth, delay-grid, cluster/ray, K-factor, Doppler, snapshot and seed defaults. | App generation callback; generation test. |
| `generate_6gpcm_lite(config)`<br>`core/generation/generate_6gpcm_lite.m` | Returns `result` containing complex `cir` shaped `[1 x 1 x snapshots x delayBins]`, delay axis, configuration, DS samples and cluster information. | App generation callback; `test_generation_6gpcm_lite`. Implemented lightweight synthetic generator. |
| `generation_result_to_dpsd(result)`<br>`core/generation/generation_result_to_dpsd.m` | Converts `result.cir` to legacy `dpsdDbm` `[delay bins x snapshots]`. | Send-to-AI callback; generation test. |

## Preprocessing

| Function / path | Contract, inputs and outputs | Called by / tests / status |
| --- | --- | --- |
| `load_dpsd_sequence(folderPath, options)`<br>`core/preprocessing/load_dpsd_sequence.m` | Reads a folder of DPSD MAT files into `sequence [records x features]` and metadata. | Standalone helper; `test_preprocessing`. Not the App's direct multi-file loader. |
| `natural_sort_files(names)`<br>`core/preprocessing/natural_sort_files.m` | Sorts file-name strings naturally; returns sorted names and original order. | App/preprocessing file loading; preprocessing tests. |
| `power_to_dbm(powerW)`<br>`core/preprocessing/power_to_dbm.m` | Converts nonnegative power in watts to dBm. | Preprocessing helper; `test_preprocessing`. |
| `build_sliding_windows(sequence, windowLength, horizon)`<br>`core/preprocessing/build_sliding_windows.m` | From `[records x features]`, returns inputs `[samples x features x windowLength]`, targets `[samples x features]`, and metadata. | Split/preprocessing paths; tests. |
| `normalize_samples(data)` / `denormalize_samples(normalized, params)`<br>`core/preprocessing/*.m` | Per-sample min-max normalization and inverse transform for generic utilities. | `test_preprocessing`. Distinct from App z-score experiment normalization. |
| `create_train_test_split(inputs, targets, testFraction)`<br>`core/preprocessing/create_train_test_split.m` | Returns chronological two-way split struct. | Legacy/helper test. Not the App's default formal protocol. |
| `create_chronological_train_val_test_split(sequence, options)`<br>`core/preprocessing/create_chronological_train_val_test_split.m` | Returns chronological partitions and non-crossing windows. | Utility/test path. The App uses the semantically equivalent prediction experiment API below. |

## Prediction and training

| Function / path | Contract, inputs and outputs | Called by / tests / status |
| --- | --- | --- |
| `prepare_temporal_prediction_experiment(sequence, options)`<br>`core/prediction/prepare_temporal_prediction_experiment.m` | Takes DPSD `sequence [snapshots x features]`; returns chronological train/validation/test partitions, windows, targets, training-only z-score parameters and source labels. Defaults: 70/15/15, window 10, horizon 1. | App training callback; `test_prediction_experiment`. Current formal experiment API. |
| `append_generated_training_windows(experiment, generatedSequence, options)`<br>`core/prediction/append_generated_training_windows.m` | Builds generated windows and appends them only to `experiment.train`; preserves held-out real partitions. | App augmented flow; experiment test. |
| `build_prediction_layers(algorithm, featureCount)`<br>`core/prediction/build_prediction_layers.m` | Builds baseline TCN, LSTM or GRU layer graph for `featureCount` DPSD features. | training function; `test_prediction_models`. |
| `train_prediction_model(experiment, algorithm, options)`<br>`core/prediction/train_prediction_model.m` | Trains a selected baseline from experiment partitions. Returns `result.net`, validation metrics, training information and timings. | App Train Model; model test. |
| `predict_holdout_partition(net, partition, normParams)`<br>`core/prediction/predict_holdout_partition.m` | Predicts a partition of normalized input cells and returns denormalized and normalized predictions. | `run_prediction_model`; prediction tests. |
| `recursive_predict(net, normalizedWindow, normParams, options)`<br>`core/prediction/recursive_predict.m` | Predicts future snapshots recursively from one normalized input window. Returns `[features x steps]`-compatible future output. | `run_prediction_model`; prediction tests. |
| `evaluate_prediction_result(predictionsDbm, truthDbm, bandwidthHz, options)`<br>`core/prediction/evaluate_prediction_result.m` | Returns legacy RMSE/NRMSE/capacity/DS-CDF and plotting metrics for aligned prediction and truth matrices. | `run_prediction_model`; prediction renderer. |
| `run_prediction_model(net, experiment, normParams, options)`<br>`core/prediction/run_prediction_model.m` | Runs held-out test prediction plus recursive forecast; returns result struct, metrics, timing and plot-ready data. | App Run Predict; experiment/model tests. |

## Evaluation

| Function / path | Contract, inputs and outputs | Called by / tests / status |
| --- | --- | --- |
| `compute_rmse(predicted, truth)` | Scalar RMSE over aligned numeric arrays. | prediction evaluation. |
| `compute_nrmse(rmseValue, truth)` | Normalizes RMSE by truth range. | prediction evaluation. |
| `compute_capacity_accuracy(preds_dbm, gt_dbm, bandwidthHz, noise_dBm)` | Returns capacity-accuracy percent and SNR/capacity vectors from DPSD values. | prediction evaluation/plots. Legacy metric; not a validated achievable-rate benchmark. |
| `compute_ds_cdf(preds_dbm, gt_dbm, bandwidthHz)` | Returns predicted/truth CDF axes and values using a Gaussian approximation of delay-spread samples. | prediction evaluation/plots. Implemented with known scientific limitation. |

## Plotting and utilities

| Function / path | Contract, inputs and outputs | Called by / tests / status |
| --- | --- | --- |
| `render_characterization_plots(axesHandles, metrics, style)` | Draws angular, delay, spread-CDF and Doppler views. `axesHandles` supplies matching UI axes; `style` includes language and colors. | App; characterization rendering test. |
| `render_generation_plots(axesHandles, generationResult, style)` | Draws generated PDP and DS-CDF views; returns plot data. | App; generation rendering test. |
| `render_prediction_plots(axesHandles, predictionResults, style)` | Draws capacity, RMSE, PSD, spread, angle and Doppler result views; returns plot data. | App; prediction rendering test. |
| `init_axes_style`, `apply_axes_style`, `apply_y_limit_margin`, `set_full_width_axes` | UI-axes formatting helpers. | App/renderers; manual and renderer tests. |

## Dataset-converter tools

| Function / path | Contract and status |
| --- | --- |
| `build_metadata_template(varargin)` | Creates a ChanAIs metadata struct from explicit name-value inputs. |
| `inspect_mat_dataset(inputPath)` | Read-only MAT variable/shape inspection report. |
| `convert_sage_to_chanais(inputPath, outputDir, metadata)` | Explicitly converts compatible SAGE MAT input into a local ChanAIs structure/output. Never use it to place private inputs in a public folder. |

Local functions below a primary `function` declaration are internal helpers. They are intentionally not stable public APIs. The generated [function inventory](generated/FUNCTION_INVENTORY.md) is a discovery aid and does not replace this contract.
