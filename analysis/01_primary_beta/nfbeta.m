% nfbeta.m
% Updated version: broad beta band is 13-30 Hz instead of 13-30 Hz.
% Beta2 remains 23-30 Hz.
% ------------------------------------------------------------
% Direct novel-vs-familiar beta/beta2 burst analysis for hc-31.
%
% Purpose:
%   This script compares beta/beta2 burst frequency in novel vs familiar
%   track sections during Run1.
%
% Inputs:
%   C:\Users\angel\Documents\MATLAB\CRCN\resSave.mat
%   C:\Users\angel\Documents\MATLAB\CRCN\beta_burst_over_time_outputs_BETA13_30_FUNC\hc31_detected_beta_bursts.csv
%
% Outputs:
%   C:\Users\angel\Documents\MATLAB\CRCN\beta_burst_novel_familiar_outputs_BETA13_30\
%       hc31_novel_familiar_burst_table.csv
%       hc31_novel_familiar_subepoch_summary.csv
%       hc31_novel_familiar_animal_summary.csv
%       hc31_novel_familiar_stats.csv
%       figures\
%
% Main logic:
%   1. Load detected beta/beta2 bursts from the existing burst-detection script.
%   2. Load resSave to access sectInt and sectExt.
%   3. Classify each burst as novel or familiar based on:
%          burst peak time  -> Run1 subepoch from sectInt
%          burst peak position -> novel section from sectExt
%   4. Estimate valid moving time spent in novel vs familiar sections.
%   5. Calculate burst frequency as bursts per minute.
%   6. Perform animal-level paired exact sign-flip tests:
%          novel burst rate vs familiar burst rate
%
% How to run:
%   Put this file in:
%       C:\Users\angel\Documents\MATLAB\CRCN\
%
%   Then try:
%       cd('C:\Users\angel\Documents\MATLAB\CRCN')
%       nfbeta
%
%   If MATLAB gives the same script/function recognition problem as before:
%       code = fileread('nfbeta.m');
%       eval(code)
%
% Important:
%   The statistical unit is the animal, not individual bursts or 60-second bins.

clear; clc; close all;

%% ------------------------------------------------------------------------
% 1. Settings
% -------------------------------------------------------------------------

direc = 'C:\Users\angel\Documents\MATLAB\CRCN\';

animalIndices = 5:9;
speedThresholdCmS = 5;

burstCsv = fullfile(direc, 'beta_burst_over_time_outputs_BETA13_30_FUNC', 'hc31_detected_beta_bursts.csv');

outDir = fullfile(direc, 'beta_burst_novel_familiar_outputs_BETA13_30');
figDir = fullfile(outDir, 'figures');

if exist(outDir, 'dir') ~= 7
    mkdir(outDir);
end

if exist(figDir, 'dir') ~= 7
    mkdir(figDir);
end

%% ------------------------------------------------------------------------
% 2. Load resSave and detected burst table
% -------------------------------------------------------------------------

resPath = fullfile(direc, 'resSave.mat');
if exist(resPath, 'file') ~= 2
    resPath = fullfile(direc, 'resSave');
end

if exist(resPath, 'file') ~= 2
    error('Could not find resSave.mat or resSave in: %s', direc);
end

if exist(burstCsv, 'file') ~= 2
    error('Could not find detected burst CSV: %s', burstCsv);
end

Sload = load(resPath);
resSave = Sload.resSave;

B = readtable(burstCsv);

fprintf('Loaded resSave from:\n%s\n\n', resPath);
fprintf('Loaded detected bursts from:\n%s\n\n', burstCsv);

%% ------------------------------------------------------------------------
% 3. Classify every detected burst as novel or familiar
% -------------------------------------------------------------------------

burstAnimal = {};
burstResIndex = [];
burstBand = {};
burstSubepoch = [];
burstCategory = {};
burstPeakUs = [];
burstPeakPosition = [];
burstPeakSpeedCmS = [];
burstPeakZ = [];
burstDurationS = [];
burstIncluded = [];

subAnimal = {};
subResIndex = [];
subBand = {};
subepochCol = [];
novelSecondsCol = [];
familiarSecondsCol = [];
novelBurstCountCol = [];
familiarBurstCountCol = [];
novelRateCol = [];
familiarRateCol = [];
diffRateCol = [];
ratioRateCol = [];
notesCol = {};

bands = unique(B.band, 'stable');

