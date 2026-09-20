%% HC-31 entry-based novelty sensitivity analysis - PLAIN SCRIPT VERSION
%
% This version contains NO local MATLAB helper functions.
% It is designed for setups where run(...) rejects scripts that contain
% local functions at the bottom of the file.
%
% How to run:
%
%   cd('C:\Users\angel\Documents\MATLAB\CRCN')
%   clear functions
%   rehash
%   scriptPath = 'C:\Users\angel\Documents\MATLAB\CRCN\hc31_entry_novelty_sensitivity_PLAIN_SCRIPT.m';
%   eval(['run(''', scriptPath, ''')'])
%
% Expected input files:
%
%   C:\Users\angel\Documents\MATLAB\CRCN\resSave.mat
%   C:\Users\angel\Documents\MATLAB\CRCN\beta_burst_over_time_outputs_FUNC\hc31_detected_beta_bursts.csv
%
% Output folder:
%
%   entry_novelty_sensitivity_outputs_PLAIN_SCRIPT
%
% Analysis logic:
%
%   familiar:
%       Burst occurred while the rat was in a track section already available
%       before the current Run1 subepoch.
%
%   early_novel:
%       Burst occurred while the rat was inside the newly opened section for
%       the current subepoch, during the first EARLY_WINDOW_SEC after first
%       behavioural entry into that new section.
%
%   repeated_novel:
%       Burst occurred while the rat was still inside the newly opened section
%       for the current subepoch, but after the early exposure window.
%
% Important:
%   Novelty is defined from behavioural entry into the new zone, not from the
%   first detected burst.

clear; clc; close all;

%% ===================== USER SETTINGS =====================

rootDir = pwd;

resSavePath = fullfile(rootDir, 'resSave.mat');
burstFilePath = fullfile(rootDir, 'beta_burst_over_time_outputs_FUNC', 'hc31_detected_beta_bursts.csv');

animalIndices = 5:9;
bandsToUse = {'beta_13_30Hz', 'beta2_23_30Hz'};

speedThresholdCmS = 5;
EARLY_WINDOW_SEC = 60;

excludeSubepoch1FromAnimalSummary = true;
removeArtefactBursts = true;

outDir = fullfile(rootDir, 'entry_novelty_sensitivity_outputs_PLAIN_SCRIPT');
figDir = fullfile(outDir, 'figures');

if ~exist(outDir, 'dir')
    mkdir(outDir);
end

if ~exist(figDir, 'dir')
    mkdir(figDir);
end

fprintf('\nHC-31 entry novelty sensitivity analysis - plain script version\n');
fprintf('Root folder: %s\n', rootDir);
fprintf('Early novel window: %.1f seconds\n', EARLY_WINDOW_SEC);
fprintf('Movement threshold: %.1f cm/s\n\n', speedThresholdCmS);

%% ===================== INPUT CHECKS =====================

if ~exist(resSavePath, 'file')
    error('Could not find resSave.mat here: %s', resSavePath);
end

if ~exist(burstFilePath, 'file')
    fallback1 = fullfile(rootDir, 'hc31_detected_beta_bursts.csv');
    fallback2 = fullfile(rootDir, 'outputs_hc31_beta', 'hc31_detected_beta_bursts.csv');

    if exist(fallback1, 'file')
        burstFilePath = fallback1;
    elseif exist(fallback2, 'file')
        burstFilePath = fallback2;
    else
        error(['Could not find hc31_detected_beta_bursts.csv.\n' ...
               'Expected path:\n%s\n\n' ...
               'Run the burst extraction script first, or move the CSV into the expected folder.'], burstFilePath);
    end
end

fprintf('Using resSave:\n  %s\n', resSavePath);
fprintf('Using burst table:\n  %s\n\n', burstFilePath);

%% ===================== LOAD DATA =====================

data = load(resSavePath);

if ~isfield(data, 'resSave')
    error('Loaded MAT file, but it does not contain variable resSave.');
end

resSave = data.resSave;
burstTable = readtable(burstFilePath);

fprintf('Loaded %d resSave entries.\n', numel(resSave));
fprintf('Loaded burst table with %d rows.\n\n', height(burstTable));

%% ===================== FIND BURST TABLE COLUMNS =====================

vars = burstTable.Properties.VariableNames;

animalCandidates = {'animal','Animal','animal_id','animalID','rat','ratID','resSaveAnimal'};
bandCandidates = {'band','Band','freqBand','frequency_band','betaBand'};
timeCandidates = {'peak_time','peakTime','peak_time_s','peakTimeS', ...
                  'peak_time_sec','peakTimeSec','peak_time_us','peakTimeUs', ...
                  'peak_timestamp','peakTimestamp','burst_peak_time','burstPeakTime', ...
                  'burst_peak_us','burstPeakUs'};
posCandidates = {'peak_linearised_position','peakLinearisedPosition', ...
                 'peak_linearized_position','peakLinearizedPosition', ...
                 'peak_lin_pos','peakLinPos','peak_position','peakPosition', ...
                 'linearised_position','linearized_position','linPos','peakPos'};
speedCandidates = {'peak_speed','peakSpeed','speed','peak_speed_cm_s', ...
                   'peakSpeedCmS','movingSpeed','speed_cm_s','peakVelocityCmS'};
artefactCandidates = {'is_artifact','isArtefact','isArtifact', ...
                      'artifact','artefact','artifactFlag','artefactFlag', ...
                      'excluded_as_artifact','excludedAsArtifact'};

animalCol = '';
bandCol = '';
timeCol = '';
posCol = '';
speedCol = '';
artefactCol = '';

% Exact case-insensitive matching.
for c = 1:numel(animalCandidates)
    for v = 1:numel(vars)
        if strcmpi(vars{v}, animalCandidates{c})
            animalCol = vars{v};
        end
    end
end

for c = 1:numel(bandCandidates)
    for v = 1:numel(vars)
        if strcmpi(vars{v}, bandCandidates{c})
            bandCol = vars{v};
        end
    end
end

for c = 1:numel(timeCandidates)
    for v = 1:numel(vars)
        if strcmpi(vars{v}, timeCandidates{c})
            timeCol = vars{v};
        end
    end
end

for c = 1:numel(posCandidates)
    for v = 1:numel(vars)
        if strcmpi(vars{v}, posCandidates{c})
            posCol = vars{v};
        end
    end
end

for c = 1:numel(speedCandidates)
    for v = 1:numel(vars)
        if strcmpi(vars{v}, speedCandidates{c})
            speedCol = vars{v};
        end
    end
end

for c = 1:numel(artefactCandidates)
    for v = 1:numel(vars)
        if strcmpi(vars{v}, artefactCandidates{c})
            artefactCol = vars{v};
        end
    end
end

% Normalised matching if exact matching failed.
normVars = cell(size(vars));
for v = 1:numel(vars)
    normVars{v} = lower(regexprep(vars{v}, '[^a-zA-Z0-9]', ''));
end

if isempty(animalCol)
    for c = 1:numel(animalCandidates)
        target = lower(regexprep(animalCandidates{c}, '[^a-zA-Z0-9]', ''));
        for v = 1:numel(vars)
            if strcmp(normVars{v}, target)
                animalCol = vars{v};
            end
        end
    end
end

if isempty(bandCol)
    for c = 1:numel(bandCandidates)
        target = lower(regexprep(bandCandidates{c}, '[^a-zA-Z0-9]', ''));
        for v = 1:numel(vars)
            if strcmp(normVars{v}, target)
                bandCol = vars{v};
            end
        end
    end
end

if isempty(timeCol)
    for c = 1:numel(timeCandidates)
        target = lower(regexprep(timeCandidates{c}, '[^a-zA-Z0-9]', ''));
        for v = 1:numel(vars)
            if strcmp(normVars{v}, target)
                timeCol = vars{v};
            end
        end
    end
end

if isempty(posCol)
    for c = 1:numel(posCandidates)
        target = lower(regexprep(posCandidates{c}, '[^a-zA-Z0-9]', ''));
        for v = 1:numel(vars)
            if strcmp(normVars{v}, target)
                posCol = vars{v};
            end
        end
    end
end

if isempty(speedCol)
    for c = 1:numel(speedCandidates)
        target = lower(regexprep(speedCandidates{c}, '[^a-zA-Z0-9]', ''));
        for v = 1:numel(vars)
            if strcmp(normVars{v}, target)
                speedCol = vars{v};
            end
        end
    end
end

if isempty(artefactCol)
    for c = 1:numel(artefactCandidates)
        target = lower(regexprep(artefactCandidates{c}, '[^a-zA-Z0-9]', ''));
        for v = 1:numel(vars)
            if strcmp(normVars{v}, target)
                artefactCol = vars{v};
            end
        end
    end
end

if isempty(animalCol) || isempty(bandCol) || isempty(timeCol)
    fprintf('Available burst table columns:\n');
    disp(vars');
    error('Could not find required animal, band, or peak-time columns in the burst table.');
end

fprintf('Detected columns:\n');
fprintf('  animal column: %s\n', animalCol);
fprintf('  band column:   %s\n', bandCol);
fprintf('  time column:   %s\n', timeCol);

if isempty(posCol)
    fprintf('  position column: not found; will interpolate from resSave position\n');
else
    fprintf('  position column: %s\n', posCol);
end

if isempty(speedCol)
    fprintf('  speed column: not found; will interpolate from resSave speed\n');
else
    fprintf('  speed column: %s\n', speedCol);
end

if isempty(artefactCol)
    fprintf('  artefact column: not found\n\n');
else
    fprintf('  artefact column: %s\n\n', artefactCol);
end

%% ===================== CONVERT ANIMAL/BAND COLUMNS TO CELL STRINGS =====================

rawAnimal = burstTable.(animalCol);
rawBand = burstTable.(bandCol);

if isnumeric(rawAnimal)
    animalVals = arrayfun(@num2str, rawAnimal(:), 'UniformOutput', false);
elseif iscell(rawAnimal)
    animalVals = cell(numel(rawAnimal), 1);
    for q = 1:numel(rawAnimal)
        if isnumeric(rawAnimal{q})
            animalVals{q} = num2str(rawAnimal{q});
        else
            animalVals{q} = char(rawAnimal{q});
        end
    end
else
    try
        animalVals = cellstr(rawAnimal);
    catch
        animalVals = cellstr(string(rawAnimal));
    end
    animalVals = animalVals(:);
end

if isnumeric(rawBand)
    bandVals = arrayfun(@num2str, rawBand(:), 'UniformOutput', false);
elseif iscell(rawBand)
    bandVals = cell(numel(rawBand), 1);
    for q = 1:numel(rawBand)
        if isnumeric(rawBand{q})
            bandVals{q} = num2str(rawBand{q});
        else
            bandVals{q} = char(rawBand{q});
        end
    end
else
    try
        bandVals = cellstr(rawBand);
    catch
        bandVals = cellstr(string(rawBand));
    end
    bandVals = bandVals(:);
end

%% ===================== OPTIONAL ARTEFACT REMOVAL =====================

if removeArtefactBursts && ~isempty(artefactCol)

    rawArtefact = burstTable.(artefactCol);
    artefactMask = false(height(burstTable), 1);

    if islogical(rawArtefact)
        artefactMask = rawArtefact(:);
    elseif isnumeric(rawArtefact)
        artefactMask = rawArtefact(:) ~= 0;
    else
        try
            artefactText = cellstr(rawArtefact);
        catch
            artefactText = cellstr(string(rawArtefact));
        end
        artefactText = lower(artefactText(:));

        for q = 1:numel(artefactText)
            if strcmp(artefactText{q}, 'true') || strcmp(artefactText{q}, '1') || ...
               strcmp(artefactText{q}, 'yes') || strcmp(artefactText{q}, 'y') || ...
               strcmp(artefactText{q}, 'artifact') || strcmp(artefactText{q}, 'artefact') || ...
               strcmp(artefactText{q}, 'excluded')
                artefactMask(q) = true;
            end
        end
    end

    nBefore = height(burstTable);
    keepRows = ~artefactMask;

    burstTable = burstTable(keepRows, :);
    animalVals = animalVals(keepRows);
    bandVals = bandVals(keepRows);

    fprintf('Removed %d artefact-labelled burst rows.\n\n', nBefore - height(burstTable));
end

%% ===================== MAIN ANALYSIS =====================

burstRows = {};
summaryRows = {};
animalRows = {};

for ai = 1:numel(animalIndices)

    idx = animalIndices(ai);

    if idx > numel(resSave)
        warning('resSave(%d) does not exist. Skipping.', idx);
        continue;
    end

    R = resSave(idx);

    % Animal ID detection, using the same structure as the example script.
    animalID = sprintf('resSave_%d', idx);

    if isfield(R, 'spAll')
        try
            if ~isempty(R.spAll) && isfield(R.spAll, 'animal')
                animalID = char(R.spAll(1).animal);
            end
        catch
        end
    end

    if strcmp(animalID, sprintf('resSave_%d', idx))
        if idx == 5
            animalID = 'ANM00190422';
        elseif idx == 6
            animalID = 'ANM204878';
        elseif idx == 7
            animalID = 'ANM212379';
        elseif idx == 8
            animalID = 'ANM228899';
        elseif idx == 9
            animalID = 'ANM228900';
        end
    end

    fprintf('Processing resSave(%d): %s\n', idx, animalID);

    if ~isfield(R, 'posMazeLin')
        warning('resSave(%d) has no posMazeLin. Skipping.', idx);
        continue;
    end

    posU = R.posMazeLin(1);

    if isstruct(posU) && isfield(posU, 'data')
        posData = double(posU.data);
    else
        posData = double(posU);
    end

    posTime = posData(:, 1);
    linPos = posData(:, 2);

    if size(posData, 2) >= 4
        rawSpeed = posData(:, 4);

        if isstruct(posU) && isfield(posU, 'unitsPerCm') && isfield(posU, 'unitsPerSecond')
            speedCmS = rawSpeed .* (1 ./ double(posU.unitsPerCm)) .* double(posU.unitsPerSecond);
        else
            speedCmS = rawSpeed;
        end
    else
        goodTime = posTime(isfinite(posTime));
        if numel(goodTime) >= 5
            dtNative = median(diff(goodTime));
            if dtNative > 100
                timeUnitsPerSecond = 1e6;
            else
                timeUnitsPerSecond = 1;
            end
        else
            timeUnitsPerSecond = 1e6;
        end

        dtSec = [NaN; diff(posTime)] ./ timeUnitsPerSecond;
        dx = [NaN; diff(linPos)];

        speedCmS = abs(dx ./ dtSec);

        if isstruct(posU) && isfield(posU, 'unitsPerCm')
            speedCmS = speedCmS ./ double(posU.unitsPerCm);
        end

        warning('Estimated speed from linearised position for resSave(%d).', idx);
    end

    posTime = posTime(:);
    linPos = linPos(:);
    speedCmS = speedCmS(:);

    goodTime = posTime(isfinite(posTime));
    if numel(goodTime) >= 5
        dtNative = median(diff(goodTime));
        if dtNative > 100
            timeUnitsPerSecond = 1e6;
        else
            timeUnitsPerSecond = 1;
        end
    else
        timeUnitsPerSecond = 1e6;
        dtNative = NaN;
    end

    if isfinite(dtNative)
        dtSec = dtNative ./ timeUnitsPerSecond;
    else
        dtSec = NaN;
    end

    earlyWindowNative = EARLY_WINDOW_SEC .* timeUnitsPerSecond;

    if ~isfield(R, 'sectInt') || ~isfield(R, 'sectExt')
        warning('resSave(%d) is missing sectInt or sectExt. Skipping.', idx);
        continue;
    end

    sectInt = double(R.sectInt);
    sectExt = double(R.sectExt);

    if size(sectInt, 2) ~= 2
        sectInt = reshape(sectInt, [], 2);
    end

    if size(sectExt, 2) ~= 2
        sectExt = reshape(sectExt, [], 2);
    end

    nSubepochs = min(size(sectInt, 1), size(sectExt, 1));

    fprintf('  Run1 position samples: %d\n', numel(posTime));
    fprintf('  Time units per second: %.0f\n', timeUnitsPerSecond);
    fprintf('  Subepochs: %d\n', nSubepochs);

    animalMask = strcmp(animalVals, animalID);

    if ~any(animalMask)
        animalMask = false(numel(animalVals), 1);
        for q = 1:numel(animalVals)
            if ~isempty(strfind(animalVals{q}, animalID))
                animalMask(q) = true;
            end
        end
    end

    if ~any(animalMask)
        numericAnimalVals = str2double(animalVals);
        animalMask = numericAnimalVals == idx;
    end

    for bi = 1:numel(bandsToUse)

        bandName = bandsToUse{bi};
        bandMask = strcmp(bandVals, bandName);

        BT = burstTable(animalMask & bandMask, :);

        fprintf('  Band %s: %d burst rows\n', bandName, height(BT));

        if height(BT) == 0
            continue;
        end

        burstPeakTime = double(BT.(timeCol));
        burstPeakTime = burstPeakTime(:);

        if ~isempty(posCol)
            burstPeakPos = double(BT.(posCol));
            burstPeakPos = burstPeakPos(:);
        else
            burstPeakPos = interp1(posTime, linPos, burstPeakTime, 'linear', NaN);
        end

        if ~isempty(speedCol)
            burstPeakSpeed = double(BT.(speedCol));
            burstPeakSpeed = burstPeakSpeed(:);
        else
            burstPeakSpeed = interp1(posTime, speedCmS, burstPeakTime, 'linear', NaN);
        end

        categoryForBurst = repmat({'unclassified'}, height(BT), 1);
        subepochForBurst = nan(height(BT), 1);
        firstEntryTimeForBurst = nan(height(BT), 1);
        timeSinceEntrySecForBurst = nan(height(BT), 1);

        animalFamiliarSec = 0;
        animalEarlyNovelSec = 0;
        animalRepeatedNovelSec = 0;

        animalFamiliarCount = 0;
        animalEarlyNovelCount = 0;
        animalRepeatedNovelCount = 0;

        for se = 1:nSubepochs

            t0 = sectInt(se, 1);
            t1 = sectInt(se, 2);

            newA = min(sectExt(se, 1), sectExt(se, 2));
            newB = max(sectExt(se, 1), sectExt(se, 2));

            inSubepochPos = posTime >= t0 & posTime <= t1;

            validMovingPos = inSubepochPos & isfinite(linPos) & isfinite(speedCmS) & ...
                speedCmS >= speedThresholdCmS;

            inNewZoneAnySpeed = inSubepochPos & isfinite(linPos) & ...
                linPos >= newA & linPos <= newB;

            if any(inNewZoneAnySpeed)
                firstEntryTime = posTime(find(inNewZoneAnySpeed, 1, 'first'));
            else
                firstEntryTime = NaN;
            end

            earlyEndTime = firstEntryTime + earlyWindowNative;

            inNewZoneMoving = validMovingPos & linPos >= newA & linPos <= newB;
            inFamiliarMoving = validMovingPos & ~inNewZoneMoving;

            earlyNovelMoving = inNewZoneMoving & posTime >= firstEntryTime & posTime <= earlyEndTime;
            repeatedNovelMoving = inNewZoneMoving & posTime > earlyEndTime;
            familiarMoving = inFamiliarMoving;

            familiarSec = sum(familiarMoving & isfinite(posTime)) .* dtSec;
            earlyNovelSec = sum(earlyNovelMoving & isfinite(posTime)) .* dtSec;
            repeatedNovelSec = sum(repeatedNovelMoving & isfinite(posTime)) .* dtSec;

            burstInSubepoch = burstPeakTime >= t0 & burstPeakTime <= t1 & ...
                isfinite(burstPeakTime) & isfinite(burstPeakPos);

            burstMoving = isfinite(burstPeakSpeed) & burstPeakSpeed >= speedThresholdCmS;
            burstInSubepoch = burstInSubepoch & burstMoving;

            burstInNewZone = burstInSubepoch & burstPeakPos >= newA & burstPeakPos <= newB;
            burstFamiliar = burstInSubepoch & ~burstInNewZone;

            burstEarlyNovel = burstInNewZone & burstPeakTime >= firstEntryTime & burstPeakTime <= earlyEndTime;
            burstRepeatedNovel = burstInNewZone & burstPeakTime > earlyEndTime;

            nFamiliar = sum(burstFamiliar);
            nEarlyNovel = sum(burstEarlyNovel);
            nRepeatedNovel = sum(burstRepeatedNovel);

            if familiarSec > 0
                familiarRate = nFamiliar ./ familiarSec .* 60;
            else
                familiarRate = NaN;
            end

            if earlyNovelSec > 0
                earlyNovelRate = nEarlyNovel ./ earlyNovelSec .* 60;
            else
                earlyNovelRate = NaN;
            end

            if repeatedNovelSec > 0
                repeatedNovelRate = nRepeatedNovel ./ repeatedNovelSec .* 60;
            else
                repeatedNovelRate = NaN;
            end

            summaryRows(end+1, :) = {animalID, idx, bandName, se, ...
                t0, t1, firstEntryTime, earlyEndTime, EARLY_WINDOW_SEC, ...
                newA, newB, familiarSec, earlyNovelSec, repeatedNovelSec, ...
                nFamiliar, nEarlyNovel, nRepeatedNovel, ...
                familiarRate, earlyNovelRate, repeatedNovelRate}; %#ok<SAGROW>

            includeInAnimalSummary = true;
            if excludeSubepoch1FromAnimalSummary && se == 1
                includeInAnimalSummary = false;
            end

            if includeInAnimalSummary
                animalFamiliarSec = animalFamiliarSec + familiarSec;
                animalEarlyNovelSec = animalEarlyNovelSec + earlyNovelSec;
                animalRepeatedNovelSec = animalRepeatedNovelSec + repeatedNovelSec;

                animalFamiliarCount = animalFamiliarCount + nFamiliar;
                animalEarlyNovelCount = animalEarlyNovelCount + nEarlyNovel;
                animalRepeatedNovelCount = animalRepeatedNovelCount + nRepeatedNovel;
            end

            localBurstIdx = find(burstInSubepoch);

            for kk = 1:numel(localBurstIdx)
                r = localBurstIdx(kk);

                if burstFamiliar(r)
                    categoryForBurst{r} = 'familiar';
                elseif burstEarlyNovel(r)
                    categoryForBurst{r} = 'early_novel';
                elseif burstRepeatedNovel(r)
                    categoryForBurst{r} = 'repeated_novel';
                else
                    categoryForBurst{r} = 'unclassified';
                end

                subepochForBurst(r) = se;
                firstEntryTimeForBurst(r) = firstEntryTime;
                timeSinceEntrySecForBurst(r) = (burstPeakTime(r) - firstEntryTime) ./ timeUnitsPerSecond;
            end
        end

        for r = 1:height(BT)
            burstRows(end+1, :) = {animalID, idx, bandName, ...
                burstPeakTime(r), burstPeakPos(r), burstPeakSpeed(r), ...
                subepochForBurst(r), categoryForBurst{r}, ...
                firstEntryTimeForBurst(r), timeSinceEntrySecForBurst(r)}; %#ok<SAGROW>
        end

        if animalFamiliarSec > 0
            familiarRateAnimal = animalFamiliarCount ./ animalFamiliarSec .* 60;
        else
            familiarRateAnimal = NaN;
        end

        if animalEarlyNovelSec > 0
            earlyNovelRateAnimal = animalEarlyNovelCount ./ animalEarlyNovelSec .* 60;
        else
            earlyNovelRateAnimal = NaN;
        end

        if animalRepeatedNovelSec > 0
            repeatedNovelRateAnimal = animalRepeatedNovelCount ./ animalRepeatedNovelSec .* 60;
        else
            repeatedNovelRateAnimal = NaN;
        end

        animalRows(end+1, :) = {animalID, idx, bandName, ...
            animalFamiliarSec, animalEarlyNovelSec, animalRepeatedNovelSec, ...
            animalFamiliarCount, animalEarlyNovelCount, animalRepeatedNovelCount, ...
            familiarRateAnimal, earlyNovelRateAnimal, repeatedNovelRateAnimal, ...
            earlyNovelRateAnimal - familiarRateAnimal, ...
            repeatedNovelRateAnimal - familiarRateAnimal, ...
            earlyNovelRateAnimal - repeatedNovelRateAnimal}; %#ok<SAGROW>
    end

    fprintf('  Finished %s\n\n', animalID);
end

%% ===================== WRITE OUTPUT TABLES =====================

burstOut = cell2table(burstRows, 'VariableNames', { ...
    'animal','resSaveIndex','band','peakTime','peakLinearisedPosition', ...
    'peakSpeedCmS','run1Subepoch','entryNoveltyCategory', ...
    'firstEntryTime','timeSinceFirstEntrySec'});

summaryOut = cell2table(summaryRows, 'VariableNames', { ...
    'animal','resSaveIndex','band','run1Subepoch', ...
    'subepochStartTime','subepochEndTime', ...
    'firstEntryTime','earlyWindowEndTime','earlyWindowSeconds', ...
    'newZoneStart','newZoneEnd', ...
    'familiarValidSeconds','earlyNovelValidSeconds','repeatedNovelValidSeconds', ...
    'familiarBurstCount','earlyNovelBurstCount','repeatedNovelBurstCount', ...
    'familiarRatePerMin','earlyNovelRatePerMin','repeatedNovelRatePerMin'});

animalOut = cell2table(animalRows, 'VariableNames', { ...
    'animal','resSaveIndex','band', ...
    'familiarValidSeconds','earlyNovelValidSeconds','repeatedNovelValidSeconds', ...
    'familiarBurstCount','earlyNovelBurstCount','repeatedNovelBurstCount', ...
    'familiarRatePerMin','earlyNovelRatePerMin','repeatedNovelRatePerMin', ...
    'earlyNovelMinusFamiliar','repeatedNovelMinusFamiliar','earlyNovelMinusRepeatedNovel'});

writetable(burstOut, fullfile(outDir, 'hc31_entry_novelty_burst_table_PLAIN_SCRIPT.csv'));
writetable(summaryOut, fullfile(outDir, 'hc31_entry_novelty_subepoch_summary_PLAIN_SCRIPT.csv'));
writetable(animalOut, fullfile(outDir, 'hc31_entry_novelty_animal_summary_PLAIN_SCRIPT.csv'));

%% ===================== STATS TABLE =====================

statsRows = {};

comparisonNames = {'earlyNovel_vs_familiar', 'repeatedNovel_vs_familiar', 'earlyNovel_vs_repeatedNovel'};
comparisonACols = {'earlyNovelRatePerMin', 'repeatedNovelRatePerMin', 'earlyNovelRatePerMin'};
comparisonBCols = {'familiarRatePerMin', 'familiarRatePerMin', 'repeatedNovelRatePerMin'};

for bi = 1:numel(bandsToUse)

    bandName = bandsToUse{bi};
    bandRows = strcmp(animalOut.band, bandName);
    A = animalOut(bandRows, :);

    for ci = 1:numel(comparisonNames)

        compName = comparisonNames{ci};
        colA = comparisonACols{ci};
        colB = comparisonBCols{ci};

        x = A.(colA);
        y = A.(colB);
        d = x - y;
        d = d(isfinite(d));

        nAnimals = numel(d);

        if isempty(x(isfinite(x)))
            meanA = NaN;
        else
            meanA = mean(x(isfinite(x)));
        end

        if isempty(y(isfinite(y)))
            meanB = NaN;
        else
            meanB = mean(y(isfinite(y)));
        end

        if isempty(d)
            meanDifference = NaN;
            medianDifference = NaN;
            nPositive = NaN;
            nNegative = NaN;
            signFlipP = NaN;
            pairedTP = NaN;
            pairedTStat = NaN;
        else
            meanDifference = mean(d);
            medianDifference = median(d);
            nPositive = sum(d > 0);
            nNegative = sum(d < 0);

            dNoZero = d(d ~= 0);

            if isempty(dNoZero)
                signFlipP = NaN;
            else
                obs = abs(mean(dNoZero));
                nPerm = 2 ^ numel(dNoZero);
                permMeans = zeros(nPerm, 1);

                for perm = 0:(nPerm - 1)
                    signs = ones(numel(dNoZero), 1);
                    bits = dec2bin(perm, numel(dNoZero)) == '1';
                    signs(bits(:)) = -1;
                    permMeans(perm + 1) = mean(dNoZero .* signs);
                end

                signFlipP = mean(abs(permMeans) >= obs);
            end

            if numel(d) >= 2 && std(d) > 0
                pairedTStat = mean(d) ./ (std(d) ./ sqrt(numel(d)));

                if exist('tcdf', 'file') == 2
                    pairedTP = 2 .* (1 - tcdf(abs(pairedTStat), numel(d) - 1));
                else
                    pairedTP = NaN;
                end
            else
                pairedTStat = NaN;
                pairedTP = NaN;
            end
        end

        statsRows(end+1, :) = {bandName, compName, nAnimals, ...
            meanA, meanB, meanDifference, medianDifference, ...
            nPositive, nNegative, signFlipP, pairedTP, pairedTStat}; %#ok<SAGROW>
    end
end

statsOut = cell2table(statsRows, 'VariableNames', { ...
    'band','comparison','nAnimals','meanA','meanB','meanDifference', ...
    'medianDifference','nPositive','nNegative', ...
    'twoSidedExactSignFlipP','pairedTTestP','pairedTStat'});

writetable(statsOut, fullfile(outDir, 'hc31_entry_novelty_stats_PLAIN_SCRIPT.csv'));

%% ===================== FIGURES =====================

for bi = 1:numel(bandsToUse)

    bandName = bandsToUse{bi};
    bandRows = strcmp(animalOut.band, bandName);
    A = animalOut(bandRows, :);

    if height(A) == 0
        continue;
    end

    vals = [A.familiarRatePerMin, A.earlyNovelRatePerMin, A.repeatedNovelRatePerMin];

    figure('Color', 'w', 'Position', [100 100 760 520]);
    hold on;

    xPositions = 1:3;

    for r = 1:size(vals, 1)
        plot(xPositions, vals(r, :), '-o', 'LineWidth', 1.2, 'MarkerSize', 6);
    end

    meanVals = nan(1, 3);
    semVals = nan(1, 3);

    for j = 1:3
        thisVals = vals(:, j);
        thisVals = thisVals(isfinite(thisVals));

        if ~isempty(thisVals)
            meanVals(j) = mean(thisVals);
            if numel(thisVals) > 1
                semVals(j) = std(thisVals) ./ sqrt(numel(thisVals));
            end
        end
    end

    errorbar(xPositions, meanVals, semVals, 'k-o', 'LineWidth', 3, ...
        'MarkerFaceColor', 'k', 'MarkerSize', 8);

    set(gca, 'XTick', xPositions, 'XTickLabel', {'Familiar','Early novel','Repeated novel'});
    ylabel('Burst rate, bursts/min');
    title(sprintf('%s entry-based novelty sensitivity', bandName), 'Interpreter', 'none');
    grid on;
    xlim([0.75 3.25]);

    saveas(gcf, fullfile(figDir, [bandName '_entry_novelty_rates_PLAIN_SCRIPT.png']));
    close(gcf);

    S = summaryOut(strcmp(summaryOut.band, bandName), :);
    subepochs = unique(S.run1Subepoch);

    meanFam = nan(numel(subepochs), 1);
    meanEarly = nan(numel(subepochs), 1);
    meanRepeat = nan(numel(subepochs), 1);
    semFam = nan(numel(subepochs), 1);
    semEarly = nan(numel(subepochs), 1);
    semRepeat = nan(numel(subepochs), 1);

    for si = 1:numel(subepochs)

        se = subepochs(si);
        X = S(S.run1Subepoch == se, :);

        temp = X.familiarRatePerMin;
        temp = temp(isfinite(temp));
        if ~isempty(temp)
            meanFam(si) = mean(temp);
            if numel(temp) > 1
                semFam(si) = std(temp) ./ sqrt(numel(temp));
            end
        end

        temp = X.earlyNovelRatePerMin;
        temp = temp(isfinite(temp));
        if ~isempty(temp)
            meanEarly(si) = mean(temp);
            if numel(temp) > 1
                semEarly(si) = std(temp) ./ sqrt(numel(temp));
            end
        end

        temp = X.repeatedNovelRatePerMin;
        temp = temp(isfinite(temp));
        if ~isempty(temp)
            meanRepeat(si) = mean(temp);
            if numel(temp) > 1
                semRepeat(si) = std(temp) ./ sqrt(numel(temp));
            end
        end
    end

    figure('Color', 'w', 'Position', [100 100 820 520]);
    hold on;
    errorbar(subepochs, meanFam, semFam, '-o', 'LineWidth', 2);
    errorbar(subepochs, meanEarly, semEarly, '-o', 'LineWidth', 2);
    errorbar(subepochs, meanRepeat, semRepeat, '-o', 'LineWidth', 2);
    xlabel('Run1 subepoch');
    ylabel('Burst rate, bursts/min');
    title(sprintf('%s entry novelty category by subepoch', bandName), 'Interpreter', 'none');
    legend({'Familiar','Early novel','Repeated novel'}, 'Location', 'best');
    grid on;

    saveas(gcf, fullfile(figDir, [bandName '_entry_novelty_by_subepoch_PLAIN_SCRIPT.png']));
    close(gcf);
end

%% ===================== FINISH =====================

fprintf('\nDone.\n');
fprintf('Outputs written to:\n  %s\n\n', outDir);

disp('Animal-level summary:');
disp(animalOut);

disp('Stats summary:');
disp(statsOut);

fprintf('\nInterpretation reminder:\n');
fprintf('  early_novel = first %.1f seconds after first behavioural entry into the newly opened section.\n', EARLY_WINDOW_SEC);
fprintf('  repeated_novel = later movement in that same newly opened section.\n');
fprintf('  familiar = track that was already available before the current subepoch.\n');
fprintf('  This is a sensitivity analysis, not a replacement for the original novel/familiar result.\n\n');
