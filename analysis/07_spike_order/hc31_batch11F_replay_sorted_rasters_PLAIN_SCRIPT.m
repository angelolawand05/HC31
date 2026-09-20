%% HC-31 Batch 11F: replay-style sorted ripple rasters
%
% Plain script version. No local functions.
%
% Purpose:
%   Create replay-style candidate ripple plots using place-field sorted CA1 units.
%
% Core idea:
%   1. Sort units by their place-field peak position on the linear track.
%   2. For each candidate ripple event, collect spikes in a short event window.
%   3. Plot a raster where y-position is place-field order.
%   4. Compute a simple sequence score:
%        corr(spike time, unit place-field position)
%      Positive correlation = forward-like sequence.
%      Negative correlation = reverse-like sequence.
%
% Outputs:
%   - Example forward-like and reverse-like candidate ripple raster figures.
%   - Event-level replay-style score CSV.
%   - Unit place-field order CSV.
%   - Group summary CSV.
%
% Required:
%   - resSave.mat
%   - csc_files folder
%   - neuralynximport folder with Nlx2MatCSC/readNlxHeader
%   - candidate sleep/rest ripple CSV from Batch 10
%
% Optional:
%   - candidate awake ripple CSV from Batch 9
%   - unit place-field CSV from Batch 8/10
%
% Important:
%   This is an exploratory replay-style screen, not a definitive replay decoder.
%   It uses a simple time-position correlation inside candidate ripple windows.
%
% Recommended MATLAB workaround:
%
%   clear; clc; close all; rehash;
%   [scriptFile, scriptFolder] = uigetfile('*.m', 'Select hc31_batch11F_replay_sorted_rasters_PLAIN_SCRIPT.m');
%   cd(scriptFolder);
%   txt = fileread(fullfile(scriptFolder, scriptFile));
%   eval(txt);

clear; clc; close all; rehash;

fprintf('\nHC-31 Batch 11F: replay-style sorted ripple rasters\n');
fprintf('---------------------------------------------------\n');

%% User-editable settings

defaultRoot = getenv('HC31_DATA_ROOT');

animalIndices = 5:9;
fallbackAnimalIDs = {'ANM00190422','ANM204878','ANM212379','ANM228899','ANM228900'};

epochLabelsWanted = {'PRE','REST','Run1Awake'};
spEpochMap.PRE = 1;
spEpochMap.Run1Awake = 2;
spEpochMap.REST = 3;

rippleLowHz = 120;
rippleHighHz = 250;
filterOrder = 4;
targetFs = 1000;

defaultHalfWindowSec = 0.10;      % used if candidate ripple start/end are unavailable
plotWindowSec = 0.25;             % plot +/- around event peak
minSpikesForScore = 5;            % minimum spikes in event window
minUnitsForScore = 3;             % minimum different units in event window
maxExampleEventsPerAnimalEpoch = 2; % top forward and top reverse examples per animal/epoch

%% Locate dataset root

if exist(defaultRoot, 'dir') == 7
    rootDir = defaultRoot;
else
    rootDir = uigetdir(pwd, 'Select the HC-31 root folder containing resSave.mat');
    if isequal(rootDir, 0)
        error('No dataset folder selected.');
    end
end

if exist(fullfile(rootDir, 'resSave.mat'), 'file') ~= 2
    [matFile, matFolder] = uigetfile('*.mat', 'Select resSave.mat');
    if isequal(matFile, 0)
        error('No resSave.mat selected.');
    end
    rootDir = matFolder;
end

fprintf('Dataset root:\n  %s\n', rootDir);

%% Add Neuralynx importer

if exist(fullfile(rootDir, 'neuralynximport'), 'dir') == 7
    addpath(genpath(fullfile(rootDir, 'neuralynximport')));
end
if exist(fullfile(rootDir, 'neuralynximport', 'nlximport'), 'dir') == 7
    addpath(genpath(fullfile(rootDir, 'neuralynximport', 'nlximport')));
end

if exist('Nlx2MatCSC', 'file') ~= 3 && exist('Nlx2MatCSC', 'file') ~= 2
    error(['MATLAB cannot find Nlx2MatCSC. ', ...
           'Check that neuralynximport is inside the dataset root, or add it to the MATLAB path.']);
end

%% Load resSave

S = load(fullfile(rootDir, 'resSave.mat'));
if ~isfield(S, 'resSave')
    error('The selected MAT file does not contain resSave.');
end
resSave = S.resSave;

%% Locate candidate ripple CSVs

sleepRippleCsv = '';
sleepCandidates = { ...
    fullfile(rootDir, 'hc31_batch10_sleep_replay_memory_link_FORCE_V2', 'hc31_batch10_candidate_sleep_ripples.csv'), ...
    fullfile(rootDir, 'allresults', 'hc31_batch10_sleep_replay_memory_link_FORCE_V2', 'hc31_batch10_candidate_sleep_ripples.csv'), ...
    fullfile(rootDir, 'hc31_batch10_candidate_sleep_ripples.csv') ...
    };

for q = 1:numel(sleepCandidates)
    if exist(sleepCandidates{q}, 'file') == 2
        sleepRippleCsv = sleepCandidates{q};
        break;
    end
