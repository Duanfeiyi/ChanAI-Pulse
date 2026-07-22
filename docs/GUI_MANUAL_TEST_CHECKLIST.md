# GUI Manual Test Checklist

Run from the repository root in MATLAB:

```matlab
addpath(genpath(pwd))
ChannelSimulatorApp
```

## General

- [ ] The App opens and all three tabs are visible: Characterization, Channel Generation, Prediction & Training.
- [ ] English and Chinese switching updates labels without severe overlap.
- [ ] Resizing leaves controls usable.

## Characterization

- [ ] Load a public synthetic demo or an authorized local compatible MAT file.
- [ ] Confirm the four legacy characteristic plots render without NaN/Inf errors.
- [ ] Treat displayed angle/Doppler axes as legacy visualization unless source metadata establishes physical units.

## Generation

- [ ] Generate a 6GPCM-lite result with default controls.
- [ ] Confirm generated PDP and DS-CDF views render.
- [ ] Use Send to AI only after generation succeeds.
- [ ] Do not interpret this as QuaDRiGa, official 6GPCM, or physical calibration.

## Prediction

- [ ] Select `Time`, then train one of TCN, LSTM, and GRU on a suitable sequence.
- [ ] Confirm validation and held-out test information are shown after prediction.
- [ ] Confirm Save Data and Export Model ask for a user-selected local destination.
- [ ] Record that `Freq` and `Space` are UI-only selections; do not use them to claim domain-specific prediction.

## Reporting failures

Record MATLAB release, Git revision, exact UI steps, full error text, whether a public synthetic or authorized local dataset was used, and a non-sensitive screenshot. Do not commit private filenames, locations, measurements or exported artifacts.
