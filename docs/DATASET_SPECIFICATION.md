# ChanAIs Dataset Specification

**Status:** Implemented schema and MATLAB validation/conversion helpers. The public repository does not ship a ChanAIs research dataset, and the App does not yet browse a dataset root directly.

## Supported layout

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

`validate_chanais_dataset(datasetRoot)` accepts a dataset with usable supported channel files and evaluates metadata completeness. Directory presence is informative: an absent optional/recommended area can produce `WARNING`; missing core identity metadata or usable channel data produces `FAIL`.

## Metadata

Required non-empty fields:

```text
dataset_id
scenario
data_source
data_type
visibility
```

Recommended fields (missing values yield warnings):

```text
environment, frequency_band, carrier_frequency, bandwidth,
antenna_configuration, polarization, mobility, trajectory,
los_condition, sampling_interval, time_window, license, units
```

Useful optional fields include `schema_version`, `dataset_version`, processing/citation notes, and an approved privacy level. Do not use optional metadata to store private locations, device identifiers or collection details.

## Supported data types

The current validator recognizes:

```text
SAGE, CIR, CTF, PDP, Doppler, Angular Spectrum,
Feature Tensor, Prediction Target
```

The standard processed MATLAB representation is:

```matlab
chanais.metadata
chanais.records
chanais.features
chanais.labels
```

Records may contain SAGE path parameters, CIR, CTF, PDP, Doppler and angular-spectrum fields. `read_sage_mat` and `convert_sage_to_chanais` normalize compatible top-level `sage` cell/struct containers.

## PASS / WARNING / FAIL

| Result | Meaning | Current behavior |
| --- | --- | --- |
| `PASS` | Core and recommended metadata are present and usable channel data is found. | Programmatic loader may return a dataset structure. |
| `WARNING` | Core metadata and usable data are present, but recommended context is incomplete. | Loading is allowed; missing interpretation context remains explicit. |
| `FAIL` | Root, metadata, required values, a supported type, or usable channel data is absent. | Normal dataset loading is rejected with concrete errors. |

The validator and converter do not change the source MAT files. A valid dataset schema does not by itself make a file compatible with every App visualization or prediction path.

## Current App boundary

The GUI uses its own compatible-MAT loading path (`extract_raw_data` and `prepare_dpsd_snapshot`). It does **not** currently call `load_chanais_dataset` from a dataset root picker. Dataset helpers therefore support tooling and future integration, not a promise that every valid ChanAIs record is immediately trainable in the App.

## Privacy and publication

Only synthetic public demos belong in this source repository. A public measured dataset requires separate authorization, anonymization, licensing, versioning and citation review. A future Complex-H/MIMO dataset schema is Planned; it is not implemented by this specification or App baseline.