end

if isempty(sleepRippleCsv)
    [f,p] = uigetfile('*.csv', 'Select hc31_batch10_candidate_sleep_ripples.csv');
    if isequal(f,0)
        error('No sleep/rest ripple CSV selected.');
    end
    sleepRippleCsv = fullfile(p,f);
end

awakeRippleCsv = '';
awakeCandidates = { ...
    fullfile(rootDir, 'hc31_batch9_candidate_awake_ripples.csv'), ...
    fullfile(rootDir, 'allresults', 'hc31_batch9_candidate_awake_ripples.csv'), ...
    fullfile(rootDir, 'hc31_batch9_awake_ripples_beta_relationship_FORCE', 'hc31_batch9_candidate_awake_ripples.csv'), ...
    fullfile(rootDir, 'allresults', 'hc31_batch9_awake_ripples_beta_relationship_FORCE', 'hc31_batch9_candidate_awake_ripples.csv') ...
    };

for q = 1:numel(awakeCandidates)
    if exist(awakeCandidates{q}, 'file') == 2
        awakeRippleCsv = awakeCandidates{q};
        break;
    end
end

if isempty(awakeRippleCsv)
    [f,p] = uigetfile('*.csv', 'Optional: select awake ripple CSV from Batch 9, or Cancel to skip Run1 awake');
    if ~isequal(f,0)
        awakeRippleCsv = fullfile(p,f);
    end
end

fprintf('\nUsing sleep/rest ripple table:\n  %s\n', sleepRippleCsv);
if ~isempty(awakeRippleCsv)
    fprintf('Using awake ripple table:\n  %s\n', awakeRippleCsv);
else
    fprintf('No awake ripple table selected. Run1Awake will be skipped.\n');
end

TR_sleep = readtable(sleepRippleCsv);
if ~isempty(awakeRippleCsv)
    TR_awake = readtable(awakeRippleCsv);
else
    TR_awake = table();
end

%% Optional place-field/unit metadata CSV

unitMetaCsv = '';
unitMetaCandidates = { ...
    fullfile(rootDir, 'hc31_batch8_spikes_placefield_linkage_FORCE', 'hc31_batch8_unit_burst_participation.csv'), ...
    fullfile(rootDir, 'allresults', 'hc31_batch8_spikes_placefield_linkage_FORCE', 'hc31_batch8_unit_burst_participation.csv'), ...
    fullfile(rootDir, 'hc31_batch10_sleep_replay_memory_link_FORCE_V2', 'hc31_batch10_run1_beta2_unit_tags.csv'), ...
    fullfile(rootDir, 'allresults', 'hc31_batch10_sleep_replay_memory_link_FORCE_V2', 'hc31_batch10_run1_beta2_unit_tags.csv'), ...
    fullfile(rootDir, 'hc31_batch8_unit_burst_participation.csv'), ...
    fullfile(rootDir, 'hc31_batch10_run1_beta2_unit_tags.csv') ...
    };

for q = 1:numel(unitMetaCandidates)
    if exist(unitMetaCandidates{q}, 'file') == 2
        unitMetaCsv = unitMetaCandidates{q};
        break;
    end
end

if isempty(unitMetaCsv)
    [f,p] = uigetfile('*.csv', 'Optional: select unit/place-field metadata CSV, or Cancel to infer place-field order');
    if ~isequal(f,0)
        unitMetaCsv = fullfile(p,f);
    end
end

if ~isempty(unitMetaCsv)
    UnitMeta = readtable(unitMetaCsv);
    fprintf('Using optional unit metadata table:\n  %s\n', unitMetaCsv);
else
    UnitMeta = table();
    fprintf('No unit metadata table selected. Place-field order will be inferred from Run1 spikes and position.\n');
end

%% Build common ripple event table

allEventRows = {};

% Sleep/rest events
varsSleep = TR_sleep.Properties.VariableNames;

slAnimalCol = '';
if any(strcmp(varsSleep, 'animal')); slAnimalCol = 'animal'; end

slEpochCol = '';
for c = {'epoch','epochName','state','session','epoch_label'}
    if any(strcmp(varsSleep, c{1}))
        slEpochCol = c{1};
        break;
    end
end

slPeakCol = '';
for c = {'ripplePeakUs','peakUs','eventPeakUs','peakTimeUs','peak_time_us'}
    if any(strcmp(varsSleep, c{1}))
        slPeakCol = c{1};
        break;
    end
end

slStartCol = '';
for c = {'rippleStartUs','startUs','eventStartUs','startTimeUs','start_time_us'}
    if any(strcmp(varsSleep, c{1}))
        slStartCol = c{1};
        break;
    end
end

slEndCol = '';
for c = {'rippleEndUs','endUs','eventEndUs','endTimeUs','end_time_us'}
    if any(strcmp(varsSleep, c{1}))
        slEndCol = c{1};
        break;
    end
end

