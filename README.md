# HC31

MATLAB analysis code and supporting provenance documentation for a secondary analysis of the CRCNS hc-31 dataset examining hippocampal beta2 events during exploration of an expanding environment.

## Manuscript

**Temporal changes in hippocampal beta2 events during exploration of an expanding environment**

This repository supports the analysis reported in the accompanying manuscript. The study reanalyses publicly available dorsal CA1 recordings from five rats exploring a progressively expanding linear track.

The central analyses examine:

- changes in beta2 (23-30 Hz) event rates over the first exploration session (Run1);
- broad-beta (13-30 Hz) and beta2 event populations;
- novel-versus-familiar spatial comparisons;
- spectral structure and the relationship of beta2-band activity to theta harmonics;
- neuronal firing, active-unit fraction, phase concentration and field-linked firing during beta events;
- screened high-frequency candidate events;
- candidate-centred beta2 amplitude;
- spike-order analyses relevant to replay.

The manuscript deliberately distinguishes detector-defined events from claims about physiological generators, and screened high-frequency candidates from validated sharp-wave ripples.

## Source dataset

The original electrophysiological recordings are **not redistributed in this repository**.

They are publicly available from CRCNS:

**Rich D, Liaw HP, Lee AK. Extracellular CA1 activity from rats during exploration of a novel 48 m track. CRCNS.org; 2022.**  
DOI: https://doi.org/10.6080/K0BV7DT2

Dataset: **hc-31**

Users should obtain the original data directly from CRCNS and comply with the dataset's access and citation conditions.

## Repository structure

```text
HC31/
├── README.md
├── .gitattributes
├── .gitignore
├── analysis/
│   ├── 01_primary_beta/
│   ├── 02_final_temporal_spatial_stats/
│   ├── 03_spectral/
│   ├── 04_neuronal_beta/
│   ├── 05_high_frequency_candidates/
│   ├── 06_candidate_firing_amplitude/
│   └── 07_spike_order/
└── docs/
    ├── FIGURE_SCRIPT_MAP.md
    ├── MANIFEST.csv
    ├── README_CURATED_SCRIPTS.md
    └── EXCLUDED_SUMMARY.md
```

### `analysis/01_primary_beta`

Core beta/beta2 detection and early analyses, including event time courses, novelty/location analyses, movement relationships and trace-quality checks.

### `analysis/02_final_temporal_spatial_stats`

Final animal-level temporal and spatial summary analyses used for the principal beta2/broad-beta statistical comparisons.

### `analysis/03_spectral`

Spectral analyses used to examine theta, broad-beta and beta2 frequency structure and spectrogram-based context.

### `analysis/04_neuronal_beta`

Analyses of neuronal firing, active-unit fraction, phase concentration and place-field-linked firing during detector-defined beta events.

### `analysis/05_high_frequency_candidates`

High-frequency candidate detection, screening, state classification, quality-control and tier-assignment pipelines.

### `analysis/06_candidate_firing_amplitude`

Candidate-centred firing and beta2-envelope analyses, including matched-control and sustained-immobility analyses.

### `analysis/07_spike_order`

Spike-order analyses using several spatial ordering definitions, including the archived/original ordering and later alternative orderings where retained source code is available.

### `docs/`

Repository-level provenance and mapping documentation.

- `FIGURE_SCRIPT_MAP.md` maps manuscript figures/results to retained scripts where identifiable.
- `MANIFEST.csv` lists curated files with source-archive provenance and hashes.
- `README_CURATED_SCRIPTS.md` describes the code-selection process.
- `EXCLUDED_SUMMARY.md` records categories of files deliberately omitted from the public-facing code package.

## Code provenance

The analysis developed over multiple stages. This repository contains the **curated scripts relevant to the final manuscript**, rather than every exploratory, test, backup or superseded file generated during development.

Where multiple versions of a script existed, the latest corrected or final version relevant to the manuscript was retained where identifiable.

The following are intentionally excluded:

- raw CRCNS hc-31 recordings;
- generated figures and bulk result folders;
- temporary/intermediate files;
- obsolete or superseded script versions;
- development/test scripts not required for the final manuscript;
- bundled copies of third-party software where redistribution is unnecessary;
- unrelated reference code.

See `docs/EXCLUDED_SUMMARY.md` and `docs/MANIFEST.csv` for details.

## Reproducibility status

The repository preserves the principal analysis code used during the HC31 project, but the project is a retrospective reconstruction of a multi-stage analysis history.

Several historical details could not be fully recovered and are reported transparently in the manuscript, including:

- the exact threshold combination underlying the archived **Balanced L2** screen;
- the exact Run1 low-speed criterion used in one historical candidate-tier assignment;
- the exact saved spectral estimator used for some archived spectra;
- the spectral estimator used for one state-classification branch;
- physical voltage calibration for some archived amplitude labels;
- the original random seed for the archived spike-order analysis;
- the exact upstream selection rule defining the archived 931-window spike-order starting set.

Some final manuscript results were reconstructed from retained outputs and later audit/reanalysis steps rather than from a single standalone script preserved in B1-B4.

Accordingly, this repository should be read together with:

- `docs/FIGURE_SCRIPT_MAP.md`
- `docs/MANIFEST.csv`
- the Methods section of the manuscript

A dedicated `REPRODUCIBILITY.md` and a compact derived-data package will be added before the public release associated with the manuscript.

## Software requirements

The analyses were performed in MATLAB.

Exact MATLAB release/toolbox requirements vary across analysis branches and are being consolidated before public release.

Some spectral analyses used or referenced **Chronux**. Chronux source code is not redistributed here; users should obtain it from its official distribution if needed.

The raw-data loading workflow also relies on Neuralynx-compatible import utilities for `.ncs` recordings. These third-party utilities are not redistributed in this repository unless their licences explicitly permit it.

## Running the analysis

This repository is not yet intended to function as a single one-command pipeline.

The analysis folders preserve the final relevant modules from the original project history. Before attempting to run a module:

1. Download the CRCNS hc-31 dataset separately.
2. Inspect the script header for required input files and directory expectations.
3. Consult `docs/FIGURE_SCRIPT_MAP.md` for the relationship between scripts and manuscript outputs.
4. Consult `docs/MANIFEST.csv` for file provenance.
5. Use the manuscript Methods as the authoritative description of the final statistical and analytical procedures.

A simplified execution guide will be added before public release.

## Data availability

The original hc-31 recordings are available from CRCNS at:

https://doi.org/10.6080/K0BV7DT2

A compact set of derived data underlying the manuscript figures, tables and summary statistics will be added to this repository or an associated archival deposit before publication.

The original CRCNS recordings will not be redistributed.

## Ethics

This project is a secondary analysis of previously collected, publicly available electrophysiological data. No new animals were used and no new experimental procedures were performed. Ethical oversight of the original animal experiments is described in the source study.

## Citation

If using the original electrophysiological recordings, please cite the hc-31 dataset and the original source study according to CRCNS guidance.

Citation information for this analysis repository will be added before public release together with the final manuscript citation and archived release DOI.

## Repository status

**Private development repository - pre-release.**

The scientific manuscript has reached content freeze. Repository documentation, derived-data packaging, dependency documentation and archival release preparation are still in progress.

## Contact

For questions about this analysis repository, please use the GitHub Issues page once the repository is public.
