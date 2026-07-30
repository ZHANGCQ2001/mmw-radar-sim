# Legacy-to-v2 migration map

| Legacy responsibility | v2 destination | Decision |
|---|---|---|
| `mmw_make_waveform_config`, carrier setter | `mmw.config.baseExperiment`, `deriveWaveform` | One source of truth; derived fields immutable |
| Scene and array factory chains | `mmw.config.loadExperiment` and array helpers | Composition replaces inheritance-by-mutation |
| `mmw_generate_transmit_signal` | `mmw.signal.generateChirp` | Retained physical convention |
| `mmw_simulate_receive_signals` | `mmw.signal.simulatePointTargets` | Rewritten with explicit seed and dimensions |
| `mmw_process_receive_signals` | `mmw.processing.formRangeDopplerCube` | Rewritten; complex RD-IQ is primary data |
| Time-domain matched-filter image | `mmw.imaging.timeDomainMatchedFilter` | Optional validation chain |
| RD-cube interpolation image | `mmw.imaging.fromRangeDoppler` | Primary practical chain |
| Radar RMS equalization | `mmw.fusion.radarAmplitudeGains` | Independent, testable helper |
| Oracle angle gate | `mmw.fusion.oracleAngleWeights` | Explicitly truth-dependent and opt-in |
| Dual-frequency runners | one `mmw.runExperiment` carrier loop | Duplicate runners removed |
| Dual-frequency power multiplication | `mmw.fusion.dualFrequencyProduct` | Grid validation included |
| Peak/pair/coverage metrics | `mmw.metrics.*` | Truth remains outside imaging |
| Plot and summary functions | `mmw.plotting.exportFigures`, `mmw.io.*` | Side effects confined to application boundary |
| `run_scene_*.m` scripts | named configs plus small examples | Names now match actual experiments |

## Legacy code intentionally not migrated

- Old OMP branches and ignored OMP artifacts: historical dictionary ambiguity
  experiments, not part of the active v0.3.27 chain.
- Per-version copied runner bodies: replaced by configuration.
- LibreOffice profiles, render checks, generated MAT/FIG caches.
- Hard-coded output paths based on `pwd`.
- Target-truth use inside ordinary imaging; only the explicit oracle experiment
  retains it.

## Known legacy problems addressed

- Runner names no longer disagree with target count or spacing.
- 61.8/62.2 GHz and 60/64 GHz cases are named configurations, not manual edits.
- Uniform, Golomb-like, and oracle-gated layouts all have reproducible IDs.
- Local 3 dB valleys and global target coverage are reported separately.
