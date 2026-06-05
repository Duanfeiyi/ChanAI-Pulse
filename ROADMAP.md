# Roadmap

This roadmap is directional and does not commit to specific release dates.

## v1.0.0 - Platform Prototype

Status: completed.

- MATLAB desktop research prototype.
- Three-module workflow: Channel Characterization, Channel Generation, Channel Prediction & Training.
- Public source code release.
- MATLAB App Package release.
- Synthetic demo data.
- Dataset policy and collaboration documentation.

## v1.1.0 - ChanAIs Dataset

Status: active planning and initial framework.

Goals:

- Define ChanAIs Dataset v1.0.
- Establish unified wireless channel data format.
- Establish unified metadata specification.
- Provide SAGE / CIR / CTF / PDP compatibility plan.
- Add SAGE-compatible converter framework.
- Add synthetic SAGE-like public demo dataset.
- Add lightweight Dataset Manager interfaces.

Out of scope for v1.1.0:

- Benchmark leaderboard.
- New prediction algorithms.
- Physics-informed loss.
- Web platform.
- Public release of private measured datasets.

## v1.2.0 - ChanAI Benchmark

Planned.

- Define benchmark tasks and fixed dataset splits.
- Add reproducible evaluation reports.
- Add baseline result templates.
- Prepare future leaderboard rules.

## v2.0.0 - Physics-Informed Prediction

Planned.

- Explore physics-informed constraints for channel prediction.
- Connect channel statistics, propagation priors, and AI models.
- Preserve compatibility with ChanAIs Dataset and Benchmark formats.

## v2.1.0 - Cross-Scenario Generalization

Planned.

- Study transfer across frequency bands, environments, mobility patterns, and antenna configurations.
- Define cross-scenario validation protocols.
- Extend dataset metadata and split strategy.

## v3.0.0 - Web Platform & Cloud Deployment

Planned.

- Explore Web platform and cloud deployment after MATLAB workflow and dataset standards are stable.
- Possible Python/FastAPI/React migration path.
- Cloud-side experiment tracking and collaborative dataset browsing.

