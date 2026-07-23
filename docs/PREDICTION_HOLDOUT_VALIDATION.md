# Prediction Hold-out Validation

**Status:** Current implementation for the legacy DPSD time-domain App workflow.

## Chronological separation

```text
first 70% -> train
next  15% -> validation
last  15% -> final test
```

The split precedes window creation. With a window length of 10 and horizon 1, each partition constructs its own usable windows; neither inputs nor targets cross into another partition. Normalization is fit only on the real training segment.

## Generated data isolation

For the App's augmented source selection:

```text
real train + generated train -> train
real validation              -> validation
real test                    -> test metrics
```

This prevents synthetic variants from entering held-out partitions. It does not prove that augmentation improves test performance; that requires a controlled real-only versus augmented experiment.

## What the App reports

After training and prediction, current outputs include validation RMSE, test RMSE/NRMSE, Capacity Accuracy, timings and plot-ready comparison data. The test partition is the source of final in-App metrics. Future recursive predictions are forecasts and should not be described as held-out evaluation.

## Verification

```matlab
run("tests/test_prediction_experiment.m")
run("tests/test_prediction_models.m")
```

For manual acceptance, use a public synthetic demo or an authorized local dataset without recording its path, filename, source details or outputs in the repository. Select `Time`, train a baseline, run prediction, and verify validation and test labels are present in the report. See [GUI Manual Test Checklist](GUI_MANUAL_TEST_CHECKLIST.md).

## Known boundary

The protocol is not yet a standardized benchmark, a cross-scenario study, or a Complex-H evaluation protocol. It must not be used to claim independent frequency/spatial prediction.
