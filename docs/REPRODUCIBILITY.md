# HC31 reproducibility guide

This document describes what can and cannot be reproduced from the retained HC31 analysis code currently included in this repository.

It is intended to be read alongside:

- the manuscript Methods;
- `docs/FIGURE_SCRIPT_MAP.md`;
- `docs/MANIFEST.csv`;
- the original CRCNS hc-31 dataset.

The scientific manuscript is the authoritative description of the final analysis. The code repository preserves the relevant retained MATLAB source from the HC31 project history. In several places, the final manuscript analysis was reconstructed from archived outputs, later audit calculations, or procedures for which no single final standalone script was preserved. Those cases are identified explicitly below.

## Reproducibility status labels

The following labels are used throughout this document.

### A - Direct retained implementation

The retained code directly represents the analysis or figure lineage used in the manuscript.

The script may still require:
- local path changes;
- separately downloaded CRCNS hc-31 data;
- MATLAB toolboxes;
- third-party Neuralynx import utilities;
- Chronux where applicable.

### B - Direct from retained intermediate outputs

The retained code can regenerate the final summary or figure from archived intermediate CSV or MAT outputs, but does not itself recreate all upstream inputs from raw data.

The current `derived_data/` package supports manuscript-level verification for these analyses when the required retained outputs are included there.

### C - Partial or closest retained implementation

Related source code and the upstream analysis lineage are retained, but the exact final manuscript procedure is not present as a single standalone B1-B4 script.

The retained code is useful for provenance and inspection, but should not be described as an exact raw-data reproduction of the final reported calculation.

### D - Final standalone code not retained

The final procedure is described in the manuscript and supported by retained outputs or audit records, but no standalone script implementing the exact final calculation was identified in B1-B4.

### E - Historical implementation detail unrecovered

An original implementation detail could not be reconstructed from the retained project material. The manuscript reports this limitation explicitly.

---

# 1. Source data required

The original electrophysiological recordings are not included in this repository.

They must be obtained directly from CRCNS:

**Dataset:** hc-31  
**DOI:** https://doi.org/10.6080/K0BV7DT2

Principal source files used across the retained analyses include:

- `resSave.mat`
- Neuralynx CSC `.ncs` files
- position and behavioural structures stored with the hc-31 data
- spike-time and unit metadata stored in the source dataset

Some scripts also expect outputs produced by earlier HC31 analysis stages.

The repository includes a compact `derived_data/` package for manuscript-level verification. It does not redistribute the raw CRCNS recordings.

---

# 2. Important execution limitations

The selected scripts were curated from the retained B1-B4 project archives. Before release, active personal Windows root paths were replaced with the `HC31_DATA_ROOT` environment variable plus an interactive fallback. These are path-only portability edits and do not change the scientific analysis logic.

They are not yet a portable one-command pipeline.

Common issues include:

- historical output-folder assumptions;
- interactive `uigetfile` prompts;
- assumptions about historical HC31 output-folder names;
- scripts that expect outputs from earlier analysis stages;
- third-party Neuralynx loading functions that are not redistributed;
- optional or historical use of Chronux.

For this reason, the status tables below distinguish the existence of the relevant retained source code from immediate out-of-the-box execution.

Set `HC31_DATA_ROOT` in MATLAB before running a module, or use the interactive root-folder prompt when available.


### MATLAB path isolation

Do not use `addpath(genpath('analysis'))` for the full repository. Several modules contain helper functions with the same filename but different module-specific implementations. Run each module from its own folder, or add only that module and its intended helper folder to the MATLAB path.

---

# 3. Primary beta and beta2 analyses

## 3.1 Event detection and Run1 time courses

**Status: A - Direct retained implementation**

Primary retained code:

- `analysis/01_primary_beta/hc31_extract_beta_bursts_over_time_FUNC.m`
- `analysis/01_primary_beta/hc31_run1_beta_timecourse_plots_PLAIN_SCRIPT.m`

These scripts contain the core broad-beta and beta2 detection and Run1 time-course workflow used upstream of the main temporal analyses.

