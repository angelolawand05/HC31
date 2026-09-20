function hc31_extract_beta_bursts_over_time_FUNC()
% Updated version: broad beta band is 13-30 Hz instead of 13-30 Hz.
% Beta2 remains 23-30 Hz.
% hc31_extract_beta_bursts_over_time_FUNC.m
% ------------------------------------------------------------
% Objective 3: Extract beta/beta2 bursts from hc-31 LFP data and plot
% burst frequency over time during Run1.
%
% This is a FUNCTION version, not a script version.
% It should work better on MATLAB versions that reject scripts with local
% functions at the bottom.
%
% Put this file in:
%   C:\Users\angel\Documents\MATLAB\CRCN\
%
% Run with:
%   hc31_extract_beta_bursts_over_time_FUNC
%
% Output folder:
%   C:\Users\angel\Documents\MATLAB\CRCN\beta_burst_over_time_outputs_BETA13_30_FUNC\

clear; clc; close all;

%% Settings

direc = 'C:\Users\angel\Documents\MATLAB\CRCN\';

animalIndices = 5:9;

targetFs = 1000;          % Downsample target, Hz
binSeconds = 60;          % Burst-frequency bin size
speedThresholdCmS = 5;    % Only analyse movement periods >= 5 cm/s

coreZ = 2;                % Burst must contain a peak above this z-score
edgeZ = 1;                % Burst edges defined by this lower z-score
minBurstDurationS = 0.150;
artifactZ = 12;           % Exclude extreme events as likely artefacts
filterOrder = 4;

bands(1).name = 'beta_13_30Hz';
bands(1).lowHz = 13;
bands(1).highHz = 30;

bands(2).name = 'beta2_23_30Hz';
bands(2).lowHz = 23;
bands(2).highHz = 30;

%% Load dataset

if exist(direc, 'dir') ~= 7
    error('Dataset folder not found: %s', direc);
end

addpath(genpath(fullfile(direc, 'neuralynximport')));

if exist('Nlx2MatCSC', 'file') ~= 3 && exist('Nlx2MatCSC', 'file') ~= 2
    error('MATLAB cannot find Nlx2MatCSC. Check neuralynximport is extracted and added to path.');
end

data = load(fullfile(direc, 'resSave.mat'));
resSave = data.resSave;

outDir = fullfile(direc, 'beta_burst_over_time_outputs_BETA13_30_FUNC');
figDir = fullfile(outDir, 'figures');

if exist(outDir, 'dir') ~= 7
    mkdir(outDir);
end
if exist(figDir, 'dir') ~= 7
    mkdir(figDir);
end

fprintf('Loaded resSave.mat successfully.\n');
fprintf('Output folder:\n%s\n\n', outDir);

%% Main analysis loop

burstRows = {};
binRows = {};

burstHeader = {'animal','resSaveIndex','band','burstStartUs','burstEndUs','burstPeakUs', ...
    'burstDurationS','peakZ','peakEnvelope','peakPosition','peakSpeedCmS','excludedAsArtifact'};

binHeader = {'animal','resSaveIndex','band','binNumber','binStartUs','binEndUs', ...
    'binMidMinutesFromRun1Start','validSecondsInBin','burstCount','burstRatePerMinute'};

