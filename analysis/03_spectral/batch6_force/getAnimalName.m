function animalName = getAnimalName(R, rIndex)
if isfield(R, 'spAll') && ~isempty(R.spAll) && isfield(R.spAll(1), 'animal')
    animalName = char(R.spAll(1).animal);
else
    animalName = sprintf('resSave%d', rIndex);
end
end
