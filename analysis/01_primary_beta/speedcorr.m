% speedcorr.m
% ------------------------------------------------------------
% HC-31 movement-speed checks and speed/burst-frequency correlation.
%
% Purpose:
%   1. Check whether animals moved at different speeds in novel vs familiar
%      Run1 track sections.
%   2. Test whether beta/beta2 burst frequency correlates with movement speed.
%
% This script uses:
%   - resSave / resSave.mat for position, speed, sectInt and sectExt.
%   - the binned burst-frequency table from the burst-detection output.
%
% Input priority:
%   1. beta_burst_over_time_outputs_BETA13_30_FUNC/hc31_beta_burst_frequency_over_time.csv
%   2. beta_burst_over_time_outputs_FUNC/hc31_beta_burst_frequency_over_time.csv
%
% Outputs:
%   <HC31_DATA_ROOT>/speed_movement_correlation_outputs\
%       hc31_speed_novel_familiar_subepoch_summary.csv
%       hc31_speed_novel_familiar_animal_summary.csv
%       hc31_speed_novel_familiar_stats.csv
%       hc31_burst_rate_speed_bin_table.csv
%       hc31_burst_rate_speed_correlation_by_animal.csv
%       hc31_burst_rate_speed_correlation_stats.csv
%       figures\
%
% Run:
%   cd('<HC31_DATA_ROOT>')
%   speedcorr
%
% If MATLAB refuses to run scripts directly:
%   code = fileread('speedcorr.m');
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
speedThresholdCmS = 5;

outDir = fullfile(direc, 'speed_movement_correlation_outputs');
figDir = fullfile(outDir, 'figures');

if exist(outDir, 'dir') ~= 7
    mkdir(outDir);
end
if exist(figDir, 'dir') ~= 7
    mkdir(figDir);
end

%% ------------------------------------------------------------------------
% 2. Load resSave
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

%% ------------------------------------------------------------------------
% 3. Load binned burst-frequency table
% -------------------------------------------------------------------------

binCsvNew = fullfile(direc, 'beta_burst_over_time_outputs_BETA13_30_FUNC', 'hc31_beta_burst_frequency_over_time.csv');
binCsvOld = fullfile(direc, 'beta_burst_over_time_outputs_FUNC', 'hc31_beta_burst_frequency_over_time.csv');

if exist(binCsvNew, 'file') == 2
    binCsv = binCsvNew;
elseif exist(binCsvOld, 'file') == 2
    binCsv = binCsvOld;
else
    error('Could not find hc31_beta_burst_frequency_over_time.csv in either expected output folder.');
end

BINS = readtable(binCsv);

fprintf('Loaded resSave from:\n%s\n\n', resPath);
fprintf('Loaded binned burst-frequency table from:\n%s\n\n', binCsv);
fprintf('Saving speed/correlation outputs to:\n%s\n\n', outDir);

%% ------------------------------------------------------------------------
% 4. Novel vs familiar speed by subepoch
% -------------------------------------------------------------------------

subAnimal = {};
subResIndex = [];
subepochCol = [];
novelAllSecondsCol = [];
familiarAllSecondsCol = [];
novelMovingSecondsCol = [];
familiarMovingSecondsCol = [];
novelMeanSpeedAllCol = [];
familiarMeanSpeedAllCol = [];
novelMeanSpeedMovingCol = [];
familiarMeanSpeedMovingCol = [];
novelMedianSpeedMovingCol = [];
familiarMedianSpeedMovingCol = [];
novelMinusFamiliarMovingSpeedCol = [];
novelMinusFamiliarAllSpeedCol = [];

