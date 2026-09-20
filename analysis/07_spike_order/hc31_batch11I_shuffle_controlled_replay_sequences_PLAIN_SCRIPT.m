%% HC-31 Batch 11I: shuffle-controlled replay-style sequence validation
%
% Plain script version. No local functions.
%
% Purpose:
%   Validate the replay-style time-versus-place-field correlations produced by
%   Batch 11F using an event-specific unit-label shuffle null distribution.
%
% Core questions:
%   1. Is each observed candidate-ripple sequence score stronger than expected
%      after randomly reassigning place-field positions across the active units?
%   2. What fraction of candidate ripple events survive false-discovery-rate
%      correction within each epoch?
%   3. Are significant events forward-like, reverse-like, or mixed?
%   4. Does shuffle-controlled sequence strength differ between PRE and REST,
%      or between other available epochs?
%
% Required:
%   - resSave.mat
%   - Batch 11F event score table:
%       hc31_batch11F_candidate_ripple_sequence_scores.csv
%   - Batch 11F place-field order table:
%       hc31_batch11F_unit_placefield_order.csv
%
% Main shuffle:
%   Spike times and the number of spikes from each active unit are preserved.
%   Place-field positions are randomly reassigned across the active units.
%   This destroys ordered time-position structure while retaining event size,
%   active-unit count, and unit-specific spike multiplicity.
%
% Important interpretation boundary:
%   This is a shuffle-controlled exploratory replay-style screen. It is not a
%   Bayesian replay decoder and does not prove physiological sharp-wave ripples,
%   replay, memory consolidation, or causality.
%
% Recommended MATLAB workaround:
%
%   clear; clc; close all; rehash;
%   [scriptFile, scriptFolder] = uigetfile('*.m', ...
%       'Select hc31_batch11I_shuffle_controlled_replay_sequences_PLAIN_SCRIPT.m');
%   cd(scriptFolder);
%   txt = fileread(fullfile(scriptFolder, scriptFile));
%   eval(txt);

clear; clc; close all; rehash;

fprintf('\nHC-31 Batch 11I: shuffle-controlled replay-style sequences\n');
fprintf('----------------------------------------------------------------\n');

%% User-editable settings

defaultRoot = 'C:\Users\angel\Documents\MATLAB\CRCN';

fallbackAnimalIDs = {'ANM00190422','ANM204878','ANM212379','ANM228899','ANM228900'};

% Epoch-to-spEpochSep column mapping used in the earlier HC-31 batches.
epochLabelsKnown = {'PRE','Run1Awake','REST','POST'};
epochSpikeColumns = [1 2 3 6];

% Event eligibility should match Batch 11F.
minSpikesForScore = 5;
minUnitsForScore = 3;

% Shuffle settings. Increase nShuffles for smoother event-level p-values.
nShuffles = 1000;
maxEventsPerAnimalEpoch = 300;
randomSeed = 1119;

% Multiple-comparison control is applied across scorable events within epoch.
fdrAlpha = 0.05;
uncorrectedAlpha = 0.05;

saveDpi = 200;

rng(randomSeed, 'twister');

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

%% Load resSave

S = load(fullfile(rootDir, 'resSave.mat'));
if ~isfield(S, 'resSave')
    error('The selected MAT file does not contain resSave.');
end
resSave = S.resSave;

%% Locate required Batch 11F event score table

scoreCsv = '';
scoreCandidates = { ...
    fullfile(rootDir, 'hc31_batch11F_replay_sorted_rasters', 'hc31_batch11F_candidate_ripple_sequence_scores.csv'), ...
    fullfile(rootDir, 'allresults', 'hc31_batch11F_replay_sorted_rasters', 'hc31_batch11F_candidate_ripple_sequence_scores.csv'), ...
    fullfile(rootDir, 'hc31_batch11F_candidate_ripple_sequence_scores.csv') ...
    };

for q = 1:numel(scoreCandidates)
    if exist(scoreCandidates{q}, 'file') == 2
        scoreCsv = scoreCandidates{q};
        break;
    end
end

if isempty(scoreCsv)
    [f,p] = uigetfile('*.csv', ...
        'Select hc31_batch11F_candidate_ripple_sequence_scores.csv');
    if isequal(f,0)
        error('No Batch 11F candidate-ripple sequence score CSV selected.');
    end
    scoreCsv = fullfile(p,f);
end

ScoreInput = readtable(scoreCsv);
fprintf('\nUsing Batch 11F event score table:\n  %s\n', scoreCsv);

%% Locate required Batch 11F place-field order table

orderCsv = '';
orderCandidates = { ...
    fullfile(rootDir, 'hc31_batch11F_replay_sorted_rasters', 'hc31_batch11F_unit_placefield_order.csv'), ...
    fullfile(rootDir, 'allresults', 'hc31_batch11F_replay_sorted_rasters', 'hc31_batch11F_unit_placefield_order.csv'), ...
    fullfile(rootDir, 'hc31_batch11F_unit_placefield_order.csv') ...
    };

