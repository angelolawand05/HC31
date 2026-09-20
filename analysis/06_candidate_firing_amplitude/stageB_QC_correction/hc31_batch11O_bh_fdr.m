function qValues = hc31_batch11O_bh_fdr(pValues)
% Benjamini-Hochberg false-discovery-rate adjusted p-values.

originalSize = size(pValues);
p = double(pValues(:));
qValues = nan(size(p));

validMask = isfinite(p) & p >= 0 & p <= 1;
validIndices = find(validMask);

if isempty(validIndices)
    qValues = reshape(qValues,originalSize);
    return
end

validP = p(validIndices);
[sortedP,order] = sort(validP);
m = numel(sortedP);

adjusted = sortedP .* m ./ (1:m)';
adjusted = min(adjusted,1);

for index = m-1:-1:1
    adjusted(index) = min( ...
        adjusted(index), ...
        adjusted(index+1));
end

unsortedAdjusted = nan(m,1);
unsortedAdjusted(order) = adjusted;
qValues(validIndices) = unsortedAdjusted;
qValues = reshape(qValues,originalSize);

end
