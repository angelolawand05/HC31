# HC31

MATLAB analysis code, compact derived data, and provenance documentation for a secondary analysis of the CRCNS hc-31 dataset examining hippocampal beta2 events during exploration of an expanding environment.

## Manuscript

**Temporal changes in hippocampal beta2 events during exploration of an expanding environment**

This repository supports the analysis reported in the accompanying manuscript. The study reanalyses publicly available dorsal CA1 recordings from five rats exploring a progressively expanding linear track.

The central analyses examine:

- changes in beta2 (23-30 Hz) event rates over the first exploration session (Run1);
- broad-beta (13-30 Hz) and beta2 event populations;
- novel-versus-familiar spatial comparisons;
- spectral structure and the relationship of beta2-band activity to theta harmonics;
- neuronal firing, active-unit fraction, phase concentration, and field-linked firing during beta events;
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
|-- README.md
|-- CITATION.cff
|-- LICENSE
|-- .gitattributes
|-- .gitignore
|-- analysis/
|   |-- 01_primary_beta/
|   |-- 02_final_temporal_spatial_stats/
|   |-- 03_spectral/
|   |-- 04_neuronal_beta/
|   |-- 05_high_frequency_candidates/
|   |-- 06_candidate_firing_amplitude/
|   `-- 07_spike_order/
|-- derived_data/
|   |-- 01_temporal_beta/
|   |-- 02_novelty_spatial/
|   |-- 03_spectral/
|   |-- 04_neuronal_beta/
|   |-- 05_candidate_screening/
|   |-- 06_candidate_firing/
|   |-- 07_amplitude/
|   `-- 08_spike_order/
|-- docs/
|   |-- FIGURE_SCRIPT_MAP.md
|   |-- MANIFEST.csv
|   |-- README_CURATED_SCRIPTS.md
|   |-- EXCLUDED_SUMMARY.md
|   `-- REPRODUCIBILITY.md
`-- environment/
    `-- MATLAB_REQUIREMENTS.m
```

## Analysis code

The `analysis/` directory contains the curated MATLAB source relevant to the frozen scientific manuscript.

### `analysis/01_primary_beta`

Core beta/beta2 detection and early analyses, including event time courses, novelty/location analyses, movement relationships, entry-novelty sensitivity, spatial summaries, and trace-quality checks.

### `analysis/02_final_temporal_spatial_stats`

Final animal-level temporal and spatial summary analyses used for the principal beta2/broad-beta statistical comparisons.

### `analysis/03_spectral`

Spectral analyses used to examine theta, broad-beta, and beta2 frequency structure and spectrogram-based context.

### `analysis/04_neuronal_beta`

Analyses of neuronal firing, active-unit fraction, phase concentration, and place-field-linked firing during detector-defined beta events.

### `analysis/05_high_frequency_candidates`

High-frequency candidate detection, screening, state classification, quality-control, and tier-assignment pipelines.

### `analysis/06_candidate_firing_amplitude`

Candidate-centred firing and beta2-envelope analyses, including matched-control and sustained-immobility analyses.

### `analysis/07_spike_order`

Spike-order analyses using several spatial-ordering definitions, including the archived/original ordering and later alternative-ordering lineage where retained source code is available.

## Derived data

The `derived_data/` directory contains compact manuscript-facing CSV files that allow readers to inspect the reported numerical results without downloading the large raw CRCNS dataset.

It includes temporal, novelty/spatial, spectral, neuronal, candidate-screening, candidate-firing, amplitude, and spike-order summaries.

See:

- `derived_data/README.md`
- `derived_data/DATA_DICTIONARY.csv`
- `derived_data/MANIFEST.csv`

The raw Neuralynx recordings and source `resSave.mat` file are not redistributed.

## Documentation

