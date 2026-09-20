%% HC-31 Batch 2: burst-frequency heat maps across the Run1 environment
% Purpose:
%   Build spatial heat maps of beta and beta2 burst frequency across the
%   linearised Run1 track and Run1 extension subepochs.
%
% Inputs expected:
%   1) resSave.mat
%      Needed to calculate valid moving time in each spatial bin. This is
%      what turns raw burst counts into burst frequency.
%
%   2) One of the mapped burst tables from earlier scripts:
%      Preferred:
%          burst_location_outputs/hc31_burst_locations_run1.csv
%      Fallback:
%          beta_burst_novel_familiar_outputs_BETA13_30/hc31_novel_familiar_burst_table.csv
%
% Outputs:
%   Folder: hc31_batch2_burst_frequency_heatmaps/
%   CSVs:
%       hc31_batch2_spatial_bin_rates_by_animal_subepoch.csv
%       hc31_batch2_group_spatial_bin_summary.csv
%       hc31_batch2_subepoch_novel_boundaries_by_animal.csv
%       hc31_batch2_summary_notes.txt
%   Figures:
%       figures/batch2_<band>_mean_animal_rate_heatmap.png
%       figures/batch2_<band>_pooled_rate_heatmap.png
%       figures/batch2_<band>_raw_burst_count_heatmap.png
%       figures/batch2_valid_moving_time_heatmap.png
%       figures/batch2_beta2_minus_beta_mean_rate_heatmap.png
%       figures/per_animal/batch2_<animal>_<band>_rate_heatmap.png
%
% Interpretation:
%   These maps ask where beta/beta2 bursts occur after correcting for how
%   long the animal spent moving in each spatial bin. They are visual and
%   descriptive outputs, not the final statistical test.
%
% Notes:
%   - Burst frequency = burst count / valid moving time * 60.
%   - Only valid moving time is used, with speed >= speedThresholdCmS.
%   - Spatial position is shown in the dataset's linearised-position units,
%     not metres. The full long track is 48 m, but the resSave linearised
%     axis is in internal position units.
%   - Novel-section boundaries are overlaid using the mean sectExt limits
%     across animals for each subepoch.

clear; clc; close all;

%% ---------------- USER SETTINGS ----------------
% Leave these blank to auto-detect files from the current folder.
% Typical place to run from:
%   C:\Users\angel\Documents\MATLAB\CRCN
rootDir = pwd;
resSavePath = '';
burstLocationFile = '';

animalIndices = 5:9;
speedThresholdCmS = 5;
nSpatialBins = 48;             % roughly one spatial bin per metre of the 48 m track, but in linearised units
minValidSecondsPerBin = 0.25;  % bins below this are left as NaN for rate plots
bandsToUse = ["beta_13_30Hz", "beta2_23_30Hz"];
makePerAnimalFigures = true;

outputFolderName = 'hc31_batch2_burst_frequency_heatmaps';

%% ---------------- LOCATE INPUTS ----------------
if isempty(resSavePath)
    resSavePath = locateFile(rootDir, {'resSave.mat', 'resSave'});
end
if isempty(resSavePath) || exist(resSavePath, 'file') ~= 2
    error(['Could not find resSave.mat. Batch 2 needs resSave because ', ...
        'burst-frequency heat maps require valid moving time in each spatial bin.']);
end

if isempty(burstLocationFile)
    burstLocationFile = locateFile(rootDir, { ...
        'hc31_burst_locations_run1.csv', ...
        'hc31_novel_familiar_burst_table.csv'});
end
if isempty(burstLocationFile) || exist(burstLocationFile, 'file') ~= 2
    error(['Could not find a mapped burst CSV. Expected either ', ...
        'hc31_burst_locations_run1.csv or hc31_novel_familiar_burst_table.csv.']);
end

outDir = fullfile(rootDir, outputFolderName);
figDir = fullfile(outDir, 'figures');
perAnimalFigDir = fullfile(figDir, 'per_animal');
if exist(outDir, 'dir') ~= 7; mkdir(outDir); end
if exist(figDir, 'dir') ~= 7; mkdir(figDir); end
if exist(perAnimalFigDir, 'dir') ~= 7; mkdir(perAnimalFigDir); end

