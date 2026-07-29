# ChanAI Pulse Roadmap

This roadmap distinguishes code currently present on `main` from research direction. It does not commit to release dates.

## Completed

- MATLAB desktop App with Characterization, Channel Generation, and Prediction & Training pages.
- GUI-independent extraction of characterization, generation, prediction and plotting functions.
- Legacy DPSD/power time-domain Train / Validation / Test workflow with training-only normalization.
- Baseline TCN, LSTM and GRU training and recursive prediction flow.
- Internal 6GPCM-lite synthetic CIR generator and legacy DPSD conversion.
- ChanAIs schema validation, SAGE-compatible conversion helpers, synthetic demo fixtures and data-provenance rules.
- ChanAI Pulse v3 CIR/CTF and interpolation/extrapolation task contracts.
- Four deterministic v3 CIR/CTF standard fixture families and capability baselines.
- A read-only, fixed-seed, headless full-6GPCM technical probe with canonical CIR conversion and core-integrity verification.
- v1.1.0 release tag for the legacy baseline and v2.0 planning documents.

## In progress

- Documentation synchronization and clearer separation of the legacy baseline from v2.0 research plans.
- Scientific review of legacy evaluation and generation boundaries, including DS CDF and delay-axis consistency.
- ChanAI Pulse v3.0 requirement, data-contract and interface work. The frozen v3.0 requirements are planning baselines and are not claims of completed functionality.

## Next

- Build the v3 module-one channel-data ingestion, validation and task-setup pipeline.
- Build capability-aware visualization shared by the input and prediction modules.
- Add real Grid Search and simulated annealing behind optimizer interfaces.
- Predict target-region channel parameters and convert them to predicted complex CIR through 6GPCM.
- Keep prediction-accuracy evaluation in a standalone benchmark outside the platform UI.
- Establish a version-pinned, reproducible official QuaDRiGa minimal generation workflow.
- Define and test a Complex-H data contract for dynamic wideband SISO data.
- Build task-specific data ingestion, validation and visualization for that contract.
- Create fixed, authorized benchmark fixtures and preserve the legacy power baseline as a comparison path.

## Long-term

- Pre-train and register scenario-bounded Base Models, then implement explicit user-data adaptation with held-out protection.
- Complex-valued \(H(t,f)\) prediction, then dynamic wideband MIMO and space-time-frequency H tensors.
- Cross-scenario/cross-band experiments only after data, task, split and metric protocols are established.
- A potential Python/Web service layer after the MATLAB research workflow is stable.

## Out of current scope

- Claims of experimentally validated “all-frequency” or “all-scenario” prediction.
- Official QuaDRiGa integration, Base Model registry, online adaptation and MIMO Complex-H prediction.
- Web, FastAPI, React, cloud execution or a standalone installer.
- Public release of private measurements or a ChanAIs research dataset without separate authorization.
