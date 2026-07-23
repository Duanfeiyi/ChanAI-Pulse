# Changelog

All notable repository changes are recorded here. Dates below come from Git history; no future version date is implied.

## Unreleased

### Documentation

- Synchronize repository documentation with the current MATLAB implementation.
- Add API Reference, Repository Structure, Feature-to-Code Map, testing guide, generated function inventory and documentation audit report.
- Clearly separate the legacy power/DPSD baseline from planned Complex-H, QuaDRiGa, Base Model and adaptation work.

## v1.1.0

### Added and changed

- Extracted characterization, generation and prediction plot rendering from the App.
- Added the unified prediction engine: TCN, LSTM and GRU shared training, hold-out prediction, recursive forecast and evaluation helpers.
- Added chronological Train / Validation / Test experiment preparation and generated-training-window isolation.
- Added internal 6GPCM-lite generation, ChanAIs dataset contracts, SAGE conversion helpers and related tests.

### Notes

- v1.1.0 is a MATLAB legacy power/DPSD baseline, not a Complex-H or cross-scenario generalization release.
- The v1.1.0 tag points to the Git revision created on 2026-07-16.

## v1.0.0

### Added

- Initial MATLAB desktop research prototype with three-page workflow, baseline model controls, synthetic demo data, data policy and release documentation.

### Notes

- Private measurements and generated local experiment artifacts are excluded from the public repository.
- Source-based MATLAB use is the supported repository workflow; a standalone installer is not part of the repository baseline.