They support:

- broad beta at 13-30 Hz;
- beta2 at 23-30 Hz;
- Hilbert-envelope event detection;
- valid-moving-time rate summaries;
- Run1 time-course outputs;
- event tables used by later novelty and spatial analyses.

Main manuscript links:

- Figure 3B detector counts
- Figure 7
- upstream data for Figures 4-6 and 8-9

### Requirements

- hc-31 `resSave.mat`
- Neuralynx CSC data
- Neuralynx MATLAB import functions

### Caveat

Set `HC31_DATA_ROOT` to the local hc-31 project/data root before rerunning, or use the interactive folder prompt.

---

## 3.2 Event-location classification

**Status: A - Direct retained implementation**

Primary retained code:

- `analysis/01_primary_beta/plotburstlocs.m`

Main manuscript link:

- Figure 2

The script maps detected Run1 events to the linearised and x-y track representations and assigns novel/familiar location labels using the retained behavioural boundaries.

---

## 3.3 Primary first-half versus second-half temporal statistics

**Status: A - Direct retained implementation**

Primary retained code:

- `analysis/02_final_temporal_spatial_stats/run_b4_updated_stats.m`
- helper functions in the same folder

Main manuscript links:

- Figure 4
- Figure 5
- primary animal-level temporal summaries

The retained Batch 4 updated-statistics runner implements the final animal-level sign-flip based summary framework used for the main displayed temporal comparisons.

It depends on earlier HC31 CSV outputs rather than reading every raw data stream independently.

---

## 3.4 Movement and rate-speed analyses

**Status: A - Direct retained implementation**

Primary retained code:

- `analysis/01_primary_beta/speedcorr.m`

Main manuscript links:

- Figure 6
- Figure 9A
- descriptive movement summaries

The script uses hc-31 behavioural data together with retained beta-event rate outputs.

---

# 4. Novelty and spatial analyses

## 4.1 Novel-versus-familiar rate summaries

**Status: A/C - Direct displayed summaries, partial final inferential lineage**

Primary retained code:

- `analysis/01_primary_beta/nfbeta.m`
- `analysis/01_primary_beta/hc31_batch4_novelty_statistics.m`
- `analysis/02_final_temporal_spatial_stats/run_b4_updated_stats.m`

Main manuscript link:

- Figure 8

The retained scripts directly support the displayed novel/familiar rate summaries and animal-level comparisons.

However, not every final manuscript sensitivity calculation exists as a standalone retained script.

---

## 4.2 Entry-novelty sensitivity

**Status: A - Direct retained implementation**

Primary retained code:

- `analysis/01_primary_beta/hc31_entry_novelty_sensitivity_PLAIN_SCRIPT.m`

This script contains the retained early-entry novelty sensitivity workflow used to examine 30 s, 60 s, 120 s, first-visit and traversal-style novelty definitions.

---

## 4.3 Final 2,000,000-draw circular-shift novelty test

**Status: D - Final standalone code not retained**

The final manuscript describes a cluster-preserving procedure in which each animal-by-interval event train is circularly shifted by a uniformly distributed moving-exposure offset, with two million Monte Carlo draws used to form the animal-balanced null distribution.

No standalone B1-B4 script implementing this exact final two-million-draw procedure was identified.

Closest retained code:

- `analysis/01_primary_beta/hc31_batch4_novelty_statistics.m`

That script contains an earlier related occupancy-preserving/permutation implementation and should not be presented as exact code for the final p=0.0571 calculation.

### Public reproducibility implication

The included `derived_data/` package provides compact manuscript-facing summaries including:
- the observed novelty contrast;
- the final null-summary output where available;
- the reported p value;
- enough audit metadata to verify the manuscript result.

If a clean final implementation is later reconstructed, it should be added as a clearly new reproduction script rather than silently replacing the retained historical source.

---

## 4.4 Held-out-animal high-rate-location overlap test

**Status: D - Final standalone code not retained**

The final manuscript describes a held-out-animal procedure using:
- highest-tenth and highest-quarter spatial definitions;
- hypergeometric null distributions conditional on available and selected bins;
- convolution of 20 held-out profile distributions to obtain exact overall p values.

