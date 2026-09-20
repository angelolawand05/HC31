function fs = estimate_pos_fs(posT)
    dt = diff(posT);
    dt = dt(isfinite(dt) & dt > 0);
    if isempty(dt), fs = 30; else, fs = 1e6 / median(dt); end
end
