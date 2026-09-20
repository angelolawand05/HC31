# Deliberately excluded from the curated code package

The following were inspected but excluded because they are not needed for the final manuscript code base or are superseded/reference material:

- All PNG/JPG/FIG/PDF/DOCX outputs.
- Bulk historical analysis-result CSVs and MAT checkpoints not required for the compact manuscript-facing derived-data package.
- B1 bundled Chronux tree.
- B1 Neuralynx import/export tree.
- B1 “Code from Walsh et al.” reference scripts.
- Generic tests/examples/backups (`test_*`, `example_*`, `*_backup_*`, `b1.m`…`b10.m`, etc.).
- Batch 4 V2 parametric/t-test runner; the final manuscript uses animal-level exact sign-flip inference.
- Batch 7 burst-triggered validation branch, which is not retained as a manuscript result.
- Batch 11B/11D/11G/11H/11J exploratory branches not used in the final manuscript.
- Earlier Batch 11K, 11L2, 11M, N+, and Stage-B correction variants where a later fixed/corrected version was available.
- Old monolithic Batch 5/6/8/9/10 scripts when a later FORCE-runner version was retained from B3.
- Old Batch 11N tier-builder superseded by N+ final master-event scripts.

Some selected FORCE-runner folders contain plotting helper functions for secondary QC outputs because the retained runner calls those helpers as part of a complete executable module. No generated plot files themselves are included.
