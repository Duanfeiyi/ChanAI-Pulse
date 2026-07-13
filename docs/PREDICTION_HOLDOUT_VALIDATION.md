# Prediction Hold-out Validation

## Purpose

This document records the formal prediction experiment path introduced in
Step 6B. The runnable MATLAB App remains the acceptance baseline. The model
architectures and their existing training settings are unchanged; only the
way data is assigned to training, validation, and final evaluation changes.

## Chronological split

For a time-ordered local channel sequence, the App now prepares data in this
order:

```text
first 70%  -> training
next 15%   -> validation
last 15%   -> final test
```

Sliding windows are created after the split. A training window can therefore
not use a future validation or test snapshot as its label. Normalization mean
and standard deviation are calculated from the training part only.

## Generated data policy

When the user selects the existing `Real + Sim` augmented dataset, the
generation page still keeps its original visualization and data-flow
behavior. For formal model training, however, the App uses:

```text
real train windows + generated train windows -> training
real validation windows                    -> validation
real test windows                          -> final metrics
```

Generated data is never appended to validation or test. This ensures that a
good metric cannot be caused by placing synthetic variants of the same source
in the held-out partitions.

## What users should see

In a normal MATLAB desktop session, the training-progress window should now
show validation values instead of `N/A`. After clicking **Run Predict**, the
evaluation dialog reports at least:

- Validation RMSE
- Test Capacity Accuracy
- Test NRMSE
- Test RMSE
- Training time and inference time

The final plots and metrics use the held-out test targets. Scores can be
lower than the former in-sample result; that is expected and is a more honest
measure of generalization.

## Local manual acceptance

Use local data only. The recommended validation source is:

```text
C:\Users\22595\Desktop\SRTP_智能预测信道模型_整理版\05_数据\02_实测数据\SAGE参数估计结果\横向道路数据\横向道路1
```

Read-only preflight on 2026-07-13 found 337 MAT snapshots. With a window
length of 10, the expected prepared sample counts are:

| Partition | Raw snapshots | Prediction windows |
| --- | ---: | ---: |
| Train | 235 | 225 |
| Validation | 50 | 40 |
| Test | 52 | 42 |

Manual acceptance steps:

1. Run `addpath(genpath(pwd))`, then open `ChannelSimulatorApp`.
2. Load all MAT files from the directory above as the raw local dataset.
3. Train TCN once and confirm the MATLAB training-progress window contains a
   validation curve or validation value rather than `N/A`.
4. Run prediction and confirm the report contains both `Validation RMSE` and
   `Test RMSE`.
5. Optionally generate a channel, select the resulting augmented dataset,
   train again, and confirm the report label reads `Real + Synthetic Train`.
6. Record screenshots and any error message. Do not copy the source MAT files
   into this repository.

## Automated checks

`tests/test_prediction_experiment.m` validates split boundaries,
training-only normalization, generated-data isolation, and short-sequence
window adaptation. Existing smoke, characterization, and generation tests
must remain green for every prediction-related pull request.
