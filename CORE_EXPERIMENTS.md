# Focused six-node simulations

This update adds four primary single-carrier experiments for comparing uniform and Golomb node placement. The existing processing chain is unchanged.

## Experiment IDs

| ID | Layout | Targets |
|---|---|---|
| `single_6uniform` | Six-node uniform | One target at `(3.0, 3.0, 1.2)` m |
| `single_6golomb` | Six-node Golomb | One target at `(3.0, 3.0, 1.2)` m |
| `two_5cm_6uniform` | Six-node uniform | Two lateral targets at `x = 2.975` m and `x = 3.025` m |
| `two_5cm_6golomb` | Six-node Golomb | Two lateral targets at `x = 2.975` m and `x = 3.025` m |

All targets have `y = 3.0` m and `z = 1.2` m.

## Node positions

The two layouts use the same 3 m aperture.

Uniform layout:

```matlab
[1.5, 2.1, 2.7, 3.3, 3.9, 4.5]
```

Golomb layout, obtained by scaling `[0, 1, 4, 10, 12, 17]` to `[1.5, 4.5]` m:

```matlab
[1.500000, 1.676471, 2.205882, 3.264706, 3.617647, 4.500000]
```

## Common simulation settings

- One carrier: 62 GHz
- Six radar nodes, one TX and one RX phase centre per node
- Exact near-field TX-target-RX path model
- RD-IQ interpolation and coherent summation
- No dual-frequency multiplication
- No oracle angle gate
- No coherence-factor weighting
- No additive noise, so the comparison isolates array-layout effects
- Full-mode imaging grid: 2.5 mm

## Run one experiment

```matlab
startup
result = run_experiment("single_6uniform", "full", true);
```

Change the experiment ID to any of the four IDs above.

## Run all four experiments

```matlab
results = run_core_experiments("full", true);
```

Artifacts are written to `artifacts/<experiment-id>/`.

## Fast checks

```matlab
run_core_smoke_tests
```