for ii = 1:numel(animalIndices)

    rIndex = animalIndices(ii);
    R = resSave(rIndex);
    animalName = R.spAll(1).animal;

    fprintf('Classifying resSave(%d): %s\n', rIndex, animalName);

    posU = R.posMazeLin(1);
    posData = posU.data;

    posTimeUs = posData(:,1);
    posLin = posData(:,2);

    if size(posData,2) >= 4
        rawSpeed = posData(:,4);

        if isfield(posU, 'unitsPerCm') && isfield(posU, 'unitsPerSecond')
            speedCmS = rawSpeed .* (1 ./ posU.unitsPerCm) .* posU.unitsPerSecond;
        else
            speedCmS = rawSpeed;
        end
    else
        speedCmS = nan(size(posLin));
    end

    % Estimate the amount of time represented by each position sample.
    dPosTimeS = [diff(posTimeUs); median(diff(posTimeUs))] ./ 1e6;
    badDt = isnan(dPosTimeS) | dPosTimeS < 0 | dPosTimeS > 10;
    dPosTimeS(badDt) = nanmedian(dPosTimeS(~badDt));

    animalBurstRows = strcmp(B.animal, animalName) & B.resSaveIndex == rIndex;

    for s = 1:size(R.sectInt,1)

        subStartUs = R.sectInt(s,1);
        subEndUs = R.sectInt(s,2);

        novelStartPos = min(R.sectExt(s,:));
        novelEndPos = max(R.sectExt(s,:));

        % Valid moving time spent in this subepoch.
        inSubepochPos = posTimeUs >= subStartUs & posTimeUs <= subEndUs;
        validPos = ~isnan(posLin) & ~isnan(speedCmS);
        movingPos = speedCmS >= speedThresholdCmS;

        validMoving = inSubepochPos & validPos & movingPos;

        inNovelPos = validMoving & posLin >= novelStartPos & posLin <= novelEndPos;
        inFamiliarPos = validMoving & ~inNovelPos;

        novelSeconds = nansum(dPosTimeS(inNovelPos));
        familiarSeconds = nansum(dPosTimeS(inFamiliarPos));

        for b = 1:numel(bands)

            bandName = bands{b};

            rows = animalBurstRows & strcmp(B.band, bandName);

            if ismember('excludedAsArtifact', B.Properties.VariableNames)
                rows = rows & B.excludedAsArtifact == 0;
            end

            rows = rows & B.burstPeakUs >= subStartUs & B.burstPeakUs <= subEndUs;

            theseRows = find(rows);

            novelBurstCount = 0;
            familiarBurstCount = 0;

            for rr = 1:numel(theseRows)

                row = theseRows(rr);

                peakPos = B.peakPosition(row);
                peakUs = B.burstPeakUs(row);
                peakSpeed = B.peakSpeedCmS(row);

                if isnan(peakPos) || isnan(peakSpeed)
                    category = 'unclassified';
                    included = 0;
                elseif peakSpeed < speedThresholdCmS
                    category = 'below_speed_threshold';
                    included = 0;
                elseif peakPos >= novelStartPos && peakPos <= novelEndPos
                    category = 'novel';
                    included = 1;
                    novelBurstCount = novelBurstCount + 1;
                else
                    category = 'familiar';
                    included = 1;
                    familiarBurstCount = familiarBurstCount + 1;
                end

                burstAnimal{end+1,1} = animalName; %#ok<SAGROW>
                burstResIndex(end+1,1) = rIndex; %#ok<SAGROW>
                burstBand{end+1,1} = bandName; %#ok<SAGROW>
                burstSubepoch(end+1,1) = s; %#ok<SAGROW>
                burstCategory{end+1,1} = category; %#ok<SAGROW>
                burstPeakUs(end+1,1) = peakUs; %#ok<SAGROW>
                burstPeakPosition(end+1,1) = peakPos; %#ok<SAGROW>
                burstPeakSpeedCmS(end+1,1) = peakSpeed; %#ok<SAGROW>
                burstPeakZ(end+1,1) = B.peakZ(row); %#ok<SAGROW>
                burstDurationS(end+1,1) = B.burstDurationS(row); %#ok<SAGROW>
                burstIncluded(end+1,1) = included; %#ok<SAGROW>
            end

            if novelSeconds > 0
                novelRate = novelBurstCount / novelSeconds * 60;
            else
                novelRate = NaN;
            end

            if familiarSeconds > 0
                familiarRate = familiarBurstCount / familiarSeconds * 60;
            else
                familiarRate = NaN;
            end

            rateDifference = novelRate - familiarRate;

            if familiarRate > 0
                rateRatio = novelRate / familiarRate;
            else
                rateRatio = NaN;
            end

            if novelSeconds == 0 || familiarSeconds == 0
                noteText = 'Insufficient valid moving time in one category.';
            else
                noteText = '';
            end

            subAnimal{end+1,1} = animalName; %#ok<SAGROW>
            subResIndex(end+1,1) = rIndex; %#ok<SAGROW>
            subBand{end+1,1} = bandName; %#ok<SAGROW>
            subepochCol(end+1,1) = s; %#ok<SAGROW>
            novelSecondsCol(end+1,1) = novelSeconds; %#ok<SAGROW>
            familiarSecondsCol(end+1,1) = familiarSeconds; %#ok<SAGROW>
            novelBurstCountCol(end+1,1) = novelBurstCount; %#ok<SAGROW>
            familiarBurstCountCol(end+1,1) = familiarBurstCount; %#ok<SAGROW>
            novelRateCol(end+1,1) = novelRate; %#ok<SAGROW>
            familiarRateCol(end+1,1) = familiarRate; %#ok<SAGROW>
            diffRateCol(end+1,1) = rateDifference; %#ok<SAGROW>
            ratioRateCol(end+1,1) = rateRatio; %#ok<SAGROW>
            notesCol{end+1,1} = noteText; %#ok<SAGROW>
        end
    end
