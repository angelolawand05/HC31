%% HC-31 noisy power-spectrum QC
% Purpose:
%   Check whether any animal/session has an unusual or noisy power spectrum
%   that could affect interpretation of beta/beta2 burst detections.
%
% Inputs expected:
%   Preferred input from psdspec_fixed_groupmean.m:
%       power_spectra_spectrogram_outputs/hc31_condition_power_spectra_long.csv
%
%   Optional supporting inputs:
%       power_spectra_spectrogram_outputs/hc31_power_spectrum_summary.csv
%       beta_burst_over_time_outputs_BETA13_30_FUNC/hc31_detected_beta_bursts.csv
%       beta_burst_over_time_outputs_FUNC/hc31_detected_beta_bursts.csv
%
% Outputs:
%   Folder: hc31_batch5_noisy_power_spectrum_qc/
%   CSVs:
%       hc31_batch5_spectral_qc_metrics_all_conditions.csv
%       hc31_batch5_spectral_qc_ranked_all_moving.csv
%       hc31_batch5_burst_counts_by_animal.csv                      [if burst table found]
%       hc31_batch5_burst_count_vs_noise_metrics.csv                [if burst table found]
%       hc31_batch5_summary_notes.txt
%   Figures:
%       figures/batch5_all_moving_spectra_overlay_1_120Hz.png
%       figures/batch5_all_moving_spectra_median_normalised.png
%       figures/batch5_line_noise_excess_by_animal.png
%       figures/batch5_high_frequency_noise_metrics.png
%       figures/batch5_theta_beta2_peak_summary.png
%       figures/batch5_beta2_burst_count_vs_noise_score.png          [if burst table found]
%
% What this batch adds:
%   1) It does not re-detect bursts.
%   2) It checks whether spectra look abnormal across animals.
%   3) It estimates simple QC metrics: theta peak, beta/beta2 peak, 50/60 Hz
%      line-noise excess, high-frequency excess, and spectral roughness.
%   4) If the burst table is available, it checks whether animals with more
%      beta2 bursts also look spectrally noisier.
%
% Interpretation note:
%   These are QC/sensitivity checks. They should be used to flag possible
%   recording-quality issues, not to automatically exclude animals.
clear; clc; close all;
runnerDir = fileparts(mfilename('fullpath'));
if ~isempty(runnerDir); addpath(runnerDir, '-begin'); end
%% ---------------- USER SETTINGS ----------------
rootDir = 'C:\Users\angel\Documents\MATLAB\CRCN';
% Leave blank to auto-detect.
spectraLongFile = fullfile(rootDir, 'allresults', 'power_spectra_spectrogram_outputs', 'hc31_condition_power_spectra_long.csv');
if exist(spectraLongFile, 'file') ~= 2
    spectraLongFile = fullfile(rootDir, 'power_spectra_spectrogram_outputs', 'hc31_condition_power_spectra_long.csv');
end
if exist(spectraLongFile, 'file') ~= 2
    error('Forced Batch 5 could not find spectra file at either known location. Check rootDir and file location.');
end

spectrumSummaryFile = '';
burstTableFile = '';

% Main QC condition. psdspec_fixed_groupmean.m usually writes all_moving,
% familiar and novel spectra. QC should focus on all_moving if available.
preferredCondition = 'all_moving';

% Frequency ranges used for QC metrics.
thetaBandHz = [6 10];
betaBandHz = [13 30];
beta2BandHz = [23 30];
gammaBandHz = [30 100];
line50BandHz = [49 51];
line50NeighbourHz = [45 48; 52 55];
line60BandHz = [59 61];
line60NeighbourHz = [55 58; 62 65];
highFreqBandHz = [100 120];
broadbandHz = [1 120];
roughnessHz = [1 120];
plotHz = [1 120];

% Simple review thresholds. These are deliberately conservative flags.
lineNoiseExcessFlagDb = 6;
highFreqExcessFlagDb = 6;
robustZFlag = 2.5;

