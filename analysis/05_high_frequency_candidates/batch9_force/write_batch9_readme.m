function write_batch9_readme(P, burstCsv)
    fid = fopen(fullfile(P.outDir, 'README_batch9_awake_ripples_beta_relationship.txt'), 'w');
    if fid < 0, return; end
    fprintf(fid, 'HC-31: Awake ripples and beta/beta2 relationship\n');
    fprintf(fid, '========================================================\n\n');
    fprintf(fid, 'Input burst table:\n%s\n\n', burstCsv);
    fprintf(fid, 'Ripple band: %.1f-%.1f Hz\n', P.rippleBandHz(1), P.rippleBandHz(2));
    fprintf(fid, 'Candidate awake ripples were detected during speed <= %.2f cm/s.\n', P.lowSpeedThresholdCmS);
    fprintf(fid, 'Envelope thresholds: boundary z >= %.2f, peak z >= %.2f, artefact-like z > %.2f.\n\n', ...
        P.rippleEnvelopeLowZ, P.rippleEnvelopePeakZ, P.rippleArtifactPeakZ);
    fprintf(fid, 'Main outputs:\n');
    fprintf(fid, '- hc31_batch9_candidate_awake_ripples.csv\n');
    fprintf(fid, '- hc31_batch9_ripple_rates_by_subepoch_category.csv\n');
    fprintf(fid, '- hc31_batch9_beta_ripple_timing_summary.csv\n');
    fprintf(fid, '- hc31_batch9_beta_ripple_crosscorr_long.csv\n');
    fprintf(fid, '- hc31_batch9_beta2_ripple_spike_participation.csv, if spikes are available\n');
    fprintf(fid, '- QC and timing figures\n\n');
    fprintf(fid, 'Interpretation notes:\n');
    fprintf(fid, '- This is an exploratory candidate-ripple screen, not a final replay analysis.\n');
    fprintf(fid, '- Review ripple examples manually before using these events for strong claims.\n');
    fprintf(fid, '- Use animal-level summaries for interpretation.\n');
    fclose(fid);
end
