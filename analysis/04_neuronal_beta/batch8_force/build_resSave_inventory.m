function Inventory = build_resSave_inventory(resSave, indices)
    rows = {};
    for ri = indices
        if ri > numel(resSave), continue; end
        R = resSave(ri);
        animal = get_animal_name(R, ri);
        hasSp = isfield(R, 'spEpochSep') && ~isempty(R.spEpochSep);
        hasPos = isfield(R, 'posMazeLin') && ~isempty(R.posMazeLin);
        hasFields = isfield(R, 'fieldInfoC') && ~isempty(R.fieldInfoC);
        nUnits = NaN;
        nFieldCells = NaN;
        if hasSp, nUnits = size(R.spEpochSep,1); end
        if hasFields, nFieldCells = size(R.fieldInfoC,1); end
        rows(end+1,:) = {animal, ri, hasSp, nUnits, hasPos, hasFields, nFieldCells}; %#ok<SAGROW>
    end
    Inventory = cell2table(rows, 'VariableNames', { ...
        'animal','resSaveIndex','hasSpEpochSep','nUnitsSpEpochSep', ...
        'hasPosMazeLin','hasFieldInfoC','nUnitsFieldInfoC'});
end