end

BT = table(burstAnimal, burstResIndex, burstBand, burstSubepoch, burstCategory, ...
    burstPeakUs, burstPeakPosition, burstPeakSpeedCmS, burstPeakZ, burstDurationS, burstIncluded, ...
    'VariableNames', {'animal','resSaveIndex','band','subepoch','category', ...
    'burstPeakUs','peakPosition','peakSpeedCmS','peakZ','burstDurationS','includedInNovelFamiliarAnalysis'});

SUB = table(subAnimal, subResIndex, subBand, subepochCol, novelSecondsCol, familiarSecondsCol, ...
    novelBurstCountCol, familiarBurstCountCol, novelRateCol, familiarRateCol, diffRateCol, ratioRateCol, notesCol, ...
    'VariableNames', {'animal','resSaveIndex','band','subepoch','novelSeconds','familiarSeconds', ...
    'novelBurstCount','familiarBurstCount','novelBurstRatePerMinute','familiarBurstRatePerMinute', ...
    'novelMinusFamiliarRate','novelOverFamiliarRateRatio','notes'});

writetable(BT, fullfile(outDir, 'hc31_novel_familiar_burst_table.csv'));
writetable(SUB, fullfile(outDir, 'hc31_novel_familiar_subepoch_summary.csv'));

fprintf('\nSaved burst-level and subepoch-level tables.\n');

%% ------------------------------------------------------------------------
% 4. Animal-level pooled novel vs familiar rates
% -------------------------------------------------------------------------

animalCol = {};
bandCol = {};
resIndexCol = [];
pooledNovelSecondsCol = [];
pooledFamiliarSecondsCol = [];
pooledNovelBurstCountCol = [];
pooledFamiliarBurstCountCol = [];
pooledNovelRateCol = [];
pooledFamiliarRateCol = [];
pooledDiffRateCol = [];
pooledRatioCol = [];

animals = unique(SUB.animal, 'stable');

