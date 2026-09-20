# HC31 derived data

This folder contains a compact set of manuscript-facing derived data for the HC31 study.

It is designed to let readers inspect the values underlying the reported analyses without downloading or redistributing the large raw CRCNS hc-31 Neuralynx dataset.

## What is included

The package contains:

- animal-level Run1 beta2 and broad-beta time-course and temporal summaries;
- novelty and spatial summary tables;
- spectral peak-frequency and line-noise quality-control summaries;
- final Figure 13 neuronal statistics;
- phase-locking and field-annotation summaries;
- screened-candidate label and evaluation summaries;
- Figure 16 candidate-firing values;
- corrected Figures 17-18 amplitude source data and statistics;
- Figure 19 example data and Figure 20 spike-order summary values.

## What is not included

This folder does not contain:

- raw Neuralynx recordings;
- the original CRCNS hc-31 dataset;
- bulk intermediate outputs;
- every exploratory CSV generated during development;
- generated manuscript figures;
- obsolete or superseded analysis outputs.

The source recordings remain available from CRCNS:

https://doi.org/10.6080/K0BV7DT2

## Provenance classes

Files in this package use one of three provenance classes.

### retained_output

Copied directly, or filtered without changing numerical values, from a retained B1-B4 analysis output that matches the manuscript use.

### retained_output_derived

A compact subset or simple aggregation made from a retained B1-B4 output. The transformation is limited to row selection, column selection, or counting.

### frozen_manuscript_summary

A compact table assembled from the scientifically frozen manuscript where the exact final standalone output file was not preserved in B1-B4, or where an older archived output was superseded by the final audited manuscript value.

This distinction is intentional. It prevents older archived intermediate results from being presented as if they were the final manuscript statistics.

## Important reproducibility note

These derived files support inspection and manuscript-level verification. They do not imply that every final result can currently be regenerated from raw hc-31 data by one retained standalone script.

See:

- `docs/REPRODUCIBILITY.md`
- `docs/FIGURE_SCRIPT_MAP.md`
- `docs/MANIFEST.csv`

for the code-level reproducibility status.

## Folder guide

- `01_temporal_beta`: Run1 60 s time courses and animal/group temporal summaries.
- `02_novelty_spatial`: novel/familiar rates, stage summaries, final novelty inference and held-out spatial summaries.
- `03_spectral`: per-animal peak-frequency and line-noise summaries.
- `04_neuronal_beta`: Figure 13, phase and field-annotation summaries.
- `05_candidate_screening`: final reviewed-label counts, screening metrics and manuscript tier counts.
- `06_candidate_firing`: Figure 16 and context-level firing summaries.
- `07_amplitude`: corrected Figure 17 PETH, Figure 18 animal effects/statistics and attrition.
- `08_spike_order`: Figure 19 example row and Figure 20 summary.

`DATA_DICTIONARY.csv` identifies the manuscript role and provenance of every data file.
`MANIFEST.csv` provides file sizes and SHA-256 hashes.