No exact standalone B1-B4 script for this final procedure was identified.

Closest retained spatial code:

- `analysis/01_primary_beta/hc31_batch2_burst_frequency_heatmaps.m`
- `analysis/01_primary_beta/hc31_batch4_novelty_statistics.m`

These scripts preserve upstream spatial binning and novelty-analysis lineage but do not reproduce the final held-out exact test as described in the frozen manuscript.

---

## 4.5 Spatial occupancy map

**Status: A - Direct retained implementation**

Primary retained code:

- `analysis/01_primary_beta/hc31_batch2_burst_frequency_heatmaps.m`

Main manuscript link:

- Figure 9B

---

# 5. Spectral analyses

## 5.1 Relative spectral shape and frequency maxima

**Status: A/E - Retained implementation available, historical estimator identity unrecovered**

Primary retained code:

- `analysis/03_spectral/psdspec_fixed_groupmean.m`
- `analysis/03_spectral/batch5_force/run_b5_force.m`
- helpers in `analysis/03_spectral/batch5_force/`

Main manuscript links:

- Figure 10
- Figure 11

The retained code provides the available HC31 spectral implementation and the final Batch 5 analysis lineage used for the manuscript spectral comparisons.

### Historical limitation

The exact estimator that generated the original saved individual spectra could not be recovered from the project history.

The manuscript therefore does not claim that one retained implementation is definitively the historical estimator.

This is an **E - Historical implementation detail unrecovered** limitation.

---

## 5.2 Run1 spectrogram and line-noise checks

**Status: A - Direct retained implementation**

Primary retained code:

- `analysis/03_spectral/batch6_force/run_b6_force.m`
- helpers in `analysis/03_spectral/batch6_force/`

Main manuscript link:

- Figure 12

The retained Batch 6 pipeline contains the Run1 spectrogram and related recording-quality checks.

---

# 6. Detector-defined beta-event neuronal analyses

## 6.1 Mean firing, active-unit fraction and event-control analysis

**Status: C - Closest retained implementation, exact final implementation not preserved**

Primary retained code:

- `analysis/04_neuronal_beta/batch8_force/run_b8_force.m`
- helpers in `analysis/04_neuronal_beta/batch8_force/`

Main manuscript link:

- Figure 13

Batch 8 is the closest retained source pipeline for:
- event-control firing;
- participation;
- unit and field summaries;
- animal-level aggregation.

However, the archived Batch 8 control procedure does not exactly match the final manuscript description of:
- 200 candidate controls per event;
- nearest-speed-control selection;
- the exact final retained control handling.

Archived Batch 8 summary values are also not numerically identical to all final Figure 13 values.

Therefore, Batch 8 should be treated as the source lineage, not as an exact raw-data reproduction of the final Figure 13 table.

### Public reproducibility implication

The included `derived_data/04_neuronal_beta/figure13_statistics.csv` provides the final manuscript-facing Figure 13 values and table-source summary.

A clean standalone implementation of the frozen Methods would improve full raw-data reproducibility if created later.

---

## 6.2 Peri-event firing and phase concentration

**Status: A - Direct retained implementation**

Primary retained code:

- `analysis/04_neuronal_beta/hc31_batch11C_PETH_phase_locking_PLAIN_SCRIPT.m`

Main manuscript link:

- Figure 14
- peri-event and phase-locking analyses

The retained Batch 11C script is the direct code lineage for the phase/PETH branch.

The frozen manuscript contains additional clarified descriptions of recording-level phase summaries and cross-recording directional agreement. Users should treat the manuscript Methods as the authoritative final statistical description.

---

## 6.3 Field-linked firing and annotation-opportunity diagnostics

**Status: A/C - Core field analysis retained; some final audit diagnostics were added later**

Core retained code:

- Batch 8 field functions in `analysis/04_neuronal_beta/batch8_force/`
- `analysis/04_neuronal_beta/hc31_batch11C_PETH_phase_locking_PLAIN_SCRIPT.m`

