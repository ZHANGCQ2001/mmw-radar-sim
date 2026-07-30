# Validation evidence

Validation was run on MATLAB R2024b (`24.2.0.2712019`) on `PCWIN64`.

## Static analysis

Command:

```matlab
files = [dir('*.m'); dir(fullfile('+mmw','**','*.m')); ...
    dir(fullfile('examples','*.m')); dir(fullfile('tests','**','*.m'))];
% checkcode(file, '-id') for every file
```

Result: 37 MATLAB files checked, zero error-level findings. Seven analyzer
messages were non-blocking historical-message/performance notices.

## Automated tests

Command:

```matlab
cd radar_sim_v2
startup
run_all_smoke_tests
```

Result: **12 passed, 0 failed, 0 incomplete**.

Coverage includes configuration validation, carrier/wavelength conversion,
exact path length, range-axis mapping, complex RD dimensions, normalized
dual-frequency multiplication, grid mismatch handling, unique target coverage,
3 dB valley metrics, Scene B end-to-end focus, deterministic repeatability,
coherent-versus-noncoherent Scene B localization, dual-carrier smoke execution,
and the target-free Scene A chain.

## Full Scene B acceptance

Command:

```matlab
result = run_experiment("scene_b_calibration", "full", true);
```

RD coherent localization error: **0.000000 m**. Acceptance criterion (no more
than one 0.025 m grid cell) passed.

Artifacts: `artifacts/scene_b_calibration/`.

## Full 60/64 GHz two-target acceptance

Command:

```matlab
result = run_experiment("dual_two_60_64", "full", true);
```

| Metric | Legacy v0.3.26 | v2 |
|---|---:|---:|
| Target coverage | 2/2 | 2/2 |
| All targets detected | true | true |
| T1-T2 dual valley dip | 32.13 dB | 32.133048 dB |
| Sidelobe-map correlation | 0.3831 | 0.383112 |
| Dual peak localization error | 0 m | 0 m |

Artifacts: `artifacts/dual_two_60_64/`.

## Full 60/64 GHz four-target negative result

Command:

```matlab
result = run_experiment("dual_four_60_64", "full", true);
```

| Metric | Legacy v0.3.27 | v2 |
|---|---:|---:|
| Target coverage | 3/4 | 3/4 |
| Missing target | T1 | T1 |
| Sidelobe-map correlation | 0.2830 | 0.283028 |
| Adjacent dips | 35.36 / 28.35 / 19.11 dB | 35.3607 / 28.3539 / 19.1077 dB |

The v2 implementation therefore preserves the important negative conclusion:
all adjacent local valleys pass 3 dB, but global Top-4 coverage is incomplete.
It does not mislabel local separability as successful four-target detection.

Artifacts: `artifacts/dual_four_60_64/`.
