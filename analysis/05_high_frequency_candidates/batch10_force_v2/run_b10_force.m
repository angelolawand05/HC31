%% HC-31 sleep replay / longer-term memory link
% Standalone exploratory script.
%
% Purpose:
%   Start testing the longer-term memory idea: are units active during Run1
%   beta2 bursts also recruited during later rest/sleep candidate ripples?
%
% Important framing:
%   This is NOT a final replay-decoding analysis. It is a first-pass
%   "memory-link" screen:
%       Run1 beta2-burst active units
%           -> candidate ripple participation in PRE / REST / POST epochs
%
% Main questions:
%   1) Which CA1 units were active during Run1 beta2 bursts?
%   2) Can candidate rest/sleep ripples be detected in PRE, inter-run REST,
%      and POST periods?
%   3) Are beta2-burst active units more likely to participate in POST
%      candidate ripples than units not active during beta2 bursts?
%   4) Is the effect stronger for units active during novel beta2 bursts?
%   5) Does beta2-tagged ripple participation increase from PRE to POST?
%
% Required inputs:
%   - resSave.mat
%   - csc_files folder with Neuralynx .ncs files
%   - neuralynximport folder containing Nlx2MatCSC
%   - previous burst output:
%       preferred: hc31_novel_familiar_burst_table.csv
%       fallback:  hc31_detected_beta_bursts.csv
%
% Output folder:
%   hc31_batch10_sleep_replay_memory_link
%
% Notes:
%   - Epoch mapping is inferred from spEpochSep columns:
%       1 = PRE, 2 = RUN1, 3 = REST, 4 = RUN2, 5 = RUN3, 6 = POST
%     This matches the HC-31 experimental sequence used in the report.
%     If your local resSave copy uses different columns, edit P.epochMap.
%   - Candidate ripples are detected from LFP using a 120-250 Hz envelope.
%   - Statistics are animal-level where possible.
%   - Treat outputs as hypothesis-generating until ripple examples and
%     replay decoding are validated manually.
clear; clc; close all;
runnerDir = fileparts(mfilename('fullpath'));
if ~isempty(runnerDir); addpath(runnerDir, '-begin'); end
%% ---------------- User settings ----------------
P = struct();
projectRoot = 'C:\Users\angel\Documents\MATLAB\CRCN';
if exist(projectRoot, 'dir') ~= 7
    error('Forced Batch 10 could not find project root: %s', projectRoot);
end
cd(projectRoot);
P.outDir = fullfile(projectRoot, 'hc31_batch10_sleep_replay_memory_link_FORCE_V2');

% Analysed HC-31 animals in resSave.
P.analysedResSaveIdx = 5:9;

% Default epoch map from spEpochSep columns.
% Edit this if your resSave epoch columns differ.
P.epochMap = struct( ...
    'PRE',  1, ...
    'RUN1', 2, ...
    'REST', 3, ...
    'RUN2', 4, ...
    'RUN3', 5, ...
    'POST', 6);

P.sleepLikeEpochs = {'PRE','REST','POST'};
P.run1EpochName = 'RUN1';

% Spike/ripple windows.
P.beta2UnitWindowS = 0.075;          % If burst start/end missing, use +/-75 ms around beta2 peak.
P.rippleUnitWindowS = 0.100;         % Unit participation around candidate ripple peak, +/-100 ms.

% Beta2-tag rule.
% A unit is "beta2-tagged" if its beta2 burst participation fraction is >= this value
% OR if it has at least P.beta2TagMinSpikesDuringBursts spikes during beta2 bursts.
P.beta2TagMinParticipation = 0.01;
P.beta2TagMinSpikesDuringBursts = 1;

% Candidate sleep/rest ripple detection settings.
P.rippleBandHz = [120 250];
P.targetFs = 986.4;
P.rippleEnvelopeLowZ = 2.0;          % Event boundaries: z >= 2.
P.rippleEnvelopePeakZ = 3.0;         % Event peak must reach z >= 3.
P.rippleMinDurationS = 0.030;
P.rippleMaxDurationS = 0.250;
P.rippleMergeGapS = 0.015;
P.rippleArtifactPeakZ = 12.0;

