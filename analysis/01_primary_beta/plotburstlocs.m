% plotburstlocs.m
% ------------------------------------------------------------
% HC-31 burst-location plotting script.
%
% Purpose:
%   Plot where detected beta/beta2 bursts occur along the track during Run1.
%
% This script:
%   1. Loads detected bursts from the most recent burst-detection output.
%   2. Loads resSave to access Run1 position, sectInt, and sectExt.
%   3. Classifies each burst location as novel or familiar using sectExt.
%   4. Plots burst locations over time on the linearised track.
%   5. Plots burst-location histograms along the linearised track.
%   6. Plots burst locations on the 2D x-y trajectory.
%   7. Produces pooled all-animal location histograms.
%   8. Saves a burst-location CSV table.
%
% Input priority:
%   1. beta_burst_over_time_outputs_BETA13_30_FUNC/hc31_detected_beta_bursts.csv
%   2. beta_burst_over_time_outputs_FUNC/hc31_detected_beta_bursts.csv
%
% Output folder:
%   <HC31_DATA_ROOT>/burst_location_outputs\
%
% Run:
%   cd('<HC31_DATA_ROOT>')
%   plotburstlocs
%
% If MATLAB refuses to run scripts directly:
%   code = fileread('plotburstlocs.m');
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

outDir = fullfile(direc, 'burst_location_outputs');
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
% 3. Load detected-burst table
% -------------------------------------------------------------------------

burstCsvNew = fullfile(direc, 'beta_burst_over_time_outputs_BETA13_30_FUNC', 'hc31_detected_beta_bursts.csv');
burstCsvOld = fullfile(direc, 'beta_burst_over_time_outputs_FUNC', 'hc31_detected_beta_bursts.csv');

if exist(burstCsvNew, 'file') == 2
    burstCsv = burstCsvNew;
elseif exist(burstCsvOld, 'file') == 2
    burstCsv = burstCsvOld;
else
    error('Could not find detected burst table in either expected output folder.');
end

B = readtable(burstCsv);

fprintf('Loaded resSave from:\n%s\n\n', resPath);
fprintf('Loaded burst table from:\n%s\n\n', burstCsv);
fprintf('Saving burst-location outputs to:\n%s\n\n', outDir);

if ~ismember('excludedAsArtifact', B.Properties.VariableNames)
    B.excludedAsArtifact = false(height(B),1);
end

bands = unique(B.band, 'stable');

%% ------------------------------------------------------------------------
% 4. Output table containers
% -------------------------------------------------------------------------

outAnimal = {};
outResIndex = [];
outBand = {};
outSubepoch = [];
outCategory = {};
outBurstPeakUs = [];
outPeakTimeMinFromRun1Start = [];
outPeakPosition = [];
outPeakX = [];
outPeakY = [];
outPeakSpeedCmS = [];
outPeakZ = [];
outBurstDurationS = [];

%% ------------------------------------------------------------------------
% 5. Classify bursts and create per-animal plots
% -------------------------------------------------------------------------