for ai = 1:numel(animalIndices)

    i = animalIndices(ai);
    R = resSave(i);
    animalName = R.spAll(1).animal;

    fprintf('Checking novel/familiar speed for resSave(%d): %s\n', i, animalName);

    posU = R.posMazeLin(1);
    posData = posU.data;

    tUs = posData(:,1);
    linPos = posData(:,2);

    if size(posData,2) >= 4
        rawSpeed = posData(:,4);

        if isfield(posU, 'unitsPerCm') && isfield(posU, 'unitsPerSecond')
            speedCmS = rawSpeed .* (1 ./ posU.unitsPerCm) .* posU.unitsPerSecond;
        else
            speedCmS = rawSpeed;
        end
    else
        error('No speed/velocity column found in posMazeLin for %s.', animalName);
    end

    dTimeS = [diff(tUs); median(diff(tUs))] ./ 1e6;
    badDt = isnan(dTimeS) | dTimeS < 0 | dTimeS > 10;
    if any(~badDt)
        dTimeS(badDt) = median(dTimeS(~badDt), 'omitnan');
    end

    validPos = ~isnan(linPos) & ~isnan(speedCmS);

    for s = 1:size(R.sectInt,1)

        subStart = R.sectInt(s,1);
        subEnd = R.sectInt(s,2);

        novelStart = min(R.sectExt(s,:));
        novelEnd = max(R.sectExt(s,:));

        inSub = tUs >= subStart & tUs <= subEnd & validPos;
        inNovel = inSub & linPos >= novelStart & linPos <= novelEnd;
        inFamiliar = inSub & ~inNovel;

        moving = speedCmS >= speedThresholdCmS;

        inNovelMoving = inNovel & moving;
        inFamiliarMoving = inFamiliar & moving;

        novelAllSeconds = sum(dTimeS(inNovel), 'omitnan');
        familiarAllSeconds = sum(dTimeS(inFamiliar), 'omitnan');

        novelMovingSeconds = sum(dTimeS(inNovelMoving), 'omitnan');
        familiarMovingSeconds = sum(dTimeS(inFamiliarMoving), 'omitnan');

        if any(inNovel)
            novelMeanSpeedAll = sum(speedCmS(inNovel) .* dTimeS(inNovel), 'omitnan') ./ novelAllSeconds;
        else
            novelMeanSpeedAll = NaN;
        end

        if any(inFamiliar)
            familiarMeanSpeedAll = sum(speedCmS(inFamiliar) .* dTimeS(inFamiliar), 'omitnan') ./ familiarAllSeconds;
        else
            familiarMeanSpeedAll = NaN;
        end

        if any(inNovelMoving)
            novelMeanSpeedMoving = sum(speedCmS(inNovelMoving) .* dTimeS(inNovelMoving), 'omitnan') ./ novelMovingSeconds;
            novelMedianSpeedMoving = median(speedCmS(inNovelMoving), 'omitnan');
        else
            novelMeanSpeedMoving = NaN;
            novelMedianSpeedMoving = NaN;
        end

        if any(inFamiliarMoving)
            familiarMeanSpeedMoving = sum(speedCmS(inFamiliarMoving) .* dTimeS(inFamiliarMoving), 'omitnan') ./ familiarMovingSeconds;
            familiarMedianSpeedMoving = median(speedCmS(inFamiliarMoving), 'omitnan');
        else
            familiarMeanSpeedMoving = NaN;
            familiarMedianSpeedMoving = NaN;
        end

        subAnimal{end+1,1} = animalName; %#ok<SAGROW>
        subResIndex(end+1,1) = i; %#ok<SAGROW>
        subepochCol(end+1,1) = s; %#ok<SAGROW>
        novelAllSecondsCol(end+1,1) = novelAllSeconds; %#ok<SAGROW>
        familiarAllSecondsCol(end+1,1) = familiarAllSeconds; %#ok<SAGROW>
        novelMovingSecondsCol(end+1,1) = novelMovingSeconds; %#ok<SAGROW>
        familiarMovingSecondsCol(end+1,1) = familiarMovingSeconds; %#ok<SAGROW>
        novelMeanSpeedAllCol(end+1,1) = novelMeanSpeedAll; %#ok<SAGROW>
        familiarMeanSpeedAllCol(end+1,1) = familiarMeanSpeedAll; %#ok<SAGROW>
        novelMeanSpeedMovingCol(end+1,1) = novelMeanSpeedMoving; %#ok<SAGROW>
        familiarMeanSpeedMovingCol(end+1,1) = familiarMeanSpeedMoving; %#ok<SAGROW>
        novelMedianSpeedMovingCol(end+1,1) = novelMedianSpeedMoving; %#ok<SAGROW>
        familiarMedianSpeedMovingCol(end+1,1) = familiarMedianSpeedMoving; %#ok<SAGROW>
        novelMinusFamiliarMovingSpeedCol(end+1,1) = novelMeanSpeedMoving - familiarMeanSpeedMoving; %#ok<SAGROW>
        novelMinusFamiliarAllSpeedCol(end+1,1) = novelMeanSpeedAll - familiarMeanSpeedAll; %#ok<SAGROW>
    end