for a = 1:numel(animals)
    animalName = animals{a};

    for b = 1:numel(bands)
        bandName = bands{b};

        rows = strcmp(SUB.animal, animalName) & strcmp(SUB.band, bandName);

        novelSeconds = nansum(SUB.novelSeconds(rows));
        familiarSeconds = nansum(SUB.familiarSeconds(rows));

        novelBurstCount = nansum(SUB.novelBurstCount(rows));
        familiarBurstCount = nansum(SUB.familiarBurstCount(rows));

        if novelSeconds > 0
            novelRate = novelBurstCount / novelSeconds * 60;
        else
            novelRate = NaN;
        end

        if familiarSeconds > 0
            familiarRate = familiarBurstCount / familiarSeconds * 60;
        else
            familiarRate = NaN;
        end

        if familiarRate > 0
            ratio = novelRate / familiarRate;
        else
            ratio = NaN;
        end

        resIndexValue = SUB.resSaveIndex(find(rows,1,'first'));

        animalCol{end+1,1} = animalName; %#ok<SAGROW>
        bandCol{end+1,1} = bandName; %#ok<SAGROW>
        resIndexCol(end+1,1) = resIndexValue; %#ok<SAGROW>
        pooledNovelSecondsCol(end+1,1) = novelSeconds; %#ok<SAGROW>
        pooledFamiliarSecondsCol(end+1,1) = familiarSeconds; %#ok<SAGROW>
        pooledNovelBurstCountCol(end+1,1) = novelBurstCount; %#ok<SAGROW>
        pooledFamiliarBurstCountCol(end+1,1) = familiarBurstCount; %#ok<SAGROW>
        pooledNovelRateCol(end+1,1) = novelRate; %#ok<SAGROW>
        pooledFamiliarRateCol(end+1,1) = familiarRate; %#ok<SAGROW>
        pooledDiffRateCol(end+1,1) = novelRate - familiarRate; %#ok<SAGROW>
        pooledRatioCol(end+1,1) = ratio; %#ok<SAGROW>
    end
end

AN = table(animalCol, resIndexCol, bandCol, pooledNovelSecondsCol, pooledFamiliarSecondsCol, ...
    pooledNovelBurstCountCol, pooledFamiliarBurstCountCol, pooledNovelRateCol, pooledFamiliarRateCol, ...
    pooledDiffRateCol, pooledRatioCol, ...
    'VariableNames', {'animal','resSaveIndex','band','novelSeconds','familiarSeconds', ...
    'novelBurstCount','familiarBurstCount','novelBurstRatePerMinute','familiarBurstRatePerMinute', ...
    'novelMinusFamiliarRate','novelOverFamiliarRateRatio'});

writetable(AN, fullfile(outDir, 'hc31_novel_familiar_animal_summary.csv'));

fprintf('Saved animal-level summary.\n');

%% ------------------------------------------------------------------------
% 5. Animal-level exact sign-flip tests: novel vs familiar
% -------------------------------------------------------------------------

testBandCol = {};
comparisonCol = {};
nAnimalsCol = [];
meanNovelCol = [];
meanFamiliarCol = [];
meanDiffCol = [];
medianDiffCol = [];
nNovelHigherCol = [];
nFamiliarHigherCol = [];
exactPCol = [];

for b = 1:numel(bands)

    bandName = bands{b};

    rows = strcmp(AN.band, bandName);
    novelRate = AN.novelBurstRatePerMinute(rows);
    familiarRate = AN.familiarBurstRatePerMinute(rows);

    ok = ~isnan(novelRate) & ~isnan(familiarRate);
    novelRate = novelRate(ok);
    familiarRate = familiarRate(ok);

    d = novelRate - familiarRate;
    dNoZero = d(d ~= 0);

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

    testBandCol{end+1,1} = bandName; %#ok<SAGROW>
    comparisonCol{end+1,1} = 'novel burst rate minus familiar burst rate'; %#ok<SAGROW>
    nAnimalsCol(end+1,1) = numel(d); %#ok<SAGROW>
    meanNovelCol(end+1,1) = mean(novelRate); %#ok<SAGROW>
    meanFamiliarCol(end+1,1) = mean(familiarRate); %#ok<SAGROW>
    meanDiffCol(end+1,1) = mean(d); %#ok<SAGROW>
    medianDiffCol(end+1,1) = median(d); %#ok<SAGROW>
    nNovelHigherCol(end+1,1) = sum(d > 0); %#ok<SAGROW>
    nFamiliarHigherCol(end+1,1) = sum(d < 0); %#ok<SAGROW>
    exactPCol(end+1,1) = p; %#ok<SAGROW>
end

STATS = table(testBandCol, comparisonCol, nAnimalsCol, meanNovelCol, meanFamiliarCol, ...
    meanDiffCol, medianDiffCol, nNovelHigherCol, nFamiliarHigherCol, exactPCol, ...
    'VariableNames', {'band','comparison','nAnimals','meanNovelRate','meanFamiliarRate', ...
    'meanNovelMinusFamiliar','medianNovelMinusFamiliar','nNovelHigher','nFamiliarHigher','exactSignFlipP'});

writetable(STATS, fullfile(outDir, 'hc31_novel_familiar_stats.csv'));

fprintf('Saved stats table.\n');
disp(STATS);

%% ------------------------------------------------------------------------
% 6. Figures: paired familiar vs novel plots for each band
% -------------------------------------------------------------------------