fprintf('\nHC-31 Batch 2: burst-frequency heat maps\n');
fprintf('resSave input: %s\n', resSavePath);
fprintf('burst table input: %s\n', burstLocationFile);
fprintf('output folder: %s\n\n', outDir);

%% ---------------- LOAD DATA ----------------
S = load(resSavePath);
if ~isfield(S, 'resSave')
    error('Loaded file does not contain variable resSave: %s', resSavePath);
end
resSave = S.resSave;

B = readtable(burstLocationFile);
B = standardiseBurstTable(B, burstLocationFile);

%% ---------------- DEFINE COMMON SPATIAL BINS ----------------
allMovingPositions = [];
for ii = 1:numel(animalIndices)
    rIndex = animalIndices(ii);
    R = resSave(rIndex);
    if ~isfield(R, 'posMazeLin') || numel(R.posMazeLin) < 1 || isempty(R.posMazeLin(1).data)
        warning('resSave(%d) has no Run1 posMazeLin data; skipping for bin setup.', rIndex);
        continue;
    end
    [posTimeUs, linPos, speedCmS] = getRun1PositionAndSpeed(R);
    validMoving = isfinite(posTimeUs) & isfinite(linPos) & isfinite(speedCmS) & speedCmS >= speedThresholdCmS;
    allMovingPositions = [allMovingPositions; linPos(validMoving)]; %#ok<AGROW>
end

if isempty(allMovingPositions)
    error('No valid moving Run1 position samples were found. Check resSave and speed settings.');
end

% Use the full observed moving-position range. Keep edges simple and common
% across animals so group heat maps can be averaged.
spatialMin = floor(min(allMovingPositions));
spatialMax = ceil(max(allMovingPositions));
spatialEdges = linspace(spatialMin, spatialMax, nSpatialBins + 1);
spatialCenters = spatialEdges(1:end-1) + diff(spatialEdges) ./ 2;

%% ---------------- COMPUTE SPATIAL-BIN BURST RATES ----------------
binRows = table();
boundaryRows = table();

for ii = 1:numel(animalIndices)
    rIndex = animalIndices(ii);
    R = resSave(rIndex);

    if ~isfield(R, 'spAll') || isempty(R.spAll) || ~isfield(R.spAll(1), 'animal')
        animalName = sprintf('resSave%d', rIndex);
    else
        animalName = char(R.spAll(1).animal);
    end

    if ~isfield(R, 'sectInt') || ~isfield(R, 'sectExt')
        warning('%s does not have sectInt/sectExt; skipping.', animalName);
        continue;
    end

    [posTimeUs, linPos, speedCmS] = getRun1PositionAndSpeed(R);
    sampleDurS = sampleDurationsSeconds(posTimeUs);

    fprintf('Processing %s / resSave(%d)\n', animalName, rIndex);

    for s = 1:size(R.sectInt, 1)
        subStartUs = R.sectInt(s, 1);
        subEndUs = R.sectInt(s, 2);
        novelStart = min(R.sectExt(s, :));
        novelEnd = max(R.sectExt(s, :));

        boundaryRows = [boundaryRows; table(string(animalName), rIndex, s, novelStart, novelEnd, ...
            'VariableNames', {'animal','resSaveIndex','subepoch','novelStartLinearPos','novelEndLinearPos'})]; %#ok<AGROW>

        inSubepoch = posTimeUs >= subStartUs & posTimeUs <= subEndUs;
        validMoving = inSubepoch & isfinite(linPos) & isfinite(speedCmS) & speedCmS >= speedThresholdCmS;

        for b = 1:numel(bandsToUse)
            bandName = bandsToUse(b);
            burstRows = B.animal == string(animalName) & B.resSaveIndex == rIndex & ...
                B.band == bandName & B.subepoch == s & B.included == true & ...
                isfinite(B.peakLinearPosition);
            Bb = B(burstRows, :);

            for k = 1:nSpatialBins
                leftEdge = spatialEdges(k);
                rightEdge = spatialEdges(k + 1);
                binCenter = spatialCenters(k);

                if k < nSpatialBins
                    inPosBin = linPos >= leftEdge & linPos < rightEdge;
                    burstInBin = Bb.peakLinearPosition >= leftEdge & Bb.peakLinearPosition < rightEdge;
                else
                    inPosBin = linPos >= leftEdge & linPos <= rightEdge;
                    burstInBin = Bb.peakLinearPosition >= leftEdge & Bb.peakLinearPosition <= rightEdge;
                end

                validSeconds = nansum(sampleDurS(validMoving & inPosBin));
                burstCount = sum(burstInBin);

                if validSeconds >= minValidSecondsPerBin
                    ratePerMinute = burstCount ./ validSeconds .* 60;
                else
                    ratePerMinute = NaN;
                end

                novelBinCenter = binCenter >= novelStart & binCenter <= novelEnd;

                row = table(string(animalName), rIndex, bandName, s, k, leftEdge, rightEdge, binCenter, ...
                    validSeconds, burstCount, ratePerMinute, novelBinCenter, novelStart, novelEnd, ...
                    'VariableNames', {'animal','resSaveIndex','band','subepoch','spatialBin', ...
                    'binStartLinearPos','binEndLinearPos','binCenterLinearPos','validMovingSeconds', ...
                    'burstCount','burstRatePerMinute','binCenterInNovelSection','novelStartLinearPos', ...
                    'novelEndLinearPos'});
                binRows = [binRows; row]; %#ok<AGROW>
            end
        end
    end