end

SUB = table(subAnimal, subResIndex, subepochCol, novelAllSecondsCol, familiarAllSecondsCol, ...
    novelMovingSecondsCol, familiarMovingSecondsCol, novelMeanSpeedAllCol, familiarMeanSpeedAllCol, ...
    novelMeanSpeedMovingCol, familiarMeanSpeedMovingCol, novelMedianSpeedMovingCol, familiarMedianSpeedMovingCol, ...
    novelMinusFamiliarMovingSpeedCol, novelMinusFamiliarAllSpeedCol, ...
    'VariableNames', {'animal','resSaveIndex','subepoch','novelAllSeconds','familiarAllSeconds', ...
    'novelMovingSeconds','familiarMovingSeconds','novelMeanSpeedAllCmS','familiarMeanSpeedAllCmS', ...
    'novelMeanSpeedMovingCmS','familiarMeanSpeedMovingCmS','novelMedianSpeedMovingCmS','familiarMedianSpeedMovingCmS', ...
    'novelMinusFamiliarMovingSpeedCmS','novelMinusFamiliarAllSpeedCmS'});

subCsv = fullfile(outDir, 'hc31_speed_novel_familiar_subepoch_summary.csv');
writetable(SUB, subCsv);

%% ------------------------------------------------------------------------
% 5. Animal-level speed summary and exact sign-flip test
% -------------------------------------------------------------------------

animals = unique(SUB.animal, 'stable');

animalCol = {};
resIndexCol = [];
novelAllSecondsAnimalCol = [];
familiarAllSecondsAnimalCol = [];
novelMovingSecondsAnimalCol = [];
familiarMovingSecondsAnimalCol = [];
novelMeanSpeedAllAnimalCol = [];
familiarMeanSpeedAllAnimalCol = [];
novelMeanSpeedMovingAnimalCol = [];
familiarMeanSpeedMovingAnimalCol = [];
novelMinusFamiliarAllAnimalCol = [];
novelMinusFamiliarMovingAnimalCol = [];