for i = animalIndices

    R = resSave(i);
    animalName = R.spAll(1).animal;

    fprintf('Processing resSave(%d): %s\n', i, animalName);

    fileName = get_csc_file(direc, animalName);
    run1IntervalUs = [min(R.sectInt(:,1)), max(R.sectInt(:,2))];

    fprintf('  Loading Run1 LFP...\n');
    [t, v, header] = Nlx2MatCSC(fileName, [1 0 0 0 1], 1, 4, run1IntervalUs);
    H = readNlxHeader(header);

    [tallUs, vallRaw, FsRaw] = make_continuous_lfp(t, v);

    if isfield(H, 'ADBitVolts')
        vallVolts = double(vallRaw(:)) .* H.ADBitVolts;
    else
        warning('ADBitVolts not found in header. Using raw values without voltage scaling.');
        vallVolts = double(vallRaw(:));
    end

    fprintf('  Raw Fs estimate: %.2f Hz\n', FsRaw);

    [lfpDs, tDsUs, FsDs, validLfpMask] = downsample_lfp(vallVolts, tallUs, FsRaw, targetFs);
    fprintf('  Downsampled Fs: %.2f Hz\n', FsDs);

    posU = R.posMazeLin(1);
    [posDs, speedDsCmS] = interpolate_position_speed(posU, tDsUs);

    validPositionMask = ~isnan(posDs) & ~isnan(speedDsCmS);
    movingMask = speedDsCmS >= speedThresholdCmS;
    analysisMask = validLfpMask & validPositionMask & movingMask;

    for b = 1:numel(bands)

        band = bands(b);
        fprintf('  Detecting %s bursts...\n', band.name);

        [filtered, envelope, zEnv, bursts] = detect_bursts_duplicate_safe( ...
            lfpDs, FsDs, band.lowHz, band.highHz, filterOrder, ...
            analysisMask, coreZ, edgeZ, minBurstDurationS, artifactZ); %#ok<ASGLU>

        includedPeakTimes = [];

        for k = 1:numel(bursts)

            st = max(1, min(bursts(k).startIdx, numel(tDsUs)));
            en = max(1, min(bursts(k).endIdx, numel(tDsUs)));
            pk = max(1, min(bursts(k).peakIdx, numel(tDsUs)));

            excluded = bursts(k).isArtifact || ~analysisMask(pk);

            if ~excluded
                includedPeakTimes(end+1,1) = tDsUs(pk); %#ok<AGROW>
            end

            burstRows(end+1,:) = { ...
                animalName, i, band.name, ...
                tDsUs(st), tDsUs(en), tDsUs(pk), ...
                bursts(k).durationS, zEnv(pk), envelope(pk), ...
                posDs(pk), speedDsCmS(pk), logical(excluded)}; %#ok<AGROW>
        end

        binEdgesUs = run1IntervalUs(1):(binSeconds*1e6):run1IntervalUs(2);
        if binEdgesUs(end) < run1IntervalUs(2)
            binEdgesUs(end+1) = run1IntervalUs(2); %#ok<AGROW>
        end

        for binIdx = 1:(numel(binEdgesUs)-1)

            binStart = binEdgesUs(binIdx);
            binEnd = binEdgesUs(binIdx+1);

            inBinSamples = tDsUs >= binStart & tDsUs < binEnd & analysisMask;
            validSeconds = sum(inBinSamples) / FsDs;

            inBinBursts = includedPeakTimes >= binStart & includedPeakTimes < binEnd;
            burstCount = sum(inBinBursts);

            if validSeconds > 0
                burstRatePerMinute = burstCount / validSeconds * 60;
            else
                burstRatePerMinute = NaN;
            end

            midMin = ((binStart + binEnd)/2 - run1IntervalUs(1)) / 60e6;

            binRows(end+1,:) = { ...
                animalName, i, band.name, binIdx, binStart, binEnd, ...
                midMin, validSeconds, burstCount, burstRatePerMinute}; %#ok<AGROW>
        end
    end

    fprintf('  Finished %s\n\n', animalName);
end

%% Save CSV files

burstCsv = fullfile(outDir, 'hc31_detected_beta_bursts.csv');
binCsv = fullfile(outDir, 'hc31_beta_burst_frequency_over_time.csv');

write_cell_csv(burstCsv, [burstHeader; burstRows]);
write_cell_csv(binCsv, [binHeader; binRows]);

fprintf('Saved burst table:\n%s\n', burstCsv);
fprintf('Saved binned frequency table:\n%s\n\n', binCsv);

%% Make plots from binned table

% Convert binRows to easier vectors.
animals = unique_cell_column(binRows, 1);

for a = 1:numel(animals)

    animalName = animals{a};

    fig = figure('Color','w', 'Name', sprintf('%s beta burst frequency over time', animalName));
    hold on;

    for b = 1:numel(bands)
        bandName = bands(b).name;

        x = [];
        y = [];

        for row = 1:size(binRows,1)
            if strcmp(binRows{row,1}, animalName) && strcmp(binRows{row,3}, bandName)
                x(end+1,1) = binRows{row,7}; %#ok<AGROW>
                y(end+1,1) = binRows{row,10}; %#ok<AGROW>
            end
        end

        plot(x, y, '-o', 'LineWidth', 1.5, 'MarkerSize', 5, 'DisplayName', bandName);
    end

    xlabel('time from Run1 start, minutes');
    ylabel('burst frequency, bursts/min');
    title(sprintf('%s beta/beta2 burst frequency over Run1', animalName), 'Interpreter','none');
    legend('Location','best', 'Interpreter','none');
    grid on;
    hold off;

    saveas(fig, fullfile(figDir, sprintf('%s_beta_burst_frequency_over_time.png', animalName)));
end

