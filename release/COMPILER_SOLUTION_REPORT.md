# MATLAB Compiler Solution Report

Current status: `license('test','Compiler')` returns 1, but MATLAB Compiler product files are not visible. `mcc`, `deploytool`, and `compiler.build.*` are unavailable in the detected R2022b installation.

## Plan A: Install MATLAB Compiler

Description: manually install MATLAB Compiler into the same MATLAB R2022b environment or use a MATLAB installation that already includes it.

Advantages:

- Most direct path to official MATLAB installer packaging.
- Compatible with App packaging workflows.
- Can support source release plus installer release.

Disadvantages:

- Requires MathWorks account access and product entitlement.
- May require administrator permission.
- Packaging still needs validation after installation.

Cost:

- Medium manual setup effort.

Success Rate:

- High if the license entitlement is real and the product can be installed.

## Plan B: Restore Old Packaging Environment

Description: locate the machine/environment that previously produced `ApplicationInstallerManifest.xml` and `ChannelSimulatorInstaller.exe`, then reproduce packaging there.

Advantages:

- May recover a known-working packaging flow.
- Could preserve icon, installer metadata, and old build settings.

Disadvantages:

- Old packaging files were not found locally in this workspace or the inspected desktop project tree.
- The old GitHub draft is reference-only and should not be used as an active release target.
- The old environment may be outdated or not reproducible.

Cost:

- Medium to high investigation effort.

Success Rate:

- Medium if old machine/project files are found; low otherwise.

## Plan C: Source-Only GitHub Release

Description: publish v1.0 as MATLAB source code with setup and run instructions, but without an installer.

Advantages:

- Does not require MATLAB Compiler.
- Fastest path to a clean open-source RC.
- Easier for academic users who already have MATLAB.

Disadvantages:

- Less convenient for non-MATLAB users.
- No standalone `.exe` installer.
- Users must manage MATLAB paths and toolboxes.

Cost:

- Low.

Success Rate:

- Very high.

## Plan D: Future Alternative Packaging

Description: investigate future migration or alternative packaging, such as MATLAB project packaging, Python/FastAPI plus React, or a compiled service wrapper.

Advantages:

- Could improve accessibility beyond MATLAB users.
- Useful for a later Web or cloud version.

Disadvantages:

- Out of scope for v1.0 RC.
- Requires algorithm/API migration.
- Higher risk of changing behavior.

Cost:

- High.

Success Rate:

- Medium long-term, low short-term.

## Recommended Order

1. Plan C: ship a source-only GitHub Release Candidate first.
2. Plan A: install MATLAB Compiler and produce an official installer when available.
3. Plan B: recover old packaging metadata only if old artifacts are found.
4. Plan D: treat alternative packaging as a future roadmap item, not a v1.0 blocker.