The field-linked analysis lineage is retained.

Some final manuscript diagnostics concerning baseline firing-rate quartiles and repeated field-detection counts were clarified during the final audit/reconstruction stage and may not exist as a dedicated standalone retained B1-B4 script.

These should be verified through the final derived-data tables.

---

# 7. High-frequency candidate screening

## 7.1 Candidate generation, waveform QC and tier construction

**Status: A - Direct retained pipeline components**

Primary retained code includes:

- `analysis/05_high_frequency_candidates/batch9_force/run_b9_force.m`
- `analysis/05_high_frequency_candidates/batch10_force_v2/run_b10_force.m`
- `analysis/05_high_frequency_candidates/hc31_batch11K_candidate_ripple_manual_QC_PLAIN_SCRIPT_FIXED.m`
- `analysis/05_high_frequency_candidates/hc31_batch11K_unblind_reviews_PLAIN_SCRIPT.m`
- `analysis/05_high_frequency_candidates/hc31_batch11L2_event_separation_non_circular_morphology_PARENT_WINDOW_FIXED.m`
- `analysis/05_high_frequency_candidates/hc31_batch11M3_corrected_pre_rest_post_state_classification_PLAIN_SCRIPT.m`
- scripts in `analysis/05_high_frequency_candidates/batch11Nplus/`

Main manuscript links:

- Figure 15
- master candidate populations feeding later analyses

The retained source covers:
- candidate detection;
- waveform/manual-review generation;
- unblinding;
- morphology/rule evaluation;
- operational state classification;
- final master-event/tier construction.

---

## 7.2 Ridge-regularised 64-clear-label screening model

**Status: D - Final standalone code not retained**

The frozen manuscript reports a ridge-regularised model trained on the 64 clear labels from the 225-candidate evaluation set.

No standalone B1-B4 script implementing that exact final ridge-model analysis was identified.

The retained Batch 11L2 code represents the morphology/rule-screening branch, not the missing final ridge model.

### Public reproducibility implication

The included `derived_data/` package includes or should be read alongside:
- the 225-candidate evaluation table if redistribution is appropriate;
- clear/ambiguous labels as allowed;
- model-input features used in the manuscript;
- final held-out predictions or summary metrics where available.

A new clean implementation may be added later only if it is reconstructed directly from the frozen manuscript definition and retained inputs.

---

# 8. Screened-candidate firing analyses

## 8.1 Run1 traversal 50-seed matched-control firing analysis

**Status: D - Final standalone code not retained**

Main manuscript link:

- Figure 16
- +0.532 Hz/unit Run1 traversal result

No standalone B1-B4 script was identified that exactly implements the final manuscript calculation using:
- 542 Tier A+C Run1 traversal candidates;
- 50 fixed control selections;
- five distinct controls per event where available;
- the final animal-equal aggregation;
- the reported +0.532 Hz/unit result.

Closest retained source lineage:

- `analysis/05_high_frequency_candidates/batch11Nplus/`
- `analysis/06_candidate_firing_amplitude/batch11O/hc31_batch11O_population_recruitment_and_state_rates_PLAIN_SCRIPT.m`

These preserve the candidate populations and closely related population-recruitment analysis but should not be described as the exact final Figure 16 calculation.

---

## 8.2 PRE, gap and traversal-plus-gap candidate firing comparisons

**Status: C/B - Related retained analysis and final summaries depend on retained outputs**

Primary retained lineage:

- `analysis/06_candidate_firing_amplitude/batch11O/hc31_batch11O_population_recruitment_and_state_rates_PLAIN_SCRIPT.m`
- `analysis/06_candidate_firing_amplitude/batch11P_synthesis/hc31_batch11P_final_synthesis_from_CSVs_PLAIN_SCRIPT.m`

Batch 11P is a synthesis script that regenerates summary tables and figures from canonical CSV outputs rather than raw CSC data.

The current `derived_data/` package provides manuscript-facing summaries, while raw-data regeneration still depends on retained canonical/intermediate outputs that are not all redistributed.

