% psdspec.m
% ------------------------------------------------------------
% Updated: spectrogram colour bar is labelled as power in dB.
% Updated: group spectra are interpolated onto a common frequency grid before averaging.
% HC-31 power spectra, spectrograms, and burst peak-frequency analysis.
%
% Purpose:
%   1. Plot broadband power spectra / spectrograms for each analysed animal.
%   2. Average the spectrogram over time to produce one smoothed spectrum.
%   3. Compare average spectra in novel vs familiar Run1 track sections.
%   4. Estimate individual burst peak frequency in the 20-30 Hz range.
%
% Preferred method:
%   If Chronux is installed and on the MATLAB path, this script uses:
%       mtspecgramc
%       mtspectrumc
%
% Fallback method:
%   If Chronux is not available, the script uses MATLAB spectrogram/pwelch.
%
% Inputs:
%   <HC31_DATA_ROOT>/resSave.mat
%   <HC31_DATA_ROOT>/csc_files\...
%   Optional burst table from:
%       beta_burst_over_time_outputs_BETA13_30_FUNC\hc31_detected_beta_bursts.csv
%   If that is not found, it falls back to:
%       beta_burst_over_time_outputs_FUNC\hc31_detected_beta_bursts.csv
%
% Outputs:
%   <HC31_DATA_ROOT>/power_spectra_spectrogram_outputs\
%       hc31_power_spectrum_summary.csv
%       hc31_condition_power_spectra_long.csv
%       hc31_burst_peak_frequency_20_30Hz.csv
%       figures\
%
% Run:
%   cd('<HC31_DATA_ROOT>')
%   psdspec
%
% If MATLAB refuses to run scripts directly:
%   code = fileread('psdspec.m');
%   eval(code)

clear; clc; close all;

%% ------------------------------------------------------------------------
% 1. Settings
% -------------------------------------------------------------------------

direc = getenv('HC31_DATA_ROOT');
if isempty(direc) || exist(direc, 'dir') ~= 7
    direc = uigetdir(pwd, 'Select the HC-31 root folder containing resSave.mat');
    if isequal(direc, 0)
        error('HC31:NoDataRoot', 'No HC-31 data root selected.');
    end
end

animalIndices = 5:9;
targetFs = 1000;
speedThresholdCmS = 5;

% Spectral settings
fpass = [1 150];               % broadband view
movingWindowS = [2 0.5];       % spectrogram: 2 s window, 0.5 s step
chronuxTapers = [3 5];         % time-bandwidth product 3, 5 tapers
nfftFallback = 2048;

% Individual burst peak-frequency settings
burstSegmentHalfWidthS = 0.300;  % peak +/- 300 ms
burstPeakBandHz = [20 30];       % requested peak-frequency range for individual bursts

outDir = fullfile(direc, 'power_spectra_spectrogram_outputs');
figDir = fullfile(outDir, 'figures');

if exist(outDir, 'dir') ~= 7
    mkdir(outDir);
end
if exist(figDir, 'dir') ~= 7
    mkdir(figDir);
end

% Add Neuralynx import tools.
addpath(genpath(fullfile(direc, 'neuralynximport')));

% Add Chronux if it is present inside the project folder.
if exist(fullfile(direc, 'chronux'), 'dir') == 7
    addpath(genpath(fullfile(direc, 'chronux')));
end

hasChronuxSpecgram = exist('mtspecgramc', 'file') == 2 || exist('mtspecgramc', 'file') == 3;
hasChronuxSpectrum = exist('mtspectrumc', 'file') == 2 || exist('mtspectrumc', 'file') == 3;

if hasChronuxSpecgram
    fprintf('Chronux mtspecgramc found. Using Chronux for spectrograms.\n');
else
    fprintf('Chronux mtspecgramc not found. Using MATLAB spectrogram fallback.\n');
end

if hasChronuxSpectrum
    fprintf('Chronux mtspectrumc found. Using Chronux for individual burst spectra.\n');