for a = 1:numel(animals)

    animalName = animals{a};
    rows = strcmp(SUB.animal, animalName);

    novelAllSeconds = sum(SUB.novelAllSeconds(rows), 'omitnan');
    familiarAllSeconds = sum(SUB.familiarAllSeconds(rows), 'omitnan');
    novelMovingSeconds = sum(SUB.novelMovingSeconds(rows), 'omitnan');
    familiarMovingSeconds = sum(SUB.familiarMovingSeconds(rows), 'omitnan');

    % Weighted animal-level speed from subepoch means.
    novelMeanAll = sum(SUB.novelMeanSpeedAllCmS(rows) .* SUB.novelAllSeconds(rows), 'omitnan') ./ novelAllSeconds;
    familiarMeanAll = sum(SUB.familiarMeanSpeedAllCmS(rows) .* SUB.familiarAllSeconds(rows), 'omitnan') ./ familiarAllSeconds;

    novelMeanMoving = sum(SUB.novelMeanSpeedMovingCmS(rows) .* SUB.novelMovingSeconds(rows), 'omitnan') ./ novelMovingSeconds;
    familiarMeanMoving = sum(SUB.familiarMeanSpeedMovingCmS(rows) .* SUB.familiarMovingSeconds(rows), 'omitnan') ./ familiarMovingSeconds;

    rIndex = SUB.resSaveIndex(find(rows,1,'first'));

    animalCol{end+1,1} = animalName; %#ok<SAGROW>
    resIndexCol(end+1,1) = rIndex; %#ok<SAGROW>
    novelAllSecondsAnimalCol(end+1,1) = novelAllSeconds; %#ok<SAGROW>
    familiarAllSecondsAnimalCol(end+1,1) = familiarAllSeconds; %#ok<SAGROW>
    novelMovingSecondsAnimalCol(end+1,1) = novelMovingSeconds; %#ok<SAGROW>
    familiarMovingSecondsAnimalCol(end+1,1) = familiarMovingSeconds; %#ok<SAGROW>
    novelMeanSpeedAllAnimalCol(end+1,1) = novelMeanAll; %#ok<SAGROW>
    familiarMeanSpeedAllAnimalCol(end+1,1) = familiarMeanAll; %#ok<SAGROW>
    novelMeanSpeedMovingAnimalCol(end+1,1) = novelMeanMoving; %#ok<SAGROW>
    familiarMeanSpeedMovingAnimalCol(end+1,1) = familiarMeanMoving; %#ok<SAGROW>
    novelMinusFamiliarAllAnimalCol(end+1,1) = novelMeanAll - familiarMeanAll; %#ok<SAGROW>
    novelMinusFamiliarMovingAnimalCol(end+1,1) = novelMeanMoving - familiarMeanMoving; %#ok<SAGROW>
end

AN = table(animalCol, resIndexCol, novelAllSecondsAnimalCol, familiarAllSecondsAnimalCol, ...
    novelMovingSecondsAnimalCol, familiarMovingSecondsAnimalCol, novelMeanSpeedAllAnimalCol, ...
    familiarMeanSpeedAllAnimalCol, novelMeanSpeedMovingAnimalCol, familiarMeanSpeedMovingAnimalCol, ...
    novelMinusFamiliarAllAnimalCol, novelMinusFamiliarMovingAnimalCol, ...
    'VariableNames', {'animal','resSaveIndex','novelAllSeconds','familiarAllSeconds', ...
    'novelMovingSeconds','familiarMovingSeconds','novelMeanSpeedAllCmS','familiarMeanSpeedAllCmS', ...
    'novelMeanSpeedMovingCmS','familiarMeanSpeedMovingCmS', ...
    'novelMinusFamiliarAllSpeedCmS','novelMinusFamiliarMovingSpeedCmS'});

animalCsv = fullfile(outDir, 'hc31_speed_novel_familiar_animal_summary.csv');
writetable(AN, animalCsv);

% Exact sign-flip tests for speed differences.
speedTestName = {};
speedComparison = {};
speedN = [];
speedMeanNovel = [];
speedMeanFamiliar = [];
speedMeanDiff = [];
speedMedianDiff = [];
speedNPositive = [];
speedNNegative = [];
speedP = [];

diffTypes = {'all_valid_speed','moving_only_speed'};
diffCols = {'novelMinusFamiliarAllSpeedCmS','novelMinusFamiliarMovingSpeedCmS'};
novCols = {'novelMeanSpeedAllCmS','novelMeanSpeedMovingCmS'};
famCols = {'familiarMeanSpeedAllCmS','familiarMeanSpeedMovingCmS'};

