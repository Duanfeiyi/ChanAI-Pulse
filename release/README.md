# Release Materials

This directory contains source-release guidance and historical packaging notes. It is not evidence that a current installer or MATLAB App package is present in this repository.

## Current status

- The supported public workflow is running the MATLAB source from a clone.
- v1.1.0 is the current tagged legacy baseline.
- No standalone executable is produced or tracked here.
- A MATLAB App package, if independently published as a GitHub Release asset, must be checked on that release page; do not assume an asset exists because a historical draft document mentions one.

## Safety

Do not add installers, archives, private data, local environment dumps, model checkpoints or experiment outputs to the source repository. Packaging requires separate toolchain verification and manual release approval.

Historical files in this directory record earlier packaging investigations. They are not current environment requirements and must not be used as run instructions without verification.