end

if isempty(binRows)
    error('No spatial-bin rows were created. Check input burst table and resSave indices.');
end

writetable(binRows, fullfile(outDir, 'hc31_batch2_spatial_bin_rates_by_animal_subepoch.csv'));
writetable(boundaryRows, fullfile(outDir, 'hc31_batch2_subepoch_novel_boundaries_by_animal.csv'));

%% ---------------- GROUP SUMMARY ----------------
groupRows = table();
subepochs = unique(binRows.subepoch, 'stable');

for b = 1:numel(bandsToUse)
    bandName = bandsToUse(b);
    for sIdx = 1:numel(subepochs)
        s = subepochs(sIdx);
        for k = 1:nSpatialBins
            idx = binRows.band == bandName & binRows.subepoch == s & binRows.spatialBin == k;
            Tb = binRows(idx, :);
            if isempty(Tb); continue; end

            validMask = Tb.validMovingSeconds >= minValidSecondsPerBin & isfinite(Tb.burstRatePerMinute);
            totalValidSeconds = sum(Tb.validMovingSeconds, 'omitnan');
            totalBurstCount = sum(Tb.burstCount, 'omitnan');

            if totalValidSeconds > 0
                pooledRate = totalBurstCount ./ totalValidSeconds .* 60;
            else
                pooledRate = NaN;
            end

            animalRates = Tb.burstRatePerMinute(validMask);
            meanAnimalRate = mean(animalRates, 'omitnan');
            semAnimalRate = sem(animalRates);
            nAnimalsWithTime = sum(Tb.validMovingSeconds >= minValidSecondsPerBin);
            nAnimalsWithRate = sum(validMask);
            propNovel = mean(double(Tb.binCenterInNovelSection), 'omitnan');

            row = table(bandName, s, k, Tb.binStartLinearPos(1), Tb.binEndLinearPos(1), Tb.binCenterLinearPos(1), ...
                nAnimalsWithTime, nAnimalsWithRate, totalValidSeconds, totalBurstCount, pooledRate, ...
                meanAnimalRate, semAnimalRate, propNovel, ...
                'VariableNames', {'band','subepoch','spatialBin','binStartLinearPos','binEndLinearPos', ...
                'binCenterLinearPos','nAnimalsWithValidTime','nAnimalsWithRate','totalValidMovingSeconds', ...
                'totalBurstCount','pooledBurstRatePerMinute','meanAnimalBurstRatePerMinute', ...
                'semAnimalBurstRatePerMinute','proportionAnimalsWhereBinIsNovel'});
            groupRows = [groupRows; row]; %#ok<AGROW>
        end
    end
end

writetable(groupRows, fullfile(outDir, 'hc31_batch2_group_spatial_bin_summary.csv'));

