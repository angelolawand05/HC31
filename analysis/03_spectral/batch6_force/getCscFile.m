function fileName = getCscFile(rootDir, animalName)
% Standard HC-31 CSC file mapping from earlier scripts.
switch char(animalName)
    case 'ANM00190422'
        rel = fullfile('csc_files', 'ANM00190422', '2012-12-09_10-48-47', 'CSC33.ncs');
        cscBase = 'CSC33.ncs';
    case 'ANM204878'
        rel = fullfile('csc_files', 'ANM204878', '2013-05-11_09-32-49', 'CSC33.ncs');
        cscBase = 'CSC33.ncs';
    case 'ANM212379'
        rel = fullfile('csc_files', 'ANM212379', '2013-06-08_10-10-46', 'CSC53.ncs');
        cscBase = 'CSC53.ncs';
    case 'ANM228899'
        rel = fullfile('csc_files', 'ANM228899', '2013-11-02_10-16-53', 'CSC45.ncs');
        cscBase = 'CSC45.ncs';
    case 'ANM228900'
        rel = fullfile('csc_files', 'ANM228900', '2013-11-03_08-59-40', 'CSC45.ncs');
        cscBase = 'CSC45.ncs';
    otherwise
        error('Unknown animal name for CSC lookup: %s', animalName);
end

fileName = fullfile(rootDir, rel);
if exist(fileName, 'file') == 2
    return;
end

% Fallback: search inside the animal's CSC folder for the expected CSC name.
animalDir = fullfile(rootDir, 'csc_files', animalName);
if exist(animalDir, 'dir') == 7
    parts = strsplit(genpath(animalDir), pathsep);
    for p = 1:numel(parts)
        if isempty(parts{p}); continue; end
        candidate = fullfile(parts{p}, cscBase);
        if exist(candidate, 'file') == 2
            fileName = candidate;
            return;
        end
    end
end

error('Could not find CSC file for %s. Expected %s', animalName, fullfile(rootDir, rel));
end
