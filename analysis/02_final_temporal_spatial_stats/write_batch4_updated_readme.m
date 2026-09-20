function write_batch4_updated_readme(outDir, overTimeCsv, nfAnimalCsv, nfSubepochCsv, nfBurstCsv, speedAnimalCsv, speedCorrCsv)
    fid = fopen(fullfile(outDir, 'README_batch4_updated_stats.txt'), 'w');
    if fid < 0, return; end

    fprintf(fid, 'HC-31 updated Batch 4 statistics\n');
    fprintf(fid, '=================================\n\n');
    fprintf(fid, 'Purpose:\n');
    fprintf(fid, 'This runner replaces the unclear original Batch 4 plots with direct animal-level statistical plots and significance-bar figures.\n\n');

    fprintf(fid, 'Core inputs:\n');
    fprintf(fid, '  over-time burst table: %s\n', overTimeCsv);
    fprintf(fid, '  novel/familiar animal summary: %s\n', nfAnimalCsv);
    fprintf(fid, '  novel/familiar subepoch summary: %s\n', nfSubepochCsv);
    if ~isempty(nfBurstCsv), fprintf(fid, '  burst event table: %s\n', nfBurstCsv); end
    if ~isempty(speedAnimalCsv), fprintf(fid, '  speed animal summary: %s\n', speedAnimalCsv); end
    if ~isempty(speedCorrCsv), fprintf(fid, '  speed/burst correlation summary: %s\n', speedCorrCsv); end

    fprintf(fid, '\nMain tests:\n');
    fprintf(fid, '- beta2_23_30Hz versus beta_13_30Hz overall burst frequency.\n');
    fprintf(fid, '- novel versus familiar burst frequency for each band.\n');
    fprintf(fid, '- beta2 versus broad beta within novel and familiar windows.\n');
    fprintf(fid, '- novel versus familiar burst frequency by Run1 subepoch.\n');
    fprintf(fid, '- first-half versus second-half burst frequency for each band.\n');
    fprintf(fid, '- animal-level burst-rate slope versus zero for each band.\n');
    fprintf(fid, '- optional speed-control and event-metric tests when available.\n');

    fprintf(fid, '\nStatistics:\n');
    fprintf(fid, 'All main p-values use exact paired sign-flip tests at animal level. The 60-s bins are not treated as independent samples.\n');
    fprintf(fid, 'With n=5 animals, exact two-sided p-values are coarse; p=0.0625 is the smallest possible two-sided p when all 5 animals move in the same direction.\n\n');

    fprintf(fid, 'Main outputs:\n');
    fprintf(fid, '- hc31_batch4_updated_stats_summary.csv\n');
    fprintf(fid, '- hc31_batch4_updated_over_time_animal_summary.csv\n');
    fprintf(fid, '- hc31_batch4_updated_novel_familiar_animal_summary.csv\n');
    fprintf(fid, '- hc31_batch4_updated_novel_familiar_subepoch_summary.csv\n');
    fprintf(fid, '- figures/batch4_stats_*.png\n');
    fprintf(fid, '- figures/batch4_stats_*.fig\n');

    fclose(fid);
end