%% ---------------- FIGURES ----------------
for b = 1:numel(bandsToUse)
    bandName = bandsToUse(b);
    plotGroupHeatmap(groupRows, boundaryRows, bandName, subepochs, spatialCenters, 'meanAnimalBurstRatePerMinute', ...
        'Mean animal burst frequency (bursts/min)', fullfile(figDir, sprintf('batch2_%s_mean_animal_rate_heatmap.png', sanitizeFileName(bandName))));

    plotGroupHeatmap(groupRows, boundaryRows, bandName, subepochs, spatialCenters, 'pooledBurstRatePerMinute', ...
        'Pooled burst frequency (bursts/min)', fullfile(figDir, sprintf('batch2_%s_pooled_rate_heatmap.png', sanitizeFileName(bandName))));

    plotGroupHeatmap(groupRows, boundaryRows, bandName, subepochs, spatialCenters, 'totalBurstCount', ...
        'Raw burst count', fullfile(figDir, sprintf('batch2_%s_raw_burst_count_heatmap.png', sanitizeFileName(bandName))));
end

% Occupancy/valid-moving-time heat map is independent of band, so use beta2 rows
% only to avoid duplicating identical occupancy values.
plotGroupHeatmap(groupRows, boundaryRows, "beta2_23_30Hz", subepochs, spatialCenters, 'totalValidMovingSeconds', ...
    'Total valid moving time (s)', fullfile(figDir, 'batch2_valid_moving_time_heatmap.png'));

% beta2 minus broad beta heat map using mean animal rates.
if all(ismember(["beta_13_30Hz", "beta2_23_30Hz"], unique(groupRows.band)))
    plotBandDifferenceHeatmap(groupRows, boundaryRows, subepochs, spatialCenters, figDir);
end

if makePerAnimalFigures
    animals = unique(binRows.animal, 'stable');
    for a = 1:numel(animals)
        for b = 1:numel(bandsToUse)
            plotAnimalHeatmap(binRows, animals(a), bandsToUse(b), subepochs, spatialCenters, perAnimalFigDir);
        end
    end
end

%% ---------------- SUMMARY NOTES ----------------
notesFile = fullfile(outDir, 'hc31_batch2_summary_notes.txt');
fid = fopen(notesFile, 'w');
fprintf(fid, 'HC-31 Batch 2: burst-frequency heat maps across Run1 environment\n');
fprintf(fid, 'resSave input: %s\n', resSavePath);
fprintf(fid, 'burst table input: %s\n', burstLocationFile);
fprintf(fid, 'speed threshold: %.3f cm/s\n', speedThresholdCmS);
fprintf(fid, 'number of spatial bins: %d\n', nSpatialBins);
fprintf(fid, 'minimum valid seconds per bin for rate: %.3f\n\n', minValidSecondsPerBin);

fprintf(fid, 'Main purpose:\n');
fprintf(fid, ['This batch maps detected beta/beta2 bursts across linearised Run1 position ', ...
    'and Run1 subepochs. Burst counts are normalised by valid moving time ', ...
    'within each animal, subepoch and spatial bin to create burst-frequency heat maps.\n\n']);

fprintf(fid, 'Interpretation notes:\n');
fprintf(fid, ['1. The heat maps are descriptive and spatial. They show where bursts occurred ', ...
    'after correcting for valid moving time.\n']);
fprintf(fid, ['2. They should not replace animal-level statistics. Use them to identify ', ...
    'candidate spatial/novelty patterns that can be tested later.\n']);
fprintf(fid, ['3. The x-axis uses resSave linearised-position units, not metres. The full track ', ...
    'is 48 m, but the analysis uses the dataset linearised coordinate system.\n']);
fprintf(fid, ['4. White dashed overlays in the figures show mean novel-section boundaries ', ...
    'from sectExt for each subepoch.\n']);
fclose(fid);

fprintf('\nBatch 2 complete. Outputs written to:\n%s\n', outDir);
fprintf('Open %s for notes.\n', notesFile);

%% ========================================================================
%% Local functions
%% ========================================================================