---

# 9. Candidate-centred beta2 amplitude

## 9.1 Movement-matched Stage B analysis

**Status: A/B - Direct code lineage, some stages require retained intermediates**

Primary retained code:

- `analysis/06_candidate_firing_amplitude/batch11O/hc31_batch11O_awake_beta2_speed_matched_PLAIN_SCRIPT.m`

This is the direct Stage B movement-matched candidate/control beta2-envelope analysis.

It reads raw CSC data and generates pair-level outputs and checkpoint material.

---

## 9.2 Final Stage B QC correction

**Status: B - Direct from retained intermediate outputs**

Primary retained code:

- `analysis/06_candidate_firing_amplitude/stageB_QC_correction/hc31_batch11O_apply_stageB_QC_correction_PLAIN_SCRIPT_NO_STRLENGTH.m`

Main manuscript links:

- Figure 17
- Figure 18
- 742 -> 542 -> 536 -> 257-pair chain

This script reads the completed Stage B pair CSV and checkpoint MAT, removes the specified failed movement matches/control segments, and rebuilds the corrected summaries and time courses.

It does not start from the original raw hc-31 data by itself.

### Public reproducibility implication

The included derived-data package provides corrected manuscript-facing PETH and summary/statistical tables for Figures 17-18. Full Stage B regeneration still requires retained intermediate inputs not all redistributed here.

---

## 9.3 Batch 11P synthesis

**Status: B - Direct from canonical CSVs**

Primary retained code:

- `analysis/06_candidate_firing_amplitude/batch11P_synthesis/hc31_batch11P_final_synthesis_from_CSVs_PLAIN_SCRIPT.m`

This script explicitly regenerates final summary tables and report figures from completed canonical CSV outputs.

It is useful for manuscript-level verification once those CSV files are distributed.

---

# 10. Spike-order analyses

## 10.1 Original spatial ordering and shuffle-controlled example

**Status: A - Direct retained implementation**

Primary retained code:

- `analysis/07_spike_order/hc31_batch11F_replay_sorted_rasters_PLAIN_SCRIPT.m`
- `analysis/07_spike_order/hc31_batch11I_shuffle_controlled_replay_sequences_PLAIN_SCRIPT.m`

Main manuscript links:

- Figure 19
- original-order row of Figure 20

These scripts preserve the original median-Run1-spike-position ordering and its event-specific shuffle analysis.

### Historical limitation

The original saved random seed could not be recovered.

The manuscript therefore retains the original saved statistics rather than claiming an exact rerandomisation of the historical result.

---

## 10.2 Quality-filtered and field-based alternative orderings

**Status: D - Final standalone code not retained**

Main manuscript link:

- remaining rows of Figure 20

Standalone B1-B4 scripts were not identified for the later recalculated orderings:

- source-quality-filtered spike-position order;
- median accepted-field position;
- dominant repeat-cluster centre.

The manuscript Methods describes the final definitions and Figure 20 reports the resulting counts and corrected statistics, but the exact final recalculation scripts were not preserved in B1-B4.

### Public reproducibility implication

The included `derived_data/08_spike_order/figure20_summary.csv` provides the final manuscript-facing four-ordering summary. Exact raw-data recalculation scripts remain unavailable for three later orderings.

If clean recalculation scripts are reconstructed later, they should be added as new reproducibility scripts with provenance clearly distinguished from the archived historical code.

---

# 11. Manuscript figure reproducibility summary