for ai = 1:numel(animalIndices)

    i = animalIndices(ai);
    R = resSave(i);
    animalName = R.spAll(1).animal;

    fprintf('Processing burst locations for resSave(%d): %s\n', i, animalName);

    %% Position data for Run1

    posLinU = R.posMazeLin(1);
    posLinData = posLinU.data;

    posTimeUs = posLinData(:,1);
    linPos = posLinData(:,2);

    if size(posLinData,2) >= 4
        rawSpeed = posLinData(:,4);

        if isfield(posLinU, 'unitsPerCm') && isfield(posLinU, 'unitsPerSecond')
            speedCmS = rawSpeed .* (1 ./ posLinU.unitsPerCm) .* posLinU.unitsPerSecond;
        else
            speedCmS = rawSpeed;
        end
    else
        speedCmS = NaN(size(linPos));
    end

    posXYU = R.posMaze(1);
    posXYData = posXYU.data;
    posXYTimeUs = posXYData(:,1);
    xPos = posXYData(:,2);
    yPos = posXYData(:,3);

    run1StartUs = min(R.sectInt(:,1));
    run1EndUs = max(R.sectInt(:,2));

    tMin = (posTimeUs - run1StartUs) ./ 60e6;

    animalRows = strcmp(B.animal, animalName) & B.resSaveIndex == i & B.excludedAsArtifact == 0;

    %% Classify burst locations for this animal

    animalBurstRows = find(animalRows);

    for rr = 1:numel(animalBurstRows)

        row = animalBurstRows(rr);

        peakUs = B.burstPeakUs(row);

        if peakUs < run1StartUs || peakUs > run1EndUs
            continue;
        end

        if ismember('peakPosition', B.Properties.VariableNames)
            peakLin = B.peakPosition(row);
        else
            peakLin = interp1(posTimeUs, linPos, peakUs, 'linear', NaN);
        end

        if ismember('peakSpeedCmS', B.Properties.VariableNames)
            peakSpeed = B.peakSpeedCmS(row);
        else
            peakSpeed = interp1(posTimeUs, speedCmS, peakUs, 'linear', NaN);
        end

        peakX = interp1(posXYTimeUs, xPos, peakUs, 'linear', NaN);
        peakY = interp1(posXYTimeUs, yPos, peakUs, 'linear', NaN);

        subepoch = NaN;
        category = 'unclassified';

        for s = 1:size(R.sectInt,1)

            if peakUs >= R.sectInt(s,1) && peakUs <= R.sectInt(s,2)

                subepoch = s;

                novelStart = min(R.sectExt(s,:));
                novelEnd = max(R.sectExt(s,:));

                if isnan(peakLin) || isnan(peakSpeed)
                    category = 'unclassified';
                elseif peakSpeed < speedThresholdCmS
                    category = 'below_speed_threshold';
                elseif peakLin >= novelStart && peakLin <= novelEnd
                    category = 'novel';
                else
                    category = 'familiar';
                end
            end
        end

        outAnimal{end+1,1} = animalName; %#ok<SAGROW>
        outResIndex(end+1,1) = i; %#ok<SAGROW>
        outBand{end+1,1} = B.band{row}; %#ok<SAGROW>
        outSubepoch(end+1,1) = subepoch; %#ok<SAGROW>
        outCategory{end+1,1} = category; %#ok<SAGROW>
        outBurstPeakUs(end+1,1) = peakUs; %#ok<SAGROW>
        outPeakTimeMinFromRun1Start(end+1,1) = (peakUs - run1StartUs) ./ 60e6; %#ok<SAGROW>
        outPeakPosition(end+1,1) = peakLin; %#ok<SAGROW>
        outPeakX(end+1,1) = peakX; %#ok<SAGROW>
        outPeakY(end+1,1) = peakY; %#ok<SAGROW>
        outPeakSpeedCmS(end+1,1) = peakSpeed; %#ok<SAGROW>

        if ismember('peakZ', B.Properties.VariableNames)
            outPeakZ(end+1,1) = B.peakZ(row); %#ok<SAGROW>
        else
            outPeakZ(end+1,1) = NaN; %#ok<SAGROW>
        end

        if ismember('burstDurationS', B.Properties.VariableNames)
            outBurstDurationS(end+1,1) = B.burstDurationS(row); %#ok<SAGROW>
        else
            outBurstDurationS(end+1,1) = NaN; %#ok<SAGROW>
        end
    end

    %% Create per-animal plots

    for b = 1:numel(bands)

        bandName = bands{b};

        rowsBand = strcmp(B.animal, animalName) & B.resSaveIndex == i & ...
                   strcmp(B.band, bandName) & B.excludedAsArtifact == 0;

        peakTimes = B.burstPeakUs(rowsBand);

        if ismember('peakPosition', B.Properties.VariableNames)
            peakLinVals = B.peakPosition(rowsBand);
        else
            peakLinVals = interp1(posTimeUs, linPos, peakTimes, 'linear', NaN);
        end

        if ismember('peakSpeedCmS', B.Properties.VariableNames)
            peakSpeedVals = B.peakSpeedCmS(rowsBand);
        else
            peakSpeedVals = interp1(posTimeUs, speedCmS, peakTimes, 'linear', NaN);
        end

        peakXVals = interp1(posXYTimeUs, xPos, peakTimes, 'linear', NaN);
        peakYVals = interp1(posXYTimeUs, yPos, peakTimes, 'linear', NaN);

        peakTimeMinVals = (peakTimes - run1StartUs) ./ 60e6;

        validBurst = peakTimes >= run1StartUs & peakTimes <= run1EndUs & ...
                     ~isnan(peakLinVals) & ~isnan(peakSpeedVals) & ...
                     peakSpeedVals >= speedThresholdCmS;

        peakTimes = peakTimes(validBurst);
        peakLinVals = peakLinVals(validBurst);
        peakXVals = peakXVals(validBurst);
        peakYVals = peakYVals(validBurst);
        peakTimeMinVals = peakTimeMinVals(validBurst);

        categoryVals = repmat({'familiar'}, numel(peakTimes), 1);

        for kk = 1:numel(peakTimes)
            categoryVals{kk} = 'unclassified';

            for s = 1:size(R.sectInt,1)
                if peakTimes(kk) >= R.sectInt(s,1) && peakTimes(kk) <= R.sectInt(s,2)

                    novelStart = min(R.sectExt(s,:));
                    novelEnd = max(R.sectExt(s,:));

                    if peakLinVals(kk) >= novelStart && peakLinVals(kk) <= novelEnd
                        categoryVals{kk} = 'novel';
                    else
                        categoryVals{kk} = 'familiar';
                    end
                end
            end
        end

        novelMask = strcmp(categoryVals, 'novel');
        familiarMask = strcmp(categoryVals, 'familiar');

        %% Plot A: burst locations over time on linearised track

        fig1 = figure('Color','w', 'Name', sprintf('%s %s burst locations over time', animalName, bandName));
        hold on;

        plot(tMin, linPos, 'Color', [0.7 0.7 0.7], 'LineWidth', 1, 'DisplayName', 'position trace');

        scatter(peakTimeMinVals(familiarMask), peakLinVals(familiarMask), 18, 'filled', ...
            'DisplayName', 'familiar bursts');
        scatter(peakTimeMinVals(novelMask), peakLinVals(novelMask), 30, 'filled', ...
            'DisplayName', 'novel bursts');

        for s = 1:size(R.sectInt,1)
            subStartMin = (R.sectInt(s,1) - run1StartUs) ./ 60e6;
            subEndMin = (R.sectInt(s,2) - run1StartUs) ./ 60e6;

            xline(subStartMin, 'k:');
            xline(subEndMin, 'r:');

            yline(R.sectExt(s,1), 'k:');
            yline(R.sectExt(s,2), 'r:');
        end

        xlabel('time from Run1 start, minutes');
        ylabel('linearised position');
        title(sprintf('%s %s burst locations on Run1 track', animalName, bandName), 'Interpreter','none');
        legend('Location','bestoutside', 'Interpreter','none');
        grid on;
        hold off;

        saveas(fig1, fullfile(figDir, sprintf('%s_%s_burst_locations_time_position.png', animalName, bandName)));

        %% Plot B: histogram of burst locations along linearised track

        fig2 = figure('Color','w', 'Name', sprintf('%s %s burst-position histogram', animalName, bandName));
        hold on;

        histogram(peakLinVals(familiarMask), 30, 'DisplayName', 'familiar bursts');
        histogram(peakLinVals(novelMask), 30, 'DisplayName', 'novel bursts');

        for s = 1:size(R.sectExt,1)
            xline(R.sectExt(s,1), 'k:');
            xline(R.sectExt(s,2), 'r:');
        end

        xlabel('linearised position');
        ylabel('burst count');
        title(sprintf('%s %s burst-position histogram', animalName, bandName), 'Interpreter','none');
        legend('Location','best');
        grid on;
        hold off;

        saveas(fig2, fullfile(figDir, sprintf('%s_%s_burst_position_histogram.png', animalName, bandName)));

        %% Plot C: burst locations on x-y path

        fig3 = figure('Color','w', 'Name', sprintf('%s %s burst x-y locations', animalName, bandName));
        hold on;

        plot(xPos, yPos, 'Color', [0.75 0.75 0.75], 'LineWidth', 1, 'DisplayName', 'Run1 path');
        scatter(peakXVals(familiarMask), peakYVals(familiarMask), 18, 'filled', 'DisplayName', 'familiar bursts');
        scatter(peakXVals(novelMask), peakYVals(novelMask), 30, 'filled', 'DisplayName', 'novel bursts');

        axis equal;
        xlabel('x position');
        ylabel('y position');
        title(sprintf('%s %s burst locations on x-y path', animalName, bandName), 'Interpreter','none');
        legend('Location','bestoutside', 'Interpreter','none');
        grid on;
        hold off;

        saveas(fig3, fullfile(figDir, sprintf('%s_%s_burst_locations_xy.png', animalName, bandName)));
    end
