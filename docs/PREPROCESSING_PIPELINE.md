# Preprocessing Pipeline

## Module goal and status

The repository contains reusable sequence/window utilities and the active prediction-experiment preparation path. **Implemented:** chronological DPSD preparation. **Not implemented:** generic frequency, spatial or Complex-H preprocessing.

## Active App flow

```text
DPSD sequence [snapshots x features]
  -> prepare_temporal_prediction_experiment
  -> chronological 70/15/15 partitions
  -> partition-local sliding windows
  -> training-only z-score normalization
  -> train / validation / test structures
```

The App invokes this flow before model training. Generated sequence windows can be appended to `train` through `append_generated_training_windows`; they do not enter validation/test.

## Auxiliary helpers

`load_dpsd_sequence`, `natural_sort_files`, `power_to_dbm`, `build_sliding_windows`, `normalize_samples`, `denormalize_samples`, `create_train_test_split`, and `create_chronological_train_val_test_split` remain reusable helpers. The generic min-max `normalize_samples` API is not the same as the active experiment's z-score normalization.

## Shapes and safeguards

- Raw prediction sequence: `[snapshots x features]`.
- Inputs: `[samples x features x windowLength]`; targets: `[samples x features]`.
- Splitting happens before window creation, so windows do not cross partition boundaries.
- The two-way `create_train_test_split` utility is legacy/helper functionality; it is not the App's formal evaluation policy.

## Tests and planned work

- Automated: `test_preprocessing.m`, `test_experiment_split.m`, `test_prediction_experiment.m`.
- Planned: metadata-aware conversion of complex time/frequency/antenna tensors and explicit task-specific preprocessing routes.