| Manuscript item | Current status | Main retained source |
|---|---|---|
| Figure 1 | Not generated by HC31 | Source-study image |
| Figure 2 | A | `plotburstlocs.m` |
| Figure 3A | A | Batch 11A event trace QC |
| Figure 3B | A | beta/beta2 extraction script |
| Figure 4 | A | Batch 4 updated-statistics runner |
| Figure 5 | A | Batch 4 updated-statistics runner |
| Figure 6 | A | `speedcorr.m` |
| Figure 7 | A | beta/beta2 extraction + Run1 plotting |
| Figure 8 | A for displayed summary, D for final shift/held-out sensitivity code | `nfbeta.m`, Batch 4 |
| Figure 9A | A | `speedcorr.m`, Batch 4 |
| Figure 9B | A | Batch 2 heatmap script |
| Figure 10 | A/E | retained spectral implementation |
| Figure 11 | A/E | Batch 5 retained implementation |
| Figure 12 | A | Batch 6 |
| Figure 13 | C | Batch 8 closest source |
| Figure 14 | A | Batch 11C |
| Figure 15 | A for waveform QC, D for final ridge model | Batch 11K/L2/N+ lineage |
| Figure 16 | D | upstream N+ and Batch 11O lineage retained |
| Figure 17 | A/B | Batch 11O Stage B + corrected QC |
| Figure 18 | B | corrected Stage B outputs |
| Figure 19 | A | Batch 11F -> 11I |
| Figure 20 | A for original ordering, D for three later orderings | Batch 11I + retained final outputs |

---

# 12. Included derived-data package

The repository includes a compact `derived_data/` package for manuscript-level inspection and verification when exact standalone raw-data scripts were not preserved.

It contains machine-readable summaries for:

## Primary beta/beta2
- animal-level first-half and second-half rates;
- temporal slopes and time-course values;
- novel/familiar animal-level and stage-level rates;
- movement summaries;
- final held-out spatial summary outputs.

## Spectral
- per-animal theta, broad-beta and beta2 peak-frequency summaries;
- line-noise QC summaries used in the manuscript.

## Detector-defined neuronal analyses
- final Figure 13 statistics;
- phase-unit and recording-level summaries;
- field-annotation summaries.

## High-frequency screening
- final reviewed-label counts;
- screening evaluation summary;
- manuscript Tier A+C population summaries.

## Candidate firing
- Figure 16 per-animal event/control firing table;
- PRE, gap, and traversal-plus-gap manuscript-facing summaries.

## Candidate-centred beta2 amplitude
- corrected Figure 17 PETH source data;
- Figure 18 animal-level effects and statistics;
- amplitude attrition summary.

## Spike order
- Figure 19 example-event output;
- Figure 20 four-ordering summary table.

See `derived_data/DATA_DICTIONARY.csv` for file-level provenance classes. The derived-data package does not contain the original raw CRCNS recordings.

---

# 13. What can be claimed publicly

With the current curated code and derived-data package, the repository can accurately state:

> This repository contains curated retained MATLAB source code and compact manuscript-facing derived data for the HC31 analysis, and documents which analyses are directly rerunnable, depend on retained intermediate outputs, or lack a preserved final standalone implementation.

It should **not yet** claim:

> All manuscript results can be reproduced from raw hc-31 data by running the scripts in this repository.

That stronger statement is not supported by the retained B1-B4 material.

Once derived data, environment documentation, and any clean missing reproduction scripts are added and tested, the repository statement can be updated accordingly.

---

# 14. Known historical limitations that should remain explicit

The following should continue to be reported rather than guessed:

- exact Balanced L2 threshold combination;
- exact Run1 low-speed Tier C/D criterion;
- identity of the historical saved individual-spectrum estimator;
- state-classification spectral estimator;
- physical voltage calibration for archived amplitude labels;
- original spike-order random seed;
- exact upstream selection rule for the archived 931-window spike-order set.

These limitations do not invalidate the retained analyses, but they prevent a claim of complete one-command historical reproduction.

---

# 15. Recommended next reproducibility tasks

Before the repository is made public:

1. Test representative status-A scripts with `HC31_DATA_ROOT` on a clean MATLAB path.
2. Test status-B scripts against the retained/intermediate inputs intended for release.
3. Decide whether to create new clean reproduction scripts for status-D analyses.
4. Select a repository licence.
5. Tag the tested manuscript-associated repository release.
6. Archive that release with a persistent DOI.
7. Update `CITATION.cff` with version, release date, licence, and DOI.

No new script should be represented as historical source code if it was reconstructed after manuscript freeze. New reproduction wrappers should be clearly labelled as such.
