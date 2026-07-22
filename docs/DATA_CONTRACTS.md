# ChanAI Pulse Data Contracts

**Status:** Current implementation contract for the MATLAB baseline. Future Complex-H contracts are explicitly marked Planned.

## Core rule

Core functions accept ordinary MATLAB arrays and structs and return arrays or structs. They must not read UI controls, create App components, or depend on page layout. The App owns file selection, user messages and export locations.

## Current App sequence representation

The active App prediction pipeline uses legacy DPSD values in dBm:

```text
dpsdDbm: [delay bins x snapshots] in characterization / App state
sequence: [snapshots x delay bins] for the prediction experiment
inputs:   [samples x delay bins x window length]
targets:  [samples x delay bins]
```

The default App target size is normally 200 delay bins (500 for selected Industrial/mmWave handling), window length 10 and horizon 1. These are current defaults, not universal channel-data limits.

## Channel record

Dataset helpers use the conceptual record below. Fields are optional unless indicated; a usable record requires `record_id`, `data_type`, and at least one channel representation.

```matlab
record.record_id                 % required identifier
record.data_type                 % required supported type
record.path_parameters.alpha
record.path_parameters.doa
record.path_parameters.delay
record.cir
record.ctf
record.pdp
record.doppler
record.angular_spectrum
record.quality
record.metadata
```

`canonicalize_cir` converts numeric CIR into conceptual `[antenna x delay_or_frequency x snapshot]` layout while preserving complex values and original-shape metadata. This dataset API is not currently the App's direct MAT-file ingestion route.

## SAGE mapping

```text
sage.alpha      -> record.path_parameters.alpha
sage.doa        -> record.path_parameters.doa
sage.delay      -> record.path_parameters.delay
sage.cir        -> record.cir
sage.cir_e      -> record.cir_estimated
sage.likelihood -> record.quality.likelihood
```

SAGE input may be a cell array or struct array. Missing path fields produce a warning in the converter/validator when a usable CIR remains available.

## 6GPCM-lite generation result

`generate_6gpcm_lite(config)` returns a MATLAB struct whose primary current fields include:

```text
result.cir                 [1 x 1 x snapshots x delayBins], complex
result.delay_axis_seconds  [1 x delayBins]
result.delay_spread_ns     [snapshots x 1]
result.config              generation configuration
result.cluster_*           generated cluster/ray information
```

`generation_result_to_dpsd(result)` produces legacy `dpsdDbm [delayBins x snapshots]` for the current training pipeline. The generator is synthetic and internal; its delay-axis calibration limitation is tracked as `GEN-001`.

## Prediction experiment contract

`prepare_temporal_prediction_experiment` creates chronological default partitions:

```text
first 70% -> train
next  15% -> validation
last  15% -> test
```

Windows are created inside each partition. Z-score mean and standard deviation are derived only from the real training segment. `append_generated_training_windows` may append generated windows to `train` only. Validation and test remain from the real/evaluation sequence.

## Planned Complex-H contract

Complex-valued \(H(t,f)\), phase-aware tensors, MIMO axes, Base Models and online adaptation are **not implemented**. The proposed v2.0 design is maintained in `docs/ideas_and_todos/`; it must not be used as the contract of the current MATLAB App.

## Privacy boundary

Public demo files must be synthetic and declare public/demo provenance. Do not include private measurement snapshots, source filenames, locations, device identifiers, user paths, timestamps, model checkpoints or experiment outputs in this repository or its documentation.