% Mean plots across animals by bin number.
for b = 1:numel(bands)

    bandName = bands(b).name;

    maxBin = 0;
    for row = 1:size(binRows,1)
        if strcmp(binRows{row,3}, bandName)
            maxBin = max(maxBin, binRows{row,4});
        end
    end

    meanTime = NaN(maxBin,1);
    meanRate = NaN(maxBin,1);
    semRate = NaN(maxBin,1);

    for binIdx = 1:maxBin

        vals = [];
        times = [];

        for row = 1:size(binRows,1)
            if strcmp(binRows{row,3}, bandName) && binRows{row,4} == binIdx
                if ~isnan(binRows{row,10})
                    vals(end+1,1) = binRows{row,10}; %#ok<AGROW>
                    times(end+1,1) = binRows{row,7}; %#ok<AGROW>
                end
            end
        end

        if ~isempty(vals)
            meanRate(binIdx) = mean(vals);
            if numel(vals) > 1
                semRate(binIdx) = std(vals) / sqrt(numel(vals));
            else
                semRate(binIdx) = 0;
            end
            meanTime(binIdx) = mean(times);
        end
    end

    fig = figure('Color','w', 'Name', sprintf('Mean %s burst frequency over time', bandName));
    errorbar(meanTime, meanRate, semRate, '-o', 'LineWidth', 1.5, 'MarkerSize', 5);
    xlabel('time from Run1 start, minutes');
    ylabel('mean burst frequency, bursts/min');
    title(sprintf('Mean %s burst frequency over Run1', bandName), 'Interpreter','none');
    grid on;

    saveas(fig, fullfile(figDir, sprintf('mean_%s_burst_frequency_over_time.png', bandName)));
end

fprintf('Saved figures to:\n%s\n', figDir);
fprintf('\nDone. Objective 3 burst extraction and frequency plotting complete.\n');

end

%% ========================================================================
% Subfunctions
% ========================================================================

function fileName = get_csc_file(direc, animalName)

switch animalName
    case 'ANM00190422'
        fileName = fullfile(direc, 'csc_files', 'ANM00190422', ...
            '2012-12-09_10-48-47', 'CSC33.ncs');

    case 'ANM204878'
        fileName = fullfile(direc, 'csc_files', 'ANM204878', ...
            '2013-05-11_09-32-49', 'CSC33.ncs');

    case 'ANM212379'
        fileName = fullfile(direc, 'csc_files', 'ANM212379', ...
            '2013-06-08_10-10-46', 'CSC53.ncs');

    case 'ANM228899'
        fileName = fullfile(direc, 'csc_files', 'ANM228899', ...
            '2013-11-02_10-16-53', 'CSC45.ncs');

    case 'ANM228900'
        fileName = fullfile(direc, 'csc_files', 'ANM228900', ...
            '2013-11-03_08-59-40', 'CSC45.ncs');

    otherwise
        error('Unknown animal name: %s', animalName);
end

if exist(fileName, 'file') ~= 2
    error('Could not find LFP .ncs file: %s', fileName);
end

end

function [tall, vall, Fs] = make_continuous_lfp(t, v)

t = double(t(:));
v = double(v);
vallRaw = v(:);

tDiff = diff(t);
mtDiff = mode(tDiff);

noSkip = tDiff > mtDiff-2 & tDiff < mtDiff+2;

if all(noSkip)
    Fs = 1 / (mean(tDiff) / 512 / 1e6);
    tall = linspace(t(1), t(end) + (511*(1/Fs)), numel(v));
    vall = vallRaw;
else
    warning('Records were lost. Inserting NaNs to preserve timing.');

    Fs = 1 / (mean(tDiff(noSkip)) / 512 / 1e6);

    tVec = t(1):((1/Fs)*1e6):(t(end)+(512*(1/Fs)*1e6));
    vVec = nan(numel(tVec), 1);

    p = 1;

    for j = 1:size(v,2)
        while p <= numel(tVec) && ~(abs(t(j)-tVec(p)) < 2)
            p = p + 1;
        end

        if p + 511 <= numel(vVec)
            vVec(p:p+511) = v(:,j);
        end

        p = p + 512;
    end

    tall = tVec(:);
    vall = vVec(:);
end

end

function [lfpDs, tDsUs, FsDs, validMaskDs] = downsample_lfp(v, tUs, Fs, targetFs)

v = double(v(:));
tUs = double(tUs(:));

factor = max(1, round(Fs / targetFs));
FsDs = Fs / factor;

validRaw = ~isnan(v);

if any(validRaw)
    fillValue = median(v(validRaw));
else
    fillValue = 0;
end