% Loading settings.
P.chunkLengthS = 120;                % Raw CSC is loaded in chunks to avoid huge memory use.
P.epochPaddingS = 0;                 % Padding around epoch intervals inferred from spikes.
P.maxEpochDurationMin = 90;          % Safety cap for very long epochs. Set Inf to disable.
P.minSpikesForEpochInterval = 20;    % Minimum pooled spikes needed to infer epoch time bounds.

% Plot/export settings.
P.saveDpi = 220;
P.rngSeed = 10;

if ~exist(P.outDir, 'dir')
    mkdir(P.outDir);
end
rng(P.rngSeed);

fprintf('\nHC-31: sleep replay / longer-term memory link FORCE runner\n');
fprintf('FORCED projectRoot: %s\n', projectRoot);
fprintf('Output folder: %s\n\n', P.outDir);

%% ---------------- Add Neuralynx import path ----------------
nyxCandidates = { ...
    fullfile(projectRoot, 'neuralynximport'), ...
    fullfile(fileparts(projectRoot), 'neuralynximport')};
nyxAdded = false;
for kk = 1:numel(nyxCandidates)
    if exist(nyxCandidates{kk}, 'dir') == 7
        addpath(genpath(nyxCandidates{kk}), '-begin');
        fprintf('Neuralynx import path added: %s\n', nyxCandidates{kk});
        nyxAdded = true;
        break;
    end
end
if ~nyxAdded
    searchRoots = {projectRoot, fileparts(projectRoot)};
    for rr = 1:numel(searchRoots)
        neuralynxDirs = dir(fullfile(searchRoots{rr}, '**', 'neuralynximport'));
        if ~isempty(neuralynxDirs)
            nyxPath = fullfile(neuralynxDirs(1).folder, neuralynxDirs(1).name);
            addpath(genpath(nyxPath), '-begin');
            fprintf('Neuralynx import path added by search: %s\n', nyxPath);
            nyxAdded = true;
            break;
        end
    end
end

if exist('Nlx2MatCSC', 'file') ~= 3 && exist('Nlx2MatCSC', 'file') ~= 2
    error('Nlx2MatCSC was not found. Add neuralynximport to the MATLAB path and rerun.');
else
    fprintf('Nlx2MatCSC path: %s\n', which('Nlx2MatCSC'));
end

%% ---------------- Load resSave ----------------
resPath = fullfile(projectRoot, 'resSave.mat');
if exist(resPath, 'file') ~= 2
    resPath = find_first_file(projectRoot, 'resSave.mat');
end
if isempty(resPath) || exist(resPath, 'file') ~= 2
    error('Forced Batch 10 could not find resSave.mat under project root: %s', projectRoot);
end
S = load(resPath);
if ~isfield(S, 'resSave')
    error('resSave.mat was found but did not contain variable resSave: %s', resPath);
end
resSave = S.resSave;
fprintf('Loaded resSave:\n%s\n\n', resPath);

%% ---------------- Load Run1 beta/beta2 burst table ----------------
% Prefer the novel/familiar burst table for novel/familiar tags, then fall back to detected bursts.
knownBurstPaths = { ...
    fullfile(projectRoot, 'allresults', 'beta_burst_novel_familiar_outputs_BETA13_30', 'hc31_novel_familiar_burst_table.csv'), ...
    fullfile(projectRoot, 'beta_burst_novel_familiar_outputs_BETA13_30', 'hc31_novel_familiar_burst_table.csv'), ...
    fullfile(projectRoot, 'allresults', 'beta_burst_novel_familiar_outputs', 'hc31_novel_familiar_burst_table.csv'), ...
    fullfile(projectRoot, 'beta_burst_novel_familiar_outputs', 'hc31_novel_familiar_burst_table.csv'), ...
    fullfile(projectRoot, 'allresults', 'beta_burst_over_time_outputs_BETA13_30_FUNC', 'hc31_detected_beta_bursts.csv'), ...
    fullfile(projectRoot, 'beta_burst_over_time_outputs_BETA13_30_FUNC', 'hc31_detected_beta_bursts.csv'), ...
    fullfile(projectRoot, 'allresults', 'beta_burst_over_time_outputs_FUNC', 'hc31_detected_beta_bursts.csv'), ...
    fullfile(projectRoot, 'beta_burst_over_time_outputs_FUNC', 'hc31_detected_beta_bursts.csv'), ...
    fullfile(projectRoot, 'allresults', 'burst_location_outputs', 'hc31_burst_locations_run1.csv'), ...
    fullfile(projectRoot, 'burst_location_outputs', 'hc31_burst_locations_run1.csv')};

