# MATLAB Environment Record

Recorded during ChanAI Pulse v1.0 Release Candidate stage 1 on 2026-06-04.

## MATLAB Runtime

- MATLAB executable detected: `E:\matlab2022b\bin\matlab.exe`
- MATLAB version reported by `version`: `9.13.0.2698988 (R2022b) Update 10`

## Toolboxes Observed

The local MATLAB installation reported these relevant products:

- Deep Learning Toolbox
- Signal Processing Toolbox
- Statistics and Machine Learning Toolbox
- Communications Toolbox
- 5G Toolbox

## MATLAB Compiler Detection

Observed checks:

- `license('test','Compiler')`: `1`
- `exist('mcc','file')`: `0`
- `exist('compiler.build.standaloneApplication','file')`: `0`
- `E:\matlab2022b\toolbox\compiler` exists: `false`

Interpretation: the environment appears to have a positive MATLAB Compiler license test, but the MATLAB Compiler product files and command/API entry points are not visible in the current MATLAB installation. Stage 1 does not attempt installation or packaging. Packaging should be revisited after confirming MATLAB Compiler is installed and available on the MATLAB path.

## Non-Fatal MATLAB Console Noise

Some batch-mode MATLAB commands exited with code 0 but printed Java shutdown messages during process termination. The smoke test should treat command success/failure by MATLAB execution status and explicit checks, not by the mere presence of this shutdown noise.

