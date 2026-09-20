# HC31 repository QA fixes applied

This release-candidate package applies the mechanical fixes identified in the final static repository QA.

## Portability fixes

- Removed active personal Windows root paths from curated entry scripts.
- Added support for the `HC31_DATA_ROOT` MATLAB environment variable.
- Added an interactive root-folder fallback where the historical scripts already had or required one.
- Replaced personal root paths in script comments with generic `<HC31_DATA_ROOT>` examples.
- Preserved the scientific calculations and analysis parameters.

These are path-only portability edits. `docs/MANIFEST.csv` retains both the original archive hash and the current repository hash so modified files remain auditable.

## Repository protection

`.gitignore` now explicitly excludes:

- `*.ncs` Neuralynx recordings;
- `resSave.mat`;
- `csc_files/`;
- `neuralynximport/`;
- B1-B4 archive ZIP files;
- common temporary and generated-output folders.

## Documentation fixes

- Updated the top-level README to include `derived_data/`, `environment/`, `CITATION.cff`, and current documentation.
- Updated `docs/REPRODUCIBILITY.md` to reflect that the derived-data package is now present.
- Updated `docs/README_CURATED_SCRIPTS.md` to describe the path-only portability edits.
- Updated `docs/FIGURE_SCRIPT_MAP.md` to use full repository-relative `analysis/...` paths.
- Added a warning not to recursively add the entire `analysis/` tree to the MATLAB path because some modules contain same-named helper functions with different implementations.
- Normalized repository-authored Markdown documentation to ordinary hyphens rather than en/em dashes.

## Manifest fixes

- Regenerated `derived_data/MANIFEST.csv` after Git line-ending normalization.
- Updated `docs/MANIFEST.csv` to include:
  - full repository paths;
  - original source-archive SHA-256 values;
  - current repository SHA-256 values;
  - a `portability_modified` flag.

## Remaining author decision

No `LICENSE` file is included because licence selection is an author decision.

Choose the licence before the final public v1.0.0 release, then update `CITATION.cff` with the selected licence together with the final version, release date, and Zenodo DOI.
