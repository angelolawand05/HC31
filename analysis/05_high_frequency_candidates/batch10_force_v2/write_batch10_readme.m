function write_batch10_readme(P, burstCsv)
    fid = fopen(fullfile(P.outDir, 'README_batch10_sleep_replay_memory_link.txt'), 'w');
    if fid < 0, return; end

    fprintf(fid, 'HC-31 sleep replay / longer-term memory link\n');
    fprintf(fid, '======================================================\n\n');
    fprintf(fid, 'Input beta2 burst table:\n%s\n\n', burstCsv);
    fprintf(fid, 'Default epoch mapping from spEpochSep columns:\n');
    fprintf(fid, '1 = PRE, 2 = RUN1, 3 = REST, 4 = RUN2, 5 = RUN3, 6 = POST\n');
    fprintf(fid, 'If your local resSave copy differs, edit P.epochMap at the top of the script.\n\n');
    fprintf(fid, 'Main outputs:\n');
    fprintf(fid, '- hc31_batch10_epoch_inventory_from_spikes.csv\n');
    fprintf(fid, '- hc31_batch10_run1_beta2_unit_tags.csv\n');
    fprintf(fid, '- hc31_batch10_candidate_sleep_ripples.csv\n');
    fprintf(fid, '- hc31_batch10_sleep_ripple_rates_by_epoch.csv\n');
    fprintf(fid, '- hc31_batch10_unit_sleep_ripple_participation.csv\n');
    fprintf(fid, '- hc31_batch10_animal_level_memory_link_summary.csv\n');
    fprintf(fid, '- hc31_batch10_memory_link_stats_summary.csv\n');
    fprintf(fid, '- QC and summary figures\n\n');
    fprintf(fid, 'Interpretation:\n');
    fprintf(fid, 'This is an exploratory first-pass memory-link analysis. It asks whether units active during Run1 beta2 bursts are more involved in later candidate rest/sleep ripples. It is not a full replay decoding analysis.\n\n');
    fprintf(fid, 'Cautions:\n');
    fprintf(fid, '- Candidate ripple detections should be manually inspected.\n');
    fprintf(fid, '- Replay claims require sequence/trajectory decoding, which this script does not perform.\n');
    fprintf(fid, '- Use animal-level summaries for interpretation.\n');

    fclose(fid);
end