else
    fprintf('Chronux mtspectrumc not found. Using MATLAB pwelch fallback for individual burst spectra.\n');
end

%% ------------------------------------------------------------------------
% 2. Load resSave and optional burst table
% -------------------------------------------------------------------------

resPath = fullfile(direc, 'resSave.mat');
if exist(resPath, 'file') ~= 2
    resPath = fullfile(direc, 'resSave');
end

if exist(resPath, 'file') ~= 2
    error('Could not find resSave.mat or resSave in: %s', direc);
end

loaded = load(resPath);
resSave = loaded.resSave;

% Prefer the updated 13-30 beta outputs, but fall back to older output.
burstCsvNew = fullfile(direc, 'beta_burst_over_time_outputs_BETA13_30_FUNC', 'hc31_detected_beta_bursts.csv');
burstCsvOld = fullfile(direc, 'beta_burst_over_time_outputs_FUNC', 'hc31_detected_beta_bursts.csv');

if exist(burstCsvNew, 'file') == 2
    burstCsv = burstCsvNew;
elseif exist(burstCsvOld, 'file') == 2
    burstCsv = burstCsvOld;
else
    burstCsv = '';
end

if ~isempty(burstCsv)
    B = readtable(burstCsv);
    fprintf('Loaded burst table:\n%s\n\n', burstCsv);
else
    B = table();
    fprintf('No detected-burst table found. Individual burst peak-frequency analysis will be skipped.\n\n');
end

%% ------------------------------------------------------------------------
% 3. Output table containers
% -------------------------------------------------------------------------

summaryAnimal = {};
summaryResIndex = [];
summaryCondition = {};
summaryThetaPeakHz = [];
summaryThetaPeakPower = [];
summaryBeta13_30PeakHz = [];
summaryBeta13_30PeakPower = [];
summaryBeta2PeakHz = [];
summaryBeta2PeakPower = [];
summaryGamma30_100MeanPower = [];
summaryNTimeWindows = [];

longAnimal = {};
longResIndex = [];
longCondition = {};
longFrequencyHz = [];
longPower = [];
longPowerDb = [];

burstAnimal = {};
burstResIndex = [];
burstBand = {};
burstCategory = {};
burstPeakUsCol = [];
burstPeakFreq20_30Hz = [];
burstPeakPower20_30 = [];
burstDurationSCol = [];
burstPeakZCol = [];

%% ------------------------------------------------------------------------
% 4. Main animal loop
% -------------------------------------------------------------------------

