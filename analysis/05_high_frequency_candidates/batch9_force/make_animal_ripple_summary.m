function AnimalSummary = make_animal_ripple_summary(RT)
    if isempty(RT), AnimalSummary = table(); return; end
    animals = unique(string(RT.animal), 'stable');
    rows = {};
    for ai = 1:numel(animals)
        idx = string(RT.animal) == animals(ai) & string(RT.category) == "all";
        if ~any(idx), continue; end
        rows(end+1,:) = {char(animals(ai)), ...
            sum(RT.validLowSpeedSeconds(idx), 'omitnan'), ...
            sum(RT.rippleCount(idx), 'omitnan'), ...
            sum(RT.rippleCount(idx), 'omitnan') / max(sum(RT.validLowSpeedSeconds(idx), 'omitnan'), eps) * 60}; %#ok<AGROW>
    end
    AnimalSummary = cell2table(rows, 'VariableNames', {'animal','validLowSpeedSeconds','rippleCount','rippleRatePerMinute'});
end