if isempty(slAnimalCol) || isempty(slPeakCol)
    fprintf('Available sleep/rest ripple columns:\n');
    disp(varsSleep');
    error('Could not identify required columns in the sleep/rest ripple table.');
end

for rr = 1:height(TR_sleep)
    animalVal = TR_sleep.(slAnimalCol)(rr,:);
    if iscell(animalVal); animalVal = animalVal{1}; end
    if isstring(animalVal); animalVal = char(animalVal); end
    animalVal = strtrim(char(animalVal));

    epochVal = 'PRE';
    if ~isempty(slEpochCol)
        tmp = TR_sleep.(slEpochCol)(rr,:);
        if iscell(tmp); tmp = tmp{1}; end
        if isstring(tmp); tmp = char(tmp); end
        tmp = lower(strtrim(char(tmp)));
        if contains(tmp, 'pre')
            epochVal = 'PRE';
        elseif contains(tmp, 'rest')
            epochVal = 'REST';
        elseif contains(tmp, 'run1') || contains(tmp, 'awake')
            epochVal = 'Run1Awake';
        else
            epochVal = '';
        end
    end

    if isempty(epochVal)
        continue;
    end

    peakUs = double(TR_sleep.(slPeakCol)(rr));
    if isempty(slStartCol)
        startUs = peakUs - defaultHalfWindowSec*1e6;
    else
        startUs = double(TR_sleep.(slStartCol)(rr));
    end
    if isempty(slEndCol)
        endUs = peakUs + defaultHalfWindowSec*1e6;
    else
        endUs = double(TR_sleep.(slEndCol)(rr));
    end

    if isfinite(peakUs) && isfinite(startUs) && isfinite(endUs) && endUs > startUs
        allEventRows(end+1,:) = {animalVal, epochVal, startUs, endUs, peakUs, 'sleepTable'}; %#ok<SAGROW>
    end
end

% Awake events, optional
if ~isempty(TR_awake)
    varsAwake = TR_awake.Properties.VariableNames;

    awAnimalCol = '';
    if any(strcmp(varsAwake, 'animal')); awAnimalCol = 'animal'; end

    awPeakCol = '';
    for c = {'ripplePeakUs','peakUs','eventPeakUs','peakTimeUs','peak_time_us'}
        if any(strcmp(varsAwake, c{1}))
            awPeakCol = c{1};
            break;
        end
    end

    awStartCol = '';
    for c = {'rippleStartUs','startUs','eventStartUs','startTimeUs','start_time_us'}
        if any(strcmp(varsAwake, c{1}))
            awStartCol = c{1};
            break;
        end
    end

    awEndCol = '';
    for c = {'rippleEndUs','endUs','eventEndUs','endTimeUs','end_time_us'}
        if any(strcmp(varsAwake, c{1}))
            awEndCol = c{1};
            break;
        end
    end

    if ~isempty(awAnimalCol) && ~isempty(awPeakCol)
        for rr = 1:height(TR_awake)
            animalVal = TR_awake.(awAnimalCol)(rr,:);
            if iscell(animalVal); animalVal = animalVal{1}; end
            if isstring(animalVal); animalVal = char(animalVal); end
            animalVal = strtrim(char(animalVal));

            peakUs = double(TR_awake.(awPeakCol)(rr));
            if isempty(awStartCol)
                startUs = peakUs - defaultHalfWindowSec*1e6;
            else
                startUs = double(TR_awake.(awStartCol)(rr));
            end
            if isempty(awEndCol)
                endUs = peakUs + defaultHalfWindowSec*1e6;
            else
                endUs = double(TR_awake.(awEndCol)(rr));
            end

            if isfinite(peakUs) && isfinite(startUs) && isfinite(endUs) && endUs > startUs
                allEventRows(end+1,:) = {animalVal, 'Run1Awake', startUs, endUs, peakUs, 'awakeTable'}; %#ok<SAGROW>
            end
        end
    end
end

if isempty(allEventRows)
    error('No usable candidate ripple events were found.');
end

Events = cell2table(allEventRows, 'VariableNames', {'animal','epoch','startUs','endUs','peakUs','sourceTable'});

%% Output folders

outDir = fullfile(rootDir, 'hc31_batch11F_replay_sorted_rasters');
figDir = fullfile(outDir, 'figures');
if exist(outDir, 'dir') ~= 7; mkdir(outDir); end
if exist(figDir, 'dir') ~= 7; mkdir(figDir); end

%% Storage tables

unitOrderRows = {};
eventScoreRows = {};
summaryRows = {};

%% Main animal loop

for ai = 1:numel(animalIndices)

    idx = animalIndices(ai);
    if idx > numel(resSave); continue; end
    R = resSave(idx);

    animalID = fallbackAnimalIDs{ai};
    try
        if isfield(R, 'spAll') && ~isempty(R.spAll) && isfield(R.spAll, 'animal')
            animalID = char(R.spAll(1).animal);
        elseif isfield(R, 'name')
            animalID = char(R.name);
        elseif isfield(R, 'animal')
            animalID = char(R.animal);
        end
    catch
    end
    animalID = strtrim(animalID);

    Eanimal = Events(strcmp(Events.animal, animalID), :);
    if isempty(Eanimal)
        fprintf('\n%s: no candidate ripple events found. Skipping.\n', animalID);
        continue;
    end

    fprintf('\nProcessing %s ...\n', animalID);

    %% Unit indices and spike times by epoch

    unitIndices = [];
    if isfield(R, 'spEpochSep')
        try
            unitIndices = (1:size(R.spEpochSep,1))';
        catch
            unitIndices = [];
        end
    end
    if isempty(unitIndices) && isfield(R, 'spAll')
        try
            unitIndices = (1:numel(R.spAll))';
        catch
            unitIndices = [];
        end
    end
    if isempty(unitIndices)
        fprintf('  No unit structure found. Skipping.\n');
        continue;
    end

    nUnits = numel(unitIndices);

    %% Get or infer place-field position for each unit

    pfPos = nan(nUnits,1);
    pfSource = cell(nUnits,1);

    % First try optional metadata table.
    if ~isempty(UnitMeta)
        umVars = UnitMeta.Properties.VariableNames;
        umAnimalCol = '';
        if any(strcmp(umVars, 'animal')); umAnimalCol = 'animal'; end

        umUnitCol = '';
        for c = {'unitIndex','unit','unit_id','cellIndex','cellID'}
            if any(strcmp(umVars, c{1}))
                umUnitCol = c{1};
                break;
            end
        end

        umPfCol = '';
        for c = {'placeFieldPeakCm','placeFieldPeakPosition','placeFieldPeak','novelPlaceFieldPeakCm','fieldPeakCm','pfPeakCm','peakPositionCm','fieldPosition'}
            if any(strcmp(umVars, c{1}))
                umPfCol = c{1};
                break;
            end
        end

        if ~isempty(umAnimalCol) && ~isempty(umUnitCol) && ~isempty(umPfCol)
            for uu = 1:nUnits
                unitIdx = unitIndices(uu);
                try
                    mask = string(UnitMeta.(umAnimalCol)) == string(animalID) & double(UnitMeta.(umUnitCol)) == double(unitIdx);
                    vals = double(UnitMeta.(umPfCol)(mask));
                    vals = vals(isfinite(vals));
                    if ~isempty(vals)
                        pfPos(uu) = vals(1);
                        pfSource{uu} = ['metadata:' umPfCol];
                    end
                catch
                end
            end
        end
    end

    % If metadata is missing, infer field position from Run1 spikes and linearised position.
    needInfer = ~isfinite(pfPos);

    posT = [];
    posLin = [];
    if any(needInfer)
        try
            posU = R.posMazeLin(1);
            posData = double(posU.data);
            posT = posData(:,1);
            posLin = posData(:,2);

            % Convert to cm if possible.
            if isfield(posU, 'unitsPerCm') && isfinite(posU.unitsPerCm) && posU.unitsPerCm ~= 0
                posLin = posLin ./ posU.unitsPerCm;
            end
        catch
            posT = [];
            posLin = [];
        end
    end

    if ~isempty(posT)
        for uu = 1:nUnits
            if isfinite(pfPos(uu)); continue; end
            unitIdx = unitIndices(uu);
            spRun = [];

            try
                if isfield(R, 'spEpochSep') && size(R.spEpochSep,1) >= unitIdx && size(R.spEpochSep,2) >= 2
                    if isfield(R.spEpochSep, 'timeStamps')
                        spRun = double(R.spEpochSep(unitIdx,2).timeStamps(:));
                    elseif isfield(R.spEpochSep, 'timestamps')
                        spRun = double(R.spEpochSep(unitIdx,2).timestamps(:));
                    elseif isfield(R.spEpochSep, 'times')
                        spRun = double(R.spEpochSep(unitIdx,2).times(:));
                    elseif isfield(R.spEpochSep, 'time')
                        spRun = double(R.spEpochSep(unitIdx,2).time(:));
                    end
                end
            catch
                spRun = [];
            end

            if isempty(spRun)
                continue;
            end

            spRun = spRun(isfinite(spRun));
            if numel(spRun) < 3
                continue;
            end

            spPos = interp1(posT, posLin, spRun, 'linear', NaN);
            spPos = spPos(isfinite(spPos));
            if numel(spPos) >= 3
                pfPos(uu) = median(spPos);
                pfSource{uu} = 'inferred_median_Run1_spike_position';
            end
        end
    end

    hasPf = isfinite(pfPos);
    if sum(hasPf) < minUnitsForScore
        fprintf('  Fewer than %d units with place-field/order positions. Skipping.\n', minUnitsForScore);
        continue;
    end

    [~, sortOrderLocal] = sort(pfPos(hasPf), 'ascend');
    localValidIdx = find(hasPf);
    sortedLocalIdx = localValidIdx(sortOrderLocal);
    sortedUnitIndices = unitIndices(sortedLocalIdx);
    sortedPfPos = pfPos(sortedLocalIdx);

    for kk = 1:numel(sortedUnitIndices)
        unitOrderRows(end+1,:) = {animalID, sortedUnitIndices(kk), kk, sortedPfPos(kk), pfSource{sortedLocalIdx(kk)}}; %#ok<SAGROW>
    end

    %% Resolve CSC file

    cscFile = '';
    if strcmp(animalID, 'ANM00190422')
        cscFile = fullfile(rootDir, 'csc_files', 'ANM00190422', '2012-12-09_10-48-47', 'CSC33.ncs');
    elseif strcmp(animalID, 'ANM204878')
        cscFile = fullfile(rootDir, 'csc_files', 'ANM204878', '2013-05-11_09-32-49', 'CSC33.ncs');
    elseif strcmp(animalID, 'ANM212379')
        cscFile = fullfile(rootDir, 'csc_files', 'ANM212379', '2013-06-08_10-10-46', 'CSC53.ncs');
    elseif strcmp(animalID, 'ANM228899')
        cscFile = fullfile(rootDir, 'csc_files', 'ANM228899', '2013-11-02_10-16-53', 'CSC45.ncs');
    elseif strcmp(animalID, 'ANM228900')
        cscFile = fullfile(rootDir, 'csc_files', 'ANM228900', '2013-11-03_08-59-40', 'CSC45.ncs');
    end

    if exist(cscFile, 'file') ~= 2
        [f,p] = uigetfile('*.ncs', ['Select CSC file for ' animalID]);
        if isequal(f,0)
            fprintf('  No CSC selected. Skipping LFP plotting but still scoring from spikes.\n');
            cscFile = '';
        else
            cscFile = fullfile(p,f);
        end
    end

    %% Epoch loop: score events

    epochsThisAnimal = intersect(epochLabelsWanted, unique(Eanimal.epoch, 'stable'));

    for ee = 1:numel(epochsThisAnimal)

        epochLabel = epochsThisAnimal{ee};
        if ~isfield(spEpochMap, epochLabel); continue; end
        epochIdx = spEpochMap.(epochLabel);

        E = Eanimal(strcmp(Eanimal.epoch, epochLabel), :);
        if isempty(E); continue; end

        fprintf('  Scoring %s candidate events (%d events)...\n', epochLabel, height(E));

        % Spike cell for sorted units in this epoch.
        spCell = cell(numel(sortedUnitIndices), 1);
        for uu = 1:numel(sortedUnitIndices)
            unitIdx = sortedUnitIndices(uu);
            sp = [];

            try
                if isfield(R, 'spEpochSep') && size(R.spEpochSep,1) >= unitIdx && size(R.spEpochSep,2) >= epochIdx
                    if isfield(R.spEpochSep, 'timeStamps')
                        sp = double(R.spEpochSep(unitIdx, epochIdx).timeStamps(:));
                    elseif isfield(R.spEpochSep, 'timestamps')
                        sp = double(R.spEpochSep(unitIdx, epochIdx).timestamps(:));
                    elseif isfield(R.spEpochSep, 'times')
                        sp = double(R.spEpochSep(unitIdx, epochIdx).times(:));
                    elseif isfield(R.spEpochSep, 'time')
                        sp = double(R.spEpochSep(unitIdx, epochIdx).time(:));
                    end
                end
            catch
                sp = [];
            end

            if isempty(sp) && strcmp(epochLabel, 'Run1Awake')
                try
                    if isfield(R, 'spAll') && numel(R.spAll) >= unitIdx
                        if isfield(R.spAll, 'timeStamps')
                            sp = double(R.spAll(unitIdx).timeStamps(:));
                        elseif isfield(R.spAll, 'timestamps')
                            sp = double(R.spAll(unitIdx).timestamps(:));
                        elseif isfield(R.spAll, 'times')
                            sp = double(R.spAll(unitIdx).times(:));
                        elseif isfield(R.spAll, 'time')
                            sp = double(R.spAll(unitIdx).time(:));
                        end
                    end
                catch
                    sp = [];
                end
            end

            sp = sp(isfinite(sp));
            spCell{uu} = sort(sp(:));
        end

        epochScores = nan(height(E),1);
        epochP = nan(height(E),1);
        epochNSpikes = zeros(height(E),1);
        epochNUnits = zeros(height(E),1);
        epochDirection = cell(height(E),1);

        for ev = 1:height(E)
            t0 = E.peakUs(ev);
            wStart = E.startUs(ev);
            wEnd = E.endUs(ev);

            relTimes = [];
            relPf = [];
            relOrder = [];

            for uu = 1:numel(spCell)
                sp = spCell{uu};
                if isempty(sp); continue; end
                spEv = sp(sp >= wStart & sp <= wEnd);
                if isempty(spEv); continue; end

                relTimes = [relTimes; (spEv(:)-t0)./1e6]; %#ok<AGROW>
                relPf = [relPf; repmat(sortedPfPos(uu), numel(spEv), 1)]; %#ok<AGROW>
                relOrder = [relOrder; repmat(uu, numel(spEv), 1)]; %#ok<AGROW>
            end

            nSp = numel(relTimes);
            nU = numel(unique(relOrder));
            epochNSpikes(ev) = nSp;
            epochNUnits(ev) = nU;

            if nSp >= minSpikesForScore && nU >= minUnitsForScore && numel(unique(relTimes)) > 1 && numel(unique(relPf)) > 1
                C = corrcoef(relTimes, relPf);
                rVal = C(1,2);
                epochScores(ev) = rVal;

                % Approximate correlation p-value.
                df = nSp - 2;
                if df > 0 && abs(rVal) < 1
                    tstat = rVal * sqrt(df / max(1-rVal^2, eps));
                    pVal = 2 * (1 - tcdf(abs(tstat), df));
                else
                    pVal = NaN;
                end
                epochP(ev) = pVal;

                if rVal > 0
                    epochDirection{ev} = 'forward_like';
                elseif rVal < 0
                    epochDirection{ev} = 'reverse_like';
                else
                    epochDirection{ev} = 'flat';
                end
            else
                epochDirection{ev} = 'insufficient_spikes';
            end

            eventScoreRows(end+1,:) = {animalID, epochLabel, ev, E.startUs(ev), E.endUs(ev), E.peakUs(ev), ...
                epochNSpikes(ev), epochNUnits(ev), epochScores(ev), epochP(ev), epochDirection{ev}, E.sourceTable{ev}}; %#ok<SAGROW>
        end

        validScore = isfinite(epochScores);
        if any(validScore)
            summaryRows(end+1,:) = {animalID, epochLabel, height(E), sum(validScore), ...
                mean(epochScores(validScore)), median(epochScores(validScore)), ...
                mean(epochScores(validScore) > 0), mean(epochScores(validScore) < 0), ...
                mean(abs(epochScores(validScore))), ...
                sum(epochScores(validScore) > 0), sum(epochScores(validScore) < 0)}; %#ok<SAGROW>
        else
            summaryRows(end+1,:) = {animalID, epochLabel, height(E), 0, NaN, NaN, NaN, NaN, NaN, 0, 0}; %#ok<SAGROW>
        end

        %% Load epoch LFP for example plots
        haveLFP = false;
        tDsUs = [];
        lfpDs = [];
        rippleFilt = [];

        if ~isempty(cscFile)
            tStartUs = min(E.startUs) - plotWindowSec*1e6;
            tEndUs = max(E.endUs) + plotWindowSec*1e6;
            try
                [tRec, vRec, header] = Nlx2MatCSC(cscFile, [1 0 0 0 1], 1, 4, [tStartUs tEndUs]);

                tRec = double(tRec(:));
                vRec = double(vRec);
                vallRaw = double(vRec(:));

                try
                    H = readNlxHeader(header);
                catch
                    H = struct();
                end

                tDiff = diff(tRec);
                mtDiff = mode(tDiff);
                noSkip = tDiff > mtDiff-2 & tDiff < mtDiff+2;

                if all(noSkip)
                    FsRaw = 1/(mean(tDiff)/512/1e6);
                    tallUs = linspace(tRec(1), tRec(end) + (511*(1/FsRaw)*1e6), numel(vallRaw))';
                    vall = vallRaw;
                else
                    FsRaw = 1/(mean(tDiff(noSkip))/512/1e6);
                    tVec = (tRec(1):((1/FsRaw)*1e6):(tRec(end)+(512*(1/FsRaw)*1e6)))';
                    vVec = nan(numel(tVec),1);
                    p = 1;
                    for rr = 1:size(vRec,2)
                        while p <= numel(tVec) && ~(abs(tRec(rr)-tVec(p)) < 2)
                            p = p + 1;
                        end
                        if p + 511 <= numel(vVec)
                            vVec(p:p+511) = vRec(:,rr);
                        end
                        p = p + 512;
                    end
                    tallUs = tVec;
                    vall = vVec;
                end

                if isfield(H, 'ADBitVolts')
                    lfp = vall .* H.ADBitVolts .* 1e6; % microvolts
                else
                    lfp = vall;
                end

                validRaw = isfinite(lfp);
                if any(validRaw)
                    fillValue = median(lfp(validRaw));
                else
                    fillValue = 0;
                end
                lfpFilled = lfp;
                lfpFilled(~validRaw) = fillValue;

                factor = max(1, round(FsRaw / targetFs));
                FsDs = FsRaw / factor;

                if factor > 1
                    try
                        lfpDs = decimate(lfpFilled, factor);
                    catch
                        lfpDs = lfpFilled(1:factor:end);
                    end
                    tDsUs = tallUs(1:factor:end);
                else
                    lfpDs = lfpFilled;
                    tDsUs = tallUs;
                end

                n = min(numel(lfpDs), numel(tDsUs));
                lfpDs = double(lfpDs(1:n));
                tDsUs = double(tDsUs(1:n));

                if rippleHighHz < FsDs/2
                    [bRip, aRip] = butter(filterOrder, [rippleLowHz rippleHighHz] ./ (FsDs/2), 'bandpass');
                    rippleFilt = filtfilt(bRip, aRip, lfpDs);
                    haveLFP = true;
                end
            catch ME
                fprintf('    Could not load/filter LFP for %s %s examples: %s\n', animalID, epochLabel, ME.message);
                haveLFP = false;
            end
        end

        %% Pick and plot examples: strongest forward-like and reverse-like

        validIdx = find(isfinite(epochScores));
        if isempty(validIdx)
            fprintf('    No scorable %s events for %s.\n', epochLabel, animalID);
            continue;
        end

        [~, posOrder] = sort(epochScores(validIdx), 'descend');
        [~, negOrder] = sort(epochScores(validIdx), 'ascend');

        exampleIdx = [];
        exampleLabels = {};

        for k = 1:min(maxExampleEventsPerAnimalEpoch, numel(posOrder))
            exampleIdx(end+1) = validIdx(posOrder(k)); %#ok<SAGROW>
            exampleLabels{end+1} = 'forward_like'; %#ok<SAGROW>
        end
        for k = 1:min(maxExampleEventsPerAnimalEpoch, numel(negOrder))
            exampleIdx(end+1) = validIdx(negOrder(k)); %#ok<SAGROW>
            exampleLabels{end+1} = 'reverse_like'; %#ok<SAGROW>
        end

        for ex = 1:numel(exampleIdx)

            ev = exampleIdx(ex);
            t0 = E.peakUs(ev);
            pStart = t0 - plotWindowSec*1e6;
            pEnd = t0 + plotWindowSec*1e6;

            fig = figure('Color','w', 'Position', [100 80 950 900], ...
                'Name', sprintf('%s %s event %d %s', animalID, epochLabel, ev, exampleLabels{ex}));

            % Raw LFP
            subplot(4,1,1);
            if haveLFP
                seg = tDsUs >= pStart & tDsUs <= pEnd;
                plot((tDsUs(seg)-t0)./1e3, lfpDs(seg), 'k');
                hold on;
                yl = ylim;
                line([0 0], yl, 'Color','r', 'LineStyle','--');
                line([(E.startUs(ev)-t0)/1e3 (E.startUs(ev)-t0)/1e3], yl, 'Color',[0.5 0.5 0.5], 'LineStyle',':');
                line([(E.endUs(ev)-t0)/1e3 (E.endUs(ev)-t0)/1e3], yl, 'Color',[0.5 0.5 0.5], 'LineStyle',':');
                hold off;
            else
                text(0.5,0.5,'LFP unavailable','HorizontalAlignment','center');
                axis off;
            end
            ylabel('Raw LFP');
            title(sprintf('%s %s candidate ripple event %d: %s, r = %.3f, p = %.3g', ...
                animalID, epochLabel, ev, exampleLabels{ex}, epochScores(ev), epochP(ev)), 'Interpreter','none');
            grid on;

            % Ripple-filtered LFP
            subplot(4,1,2);
            if haveLFP
                seg = tDsUs >= pStart & tDsUs <= pEnd;
                plot((tDsUs(seg)-t0)./1e3, rippleFilt(seg), 'k');
                hold on;
                yl = ylim;
                line([0 0], yl, 'Color','r', 'LineStyle','--');
                line([(E.startUs(ev)-t0)/1e3 (E.startUs(ev)-t0)/1e3], yl, 'Color',[0.5 0.5 0.5], 'LineStyle',':');
                line([(E.endUs(ev)-t0)/1e3 (E.endUs(ev)-t0)/1e3], yl, 'Color',[0.5 0.5 0.5], 'LineStyle',':');
                hold off;
            else
                text(0.5,0.5,'Ripple-filtered LFP unavailable','HorizontalAlignment','center');
                axis off;
            end
            ylabel('Ripple filt.');
            grid on;

            % Sorted raster
            subplot(4,1,[3 4]);
            hold on;
            for uu = 1:numel(spCell)
                sp = spCell{uu};
                if isempty(sp); continue; end
                spPlot = sp(sp >= pStart & sp <= pEnd);
                if isempty(spPlot); continue; end
                xMs = (spPlot - t0)./1e3;
                y = repmat(uu, size(xMs));
                plot(xMs, y, 'k.', 'MarkerSize', 8);
            end

            yl = [0 numel(spCell)+1];
            ylim(yl);
            line([0 0], yl, 'Color','r', 'LineStyle','--');
            line([(E.startUs(ev)-t0)/1e3 (E.startUs(ev)-t0)/1e3], yl, 'Color',[0.5 0.5 0.5], 'LineStyle',':');
            line([(E.endUs(ev)-t0)/1e3 (E.endUs(ev)-t0)/1e3], yl, 'Color',[0.5 0.5 0.5], 'LineStyle',':');
            xlabel('Time from candidate ripple peak (ms)');
            ylabel('Units sorted by place-field position');
            title(sprintf('Sorted raster: %d spikes, %d units; bottom = early field, top = late field', ...
                epochNSpikes(ev), epochNUnits(ev)));
            grid on;
            hold off;

            figFile = fullfile(figDir, sprintf('%s_%s_event%04d_%s_sorted_replay_raster.png', ...
                animalID, epochLabel, ev, exampleLabels{ex}));
            print(fig, figFile, '-dpng', '-r200');
            close(fig);

            fprintf('    Saved example raster:\n      %s\n', figFile);
        end
    end
end

%% Save CSV outputs

if ~isempty(unitOrderRows)
    UnitOrder = cell2table(unitOrderRows, 'VariableNames', ...
        {'animal','unitIndex','placeFieldSortOrder','placeFieldPosition','placeFieldSource'});
    writetable(UnitOrder, fullfile(outDir, 'hc31_batch11F_unit_placefield_order.csv'));
else
    UnitOrder = table();
end

if ~isempty(eventScoreRows)
    EventScores = cell2table(eventScoreRows, 'VariableNames', ...
        {'animal','epoch','eventIndex','eventStartUs','eventEndUs','eventPeakUs','nSpikes','nUnits','timePositionCorrelation','correlationP','sequenceDirection','sourceTable'});
    writetable(EventScores, fullfile(outDir, 'hc31_batch11F_candidate_ripple_sequence_scores.csv'));
else
    EventScores = table();
end

if ~isempty(summaryRows)
    Summary = cell2table(summaryRows, 'VariableNames', ...
        {'animal','epoch','nEvents','nScorableEvents','meanCorrelation','medianCorrelation','fractionForwardLike','fractionReverseLike','meanAbsCorrelation','nForwardLike','nReverseLike'});
    writetable(Summary, fullfile(outDir, 'hc31_batch11F_sequence_summary.csv'));
else
    Summary = table();
end

%% Group summary figures

if ~isempty(Summary)
    epochsPresent = intersect(epochLabelsWanted, unique(Summary.epoch, 'stable'));

    fig1 = figure('Color','w', 'Position', [120 120 950 450]);
    x = 1:numel(epochsPresent);
    means = nan(size(x));
    sems = nan(size(x));
    for ee = 1:numel(epochsPresent)
        vals = Summary.meanAbsCorrelation(strcmp(Summary.epoch, epochsPresent{ee}));
        means(ee) = mean(vals, 'omitnan');
        sems(ee) = std(vals, 'omitnan') / max(sqrt(sum(isfinite(vals))),1);
    end
    errorbar(x, means, sems, 'ko-', 'LineWidth', 2, 'MarkerFaceColor','k');
    xlim([0.75 numel(x)+0.25]);
    xticks(x);
    xticklabels(epochsPresent);
    ylabel('Mean |time-position correlation|');
    xlabel('Epoch');
    title('Replay-style sequence strength by epoch');
    grid on;
    print(fig1, fullfile(figDir, 'group_replay_style_sequence_strength_by_epoch.png'), '-dpng', '-r200');
    close(fig1);

    fig2 = figure('Color','w', 'Position', [140 140 950 450]);
    fwd = nan(size(x));
    rev = nan(size(x));
    for ee = 1:numel(epochsPresent)
        fwdVals = Summary.fractionForwardLike(strcmp(Summary.epoch, epochsPresent{ee}));
        revVals = Summary.fractionReverseLike(strcmp(Summary.epoch, epochsPresent{ee}));
        fwd(ee) = mean(fwdVals, 'omitnan');
        rev(ee) = mean(revVals, 'omitnan');
    end
    bar(x, [fwd(:) rev(:)], 'grouped');
    xlim([0.5 numel(x)+0.5]);
    xticks(x);
    xticklabels(epochsPresent);
    ylabel('Fraction of scorable events');
    xlabel('Epoch');
    title('Forward-like versus reverse-like candidate ripple sequences');
    legend({'forward-like','reverse-like'}, 'Location','best');
    grid on;
    print(fig2, fullfile(figDir, 'group_forward_reverse_fraction_by_epoch.png'), '-dpng', '-r200');
    close(fig2);
end

%% Write summary text

summaryTxt = fullfile(outDir, 'hc31_batch11F_summary.txt');
fid = fopen(summaryTxt, 'w');
fprintf(fid, 'HC-31 Batch 11F: replay-style sorted ripple rasters\n');
fprintf(fid, '====================================================\n\n');
fprintf(fid, 'What this batch does\n');
fprintf(fid, '- Sorts CA1 units by place-field position.\n');
fprintf(fid, '- Plots candidate ripple spike rasters using that place-field order.\n');
fprintf(fid, '- Scores each candidate ripple using corr(spike time, place-field position).\n');
fprintf(fid, '- Positive correlations are forward-like; negative correlations are reverse-like.\n\n');
fprintf(fid, 'Main output files\n');
fprintf(fid, '- hc31_batch11F_unit_placefield_order.csv\n');
fprintf(fid, '- hc31_batch11F_candidate_ripple_sequence_scores.csv\n');
fprintf(fid, '- hc31_batch11F_sequence_summary.csv\n');
fprintf(fid, '- figures/*sorted_replay_raster.png\n');
fprintf(fid, '- figures/group_replay_style_sequence_strength_by_epoch.png\n');
fprintf(fid, '- figures/group_forward_reverse_fraction_by_epoch.png\n\n');
fprintf(fid, 'Important caution\n');
fprintf(fid, 'This is an exploratory replay-style screen, not a full Bayesian replay decoder.\n');
fprintf(fid, 'It is useful for identifying example events and asking whether place-field ordered spike sequences appear around candidate ripples.\n');
fclose(fid);

fprintf('\nSaved output folder:\n  %s\n', outDir);
fprintf('Saved summary text:\n  %s\n', summaryTxt);
fprintf('\nBatch 11F complete.\n');
