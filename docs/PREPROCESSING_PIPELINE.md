# ChanAI Pulse Preprocessing Pipeline

## Purpose

This pipeline converts local channel-derived sequences into reproducible model inputs without changing the original source files.

## DPSD Workflow

```text
Naturally sorted DPSD MAT files
  -> load_dpsd_sequence
  -> optional power_to_dbm
  -> build_sliding_windows
  -> normalize_samples
  -> create_train_test_split
```

## Data Shapes

```text
Raw sequence:       [record, feature]
Model input:        [sample, feature, time_window]
Prediction target:  [sample, feature]
```

The original historical workflow uses 200 feature bins and a 10-record input window. These are defaults from the old experiments, not hard-coded limits of the platform.

## Safety Rules

- Input files are read only.
- Train/test splitting is chronological by default to avoid future-data leakage.
- Normalization parameters must be saved with a trained model.
- Private DPSD, model input, and output files remain local.
- Public repositories may contain only synthetic demo data.