for dt = 1:numel(diffTypes)

    d = AN.(diffCols{dt});
    novelVals = AN.(novCols{dt});
    familiarVals = AN.(famCols{dt});

    ok = ~isnan(d) & ~isnan(novelVals) & ~isnan(familiarVals);
    dUse = d(ok);
    dNoZero = dUse(dUse ~= 0);

    n = numel(dNoZero);

    if n == 0
        p = NaN;
    else
        observed = abs(mean(dNoZero));
        nPerm = 2^n;
        permMeans = zeros(nPerm,1);

        for mask = 0:(nPerm-1)
            signs = ones(n,1);
            for bit = 1:n
                if bitget(mask, bit)
                    signs(bit) = -1;
                end
            end
            permMeans(mask+1) = mean(dNoZero .* signs);
        end

        p = mean(abs(permMeans) >= observed);
    end

    speedTestName{end+1,1} = diffTypes{dt}; %#ok<SAGROW>
    speedComparison{end+1,1} = 'novel speed minus familiar speed'; %#ok<SAGROW>
    speedN(end+1,1) = numel(dUse); %#ok<SAGROW>
    speedMeanNovel(end+1,1) = mean(novelVals(ok), 'omitnan'); %#ok<SAGROW>
    speedMeanFamiliar(end+1,1) = mean(familiarVals(ok), 'omitnan'); %#ok<SAGROW>
    speedMeanDiff(end+1,1) = mean(dUse, 'omitnan'); %#ok<SAGROW>
    speedMedianDiff(end+1,1) = median(dUse, 'omitnan'); %#ok<SAGROW>
    speedNPositive(end+1,1) = sum(dUse > 0); %#ok<SAGROW>
    speedNNegative(end+1,1) = sum(dUse < 0); %#ok<SAGROW>
    speedP(end+1,1) = p; %#ok<SAGROW>
end

SPEEDSTATS = table(speedTestName, speedComparison, speedN, speedMeanNovel, speedMeanFamiliar, ...
    speedMeanDiff, speedMedianDiff, speedNPositive, speedNNegative, speedP, ...
    'VariableNames', {'testName','comparison','nAnimals','meanNovelSpeedCmS','meanFamiliarSpeedCmS', ...
    'meanNovelMinusFamiliarSpeedCmS','medianNovelMinusFamiliarSpeedCmS', ...
    'nNovelHigher','nFamiliarHigher','exactSignFlipP'});

speedStatsCsv = fullfile(outDir, 'hc31_speed_novel_familiar_stats.csv');
writetable(SPEEDSTATS, speedStatsCsv);

disp(SPEEDSTATS);

%% ------------------------------------------------------------------------
% 6. Plot novel vs familiar speed
% -------------------------------------------------------------------------

figSpeed = figure('Color','w', 'Name', 'Novel vs familiar speed');
hold on;

for a = 1:height(AN)
    plot([1 2], [AN.familiarMeanSpeedMovingCmS(a) AN.novelMeanSpeedMovingCmS(a)], '-o', 'LineWidth', 1.5);
    text(2.05, AN.novelMeanSpeedMovingCmS(a), AN.animal{a}, 'Interpreter','none', 'FontSize', 8);
end

meanFam = mean(AN.familiarMeanSpeedMovingCmS, 'omitnan');
meanNov = mean(AN.novelMeanSpeedMovingCmS, 'omitnan');

plot([1 2], [meanFam meanNov], 'k-o', 'LineWidth', 3, 'MarkerSize', 8, 'MarkerFaceColor','k');

set(gca, 'XTick', [1 2], 'XTickLabel', {'familiar','novel'});
ylabel('mean moving speed, cm/s');
title('Moving speed in familiar vs novel track sections');
grid on;
xlim([0.75 2.45]);
hold off;

saveas(figSpeed, fullfile(figDir, 'novel_vs_familiar_moving_speed.png'));

%% ------------------------------------------------------------------------
% 7. Build 60-second bin speed table and correlate burst rate with speed
% -------------------------------------------------------------------------

