%% HC-31 awake ripple detection and beta/beta2-ripple relationship
% Standalone script.
%
% Purpose:
%   Extend the LFP analysis beyond beta/beta2 bursts by detecting candidate
%   awake sharp-wave ripple events during Run1 and testing whether beta/beta2
%   bursts and awake ripples are temporally related.
%
% Main questions:
%   1) Can candidate awake ripples be detected during Run1 low-speed/pause periods?
%   2) Do beta/beta2 bursts tend to occur shortly before or after ripple events?
%   3) Are awake ripple rates different in novel versus familiar track sections?
%   4) Are beta2 bursts and awake ripples associated with overlapping spike
%      participation, if spike data are available in resSave?
%
% Required inputs:
%   - resSave.mat
%   - csc_files folder with raw Neuralynx .ncs files
%   - neuralynximport folder containing Nlx2MatCSC
%   - previous beta/beta2 burst output:
%       preferred: hc31_novel_familiar_burst_table.csv
%       fallback:  hc31_detected_beta_bursts.csv
%
% Output folder:
%   hc31_batch9_awake_ripples_beta_relationship
%
% Notes:
%   - This is an exploratory ripple screen, not a final validated replay
%     analysis.
%   - Ripple parameters should be reviewed with someone experienced in CA1
%     SWR detection before publication.
%   - The default ripple band is 120-250 Hz.
%   - Candidate awake ripples are detected during low-speed periods.
%   - Statistics are summarised at animal level whenever possible.
clear; clc; close all;
runnerDir = fileparts(mfilename('fullpath'));
if ~isempty(runnerDir); addpath(runnerDir, '-begin'); end
%% ---------------- User settings ----------------
P = struct();
projectRoot = 'C:\Users\angel\Documents\MATLAB\CRCN';
if exist(projectRoot, 'dir') ~= 7
    error('Forced Batch 9 could not find project root: %s', projectRoot);
end
cd(projectRoot);
P.outDir = fullfile(projectRoot, 'hc31_batch9_awake_ripples_beta_relationship_FORCE');

% Analysed HC-31 resSave indices.
P.analysedResSaveIdx = 5:9;

% Ripple detection settings.
P.rippleBandHz = [120 250];
P.targetFs = 986.4;                  % Downsample target near previous LFP analyses.
P.lowSpeedThresholdCmS = 5;          % Awake ripple candidates are detected in low-speed/pause samples.
P.rippleEnvelopeLowZ = 2.0;          % Event boundaries: envelope z >= 2.
P.rippleEnvelopePeakZ = 3.0;         % Event must contain peak z >= 3.
P.rippleMinDurationS = 0.030;        % Minimum SWR duration, 30 ms.
P.rippleMaxDurationS = 0.250;        % Maximum SWR duration, 250 ms.
P.rippleMergeGapS = 0.015;           % Merge events separated by <=15 ms.
P.rippleArtifactPeakZ = 12.0;        % Candidate events above this are labelled artefact-like.

% Beta/beta2 timing relationship settings.
P.betaBandsToUse = {'beta_13_30Hz', 'beta2_23_30Hz'};
P.crossCorrWindowS = 2.0;            % +/- window around ripple peak.
P.crossCorrBinS = 0.05;              % 50 ms bins.
P.prePostWindowS = 0.50;             % Count beta/beta2 bursts within 500 ms before/after ripple.
P.betaRippleOverlapWindowS = 0.05;   % Direct temporal overlap/tolerance around ripple.

% Surrogate/permutation settings for event timing.
P.nSurrogates = 1000;
P.minShiftS = 5.0;                   % Circular shifts at least this large in magnitude.

% Spike participation settings.
P.run1SpikeEpoch = 2;
P.spikeParticipationWindowS = 0.100; % +/-100 ms around event peak.

% Plot/export settings.
P.saveDpi = 220;
P.rngSeed = 9;

if ~exist(P.outDir, 'dir')
    mkdir(P.outDir);
end
rng(P.rngSeed);

fprintf('\nHC-31: awake ripple detection and beta/beta2-ripple relationship FORCE runner\n');
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
    error('Forced Batch 9 could not find resSave.mat under project root: %s', projectRoot);
end
S = load(resPath);
if ~isfield(S, 'resSave')
    error('resSave.mat was found but did not contain variable resSave: %s', resPath);
end
resSave = S.resSave;
fprintf('Loaded resSave:\n%s\n\n', resPath);