for b = 1:numel(bands)

    bandName = bands{b};
    rows = strcmp(AN.band, bandName);

    plotAnimals = AN.animal(rows);
    familiarRate = AN.familiarBurstRatePerMinute(rows);
    novelRate = AN.novelBurstRatePerMinute(rows);

    ok = ~isnan(familiarRate) & ~isnan(novelRate);
    plotAnimals = plotAnimals(ok);
    familiarRate = familiarRate(ok);
    novelRate = novelRate(ok);

    d = novelRate - familiarRate;
    dNoZero = d(d ~= 0);

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

    if isnan(p)
        pLabel = 'p = NaN';
    elseif p < 0.001
        pLabel = '***  p < 0.001';
    elseif p < 0.01
        pLabel = '**  p < 0.01';
    elseif p < 0.05
        pLabel = '*  p < 0.05';
    else
        pLabel = sprintf('n.s.  p = %.3f', p);
    end

    fig = figure('Color','w', 'Name', sprintf('%s familiar vs novel', bandName));
    hold on;

    for a = 1:numel(plotAnimals)
        plot([1 2], [familiarRate(a) novelRate(a)], '-o', 'LineWidth', 1.5, 'MarkerSize', 6);
        text(2.05, novelRate(a), plotAnimals{a}, 'Interpreter','none', 'FontSize', 8);
    end

    meanFam = mean(familiarRate);
    meanNov = mean(novelRate);

    semFam = std(familiarRate) / sqrt(numel(familiarRate));
    semNov = std(novelRate) / sqrt(numel(novelRate));

    plot([1 2], [meanFam meanNov], 'k-o', 'LineWidth', 3, 'MarkerSize', 8, 'MarkerFaceColor','k');
    errorbar([1 2], [meanFam meanNov], [semFam semNov], 'k', 'LineStyle','none', 'LineWidth', 1.5);

    xlim([0.75 2.45]);
    set(gca, 'XTick', [1 2], 'XTickLabel', {'familiar','novel'});
    ylabel('burst frequency, bursts/min');
    title(sprintf('%s burst frequency: familiar vs novel track sections', bandName), 'Interpreter','none');
    grid on;

    yMax = max([familiarRate; novelRate]);
    yMin = min([familiarRate; novelRate]);
    yr = yMax - yMin;
    if yr == 0
        yr = 1;
    end

    y = yMax + 0.12*yr;
    h = 0.04*yr;

    plot([1 1 2 2], [y y+h y+h y], 'k', 'LineWidth', 1.5);
    text(1.5, y+h, pLabel, 'HorizontalAlignment','center', 'VerticalAlignment','bottom', 'FontWeight','bold');

    ylimCurrent = ylim;
    if y+h > ylimCurrent(2)
        ylim([ylimCurrent(1), y + 3*h]);
    end

    saveas(fig, fullfile(figDir, sprintf('%s_familiar_vs_novel_with_significance_bar.png', bandName)));
end

%% ------------------------------------------------------------------------
% 7. Figure: subepoch-level novel-minus-familiar differences
% -------------------------------------------------------------------------

for b = 1:numel(bands)

    bandName = bands{b};

    rows = strcmp(SUB.band, bandName) & ~isnan(SUB.novelMinusFamiliarRate);

    fig = figure('Color','w', 'Name', sprintf('%s subepoch differences', bandName));
    hold on;

    for a = 1:numel(animals)
        animalName = animals{a};
        ar = rows & strcmp(SUB.animal, animalName);

        if any(ar)
            plot(SUB.subepoch(ar), SUB.novelMinusFamiliarRate(ar), '-o', ...
                'LineWidth', 1.5, 'MarkerSize', 6, 'DisplayName', animalName);
        end
    end

    plot([0.5 4.5], [0 0], 'k--');
    xlim([0.5 4.5]);
    set(gca, 'XTick', 1:4);
    xlabel('Run1 subepoch');
    ylabel('novel - familiar burst frequency, bursts/min');
    title(sprintf('%s subepoch-level novelty difference', bandName), 'Interpreter','none');
    legend('Location','bestoutside', 'Interpreter','none');
    grid on;
    hold off;

    saveas(fig, fullfile(figDir, sprintf('%s_subepoch_novel_minus_familiar.png', bandName)));
end

fprintf('\nNovel-vs-familiar analysis complete.\n');
fprintf('Outputs saved to:\n%s\n\n', outDir);
