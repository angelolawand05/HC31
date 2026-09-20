%% HC-31 z-scored spectrograms over Run1
% Purpose:
%   Create z-scored time-frequency spectrograms for Run1 LFP so transient
%   beta/beta2 activity can be viewed without the plot being dominated by
%   strong low-frequency power.
%
% Inputs expected:
%   1) resSave.mat
%   2) Neuralynx CSC files in the standard HC-31 folder layout:
%        csc_files/<animal>/<recording folder>/<CSCxx.ncs>
%   3) neuralynximport folder containing Nlx2MatCSC
%
% Optional input:
%   A burst table from earlier analysis, usually one of:
%        beta_burst_over_time_outputs_BETA13_30_FUNC/hc31_detected_beta_bursts.csv
%        beta_burst_novel_familiar_outputs_BETA13_30/hc31_novel_familiar_burst_table.csv
%        burst_location_outputs/hc31_burst_locations_run1.csv
%
% Outputs:
%   Folder: hc31_batch6_zscored_spectrograms/
%   CSVs:
%       hc31_batch6_zspectrogram_summary.csv
%       hc31_batch6_band_zpower_timecourses.csv
%       hc31_batch6_band_zpower_1min_group_summary.csv
%       hc31_batch6_burst_overlay_counts.csv                         [if burst table found]
%       hc31_batch6_summary_notes.txt
%   Figures:
%       figures/per_animal/<animal>_zspec_1_80Hz.png
%       figures/per_animal/<animal>_zspec_1_50Hz.png
%       figures/per_animal/<animal>_zspec_10_35Hz_with_bursts_and_position.png
%       figures/batch6_group_mean_band_zpower_timecourses.png
%
% What this batch adds:
%   1) Each frequency is z-scored over time separately.
%      This highlights transient increases at a given frequency.
%   2) Run1 subepoch boundaries are overlaid so extension stages can be
%      compared visually.
%   3) If a burst table is found, beta/beta2 burst peak times are overlaid
%      as a rug on the beta-focused spectrogram.
%
% Interpretation note:
%   A z-scored spectrogram does not show raw power. It shows whether a
%   frequency is high or low relative to its own average over time. This is
%   useful for seeing transient beta/beta2 events, but raw/average spectra
%   are still needed for absolute power comparisons.
clear; clc; close all;
runnerDir = fileparts(mfilename('fullpath'));
if ~isempty(runnerDir); addpath(runnerDir, '-begin'); end
%% ---------------- USER SETTINGS ----------------
rootDir = 'C:\Users\angel\Documents\MATLAB\CRCN';
resSavePath = fullfile(rootDir, 'resSave.mat');
if exist(resSavePath, 'file') ~= 2
    error('Forced Batch 6 could not find resSave.mat at C:\Users\angel\Documents\MATLAB\CRCN\resSave.mat');
end

% Optional burst overlay table. Use the first existing known location.
burstTableFile = '';
knownBurstPaths = { ...
    fullfile(rootDir, 'allresults', 'beta_burst_over_time_outputs_BETA13_30_FUNC', 'hc31_detected_beta_bursts.csv'), ...
    fullfile(rootDir, 'beta_burst_over_time_outputs_BETA13_30_FUNC', 'hc31_detected_beta_bursts.csv'), ...
    fullfile(rootDir, 'allresults', 'beta_burst_over_time_outputs_FUNC', 'hc31_detected_beta_bursts.csv'), ...
    fullfile(rootDir, 'beta_burst_over_time_outputs_FUNC', 'hc31_detected_beta_bursts.csv'), ...
    fullfile(rootDir, 'allresults', 'beta_burst_novel_familiar_outputs_BETA13_30', 'hc31_novel_familiar_burst_table.csv'), ...
    fullfile(rootDir, 'beta_burst_novel_familiar_outputs_BETA13_30', 'hc31_novel_familiar_burst_table.csv'), ...
    fullfile(rootDir, 'allresults', 'burst_location_outputs', 'hc31_burst_locations_run1.csv'), ...
    fullfile(rootDir, 'burst_location_outputs', 'hc31_burst_locations_run1.csv')};
for kk = 1:numel(knownBurstPaths)
    if exist(knownBurstPaths{kk}, 'file') == 2
        burstTableFile = knownBurstPaths{kk};
        break;
    end
end

animalIndices = 5:9;
targetFs = 1000;                  % downsample target; actual will be ~986 Hz
speedThresholdCmS = 5;            % for optional moving-time/timecourse summaries only

