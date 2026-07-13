# ChanAIs Synthetic Demo Dataset

This folder contains a small synthetic ChanAIs-style demo dataset for v1.1.0 planning.

It is not measured data. It does not contain private channel measurement files, raw archives, or extracted previews.

## Purpose

The demo is designed to resemble a SAGE-compatible dataset structure so that ChanAI Pulse can evolve from simple `Load MAT` workflows toward future `Load ChanAIs Dataset` workflows.

Its metadata is intentionally complete enough to return `PASS` from
`validate_chanais_dataset`. Use it as a public reference for the expected
folder structure, not as measured evidence or a benchmark dataset.

## Layout

```text
demo_data/chanais_demo/
├─ metadata.json
├─ data/
│  ├─ raw/
│  ├─ processed/
│  └─ features/
├─ labels/
├─ splits/
├─ generate_chanais_demo_sage.m
└─ README.md
```

## Synthetic SAGE Fields

The generator creates a top-level MATLAB variable named `sage`, with fields:

- `alpha`
- `doa`
- `delay`
- `cir`
- `cir_e`
- `likelihood`

It also creates a `metadata` variable.

## Regenerate

From the repository root in MATLAB:

```matlab
run("demo_data/chanais_demo/generate_chanais_demo_sage.m")
```

Generated files are small and intended for public testing only.
