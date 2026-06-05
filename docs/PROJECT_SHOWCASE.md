# ChanAI Pulse Project Showcase

## Project Background

Wireless channel modeling is becoming increasingly complex as communication systems move beyond a single frequency band, a single deployment scenario, or a single propagation assumption. Future wireless research needs to compare and connect Sub-6 GHz, mmWave, THz, optical wireless, satellite, UAV, maritime, RIS, industrial IoT, ISAC-oriented, and other emerging scenarios in a unified experimental workflow.

ChanAI Pulse is designed for this research need. It provides a MATLAB-based platform for channel characterization, channel generation, and AI-driven prediction while keeping the workflow accessible to students and research teams.

## Platform Positioning

ChanAI Pulse is an AI-driven universal channel characterization, generation and prediction platform for full-frequency and full-scenario wireless channel research, with 6G-oriented applications.

中文定位：ChanAI Pulse 是一个面向全频段、全场景无线信道研究的 AI 驱动信道特性分析、信道生成与信道预测平台，并面向 6G 通信场景进行应用扩展。

The project is not limited to a single millimeter-wave tool or a single 6G scenario. Its long-term goal is to become a reusable research platform that connects measured data, synthetic channel generation, AI model training, prediction evaluation, and future benchmark tasks.

## Three Core Modules

### Channel Characterization

The characterization module supports channel data loading and feature analysis. It focuses on extracting and visualizing channel properties such as angular behavior, delay-domain characteristics, Doppler-related behavior, and statistical distributions.

### Channel Generation

The generation module supports synthetic channel generation and data augmentation workflows. It provides a controlled way to create channel-like data for algorithm validation, GUI testing, and future benchmark design.

### Channel Prediction & Training

The prediction module supports AI-based channel prediction and training workflows. The current MATLAB App keeps the existing TCN, LSTM, and GRU model selection workflow and preserves the original training and prediction behavior.

## Technical Route

```text
Channel data
  |
  v
Feature extraction and channel characterization
  |
  v
Synthetic channel generation and data augmentation
  |
  v
AI model training and prediction
  |
  v
Metric evaluation and benchmark preparation
```

The v1.0.0 public release focuses on a stable MATLAB App Package, clear project structure, public synthetic demo data, and documentation for future collaboration.

## Platform Characteristics

- Unified research positioning across full-frequency and full-scenario wireless channel studies.
- MATLAB App workflow suitable for laboratory research and student collaboration.
- Three-module structure: characterization, generation, and prediction.
- Synthetic demo data included for public testing.
- Private measured datasets excluded from the public repository.
- Clear roadmap for future ChanAIs Dataset and benchmark ecosystem.
- Documentation designed for both academic presentation and engineering collaboration.

## Dataset And Benchmark Direction

The current public repository does not include private measured datasets. Future dataset work will be organized through a separate ChanAIs Dataset plan, including authorization, anonymization, unified schema design, metadata documentation, task definition, and version management.

Benchmark development will focus on reproducible tasks such as channel characterization, channel generation, channel prediction, missing data completion, and cross-scenario generalization.

## Future Development

Planned directions include:

- More standardized synthetic demo scenarios.
- Experiment management and benchmark reporting.
- A future authorized ChanAIs Dataset release.
- Reproducible baseline models and evaluation protocols.
- MATLAB App Package refinement.
- Possible future Python/Web migration after the MATLAB workflow is stable.

