%% HC-31 Batch 11K: blinded candidate-ripple manual QC pack
%
% Plain script version. No local functions.
%
% Purpose:
%   Build a reproducible, blinded manual-review pack for the current candidate
%   ripple detections before any further detector optimisation, reactivation,
%   or replay analysis.
%
% The batch:
%   1. combines PRE/REST/POST candidate events from Batch 10 with optional
%      Run1-awake candidates from Batch 9;
%   2. samples events reproducibly across animal, epoch, detector peak-z range,
%      and current artefact-flag status;
%   3. assigns anonymous Blind IDs and hides animal/epoch information from the
%      review figures;
%   4. creates one multi-panel QC figure per selected event;
%   5. writes a blank manual-review CSV and a separate unblinding key;
%   6. extracts morphology features for use in Batch 11L detector optimisation.
%
% Each blinded review figure attempts to show:
%   - raw wide-band LFP;
%   - 1-30 Hz sharp-wave-range LFP;
%   - 120-250 Hz ripple-filtered LFP;
%   - local robust ripple-envelope z-score and detector boundaries;
%   - event-centred spectrogram;
%   - movement speed where Run1 tracking is available;
%   - local theta/delta ratio;
%   - CA1 spike raster;
%   - population spike histogram.
%
% Required:
%   - resSave.mat
%   - csc_files folder with raw Neuralynx .ncs files
%   - neuralynximport folder containing Nlx2MatCSC/readNlxHeader
%   - hc31_batch10_candidate_sleep_ripples.csv OR an equivalent PRE/REST table
%
% Optional:
%   - hc31_batch9_candidate_awake_ripples.csv
%
% Important interpretation boundary:
%   This batch does not decide whether events are true physiological SWRs.
%   It creates the blinded material needed for that decision.
%
% Recommended MATLAB workaround:
%
%   clear; clc; close all; rehash;
%   [scriptFile, scriptFolder] = uigetfile('*.m', ...
%       'Select hc31_batch11K_candidate_ripple_manual_QC_PLAIN_SCRIPT.m');
%   cd(scriptFolder);
%   txt = fileread(fullfile(scriptFolder, scriptFile));
%   eval(txt);

clear; clc; close all; rehash;

fprintf('\nHC-31 Batch 11K: blinded candidate-ripple manual QC pack\n');
fprintf('----------------------------------------------------------\n');

%% User-editable settings

defaultRoot = getenv('HC31_DATA_ROOT');

animalIndices = 5:9;
fallbackAnimalIDs = {'ANM00190422','ANM204878','ANM212379','ANM228899','ANM228900'};

% Sampling design. Fifteen events per available animal/epoch gives up to
% approximately 45-60 reviewed events per animal when PRE, REST, POST and
% Run1-awake are all available.
nReviewPerAnimalEpoch = 15;
maxArtifactFlaggedPerAnimalEpoch = 2;
rngSeed = 11011;

% LFP and figure settings.
targetFs = 1000;                 % ripple 120-250 Hz remains below Nyquist
loadHalfWindowSec = 12;          % LFP loaded around each event for local baselines
figureHalfWindowSec = 1.5;       % visible time range
spectrogramHalfWindowSec = 0.75;
rasterHalfWindowSec = 0.50;
populationBinSec = 0.010;

sharpWaveLowHz = 1;
sharpWaveHighHz = 30;
rippleLowHz = 120;
rippleHighHz = 250;
thetaLowHz = 6;
thetaHighHz = 10;
deltaLowHz = 1;
deltaHighHz = 4;
filterOrder = 4;

% Current detector thresholds are shown only as reference guides. The plotted
% envelope z-score is recomputed from a local robust baseline around each event.
rippleBoundaryZReference = 2;
ripplePeakZReference = 3;
artefactPeakZReference = 12;
lowSpeedThresholdCmS = 5;

% Morphology windows.
sharpWaveFeatureHalfWindowSec = 0.10;
spectralFeatureHalfWindowSec = 0.10;

saveDpi = 180;

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

%% Locate candidate-ripple tables

sleepRippleCsv = '';
sleepCandidates = { ...
    fullfile(rootDir, 'hc31_batch10_sleep_replay_memory_link_FORCE_V2', 'hc31_batch10_candidate_sleep_ripples.csv'), ...
    fullfile(rootDir, 'allresults', 'hc31_batch10_sleep_replay_memory_link_FORCE_V2', 'hc31_batch10_candidate_sleep_ripples.csv'), ...
    fullfile(rootDir, 'hc31_batch10_sleep_replay_memory_link_FORCE', 'hc31_batch10_candidate_sleep_ripples.csv'), ...
    fullfile(rootDir, 'allresults', 'hc31_batch10_sleep_replay_memory_link_FORCE', 'hc31_batch10_candidate_sleep_ripples.csv'), ...
    fullfile(rootDir, 'hc31_batch10_candidate_sleep_ripples.csv'), ...
    fullfile(rootDir, 'candidate_sleep_ripples.csv') ...
    };

for q = 1:numel(sleepCandidates)
    if exist(sleepCandidates{q}, 'file') == 2
        sleepRippleCsv = sleepCandidates{q};
        break;
    end
end

if isempty(sleepRippleCsv)
    [f,p] = uigetfile('*.csv', ...
        'Select hc31_batch10_candidate_sleep_ripples.csv, or Cancel if unavailable');
    if ~isequal(f,0)
        sleepRippleCsv = fullfile(p,f);
    end
end

awakeRippleCsv = '';
awakeCandidates = { ...
    fullfile(rootDir, 'hc31_batch9_awake_ripples_beta_relationship_FORCE', 'hc31_batch9_candidate_awake_ripples.csv'), ...
    fullfile(rootDir, 'allresults', 'hc31_batch9_awake_ripples_beta_relationship_FORCE', 'hc31_batch9_candidate_awake_ripples.csv'), ...
    fullfile(rootDir, 'hc31_batch9_candidate_awake_ripples.csv'), ...
    fullfile(rootDir, 'candidate_awake_ripples.csv') ...
    };

for q = 1:numel(awakeCandidates)
    if exist(awakeCandidates{q}, 'file') == 2
        awakeRippleCsv = awakeCandidates{q};
        break;
    end
end

if isempty(awakeRippleCsv)
    [f,p] = uigetfile('*.csv', ...
        'Optional: select hc31_batch9_candidate_awake_ripples.csv, or Cancel');
    if ~isequal(f,0)
        awakeRippleCsv = fullfile(p,f);
    end
end

if isempty(sleepRippleCsv) && isempty(awakeRippleCsv)
    error('No candidate-ripple table was selected or found.');
end

if ~isempty(sleepRippleCsv)
    SleepT = readtable(sleepRippleCsv);
    fprintf('\nUsing sleep/rest candidate table:\n  %s\n', sleepRippleCsv);
else
    SleepT = table();
    fprintf('\nNo sleep/rest candidate table selected. PRE/REST/POST will be skipped.\n');
end

if ~isempty(awakeRippleCsv)
    AwakeT = readtable(awakeRippleCsv);
    fprintf('Using awake candidate table:\n  %s\n', awakeRippleCsv);
else
    AwakeT = table();
    fprintf('No awake candidate table selected. Run1Awake will be skipped.\n');
end

%% Build animal-name to resSave-index map

animalMapNames = fallbackAnimalIDs(:);
animalMapIndices = animalIndices(:);