% Spectrogram settings.
windowSeconds = 2.0;
stepSeconds = 0.5;
freqMaxComputeHz = 120;
plotRangesHz = [1 80; 1 50; 10 35];
zColorLimits = [-3 3];

% Band time-course summaries from the z-scored spectrogram.
bandDefs = struct();
bandDefs(1).name = 'theta_6_10Hz';        bandDefs(1).rangeHz = [6 10];
bandDefs(2).name = 'beta_13_30Hz';        bandDefs(2).rangeHz = [13 30];
bandDefs(3).name = 'beta2_23_30Hz';       bandDefs(3).rangeHz = [23 30];
bandDefs(4).name = 'low_gamma_30_80Hz';   bandDefs(4).rangeHz = [30 80];

% Burst-rug y-positions on the beta-focused spectrogram. These are visual
% positions only; they are not burst peak frequencies.
betaRugYHz = 13.2;
beta2RugYHz = 29.5;
maxBurstDotsPerBand = 1200;       % prevents overcrowded figures; all counts are still stored

outputFolderName = 'hc31_batch6_zscored_spectrograms';

%% ---------------- LOCATE INPUTS ----------------
if isempty(resSavePath) || exist(resSavePath, 'file') ~= 2
    error('Could not find resSave.mat. Set resSavePath manually near the top of this script.');
end

% Add neuralynximport if present.
nyxPath = fullfile(rootDir, 'neuralynximport');
if exist(nyxPath, 'dir') == 7
    addpath(genpath(nyxPath), '-begin');
else
    foundNyx = locateFolder(rootDir, 'neuralynximport');
    if ~isempty(foundNyx)
        addpath(genpath(foundNyx), '-begin');
    end
end

fprintf('FORCED rootDir: %s\n', rootDir);
fprintf('FORCED resSavePath: %s\n', resSavePath);
if ~isempty(burstTableFile)
    fprintf('FORCED burstTableFile: %s\n', burstTableFile);
else
    fprintf('FORCED burstTableFile: none found; overlays will be skipped.\n');
end

if exist('Nlx2MatCSC', 'file') ~= 3 && exist('Nlx2MatCSC', 'file') ~= 2
    error(['MATLAB cannot find Nlx2MatCSC. Add the neuralynximport folder to the MATLAB path, ', ...
        'or place this script in the HC-31/CRCN folder containing neuralynximport.']);
end

hasBurstTable = ~isempty(burstTableFile) && exist(burstTableFile, 'file') == 2;

outDir = fullfile(rootDir, outputFolderName);
figDir = fullfile(outDir, 'figures');
perAnimalFigDir = fullfile(figDir, 'per_animal');
if exist(outDir, 'dir') ~= 7; mkdir(outDir); end
if exist(figDir, 'dir') ~= 7; mkdir(figDir); end
if exist(perAnimalFigDir, 'dir') ~= 7; mkdir(perAnimalFigDir); end

fprintf('\nHC-31: z-scored spectrograms\n');
fprintf('resSave input: %s\n', resSavePath);
if hasBurstTable
    fprintf('burst overlay input: %s\n', burstTableFile);
else
    fprintf('burst overlay input: not found; burst overlay rugs will be skipped.\n');
end
fprintf('output folder: %s\n\n', outDir);

%% ---------------- LOAD DATA ----------------
S = load(resSavePath);
if ~isfield(S, 'resSave')
    error('Loaded file does not contain variable resSave: %s', resSavePath);
end
resSave = S.resSave;

if hasBurstTable
    B = readtable(burstTableFile);
    B = standardiseBurstTable(B);
else
    B = table();
end

summaryRows = table();
bandRows = table();
overlayRows = table();

