# ChanAIs Dataset Specification

Version: Draft for ChanAI Pulse v1.1.0

## 1. Purpose

ChanAIs Dataset v1.0 is planned as the dataset foundation for ChanAI Pulse v1.1.0. Its goal is not to collect files loosely, but to define a unified wireless channel dataset format that can support channel characterization, channel generation, AI-based channel prediction, and future benchmark tasks.

The specification prioritizes compatibility with existing SAGE-style MATLAB measurement data while also supporting CIR, CTF, PDP, Doppler, angular spectrum, simulation data, and future synthetic or anonymized public datasets.

## 2. Dataset Hierarchy

Recommended dataset layout:

```text
ChanAIs-Dataset/
├─ metadata.json
├─ data/
│  ├─ raw/
│  ├─ processed/
│  └─ features/
├─ labels/
├─ splits/
└─ README.md
```

Directory meanings:

- `metadata.json`: dataset-level metadata and schema version.
- `data/raw/`: source files or source-compatible files. Public releases must not include private raw measured archives unless fully authorized and anonymized.
- `data/processed/`: normalized MATLAB files or channel tensors in ChanAIs-compatible format.
- `data/features/`: extracted feature tensors, PDP, angular spectrum, Doppler features, delay spread, and other derived data.
- `labels/`: optional scenario labels, LOS/NLOS labels, trajectory labels, or prediction targets.
- `splits/`: train, validation, and test split files.
- `README.md`: human-readable dataset card summary and usage notes.

## 3. Required Metadata

Each dataset should define the following metadata fields:

```text
dataset_id
scenario
environment
frequency_band
carrier_frequency
bandwidth
antenna_configuration
polarization
mobility
trajectory
los_condition
sampling_interval
time_window
data_source
data_type
license
visibility
```

Recommended optional fields:

```text
schema_version
dataset_version
creator
institution
measurement_date
processing_pipeline
coordinate_system
units
privacy_level
citation
notes
```

## 4. Supported Data Types

ChanAIs Dataset should support the following data types:

- `SAGE`
- `CIR`
- `CTF`
- `PDP`
- `Doppler`
- `Angular Spectrum`
- `Feature Tensor`
- `Prediction Target`

Multiple data types may coexist in the same dataset. For example, a SAGE measurement file may provide path parameters and CIR, while derived feature files may provide PDP, delay spread, angular spectrum, and prediction targets.

## 5. Standard MATLAB Representation

A processed ChanAIs MATLAB file should use a clear top-level structure:

```matlab
chanais.metadata
chanais.records
chanais.features
chanais.labels
```

Recommended record structure:

```matlab
record.record_id
record.source_file
record.time_window
record.polarization
record.frequency_id
record.trajectory
record.data_type
record.path_parameters
record.cir
record.ctf
record.pdp
record.doppler
record.angular_spectrum
record.quality
```

The minimum valid record should contain `record_id`, `data_type`, and at least one channel representation such as `cir`, `ctf`, `pdp`, or `path_parameters`.

## 6. SAGE-Compatible Schema

Existing SAGE-style `.mat` files commonly contain a top-level variable:

```matlab
sage
```

Typical fields include:

```text
sage.alpha
sage.doa
sage.delay
sage.cir
sage.cir_e
sage.likelihood
```

### Field Meanings

- `sage.alpha`: complex path amplitude or path gain.
- `sage.doa`: direction-of-arrival information.
- `sage.delay`: multipath delay.
- `sage.cir`: channel impulse response.
- `sage.cir_e`: estimated or processed channel impulse response.
- `sage.likelihood`: SAGE fitting or estimation quality indicator.

### Mapping To ChanAIs

Recommended mapping:

```text
sage.alpha      -> record.path_parameters.alpha
sage.doa        -> record.path_parameters.doa
sage.delay      -> record.path_parameters.delay
sage.cir        -> record.cir
sage.cir_e      -> record.cir_estimated
sage.likelihood -> record.quality.likelihood
```

If `sage` is a cell array, each cell should be converted to one `record`. If `sage` is a struct array, each element should be converted to one `record`.

### Source Filename Parsing

For files named like:

```text
Pol_0_SAGE_F7_MovingR1_0-1s.mat
```

Recommended metadata extraction:

```text
Pol_0     -> polarization
SAGE      -> data_type
F7        -> frequency_id
MovingR1  -> trajectory
0-1s      -> time_window
```

Filename parsing should be treated as a helper method, not as the only source of truth. If metadata.json provides explicit values, metadata.json should take priority.

## 7. CIR / CTF / PDP Compatibility

For non-SAGE datasets:

- CIR should be stored as `record.cir`.
- CTF should be stored as `record.ctf`.
- PDP should be stored as `record.pdp`.
- Doppler features should be stored as `record.doppler`.
- Angular spectrum should be stored as `record.angular_spectrum`.

Units should be documented in `metadata.units`, especially for delay, frequency, time, power, and angle.

## 8. Visibility And Privacy

Recommended visibility values:

```text
public_demo
public_research
internal_only
restricted
private_measured
```

The public ChanAI Pulse repository must only include `public_demo` synthetic data unless a separate review approves a public measured dataset.

## 9. Validation Rules

A dataset should be considered valid if:

1. `metadata.json` exists.
2. Required metadata fields are present.
3. At least one supported data type is declared.
4. Data files are present under `data/raw`, `data/processed`, or `data/features`.
5. Private measured data is not included in public demo releases.
6. Units and visibility are documented.

## 10. v1.1.0 Scope

The v1.1.0 scope is:

- Define the ChanAIs Dataset specification.
- Provide SAGE-compatible converter framework.
- Provide a synthetic SAGE-like demo dataset.
- Provide lightweight dataset loading and validation interfaces.

The v1.1.0 scope does not include benchmark leaderboard, new prediction algorithms, physics-informed modeling, Web deployment, or public release of private measured datasets.

