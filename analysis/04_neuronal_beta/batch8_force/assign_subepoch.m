function subepoch = assign_subepoch(tUs, sectInt)
    subepoch = nan(size(tUs));
    for se = 1:size(sectInt,1)
        idx = tUs >= sectInt(se,1) & tUs <= sectInt(se,2);
        subepoch(idx) = se;
    end
end
