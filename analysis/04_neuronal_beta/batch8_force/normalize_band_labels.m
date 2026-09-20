function labels = normalize_band_labels(labels)
    labels = string(labels);
    out = strings(size(labels));
    for i = 1:numel(labels)
        s = lower(strtrim(labels(i)));
        s = replace(s, " ", "_");
        s = replace(s, "-", "_");
        if contains(s, "beta2") || contains(s, "23_30")
            out(i) = "beta2_23_30Hz";
        elseif contains(s, "13_30") || contains(s, "beta_13") || contains(s, "broad") || contains(s, "beta")
            out(i) = "beta_13_30Hz";
        else
            out(i) = labels(i);
        end
    end
    labels = out;
end
