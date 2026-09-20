function counts = count_spikes_in_intervals(st, starts, ends)
    counts = zeros(numel(starts),1);
    if isempty(st), return; end
    for i = 1:numel(starts)
        counts(i) = nnz(st >= starts(i) & st <= ends(i));
    end
end