outputFolderName = 'hc31_batch5_noisy_power_spectrum_qc';

%% ---------------- LOCATE INPUTS ----------------
if isempty(spectrumSummaryFile)
    spectrumSummaryFile = locateFile(rootDir, {'hc31_power_spectrum_summary.csv'});
end
if isempty(burstTableFile)
    burstTableFile = locateFile(rootDir, { ...
        'hc31_detected_beta_bursts.csv'});
end

if isempty(spectraLongFile) || exist(spectraLongFile, 'file') ~= 2
    error(['Could not find hc31_condition_power_spectra_long.csv. ', ...
        'Run psdspec_fixed_groupmean.m first, or set spectraLongFile manually at the top of this script.']);
end

hasSummary = ~isempty(spectrumSummaryFile) && exist(spectrumSummaryFile, 'file') == 2;
hasBurstTable = ~isempty(burstTableFile) && exist(burstTableFile, 'file') == 2;

outDir = fullfile(rootDir, outputFolderName);
figDir = fullfile(outDir, 'figures');
if exist(outDir, 'dir') ~= 7; mkdir(outDir); end
if exist(figDir, 'dir') ~= 7; mkdir(figDir); end

fprintf('\nHC-31 noisy power-spectrum QC\n');
fprintf('spectra input: %s\n', spectraLongFile);
if hasSummary
    fprintf('summary input: %s\n', spectrumSummaryFile);
else
    fprintf('summary input: not found; metrics will be calculated from the long spectra table only.\n');
end
if hasBurstTable
    fprintf('burst input: %s\n', burstTableFile);
else
    fprintf('burst input: not found; burst-count vs noise plots will be skipped.\n');
end
fprintf('output folder: %s\n\n', outDir);

%% ---------------- READ AND STANDARDISE SPECTRA ----------------
Traw = readtable(spectraLongFile);
T = standardiseLongSpectraTable(Traw);
T = T(isfinite(T.frequencyHz) & isfinite(T.powerDb), :);

if isempty(T)
    error('The spectra table was read, but no valid frequency/powerDb rows were found.');
end

conditions = unique(T.condition, 'stable');
if any(strcmp(conditions, preferredCondition))
    mainCondition = preferredCondition;
else
    mainCondition = char(conditions(1));
    warning('Preferred condition %s not found. Using %s for main QC plots.', preferredCondition, mainCondition);
end

%% ---------------- CALCULATE QC METRICS FOR EACH ANIMAL/CONDITION ----------------
animals = unique(T.animal, 'stable');
metricsRows = {};
metricNames = {'animal','condition','nFrequencyBins','minFrequencyHz','maxFrequencyHz', ...
    'thetaPeakHz','thetaPeakDb','betaPeakHz','betaPeakDb','beta2PeakHz','beta2PeakDb', ...
    'betaMeanDb','beta2MeanDb','gammaMeanDb','highFreqMeanDb','broadbandMedianDb', ...
    'line50MeanDb','line50NeighbourDb','line50ExcessDb', ...
    'line60MeanDb','line60NeighbourDb','line60ExcessDb', ...
    'highFreqExcessDb','spectralRoughnessMadDb','spectralSlope30_120DbPerHz'};