function filePath = locateFile(rootDir, candidateNames)
    filePath = '';
    % First check common direct/current-folder locations.
    commonSubdirs = {'', 'allresults', 'burst_location_outputs', ...
        fullfile('allresults','burst_location_outputs'), ...
        'beta_burst_novel_familiar_outputs_BETA13_30', ...
        fullfile('allresults','beta_burst_novel_familiar_outputs_BETA13_30')};

    for c = 1:numel(candidateNames)
        fname = candidateNames{c};
        for s = 1:numel(commonSubdirs)
            testPath = fullfile(rootDir, commonSubdirs{s}, fname);
            if exist(testPath, 'file') == 2
                filePath = testPath;
                return;
            end
        end
    end

    % Then try recursive search from rootDir.
    for c = 1:numel(candidateNames)
        fname = candidateNames{c};
        hits = dir(fullfile(rootDir, '**', fname));
        if ~isempty(hits)
            filePath = fullfile(hits(1).folder, hits(1).name);
            return;
        end
    end
end

function B = standardiseBurstTable(B, sourceFile)
    vars = B.Properties.VariableNames;

    mustHave = {'animal','resSaveIndex','band','subepoch','category','burstPeakUs'};
    for i = 1:numel(mustHave)
        if ~ismember(mustHave{i}, vars)
            error('Burst table %s is missing required column: %s', sourceFile, mustHave{i});
        end
    end

    B.animal = string(B.animal);
    B.band = string(B.band);
    B.category = string(B.category);
    B.resSaveIndex = double(B.resSaveIndex);
    B.subepoch = double(B.subepoch);

    if ismember('peakLinearPosition', vars)
        B.peakLinearPosition = double(B.peakLinearPosition);
    elseif ismember('peakPosition', vars)
        B.peakLinearPosition = double(B.peakPosition);
    else
        error('Burst table %s needs peakLinearPosition or peakPosition.', sourceFile);
    end

    % Include only bursts that were valid/mapped for novelty analysis.
    if ismember('includedInNovelFamiliarAnalysis', vars)
        B.included = B.includedInNovelFamiliarAnalysis == 1;
    else
        B.included = ismember(lower(B.category), ["novel", "familiar"]);
    end

    % Keep category-based exclusion as an extra guard.
    B.included = B.included & ismember(lower(B.category), ["novel", "familiar"]);
end

function [posTimeUs, linPos, speedCmS] = getRun1PositionAndSpeed(R)
    posU = R.posMazeLin(1);
    posData = posU.data;
    posTimeUs = double(posData(:, 1));
    linPos = double(posData(:, 2));

    if size(posData, 2) >= 4
        rawSpeed = double(posData(:, 4));
        if isfield(posU, 'unitsPerCm') && isfield(posU, 'unitsPerSecond')
            speedCmS = rawSpeed .* (1 ./ posU.unitsPerCm) .* posU.unitsPerSecond;
        else
            speedCmS = rawSpeed;
        end
    else
        speedCmS = nan(size(linPos));
    end
end

function sampleDurS = sampleDurationsSeconds(tUs)
    tUs = double(tUs);
    dt = [diff(tUs); NaN] ./ 1e6;
    good = isfinite(dt) & dt > 0 & dt < 10;
    medDt = median(dt(good), 'omitnan');
    if isempty(medDt) || ~isfinite(medDt)
        medDt = 0;
    end
    dt(~good) = medDt;
    sampleDurS = dt;
end

function s = sem(x)
    x = x(isfinite(x));
    if numel(x) <= 1
        s = NaN;
    else
        s = std(x, 0, 'omitnan') ./ sqrt(numel(x));
    end
end