binAnimal = {};
binResIndex = [];
binBand = {};
binNumber = [];
binStartUs = [];
binEndUs = [];
binMidMin = [];
meanSpeedAllBin = [];
meanSpeedMovingBin = [];
movingSecondsBin = [];
validPositionSecondsBin = [];
burstCountBin = [];
burstRateBin = [];

for row = 1:height(BINS)

    animalName = BINS.animal{row};
    rIndex = BINS.resSaveIndex(row);
    bandName = BINS.band{row};
    bStart = BINS.binStartUs(row);
    bEnd = BINS.binEndUs(row);

    R = resSave(rIndex);
    posU = R.posMazeLin(1);
    posData = posU.data;

    tUs = posData(:,1);
    linPos = posData(:,2);

    rawSpeed = posData(:,4);
    if isfield(posU, 'unitsPerCm') && isfield(posU, 'unitsPerSecond')
        speedCmS = rawSpeed .* (1 ./ posU.unitsPerCm) .* posU.unitsPerSecond;
    else
        speedCmS = rawSpeed;
    end

    dTimeS = [diff(tUs); median(diff(tUs))] ./ 1e6;
    badDt = isnan(dTimeS) | dTimeS < 0 | dTimeS > 10;
    if any(~badDt)
        dTimeS(badDt) = median(dTimeS(~badDt), 'omitnan');
    end

    inBin = tUs >= bStart & tUs < bEnd & ~isnan(linPos) & ~isnan(speedCmS);
    inBinMoving = inBin & speedCmS >= speedThresholdCmS;

    validSec = sum(dTimeS(inBin), 'omitnan');
    movingSec = sum(dTimeS(inBinMoving), 'omitnan');

    if validSec > 0
        meanSpeedAll = sum(speedCmS(inBin) .* dTimeS(inBin), 'omitnan') ./ validSec;
    else
        meanSpeedAll = NaN;
    end

    if movingSec > 0
        meanSpeedMoving = sum(speedCmS(inBinMoving) .* dTimeS(inBinMoving), 'omitnan') ./ movingSec;
    else
        meanSpeedMoving = NaN;
    end

    binAnimal{end+1,1} = animalName; %#ok<SAGROW>
    binResIndex(end+1,1) = rIndex; %#ok<SAGROW>
    binBand{end+1,1} = bandName; %#ok<SAGROW>
    binNumber(end+1,1) = BINS.binNumber(row); %#ok<SAGROW>
    binStartUs(end+1,1) = bStart; %#ok<SAGROW>
    binEndUs(end+1,1) = bEnd; %#ok<SAGROW>
    binMidMin(end+1,1) = BINS.binMidMinutesFromRun1Start(row); %#ok<SAGROW>
    meanSpeedAllBin(end+1,1) = meanSpeedAll; %#ok<SAGROW>
    meanSpeedMovingBin(end+1,1) = meanSpeedMoving; %#ok<SAGROW>
    movingSecondsBin(end+1,1) = movingSec; %#ok<SAGROW>
    validPositionSecondsBin(end+1,1) = validSec; %#ok<SAGROW>
    burstCountBin(end+1,1) = BINS.burstCount(row); %#ok<SAGROW>
    burstRateBin(end+1,1) = BINS.burstRatePerMinute(row); %#ok<SAGROW>
end

BINSPD = table(binAnimal, binResIndex, binBand, binNumber, binStartUs, binEndUs, binMidMin, ...
    meanSpeedAllBin, meanSpeedMovingBin, movingSecondsBin, validPositionSecondsBin, burstCountBin, burstRateBin, ...
    'VariableNames', {'animal','resSaveIndex','band','binNumber','binStartUs','binEndUs','binMidMinutesFromRun1Start', ...
    'meanSpeedAllCmS','meanSpeedMovingCmS','movingSeconds','validPositionSeconds','burstCount','burstRatePerMinute'});

