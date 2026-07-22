# Contributing to ChanAI Pulse

## Branch policy

- `main` is the stable legacy-release line. Do not commit directly to it.
- `develop/v2.0` is the integration line for approved v2.0 work.
- Create a focused branch from the line that owns the work, for example `docs/...`, `feature/v2-...`, `fix/...`, or `test/...`.
- Open a pull request for review. The repository owner performs every merge manually; never enable or use automatic merge.

## Before coding

1. Start from the current target branch and inspect `git status`.
2. Read [Repository Structure](REPOSITORY_STRUCTURE.md), [API Reference](API_REFERENCE.md), and the applicable pipeline document.
3. Keep one PR focused. Do not combine algorithm changes, GUI redesign, data migration and documentation rewriting without explicit approval.

## Required validation

- Run the relevant MATLAB tests from [Testing](TESTING.md).
- When App callbacks, plots or layouts change, complete the [GUI manual checklist](GUI_MANUAL_TEST_CHECKLIST.md).
- State precisely what was not run and why. Never describe an unrun test as passed.
- Algorithm, metric, data-contract, generator, or App workflow changes require evidence and review; documentation-only changes do not alter scientific claims.

## Data safety

Never commit private measurements, archives, local conversion outputs, model checkpoints, experiment outputs, user paths, screenshots containing sensitive metadata, tokens or keys. Public demo data must be synthetic. Review `git status` before staging and stage explicit files rather than using indiscriminate commands.

## Pull request content

Describe the purpose, affected modules, tests run, manual GUI checks, data provenance, any changed scientific behavior, rollback approach, and unresolved risks. If a change affects an existing baseline, include a comparison or explicitly request a scientific review.
