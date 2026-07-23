# Testing and Validation

## Automated tests

Run tests from the repository root after adding the tree to the MATLAB path:

```matlab
addpath(genpath(pwd))
run("tests/smoke_test.m")
run("tests/test_characterization_pipeline.m")
run("tests/test_generation_6gpcm_lite.m")
run("tests/test_prediction_experiment.m")
run("tests/test_prediction_models.m")
```

| Test | Scope | Notes |
| --- | --- | --- |
| `smoke_test.m` | Required files and toolboxes | GUI launch is opt-in through `CHANAI_GUI_SMOKE=1`. |
| `test_app_runtime_paths.m` | App startup path registration | Creates an invisible App window; GUI-capable MATLAB is required. |
| `test_characterization_pipeline.m` | Extractors and legacy characterization calculations | Synthetic in-memory fixtures. |
| `test_characterization_rendering.m` | Four characterization renderer outputs | Invisible figure environment required. |
| `test_generation_6gpcm_lite.m` | Generator shape, reproducibility and DPSD conversion | Does not prove physical calibration. |
| `test_generation_rendering.m` | Generation renderer | Invisible figure environment required. |
| `test_prediction_experiment.m` | Chronological split and generated-train isolation | Core experiment contract. |
| `test_prediction_models.m` | One short training run for TCN, LSTM and GRU | Requires Deep Learning Toolbox. |
| `test_prediction_rendering.m` | Prediction renderer | Invisible figure environment required. |
| `test_preprocessing.m` | Generic preprocessing helpers | Separate from the App experiment API. |
| `test_dataset_contract.m` | ChanAIs metadata and converter contracts | Uses repository fixtures only. |

## Local-only checks

`test_measured_dataset_probe.m` and `test_real_data_validation.m` are not general public-repository tests. They can inspect and write local audit/preview artifacts when a user explicitly supplies private measured data. Do not run them in CI or document a private location in issue reports, commits, or pull requests.

## Manual GUI acceptance

Automated tests do not replace desktop acceptance. Use [GUI Manual Test Checklist](GUI_MANUAL_TEST_CHECKLIST.md) to verify:

1. App startup, tab switching and bilingual labels;
2. compatible synthetic data loading and four plots;
3. 6GPCM-lite generation and Send to AI;
4. time-domain TCN/LSTM/GRU training and prediction;
5. exported files only go to a user-selected local location.

Do not represent an unexecuted test or a successful GUI rendering check as scientific validation of prediction accuracy or generator realism.