binSpeedCsv = fullfile(outDir, 'hc31_burst_rate_speed_bin_table.csv');
writetable(BINSPD, binSpeedCsv);

%% ------------------------------------------------------------------------
% 8. Animal-level correlations: burst rate vs speed
% -------------------------------------------------------------------------

bands = unique(BINSPD.band, 'stable');

corrAnimal = {};
corrResIndex = [];
corrBand = {};
corrN = [];
corrPearsonR = [];
corrFisherZ = [];
corrSlope = [];
corrIntercept = [];

for a = 1:numel(animals)

    animalName = animals{a};

    for b = 1:numel(bands)

        bandName = bands{b};

        rows = strcmp(BINSPD.animal, animalName) & strcmp(BINSPD.band, bandName);

        x = BINSPD.meanSpeedMovingCmS(rows);
        y = BINSPD.burstRatePerMinute(rows);

        ok = ~isnan(x) & ~isnan(y) & isfinite(x) & isfinite(y);

        xUse = x(ok);
        yUse = y(ok);

        if numel(xUse) >= 3 && std(xUse) > 0 && std(yUse) > 0
            C = corrcoef(xUse, yUse);
            rVal = C(1,2);

            pfit = polyfit(xUse, yUse, 1);
            slope = pfit(1);
            intercept = pfit(2);

            if abs(rVal) < 1
                zVal = 0.5 .* log((1 + rVal) ./ (1 - rVal));
            else
                zVal = NaN;
            end
        else
            rVal = NaN;
            zVal = NaN;
            slope = NaN;
            intercept = NaN;
        end

        rIndex = BINSPD.resSaveIndex(find(rows,1,'first'));

        corrAnimal{end+1,1} = animalName; %#ok<SAGROW>
        corrResIndex(end+1,1) = rIndex; %#ok<SAGROW>
        corrBand{end+1,1} = bandName; %#ok<SAGROW>
        corrN(end+1,1) = numel(xUse); %#ok<SAGROW>
        corrPearsonR(end+1,1) = rVal; %#ok<SAGROW>
        corrFisherZ(end+1,1) = zVal; %#ok<SAGROW>
        corrSlope(end+1,1) = slope; %#ok<SAGROW>
        corrIntercept(end+1,1) = intercept; %#ok<SAGROW>
    end
end

CORR = table(corrAnimal, corrResIndex, corrBand, corrN, corrPearsonR, corrFisherZ, corrSlope, corrIntercept, ...
    'VariableNames', {'animal','resSaveIndex','band','nBins','pearsonR_speedVsBurstRate', ...
    'fisherZ','linearSlope_burstRatePerCmS','linearIntercept'});

corrCsv = fullfile(outDir, 'hc31_burst_rate_speed_correlation_by_animal.csv');
writetable(CORR, corrCsv);

%% ------------------------------------------------------------------------
% 9. Animal-level exact sign-flip tests: correlation against zero
% -------------------------------------------------------------------------

corrStatBand = {};
corrStatN = [];
corrMeanR = [];
corrMedianR = [];
corrMeanZ = [];
corrNPositive = [];
corrNNegative = [];
corrExactP = [];