burstCsv = '';
for kk = 1:numel(knownBurstPaths)
    if exist(knownBurstPaths{kk}, 'file') == 2
        burstCsv = knownBurstPaths{kk};
        break;
    end
end
if isempty(burstCsv)
    burstCsv = find_first_file(projectRoot, 'hc31_novel_familiar_burst_table.csv');
end
if isempty(burstCsv)
    burstCsv = find_first_file(projectRoot, 'hc31_detected_beta_bursts.csv');
end
if isempty(burstCsv)
    error('Could not find hc31_novel_familiar_burst_table.csv or hc31_detected_beta_bursts.csv under project root: %s', projectRoot);
end

Braw = readtable(burstCsv);
B = standardise_burst_table(Braw);
B.band = normalize_band_labels(B.band);

if ismember('included', B.Properties.VariableNames)
    B = B(B.included == 1, :);
end
if ismember('isArtifact', B.Properties.VariableNames)
    B = B(B.isArtifact == 0, :);
end
B = B(B.band == "beta2_23_30Hz", :);

fprintf('Loaded beta2 burst table:\n%s\nRows after filtering: %d\n\n', burstCsv, height(B));

%% ---------------- Find CSC files ----------------
cscFiles = dir(fullfile(projectRoot, '**', '*.ncs'));
if isempty(cscFiles)
    parentCscRoot = fileparts(projectRoot);
    cscFiles = dir(fullfile(parentCscRoot, '**', '*.ncs'));
end
if isempty(cscFiles)
    error('No .ncs files found under project root or parent MATLAB folder.');
end
fprintf('Found %d CSC files.\n', numel(cscFiles));

%% ---------------- Main outputs ----------------
EpochRows = {};
Beta2TagRows = {};
RippleRows = {};
RippleRateRows = {};
RippleParticipationRows = {};
AnimalComparisonRows = {};

