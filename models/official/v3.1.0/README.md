# ChanAI Pulse v3.1.0 official Base Models

This directory is the self-contained, versioned P8 model package introduced by v3.1-5. A fresh clone contains every file required for CPU inference; no local experiment directory is needed.

## Frozen recommendations

| Task | Ordinary-user recommendation | Advanced compatible choices |
|---|---|---|
| Interpolation | Persistence | Persistence, Linear, AR, Kalman, GRU, LSTM, TCN, DLinear, NLinear |
| Extrapolation | Kalman | Persistence, Linear, AR, Kalman, GRU, LSTM, TCN, DLinear, NLinear |

The five neural checkpoints per task are official, reproducible experiment artifacts, but they are marked `official_experimental_not_system_recommended`: none passed every v3.1-4 admission gate. Manual selection never changes the ordinary-user recommendation.

## Package contract

- Parameter bundle: ordered P8 (`DS_mu`, `KF_mu`, `DS_sigma`, `KF_sigma`, `r_DS`, `LNS_ksi`, `num_clusters`, `num_rays`).
- Input/output shape: `[N,16,8] -> [N,4,8]`.
- Registries contain preprocessing statistics, units, bounds, compatibility signatures, validation evidence and SHA-256 hashes.
- Checkpoints are loaded with `torch.load(weights_only=True)` and rejected if their registered hash changes.
- Only GRU, LSTM and TCN support v3.1-5 head-only adaptation. DLinear and NLinear remain manual inference choices.
- Automatic adaptation uses only a separately labelled known region, validates on a disjoint known-region split, and rolls back unless the adapted model beats both its original checkpoint and the registered safe baseline.
- Prediction-target truth is never used for selection or adaptation.

## Files

```text
interpolation/interpolation_model_registry_v2.json
interpolation/interpolation_{gru,lstm,tcn,dlinear,nlinear}.pt
extrapolation/extrapolation_model_registry_v2.json
extrapolation/extrapolation_{gru,lstm,tcn,dlinear,nlinear}.pt
```

The package is intentionally small: it contains 10 selected checkpoints and two registries, not search checkpoints, training caches, private measurements or large experiment outputs.

## v3.1-7 flexible product execution

The public UI is no longer restricted to a 16-known/4-target task. The
versioned [`flexible_product_contract.json`](flexible_product_contract.json)
defines arbitrary valid public lengths, full-history classical trend models,
per-parameter Hybrid selection, bidirectional interpolation, and warning-only
performance diagnostics. The ten neural files above remain legacy native
16-to-4 checkpoints. GRU/LSTM/TCN encoders can consume all available known rows
through a clearly labelled runtime length extension; their four-point heads and
the fixed-width DLinear/NLinear models use an explicitly recorded rolling
compatibility layer for longer targets. They are not relabelled as newly trained
variable-length weights.

See [the v3.1-5 guide](../../../docs/v3.1/V3_1_5_MODEL_REGISTRY_AND_ADAPTATION.md) for commands and safety behavior.