%% ---------------- MAIN LOOP ----------------
for ii = 1:numel(animalIndices)
    rIndex = animalIndices(ii);
    R = resSave(rIndex);
    animalName = getAnimalName(R, rIndex);

    fprintf('Processing %s / resSave(%d)\n', animalName, rIndex);

    if ~isfield(R, 'sectInt') || isempty(R.sectInt)
        warning('%s has no sectInt; skipping.', animalName);
        continue;
    end

    run1IntervalUs = [min(R.sectInt(:,1)), max(R.sectInt(:,2))];
    cscFile = getCscFile(rootDir, animalName);

    fprintf('  Loading Run1 LFP: %s\n', cscFile);
    [t, v, header] = Nlx2MatCSC(cscFile, [1 0 0 0 1], 1, 4, run1IntervalUs); %#ok<ASGLU>
    H = readNlxHeader(header);

    [tallUs, lfpRaw, FsRaw] = makeContinuousLfp(t, v);
    if isfield(H, 'ADBitVolts')
        lfpVolts = double(lfpRaw(:)) .* H.ADBitVolts;
    else
        warning('%s: ADBitVolts missing; using raw CSC values.', animalName);
        lfpVolts = double(lfpRaw(:));
    end

    [lfpDs, tDsUs, FsDs, validLfpMask] = downsampleLfp(lfpVolts, tallUs, FsRaw, targetFs);
    fprintf('  Raw Fs %.2f Hz -> downsampled Fs %.2f Hz\n', FsRaw, FsDs);

    % Prepare LFP for spectrogram. Fill rare NaNs from record gaps so the
    % spectrogram can run, but keep the valid mask in the summary.
    lfpForSpec = double(lfpDs(:));
    lfpForSpec = fillMissingForSpectrogram(lfpForSpec);
    lfpForSpec = lfpForSpec - median(lfpForSpec(isfinite(lfpForSpec)));

    % Spectrogram.
    winSamples = max(16, round(windowSeconds * FsDs));
    stepSamples = max(1, round(stepSeconds * FsDs));
    overlapSamples = max(0, winSamples - stepSamples);
    nfft = max(512, 2^nextpow2(winSamples));

    try
        [Sxx, F, Tsec, P] = spectrogram(lfpForSpec, hamming(winSamples), overlapSamples, nfft, FsDs);
        power = abs(Sxx).^2;
        if ~isempty(P) && all(size(P) == size(power))
            power = P;
        end
    catch ME
        error('spectrogram failed for %s: %s', animalName, ME.message);
    end

    keepF = F >= 0 & F <= freqMaxComputeHz;
    F = F(keepF);
    power = power(keepF, :);

    powerDb = 10 .* log10(power + eps);
    zPower = zscoreRows(powerDb);
    timeMin = ((tDsUs(1) - run1IntervalUs(1)) / 1e6 + Tsec(:)) ./ 60;

    % Position trace for beta-focused plot.
    [posTimeUs, linPos, speedCmS] = getRun1PositionAndSpeed(R); %#ok<ASGLU>
    posTimeMin = (posTimeUs - run1IntervalUs(1)) ./ 60e6;

    % Save summary rows.
    srow = table({animalName}, rIndex, FsRaw, FsDs, numel(F), numel(Tsec), min(F), max(F), ...
        min(timeMin), max(timeMin), mean(validLfpMask), ...
        'VariableNames', {'animal','resSaveIndex','rawFsHz','downsampledFsHz','nFrequencyBins','nTimeBins', ...
        'minFrequencyHz','maxFrequencyHz','minTimeMin','maxTimeMin','fractionValidLfpSamples'});
    summaryRows = [summaryRows; srow]; %#ok<AGROW>

    % Band z-power time courses.
    for b = 1:numel(bandDefs)
        bandName = bandDefs(b).name;
        bandRange = bandDefs(b).rangeHz;
        inBand = F >= bandRange(1) & F <= bandRange(2);
        if ~any(inBand)
            continue;
        end
        meanZ = mean(zPower(inBand, :), 1, 'omitnan')';
        tmp = table(repmat({animalName}, numel(timeMin), 1), repmat(rIndex, numel(timeMin), 1), ...
            repmat({bandName}, numel(timeMin), 1), timeMin(:), meanZ(:), ...
            'VariableNames', {'animal','resSaveIndex','band','timeMinFromRun1Start','meanZPower'});
        bandRows = [bandRows; tmp]; %#ok<AGROW>
    end

    % Plot 1: 1-80 Hz z-scored spectrogram.
    plotZSpecFigure(F, timeMin, zPower, plotRangesHz(1,:), zColorLimits, R, run1IntervalUs, [], [], [], ...
        sprintf('%s z-scored Run1 spectrogram, 1-80 Hz', animalName), ...
        fullfile(perAnimalFigDir, sprintf('%s_zspec_1_80Hz.png', sanitizeFileName(animalName))));

    % Plot 2: 1-50 Hz z-scored spectrogram.
    plotZSpecFigure(F, timeMin, zPower, plotRangesHz(2,:), zColorLimits, R, run1IntervalUs, [], [], [], ...
        sprintf('%s z-scored Run1 spectrogram, 1-50 Hz', animalName), ...
        fullfile(perAnimalFigDir, sprintf('%s_zspec_1_50Hz.png', sanitizeFileName(animalName))));

    % Plot 3: beta-focused spectrogram with burst rugs and position trace.
    betaTimes = [];
    beta2Times = [];
    if hasBurstTable && ~isempty(B)
        animalRows = strcmp(cellstr(B.animal), animalName) & B.excludedAsArtifact == false;
        if any(animalRows)
            betaRows = animalRows & strcmp(cellstr(B.band), 'beta_13_30Hz');
            beta2Rows = animalRows & strcmp(cellstr(B.band), 'beta2_23_30Hz');
            betaTimes = (B.burstPeakUs(betaRows) - run1IntervalUs(1)) ./ 60e6;
            beta2Times = (B.burstPeakUs(beta2Rows) - run1IntervalUs(1)) ./ 60e6;
        end

        orow = table({animalName}, rIndex, numel(betaTimes), numel(beta2Times), ...
            'VariableNames', {'animal','resSaveIndex','nBetaBurstsOverlay','nBeta2BurstsOverlay'});
        overlayRows = [overlayRows; orow]; %#ok<AGROW>
    end

    plotBetaFocusedFigure(F, timeMin, zPower, zColorLimits, R, run1IntervalUs, ...
        betaTimes, beta2Times, betaRugYHz, beta2RugYHz, maxBurstDotsPerBand, ...
        posTimeMin, linPos, ...
        sprintf('%s beta-focused z-scored spectrogram with burst timing', animalName), ...
        fullfile(perAnimalFigDir, sprintf('%s_zspec_10_35Hz_with_bursts_and_position.png', sanitizeFileName(animalName))));

    fprintf('  Finished %s\n\n', animalName);
