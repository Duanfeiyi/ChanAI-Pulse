# ChanAI Pulse Pre-Refactor Baseline Acceptance

## Purpose

This document records the known-good baseline before the phased modular refactor. All future refactor pull requests must preserve the current runnable App behavior unless an approved change explicitly states otherwise.

## Baseline Revision

- Baseline branch: `feature/refactor-foundation`
- MATLAB: R2022b Update 10
- Automated smoke test: passed
- GUI verification: manually accepted

## Manual GUI Acceptance

The following checks were manually confirmed as normal:

1. `ChannelSimulatorApp` opens successfully.
2. The three main pages switch successfully.
3. English and Chinese UI switching works normally.
4. Synthetic demo loading and channel-characteristic plots work normally.
5. The existing channel generation workflow works normally.
6. The Prediction & Training page works normally.
7. No user-visible error or abnormal behavior was reported.

## Baseline Rule

Every modularization pull request must preserve this runnable-App baseline. Before merge, the pull request must pass the checks defined in `docs/CONTRIBUTING.md` and `docs/GITHUB_WORKFLOW.md`.

## Rollback

If a later refactor changes current behavior unexpectedly, revert the associated commit or restore the `pre-refactor-v1.1.0` tag. Do not delete the legacy App backup or rewrite published history.
