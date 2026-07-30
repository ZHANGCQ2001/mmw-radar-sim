# Distributed FMCW Radar Simulation v2

A clean, dependency-light MATLAB implementation of same-wall distributed
60 GHz FMCW near-field coherent imaging. The v2 tree is independent of the
legacy prototype and does not require paid radar toolboxes.

## Quick start

```matlab
cd radar_sim_v2
startup
result = run_experiment("scene_b_calibration", "smoke", false);
```

Run all fast tests:

```matlab
cd radar_sim_v2
startup
run_all_smoke_tests
```

Run the principal full-grid acceptance experiment and write artifacts:

```matlab
result = run_experiment("dual_two_60_64", "full", true);
result.metrics.dualFrequency.coverage
```

Run the four-target negative test:

```matlab
result = run_experiment("dual_four_60_64", "full", true);
result.metrics.dualFrequency.coverage
```

List every named experiment:

```matlab
mmw.config.listExperiments
```

## What is implemented

- Exact TX-target-RX point-target paths and complex FMCW returns
- Reproducible complex noise and simple path loss
- Dechirp, range FFT, Doppler FFT, and full complex RD-IQ
- Time-domain matched filtering and RD-IQ near-field interpolation
- Single-radar, non-coherent, and coherent distributed images
- Radar RMS amplitude equalization and configurable coherence factor
- Explicitly named oracle angle gates for ideal-prior stress tests
- Independent-acquisition dual-carrier coherent-power multiplication
- Global peaks, Top-N suppression, target coverage, pair valleys, PSLR, and
  dual-carrier sidelobe correlation
- JSON manifest, text summary, PNG figures, and optional MAT output

## Experiment interpretation

The code distinguishes four statements:

1. The numerical chain is implemented.
2. An ideal simulation produced a positive result.
3. An ideal simulation produced a negative result.
4. Hardware feasibility has not been validated.

The 60/64 GHz pair is a large-separation stress test. It does not establish that
a particular radar supports the acquisition. Each carrier is simulated as an
independent complete FMCW RD-IQ acquisition. Absolute phase coherence between
carriers is not assumed; accurate inter-radar calibration within each carrier is.

The `oracle_*` experiments use target truth to gate candidate azimuths. Their
results are not the natural angular resolution of a compact radar. Ordinary
imaging never reads target truth.

## Configuration and outputs

Every run starts from a validated `ExperimentConfig`. Full runs write under
`artifacts/<experiment-id>/`; smoke runs default to no files. Numerical layers
have no file or plotting side effects. Set:

```matlab
cfg.output.writeArtifacts = true;
cfg.output.exportFigures = true;
cfg.output.saveMat = false;
```

The manifest records the complete config, random seed, MATLAB release, platform,
timestamp, and schema version.

## Dependencies

- MATLAB with `matlab.unittest`
- No Phased Array System Toolbox
- No Radar Toolbox
- No Signal Processing Toolbox (windows are implemented locally)

## Not yet implemented

- Radar position, phase, timing, and carrier-offset error sweeps
- Per-channel and per-radar calibration coefficient estimation
- First-order wall multipath and reflection sweeps
- Human multi-scatterer, trajectory, and micro-Doppler models
- General 3-D volumetric imaging
- Full 3TX4RX virtual-array scheduling and calibration
- Real sensor data import and hardware validation
- Soft probabilistic angular priors

See `ARCHITECTURE.md`, `MIGRATION.md`, and `VALIDATION.md` for design, legacy
mapping, executed test commands, and numerical acceptance evidence.
