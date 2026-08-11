# v3.1-1: bundled Full 6GPCM and zero-configuration generation

Issue: [#67](https://github.com/Duanfeiyi/ChanAI-Pulse/issues/67)

## What changed

`third_party/full_6gpcm/` contains the complete approved Full 6GPCM runtime package required by ChanAI Pulse. The package is copied as a runtime artifact: ChanAI Pulse does not edit its core files. The project-owned adapter remains responsible for parameter mapping, canonical CIR conversion, candidate selection, error reporting, and integrity checks.

The only excluded archive entry is `GUI/6gpcs.tmp`, a clearly temporary GUI file. No measured data, runtime cache, training corpus, model checkpoint, or experiment output is included.

## Normal use

Clone or download the repository, open MATLAB in the repository root, then run:

```matlab
addpath(genpath(pwd))
ChannelSimulator
```

No Full 6GPCM path configuration is required. Root resolution is based on the location of the ChanAI Pulse source files, not MATLAB's current directory, so installation paths containing spaces or Chinese characters are supported.

Automatic generation tries candidates honestly:

1. Compatible SISO requests use 6GPCM-Lite first.
2. MIMO requests, or requests Lite cannot support, use the bundled Full 6GPCM public API when it is available.
3. Only after every registered compatible candidate is unavailable does the application report a generation error.

## Advanced override

Developers may test another Full 6GPCM installation by explicitly setting the advanced UI `EngineRoot` field or the environment variable below before MATLAB starts:

```powershell
$env:CHANAI_FULL_6GPCM_ROOT = "D:\path with spaces\other-full-6gpcm"
```

An explicit override is never silently replaced by the bundled copy. Because it may be a different version, it is identified in manifests as `full_6gpcm_external_override` and is not checked against the bundled artifact hash.

## Technical integrity record

| Item | Value |
|---|---|
| Package ZIP SHA-256 | `fcf151adf94038a6cf10d86c6dd687938b085a8f78a64d6829b5439c1d6c5875` |
| Imported file count | `586` |
| Imported bytes | `94,491,478` |
| Imported tree SHA-256 | `369d778674004bbda6231b89b967b12c1fecacdddf9306b842db8982309a8ae9` |
| Fixed entry point | `generate_channel_v1.m` |
| Configurable API entry | `@channel_model/channel_model.m` |

The Full adapter hashes the runtime tree before and after a Full generation call. A changed tree causes the call to fail rather than presenting an unverified result.

## Required validation

Run the v3.1-1 regression from the repository root:

```powershell
matlab -batch "cd('repository-root'); addpath(genpath(pwd)); run('tests/run_v31_1_regression.m');"
```

The release acceptance additionally runs this regression from a fresh Git clone and from a ZIP-style extraction located in a path containing spaces and Chinese characters.