%% ---------------- Load beta/beta2 burst table ----------------
% Prefer the novel/familiar burst table, then fall back to detected bursts.
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
    warning('No beta/beta2 burst table found. Ripple detection will run, but beta-ripple analyses will be skipped.');
    B = table();
else
    Braw = readtable(burstCsv);
    B = standardise_burst_table(Braw);
    B.band = normalize_band_labels(B.band);
    if ismember('included', B.Properties.VariableNames)
        B = B(B.included == 1, :);
    end
    if ismember('isArtifact', B.Properties.VariableNames)
        B = B(B.isArtifact == 0, :);
    end
    B = B(ismember(cellstr(B.band), P.betaBandsToUse), :);
    fprintf('Loaded beta/beta2 burst table:\n%s\nRows after filtering: %d\n\n', burstCsv, height(B));
end

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

%% ---------------- Main analysis ----------------
RippleRows = {};
RippleRateRows = {};
TimingRows = {};
CrossCorrRows = {};
SpikeRows = {};
AnimalQCRows = {};

for ri = P.analysedResSaveIdx
    if ri > numel(resSave), continue; end
    R = resSave(ri);
    animal = get_animal_name(R, ri);
    fprintf('\nAnimal %s | resSave(%d)\n', animal, ri);

    if ~isfield(R, 'sectInt') || isempty(R.sectInt)
        warning('No sectInt for %s. Skipping.', animal);
        continue;
    end
    if ~isfield(R, 'posMazeLin') || isempty(R.posMazeLin)
        warning('No posMazeLin for %s. Skipping.', animal);
        continue;
    end

    sectInt = double(R.sectInt);
    if max(abs(sectInt(:))) < 1e6
        sectInt = sectInt .* 1e6;
    end
    run1StartUs = min(sectInt(:));
    run1EndUs   = max(sectInt(:));

    [posT, posLin, speedCmS] = extract_position_speed(R.posMazeLin(1));
    if max(abs(posT), [], 'omitnan') < 1e6
        posT = posT .* 1e6;
    end

    % Select Run1 CSC file.
    [cscPath, cscInfo] = choose_run1_csc_for_animal(cscFiles, animal, run1StartUs, run1EndUs);
    if isempty(cscPath)
        warning('No Run1 CSC file could be selected for %s. Skipping.', animal);
        continue;
    end
    fprintf('Using CSC: %s\n', cscPath);

    % Load Run1 LFP.
    [tUs, lfp, fsRaw] = load_csc_interval(cscPath, run1StartUs, run1EndUs);
    if isempty(tUs)
        warning('Could not load Run1 LFP for %s.', animal);
        continue;
    end

    % Downsample and ripple filter.
    [tDsUs, lfpDs, fsDs] = downsample_lfp(tUs, lfp, fsRaw, P.targetFs);
    [rippleFilt, rippleEnv, rippleEnvZ] = ripple_filter_envelope(lfpDs, fsDs, P.rippleBandHz);

    % Interpolate speed/position to LFP time base.
    speedDs = interp1(posT, speedCmS, tDsUs, 'linear', NaN);
    posDs = interp1(posT, posLin, tDsUs, 'linear', NaN);
    lowSpeed = isfinite(speedDs) & speedDs <= P.lowSpeedThresholdCmS;

    % Detect candidate ripples.
    ripples = detect_ripples_from_envelope(tDsUs, rippleFilt, rippleEnvZ, speedDs, posDs, lowSpeed, sectInt, P);

    fprintf('Detected %d valid candidate awake ripples before artefact filtering.\n', numel(ripples));

    % Write ripple rows.
    for r = 1:numel(ripples)
        RippleRows(end+1,:) = {animal, ri, r, ...
            ripples(r).startUs, ripples(r).endUs, ripples(r).peakUs, ...
            ripples(r).durationS, ripples(r).peakZ, ripples(r).peakRippleAmp, ...
            ripples(r).peakSpeedCmS, ripples(r).peakLinearPosition, ...
            ripples(r).subepoch, char(ripples(r).category), ripples(r).isArtifactLike}; %#ok<SAGROW>
    end

    % Ripple rate by animal/subepoch/category.
    validRipple = ripples(~[ripples.isArtifactLike]);
    rateRows = compute_ripple_rates(validRipple, sectInt, posT, posLin, speedCmS, P);
    for rr = 1:size(rateRows,1)
        RippleRateRows(end+1,:) = [{animal, ri}, rateRows(rr,:)]; %#ok<AGROW>
    end

    % Animal QC summary.
    runDurS = (run1EndUs - run1StartUs) / 1e6;
    lowSpeedS = sum(lowSpeed) / fsDs;
    AnimalQCRows(end+1,:) = {animal, ri, fsRaw, fsDs, runDurS, lowSpeedS, ...
        numel(ripples), nnz(~[ripples.isArtifactLike]), nnz([ripples.isArtifactLike]), ...
        median([validRipple.durationS], 'omitnan'), median([validRipple.peakZ], 'omitnan')}; %#ok<SAGROW>

    % Plot ripple QC for animal.
    make_ripple_qc_figures(animal, tDsUs, rippleFilt, rippleEnvZ, speedDs, posDs, validRipple, sectInt, P);

    % Beta/beta2 timing relation.
    if ~isempty(B) && numel(validRipple) > 0
        animalBursts = B(strcmp(string(B.animal), string(animal)) | B.resSaveIndex == ri, :);

        for bi = 1:numel(P.betaBandsToUse)
            band = string(P.betaBandsToUse{bi});
            BB = animalBursts(animalBursts.band == band, :);
            if height(BB) == 0, continue; end

            % Keep Run1-only if possible.
            BB = BB(BB.peakUs >= run1StartUs & BB.peakUs <= run1EndUs, :);
            if height(BB) == 0, continue; end

            ripplePeaks = [validRipple.peakUs]';
            betaPeaks = BB.peakUs(:);

            % Pre/post counts around ripples.
            [preCounts, postCounts, overlapCounts, nearestDeltaS] = beta_counts_around_ripples(ripplePeaks, betaPeaks, P);

            TimingRows(end+1,:) = {animal, ri, char(band), ...
                numel(ripplePeaks), numel(betaPeaks), ...
                mean(preCounts, 'omitnan'), mean(postCounts, 'omitnan'), ...
                mean(postCounts - preCounts, 'omitnan'), ...
                nnz(postCounts > preCounts), nnz(preCounts > postCounts), ...
                mean(overlapCounts > 0, 'omitnan'), ...
                median(abs(nearestDeltaS), 'omitnan')}; %#ok<SAGROW>

            % Cross-correlation histogram, animal-level.
            [centers, counts, ratePerRipple] = event_crosscorr(ripplePeaks, betaPeaks, P.crossCorrWindowS, P.crossCorrBinS);
            for c = 1:numel(centers)
                CrossCorrRows(end+1,:) = {animal, ri, char(band), centers(c), counts(c), ratePerRipple(c)}; %#ok<SAGROW>
            end

            % Circular-shift surrogate for beta events around ripple, if enough events.
            if numel(ripplePeaks) >= 5 && numel(betaPeaks) >= 5
                obs = mean(postCounts - preCounts, 'omitnan');
                sur = circular_shift_surrogate_prepost(ripplePeaks, betaPeaks, run1StartUs, run1EndUs, P);
                pTwo = (nnz(abs(sur) >= abs(obs)) + 1) / (numel(sur) + 1);
                fname = sprintf('batch9_%s_%s_surrogate_prepost_beta_minus_ripple.csv', animal, band);
                Tsur = table(repmat(string(animal),numel(sur),1), repmat(band,numel(sur),1), sur(:), ...
                    'VariableNames', {'animal','band','surrogateMeanPostMinusPre'});
                writetable(Tsur, fullfile(P.outDir, safe_filename(fname)));

                % Append a compact row by reusing TimingRows? Write separate below.
                TimingRows(end,:) = TimingRows(end,:); %#ok<NASGU>
                % Store p-value in a separate CSV row list using CrossCorrRows impossible.
                % Add as a special row to a text notes file later.
                append_timing_note(P, animal, band, obs, pTwo);
            end
        end
    end

    % Spike participation around beta2 bursts versus ripples.
    if ~isempty(B) && numel(validRipple) > 0 && isfield(R, 'spEpochSep') && ~isempty(R.spEpochSep)
        animalBursts = B(strcmp(string(B.animal), string(animal)) | B.resSaveIndex == ri, :);
        BB2 = animalBursts(animalBursts.band == "beta2_23_30Hz", :);
        BB2 = BB2(BB2.peakUs >= run1StartUs & BB2.peakUs <= run1EndUs, :);
        if height(BB2) > 0
            spikeRows = compute_spike_participation_overlap(R, ri, animal, BB2.peakUs, [validRipple.peakUs]', P);
            for sr = 1:size(spikeRows,1)
                SpikeRows(end+1,:) = spikeRows(sr,:); %#ok<AGROW>
            end
        end
    end
end

%% ---------------- Write outputs ----------------
if ~isempty(RippleRows)
    RippleTable = cell2table(RippleRows, 'VariableNames', { ...
        'animal','resSaveIndex','rippleIndex','startUs','endUs','peakUs', ...
        'durationS','peakZ','peakRippleAmplitude','peakSpeedCmS', ...
        'peakLinearPosition','subepoch','category','isArtifactLike'});
    writetable(RippleTable, fullfile(P.outDir, 'hc31_batch9_candidate_awake_ripples.csv'));
else
    RippleTable = table();
    warning('No ripple rows created.');
end

if ~isempty(RippleRateRows)
    RippleRateTable = cell2table(RippleRateRows, 'VariableNames', { ...
        'animal','resSaveIndex','subepoch','category','validLowSpeedSeconds', ...
        'rippleCount','rippleRatePerMinute'});
    writetable(RippleRateTable, fullfile(P.outDir, 'hc31_batch9_ripple_rates_by_subepoch_category.csv'));
else
    RippleRateTable = table();
end

if ~isempty(TimingRows)
    TimingTable = cell2table(TimingRows, 'VariableNames', { ...
        'animal','resSaveIndex','betaBand','nRipples','nBetaBursts', ...
        'meanBetaBurstsPreRipple','meanBetaBurstsPostRipple', ...
        'meanPostMinusPre','nRipplesPostGreaterThanPre','nRipplesPreGreaterThanPost', ...
        'fractionRipplesWithNearbyBetaBurst','medianAbsNearestBetaRippleDeltaS'});
    writetable(TimingTable, fullfile(P.outDir, 'hc31_batch9_beta_ripple_timing_summary.csv'));
else
    TimingTable = table();
end

if ~isempty(CrossCorrRows)
    CrossCorrTable = cell2table(CrossCorrRows, 'VariableNames', { ...
        'animal','resSaveIndex','betaBand','lagCenterS','count','eventsPerRipple'});
    writetable(CrossCorrTable, fullfile(P.outDir, 'hc31_batch9_beta_ripple_crosscorr_long.csv'));
else
    CrossCorrTable = table();
end

if ~isempty(SpikeRows)
    SpikeTable = cell2table(SpikeRows, 'VariableNames', { ...
        'animal','resSaveIndex','unitIndex','run1SpikeCount', ...
        'beta2SpikeCount','rippleSpikeCount','beta2ParticipationFraction', ...
        'rippleParticipationFraction','participatedInBothBeta2AndRipple'});
    writetable(SpikeTable, fullfile(P.outDir, 'hc31_batch9_beta2_ripple_spike_participation.csv'));
else
    SpikeTable = table();
end

if ~isempty(AnimalQCRows)
    AnimalQCTable = cell2table(AnimalQCRows, 'VariableNames', { ...
        'animal','resSaveIndex','rawFsHz','downsampledFsHz','run1DurationS', ...
        'lowSpeedSeconds','nCandidateRipples','nValidRipples','nArtifactLikeRipples', ...
        'medianValidRippleDurationS','medianValidRipplePeakZ'});
    writetable(AnimalQCTable, fullfile(P.outDir, 'hc31_batch9_ripple_detection_qc_by_animal.csv'));
else
    AnimalQCTable = table();
end

%% ---------------- Animal-level stats and figures ----------------
if ~isempty(RippleRateTable)
    AnimalRippleSummary = make_animal_ripple_summary(RippleRateTable);
    writetable(AnimalRippleSummary, fullfile(P.outDir, 'hc31_batch9_animal_level_ripple_summary.csv'));

    RippleStats = make_ripple_stats(AnimalRippleSummary);
    writetable(RippleStats, fullfile(P.outDir, 'hc31_batch9_ripple_stats_summary.csv'));

    make_ripple_rate_figures(RippleRateTable, AnimalRippleSummary, P);
end

if ~isempty(TimingTable)
    AnimalTimingStats = make_timing_stats(TimingTable);
    writetable(AnimalTimingStats, fullfile(P.outDir, 'hc31_batch9_timing_stats_summary.csv'));
    make_beta_ripple_timing_figures(TimingTable, CrossCorrTable, P);
end

if ~isempty(SpikeTable)
    make_spike_participation_figures(SpikeTable, P);
end

write_batch9_readme(P, burstCsv);

fprintf('\nBatch 9 complete.\n');
fprintf('Outputs saved in:\n%s\n', P.outDir);

%% ========================================================================
%% Local functions
%% ========================================================================