for q = 1:numel(orderCandidates)
    if exist(orderCandidates{q}, 'file') == 2
        orderCsv = orderCandidates{q};
        break;
    end
end

if isempty(orderCsv)
    [f,p] = uigetfile('*.csv', ...
        'Select hc31_batch11F_unit_placefield_order.csv');
    if isequal(f,0)
        error('No Batch 11F place-field order CSV selected.');
    end
    orderCsv = fullfile(p,f);
end

UnitOrder = readtable(orderCsv);
fprintf('Using Batch 11F place-field order table:\n  %s\n', orderCsv);

%% Validate expected Batch 11F columns

scoreVars = ScoreInput.Properties.VariableNames;
requiredScoreVars = {'animal','epoch','eventIndex','eventStartUs','eventEndUs','eventPeakUs'};
for q = 1:numel(requiredScoreVars)
    if ~any(strcmp(scoreVars, requiredScoreVars{q}))
        fprintf('Available event-score columns:\n');
        disp(scoreVars');
        error('Required Batch 11F column is missing: %s', requiredScoreVars{q});
    end
end

orderVars = UnitOrder.Properties.VariableNames;
requiredOrderVars = {'animal','unitIndex','placeFieldPosition'};
for q = 1:numel(requiredOrderVars)
    if ~any(strcmp(orderVars, requiredOrderVars{q}))
        fprintf('Available place-field-order columns:\n');
        disp(orderVars');
        error('Required Batch 11F column is missing: %s', requiredOrderVars{q});
    end
end

%% Standardise text columns

ScoreInput.animal = cellstr(string(ScoreInput.animal));
ScoreInput.epoch = cellstr(string(ScoreInput.epoch));
UnitOrder.animal = cellstr(string(UnitOrder.animal));

for rr = 1:height(ScoreInput)
    ScoreInput.animal{rr} = strtrim(ScoreInput.animal{rr});
    ScoreInput.epoch{rr} = strtrim(ScoreInput.epoch{rr});
end
for rr = 1:height(UnitOrder)
    UnitOrder.animal{rr} = strtrim(UnitOrder.animal{rr});
end

%% Output folders

outDir = fullfile(rootDir, 'hc31_batch11I_shuffle_controlled_replay_sequences');
figDir = fullfile(outDir, 'figures');
if exist(outDir, 'dir') ~= 7; mkdir(outDir); end
if exist(figDir, 'dir') ~= 7; mkdir(figDir); end

%% Resolve resSave animal names

resAnimalNames = cell(numel(resSave),1);
for idx = 1:numel(resSave)
    animalID = '';
    try
        R = resSave(idx);
        if isfield(R, 'spAll') && ~isempty(R.spAll) && isfield(R.spAll, 'animal')
            animalID = char(R.spAll(1).animal);
        elseif isfield(R, 'animal')
            animalID = char(R.animal);
        elseif isfield(R, 'name')
            animalID = char(R.name);
        end
    catch
        animalID = '';
    end
    resAnimalNames{idx} = strtrim(animalID);
end

%% Storage

eventRows = {};
coverageRows = {};

exampleAnimal = {};
exampleEpoch = {};
exampleEventIndex = [];
examplePeakUs = [];
exampleObservedR = [];
exampleShuffleMean = [];
exampleShuffleZ = [];
exampleP = [];
exampleNull = {};

animalsPresent = unique(ScoreInput.animal, 'stable');

%% Main animal loop

for aa = 1:numel(animalsPresent)

    animalID = animalsPresent{aa};

    resIdx = find(strcmp(resAnimalNames, animalID), 1);
    if isempty(resIdx)
        % Fallback for the five expected analysed animals.
        fallbackHit = find(strcmp(fallbackAnimalIDs, animalID), 1);
        if ~isempty(fallbackHit)
            candidateIdx = fallbackHit + 4;
            if candidateIdx <= numel(resSave)
                resIdx = candidateIdx;
            end
        end
    end

    if isempty(resIdx)
        fprintf('\n%s: could not match to a resSave entry. Skipping.\n', animalID);
        continue;
    end

    R = resSave(resIdx);

    U = UnitOrder(strcmp(UnitOrder.animal, animalID), :);
    if isempty(U)
        fprintf('\n%s: no Batch 11F unit order rows. Skipping.\n', animalID);
        continue;
    end

    unitIndices = double(U.unitIndex(:));
    pfPositions = double(U.placeFieldPosition(:));
    validUnits = isfinite(unitIndices) & isfinite(pfPositions);
    unitIndices = unitIndices(validUnits);
    pfPositions = pfPositions(validUnits);

    [unitIndices, uniqueKeep] = unique(unitIndices, 'stable');
    pfPositions = pfPositions(uniqueKeep);

    if numel(unitIndices) < minUnitsForScore
        fprintf('\n%s: fewer than %d units with place-field positions. Skipping.\n', ...
            animalID, minUnitsForScore);
        continue;
    end

    Eanimal = ScoreInput(strcmp(ScoreInput.animal, animalID), :);
    epochsThisAnimal = unique(Eanimal.epoch, 'stable');

    fprintf('\nProcessing %s: %d place-field ordered units.\n', animalID, numel(unitIndices));

    for ee = 1:numel(epochsThisAnimal)

        epochLabel = epochsThisAnimal{ee};
        knownHit = find(strcmpi(epochLabelsKnown, epochLabel), 1);
        if isempty(knownHit)
            fprintf('  %s: unknown spike epoch mapping. Skipping.\n', epochLabel);
            continue;
        end
        spikeColumn = epochSpikeColumns(knownHit);

        E = Eanimal(strcmp(Eanimal.epoch, epochLabel), :);
        nAvailable = height(E);
        if nAvailable == 0
            continue;
        end

        if nAvailable > maxEventsPerAnimalEpoch
            selectedRows = sort(randperm(nAvailable, maxEventsPerAnimalEpoch));
            Eselected = E(selectedRows,:);
        else
            selectedRows = (1:nAvailable)';
            Eselected = E;
        end

        fprintf('  %s: analysing %d of %d Batch 11F events.\n', ...
            epochLabel, height(Eselected), nAvailable);

        % Load spike timestamps once for every ordered unit in this epoch.
        spCell = cell(numel(unitIndices),1);
        nUnitsWithSpikes = 0;

        for uu = 1:numel(unitIndices)
            unitIdx = unitIndices(uu);
            sp = [];

            try
                if isfield(R, 'spEpochSep') && ...
                        size(R.spEpochSep,1) >= unitIdx && ...
                        size(R.spEpochSep,2) >= spikeColumn
                    if isfield(R.spEpochSep, 'timeStamps')
                        sp = double(R.spEpochSep(unitIdx,spikeColumn).timeStamps(:));
                    elseif isfield(R.spEpochSep, 'timestamps')
                        sp = double(R.spEpochSep(unitIdx,spikeColumn).timestamps(:));
                    elseif isfield(R.spEpochSep, 'times')
                        sp = double(R.spEpochSep(unitIdx,spikeColumn).times(:));
                    elseif isfield(R.spEpochSep, 'time')
                        sp = double(R.spEpochSep(unitIdx,spikeColumn).time(:));
                    end
                end
            catch
                sp = [];
            end

            % Run1 fallback, matching the earlier workflow.
            if isempty(sp) && strcmpi(epochLabel, 'Run1Awake')
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
            if ~isempty(spCell{uu})
                nUnitsWithSpikes = nUnitsWithSpikes + 1;
            end
        end

        nScorable = 0;

        for ev = 1:height(Eselected)

            eventStartUs = double(Eselected.eventStartUs(ev));
            eventEndUs = double(Eselected.eventEndUs(ev));
            eventPeakUs = double(Eselected.eventPeakUs(ev));
            eventIndex = double(Eselected.eventIndex(ev));

            if ~isfinite(eventStartUs) || ~isfinite(eventEndUs) || ...
                    ~isfinite(eventPeakUs) || eventEndUs <= eventStartUs
                continue;
            end

            relTimesSec = [];
            relUnitLocal = [];
            relPfObserved = [];

            for uu = 1:numel(spCell)
                sp = spCell{uu};
                if isempty(sp); continue; end

                spEvent = sp(sp >= eventStartUs & sp <= eventEndUs);
                if isempty(spEvent); continue; end

                nAdd = numel(spEvent);
                relTimesSec = [relTimesSec; (spEvent(:)-eventPeakUs)./1e6]; %#ok<AGROW>
                relUnitLocal = [relUnitLocal; repmat(uu,nAdd,1)]; %#ok<AGROW>
                relPfObserved = [relPfObserved; repmat(pfPositions(uu),nAdd,1)]; %#ok<AGROW>
            end

            nSpikes = numel(relTimesSec);
            activeUnits = unique(relUnitLocal);
            nActiveUnits = numel(activeUnits);

            if nSpikes < minSpikesForScore || nActiveUnits < minUnitsForScore || ...
                    numel(unique(relTimesSec)) < 2 || numel(unique(relPfObserved)) < 2
                continue;
            end

            C = corrcoef(relTimesSec, relPfObserved);
            observedR = C(1,2);
            if ~isfinite(observedR)
                continue;
            end

            % Map each spike to one of the active units. The shuffle permutes
            % place-field identities across active units, not across spikes.
            activeGroup = zeros(nSpikes,1);
            activePf = nan(nActiveUnits,1);
            for gu = 1:nActiveUnits
                activeGroup(relUnitLocal == activeUnits(gu)) = gu;
                activePf(gu) = pfPositions(activeUnits(gu));
            end

            nullR = nan(nShuffles,1);
            for ss = 1:nShuffles
                permutedPf = activePf(randperm(nActiveUnits));
                shuffledPfPerSpike = permutedPf(activeGroup);
                Cs = corrcoef(relTimesSec, shuffledPfPerSpike);
                nullR(ss) = Cs(1,2);
            end
            nullR = nullR(isfinite(nullR));

            if isempty(nullR)
                continue;
            end

            shuffleMean = mean(nullR);
            shuffleSd = std(nullR);
            if isfinite(shuffleSd) && shuffleSd > 0
                shuffleZ = (observedR - shuffleMean) ./ shuffleSd;
            else
                shuffleZ = NaN;
            end

            pTwo = (1 + sum(abs(nullR) >= abs(observedR))) ./ (numel(nullR)+1);
            pForward = (1 + sum(nullR >= observedR)) ./ (numel(nullR)+1);
            pReverse = (1 + sum(nullR <= observedR)) ./ (numel(nullR)+1);
            percentile = 100 .* mean(nullR <= observedR);

            if observedR > 0
                direction = 'forward_like';
            elseif observedR < 0
                direction = 'reverse_like';
            else
                direction = 'flat';
            end

            originalR = NaN;
            if any(strcmp(scoreVars, 'timePositionCorrelation'))
                originalR = double(Eselected.timePositionCorrelation(ev));
            end

            nScorable = nScorable + 1;
            eventRows(end+1,:) = {animalID,resIdx,epochLabel,eventIndex, ...
                eventStartUs,eventEndUs,eventPeakUs,nSpikes,nActiveUnits, ...
                observedR,originalR,observedR-originalR,shuffleMean,shuffleSd, ...
                shuffleZ,pTwo,pForward,pReverse,percentile,direction, ...
                numel(nullR),selectedRows(ev)}; %#ok<SAGROW>

            % Keep one strongest absolute-z example per animal and epoch.
            exHit = find(strcmp(exampleAnimal, animalID) & strcmp(exampleEpoch, epochLabel), 1);
            replaceExample = isempty(exHit);
            if ~replaceExample && isfinite(shuffleZ)
                if ~isfinite(exampleShuffleZ(exHit))
                    replaceExample = true;
                else
                    replaceExample = abs(shuffleZ) > abs(exampleShuffleZ(exHit));
                end
            end

            if replaceExample
                if isempty(exHit)
                    exHit = numel(exampleAnimal)+1;
                end
                exampleAnimal{exHit,1} = animalID;
                exampleEpoch{exHit,1} = epochLabel;
                exampleEventIndex(exHit,1) = eventIndex;
                examplePeakUs(exHit,1) = eventPeakUs;
                exampleObservedR(exHit,1) = observedR;
                exampleShuffleMean(exHit,1) = shuffleMean;
                exampleShuffleZ(exHit,1) = shuffleZ;
                exampleP(exHit,1) = pTwo;
                exampleNull{exHit,1} = nullR;
            end
        end

        coverageRows(end+1,:) = {animalID,resIdx,epochLabel,nAvailable, ...
            height(Eselected),nScorable,numel(unitIndices),nUnitsWithSpikes}; %#ok<SAGROW>
    end
end

%% Create event-level output table

if isempty(eventRows)
    error(['No events met the minimum requirements. Check that the Batch 11F ', ...
        'tables match this resSave file and that spike timestamps are available.']);
end

EventTable = cell2table(eventRows, 'VariableNames', ...
    {'animal','resSaveIndex','epoch','eventIndex','eventStartUs','eventEndUs', ...
     'eventPeakUs','nSpikes','nActiveUnits','observedCorrelation', ...
     'batch11FOriginalCorrelation','correlationReproductionDifference', ...
     'shuffleMeanCorrelation','shuffleSdCorrelation','shuffleZ', ...
     'shufflePTwoSided','shufflePForward','shufflePReverse', ...
     'observedPercentileInNull','sequenceDirection','nValidShuffles', ...
     'selectedInputRow'});

%% Benjamini-Hochberg FDR correction within each epoch

EventTable.shuffleQWithinEpoch = nan(height(EventTable),1);
EventTable.isUncorrectedSignificant = EventTable.shufflePTwoSided < uncorrectedAlpha;
EventTable.isFdrSignificant = false(height(EventTable),1);
EventTable.fdrSequenceClass = repmat({''},height(EventTable),1);

epochsPresent = unique(EventTable.epoch, 'stable');
for ee = 1:numel(epochsPresent)
    epochLabel = epochsPresent{ee};
    mask = strcmp(EventTable.epoch, epochLabel) & isfinite(EventTable.shufflePTwoSided);
    idx = find(mask);
    pvals = EventTable.shufflePTwoSided(idx);
    m = numel(pvals);
    if m == 0; continue; end

    [pSorted, sortOrder] = sort(pvals, 'ascend');
    qSorted = pSorted .* m ./ (1:m)';
    qSorted(qSorted > 1) = 1;
    for kk = m-1:-1:1
        qSorted(kk) = min(qSorted(kk), qSorted(kk+1));
    end

    qUnsorted = nan(m,1);
    qUnsorted(sortOrder) = qSorted;
    EventTable.shuffleQWithinEpoch(idx) = qUnsorted;
    EventTable.isFdrSignificant(idx) = qUnsorted < fdrAlpha;
end

for rr = 1:height(EventTable)
    if EventTable.isFdrSignificant(rr)
        if EventTable.observedCorrelation(rr) > 0
            EventTable.fdrSequenceClass{rr} = 'significant_forward_like';
        elseif EventTable.observedCorrelation(rr) < 0
            EventTable.fdrSequenceClass{rr} = 'significant_reverse_like';
        else
            EventTable.fdrSequenceClass{rr} = 'significant_flat';
        end
    else
        EventTable.fdrSequenceClass{rr} = 'not_FDR_significant';
    end
end

% Confirm that the observed score reproduces the Batch 11F correlation.
reproMask = isfinite(EventTable.batch11FOriginalCorrelation) & ...
    isfinite(EventTable.observedCorrelation);
if any(reproMask)
    maxReproductionDifference = max(abs( ...
        EventTable.correlationReproductionDifference(reproMask)));
    fprintf('Maximum absolute difference from Batch 11F score: %.3g\n', ...
        maxReproductionDifference);
    if maxReproductionDifference > 1e-8
        warning(['Recomputed sequence scores differ from Batch 11F by more than ', ...
            '1e-8. Check that the same resSave and unit-order table were selected.']);
    end
end

writetable(EventTable, ...
    fullfile(outDir, 'hc31_batch11I_event_level_shuffle_sequence_results.csv'));

%% Coverage table

if ~isempty(coverageRows)
    CoverageTable = cell2table(coverageRows, 'VariableNames', ...
        {'animal','resSaveIndex','epoch','nBatch11FEventsAvailable', ...
         'nEventsSelected','nEventsScorable','nPlaceFieldOrderedUnits', ...
         'nUnitsWithEpochSpikes'});
    writetable(CoverageTable, fullfile(outDir, 'hc31_batch11I_analysis_coverage.csv'));
else
    CoverageTable = table();
end

%% Animal-by-epoch summary

summaryRows = {};
animalsAnalysed = unique(EventTable.animal, 'stable');
for aa = 1:numel(animalsAnalysed)
    animalID = animalsAnalysed{aa};
    for ee = 1:numel(epochsPresent)
        epochLabel = epochsPresent{ee};
        mask = strcmp(EventTable.animal, animalID) & strcmp(EventTable.epoch, epochLabel);
        T = EventTable(mask,:);
        if isempty(T); continue; end

        nEvents = height(T);
        nUncorrected = sum(T.isUncorrectedSignificant);
        nFdr = sum(T.isFdrSignificant);
        nFdrForward = sum(T.isFdrSignificant & T.observedCorrelation > 0);
        nFdrReverse = sum(T.isFdrSignificant & T.observedCorrelation < 0);

        summaryRows(end+1,:) = {animalID,epochLabel,nEvents, ...
            mean(T.observedCorrelation,'omitnan'), ...
            median(T.observedCorrelation,'omitnan'), ...
            mean(abs(T.observedCorrelation),'omitnan'), ...
            mean(T.shuffleZ,'omitnan'), ...
            mean(abs(T.shuffleZ),'omitnan'), ...
            median(T.shufflePTwoSided,'omitnan'), ...
            nUncorrected,nUncorrected/nEvents,nFdr,nFdr/nEvents, ...
            nFdrForward,nFdrForward/nEvents,nFdrReverse,nFdrReverse/nEvents}; %#ok<SAGROW>
    end
end

AnimalSummary = cell2table(summaryRows, 'VariableNames', ...
    {'animal','epoch','nScorableEvents','meanObservedCorrelation', ...
     'medianObservedCorrelation','meanAbsoluteObservedCorrelation', ...
     'meanShuffleZ','meanAbsoluteShuffleZ','medianShufflePTwoSided', ...
     'nUncorrectedSignificant','fractionUncorrectedSignificant', ...
     'nFdrSignificant','fractionFdrSignificant','nFdrForwardLike', ...
     'fractionFdrForwardLike','nFdrReverseLike','fractionFdrReverseLike'});

writetable(AnimalSummary, fullfile(outDir, 'hc31_batch11I_animal_epoch_summary.csv'));

%% Group descriptive summary

groupRows = {};
for ee = 1:numel(epochsPresent)
    epochLabel = epochsPresent{ee};
    T = AnimalSummary(strcmp(AnimalSummary.epoch,epochLabel),:);
    if isempty(T); continue; end

    nAnimals = height(T);
    vals1 = T.meanAbsoluteShuffleZ;
    vals2 = T.fractionFdrSignificant;
    vals3 = T.fractionFdrForwardLike;
    vals4 = T.fractionFdrReverseLike;

    groupRows(end+1,:) = {epochLabel,nAnimals, ...
        mean(vals1,'omitnan'),std(vals1,'omitnan')/max(sqrt(sum(isfinite(vals1))),1), ...
        mean(vals2,'omitnan'),std(vals2,'omitnan')/max(sqrt(sum(isfinite(vals2))),1), ...
        mean(vals3,'omitnan'),mean(vals4,'omitnan')}; %#ok<SAGROW>
end

GroupSummary = cell2table(groupRows, 'VariableNames', ...
    {'epoch','nAnimals','meanAnimalAbsoluteShuffleZ','semAnimalAbsoluteShuffleZ', ...
     'meanAnimalFdrSignificantFraction','semAnimalFdrSignificantFraction', ...
     'meanAnimalFdrForwardFraction','meanAnimalFdrReverseFraction'});
writetable(GroupSummary, fullfile(outDir, 'hc31_batch11I_group_descriptive_summary.csv'));

%% Exact paired sign-flip comparisons between epochs

statsRows = {};
referenceEpoch = 'PRE';
comparisonEpochs = {'REST','Run1Awake','POST'};
metrics = {'meanAbsoluteShuffleZ','fractionFdrSignificant', ...
    'fractionFdrForwardLike','fractionFdrReverseLike'};

for cc = 1:numel(comparisonEpochs)
    comparisonEpoch = comparisonEpochs{cc};
    if ~any(strcmp(AnimalSummary.epoch,referenceEpoch)) || ...
            ~any(strcmp(AnimalSummary.epoch,comparisonEpoch))
        continue;
    end

    A = AnimalSummary(strcmp(AnimalSummary.epoch,referenceEpoch),:);
    B = AnimalSummary(strcmp(AnimalSummary.epoch,comparisonEpoch),:);
    commonAnimals = intersect(A.animal,B.animal,'stable');

    for mm = 1:numel(metrics)
        metricName = metrics{mm};
        diffs = nan(numel(commonAnimals),1);
        for aa = 1:numel(commonAnimals)
            animalID = commonAnimals{aa};
            aRow = A(strcmp(A.animal,animalID),:);
            bRow = B(strcmp(B.animal,animalID),:);
            diffs(aa) = double(bRow.(metricName)(1)) - double(aRow.(metricName)(1));
        end
        diffs = diffs(isfinite(diffs));

        n = numel(diffs);
        observedMeanDifference = NaN;
        exactP = NaN;
        if n >= 1
            observedMeanDifference = mean(diffs);
            nCombinations = 2^n;
            nullMeans = nan(nCombinations,1);
            for comb = 0:nCombinations-1
                signs = ones(n,1);
                for jj = 1:n
                    if bitget(comb,jj) == 1
                        signs(jj) = -1;
                    end
                end
                nullMeans(comb+1) = mean(diffs(:).*signs);
            end
            exactP = mean(abs(nullMeans) >= abs(observedMeanDifference)-1e-12);
        end

        statsRows(end+1,:) = {[comparisonEpoch '_minus_' referenceEpoch], ...
            metricName,n,observedMeanDifference,exactP, ...
            'two-sided exact paired sign-flip across animals'}; %#ok<SAGROW>
    end
end

if ~isempty(statsRows)
    StatsTable = cell2table(statsRows, 'VariableNames', ...
        {'comparison','metric','nAnimals','meanPairedDifference','exactP','test'});
    writetable(StatsTable, fullfile(outDir, 'hc31_batch11I_exact_animal_level_stats.csv'));
else
    StatsTable = table();
end

%% Figure 1: fraction of FDR-significant events by epoch

fig1 = figure('Color','w','Position',[120 120 980 520]);
x = 1:height(GroupSummary);
bar(x, GroupSummary.meanAnimalFdrSignificantFraction, 0.65);
hold on;
errorbar(x, GroupSummary.meanAnimalFdrSignificantFraction, ...
    GroupSummary.semAnimalFdrSignificantFraction, 'k.', 'LineWidth',1.5);
for ee = 1:height(GroupSummary)
    vals = AnimalSummary.fractionFdrSignificant(strcmp(AnimalSummary.epoch,GroupSummary.epoch{ee}));
    xj = ee + linspace(-0.08,0.08,numel(vals))';
    plot(xj,vals,'ko','MarkerFaceColor','w','MarkerSize',6);
end
hold off;
xticks(x);
xticklabels(GroupSummary.epoch);
ylabel('Fraction of scorable events, q < 0.05');
xlabel('Epoch');
title('Shuffle-controlled replay-style events surviving within-epoch FDR');
grid on;
print(fig1, fullfile(figDir,'group_FDR_significant_sequence_fraction_by_epoch.png'), ...
    '-dpng',sprintf('-r%d',saveDpi));
close(fig1);

%% Figure 2: animal-level absolute shuffle z by epoch

fig2 = figure('Color','w','Position',[140 140 980 520]);
hold on;
for aa = 1:numel(animalsAnalysed)
    animalID = animalsAnalysed{aa};
    y = nan(numel(epochsPresent),1);
    for ee = 1:numel(epochsPresent)
        mask = strcmp(AnimalSummary.animal,animalID) & ...
            strcmp(AnimalSummary.epoch,epochsPresent{ee});
        if any(mask)
            y(ee) = AnimalSummary.meanAbsoluteShuffleZ(find(mask,1));
        end
    end
    plot(1:numel(epochsPresent),y,'-o','LineWidth',1.2,'DisplayName',animalID);
end
plot(1:numel(epochsPresent),GroupSummary.meanAnimalAbsoluteShuffleZ,'k-o', ...
    'LineWidth',3,'MarkerFaceColor','k','DisplayName','Group mean');
errorbar(1:numel(epochsPresent),GroupSummary.meanAnimalAbsoluteShuffleZ, ...
    GroupSummary.semAnimalAbsoluteShuffleZ,'k.','LineWidth',1.5, ...
    'HandleVisibility','off');
hold off;
xticks(1:numel(epochsPresent));
xticklabels(epochsPresent);
ylabel('Mean absolute event shuffle z-score');
xlabel('Epoch');
title('Animal-level shuffle-controlled sequence strength');
legend('Location','bestoutside','Interpreter','none');
grid on;
print(fig2, fullfile(figDir,'animal_shuffle_sequence_strength_by_epoch.png'), ...
    '-dpng',sprintf('-r%d',saveDpi));
close(fig2);

%% Figure 3: forward-like and reverse-like FDR fractions

fig3 = figure('Color','w','Position',[160 160 980 520]);
Y = [GroupSummary.meanAnimalFdrForwardFraction, ...
     GroupSummary.meanAnimalFdrReverseFraction];
bar(1:height(GroupSummary),Y,'grouped');
xticks(1:height(GroupSummary));
xticklabels(GroupSummary.epoch);
ylabel('Mean animal fraction of scorable events');
xlabel('Epoch');
title('FDR-significant forward-like and reverse-like event fractions');
legend({'Forward-like','Reverse-like'},'Location','best');
grid on;
print(fig3, fullfile(figDir,'group_FDR_forward_reverse_fraction_by_epoch.png'), ...
    '-dpng',sprintf('-r%d',saveDpi));
close(fig3);

%% Figure 4: observed score against shuffle z-score

fig4 = figure('Color','w','Position',[180 180 980 560]);
hold on;
markerSet = {'o','s','^','d','v','>','<','p'};
for ee = 1:numel(epochsPresent)
    mask = strcmp(EventTable.epoch,epochsPresent{ee});
    marker = markerSet{1+mod(ee-1,numel(markerSet))};
    scatter(EventTable.observedCorrelation(mask),EventTable.shuffleZ(mask),28, ...
        marker,'filled','DisplayName',epochsPresent{ee});
end
line([0 0],ylim,'Color',[0.4 0.4 0.4],'LineStyle',':','HandleVisibility','off');
line(xlim,[0 0],'Color',[0.4 0.4 0.4],'LineStyle',':','HandleVisibility','off');
hold off;
xlabel('Observed time-position correlation');
ylabel('Event-specific shuffle z-score');
title('Observed replay-style score relative to unit-label shuffle null');
legend('Location','best','Interpreter','none');
grid on;
print(fig4, fullfile(figDir,'observed_correlation_vs_shuffle_z.png'), ...
    '-dpng',sprintf('-r%d',saveDpi));
close(fig4);

%% Figure 5: paired PRE-versus-REST summary, when available

if any(strcmp(epochsPresent,'PRE')) && any(strcmp(epochsPresent,'REST'))
    preT = AnimalSummary(strcmp(AnimalSummary.epoch,'PRE'),:);
    restT = AnimalSummary(strcmp(AnimalSummary.epoch,'REST'),:);
    commonAnimals = intersect(preT.animal,restT.animal,'stable');

    if ~isempty(commonAnimals)
        preZ = nan(numel(commonAnimals),1);
        restZ = nan(numel(commonAnimals),1);
        preFrac = nan(numel(commonAnimals),1);
        restFrac = nan(numel(commonAnimals),1);
        for aa = 1:numel(commonAnimals)
            animalID = commonAnimals{aa};
            pRow = preT(strcmp(preT.animal,animalID),:);
            rRow = restT(strcmp(restT.animal,animalID),:);
            preZ(aa) = pRow.meanAbsoluteShuffleZ(1);
            restZ(aa) = rRow.meanAbsoluteShuffleZ(1);
            preFrac(aa) = pRow.fractionFdrSignificant(1);
            restFrac(aa) = rRow.fractionFdrSignificant(1);
        end

        fig5 = figure('Color','w','Position',[200 160 1050 480]);
        subplot(1,2,1);
        hold on;
        for aa = 1:numel(commonAnimals)
            plot([1 2],[preZ(aa) restZ(aa)],'-o','LineWidth',1.3);
        end
        hold off;
        xlim([0.75 2.25]);
        xticks([1 2]);
        xticklabels({'PRE','REST'});
        ylabel('Mean absolute event shuffle z-score');
        title('Sequence strength');
        grid on;

        subplot(1,2,2);
        hold on;
        for aa = 1:numel(commonAnimals)
            plot([1 2],[preFrac(aa) restFrac(aa)],'-o','LineWidth',1.3);
        end
        hold off;
        xlim([0.75 2.25]);
        xticks([1 2]);
        xticklabels({'PRE','REST'});
        ylabel('Fraction of events, q < 0.05');
        title('FDR-significant event fraction');
        grid on;

        sgtitle('Paired shuffle-controlled PRE-to-REST comparison');
        print(fig5, fullfile(figDir,'paired_PRE_REST_shuffle_sequence_summary.png'), ...
            '-dpng',sprintf('-r%d',saveDpi));
        close(fig5);
    end
end

%% Strongest event-specific null examples

for ex = 1:numel(exampleAnimal)
    nullR = exampleNull{ex};
    if isempty(nullR); continue; end

    fig = figure('Color','w','Position',[220 180 900 520]);
    histogram(nullR,35,'Normalization','probability');
    hold on;
    yl = ylim;
    line([exampleObservedR(ex) exampleObservedR(ex)],yl, ...
        'Color','r','LineWidth',2,'LineStyle','--');
    line([exampleShuffleMean(ex) exampleShuffleMean(ex)],yl, ...
        'Color','k','LineWidth',1.5,'LineStyle',':');
    hold off;
    xlabel('Time-position correlation under unit-label shuffle');
    ylabel('Probability');
    title(sprintf('%s %s event %d: observed r = %.3f, z = %.2f, p = %.4g', ...
        exampleAnimal{ex},exampleEpoch{ex},exampleEventIndex(ex), ...
        exampleObservedR(ex),exampleShuffleZ(ex),exampleP(ex)), ...
        'Interpreter','none');
    legend({'Shuffle null','Observed correlation','Shuffle mean'},'Location','best');
    grid on;

    figFile = fullfile(figDir,sprintf('%s_%s_event%04d_shuffle_null.png', ...
        exampleAnimal{ex},exampleEpoch{ex},exampleEventIndex(ex)));
    print(fig,figFile,'-dpng',sprintf('-r%d',saveDpi));
    close(fig);
end

%% Write plain-text summary

summaryFile = fullfile(outDir,'hc31_batch11I_summary.txt');
fid = fopen(summaryFile,'w');

fprintf(fid,'HC-31 Batch 11I: shuffle-controlled replay-style sequence validation\n');
fprintf(fid,'====================================================================\n\n');
fprintf(fid,'Input event table:\n%s\n\n',scoreCsv);
fprintf(fid,'Input place-field order table:\n%s\n\n',orderCsv);
fprintf(fid,'Settings\n');
fprintf(fid,'- Unit-label shuffles per event: %d\n',nShuffles);
fprintf(fid,'- Maximum selected events per animal/epoch: %d\n',maxEventsPerAnimalEpoch);
fprintf(fid,'- Minimum spikes per event: %d\n',minSpikesForScore);
fprintf(fid,'- Minimum active units per event: %d\n',minUnitsForScore);
fprintf(fid,'- Within-epoch FDR alpha: %.3f\n\n',fdrAlpha);

fprintf(fid,'What the null preserves\n');
fprintf(fid,'- Original candidate-ripple event window.\n');
fprintf(fid,'- Original spike times.\n');
fprintf(fid,'- Original active-unit count.\n');
fprintf(fid,'- Original spike count contributed by each active unit.\n');
fprintf(fid,'- Place-field positions are reassigned across active units.\n\n');

fprintf(fid,'Interpretation\n');
fprintf(fid,'- Positive observed correlation: forward-like place-field sequence.\n');
fprintf(fid,'- Negative observed correlation: reverse-like place-field sequence.\n');
fprintf(fid,'- Small shuffle p: observed ordering is uncommon after unit-label randomisation.\n');
fprintf(fid,'- q < %.3f: event survives within-epoch Benjamini-Hochberg FDR.\n',fdrAlpha);
fprintf(fid,'- Event-level significance is descriptive; animal-level summaries remain the biological comparison.\n\n');

fprintf(fid,'Main output files\n');
fprintf(fid,'- hc31_batch11I_event_level_shuffle_sequence_results.csv\n');
fprintf(fid,'- hc31_batch11I_animal_epoch_summary.csv\n');
fprintf(fid,'- hc31_batch11I_group_descriptive_summary.csv\n');
fprintf(fid,'- hc31_batch11I_exact_animal_level_stats.csv\n');
fprintf(fid,'- hc31_batch11I_analysis_coverage.csv\n');
fprintf(fid,'- figures/*.png\n\n');

fprintf(fid,'Important caution\n');
fprintf(fid,'This is not a full Bayesian replay decoder. Candidate ripple events remain automatically detected, and place-field ordering may include inferred field positions from Batch 11F. Significant shuffle-controlled ordering would be evidence for structured spike timing, not proof of replay or memory consolidation.\n');
fclose(fid);

fprintf('\nSaved output folder:\n  %s\n',outDir);
fprintf('Saved summary:\n  %s\n',summaryFile);
fprintf('\nBatch 11I complete.\n');
