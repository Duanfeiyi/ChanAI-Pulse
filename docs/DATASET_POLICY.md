# Dataset Policy

## Public repository boundary

The public repository may contain only small, synthetic demonstration data under `demo_data/`. Such files are for loading checks, visualization and tests; they are not scientific benchmark evidence.

## Local-only material

Private measurements, raw archives, converted local previews, trained models, experiment results and sensitive metadata must remain outside version control. Do not add their names, paths, locations, device information, collection times, screenshots or derived outputs to commits, pull requests or documentation.

## Future datasets

A ChanAIs public research dataset, if approved, must be released separately with authorization, anonymization, licensing, schema versioning, a dataset card and citation guidance. It must not be created by copying a private dataset into this source repository.

## Contributor check

Before staging changes, inspect `git status` and stage explicit intended files. Stop and request review if an unfamiliar data, archive or result file appears.
