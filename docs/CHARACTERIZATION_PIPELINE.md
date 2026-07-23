# Characterization Pipeline

## Module goal and status

**Implemented:** characterize compatible local MAT inputs for the legacy App display and produce four plot-ready metrics. This is not a general Complex-H characterization pipeline.

## Call flow

```text
App file picker -> load MAT -> extract_raw_data
  -> calculate_angular_spectrum
  -> prepare_dpsd_snapshot (per snapshot)
  -> DPSD matrix [delay bins x snapshots]
  -> analyze_channel_data
  -> render_characterization_plots
```

## Inputs and outputs

- Input: one or more user-selected compatible `.mat` files. The extractor recognizes several historical numeric/struct field conventions.
- Intermediate: legacy DPSD values `[delay bins x snapshots]` in dBm; target length is normally 200 bins, with a 500-bin branch for selected App scenarios.
- Output: angle display, delay-power display, delay-spread samples/CDF, and normalized Doppler display for four UI axes.

## Core functions and GUI integration

`LoadDataButtonPushed` invokes the pipeline through `loadData_Generic`; `updateVisualizations` calls `render_characterization_plots`. Public computation interfaces are listed in [API Reference](API_REFERENCE.md).

## Error handling

The App reports failed file loading and skips invalid selected files. Unsupported shape/axis semantics may still produce a legacy fallback representation; users must inspect metadata and plotted axes before scientific interpretation.

## Tests and known limits

- Automated: `test_characterization_pipeline.m`, `test_characterization_rendering.m`.
- Manual: load a public synthetic demo and inspect all four plots through the [GUI checklist](GUI_MANUAL_TEST_CHECKLIST.md).
- `prepare_dpsd_snapshot` preserves old scenario-specific behavior, including padding with `-130 dBm`; it is not a validated universal CIR parser.
- Doppler display uses a normalized axis, not a physical frequency axis inferred from sampling metadata.
- Planned: metadata-aware complex-H/CIR characterization with physically validated time, delay, frequency and antenna axes.
