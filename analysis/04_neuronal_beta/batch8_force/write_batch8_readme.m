function write_batch8_readme(P, burstCsv)
    fid = fopen(fullfile(P.outDir, 'README_batch8_spikes_placefield_linkage.txt'), 'w');
    if fid < 0, return; end

    fprintf(fid, 'HC-31: spikes/place-field linkage\n');
    fprintf(fid, '========================================\n\n');
    fprintf(fid, 'Input burst table:\n%s\n\n', burstCsv);
    fprintf(fid, 'Purpose:\n');
    fprintf(fid, 'This batch links detected beta/beta2 bursts to CA1 spike times and place-field annotations in resSave.\n\n');
    fprintf(fid, 'Main outputs:\n');
    fprintf(fid, '- hc31_batch8_resSave_spike_placefield_inventory.csv\n');
    fprintf(fid, '- hc31_batch8_unit_placefield_summary.csv\n');
    fprintf(fid, '- hc31_batch8_unit_burst_participation.csv\n');
    fprintf(fid, '- hc31_batch8_event_ensemble_activity.csv\n');
    fprintf(fid, '- hc31_batch8_animal_level_unit_summary.csv\n');
    fprintf(fid, '- hc31_batch8_animal_level_event_summary.csv\n');
    fprintf(fid, '- hc31_batch8_animal_level_stats_summary.csv\n');
    fprintf(fid, '- burst/control and place-field figures\n\n');
    fprintf(fid, 'Interpretation notes:\n');
    fprintf(fid, '- This is exploratory and should not be described as replay analysis.\n');
    fprintf(fid, '- Burst windows are compared with matched movement control windows from the same subepoch.\n');
    fprintf(fid, '- Statistics are summarised at animal level to avoid treating every unit as fully independent.\n');
    fprintf(fid, '- Novel/familiar burst labels are only as reliable as the existing nfbeta output table.\n');

    fclose(fid);
end
