# Synthetic Demo Data

This folder contains small synthetic demo datasets for ChanAI Pulse.

Files:

- `demo_sub6_scenario1.mat`
- `demo_mmwave_scenario2.mat`

These files are not measured data. They are generated from simple synthetic power-delay patterns and are intended only for:

- quick App loading checks;
- GUI visualization tests;
- smoke testing public repository setup;
- beginner demonstrations.

They must not be used as scientific benchmark evidence.

Real measured datasets remain local-only under `datasets/measured/` and must not be copied into this folder.

To regenerate the demo files in MATLAB:

```matlab
run("demo_data/generate_demo_data.m")
```

The generated `.mat` files contain:

- `DPSD_dB`: synthetic delay-power style matrix in dB;
- `metadata`: a struct explicitly marking the data as synthetic.