for ai = 1:numel(animalIndices)
    idx = animalIndices(ai);
    if idx > numel(resSave)
        continue;
    end
    R = resSave(idx);
    resolvedName = fallbackAnimalIDs{ai};
    try
        if isfield(R, 'spAll') && ~isempty(R.spAll) && isfield(R.spAll, 'animal')
            resolvedName = strtrim(char(R.spAll(1).animal));
        elseif isfield(R, 'animal')
            resolvedName = strtrim(char(R.animal));
        elseif isfield(R, 'name')
            resolvedName = strtrim(char(R.name));
        end
    catch
    end
    animalMapNames{ai} = resolvedName;
end

%% Standardise sleep/rest candidate events

allRows = {};
allHeader = {'animal','resSaveIndex','epoch','startUs','endUs','peakUs', ...
    'detectorPeakZ','durationS','peakSpeedCmS','currentArtifactFlag', ...
    'sourceTable','sourceRow'};

if ~isempty(SleepT)
    vars = SleepT.Properties.VariableNames;

    animalCol = '';
    for c = {'animal','animalID','animal_id','rat','subject'}
        hit = find(strcmpi(vars, c{1}), 1);
        if ~isempty(hit); animalCol = vars{hit}; break; end
    end

    indexCol = '';
    for c = {'resSaveIndex','res_save_index','resIndex','index'}
        hit = find(strcmpi(vars, c{1}), 1);
        if ~isempty(hit); indexCol = vars{hit}; break; end
    end

    epochCol = '';
    for c = {'epoch','epochName','epoch_name','state','session','epoch_label'}
        hit = find(strcmpi(vars, c{1}), 1);
        if ~isempty(hit); epochCol = vars{hit}; break; end
    end

    peakCol = '';
    for c = {'peakUs','ripplePeakUs','eventPeakUs','peakTimeUs','peak_time_us'}
        hit = find(strcmpi(vars, c{1}), 1);
        if ~isempty(hit); peakCol = vars{hit}; break; end
    end

    startCol = '';
    for c = {'startUs','rippleStartUs','eventStartUs','startTimeUs','start_time_us'}
        hit = find(strcmpi(vars, c{1}), 1);
        if ~isempty(hit); startCol = vars{hit}; break; end
    end

    endCol = '';
    for c = {'endUs','rippleEndUs','eventEndUs','endTimeUs','end_time_us'}
        hit = find(strcmpi(vars, c{1}), 1);
        if ~isempty(hit); endCol = vars{hit}; break; end
    end

    peakZCol = '';
    for c = {'peakZ','ripplePeakZ','peakEnvelopeZ','peak_z'}
        hit = find(strcmpi(vars, c{1}), 1);
        if ~isempty(hit); peakZCol = vars{hit}; break; end
    end

    durationCol = '';
    for c = {'durationS','durationSec','durationSeconds','duration_s'}
        hit = find(strcmpi(vars, c{1}), 1);
        if ~isempty(hit); durationCol = vars{hit}; break; end
    end

    speedCol = '';
    for c = {'peakSpeedCmS','speedCmS','peakSpeed','speed_at_peak'}
        hit = find(strcmpi(vars, c{1}), 1);
        if ~isempty(hit); speedCol = vars{hit}; break; end
    end

    artifactCol = '';
    for c = {'isArtifactLike','excludedAsArtifact','isArtifact','artifactLike','isArtefactLike','excludedAsArtefact'}
        hit = find(strcmpi(vars, c{1}), 1);
        if ~isempty(hit); artifactCol = vars{hit}; break; end
    end

    if isempty(animalCol) || isempty(peakCol)
        fprintf('Available sleep/rest table columns:\n');
        disp(vars');
        error('Could not identify animal and candidate-ripple peak columns in the sleep/rest table.');
    end

    for rr = 1:height(SleepT)
        animalVal = SleepT.(animalCol)(rr,:);
        if iscell(animalVal); animalVal = animalVal{1}; end
        if isstring(animalVal); animalVal = char(animalVal); end
        animalVal = strtrim(char(animalVal));

        resIdx = NaN;
        if ~isempty(indexCol)
            try; resIdx = double(SleepT.(indexCol)(rr)); catch; resIdx = NaN; end
        end
        if ~isfinite(resIdx)
            hit = find(strcmp(animalMapNames, animalVal), 1);
            if ~isempty(hit); resIdx = animalMapIndices(hit); end
        end

        epochVal = 'PRE';
        if ~isempty(epochCol)
            tmp = SleepT.(epochCol)(rr,:);
            if iscell(tmp); tmp = tmp{1}; end
            if isstring(tmp); tmp = char(tmp); end
            tmp = lower(strtrim(char(tmp)));
            if contains(tmp, 'pre')
                epochVal = 'PRE';
            elseif contains(tmp, 'rest')
                epochVal = 'REST';
            elseif contains(tmp, 'post')
                epochVal = 'POST';
            elseif contains(tmp, 'run1') || contains(tmp, 'awake')
                epochVal = 'Run1Awake';
            else
                epochVal = '';
            end
        end
        if isempty(epochVal)
            continue;
        end

        peakUs = double(SleepT.(peakCol)(rr));
        if abs(peakUs) < 1e6; peakUs = peakUs * 1e6; end

        if ~isempty(startCol)
            startUs = double(SleepT.(startCol)(rr));
            if abs(startUs) < 1e6; startUs = startUs * 1e6; end
        else
            startUs = peakUs - 0.050e6;
        end

        if ~isempty(endCol)
            endUs = double(SleepT.(endCol)(rr));
            if abs(endUs) < 1e6; endUs = endUs * 1e6; end
        else
            endUs = peakUs + 0.050e6;
        end

        peakZ = NaN;
        if ~isempty(peakZCol)
            try; peakZ = double(SleepT.(peakZCol)(rr)); catch; peakZ = NaN; end
        end

        durationS = (endUs - startUs) / 1e6;
        if ~isempty(durationCol)
            try
                tmpDur = double(SleepT.(durationCol)(rr));
                if isfinite(tmpDur) && tmpDur > 0; durationS = tmpDur; end
            catch
            end
        end

        peakSpeed = NaN;
        if ~isempty(speedCol)
            try; peakSpeed = double(SleepT.(speedCol)(rr)); catch; peakSpeed = NaN; end
        end

        artifactFlag = false;
        if ~isempty(artifactCol)
            try
                av = SleepT.(artifactCol)(rr,:);
                if iscell(av); av = av{1}; end
                if islogical(av)
                    artifactFlag = logical(av);
                elseif isnumeric(av)
                    artifactFlag = double(av) ~= 0;
                else
                    avs = lower(strtrim(char(string(av))));
                    artifactFlag = any(strcmp(avs, {'true','1','yes','y'}));
                end
            catch
                artifactFlag = false;
            end
        end

        if isfinite(peakUs) && isfinite(startUs) && isfinite(endUs) && endUs > startUs
            allRows(end+1,:) = {animalVal, resIdx, epochVal, startUs, endUs, peakUs, ...
                peakZ, durationS, peakSpeed, artifactFlag, 'sleepRestTable', rr}; %#ok<SAGROW>
        end
    end
end

%% Standardise optional awake candidate events

if ~isempty(AwakeT)
    vars = AwakeT.Properties.VariableNames;

    animalCol = '';
    for c = {'animal','animalID','animal_id','rat','subject'}
        hit = find(strcmpi(vars, c{1}), 1);
        if ~isempty(hit); animalCol = vars{hit}; break; end
    end

    indexCol = '';
    for c = {'resSaveIndex','res_save_index','resIndex','index'}
        hit = find(strcmpi(vars, c{1}), 1);
        if ~isempty(hit); indexCol = vars{hit}; break; end
    end

    peakCol = '';
    for c = {'peakUs','ripplePeakUs','eventPeakUs','peakTimeUs','peak_time_us'}
        hit = find(strcmpi(vars, c{1}), 1);
        if ~isempty(hit); peakCol = vars{hit}; break; end
    end

    startCol = '';
    for c = {'startUs','rippleStartUs','eventStartUs','startTimeUs','start_time_us'}
        hit = find(strcmpi(vars, c{1}), 1);
        if ~isempty(hit); startCol = vars{hit}; break; end
    end

    endCol = '';
    for c = {'endUs','rippleEndUs','eventEndUs','endTimeUs','end_time_us'}
        hit = find(strcmpi(vars, c{1}), 1);
        if ~isempty(hit); endCol = vars{hit}; break; end
    end

    peakZCol = '';
    for c = {'peakZ','ripplePeakZ','peakEnvelopeZ','peak_z'}
        hit = find(strcmpi(vars, c{1}), 1);
        if ~isempty(hit); peakZCol = vars{hit}; break; end
    end

    durationCol = '';
    for c = {'durationS','durationSec','durationSeconds','duration_s'}
        hit = find(strcmpi(vars, c{1}), 1);
        if ~isempty(hit); durationCol = vars{hit}; break; end
    end

    speedCol = '';
    for c = {'peakSpeedCmS','speedCmS','peakSpeed','speed_at_peak'}
        hit = find(strcmpi(vars, c{1}), 1);
        if ~isempty(hit); speedCol = vars{hit}; break; end
    end

    artifactCol = '';
    for c = {'isArtifactLike','excludedAsArtifact','isArtifact','artifactLike','isArtefactLike','excludedAsArtefact'}
        hit = find(strcmpi(vars, c{1}), 1);
        if ~isempty(hit); artifactCol = vars{hit}; break; end
    end

    if isempty(animalCol) || isempty(peakCol)
        fprintf('Available awake table columns:\n');
        disp(vars');
        error('Could not identify animal and candidate-ripple peak columns in the awake table.');
    end

    for rr = 1:height(AwakeT)
        animalVal = AwakeT.(animalCol)(rr,:);
        if iscell(animalVal); animalVal = animalVal{1}; end
        if isstring(animalVal); animalVal = char(animalVal); end
        animalVal = strtrim(char(animalVal));

        resIdx = NaN;
        if ~isempty(indexCol)
            try; resIdx = double(AwakeT.(indexCol)(rr)); catch; resIdx = NaN; end
        end
        if ~isfinite(resIdx)
            hit = find(strcmp(animalMapNames, animalVal), 1);
            if ~isempty(hit); resIdx = animalMapIndices(hit); end
        end

        peakUs = double(AwakeT.(peakCol)(rr));
        if abs(peakUs) < 1e6; peakUs = peakUs * 1e6; end

        if ~isempty(startCol)
            startUs = double(AwakeT.(startCol)(rr));
            if abs(startUs) < 1e6; startUs = startUs * 1e6; end
        else
            startUs = peakUs - 0.050e6;
        end

        if ~isempty(endCol)
            endUs = double(AwakeT.(endCol)(rr));
            if abs(endUs) < 1e6; endUs = endUs * 1e6; end
        else
            endUs = peakUs + 0.050e6;
        end

        peakZ = NaN;
        if ~isempty(peakZCol)
            try; peakZ = double(AwakeT.(peakZCol)(rr)); catch; peakZ = NaN; end
        end

        durationS = (endUs - startUs) / 1e6;
        if ~isempty(durationCol)
            try
                tmpDur = double(AwakeT.(durationCol)(rr));
                if isfinite(tmpDur) && tmpDur > 0; durationS = tmpDur; end
            catch
            end
        end

        peakSpeed = NaN;
        if ~isempty(speedCol)
            try; peakSpeed = double(AwakeT.(speedCol)(rr)); catch; peakSpeed = NaN; end
        end

        artifactFlag = false;
        if ~isempty(artifactCol)
            try
                av = AwakeT.(artifactCol)(rr,:);
                if iscell(av); av = av{1}; end
                if islogical(av)
                    artifactFlag = logical(av);
                elseif isnumeric(av)
                    artifactFlag = double(av) ~= 0;
                else
                    avs = lower(strtrim(char(string(av))));
                    artifactFlag = any(strcmp(avs, {'true','1','yes','y'}));
                end
            catch
                artifactFlag = false;
            end
        end

        if isfinite(peakUs) && isfinite(startUs) && isfinite(endUs) && endUs > startUs
            allRows(end+1,:) = {animalVal, resIdx, 'Run1Awake', startUs, endUs, peakUs, ...
                peakZ, durationS, peakSpeed, artifactFlag, 'awakeTable', rr}; %#ok<SAGROW>
        end
    end
end

if isempty(allRows)
    error('No usable candidate-ripple events were found in the selected tables.');
end

AllEvents = cell2table(allRows, 'VariableNames', allHeader);

% Keep only analysed animals and remove duplicate entries with matching animal,
% epoch and peak timestamp. Duplicates can appear when an event was copied into
% more than one prior output table.
keepAnimal = false(height(AllEvents),1);
for rr = 1:height(AllEvents)
    keepAnimal(rr) = any(strcmp(animalMapNames, AllEvents.animal{rr}));
end
AllEvents = AllEvents(keepAnimal,:);

[~, uniqueIdx] = unique(strcat(AllEvents.animal, '|', AllEvents.epoch, '|', ...
    cellstr(string(round(AllEvents.peakUs)))), 'stable');
AllEvents = AllEvents(sort(uniqueIdx),:);

fprintf('\nUnified candidate table: %d events.\n', height(AllEvents));

%% Reproducible stratified sample

rng(rngSeed, 'twister');
selectedRows = [];
samplingRows = {};

for ai = 1:numel(animalMapNames)
    animalID = animalMapNames{ai};
    epochsForAnimal = {'PRE','REST','POST','Run1Awake'};

    for ee = 1:numel(epochsForAnimal)
        epochName = epochsForAnimal{ee};
        idx = find(strcmp(AllEvents.animal, animalID) & strcmp(AllEvents.epoch, epochName));
        nAvailable = numel(idx);
        if nAvailable == 0
            continue;
        end

        nTake = min(nReviewPerAnimalEpoch, nAvailable);
        idxArtifact = idx(logical(AllEvents.currentArtifactFlag(idx)));
        idxRegular = idx(~logical(AllEvents.currentArtifactFlag(idx)));

        nArtifactTake = min([maxArtifactFlaggedPerAnimalEpoch, numel(idxArtifact), nTake]);
        nRegularTake = nTake - nArtifactTake;

        chosen = [];

        if nRegularTake > 0 && ~isempty(idxRegular)
            z = AllEvents.detectorPeakZ(idxRegular);
            zSort = z;
            zSort(~isfinite(zSort)) = inf;
            [~,ord] = sort(zSort, 'ascend');
            orderedIdx = idxRegular(ord);
            pickPos = unique(round(linspace(1, numel(orderedIdx), nRegularTake)), 'stable');
            chosen = orderedIdx(pickPos);

            if numel(chosen) < nRegularTake
                remaining = setdiff(orderedIdx, chosen, 'stable');
                if ~isempty(remaining)
                    addN = min(nRegularTake-numel(chosen), numel(remaining));
                    chosen = [chosen; remaining(randperm(numel(remaining), addN))]; %#ok<AGROW>
                end
            end
        end

        if nArtifactTake > 0
            z = AllEvents.detectorPeakZ(idxArtifact);
            zSort = z;
            zSort(~isfinite(zSort)) = -inf;
            [~,ord] = sort(zSort, 'descend');
            orderedArt = idxArtifact(ord);
            chosenArt = orderedArt(1:nArtifactTake);
            chosen = [chosen(:); chosenArt(:)]; %#ok<AGROW>
        end

        if numel(chosen) < nTake
            remaining = setdiff(idx, chosen, 'stable');
            if ~isempty(remaining)
                addN = min(nTake-numel(chosen), numel(remaining));
                chosen = [chosen(:); remaining(randperm(numel(remaining), addN))]; %#ok<AGROW>
            end
        end

        chosen = chosen(1:min(nTake,numel(chosen)));
        selectedRows = [selectedRows; chosen(:)]; %#ok<AGROW>

        samplingRows(end+1,:) = {animalID, epochName, nAvailable, numel(chosen), ...
            numel(idxRegular), numel(idxArtifact), ...
            sum(~logical(AllEvents.currentArtifactFlag(chosen))), ...
            sum(logical(AllEvents.currentArtifactFlag(chosen)))}; %#ok<SAGROW>
    end
end

if isempty(selectedRows)
    error('The stratified sampler did not select any events.');
end

selectedRows = unique(selectedRows, 'stable');
Selected = AllEvents(selectedRows,:);

% Randomise the review order and assign blind IDs.
reviewOrder = randperm(height(Selected));
Selected = Selected(reviewOrder,:);
blindIDs = cell(height(Selected),1);
for rr = 1:height(Selected)
    blindIDs{rr} = sprintf('QC_%04d', rr);
end
Selected.blindID = blindIDs;
Selected.reviewOrder = (1:height(Selected))';
Selected = movevars(Selected, {'blindID','reviewOrder'}, 'Before', 1);

fprintf('Selected %d events for blinded review.\n', height(Selected));

%% Output folders and initial tables

outDir = fullfile(rootDir, 'hc31_batch11K_candidate_ripple_manual_QC');
figDir = fullfile(outDir, 'blinded_review_figures');
if exist(outDir, 'dir') ~= 7; mkdir(outDir); end
if exist(figDir, 'dir') ~= 7; mkdir(figDir); end

SamplingSummary = cell2table(samplingRows, 'VariableNames', ...
    {'animal','epoch','nAvailable','nSelected','nRegularAvailable','nArtifactFlaggedAvailable', ...
     'nRegularSelected','nArtifactFlaggedSelected'});
writetable(SamplingSummary, fullfile(outDir, 'hc31_batch11K_sampling_summary.csv'));

% Separate key. Keep this file hidden until review is complete.
KeyTable = Selected;
KeyTable.figureFile = cell(height(KeyTable),1);
for rr = 1:height(KeyTable)
    KeyTable.figureFile{rr} = fullfile(figDir, [KeyTable.blindID{rr} '.png']);
end
writetable(KeyTable, fullfile(outDir, 'hc31_batch11K_BLINDING_KEY_DO_NOT_OPEN_DURING_REVIEW.csv'));

% Blank review form.
nReview = height(Selected);
ManualReview = table(Selected.blindID, ...
    repmat({''},nReview,1), ... % primaryClassification
    repmat({''},nReview,1), ... % confidence
    false(nReview,1), ...       % likely ripple
    false(nReview,1), ...       % sharp wave present
    false(nReview,1), ...       % oscillation present
    false(nReview,1), ...       % spectral peak
    false(nReview,1), ...       % broadband artefact
    false(nReview,1), ...       % filter ringing
    false(nReview,1), ...       % multiple merged events
    false(nReview,1), ...       % movement related
    false(nReview,1), ...       % insufficient evidence
    repmat({''},nReview,1), ... % comments
    repmat({''},nReview,1), ... % reviewer
    repmat({''},nReview,1), ... % date
    false(nReview,1), ...       % review complete
    'VariableNames', {'blindID','primaryClassification','confidence', ...
    'isLikelyPhysiologicalRipple','sharpWavePresent','rippleOscillationPresent', ...
    'spectralPeakPresent','broadbandArtifact','filterRinging','multipleMergedEvents', ...
    'movementRelatedHighFrequency','insufficientEvidence','comments','reviewer', ...
    'reviewDate','reviewComplete'});
writetable(ManualReview, fullfile(outDir, 'hc31_batch11K_MANUAL_REVIEW_TEMPLATE.csv'));

%% Prepare CSC coverage information for each animal

cscCoverageRows = {};
cscPathsByAnimal = cell(numel(animalMapNames),1);
cscStartByAnimal = cell(numel(animalMapNames),1);
cscEndByAnimal = cell(numel(animalMapNames),1);

for ai = 1:numel(animalMapNames)
    animalID = animalMapNames{ai};

    preferredChannel = '';
    if strcmp(animalID, 'ANM00190422') || strcmp(animalID, 'ANM204878')
        preferredChannel = 'CSC33.ncs';
    elseif strcmp(animalID, 'ANM212379')
        preferredChannel = 'CSC53.ncs';
    elseif strcmp(animalID, 'ANM228899') || strcmp(animalID, 'ANM228900')
        preferredChannel = 'CSC45.ncs';
    end

    paths = {};
    if ~isempty(preferredChannel)
        D = dir(fullfile(rootDir, 'csc_files', animalID, '**', preferredChannel));
        for dd = 1:numel(D)
            paths{end+1,1} = fullfile(D(dd).folder, D(dd).name); %#ok<SAGROW>
        end
    end

    if isempty(paths)
        D = dir(fullfile(rootDir, 'csc_files', animalID, '**', '*.ncs'));
        for dd = 1:numel(D)
            paths{end+1,1} = fullfile(D(dd).folder, D(dd).name); %#ok<SAGROW>
        end
    end

    if isempty(paths)
        [f,p] = uigetfile('*.ncs', ['Select one or more CSC files for ' animalID], 'MultiSelect','on');
        if ~isequal(f,0)
            if ischar(f); f = {f}; end
            for ff = 1:numel(f)
                paths{end+1,1} = fullfile(p,f{ff}); %#ok<SAGROW>
            end
        end
    end

    % Stable unique file list.
    uniquePaths = {};
    for pp = 1:numel(paths)
        if exist(paths{pp}, 'file') == 2 && ~any(strcmp(uniquePaths, paths{pp}))
            uniquePaths{end+1,1} = paths{pp}; %#ok<SAGROW>
        end
    end
    paths = uniquePaths;

    starts = nan(numel(paths),1);
    ends = nan(numel(paths),1);

    for pp = 1:numel(paths)
        try
            ts = Nlx2MatCSC(paths{pp}, [1 0 0 0 0], 0, 1, []);
            ts = double(ts(:));
            if ~isempty(ts)
                starts(pp) = min(ts);
                ends(pp) = max(ts);
            end
        catch ME
            fprintf('Could not read CSC coverage for %s:\n  %s\n', paths{pp}, ME.message);
        end
        cscCoverageRows(end+1,:) = {animalID, paths{pp}, starts(pp), ends(pp), ...
            (ends(pp)-starts(pp))/1e6}; %#ok<SAGROW>
    end

    cscPathsByAnimal{ai} = paths;
    cscStartByAnimal{ai} = starts;
    cscEndByAnimal{ai} = ends;
end

if ~isempty(cscCoverageRows)
    CscCoverage = cell2table(cscCoverageRows, 'VariableNames', ...
        {'animal','cscFile','coverageStartUs','coverageEndUs','coverageDurationS'});
    writetable(CscCoverage, fullfile(outDir, 'hc31_batch11K_csc_coverage.csv'));
else
    CscCoverage = table();
end

% Stop early if CSC coverage could not be read. This prevents silently
% creating a review template when no blinded figures can be generated.
if isempty(CscCoverage) || all(isnan(CscCoverage.coverageStartUs))
    error(['No CSC timestamp coverage could be read. Check Nlx2MatCSC and the CSC files. ', ...
        'The review figures have not been generated.']);
end

%% Process each blinded event

morphRows = {};
failedRows = {};

for rr = 1:height(Selected)

    blindID = Selected.blindID{rr};
    animalID = Selected.animal{rr};
    epochName = Selected.epoch{rr};
    peakUs = double(Selected.peakUs(rr));
    startUs = double(Selected.startUs(rr));
    endUs = double(Selected.endUs(rr));

    fprintf('\n[%d/%d] Creating %s ...\n', rr, height(Selected), blindID);

    ai = find(strcmp(animalMapNames, animalID), 1);
    if isempty(ai)
        failedRows(end+1,:) = {blindID, 'Animal was not found in the analysed animal map.'}; %#ok<SAGROW>
        continue;
    end

    resIdx = animalMapIndices(ai);
    if isfinite(Selected.resSaveIndex(rr))
        candidateIdx = round(double(Selected.resSaveIndex(rr)));
        if candidateIdx >= 1 && candidateIdx <= numel(resSave)
            resIdx = candidateIdx;
        end
    end
    R = resSave(resIdx);

    % Choose the CSC file whose timestamp coverage contains the event peak.
    paths = cscPathsByAnimal{ai};
    starts = cscStartByAnimal{ai};
    ends = cscEndByAnimal{ai};
    cscFile = '';

    containsPeak = find(starts <= peakUs & ends >= peakUs, 1);
    if ~isempty(containsPeak)
        cscFile = paths{containsPeak};
    elseif ~isempty(paths)
        distanceToCoverage = min(abs(starts-peakUs), abs(ends-peakUs));
        [~,nearestFile] = min(distanceToCoverage);
        if isfinite(distanceToCoverage(nearestFile)) && distanceToCoverage(nearestFile) <= 2e6
            cscFile = paths{nearestFile};
        end
    end

    if isempty(cscFile)
        failedRows(end+1,:) = {blindID, 'No CSC file covered the event timestamp.'}; %#ok<SAGROW>
        fprintf('  No CSC file covers this event. Skipping.\n');
        continue;
    end

    loadStartUs = peakUs - loadHalfWindowSec*1e6;
    loadEndUs = peakUs + loadHalfWindowSec*1e6;

    % Read the short event-centred interval.
    try
        [tRec, vRec, header] = Nlx2MatCSC(cscFile, [1 0 0 0 1], 1, 4, [loadStartUs loadEndUs]);
    catch ME
        failedRows(end+1,:) = {blindID, ['Nlx2MatCSC interval read failed: ' ME.message]}; %#ok<SAGROW>
        continue;
    end

    if isempty(tRec) || isempty(vRec)
        failedRows(end+1,:) = {blindID, 'CSC interval read returned no samples.'}; %#ok<SAGROW>
        continue;
    end

    tRec = double(tRec(:));
    vRec = double(vRec);
    vallRaw = double(vRec(:));

    % Parse scaling where possible.
    H = struct();
    try
        H = readNlxHeader(header);
    catch
    end

    tDiff = diff(tRec);
    tDiffGood = tDiff(isfinite(tDiff) & tDiff > 0);
    if isempty(tDiffGood)
        failedRows(end+1,:) = {blindID, 'Could not estimate CSC sampling rate.'}; %#ok<SAGROW>
        continue;
    end

    mtDiff = mode(round(tDiffGood));
    noSkip = abs(tDiff-mtDiff) <= 2;
    if any(noSkip)
        FsRaw = 1/(mean(tDiff(noSkip))/512/1e6);
    else
        FsRaw = 1/(median(tDiffGood)/512/1e6);
    end

    if all(noSkip)
        tallUs = linspace(tRec(1), tRec(end)+(511/FsRaw)*1e6, numel(vallRaw))';
        vall = vallRaw;
    else
        tVec = (tRec(1):(1/FsRaw)*1e6:(tRec(end)+(511/FsRaw)*1e6))';
        vVec = nan(numel(tVec),1);
        posInsert = 1;
        for rec = 1:size(vRec,2)
            while posInsert <= numel(tVec) && abs(tRec(rec)-tVec(posInsert)) >= 2
                posInsert = posInsert + 1;
            end
            if posInsert+511 <= numel(vVec)
                vVec(posInsert:posInsert+511) = vRec(:,rec);
            end
            posInsert = posInsert + 512;
        end
        tallUs = tVec;
        vall = vVec;
    end

    rawScale = 1;
    rawLabel = 'Raw LFP (raw units)';
    if isfield(H, 'ADBitVolts')
        rawScale = double(H.ADBitVolts(1)) * 1e6;
        rawLabel = 'Raw LFP (\muV)';
    end
    lfpRaw = vall .* rawScale;

    validRaw = isfinite(lfpRaw);
    if ~any(validRaw)
        failedRows(end+1,:) = {blindID, 'All LFP samples were invalid.'}; %#ok<SAGROW>
        continue;
    end
    fillValue = median(lfpRaw(validRaw));
    lfpFilled = lfpRaw;
    lfpFilled(~validRaw) = fillValue;

    % Downsample.
    factor = max(1, round(FsRaw/targetFs));
    FsDs = FsRaw/factor;
    if factor > 1
        try
            lfpDs = decimate(lfpFilled, factor);
        catch
            lfpDs = lfpFilled(1:factor:end);
        end
        tDsUs = tallUs(1:factor:end);
        validDs = validRaw(1:factor:end);
    else
        lfpDs = lfpFilled;
        tDsUs = tallUs;
        validDs = validRaw;
    end

    nCommon = min([numel(lfpDs),numel(tDsUs),numel(validDs)]);
    lfpDs = double(lfpDs(1:nCommon));
    tDsUs = double(tDsUs(1:nCommon));
    validDs = logical(validDs(1:nCommon));

    if rippleHighHz >= FsDs/2
        failedRows(end+1,:) = {blindID, 'Downsampled Nyquist frequency was too low for 250 Hz ripple filtering.'}; %#ok<SAGROW>
        continue;
    end

    % Filters.
    [bSharp,aSharp] = butter(filterOrder, [sharpWaveLowHz sharpWaveHighHz]/(FsDs/2), 'bandpass');
    [bRipple,aRipple] = butter(filterOrder, [rippleLowHz rippleHighHz]/(FsDs/2), 'bandpass');
    [bTheta,aTheta] = butter(filterOrder, [thetaLowHz thetaHighHz]/(FsDs/2), 'bandpass');
    [bDelta,aDelta] = butter(filterOrder, [deltaLowHz deltaHighHz]/(FsDs/2), 'bandpass');

    sharpFilt = filtfilt(bSharp,aSharp,lfpDs);
    rippleFilt = filtfilt(bRipple,aRipple,lfpDs);
    thetaFilt = filtfilt(bTheta,aTheta,lfpDs);
    deltaFilt = filtfilt(bDelta,aDelta,lfpDs);

    rippleEnv = abs(hilbert(rippleFilt));
    thetaPower = abs(hilbert(thetaFilt)).^2;
    deltaPower = abs(hilbert(deltaFilt)).^2;
    smoothN = max(3,round(0.50*FsDs));
    thetaPowerSm = movmean(thetaPower,smoothN,'omitnan');
    deltaPowerSm = movmean(deltaPower,smoothN,'omitnan');
    logThetaDelta = log10((thetaPowerSm+eps)./(deltaPowerSm+eps));

    relAllSec = (tDsUs-peakUs)/1e6;

    % Speed is available for Run1Awake from posMazeLin(1). For sleep/rest,
    % leave it as NaN rather than inventing a zero-speed trace.
    speedDs = nan(size(tDsUs));
    if strcmp(epochName,'Run1Awake')
        try
            posU = R.posMazeLin(1);
            posData = double(posU.data);
            posT = posData(:,1);
            if max(abs(posT),[],'omitnan') < 1e6; posT = posT*1e6; end
            if size(posData,2) >= 4
                speedRaw = abs(posData(:,4));
                if isfield(posU,'unitsPerCm') && isfield(posU,'unitsPerSecond')
                    speedRaw = speedRaw .* (1/posU.unitsPerCm) .* posU.unitsPerSecond;
                end
                speedDs = interp1(posT,speedRaw,tDsUs,'linear',NaN);
            end
        catch
            speedDs = nan(size(tDsUs));
        end
    end

    % Local robust envelope z-score. Exclude the central +/-0.5 s event area.
    baselineMask = validDs & isfinite(rippleEnv) & abs(relAllSec) >= 0.50;
    if strcmp(epochName,'Run1Awake') && sum(baselineMask & speedDs <= lowSpeedThresholdCmS) >= round(FsDs)
        baselineMask = baselineMask & speedDs <= lowSpeedThresholdCmS;
    end
    baseEnv = rippleEnv(baselineMask);
    if numel(baseEnv) < round(FsDs)
        baseEnv = rippleEnv(validDs & isfinite(rippleEnv));
    end
    baseMedian = median(baseEnv,'omitnan');
    baseMad = median(abs(baseEnv-baseMedian),'omitnan');
    baseSigma = 1.4826*baseMad;
    if ~isfinite(baseSigma) || baseSigma <= 0
        baseSigma = std(baseEnv,'omitnan');
    end
    if ~isfinite(baseSigma) || baseSigma <= 0
        baseSigma = 1;
    end
    localRippleZ = (rippleEnv-baseMedian)/baseSigma;

    % Event-relative boundaries.
    relStartSec = (startUs-peakUs)/1e6;
    relEndSec = (endUs-peakUs)/1e6;

    % Spike data for the appropriate epoch.
    spikeEpochColumn = NaN;
    if strcmp(epochName,'PRE'); spikeEpochColumn = 1; end
    if strcmp(epochName,'Run1Awake'); spikeEpochColumn = 2; end
    if strcmp(epochName,'REST'); spikeEpochColumn = 3; end
    if strcmp(epochName,'POST'); spikeEpochColumn = 6; end

    nUnits = 0;
    try; nUnits = size(R.spEpochSep,1); catch; nUnits = 0; end
    spikeTimesByUnit = cell(nUnits,1);
    nEventSpikes = 0;
    nActiveUnits = 0;

    for uu = 1:nUnits
        sp = [];
        try
            if isfinite(spikeEpochColumn) && size(R.spEpochSep,2) >= spikeEpochColumn
                if isfield(R.spEpochSep,'timeStamps')
                    sp = double(R.spEpochSep(uu,spikeEpochColumn).timeStamps(:));
                elseif isfield(R.spEpochSep,'timestamps')
                    sp = double(R.spEpochSep(uu,spikeEpochColumn).timestamps(:));
                elseif isfield(R.spEpochSep,'times')
                    sp = double(R.spEpochSep(uu,spikeEpochColumn).times(:));
                elseif isfield(R.spEpochSep,'time')
                    sp = double(R.spEpochSep(uu,spikeEpochColumn).time(:));
                end
            end
        catch
            sp = [];
        end

        if isempty(sp) && strcmp(epochName,'Run1Awake')
            try
                if isfield(R,'spAll') && numel(R.spAll) >= uu
                    if isfield(R.spAll,'timeStamps')
                        sp = double(R.spAll(uu).timeStamps(:));
                    elseif isfield(R.spAll,'timestamps')
                        sp = double(R.spAll(uu).timestamps(:));
                    elseif isfield(R.spAll,'times')
                        sp = double(R.spAll(uu).times(:));
                    elseif isfield(R.spAll,'time')
                        sp = double(R.spAll(uu).time(:));
                    end
                end
            catch
                sp = [];
            end
        end

        sp = sp(isfinite(sp));
        if ~isempty(sp) && median(abs(sp),'omitnan') < 1e6
            sp = sp*1e6;
        end
        spikeTimesByUnit{uu} = sp;

        evSp = sp >= startUs & sp <= endUs;
        nEventSpikes = nEventSpikes + sum(evSp);
        if any(evSp); nActiveUnits = nActiveUnits + 1; end
    end

    % Automated morphology features.
    eventMask = tDsUs >= startUs & tDsUs <= endUs;
    if sum(eventMask) < 3
        eventMask = abs(relAllSec) <= 0.050;
    end

    featureMask = abs(relAllSec) <= sharpWaveFeatureHalfWindowSec;
    spectralMask = abs(relAllSec) <= spectralFeatureHalfWindowSec;

    rawP2P = NaN;
    sharpWavePeakAbs = NaN;
    localPeakZ = NaN;
    localPeakRippleAmp = NaN;
    estimatedCycles = NaN;
    spectralPeakHz = NaN;
    ripplePower = NaN;
    highFreqPower = NaN;
    rippleToHighFreqRatio = NaN;
    thetaDeltaAtPeak = NaN;
    speedAtPeak = NaN;

    if any(featureMask)
        rawP2P = max(lfpDs(featureMask))-min(lfpDs(featureMask));
        sharpWavePeakAbs = max(abs(sharpFilt(featureMask)));
    end
    if any(eventMask)
        localPeakZ = max(localRippleZ(eventMask));
        localPeakRippleAmp = max(abs(rippleFilt(eventMask)));
        evRip = rippleFilt(eventMask);
        zeroCrossings = sum(diff(sign(evRip)) ~= 0);
        estimatedCycles = zeroCrossings/2;
    end

    [~,peakSampleIdx] = min(abs(tDsUs-peakUs));
    if ~isempty(peakSampleIdx) && isfinite(peakSampleIdx)
        thetaDeltaAtPeak = logThetaDelta(peakSampleIdx);
        if isfinite(speedDs(peakSampleIdx)); speedAtPeak = speedDs(peakSampleIdx); end
    end

    if sum(spectralMask) >= 32
        xSpec = lfpDs(spectralMask);
        winN = min(numel(xSpec), max(32,round(0.050*FsDs)));
        overlapN = max(0,round(0.50*winN));
        nfftFeat = max(256,2^nextpow2(winN));
        try
            [pxx,fPxx] = pwelch(xSpec,winN,overlapN,nfftFeat,FsDs);
            searchMask = fPxx >= 80 & fPxx <= min(300,FsDs/2-1);
            if any(searchMask)
                pSearch = pxx(searchMask);
                fSearch = fPxx(searchMask);
                [~,mx] = max(pSearch);
                spectralPeakHz = fSearch(mx);
            end
            ripMask = fPxx >= rippleLowHz & fPxx <= rippleHighHz;
            hfMask = fPxx >= 80 & fPxx <= min(300,FsDs/2-1);
            if any(ripMask); ripplePower = trapz(fPxx(ripMask),pxx(ripMask)); end
            if any(hfMask); highFreqPower = trapz(fPxx(hfMask),pxx(hfMask)); end
            if isfinite(ripplePower) && isfinite(highFreqPower) && highFreqPower > 0
                rippleToHighFreqRatio = ripplePower/highFreqPower;
            end
        catch
        end
    end

    morphologyFigure = fullfile(figDir,[blindID '.png']);

    morphRows(end+1,:) = {blindID, Selected.reviewOrder(rr), animalID, resIdx, epochName, ...
        peakUs, startUs, endUs, (endUs-startUs)/1e6, Selected.detectorPeakZ(rr), ...
        localPeakZ, rawP2P, sharpWavePeakAbs, localPeakRippleAmp, estimatedCycles, ...
        spectralPeakHz, ripplePower, highFreqPower, rippleToHighFreqRatio, ...
        speedAtPeak, thetaDeltaAtPeak, nUnits, nActiveUnits, nEventSpikes, ...
        logical(Selected.currentArtifactFlag(rr)), cscFile, morphologyFigure}; %#ok<SAGROW>

    %% Create blinded figure

    visibleMask = abs(relAllSec) <= figureHalfWindowSec;
    xVisible = relAllSec(visibleMask);

    fig = figure('Color','w','Position',[50 25 1350 1350], ...
        'Name',['Blinded ripple QC ' blindID]);
    tl = tiledlayout(9,1,'TileSpacing','compact','Padding','compact');

    % 1. Raw LFP.
    nexttile;
    plot(xVisible,lfpDs(visibleMask),'k','LineWidth',0.8);
    hold on;
    xline(0,'r--','LineWidth',1.0);
    xline(relStartSec,':','Color',[0.45 0.45 0.45]);
    xline(relEndSec,':','Color',[0.45 0.45 0.45]);
    hold off;
    ylabel(rawLabel);
    title(['Blinded candidate-ripple review: ' blindID],'Interpreter','none');
    grid on; xlim([-figureHalfWindowSec figureHalfWindowSec]);

    % 2. Sharp-wave range.
    nexttile;
    plot(xVisible,sharpFilt(visibleMask),'Color',[0.15 0.35 0.70],'LineWidth',0.8);
    hold on;
    xline(0,'r--'); xline(relStartSec,':','Color',[0.45 0.45 0.45]); xline(relEndSec,':','Color',[0.45 0.45 0.45]);
    hold off;
    ylabel('1-30 Hz');
    grid on; xlim([-figureHalfWindowSec figureHalfWindowSec]);

    % 3. Ripple-filtered LFP.
    nexttile;
    plot(xVisible,rippleFilt(visibleMask),'k','LineWidth',0.8);
    hold on;
    xline(0,'r--'); xline(relStartSec,':','Color',[0.45 0.45 0.45]); xline(relEndSec,':','Color',[0.45 0.45 0.45]);
    hold off;
    ylabel('120-250 Hz');
    grid on; xlim([-figureHalfWindowSec figureHalfWindowSec]);

    % 4. Local ripple-envelope z.
    nexttile;
    plot(xVisible,localRippleZ(visibleMask),'k','LineWidth',0.9);
    hold on;
    yline(rippleBoundaryZReference,':','Boundary z=2');
    yline(ripplePeakZReference,'--','Peak z=3');
    yline(artefactPeakZReference,':','Artefact ref z=12');
    xline(0,'r--'); xline(relStartSec,':','Color',[0.45 0.45 0.45]); xline(relEndSec,':','Color',[0.45 0.45 0.45]);
    hold off;
    ylabel('Local env z');
    grid on; xlim([-figureHalfWindowSec figureHalfWindowSec]);

    % 5. Spectrogram.
    nexttile;
    specMask = abs(relAllSec) <= spectrogramHalfWindowSec;
    if sum(specMask) >= 64
        xSpecPlot = lfpDs(specMask);
        winSpec = max(32,round(0.050*FsDs));
        winSpec = min(winSpec,numel(xSpecPlot));
        overlapSpec = max(0,round(0.90*winSpec));
        if overlapSpec >= winSpec; overlapSpec = winSpec-1; end
        nfftSpec = max(512,2^nextpow2(winSpec));
        try
            [sSpec,fSpec,tSpec,pSpec] = spectrogram(xSpecPlot,winSpec,overlapSpec,nfftSpec,FsDs,'yaxis'); %#ok<ASGLU>
            tSpec = tSpec + relAllSec(find(specMask,1,'first'));
            useF = fSpec >= 1 & fSpec <= min(300,FsDs/2-1);
            imagesc(tSpec,fSpec(useF),10*log10(pSpec(useF,:)+eps));
            axis xy;
            hold on;
            xline(0,'r--'); xline(relStartSec,':w'); xline(relEndSec,':w');
            hold off;
            ylabel('Frequency (Hz)');
            xlim([-spectrogramHalfWindowSec spectrogramHalfWindowSec]);
            colormap(gca,parula);
        catch
            text(0.5,0.5,'Spectrogram calculation failed','HorizontalAlignment','center');
            axis off;
        end
    else
        text(0.5,0.5,'Insufficient samples for spectrogram','HorizontalAlignment','center');
        axis off;
    end

    % 6. Speed.
    nexttile;
    if any(isfinite(speedDs(visibleMask)))
        plot(xVisible,speedDs(visibleMask),'Color',[0 0.45 0.74],'LineWidth',0.9);
        hold on;
        yline(lowSpeedThresholdCmS,'--','5 cm/s'); xline(0,'r--');
        hold off;
        ylabel('Speed (cm/s)');
        grid on; xlim([-figureHalfWindowSec figureHalfWindowSec]);
    else
        text(0.5,0.5,'Speed unavailable for this rest/sleep epoch','HorizontalAlignment','center');
        axis off;
    end

    % 7. Theta/delta ratio.
    nexttile;
    plot(xVisible,logThetaDelta(visibleMask),'Color',[0.49 0.18 0.56],'LineWidth',0.9);
    hold on; xline(0,'r--'); hold off;
    ylabel('log10 \theta/\delta');
    grid on; xlim([-figureHalfWindowSec figureHalfWindowSec]);

    % 8. Spike raster.
    nexttile;
    hold on;
    for uu = 1:nUnits
        sp = spikeTimesByUnit{uu};
        if isempty(sp); continue; end
        take = sp >= peakUs-rasterHalfWindowSec*1e6 & sp <= peakUs+rasterHalfWindowSec*1e6;
        if any(take)
            plot((sp(take)-peakUs)/1e6,uu*ones(sum(take),1),'k.','MarkerSize',5);
        end
    end
    xline(0,'r--'); xline(relStartSec,':','Color',[0.45 0.45 0.45]); xline(relEndSec,':','Color',[0.45 0.45 0.45]);
    hold off;
    xlim([-rasterHalfWindowSec rasterHalfWindowSec]);
    if nUnits > 0; ylim([0 nUnits+1]); else; ylim([0 1]); end
    ylabel('CA1 unit');
    grid on;

    % 9. Population spike histogram.
    nexttile;
    popEdges = -rasterHalfWindowSec:populationBinSec:rasterHalfWindowSec;
    popCounts = zeros(1,numel(popEdges)-1);
    for uu = 1:nUnits
        sp = spikeTimesByUnit{uu};
        if isempty(sp); continue; end
        relSp = (sp-peakUs)/1e6;
        popCounts = popCounts + histcounts(relSp,popEdges);
    end
    popCenters = popEdges(1:end-1)+populationBinSec/2;
    bar(popCenters,popCounts,1,'FaceColor',[0.35 0.35 0.35],'EdgeColor','none');
    hold on; xline(0,'r--'); xline(relStartSec,':'); xline(relEndSec,':'); hold off;
    xlabel('Time from candidate peak (s)');
    ylabel('Spikes / 10 ms');
    grid on; xlim([-rasterHalfWindowSec rasterHalfWindowSec]);

    title(tl,'Red dashed = candidate peak; grey dotted = detector start/end. Animal and epoch are blinded.', ...
        'FontSize',10,'FontWeight','normal');

    print(fig,morphologyFigure,'-dpng',['-r' num2str(saveDpi)]);
    close(fig);
end

%% Save morphology and failure tables

morphHeader = {'blindID','reviewOrder','animal','resSaveIndex','epoch', ...
    'peakUs','startUs','endUs','detectorDurationS','detectorPeakZ', ...
    'localRobustPeakZ','rawPeakToPeak','sharpWavePeakAbs','ripplePeakAbs', ...
    'estimatedRippleCycles','spectralPeakHz80To300','rippleBandPower', ...
    'highFrequencyPower80To300','rippleToHighFrequencyPowerRatio', ...
    'peakSpeedCmS','log10ThetaDeltaAtPeak','nRecordedUnits','nActiveUnitsInEvent', ...
    'nSpikesInEvent','currentArtifactFlag','cscFile','figureFile'};

if ~isempty(morphRows)
    Morphology = cell2table(morphRows,'VariableNames',morphHeader);
    writetable(Morphology,fullfile(outDir,'hc31_batch11K_selected_event_morphology.csv'));
else
    Morphology = table();
end

if ~isempty(failedRows)
    Failed = cell2table(failedRows,'VariableNames',{'blindID','failureReason'});
    writetable(Failed,fullfile(outDir,'hc31_batch11K_failed_event_figures.csv'));
else
    Failed = table();
end

%% Write manual-review guide

guideFile = fullfile(outDir,'hc31_batch11K_MANUAL_REVIEW_GUIDE.txt');
fid = fopen(guideFile,'w');
fprintf(fid,'HC-31 Batch 11K manual candidate-ripple review guide\n');
fprintf(fid,'====================================================\n\n');
fprintf(fid,'Review the PNG files in blinded_review_figures in Blind-ID order.\n');
fprintf(fid,'Do not open the BLINDING_KEY file until all classifications are complete.\n\n');
fprintf(fid,'Recommended primaryClassification values\n');
fprintf(fid,'1. Likely physiological ripple\n');
fprintf(fid,'   A compact ripple-band oscillation with several visible cycles, a local\n');
fprintf(fid,'   high-frequency spectral concentration, and no dominant broadband artefact.\n');
fprintf(fid,'   A sharp-wave-range deflection and population spiking strengthen confidence\n');
fprintf(fid,'   but are not mandatory in every single event.\n\n');
fprintf(fid,'2. Ambiguous\n');
fprintf(fid,'   Some ripple-like features are present, but the event cannot be classified\n');
fprintf(fid,'   confidently from this figure alone.\n\n');
fprintf(fid,'3. Broadband artefact\n');
fprintf(fid,'   A sharp transient affects a broad frequency range simultaneously, often\n');
fprintf(fid,'   with an implausibly large raw-LFP deflection.\n\n');
fprintf(fid,'4. Filter ringing\n');
fprintf(fid,'   Ripple-band oscillations appear to be generated around a sharp edge or\n');
fprintf(fid,'   transient rather than forming an independent physiological event.\n\n');
fprintf(fid,'5. Multiple merged events\n');
fprintf(fid,'   More than one distinct high-frequency event is included inside the current\n');
fprintf(fid,'   detector start/end boundaries.\n\n');
fprintf(fid,'6. Movement-related high-frequency activity\n');
fprintf(fid,'   The event occurs during or immediately around clear locomotion/acceleration\n');
fprintf(fid,'   and resembles movement-related high-frequency contamination.\n\n');
fprintf(fid,'7. Insufficient evidence\n');
fprintf(fid,'   Missing LFP context, missing units, clipping, or another technical problem\n');
fprintf(fid,'   prevents classification.\n\n');
fprintf(fid,'Confidence values: High, Medium, or Low.\n');
fprintf(fid,'Binary columns may be used in addition to the primary classification.\n');
fprintf(fid,'Set reviewComplete to 1 only when the row has been checked.\n\n');
fprintf(fid,'Important figure note\n');
fprintf(fid,'The envelope panel uses a LOCAL robust baseline around the displayed event.\n');
fprintf(fid,'It is intended for visual morphology QC and may not numerically reproduce the\n');
fprintf(fid,'original detector peak-z. The original detector peak-z is preserved in the\n');
fprintf(fid,'hidden key and morphology tables.\n');
fclose(fid);

%% Write README

readmeFile = fullfile(outDir,'README_hc31_batch11K_candidate_ripple_manual_QC.txt');
fid = fopen(readmeFile,'w');
fprintf(fid,'HC-31 Batch 11K: blinded candidate-ripple manual QC pack\n');
fprintf(fid,'=========================================================\n\n');
fprintf(fid,'Purpose\n');
fprintf(fid,'- Create a reproducible manual-validation sample before detector optimisation.\n');
fprintf(fid,'- Keep reviewer classification blinded to animal, epoch and detector metadata.\n');
fprintf(fid,'- Extract event morphology features for the next threshold-optimisation batch.\n\n');
fprintf(fid,'Sampling\n');
fprintf(fid,'- RNG seed: %d\n',rngSeed);
fprintf(fid,'- Target events per available animal/epoch: %d\n',nReviewPerAnimalEpoch);
fprintf(fid,'- Maximum current artefact-flagged control events per animal/epoch: %d\n',maxArtifactFlaggedPerAnimalEpoch);
fprintf(fid,'- Final selected events: %d\n\n',height(Selected));
fprintf(fid,'Main outputs\n');
fprintf(fid,'- blinded_review_figures/QC_####.png\n');
fprintf(fid,'- hc31_batch11K_MANUAL_REVIEW_TEMPLATE.csv\n');
fprintf(fid,'- hc31_batch11K_BLINDING_KEY_DO_NOT_OPEN_DURING_REVIEW.csv\n');
fprintf(fid,'- hc31_batch11K_selected_event_morphology.csv\n');
fprintf(fid,'- hc31_batch11K_sampling_summary.csv\n');
fprintf(fid,'- hc31_batch11K_csc_coverage.csv\n');
fprintf(fid,'- hc31_batch11K_failed_event_figures.csv, if any figures fail\n');
fprintf(fid,'- hc31_batch11K_MANUAL_REVIEW_GUIDE.txt\n\n');
fprintf(fid,'Review procedure\n');
fprintf(fid,'1. Open only the blinded PNG figures and MANUAL_REVIEW_TEMPLATE.\n');
fprintf(fid,'2. Complete primaryClassification, confidence, binary flags and comments.\n');
fprintf(fid,'3. Set reviewComplete = 1 for reviewed rows.\n');
fprintf(fid,'4. Save the completed review CSV under a new filename.\n');
fprintf(fid,'5. Run hc31_batch11K_unblind_reviews_PLAIN_SCRIPT.m.\n\n');
fprintf(fid,'Interpretation boundary\n');
fprintf(fid,'This batch does not prove that any event is a physiological SWR. It creates the\n');
fprintf(fid,'manual labels needed to quantify detector precision and optimise Batch 11L.\n');
fclose(fid);

fprintf('\nBatch 11K generation complete.\n');
fprintf('Output folder:\n  %s\n',outDir);
fprintf('Blinded review figures created: %d\n',height(Morphology));
if ~isempty(Failed)
    fprintf('Figures that failed: %d. See hc31_batch11K_failed_event_figures.csv\n',height(Failed));
end
fprintf('\nDo not open the BLINDING_KEY until the manual review is complete.\n');
