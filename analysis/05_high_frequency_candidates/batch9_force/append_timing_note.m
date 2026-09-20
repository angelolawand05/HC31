function append_timing_note(P, animal, band, obs, pTwo)
    notePath = fullfile(P.outDir, 'hc31_batch9_surrogate_timing_notes.txt');
    fid = fopen(notePath, 'a');
    if fid < 0, return; end
    fprintf(fid, '%s | %s | observed mean post-pre = %.6g | two-sided circular-shift p = %.6g\n', ...
        char(animal), char(band), obs, pTwo);
    fclose(fid);
end
