# Prediction Engine

## Module goal and status

**Implemented:** baseline time-domain prediction over legacy DPSD sequences. **Not implemented:** frequency-domain prediction, spatial-domain prediction, complex-valued H prediction, Base Models, online adaptation, or MIMO prediction.

## Current workflow

```text
sequence [snapshots x features]
  -> prepare_temporal_prediction_experiment
  -> train_prediction_model (TCN / LSTM / GRU)
  -> run_prediction_model
     -> held-out test prediction
     -> recursive future prediction
     -> evaluate_prediction_result
  -> render_prediction_plots
```

The App creates the experiment in `trainModel_Generic` and runs it in `runPredictionLogic_Generic`. The `Time` selection maps to this workflow. `Freq` and `Space` do not change input shapes, layers, split policy or loss: they are currently UI-only selections.

## Models

- `TCN`: three causal convolution blocks with dilations 1, 2 and 4.
- `LSTM`: two 256-unit LSTM layers with dropout between recurrent blocks.
- `GRU`: two 256-unit GRU layers with dropout between recurrent blocks.

Each model choice reaches `build_prediction_layers` and `train_prediction_model`. These are reproducible baselines, not evidence of cross-scenario generalization.

## Data, validation and outputs

- Default split: chronological 70% train, 15% validation, 15% test.
- Windows are partition-local; normalization parameters come from real training data only.
- Synthetic windows may augment training only.
- Held-out test prediction and recursive future prediction are different outputs. The former has truth and metrics; the latter is a forecast without future ground truth in normal use.
- Export Model saves the trained network selected by the user. Save Data saves current result structures to a selected local location.

## Evaluation limits

The current report exposes RMSE, NRMSE, Capacity Accuracy, timing and display metrics. DS-CDF currently uses a Gaussian approximation. Angular and Doppler plots are auxiliary legacy displays, not separate predicted targets. See [Open Issues](OPEN_ISSUES_AND_REFACTOR_ROADMAP.md) before making scientific claims.

## Tests and future work

- Automated: `test_prediction_experiment.m`, `test_prediction_models.m`, `test_prediction_rendering.m`.
- Manual: train and predict at least one Time-domain model through the GUI.
- Planned: empirical DS CDF, complete group-RMSE handling, experiment manager, task-specific frequency/spatial routes, Complex-H contracts, pre-trained Base Model and safe user adaptation.