for ai = 1:numel(animalIndices)

    i = animalIndices(ai);
    R = resSave(i);
    animalName = R.spAll(1).animal;

    fprintf('\nProcessing resSave(%d): %s\n', i, animalName);

    %% 4A. Determine CSC path

    if strcmp(animalName, 'ANM00190422')
        fileName = fullfile(direc, 'csc_files', 'ANM00190422', '2012-12-09_10-48-47', 'CSC33.ncs');
    elseif strcmp(animalName, 'ANM204878')
        fileName = fullfile(direc, 'csc_files', 'ANM204878', '2013-05-11_09-32-49', 'CSC33.ncs');
    elseif strcmp(animalName, 'ANM212379')
        fileName = fullfile(direc, 'csc_files', 'ANM212379', '2013-06-08_10-10-46', 'CSC53.ncs');
    elseif strcmp(animalName, 'ANM228899')
        fileName = fullfile(direc, 'csc_files', 'ANM228899', '2013-11-02_10-16-53', 'CSC45.ncs');
    elseif strcmp(animalName, 'ANM228900')
        fileName = fullfile(direc, 'csc_files', 'ANM228900', '2013-11-03_08-59-40', 'CSC45.ncs');
    else
        error('Unknown animal name: %s', animalName);
    end

    if exist(fileName, 'file') ~= 2
        error('Could not find CSC file: %s', fileName);
    end

    %% 4B. Load Run1 LFP

    run1IntervalUs = [min(R.sectInt(:,1)), max(R.sectInt(:,2))];

    fprintf('  Loading Run1 LFP...\n');
    [t, v, header] = Nlx2MatCSC(fileName, [1 0 0 0 1], 1, 4, run1IntervalUs); %#ok<ASGLU>

    t = double(t(:));
    v = double(v);
    vall = v(:);

    tDiff = diff(t);
    mtDiff = mode(tDiff);
    noSkip = tDiff > mtDiff-2 & tDiff < mtDiff+2;

    if any(noSkip)
        FsRaw = 1 / (mean(tDiff(noSkip)) / 512 / 1e6);
    else
        FsRaw = 32552.08;
    end

    fprintf('  Raw Fs estimate: %.2f Hz\n', FsRaw);

    % Build an approximate continuous sample-time vector.
    dtUs = 1e6 / FsRaw;
    tallUs = t(1) + (0:(numel(vall)-1))' .* dtUs;

    % Downsample to around targetFs.
    dsFactor = max(1, round(FsRaw / targetFs));
    FsDs = FsRaw / dsFactor;

    vallNoNan = vall;
    vallNoNan(isnan(vallNoNan)) = 0;

    try
        lfpDs = decimate(vallNoNan, dsFactor);
    catch
        lfpDs = vallNoNan(1:dsFactor:end);
    end

    tDsUs = tallUs(1:dsFactor:end);
    nMin = min(numel(lfpDs), numel(tDsUs));
    lfpDs = double(lfpDs(1:nMin));
    tDsUs = double(tDsUs(1:nMin));

    % Detrend and centre.
    lfpDs = lfpDs - mean(lfpDs, 'omitnan');
    lfpDs(isnan(lfpDs)) = 0;

    fprintf('  Downsampled Fs: %.2f Hz\n', FsDs);

    %% 4C. Interpolate position and speed onto downsampled LFP time base

    posU = R.posMazeLin(1);
    posData = posU.data;

    posTimeUs = posData(:,1);
    linPos = posData(:,2);

    posDs = interp1(posTimeUs, linPos, tDsUs, 'linear', NaN);

    if size(posData,2) >= 4
        rawSpeed = posData(:,4);
        if isfield(posU, 'unitsPerCm') && isfield(posU, 'unitsPerSecond')
            speedCmS = rawSpeed .* (1 ./ posU.unitsPerCm) .* posU.unitsPerSecond;
        else
            speedCmS = rawSpeed;
        end
        speedDs = interp1(posTimeUs, speedCmS, tDsUs, 'linear', NaN);
    else
        speedDs = NaN(size(tDsUs));
    end

    movingSampleMask = ~isnan(posDs) & ~isnan(speedDs) & speedDs >= speedThresholdCmS;

    %% 4D. Calculate spectrogram

    fprintf('  Calculating spectrogram / time-resolved spectrum...\n');

    if hasChronuxSpecgram
        params = [];
        params.Fs = FsDs;
        params.tapers = chronuxTapers;
        params.fpass = fpass;
        params.trialave = 0;

        [Sspec, tSpecS, fSpec] = mtspecgramc(lfpDs, movingWindowS, params);

        % Chronux output is time x freq.
        Pspec = Sspec;
        fSpec = fSpec(:);
        tSpecS = tSpecS(:);
    else
        winSamples = round(movingWindowS(1) * FsDs);
        stepSamples = round(movingWindowS(2) * FsDs);
        overlapSamples = max(0, winSamples - stepSamples);

        if winSamples < 8
            winSamples = 8;
        end
        if nfftFallback < winSamples
            nfftFallback = 2^nextpow2(winSamples);
        end

        [Smat, fSpec, tSpecS, Pmat] = spectrogram(lfpDs, hamming(winSamples), overlapSamples, nfftFallback, FsDs); %#ok<ASGLU>
        keepF = fSpec >= fpass(1) & fSpec <= fpass(2);
        fSpec = fSpec(keepF);
        Pspec = Pmat(keepF, :)';
        tSpecS = tSpecS(:);
    end

    % Absolute time of spectrogram windows.
    tSpecUs = tDsUs(1) + tSpecS .* 1e6;

    % Classify spectrogram time bins as all-moving, novel-moving, or familiar-moving.
    posSpec = interp1(posTimeUs, linPos, tSpecUs, 'linear', NaN);

    if size(posData,2) >= 4
        speedSpec = interp1(posTimeUs, speedCmS, tSpecUs, 'linear', NaN);
    else
        speedSpec = NaN(size(tSpecUs));
    end

    specMoving = ~isnan(posSpec) & ~isnan(speedSpec) & speedSpec >= speedThresholdCmS;

    specNovel = false(size(tSpecUs));
    specFamiliar = false(size(tSpecUs));

    for s = 1:size(R.sectInt,1)
        subStart = R.sectInt(s,1);
        subEnd = R.sectInt(s,2);

        novelStartPos = min(R.sectExt(s,:));
        novelEndPos = max(R.sectExt(s,:));

        inSub = tSpecUs >= subStart & tSpecUs <= subEnd & specMoving;
        inNovel = inSub & posSpec >= novelStartPos & posSpec <= novelEndPos;
        inFam = inSub & ~inNovel;

        specNovel = specNovel | inNovel;
        specFamiliar = specFamiliar | inFam;
    end

    %% 4E. Average time axis into smoothed spectra

    conditionNames = {'all_moving','familiar','novel'};
    conditionMasks = {specMoving, specFamiliar, specNovel};

    animalSpectra = struct();

    for c = 1:numel(conditionNames)

        conditionName = conditionNames{c};
        conditionMask = conditionMasks{c};

        if sum(conditionMask) > 0
            meanPower = mean(Pspec(conditionMask,:), 1, 'omitnan');
        else
            meanPower = NaN(1, numel(fSpec));
        end

        meanPower = meanPower(:);
        powerDb = 10 .* log10(meanPower);

        animalSpectra.(conditionName).power = meanPower;
        animalSpectra.(conditionName).powerDb = powerDb;
        animalSpectra.(conditionName).nWindows = sum(conditionMask);

        % Save long-format spectrum rows.
        for fi = 1:numel(fSpec)
            longAnimal{end+1,1} = animalName; %#ok<SAGROW>
            longResIndex(end+1,1) = i; %#ok<SAGROW>
            longCondition{end+1,1} = conditionName; %#ok<SAGROW>
            longFrequencyHz(end+1,1) = fSpec(fi); %#ok<SAGROW>
            longPower(end+1,1) = meanPower(fi); %#ok<SAGROW>
            longPowerDb(end+1,1) = powerDb(fi); %#ok<SAGROW>
        end

        % Band summaries.
        thetaMask = fSpec >= 6 & fSpec <= 10;
        betaMask = fSpec >= 13 & fSpec <= 30;
        beta2Mask = fSpec >= 23 & fSpec <= 30;
        gammaMask = fSpec >= 30 & fSpec <= 100;

        thetaPeakHz = NaN; thetaPeakPower = NaN;
        betaPeakHz = NaN; betaPeakPower = NaN;
        beta2PeakHz = NaN; beta2PeakPower = NaN;
        gammaMeanPower = NaN;

        if any(thetaMask) && any(~isnan(meanPower(thetaMask)))
            fLocal = fSpec(thetaMask);
            pLocal = meanPower(thetaMask);
            [thetaPeakPower, indMax] = max(pLocal);
            thetaPeakHz = fLocal(indMax);
        end

        if any(betaMask) && any(~isnan(meanPower(betaMask)))
            fLocal = fSpec(betaMask);
            pLocal = meanPower(betaMask);
            [betaPeakPower, indMax] = max(pLocal);
            betaPeakHz = fLocal(indMax);
        end

        if any(beta2Mask) && any(~isnan(meanPower(beta2Mask)))
            fLocal = fSpec(beta2Mask);
            pLocal = meanPower(beta2Mask);
            [beta2PeakPower, indMax] = max(pLocal);
            beta2PeakHz = fLocal(indMax);
        end

        if any(gammaMask)
            gammaMeanPower = mean(meanPower(gammaMask), 'omitnan');
        end

        summaryAnimal{end+1,1} = animalName; %#ok<SAGROW>
        summaryResIndex(end+1,1) = i; %#ok<SAGROW>
        summaryCondition{end+1,1} = conditionName; %#ok<SAGROW>
        summaryThetaPeakHz(end+1,1) = thetaPeakHz; %#ok<SAGROW>
        summaryThetaPeakPower(end+1,1) = thetaPeakPower; %#ok<SAGROW>
        summaryBeta13_30PeakHz(end+1,1) = betaPeakHz; %#ok<SAGROW>
        summaryBeta13_30PeakPower(end+1,1) = betaPeakPower; %#ok<SAGROW>
        summaryBeta2PeakHz(end+1,1) = beta2PeakHz; %#ok<SAGROW>
        summaryBeta2PeakPower(end+1,1) = beta2PeakPower; %#ok<SAGROW>
        summaryGamma30_100MeanPower(end+1,1) = gammaMeanPower; %#ok<SAGROW>
        summaryNTimeWindows(end+1,1) = sum(conditionMask); %#ok<SAGROW>
    end

    %% 4F. Save figures: spectrogram and averaged spectra

    % Spectrogram figure.
    figSpec = figure('Color','w', 'Name', sprintf('%s Run1 spectrogram', animalName));
    imagesc(tSpecS ./ 60, fSpec, 10 .* log10(Pspec'));
    axis xy;
    xlabel('time from Run1 start, minutes');
    ylabel('frequency, Hz');
    title(sprintf('%s Run1 spectrogram', animalName), 'Interpreter','none');
    cb = colorbar;
    ylabel(cb, 'Power (dB; 10 log_{10})');
    ylim([1 120]);
    saveas(figSpec, fullfile(figDir, sprintf('%s_Run1_spectrogram_1_120Hz.png', animalName)));

    % All-moving average spectrum.
    figPower = figure('Color','w', 'Name', sprintf('%s average power spectrum', animalName));
    plot(fSpec, animalSpectra.all_moving.powerDb, 'k', 'LineWidth', 1.5);
    hold on;
    xline(8, 'k--');
    xline(13, 'b:');
    xline(30, 'b:');
    xline(100, 'r:');
    hold off;
    xlabel('frequency, Hz');
    ylabel('power, dB');
    title(sprintf('%s average Run1 power spectrum, moving periods', animalName), 'Interpreter','none');
    grid on;
    xlim([1 120]);
    saveas(figPower, fullfile(figDir, sprintf('%s_average_power_spectrum_moving.png', animalName)));

    % Familiar vs novel average spectrum.
    figCond = figure('Color','w', 'Name', sprintf('%s familiar vs novel spectrum', animalName));
    plot(fSpec, animalSpectra.familiar.powerDb, 'LineWidth', 1.5, 'DisplayName', 'familiar');
    hold on;
    plot(fSpec, animalSpectra.novel.powerDb, 'LineWidth', 1.5, 'DisplayName', 'novel');
    xline(8, 'k--', 'DisplayName', '8 Hz');
    xline(13, 'b:', 'DisplayName', '13 Hz');
    xline(30, 'b:', 'DisplayName', '30 Hz');
    xline(100, 'r:', 'DisplayName', '100 Hz');
    hold off;
    xlabel('frequency, Hz');
    ylabel('power, dB');
    title(sprintf('%s familiar vs novel average spectra', animalName), 'Interpreter','none');
    legend('Location','best');
    grid on;
    xlim([1 120]);
    saveas(figCond, fullfile(figDir, sprintf('%s_familiar_vs_novel_average_spectrum.png', animalName)));

    %% 4G. Individual burst peak frequency in 20-30 Hz

    if ~isempty(B)

        rowsAnimal = strcmp(B.animal, animalName);

        if ismember('excludedAsArtifact', B.Properties.VariableNames)
            rowsAnimal = rowsAnimal & B.excludedAsArtifact == 0;
        end

        rowsIdx = find(rowsAnimal);

        fprintf('  Calculating individual-burst peak frequencies for %d bursts...\n', numel(rowsIdx));

        for bi = 1:numel(rowsIdx)

            row = rowsIdx(bi);

            if ~ismember('burstPeakUs', B.Properties.VariableNames)
                continue;
            end

            burstPeakUs = B.burstPeakUs(row);

            if burstPeakUs < tDsUs(1) || burstPeakUs > tDsUs(end)
                continue;
            end

            segStartUs = burstPeakUs - burstSegmentHalfWidthS * 1e6;
            segEndUs = burstPeakUs + burstSegmentHalfWidthS * 1e6;

            segMask = tDsUs >= segStartUs & tDsUs <= segEndUs;

            if sum(segMask) < round(0.25 * FsDs)
                continue;
            end

            segData = lfpDs(segMask);
            segData = segData - mean(segData, 'omitnan');
            segData(isnan(segData)) = 0;

            if hasChronuxSpectrum
                params2 = [];
                params2.Fs = FsDs;
                params2.tapers = chronuxTapers;
                params2.fpass = [10 40];
                [pBurst, fBurst] = mtspectrumc(segData, params2);
                pBurst = pBurst(:);
                fBurst = fBurst(:);
            else
                winBurst = min(numel(segData), round(0.25 * FsDs));
                if winBurst < 8
                    winBurst = numel(segData);
                end
                [pBurst, fBurst] = pwelch(segData, hamming(winBurst), [], nfftFallback, FsDs);
                keep = fBurst >= 10 & fBurst <= 40;
                pBurst = pBurst(keep);
                fBurst = fBurst(keep);
            end

            peakMask = fBurst >= burstPeakBandHz(1) & fBurst <= burstPeakBandHz(2);

            if any(peakMask)
                fLocal = fBurst(peakMask);
                pLocal = pBurst(peakMask);
                [peakP, peakInd] = max(pLocal);
                peakF = fLocal(peakInd);
            else
                peakF = NaN;
                peakP = NaN;
            end

            % Classify burst as novel/familiar from peak time and peak position.
            category = 'unclassified';

            if ismember('peakPosition', B.Properties.VariableNames)
                peakPos = B.peakPosition(row);
            else
                peakPos = NaN;
            end

            if ismember('peakSpeedCmS', B.Properties.VariableNames)
                peakSpeed = B.peakSpeedCmS(row);
            else
                peakSpeed = NaN;
            end

            for s = 1:size(R.sectInt,1)
                if burstPeakUs >= R.sectInt(s,1) && burstPeakUs <= R.sectInt(s,2)

                    novelStartPos = min(R.sectExt(s,:));
                    novelEndPos = max(R.sectExt(s,:));

                    if isnan(peakPos) || isnan(peakSpeed)
                        category = 'unclassified';
                    elseif peakSpeed < speedThresholdCmS
                        category = 'below_speed_threshold';
                    elseif peakPos >= novelStartPos && peakPos <= novelEndPos
                        category = 'novel';
                    else
                        category = 'familiar';
                    end
                end
            end

            if ismember('band', B.Properties.VariableNames)
                burstBandValue = B.band{row};
            else
                burstBandValue = '';
            end

            if ismember('burstDurationS', B.Properties.VariableNames)
                durValue = B.burstDurationS(row);
            else
                durValue = NaN;
            end

            if ismember('peakZ', B.Properties.VariableNames)
                peakZValue = B.peakZ(row);
            else
                peakZValue = NaN;
            end

            burstAnimal{end+1,1} = animalName; %#ok<SAGROW>
            burstResIndex(end+1,1) = i; %#ok<SAGROW>
            burstBand{end+1,1} = burstBandValue; %#ok<SAGROW>
            burstCategory{end+1,1} = category; %#ok<SAGROW>
            burstPeakUsCol(end+1,1) = burstPeakUs; %#ok<SAGROW>
            burstPeakFreq20_30Hz(end+1,1) = peakF; %#ok<SAGROW>
            burstPeakPower20_30(end+1,1) = peakP; %#ok<SAGROW>
            burstDurationSCol(end+1,1) = durValue; %#ok<SAGROW>
            burstPeakZCol(end+1,1) = peakZValue; %#ok<SAGROW>
        end
    end
end

%% ------------------------------------------------------------------------
% 5. Save output tables
% -------------------------------------------------------------------------

summaryTable = table(summaryAnimal, summaryResIndex, summaryCondition, ...
    summaryThetaPeakHz, summaryThetaPeakPower, ...
    summaryBeta13_30PeakHz, summaryBeta13_30PeakPower, ...
    summaryBeta2PeakHz, summaryBeta2PeakPower, ...
    summaryGamma30_100MeanPower, summaryNTimeWindows, ...
    'VariableNames', {'animal','resSaveIndex','condition', ...
    'theta6_10PeakHz','theta6_10PeakPower', ...
    'beta13_30PeakHz','beta13_30PeakPower', ...
    'beta2_23_30PeakHz','beta2_23_30PeakPower', ...
    'gamma30_100MeanPower','nSpectrogramTimeWindows'});

summaryCsv = fullfile(outDir, 'hc31_power_spectrum_summary.csv');
writetable(summaryTable, summaryCsv);

longTable = table(longAnimal, longResIndex, longCondition, longFrequencyHz, longPower, longPowerDb, ...
    'VariableNames', {'animal','resSaveIndex','condition','frequencyHz','power','powerDb'});

longCsv = fullfile(outDir, 'hc31_condition_power_spectra_long.csv');
writetable(longTable, longCsv);

fprintf('\nSaved power spectrum summary:\n%s\n', summaryCsv);
fprintf('Saved long-format spectra:\n%s\n', longCsv);

if ~isempty(burstAnimal)

    burstPeakTable = table(burstAnimal, burstResIndex, burstBand, burstCategory, burstPeakUsCol, ...
        burstPeakFreq20_30Hz, burstPeakPower20_30, burstDurationSCol, burstPeakZCol, ...
        'VariableNames', {'animal','resSaveIndex','burstBand','category','burstPeakUs', ...
        'peakFrequency20_30Hz','peakPower20_30Hz','burstDurationS','peakZ'});

    burstPeakCsv = fullfile(outDir, 'hc31_burst_peak_frequency_20_30Hz.csv');
    writetable(burstPeakTable, burstPeakCsv);

    fprintf('Saved individual burst peak-frequency table:\n%s\n', burstPeakCsv);

    %% 5A. Histogram of individual burst peak frequencies

    validPeak = ~isnan(burstPeakTable.peakFrequency20_30Hz);

    figHist = figure('Color','w', 'Name', 'Individual burst peak frequencies 20-30 Hz');
    histogram(burstPeakTable.peakFrequency20_30Hz(validPeak), 'BinWidth', 0.5);
    xlabel('individual burst peak frequency, Hz');
    ylabel('burst count');
    title('Individual burst peak frequencies in 20-30 Hz range');
    grid on;
    saveas(figHist, fullfile(figDir, 'individual_burst_peak_frequency_20_30Hz_histogram.png'));

    % Familiar vs novel histograms, if available.
    validNF = validPeak & (strcmp(burstPeakTable.category, 'familiar') | strcmp(burstPeakTable.category, 'novel'));

    figHistNF = figure('Color','w', 'Name', 'Novel vs familiar individual burst peak frequencies');
    hold on;
    histogram(burstPeakTable.peakFrequency20_30Hz(validNF & strcmp(burstPeakTable.category, 'familiar')), ...
        'BinWidth', 0.5, 'Normalization', 'probability', 'DisplayName', 'familiar');
    histogram(burstPeakTable.peakFrequency20_30Hz(validNF & strcmp(burstPeakTable.category, 'novel')), ...
        'BinWidth', 0.5, 'Normalization', 'probability', 'DisplayName', 'novel');
    hold off;
    xlabel('individual burst peak frequency, Hz');
    ylabel('probability');
    title('Individual burst peak frequencies: familiar vs novel');
    legend('Location','best');
    grid on;
    saveas(figHistNF, fullfile(figDir, 'individual_burst_peak_frequency_familiar_vs_novel.png'));
else
    fprintf('No individual burst peak-frequency rows generated.\n');
end

%% ------------------------------------------------------------------------
% 6. Group-level familiar vs novel spectra
% -------------------------------------------------------------------------
% Important correction:
%   Different animals can have slightly different frequency grids because
%   their downsampled sampling rates can differ slightly. Therefore, group
%   averages must be calculated after interpolating each animal spectrum onto
%   one common frequency grid. Do NOT group by exact frequency equality.

if ~isempty(longTable)

    commonF = (1:0.5:120)';
    conditionsForGroup = {'all_moving','familiar','novel'};

    figGroup = figure('Color','w', 'Name', 'Group mean spectra');
    hold on;

    groupRows = {};
    groupHeader = {'condition','frequencyHz','meanPowerDb','semPowerDb','nAnimals'};

    for c = 1:numel(conditionsForGroup)

        cond = conditionsForGroup{c};

        interpDbByAnimal = NaN(numel(commonF), numel(animalIndices));

        for ai = 1:numel(animalIndices)

            animalName = resSave(animalIndices(ai)).spAll(1).animal;

            rows = strcmp(longTable.animal, animalName) & strcmp(longTable.condition, cond);

            if any(rows)
                fAnimal = longTable.frequencyHz(rows);
                pAnimalDb = longTable.powerDb(rows);

                [fAnimalSorted, sortIdx] = sort(fAnimal);
                pAnimalSorted = pAnimalDb(sortIdx);

                % Remove duplicate frequencies within animal, if any.
                [fAnimalUnique, uniqueIdx] = unique(fAnimalSorted, 'stable');
                pAnimalUnique = pAnimalSorted(uniqueIdx);

                interpDbByAnimal(:,ai) = interp1(fAnimalUnique, pAnimalUnique, commonF, 'linear', NaN);
            end
        end

        meanDb = mean(interpDbByAnimal, 2, 'omitnan');
        semDb = std(interpDbByAnimal, 0, 2, 'omitnan') ./ sqrt(sum(~isnan(interpDbByAnimal), 2));
        nAnimalsAtF = sum(~isnan(interpDbByAnimal), 2);

        % Smooth only the displayed group curve. The CSV still stores the
        % interpolated mean at each common frequency.
        meanDbForPlot = movmean(meanDb, 3, 'omitnan');

        plot(commonF, meanDbForPlot, 'LineWidth', 1.8, 'DisplayName', cond);

        for fi = 1:numel(commonF)
            groupRows(end+1,:) = {cond, commonF(fi), meanDb(fi), semDb(fi), nAnimalsAtF(fi)}; %#ok<SAGROW>
        end
    end

    xline(8, 'k--', 'DisplayName', '8 Hz');
    xline(13, 'b:', 'DisplayName', '13 Hz');
    xline(30, 'b:', 'DisplayName', '30 Hz');
    xline(100, 'r:', 'DisplayName', '100 Hz');

    hold off;
    xlabel('frequency, Hz');
    ylabel('mean power, dB');
    title('Group mean power spectra');
    legend('Location','best');
    grid on;
    xlim([1 120]);

    saveas(figGroup, fullfile(figDir, 'group_mean_power_spectra_all_familiar_novel.png'));

    groupTable = cell2table(groupRows, 'VariableNames', groupHeader);
    groupCsv = fullfile(outDir, 'hc31_group_mean_power_spectra.csv');
    writetable(groupTable, groupCsv);

    fprintf('Saved group mean spectra with common-frequency interpolation:\n%s\n', groupCsv);
end

fprintf('\nPower spectra, spectrogram, and burst peak-frequency analysis complete.\n');
fprintf('Outputs saved to:\n%s\n', outDir);
