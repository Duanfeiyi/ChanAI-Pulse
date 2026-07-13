# Unified Prediction Engine

## Purpose

The MATLAB App remains the user-facing entry point for ChanAI Pulse. This
module keeps shared prediction logic outside the App so TCN, LSTM, and GRU
can be tested and maintained without changing the GUI.

## Current Baseline Models

- `TCN`: three causal 1-D convolution blocks with dilation factors 1, 2, and 4.
- `LSTM`: two 256-unit LSTM layers with dropout between recurrent blocks.
- `GRU`: two 256-unit GRU layers with dropout between recurrent blocks.

These are the existing baseline architectures. This refactor does not add
residual blocks, weight normalization, new dropout behavior, or new training
hyperparameters.

## Interfaces

- `build_prediction_layers.m`: returns the selected baseline network layers.
- `train_prediction_model.m`: trains TCN, LSTM, or GRU with the App defaults.
- `run_prediction_model.m`: produces hold-out predictions, future predictions, and metrics.
- `recursive_predict.m`: performs future multi-step recursive prediction.
- `evaluate_prediction_result.m`: calculates the App's current metric definitions.

## Acceptance Rule

The runnable App is the non-negotiable acceptance standard. A prediction
refactor PR must preserve the three-page GUI, bilingual switching, existing
data split policy, existing metric definitions, and TCN/LSTM/GRU training and
prediction workflows.

## Future Model Research

Residual TCN blocks, configurable receptive field, weight normalization, and
other architecture changes should be proposed as separate research PRs after
the baseline refactor is accepted. They must be compared using the same
chronological train/validation/test protocol.
