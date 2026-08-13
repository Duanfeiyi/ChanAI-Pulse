# ChanAI Pulse v3.1-6 formal evidence summary

- Protocol: `v31_6_end_to_end_benchmark.2`
- Test Full-6GPCM parameter pairs: 660
- Validation gate: PASS; Test was not used for model selection.
- Full 6GPCM core unchanged: `true`

## Frozen product conclusion

| Task | Registry default | Test mean complex NMSE | Descriptive best classical | Descriptive best overall |
|---|---:|---:|---:|---:|
| interpolation | persistence | 1.67197 | ar (1.49999) | dlinear (1.48049) |
| extrapolation | kalman | 1.52488 | kalman (1.52488) | gru (1.49882) |

The Test set does not change the Registry v2 defaults. Neural results remain advanced/research evidence unless admitted by a future predeclared study.

## Scope limits

- Angular metrics are explicitly unavailable from the current public adapter.
- Nt=4 temporal and Doppler outputs are short-window diagnostics, not a long-sequence study.
- Large row-level CSV and generated channel caches remain outside Git; source hashes are in the JSON summary.