for a = 1:numel(animals)
    animalName = char(animals(a));
    animalConds = unique(T.condition(T.animal == animals(a)), 'stable');
    for c = 1:numel(animalConds)
        condName = char(animalConds(c));
        rows = T.animal == animals(a) & T.condition == animalConds(c);
        f = T.frequencyHz(rows);
        y = T.powerDb(rows);
        [f, order] = sort(f);
        y = y(order);
        [f, uniqueIdx] = unique(f, 'stable');
        y = y(uniqueIdx);

        [thetaHz, thetaDb] = bandPeak(f, y, thetaBandHz);
        [betaHz, betaDb] = bandPeak(f, y, betaBandHz);
        [beta2Hz, beta2Db] = bandPeak(f, y, beta2BandHz);

        betaMean = bandMean(f, y, betaBandHz);
        beta2Mean = bandMean(f, y, beta2BandHz);
        gammaMean = bandMean(f, y, gammaBandHz);
        highMean = bandMean(f, y, highFreqBandHz);
        broadMedian = bandMedian(f, y, broadbandHz);

        line50Mean = bandMean(f, y, line50BandHz);
        line50Neighbour = neighbourMedian(f, y, line50NeighbourHz);
        line50Excess = line50Mean - line50Neighbour;

        line60Mean = bandMean(f, y, line60BandHz);
        line60Neighbour = neighbourMedian(f, y, line60NeighbourHz);
        line60Excess = line60Mean - line60Neighbour;

        highExcess = highMean - broadMedian;
        roughness = spectralRoughnessMad(f, y, roughnessHz);
        slope30_120 = spectralSlope(f, y, [30 120]);

        metricsRows(end+1,:) = {animalName, condName, numel(f), min(f), max(f), ...
            thetaHz, thetaDb, betaHz, betaDb, beta2Hz, beta2Db, ...
            betaMean, beta2Mean, gammaMean, highMean, broadMedian, ...
            line50Mean, line50Neighbour, line50Excess, ...
            line60Mean, line60Neighbour, line60Excess, ...
            highExcess, roughness, slope30_120}; %#ok<SAGROW>
    end
end

M = cell2table(metricsRows, 'VariableNames', metricNames);

% Add robust z-scores and review flags within each condition.
M.line50ExcessRobustZ = NaN(height(M),1);
M.line60ExcessRobustZ = NaN(height(M),1);
M.highFreqExcessRobustZ = NaN(height(M),1);
M.spectralRoughnessRobustZ = NaN(height(M),1);
M.combinedNoiseScore = NaN(height(M),1);
M.reviewFlag = false(height(M),1);
M.reviewReason = repmat({''}, height(M), 1);

for c = 1:numel(conditions)
    condRows = M.condition == conditions(c);
    M.line50ExcessRobustZ(condRows) = robustZ(M.line50ExcessDb(condRows));
    M.line60ExcessRobustZ(condRows) = robustZ(M.line60ExcessDb(condRows));
    M.highFreqExcessRobustZ(condRows) = robustZ(M.highFreqExcessDb(condRows));
    M.spectralRoughnessRobustZ(condRows) = robustZ(M.spectralRoughnessMadDb(condRows));

    zMat = [M.line50ExcessRobustZ(condRows), M.line60ExcessRobustZ(condRows), ...
        M.highFreqExcessRobustZ(condRows), M.spectralRoughnessRobustZ(condRows)];
    M.combinedNoiseScore(condRows) = mean(max(zMat, 0), 2, 'omitnan');
end

for r = 1:height(M)
    reasons = {};
    if M.line50ExcessDb(r) > lineNoiseExcessFlagDb || M.line50ExcessRobustZ(r) > robustZFlag
        reasons{end+1} = '50Hz_excess'; %#ok<SAGROW>
    end
    if M.line60ExcessDb(r) > lineNoiseExcessFlagDb || M.line60ExcessRobustZ(r) > robustZFlag
        reasons{end+1} = '60Hz_excess'; %#ok<SAGROW>
    end
    if M.highFreqExcessDb(r) > highFreqExcessFlagDb || M.highFreqExcessRobustZ(r) > robustZFlag
        reasons{end+1} = 'high_frequency_excess'; %#ok<SAGROW>
    end
    if M.spectralRoughnessRobustZ(r) > robustZFlag
        reasons{end+1} = 'spectral_roughness'; %#ok<SAGROW>
    end
    if ~isempty(reasons)
        M.reviewFlag(r) = true;
        M.reviewReason{r} = strjoin(reasons, ';');
    end
end

writetable(M, fullfile(outDir, 'hc31_batch5_spectral_qc_metrics_all_conditions.csv'));