end

%% ------------------------------------------------------------------------
% 6. Save burst-location table
% -------------------------------------------------------------------------

locTable = table(outAnimal, outResIndex, outBand, outSubepoch, outCategory, ...
    outBurstPeakUs, outPeakTimeMinFromRun1Start, outPeakPosition, outPeakX, outPeakY, ...
    outPeakSpeedCmS, outPeakZ, outBurstDurationS, ...
    'VariableNames', {'animal','resSaveIndex','band','subepoch','category', ...
    'burstPeakUs','peakTimeMinFromRun1Start','peakLinearPosition','peakX','peakY', ...
    'peakSpeedCmS','peakZ','burstDurationS'});

locCsv = fullfile(outDir, 'hc31_burst_locations_run1.csv');
writetable(locTable, locCsv);

fprintf('\nSaved burst-location table:\n%s\n', locCsv);

%% ------------------------------------------------------------------------
% 7. Pooled all-animal plots by band
% -------------------------------------------------------------------------

bandsOut = unique(locTable.band, 'stable');

for b = 1:numel(bandsOut)

    bandName = bandsOut{b};

    rowsBand = strcmp(locTable.band, bandName) & ...
               (strcmp(locTable.category, 'novel') | strcmp(locTable.category, 'familiar'));

    if ~any(rowsBand)
        continue;
    end

    %% Pooled histogram by position

    figPool = figure('Color','w', 'Name', sprintf('Pooled %s burst locations', bandName));
    hold on;

    histogram(locTable.peakLinearPosition(rowsBand & strcmp(locTable.category, 'familiar')), ...
        40, 'Normalization', 'probability', 'DisplayName', 'familiar');
    histogram(locTable.peakLinearPosition(rowsBand & strcmp(locTable.category, 'novel')), ...
        40, 'Normalization', 'probability', 'DisplayName', 'novel');

    xlabel('linearised position');
    ylabel('probability');
    title(sprintf('Pooled %s burst locations along linearised track', bandName), 'Interpreter','none');
    legend('Location','best');
    grid on;
    hold off;

    saveas(figPool, fullfile(figDir, sprintf('pooled_%s_burst_position_probability_histogram.png', bandName)));

    %% Pooled count per subepoch and category

    subepochVals = 1:4;
    familiarCounts = zeros(numel(subepochVals),1);
    novelCounts = zeros(numel(subepochVals),1);

    for s = 1:numel(subepochVals)
        familiarCounts(s) = sum(rowsBand & locTable.subepoch == subepochVals(s) & strcmp(locTable.category, 'familiar'));
        novelCounts(s) = sum(rowsBand & locTable.subepoch == subepochVals(s) & strcmp(locTable.category, 'novel'));
    end

    figSub = figure('Color','w', 'Name', sprintf('Pooled %s bursts by subepoch', bandName));
    bar(subepochVals, [familiarCounts novelCounts]);
    xlabel('Run1 subepoch');
    ylabel('burst count');
    title(sprintf('Pooled %s burst counts by subepoch and track category', bandName), 'Interpreter','none');
    legend({'familiar','novel'}, 'Location','best');
    grid on;

    saveas(figSub, fullfile(figDir, sprintf('pooled_%s_burst_counts_by_subepoch.png', bandName)));
end

fprintf('Saved figures to:\n%s\n', figDir);
fprintf('\nDone. Burst-location plotting complete.\n');
