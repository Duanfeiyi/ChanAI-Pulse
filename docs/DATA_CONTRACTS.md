# ChanAI Pulse Data Contracts

## Purpose

This document defines the data exchanged between the three platform modules: Channel Characteristics, Channel Generation, and Channel Prediction. It keeps algorithm code independent from GUI controls and makes future pull requests easier to review.

## Core Rule

Core functions must receive ordinary MATLAB data and configuration structs, then return ordinary MATLAB structs or arrays. They must not read UI controls, create App components, or depend on a specific page layout.

## Channel Record

Each normalized channel record uses the following conceptual structure:

```matlab
record.record_id
record.data_type
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

Fields may be absent when the source format does not provide them. `record_id`, `data_type`, and at least one channel representation are required.

## Canonical CIR Layout

`core/dataset/canonicalize_cir.m` converts a numeric CIR to:

```text
[antenna, delay_or_frequency, snapshot]
```

Examples:

```text
1 x 16 x 683  -> 16 x 683 x 1
16 x 683      -> 16 x 683 x 1
683 x 1       -> 1 x 683 x 1
```

The function preserves complex values. Original dimensions remain available through returned metadata for traceability.

## SAGE Contract

SAGE sources may be cell arrays or struct arrays. Each SAGE item maps as follows:

```text
sage.alpha      -> record.path_parameters.alpha
sage.doa        -> record.path_parameters.doa
sage.delay      -> record.path_parameters.delay
sage.cir        -> record.cir
sage.cir_e      -> record.cir_estimated
sage.likelihood -> record.quality.likelihood
```

## Generation Contract

The future generation module will receive a `GenerationConfig` struct containing scenario, frequency, bandwidth, antenna settings, random seed, generation parameters, and optional reference statistics. It will return a `GenerationResult` struct containing generated channel data, derived features, metadata, and validation metrics.

## Prediction Contract

The prediction module will receive normalized input windows, a `PredictionConfig`, and optional normalization parameters. It will return predictions, targets when available, metrics, model metadata, and timing information.

## Privacy Contract

Private measured data remains local. Public demo files must declare `visibility: public_demo` and `data_source: synthetic_demo` or `measurement_calibrated_synthetic`. No raw measured snapshots, file names, collection locations, device identifiers, or experiment timestamps may enter public demo files.