for ri = P.analysedResSaveIdx
    if ri > numel(resSave), continue; end
    R = resSave(ri);
    animal = get_animal_name(R, ri);
    fprintf('\nAnimal %s | resSave(%d)\n', animal, ri);

    if ~isfield(R, 'spEpochSep') || isempty(R.spEpochSep)
        warning('No spEpochSep for %s. Skipping.', animal);
        continue;
    end

    sp = R.spEpochSep;
    nUnits = size(sp, 1);
    nEpochs = size(sp, 2);

    % Infer epoch intervals from pooled spike timestamps.
    EpochInfo = infer_epoch_intervals_from_spikes(R, ri, animal, P);
    for e = 1:numel(EpochInfo)
        EpochRows(end+1,:) = {animal, ri, EpochInfo(e).epochName, EpochInfo(e).epochCol, ...
            EpochInfo(e).startUs, EpochInfo(e).endUs, EpochInfo(e).durationS, ...
            EpochInfo(e).nPooledSpikes, EpochInfo(e).isUsable}; %#ok<AGROW>
    end

    % Run1 unit spike times.
    run1Col = get_epoch_col(P, P.run1EpochName, nEpochs);
    if isnan(run1Col)
        warning('RUN1 epoch column is not available for %s. Skipping beta2 unit tagging.', animal);
        continue;
    end

    UnitRun1 = get_unit_spikes_for_epoch(R, run1Col);

    % Match beta2 bursts to this animal.
    animalBursts = B(strcmp(string(B.animal), string(animal)) | B.resSaveIndex == ri, :);
    if height(animalBursts) == 0
        warning('No beta2 burst rows matched %s / resSave(%d).', animal, ri);
        continue;
    end

    % Build beta2 burst windows and unit tags.
    [bStartUs, bEndUs, bCat] = beta2_windows_from_table(animalBursts, P);
    TagInfo = make_beta2_unit_tags(UnitRun1, bStartUs, bEndUs, bCat, P);

    for u = 1:nUnits
        Beta2TagRows(end+1,:) = {animal, ri, u, ...
            numel(UnitRun1{u}), ...
            TagInfo(u).allSpikeCount, TagInfo(u).allParticipation, TagInfo(u).isBeta2Tagged, ...
            TagInfo(u).novelSpikeCount, TagInfo(u).novelParticipation, TagInfo(u).isNovelBeta2Tagged, ...
            TagInfo(u).familiarSpikeCount, TagInfo(u).familiarParticipation, TagInfo(u).isFamiliarBeta2Tagged}; %#ok<AGROW>
    end

    % Detect candidate ripples in PRE / REST / POST.
    AnimalRippleEvents = struct([]);
    for ei = 1:numel(P.sleepLikeEpochs)
        epochName = string(P.sleepLikeEpochs{ei});
        epochInfo = find_epoch_info(EpochInfo, epochName);
        if isempty(epochInfo) || ~epochInfo.isUsable
            warning('%s epoch not usable for %s. Skipping.', epochName, animal);
            continue;
        end

        startUs = epochInfo.startUs - P.epochPaddingS * 1e6;
        endUs   = epochInfo.endUs   + P.epochPaddingS * 1e6;

        if isfinite(P.maxEpochDurationMin)
            maxDurUs = P.maxEpochDurationMin * 60 * 1e6;
            if endUs - startUs > maxDurUs
                warning('%s %s epoch is long. Trimming to first %.1f minutes for this exploratory screen.', ...
                    animal, epochName, P.maxEpochDurationMin);
                endUs = startUs + maxDurUs;
            end
        end

        [cscPath, cscInfo] = choose_csc_for_interval(cscFiles, animal, startUs, endUs);
        if isempty(cscPath)
            warning('No CSC overlap for %s %s. Skipping ripple detection.', animal, epochName);
            continue;
        end
        fprintf('  %s: loading LFP from %s\n', epochName, cscPath);

        [tDsUs, lfpDs, fsDs] = load_csc_interval_downsampled_chunked(cscPath, startUs, endUs, P.targetFs, P.chunkLengthS);
        if isempty(tDsUs)
            warning('Could not load LFP for %s %s.', animal, epochName);
            continue;
        end

        [rippleFilt, rippleEnv, rippleEnvZ] = ripple_filter_envelope(lfpDs, fsDs, P.rippleBandHz);
        ripples = detect_candidate_sleep_ripples(tDsUs, rippleFilt, rippleEnvZ, epochName, P);

        validRipples = ripples(~[ripples.isArtifactLike]);

        fprintf('  %s: %d valid candidate ripples, %d artefact-like candidates\n', ...
            epochName, numel(validRipples), nnz([ripples.isArtifactLike]));

        for r = 1:numel(ripples)
            RippleRows(end+1,:) = {animal, ri, char(epochName), r, ...
                ripples(r).startUs, ripples(r).endUs, ripples(r).peakUs, ...
                ripples(r).durationS, ripples(r).peakZ, ripples(r).peakRippleAmp, ...
                ripples(r).isArtifactLike}; %#ok<AGROW>
        end

        epochDurS = (endUs - startUs) / 1e6;
        RippleRateRows(end+1,:) = {animal, ri, char(epochName), epochDurS, ...
            numel(ripples), numel(validRipples), nnz([ripples.isArtifactLike]), ...
            numel(validRipples) / max(epochDurS, eps) * 60}; %#ok<AGROW>

        % Event QC plot.
        make_sleep_ripple_qc_plot(animal, epochName, tDsUs, rippleEnvZ, validRipples, P);

        % Unit participation in this epoch's candidate ripples.
        epochCol = get_epoch_col(P, epochName, nEpochs);
        if ~isnan(epochCol)
            UnitEpoch = get_unit_spikes_for_epoch(R, epochCol);
            Part = compute_unit_participation_in_events(UnitEpoch, [validRipples.peakUs]', P.rippleUnitWindowS);
            for u = 1:nUnits
                RippleParticipationRows(end+1,:) = {animal, ri, char(epochName), u, ...
                    numel(UnitEpoch{u}), numel(validRipples), ...
                    Part(u).spikeCount, Part(u).participationFraction, Part(u).firingRateHz, ...
                    TagInfo(u).isBeta2Tagged, TagInfo(u).isNovelBeta2Tagged, TagInfo(u).isFamiliarBeta2Tagged, ...
                    TagInfo(u).allParticipation, TagInfo(u).novelParticipation, TagInfo(u).familiarParticipation}; %#ok<AGROW>
            end
        else
            warning('No spike epoch column for %s %s; ripple participation not computed.', animal, epochName);
        end

        % Store for optional later use.
        if isempty(AnimalRippleEvents)
            AnimalRippleEvents = ripples(:);
        else
            AnimalRippleEvents = [AnimalRippleEvents(:); ripples(:)]; %#ok<AGROW>
        end
    end
end

%% ---------------- Write primary tables ----------------
if ~isempty(EpochRows)
    EpochInventory = cell2table(EpochRows, 'VariableNames', { ...
        'animal','resSaveIndex','epochName','epochCol','startUs','endUs', ...
        'durationS','nPooledSpikes','isUsable'});
    writetable(EpochInventory, fullfile(P.outDir, 'hc31_batch10_epoch_inventory_from_spikes.csv'));
else
    EpochInventory = table();
end

if ~isempty(Beta2TagRows)
    Beta2Tags = cell2table(Beta2TagRows, 'VariableNames', { ...
        'animal','resSaveIndex','unitIndex','run1SpikeCount', ...
        'beta2SpikeCount','beta2ParticipationFraction','isBeta2Tagged', ...
        'novelBeta2SpikeCount','novelBeta2ParticipationFraction','isNovelBeta2Tagged', ...
        'familiarBeta2SpikeCount','familiarBeta2ParticipationFraction','isFamiliarBeta2Tagged'});
    writetable(Beta2Tags, fullfile(P.outDir, 'hc31_batch10_run1_beta2_unit_tags.csv'));
else
    Beta2Tags = table();
end

if ~isempty(RippleRows)
    SleepRipples = cell2table(RippleRows, 'VariableNames', { ...
        'animal','resSaveIndex','epochName','rippleIndex','startUs','endUs','peakUs', ...
        'durationS','peakZ','peakRippleAmplitude','isArtifactLike'});
    writetable(SleepRipples, fullfile(P.outDir, 'hc31_batch10_candidate_sleep_ripples.csv'));
else
    SleepRipples = table();
end

if ~isempty(RippleRateRows)
    RippleRates = cell2table(RippleRateRows, 'VariableNames', { ...
        'animal','resSaveIndex','epochName','epochDurationS','nCandidateRipples', ...
        'nValidRipples','nArtifactLikeRipples','validRippleRatePerMinute'});
    writetable(RippleRates, fullfile(P.outDir, 'hc31_batch10_sleep_ripple_rates_by_epoch.csv'));
else
    RippleRates = table();
end

if ~isempty(RippleParticipationRows)
    RippleParticipation = cell2table(RippleParticipationRows, 'VariableNames', { ...
        'animal','resSaveIndex','epochName','unitIndex','epochSpikeCount','nRipples', ...
        'spikesDuringRipples','rippleParticipationFraction','rippleWindowFiringRateHz', ...
        'isBeta2Tagged','isNovelBeta2Tagged','isFamiliarBeta2Tagged', ...
        'run1Beta2ParticipationFraction','run1NovelBeta2ParticipationFraction', ...
        'run1FamiliarBeta2ParticipationFraction'});
    writetable(RippleParticipation, fullfile(P.outDir, 'hc31_batch10_unit_sleep_ripple_participation.csv'));
else
    RippleParticipation = table();
end

%% ---------------- Animal-level summaries and stats ----------------
if ~isempty(RippleParticipationRows)
    AnimalSummary = make_animal_level_memory_link_summary(RippleParticipation);
    writetable(AnimalSummary, fullfile(P.outDir, 'hc31_batch10_animal_level_memory_link_summary.csv'));

    StatsSummary = make_batch10_stats_summary(AnimalSummary);
    writetable(StatsSummary, fullfile(P.outDir, 'hc31_batch10_memory_link_stats_summary.csv'));

    make_batch10_figures(Beta2Tags, RippleRates, RippleParticipation, AnimalSummary, P);
else
    AnimalSummary = table();
    StatsSummary = table();
end

write_batch10_readme(P, burstCsv);

fprintf('\nBatch 10 complete.\n');
fprintf('Outputs saved in:\n%s\n', P.outDir);

%% ========================================================================
%% Local functions
%% ========================================================================
