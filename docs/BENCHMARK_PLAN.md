# ChanAIs Benchmark Plan

## 1. Benchmark Motivation

ChanAI Pulse has a long-term research ambition to support broader wireless-channel studies. A reproducible benchmark is needed before comparing characterization, generation, or prediction methods under consistent data splits, metrics, and reporting rules. This benchmark is not implemented.

The benchmark plan is currently a roadmap. No private measured datasets are included in this repository, and no new benchmark implementation is added in this stage.

## 2. Supported Tasks

### Channel Characterization

Evaluate whether a method can extract stable and meaningful channel statistics, such as delay spread, angular spectrum, power delay profile, Doppler-related features, and scenario-level descriptors.

### Channel Generation

Evaluate whether generated channel data can match target statistical properties and support downstream prediction tasks.

### Channel Prediction

Evaluate short-term and recursive channel prediction performance across different frequency bands, scenarios, and temporal windows.

### Missing Data Completion

Evaluate whether models can reconstruct missing channel samples, incomplete channel matrices, or partially observed time-frequency channel responses.

## 3. Evaluation Metrics

Initial candidate metrics include:

- RMSE
- NRMSE
- MAE
- Capacity Accuracy
- K-S Distance
- Inference Latency
- Training Time
- PDP matching score
- Doppler spectrum matching score
- Delay spread CDF matching score

Additional metrics may be added after the ChanAIs Dataset schema and benchmark tasks are frozen.

## 4. Baseline Models

Candidate baselines include:

- Statistical channel models
- Persistence and moving-average predictors
- LSTM
- GRU
- TCN
- Lightweight Transformer-style models
- Scenario-specific generation baselines

The first benchmark version should prioritize stable, reproducible baselines rather than overly complex models.

## 5. Dataset Split Strategy

Recommended split levels:

- Random sample split for basic sanity checks.
- Time-based split for prediction tasks.
- Scenario-based split for generalization testing.
- Frequency-band split for cross-band transfer evaluation.
- Device or measurement-session split when metadata allows.

Each benchmark release should publish fixed train, validation, and test lists to avoid accidental data leakage.

## 6. Future Leaderboard

A future leaderboard may report:

- Task name
- Dataset version
- Scenario
- Frequency band
- Model name
- Metrics
- Training cost
- Inference latency
- Code availability
- Reproducibility notes

The leaderboard should only be introduced after the dataset license, schema, and evaluation scripts are stable.

