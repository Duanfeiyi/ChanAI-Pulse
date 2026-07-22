# Experiment Data Protocol

**Status:** Implemented for the current time-domain DPSD prediction workflow. It does not define a Complex-H benchmark.

## Current split policy

For an ordered real/evaluation sequence, the App uses chronological default partitions:

```text
first 70% -> Train
next  15% -> Validation
last  15% -> Test
```

The split occurs before sliding-window construction. A window and its target therefore remain within one partition; no training window can consume a validation/test target. Normalization parameters are fitted to the real training segment only.

## Generated data policy

```text
real train windows + generated train windows -> training
real validation windows                      -> validation
real test windows                            -> final held-out metrics
```

Generated samples are permitted for augmentation experiments only in the training source. They must never be silently mixed into validation or test. A successful augmented run shows pipeline compatibility, not proof that synthetic augmentation improves real-world generalization.

## Current metrics and limitations

The App reports legacy DPSD-oriented RMSE, NRMSE, Capacity Accuracy, timing and DS-CDF-related views. The DS-CDF calculation currently uses a Gaussian approximation; it is not an empirical CDF. Capacity Accuracy is a legacy comparative metric, not a complete communication-system evaluation. See `EVAL-001` and related items in [Open Issues](OPEN_ISSUES_AND_REFACTOR_ROADMAP.md).

## Reporting requirements

For an experiment comparison, record locally:

- code revision and algorithm;
- data provenance category, never private paths or raw data;
- split/window/horizon and normalization policy;
- generator seed and configuration if synthetic augmentation was used;
- train, validation and test sample counts;
- held-out test metrics and training/inference time.

Do not publish a benchmark claim until a fixed task, dataset authorization, repeatable seeds and scientifically reviewed metrics have been established.