function out = sanitizeFileName(strIn)
    out = char(strIn);
    out = strrep(out, '/', '_');
    out = strrep(out, '\', '_');
    out = strrep(out, ':', '_');
    out = strrep(out, ' ', '_');
end

function M = matrixFromGroupRows(G, bandName, subepochs, nSpatialBins, valueName)
    M = nan(numel(subepochs), nSpatialBins);
    for sIdx = 1:numel(subepochs)
        s = subepochs(sIdx);
        for k = 1:nSpatialBins
            idx = G.band == bandName & G.subepoch == s & G.spatialBin == k;
            if any(idx)
                M(sIdx, k) = G.(valueName)(find(idx, 1, 'first'));
            end
        end
    end
end

function plotGroupHeatmap(G, boundaryRows, bandName, subepochs, spatialCenters, valueName, colorbarLabel, savePath)
    nSpatialBins = numel(spatialCenters);
    M = matrixFromGroupRows(G, bandName, subepochs, nSpatialBins, valueName);

    fig = figure('Color','w', 'Position', [100 100 1100 550]);
    h = imagesc(spatialCenters, subepochs, M);
    set(gca, 'YDir', 'normal');
    set(h, 'AlphaData', ~isnan(M));
    colormap(parula);
    cb = colorbar;
    ylabel(cb, colorbarLabel, 'Interpreter','none');
    xlabel('linearised Run1 position');
    ylabel('Run1 subepoch');
    title(sprintf('%s: %s', char(bandName), colorbarLabel), 'Interpreter','none');
    yticks(subepochs);
    grid on;
    hold on;
    overlayNovelBoundaries(boundaryRows, subepochs);
    hold off;
    saveas(fig, savePath);
    close(fig);
end

function overlayNovelBoundaries(boundaryRows, subepochs)
    for sIdx = 1:numel(subepochs)
        s = subepochs(sIdx);
        idx = boundaryRows.subepoch == s;
        if any(idx)
            ns = mean(boundaryRows.novelStartLinearPos(idx), 'omitnan');
            ne = mean(boundaryRows.novelEndLinearPos(idx), 'omitnan');
            y0 = s - 0.42;
            y1 = s + 0.42;
            plot([ns ns], [y0 y1], 'w--', 'LineWidth', 1.5);
            plot([ne ne], [y0 y1], 'w--', 'LineWidth', 1.5);
        end
    end
end

function plotBandDifferenceHeatmap(G, boundaryRows, subepochs, spatialCenters, figDir)
    nSpatialBins = numel(spatialCenters);
    Mbeta = matrixFromGroupRows(G, "beta_13_30Hz", subepochs, nSpatialBins, 'meanAnimalBurstRatePerMinute');
    Mbeta2 = matrixFromGroupRows(G, "beta2_23_30Hz", subepochs, nSpatialBins, 'meanAnimalBurstRatePerMinute');
    Mdiff = Mbeta2 - Mbeta;

    fig = figure('Color','w', 'Position', [100 100 1100 550]);
    h = imagesc(spatialCenters, subepochs, Mdiff);
    set(gca, 'YDir', 'normal');
    set(h, 'AlphaData', ~isnan(Mdiff));
    colormap(parula);
    cb = colorbar;
    ylabel(cb, 'beta2 minus beta mean animal rate (bursts/min)', 'Interpreter','none');
    xlabel('linearised Run1 position');
    ylabel('Run1 subepoch');
    title('beta2_23_30Hz minus beta_13_30Hz burst-frequency heat map', 'Interpreter','none');
    yticks(subepochs);
    grid on;
    hold on;
    overlayNovelBoundaries(boundaryRows, subepochs);
    hold off;
    saveas(fig, fullfile(figDir, 'batch2_beta2_minus_beta_mean_rate_heatmap.png'));
    close(fig);
end

function plotAnimalHeatmap(binRows, animalName, bandName, subepochs, spatialCenters, saveDir)
    nSpatialBins = numel(spatialCenters);
    M = nan(numel(subepochs), nSpatialBins);
    for sIdx = 1:numel(subepochs)
        s = subepochs(sIdx);
        for k = 1:nSpatialBins
            idx = binRows.animal == animalName & binRows.band == bandName & ...
                binRows.subepoch == s & binRows.spatialBin == k;
            if any(idx)
                M(sIdx, k) = binRows.burstRatePerMinute(find(idx, 1, 'first'));
            end
        end
    end

    fig = figure('Color','w', 'Position', [100 100 1000 500]);
    h = imagesc(spatialCenters, subepochs, M);
    set(gca, 'YDir', 'normal');
    set(h, 'AlphaData', ~isnan(M));
    colormap(parula);
    cb = colorbar;
    ylabel(cb, 'burst frequency (bursts/min)', 'Interpreter','none');
    xlabel('linearised Run1 position');
    ylabel('Run1 subepoch');
    title(sprintf('%s %s spatial burst-frequency heat map', char(animalName), char(bandName)), 'Interpreter','none');
    yticks(subepochs);
    grid on;
    saveName = sprintf('batch2_%s_%s_rate_heatmap.png', sanitizeFileName(animalName), sanitizeFileName(bandName));
    saveas(fig, fullfile(saveDir, saveName));
    close(fig);
end
