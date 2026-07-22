# Feature-to-Code Map

This map is based on the current callback chain in `app/ChannelSimulatorApp.m`. “UI-only” means a control updates application state or appearance but does not select an independent algorithmic data path.

| User feature | GUI entry / callback | Core implementation | Renderer | Test / status |
| --- | --- | --- | --- | --- |
| Start App | `ChannelSimulatorApp` constructor and `startupFcn` | runtime `addpath` registration | — | `smoke_test`, `test_app_runtime_paths`; Implemented |
| English / Chinese | language dropdown / `LanguageDropDownValueChanged` | App localization state | App labels and render styles | manual GUI; Implemented |
| Load MATLAB files | Load Data / `LoadDataButtonPushed` | `extract_raw_data`, `prepare_dpsd_snapshot`, `calculate_angular_spectrum`, `analyze_channel_data` | `render_characterization_plots` | characterization tests; Implemented for compatible MAT files |
| Band / scenario recognition | file-name/path heuristic in load workflow | App-local metadata heuristic | App values | manual GUI; Partially Implemented, not metadata-grade classification |
| Four characteristic plots | post-load `updateVisualizations` | characterization functions above | `render_characterization_plots` | `test_characterization_rendering`; Implemented legacy displays |
| Generate synthetic channel | Generate Channel / `GenStartButtonPushed` | `default_6gpcm_lite_config`, `generate_6gpcm_lite` | `render_generation_plots` | generator/rendering tests; Implemented lightweight baseline |
| Send generated data to AI | Send to AI / `GenSendToAIButtonPushed` | `generation_result_to_dpsd`; App interpolation/augmentation orchestration | generation page retained | experiment tests; Implemented with legacy augmentation policy |
| Real + generated training | dataset selected in App | `append_generated_training_windows`, `merge_training_sources` policy | prediction results later | `test_prediction_experiment`; Implemented; generated data is training-only |
| Select TCN | TCN button | `build_prediction_layers`, `train_prediction_model` | — | `test_prediction_models`; Implemented |
| Select LSTM | LSTM button | `build_prediction_layers`, `train_prediction_model` | — | `test_prediction_models`; Implemented |
| Select GRU | GRU button | `build_prediction_layers`, `train_prediction_model` | — | `test_prediction_models`; Implemented |
| Select Time | Time button | state selects current temporal workflow | — | manual GUI; Implemented |
| Select Freq | Freq button | no alternate data/model path | — | UI-only / Not Implemented as prediction task |
| Select Space | Space button | no alternate data/model path | — | UI-only / Not Implemented as prediction task |
| Train model | Train Model / `trainModel_Generic` | `prepare_temporal_prediction_experiment`, `train_prediction_model` | App training UI | experiment/model tests; Implemented |
| Validation / test isolation | invoked during train and run prediction | chronological 70/15/15 split, training-only normalization | metrics display | `test_prediction_experiment`; Implemented |
| Held-out and recursive prediction | Run Predict / `runPredictionLogic_Generic` | `run_prediction_model`, `predict_holdout_partition`, `recursive_predict`, `evaluate_prediction_result` | `render_prediction_plots` | prediction/render tests; Implemented baseline |
| Evaluate legacy metrics | prediction result assembly | `compute_rmse`, `compute_nrmse`, `compute_capacity_accuracy`, `compute_ds_cdf` | `render_prediction_plots` | unit/integration coverage; Implemented with documented limits |
| Save prediction data | Save Data / `SaveDataButtonPushed` | App writes selected result structures | — | manual GUI; Implemented, user-selected local location |
| Export trained model | Export Model / `ExportModelButtonPushed` | App saves `net` only | — | manual GUI; Implemented, user-selected local location |
| ChanAIs dataset validation | programmatic API, not App file picker | `validate_chanais_dataset`, `load_chanais_dataset` | — | `test_dataset_contract`; Implemented API |
| SAGE conversion | converter tool, explicit caller action | `read_sage_mat`, `convert_sage_to_chanais` | — | `test_dataset_contract`; Implemented helper |

## Data flow

```text
MAT files -> App extraction -> DPSD matrix [delay bins x snapshots]
         -> chronological experiment -> windows -> baseline network
         -> held-out metrics / recursive future sequence -> external renderer

6GPCM-lite CIR [1 x 1 x snapshots x delay bins]
         -> DPSD conversion -> optional training-only augmentation
```

The plots labelled angle or Doppler are characterization/evaluation displays in the current baseline. They do not establish separate angle, spatial, or Doppler prediction tasks.