- `docs/FIGURE_SCRIPT_MAP.md` maps manuscript figures/results to retained code.
- `docs/MANIFEST.csv` records current repository paths, source-archive provenance, and both archive/current hashes where relevant.
- `docs/README_CURATED_SCRIPTS.md` describes how the code set was selected.
- `docs/EXCLUDED_SUMMARY.md` records categories deliberately omitted from the public-facing repository.
- `docs/REPRODUCIBILITY.md` states which analyses are directly rerunnable, depend on retained intermediate outputs, or lack a preserved final standalone implementation.
- `environment/MATLAB_REQUIREMENTS.m` documents dependencies and provides a lightweight local environment check.

## Data-root configuration

The retained MATLAB scripts were originally developed with local Windows paths. For repository portability, active personal paths have been replaced with the environment variable:

`HC31_DATA_ROOT`

Set it in MATLAB before running a module, for example:

```matlab
setenv('HC31_DATA_ROOT', 'D:\path\to\hc31')
```

If `HC31_DATA_ROOT` is not set or does not point to an existing folder, patched entry scripts prompt the user to select the hc-31 project/data root.

These are path-only portability edits. They do not change the scientific analysis logic.

## Important MATLAB path rule

Do **not** add the entire `analysis/` tree recursively to the MATLAB path.

Several modules contain helper functions with the same filenames but different module-specific implementations. Run a module from its own folder, or add only that module and its intended helper folder to the MATLAB path.

## Reproducibility status

The repository preserves the principal retained HC31 analysis code and includes compact derived data for manuscript-level verification.

However, the project is a retrospective reconstruction of a multi-stage analysis history. Some final manuscript calculations were reconstructed from retained outputs and later audit/reanalysis steps rather than from a single preserved standalone script.

Known historical limitations include:

- the exact threshold combination underlying the archived **Balanced L2** screen;
- the exact Run1 low-speed criterion used in one historical candidate-tier assignment;
- the exact saved spectral estimator used for some archived spectra;
- the spectral estimator used for one state-classification branch;
- physical voltage calibration for some archived amplitude labels;
- the original random seed for the archived spike-order analysis;
- the exact upstream selection rule defining the archived 931-window spike-order starting set.

See `docs/REPRODUCIBILITY.md` for analysis-by-analysis status.

## Software requirements

The analyses were performed in MATLAB.

A practical compatibility target is MATLAB R2020a or newer. The curated code uses functions from:

- Signal Processing Toolbox;
- Statistics and Machine Learning Toolbox.

Some branches additionally require:

- Neuralynx MATLAB import utilities, including `Nlx2MatCSC`;
- Chronux for retained spectral implementations that call Chronux functions.

These third-party dependencies are not redistributed here.

Run `environment/MATLAB_REQUIREMENTS.m` for a lightweight local dependency check.

## Running the analysis

This repository is not a single one-command pipeline.

Before running a module:

1. Download the CRCNS hc-31 dataset separately.
2. Set `HC31_DATA_ROOT` or allow the script to prompt for the data root.
3. Run one analysis module at a time rather than recursively adding all of `analysis/` to the MATLAB path.
4. Inspect the script header for expected upstream inputs.
5. Consult `docs/FIGURE_SCRIPT_MAP.md` and `docs/REPRODUCIBILITY.md`.
6. Use the manuscript Methods as the authoritative description of the frozen analysis.

## Data availability

The original hc-31 recordings are available from CRCNS at:

https://doi.org/10.6080/K0BV7DT2

Compact derived data underlying manuscript-facing analyses are included under `derived_data/`.

The original CRCNS recordings are not redistributed.

## Ethics

This project is a secondary analysis of previously collected, publicly available electrophysiological data. No new animals were used and no new experimental procedures were performed. Ethical oversight of the original animal experiments is described in the source study.

## Citation

If using the original electrophysiological recordings, please cite the hc-31 dataset and the original source study according to CRCNS guidance.

Citation metadata are provided in `CITATION.cff`.

## Contact

For questions about this analysis repository, please use the GitHub Issues page.
