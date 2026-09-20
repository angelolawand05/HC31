# HC31 curated analysis scripts — repository candidate set v1.0

This package is a **curated code-only selection** from the B1–B4 HC31 archives for the frozen scientific manuscript **HC31 v10.3.24**.

It intentionally excludes analysis outputs, figures, CSV result tables, MAT checkpoints, old backups, test scripts, superseded variants, and third-party packages. The goal is to keep only the analysis modules that directly generated, or are upstream dependencies of, results retained in the final manuscript.

## What is included

### 01_primary_beta
Core 13–30 Hz broad-beta / 23–30 Hz beta2 detection, Run1 time courses, event-location mapping, novel/familiar classification, movement analyses, entry-novelty sensitivity, spatial occupancy/rate heat maps, and the retained trace-QC script.

Main manuscript links: Figures 2–9 and the primary temporal/novelty analyses.

### 02_final_temporal_spatial_stats
The final sign-flip based Batch 4 updated-statistics runner and its local helpers.

Main manuscript links: Figures 4, 5, 8, and 9A; animal-level temporal and spatial summaries.

### 03_spectral
The retained spectrum-generation script plus the final Batch 5 and Batch 6 FORCE runners and required helper functions.

Main manuscript links: Figures 10–12 and the spectral/harmonic interpretation.

### 04_neuronal_beta
The retained Batch 8 FORCE neuronal/event-control pipeline and Batch 11C PETH/phase-locking analysis.

Main manuscript links: Figures 13–14 and the detector-defined beta-event neuronal analyses.

### 05_high_frequency_candidates
Upstream awake/PRE candidate detection, waveform/manual-QC generation, L2 morphology/rule evaluation, corrected state classification, and final N+ master-event/tiering scripts.

Main manuscript links: Figure 15 and the candidate populations feeding Figures 16–20.

### 06_candidate_firing_amplitude
Batch 11O population/candidate analyses, movement-matched beta2 amplitude analysis, final Stage-B QC correction, and Batch 11P synthesis.

Main manuscript links: candidate-firing text, Figures 16–18, and the final corrected 742→542→536→257-pair amplitude chain.

### 07_spike_order
The retained Batch 11F spatial ordering and Batch 11I shuffle-controlled sequence analysis.

Main manuscript links: Figure 19 and the original-order component of Figure 20.

## Important: this is a curated source set, not yet a polished public release

The scripts are copied **unchanged** from the retained B1–B4 archives. Many contain hard-coded Windows paths and/or interactive file-selection prompts. Before publishing the repository, the next step should be to add a common configuration layer, clean run instructions, dependency/version information, and a reproducibility wrapper.

## External dependencies intentionally NOT bundled

- **CRCNS hc-31 raw/source data** (`resSave.mat`, Neuralynx CSC files, etc.). The repository should point users to CRCNS rather than redistribute the source dataset.
- **Neuralynx MATLAB import/export utilities**, including `Nlx2MatCSC`. These were present in B1 but are third-party software and should be installed/documented separately.
- **Chronux**. A complete Chronux tree was bundled in B1, but it is third-party software. Document it as a dependency instead of republishing it.
- **Walsh et al. reference code** bundled in B1. It was used as a methodological reference during development but is not HC31-authored final repository code.

## Important code gaps found in B1–B4

The archives do **not** contain a standalone script that exactly reproduces every final manuscript calculation. These should be resolved before making a public reproducibility claim:

1. **Final circular-shift / held-out spatial tests.** The final manuscript describes a 2,000,000-draw moving-exposure circular-shift null and exact hypergeometric held-out overlap calculation. The retained `hc31_batch4_novelty_statistics.m` is an earlier related implementation and does not encode the final procedure exactly.
2. **Final detector-defined beta event-control analysis (Figure 13).** Batch 8 is the closest retained source pipeline, but its control implementation does not exactly match the final manuscript's 200-control / nearest-speed-control description and its archived summary values are not numerically identical to the final table.
3. **Ridge-regularised 64-clear-label screening model.** No standalone ridge-model script matching the final manuscript description was identified in B1–B4. Batch 11L2 contains the retained morphology/rule-screening branch, not the missing ridge model itself.
4. **Final Run1 traversal high-frequency matched-control firing analysis (Figure 16).** No standalone script matching the final 50-seed, five-controls-per-event calculation and +0.532 Hz/unit result was identified in B1–B4. The included Batch 11O code covers closely related candidate population-firing analyses and the downstream candidate/amplitude pipeline.
5. **Alternative spike-order specifications in Figure 20.** Batch 11F/11I reproduce the archived original spatial ordering and Figure 19. Standalone code for the later quality-filtered, median accepted-field, and dominant repeat-cluster ordering recalculations was not located in B1–B4.
6. **Historical saved spectral estimator.** The manuscript correctly states that the exact estimator used for the archived individual spectra could not be recovered. `psdspec_fixed_groupmean.m` and the Batch 5/6 runners are retained available implementations, not proof of the historical estimator identity.

These gaps are why this archive should be treated as the **curated source-code base for the repository**, followed by a small clean-reproduction layer for the final manuscript calculations that are not present as standalone scripts.

## Source archive selection

- **B1:** inspected, but no unique manuscript-critical HC31 script was selected. It primarily contained outputs and bundled third-party/reference code; later HC31 script versions were retained from B3/B4.
- **B2:** final late-stage candidate, QC-correction, and synthesis scripts.
- **B3:** final FORCE-runner modules and their helper functions.
- **B4:** core and intermediate HC31 MATLAB scripts.

See `FIGURE_SCRIPT_MAP.md` and `MANIFEST.csv` for the detailed mapping.
