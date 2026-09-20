# HC31 pre-release checklist

This checklist records the remaining repository tasks before the public v1.0.0 release.

## Completed

- Curated manuscript-relevant MATLAB code included under `analysis/`.
- Compact manuscript-facing derived data included under `derived_data/`.
- Code provenance manifest included.
- Derived-data manifest included.
- Reproducibility status documented.
- MATLAB/toolbox requirements documented.
- Active personal Windows data-root paths removed from entry scripts.
- Raw CRCNS hc-31 recordings excluded.
- Third-party Chronux and Neuralynx source code excluded.
- `CITATION.cff` present.
- `.gitignore` protects principal raw-data file types and local archive bundles.

## Remaining before public v1.0.0

1. **Choose a repository licence.** This is an author decision and is intentionally not selected automatically. A permissive research-code licence such as MIT or BSD-3-Clause is commonly used, but the final choice belongs to the repository author.
2. Run a clean-machine or clean-MATLAB-path smoke test on representative status-A modules.
3. Re-run the static repository QA after any final changes.
4. Make the repository public when ready.
5. Create GitHub release `v1.0.0`.
6. Archive the release with Zenodo and obtain a DOI.
7. Update `CITATION.cff` with the final version, release date, licence, and Zenodo DOI.
8. Add the final code and data availability links/DOI to the manuscript.

## Licence note

No `LICENSE` file is included in this release candidate because the licence is a legal/reuse choice for the author. Do not make the repository public as the final release until this has been decided.
