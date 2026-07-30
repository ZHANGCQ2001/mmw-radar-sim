# Radar Simulation v2 Architecture

## Design goals

The v2 tree is a clean implementation derived from the physical intent and
measured behaviour of the legacy prototype. The legacy files are not runtime
dependencies. Configuration, numerical algorithms, metrics, plotting, and
artifact I/O have one-way dependencies and can be tested independently.

## Public API

```matlab
startup
cfg = mmw.config.loadExperiment("scene_b_calibration", "smoke");
result = mmw.runExperiment(cfg);
```

`run_experiment(name, mode)` is the convenience entry point. `mode` is either
`"full"` or `"smoke"`.

## Dependency direction

```text
config -> signal -> processing -> imaging -> fusion -> metrics
                                             |          |
                                             +-> plotting/io
```

Numerical layers do not create directories, write files, or draw figures.
`mmw.runExperiment` is the application service that coordinates those layers.

## ExperimentConfig

Every experiment is a scalar structure with these top-level fields:

- `id`, `description`
- `waveform`: one or two carrier frequencies plus chirp/ADC parameters
- `array`: radar poses and local TX/RX phase centres
- `scene`: room and target truth
- `simulation`: noise, seed, gain, and path-loss controls
- `processing`: windows and FFT sizes
- `imaging`: x-y grid, fixed z plane, and enabled methods
- `fusion`: amplitude equalization, CF, and explicitly named oracle gate
- `metrics`: peak and target-matching rules
- `output`: artifact policy and location

`mmw.config.validateExperiment` rejects inconsistent or non-physical values.
Carrier-dependent derived quantities are produced by
`mmw.config.deriveWaveform`; they are never stored as independent mutable
configuration.

## Result structure

`mmw.runExperiment` returns:

- `config`: validated experiment configuration
- `acquisitions(k)`: waveform, transmit signal, receive cube, processed RD-IQ,
  time-domain image (optional), and RD image for carrier `k`
- `dualFrequency`: normalized power product for two-carrier experiments
- `metrics`: truth-based evaluation, kept outside imaging
- `manifest`: reproducibility metadata
- `outputDirectory`: empty when artifact writing is disabled

## Truth boundary

Target truth enters only receive-signal generation and metrics. Imaging is
truth-independent unless `fusion.oracleAngleGate.enabled` is true. That field
name is deliberately explicit because the gate is an ideal prior, not an
estimated sensor angle.

## Legacy migration boundary

See `MIGRATION.md`. OMP experiments, render caches, generated MAT files, and
legacy report builders are not runtime dependencies of v2.
