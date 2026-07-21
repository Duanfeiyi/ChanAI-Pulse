# Generation Pipeline

## Module goal and status

**Implemented:** an internal, lightweight `6GPCM-lite` synthetic generator for controlled demos and augmentation experiments. **Not implemented:** official 6GPCM, QuaDRiGa, scenario-calibrated Complex-H generation, or MIMO generation.

## Call flow

```text
Generation page controls
  -> default_6gpcm_lite_config
  -> generate_6gpcm_lite
  -> render_generation_plots
  -> generation_result_to_dpsd (only after Send to AI)
  -> optional training-only augmentation
```

## Inputs, outputs and dimensions

- Input: configuration struct with bandwidth, seed, clusters, rays, delay-spread/K-factor parameters, Doppler scale and snapshots.
- Output: complex synthetic CIR `[1 x 1 x snapshots x delayBins]`, delay axis, generated spread samples and cluster/ray metadata.
- Current training adapter output: DPSD `[delayBins x snapshots]` in dBm.

## GUI integration and data policy

`GenStartButtonPushed` generates and renders the result. `GenSendToAIButtonPushed` converts it and prepares the existing App augmentation state. Formal prediction experiments append synthetic windows to train only; validation and test stay real/evaluation-derived.

## Tests, errors and limits

- Automated: `test_generation_6gpcm_lite.m`, `test_generation_rendering.m`.
- Manual: generate with defaults, inspect PDP/CDF, then use Send to AI and complete a time-domain training flow.
- Configuration validation raises errors for invalid numeric settings.
- `6GPCM-lite` is a lightweight internal generator, not an official external engine and not proof of physical fidelity.
- The configured delay-grid step and bandwidth-derived delay axis require scientific reconciliation (`GEN-001`); do not use current DS/PDP output as a final calibration claim.
- Planned: version-pinned QuaDRiGa adapter, explicit trajectory/antenna contracts and Complex-H generation.
