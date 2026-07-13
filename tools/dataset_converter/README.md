# ChanAIs Dataset Converter Framework

This folder contains lightweight converter utilities for ChanAIs Dataset v1.0 planning.

The current scope is a framework only. It does not convert or publish private measured datasets automatically.

## Goals

- Inspect MATLAB `.mat` files without modifying the source data.
- Read SAGE-compatible structures.
- Build a metadata template for ChanAIs Dataset.
- Convert SAGE-like `.mat` files into a normalized ChanAIs-compatible structure when explicitly called by the user.

## Files

- `inspect_mat_dataset.m`: read-only inspection of variables, classes, dimensions, and likely channel-related fields.
- `build_metadata_template.m`: creates a ChanAIs metadata struct with required fields.
- `convert_sage_to_chanais.m`: maps SAGE-compatible `.mat` files to a normalized `chanais` MATLAB structure.

## Safety Rules

- Do not modify original `.mat` files.
- Do not copy private measured data into public folders.
- Do not commit generated conversion outputs from private datasets.
- Treat `datasets/measured/raw_archives/` and `datasets/measured/extracted_preview/` as local-only.

## Example

```matlab
inputFile = "private/path/Pol_0_SAGE_F7_MovingR1_0-1s.mat";
outputDir = "local_outputs/chanais_preview";
metadata = build_metadata_template("dataset_id", "local_sage_preview", ...
    "visibility", "internal_only", ...
    "data_source", "private_measured");

report = inspect_mat_dataset(inputFile);
chanais = convert_sage_to_chanais(inputFile, outputDir, metadata);
```

Generated outputs from private datasets should stay local.