end

%% ---------------- GROUP BAND TIME-COURSE SUMMARY ----------------
if ~isempty(bandRows)
    groupSummary = makeOneMinuteGroupSummary(bandRows);
else
    groupSummary = table();
end

%% ---------------- SAVE TABLES ----------------
writetable(summaryRows, fullfile(outDir, 'hc31_batch6_zspectrogram_summary.csv'));
writetable(bandRows, fullfile(outDir, 'hc31_batch6_band_zpower_timecourses.csv'));
if ~isempty(groupSummary)
    writetable(groupSummary, fullfile(outDir, 'hc31_batch6_band_zpower_1min_group_summary.csv'));
end
if ~isempty(overlayRows)
    writetable(overlayRows, fullfile(outDir, 'hc31_batch6_burst_overlay_counts.csv'));
end

%% ---------------- GROUP FIGURE ----------------
if ~isempty(groupSummary)
    plotGroupBandTimecourse(groupSummary, fullfile(figDir, 'batch6_group_mean_band_zpower_timecourses.png'));
end

%% ---------------- SUMMARY NOTES ----------------
notesPath = fullfile(outDir, 'hc31_batch6_summary_notes.txt');
fid = fopen(notesPath, 'w');
fprintf(fid, 'HC-31 z-scored spectrograms over Run1\n');
fprintf(fid, 'Generated: %s\n\n', datestr(now));
fprintf(fid, 'Inputs:\n');
fprintf(fid, '  resSave: %s\n', resSavePath);
if hasBurstTable
    fprintf(fid, '  burst table: %s\n', burstTableFile);
else
    fprintf(fid, '  burst table: not found; overlay rugs skipped.\n');
end
fprintf(fid, '\nSettings:\n');
fprintf(fid, '  windowSeconds = %.3f\n', windowSeconds);
fprintf(fid, '  stepSeconds = %.3f\n', stepSeconds);
fprintf(fid, '  computed frequency range = 0-%.1f Hz\n', freqMaxComputeHz);
fprintf(fid, '  z-score is calculated separately for each frequency across time.\n');
fprintf(fid, '  colour limits = [%.1f %.1f] z units.\n', zColorLimits(1), zColorLimits(2));
fprintf(fid, '\nInterpretation:\n');
fprintf(fid, '  These figures show relative time-varying power at each frequency.\n');
fprintf(fid, '  They are designed to make transient beta/beta2 events easier to see.\n');
fprintf(fid, '  They should not be interpreted as raw power or absolute beta power.\n');
fprintf(fid, '  Vertical lines mark Run1 subepoch/extension boundaries.\n');
fprintf(fid, '  Burst rugs, if present, show burst peak times only; their y-position is visual, not peak frequency.\n');
fclose(fid);

fprintf('Saved Batch 6 outputs to:\n%s\n', outDir);
fprintf('Done.\n');

%% ========================================================================
% Local functions
% ========================================================================