for b = 1:numel(bands)

    bandName = bands{b};

    rows = strcmp(CORR.band, bandName);

    zVals = CORR.fisherZ(rows);
    rVals = CORR.pearsonR_speedVsBurstRate(rows);

    ok = ~isnan(zVals) & ~isnan(rVals);

    zUse = zVals(ok);
    rUse = rVals(ok);

    zNoZero = zUse(zUse ~= 0);

    n = numel(zNoZero);

    if n == 0
        p = NaN;
    else
        observed = abs(mean(zNoZero));
        nPerm = 2^n;
        permMeans = zeros(nPerm,1);

        for mask = 0:(nPerm-1)
            signs = ones(n,1);
            for bit = 1:n
                if bitget(mask, bit)
                    signs(bit) = -1;
                end
            end
            permMeans(mask+1) = mean(zNoZero .* signs);
        end

        p = mean(abs(permMeans) >= observed);
    end

    corrStatBand{end+1,1} = bandName; %#ok<SAGROW>
    corrStatN(end+1,1) = numel(zUse); %#ok<SAGROW>
    corrMeanR(end+1,1) = mean(rUse, 'omitnan'); %#ok<SAGROW>
    corrMedianR(end+1,1) = median(rUse, 'omitnan'); %#ok<SAGROW>
    corrMeanZ(end+1,1) = mean(zUse, 'omitnan'); %#ok<SAGROW>
    corrNPositive(end+1,1) = sum(rUse > 0); %#ok<SAGROW>
    corrNNegative(end+1,1) = sum(rUse < 0); %#ok<SAGROW>
    corrExactP(end+1,1) = p; %#ok<SAGROW>
end

CORRSTATS = table(corrStatBand, corrStatN, corrMeanR, corrMedianR, corrMeanZ, corrNPositive, corrNNegative, corrExactP, ...
    'VariableNames', {'band','nAnimals','meanPearsonR','medianPearsonR','meanFisherZ', ...
    'nPositiveCorrelations','nNegativeCorrelations','exactSignFlipP_onFisherZ'});

corrStatsCsv = fullfile(outDir, 'hc31_burst_rate_speed_correlation_stats.csv');
writetable(CORRSTATS, corrStatsCsv);

disp(CORRSTATS);

%% ------------------------------------------------------------------------
% 10. Correlation figures
% -------------------------------------------------------------------------

for b = 1:numel(bands)

    bandName = bands{b};

    %% Pooled scatter, colour/style by animal

    figScatter = figure('Color','w', 'Name', sprintf('%s burst rate vs speed', bandName));
    hold on;

    for a = 1:numel(animals)

        animalName = animals{a};

        rows = strcmp(BINSPD.animal, animalName) & strcmp(BINSPD.band, bandName);
        x = BINSPD.meanSpeedMovingCmS(rows);
        y = BINSPD.burstRatePerMinute(rows);

        ok = ~isnan(x) & ~isnan(y) & isfinite(x) & isfinite(y);

        scatter(x(ok), y(ok), 28, 'filled', 'DisplayName', animalName);
    end

    xlabel('mean moving speed in 60-s bin, cm/s');
    ylabel('burst frequency, bursts/min');
    title(sprintf('%s burst frequency vs movement speed', bandName), 'Interpreter','none');
    legend('Location','bestoutside', 'Interpreter','none');
    grid on;
    hold off;

    saveas(figScatter, fullfile(figDir, sprintf('%s_burst_rate_vs_speed_scatter.png', bandName)));

    %% Animal-level correlation values

    figR = figure('Color','w', 'Name', sprintf('%s animal-level speed correlations', bandName));

    rows = strcmp(CORR.band, bandName);
    rVals = CORR.pearsonR_speedVsBurstRate(rows);
    labels = CORR.animal(rows);

    bar(rVals);
    yline(0, 'k--');
    set(gca, 'XTick', 1:numel(rVals), 'XTickLabel', labels);
    xtickangle(45);
    ylabel('Pearson r');
    title(sprintf('%s animal-level correlation: speed vs burst frequency', bandName), 'Interpreter','none');
    grid on;

    saveas(figR, fullfile(figDir, sprintf('%s_animal_level_speed_correlations.png', bandName)));
end

fprintf('\nSaved output tables:\n');
fprintf('%s\n', subCsv);
fprintf('%s\n', animalCsv);
fprintf('%s\n', speedStatsCsv);
fprintf('%s\n', binSpeedCsv);
fprintf('%s\n', corrCsv);
fprintf('%s\n', corrStatsCsv);
fprintf('\nSaved figures to:\n%s\n', figDir);
fprintf('\nDone. Speed and burst-frequency correlation analysis complete.\n');