vFilled = v;
vFilled(~validRaw) = fillValue;

if factor > 1
    try
        lfpDs = decimate(vFilled, factor);
    catch
        lfpDs = vFilled(1:factor:end);
    end

    tDsUs = tUs(1:factor:end);
    validMaskDs = validRaw(1:factor:end);
else
    lfpDs = vFilled;
    tDsUs = tUs;
    validMaskDs = validRaw;
end

n = min([numel(lfpDs), numel(tDsUs), numel(validMaskDs)]);

lfpDs = lfpDs(1:n);
tDsUs = tDsUs(1:n);
validMaskDs = validMaskDs(1:n);

end

function [posDs, speedDsCmS] = interpolate_position_speed(posU, tDsUs)

posData = double(posU.data);

posT = posData(:,1);
pos = posData(:,2);
vel = posData(:,4);

posDs = interp1(posT, pos, tDsUs, 'linear', NaN);
velDs = interp1(posT, vel, tDsUs, 'linear', NaN);

speedDsCmS = abs(velDs) .* (1/posU.unitsPerCm) .* posU.unitsPerSecond;

end

function [filtered, envelope, zEnv, bursts] = detect_bursts_duplicate_safe( ...
    lfp, Fs, lowHz, highHz, filterOrder, analysisMask, coreZ, edgeZ, minDurS, artifactZ)

lfp = double(lfp(:));
analysisMask = logical(analysisMask(:));

if highHz >= Fs/2
    error('High filter edge %.2f exceeds Nyquist %.2f.', highHz, Fs/2);
end

[b, a] = butter(filterOrder, [lowHz highHz] / (Fs/2), 'bandpass');
filtered = filtfilt(b, a, lfp);

envelope = abs(hilbert(filtered));

baselineVals = envelope(analysisMask & ~isnan(envelope));

if numel(baselineVals) < 100
    baselineVals = envelope(~isnan(envelope));
end

medEnv = median(baselineVals);
madEnv = median(abs(baselineVals - medEnv));
sigmaEnv = 1.4826 * madEnv;

if sigmaEnv <= 0 || isnan(sigmaEnv)
    sigmaEnv = std(baselineVals);
end
if sigmaEnv <= 0 || isnan(sigmaEnv)
    sigmaEnv = 1;
end

zEnv = (envelope - medEnv) ./ sigmaEnv;

edgeMask = zEnv >= edgeZ & analysisMask;

edgeStarts = find(diff([false; edgeMask(:); false]) == 1);
edgeEnds = find(diff([false; edgeMask(:); false]) == -1) - 1;

bursts = struct('startIdx', {}, 'endIdx', {}, 'peakIdx', {}, ...
                'durationS', {}, 'isArtifact', {});

for k = 1:numel(edgeStarts)

    st = edgeStarts(k);
    en = edgeEnds(k);

    durationS = (en - st + 1) / Fs;

    if durationS < minDurS
        continue;
    end

    if ~any(zEnv(st:en) >= coreZ)
        continue;
    end

    [peakZ, relPk] = max(zEnv(st:en));
    peakIdx = st + relPk - 1;

    isArtifact = peakZ > artifactZ;

    bursts(end+1).startIdx = st; %#ok<AGROW>
    bursts(end).endIdx = en;
    bursts(end).peakIdx = peakIdx;
    bursts(end).durationS = durationS;
    bursts(end).isArtifact = logical(isArtifact);
end

end

function write_cell_csv(fileName, cellData)

fid = fopen(fileName, 'w');
if fid == -1
    error('Could not open output CSV: %s', fileName);
end

for r = 1:size(cellData,1)
    for c = 1:size(cellData,2)
        value = cellData{r,c};

        if ischar(value)
            out = value;
        elseif islogical(value)
            out = num2str(value);
        elseif isnumeric(value)
            if isempty(value)
                out = '';
            elseif isnan(value)
                out = 'NaN';
            else
                out = num2str(value, 15);
            end
        else
            out = '';
        end

        % Basic CSV escaping.
        out = strrep(out, '"', '""');
        if any(out == ',')
            out = ['"' out '"'];
        end

        fprintf(fid, '%s', out);

        if c < size(cellData,2)
            fprintf(fid, ',');
        end
    end
    fprintf(fid, '\n');
end

fclose(fid);

end

function vals = unique_cell_column(cellData, col)

vals = {};
for r = 1:size(cellData,1)
    item = cellData{r,col};
    if ~any(strcmp(vals, item))
        vals{end+1} = item; %#ok<AGROW>
    end
end

end
