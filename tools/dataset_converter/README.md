# ChanAIs Dataset Converter

These explicit MATLAB utilities inspect compatible MAT files, create ChanAIs metadata templates and convert SAGE-like structures into a normalized local ChanAIs representation.

## Available tools

- `inspect_mat_dataset.m`: read-only variable, class, shape and channel-field inspection.
- `build_metadata_template.m`: builds metadata from supplied name-value fields.
- `convert_sage_to_chanais.m`: converts compatible top-level `sage` structures when the caller explicitly supplies input, output and metadata.

## Boundaries

- The tools never modify original MAT files.
- Use a local output location for private inputs; never commit converter outputs derived from private data.
- The converter supports SAGE structures with usable `cir`, `cir_e`, or `alpha` records; missing path fields are reported as warnings where possible.
- A successful conversion does not automatically make the output App-ready or scientifically benchmark-qualified.

See [Dataset Specification](../../docs/DATASET_SPECIFICATION.md) and [Data Contracts](../../docs/DATA_CONTRACTS.md).