mainRows = M(strcmp(M.condition, mainCondition), :);
mainRows = sortrows(mainRows, 'combinedNoiseScore', 'descend');
writetable(mainRows, fullfile(outDir, 'hc31_batch5_spectral_qc_ranked_all_moving.csv'));

%% ---------------- OPTIONAL SUMMARY COMPARISON ----------------
if hasSummary
    Sraw = readtable(spectrumSummaryFile);
    writetable(Sraw, fullfile(outDir, 'hc31_batch5_original_power_spectrum_summary_copy.csv'));
end

%% ---------------- FIGURES: SPECTRAL QC ----------------
plotAllMovingSpectraOverlay(T, mainCondition, plotHz, thetaBandHz, betaBandHz, beta2BandHz, gammaBandHz, figDir);
plotMedianNormalisedSpectra(T, mainCondition, plotHz, figDir);
plotLineNoiseMetrics(mainRows, figDir);
plotHighFrequencyMetrics(mainRows, figDir);
plotThetaBeta2PeakSummary(mainRows, figDir);

%% ---------------- OPTIONAL BURST COUNTS VS NOISE METRICS ----------------
if hasBurstTable
    Braw = readtable(burstTableFile);
    B = standardiseBurstTable(Braw);
    burstCounts = countBurstsByAnimal(B, animals);
    writetable(burstCounts, fullfile(outDir, 'hc31_batch5_burst_counts_by_animal.csv'));

    C = innerjoin(mainRows, burstCounts, 'Keys', 'animal');
    if ~isempty(C)
        C.beta2BurstsPerNoiseScore = C.beta2ValidBurstCount ./ max(C.combinedNoiseScore, eps);
        writetable(C, fullfile(outDir, 'hc31_batch5_burst_count_vs_noise_metrics.csv'));
        plotBurstCountVsNoise(C, figDir);
    end
end

%% ---------------- SUMMARY NOTES ----------------
notesPath = fullfile(outDir, 'hc31_batch5_summary_notes.txt');
fid = fopen(notesPath, 'w');
fprintf(fid, 'HC-31 noisy power-spectrum QC\n');
fprintf(fid, 'Spectra input: %s\n', spectraLongFile);
fprintf(fid, 'Main condition for QC ranking: %s\n\n', mainCondition);
fprintf(fid, 'Purpose:\n');
fprintf(fid, '  This batch checks whether any animal/session has an unusual spectral profile that might complicate burst interpretation.\n\n');
fprintf(fid, 'Main QC metrics:\n');
fprintf(fid, '  - theta peak frequency and power, expected to show hippocampal low-frequency/theta structure.\n');
fprintf(fid, '  - beta and beta2 peak frequencies/power.\n');
fprintf(fid, '  - 50 Hz and 60 Hz line-noise excess relative to neighbouring frequencies.\n');
fprintf(fid, '  - high-frequency excess in %.0f-%.0f Hz relative to the broadband median.\n', highFreqBandHz(1), highFreqBandHz(2));
fprintf(fid, '  - spectral roughness, calculated from adjacent-frequency changes.\n\n');
fprintf(fid, 'Review flags:\n');
if any(mainRows.reviewFlag)
    for r = 1:height(mainRows)
        if mainRows.reviewFlag(r)
            fprintf(fid, '  %s: %s\n', mainRows.animal{r}, mainRows.reviewReason{r});
        end
    end
else
    fprintf(fid, '  No animals exceeded the simple review-flag thresholds for the main condition.\n');
end
fprintf(fid, '\nInterpretation:\n');
fprintf(fid, '  These QC metrics do not automatically exclude recordings. They identify spectra worth checking visually.\n');
fprintf(fid, '  If animals with high beta2 burst counts also have high noise scores, beta2 detections should be interpreted more cautiously.\n');
fclose(fid);

fprintf('\nBatch 5 complete. Outputs saved to:\n%s\n', outDir);

%% ========================================================================
%                              LOCAL FUNCTIONS
% ========================================================================
