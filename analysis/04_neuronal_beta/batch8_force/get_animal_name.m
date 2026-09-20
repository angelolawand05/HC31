function animal = get_animal_name(R, idx)
    animal = sprintf('resSave_%d', idx);
    try
        if isfield(R, 'spAll') && ~isempty(R.spAll) && isfield(R.spAll(1), 'animal')
            animal = char(string(R.spAll(1).animal));
            return;
        end
    catch
    end
    f = fieldnames(R);
    for i = 1:numel(f)
        name = lower(f{i});
        if contains(name, 'animal') || contains(name, 'rat')
            v = R.(f{i});
            if ischar(v) || isstring(v)
                animal = char(string(v));
                return;
            end
        end
    end
end
