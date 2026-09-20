%% HC-31 Batch 4: improved novelty statistics
% Purpose:
%   Strengthen the novel-vs-familiar beta/beta2 analysis by adding more
%   explicit animal-level statistics, bootstrap confidence intervals,
%   occupancy-preserving permutation tests, and model-ready long-format data.
%
% Inputs expected:
%   Preferred:
%       hc31_batch1_within_subepoch_animal_rates.csv
%       OR hc31_novel_familiar_subepoch_summary.csv
%
%   Optional, if Batch 3 has been run:
%       hc31_batch3_novel_familiar_speed_by_animal_subepoch.csv
%
% Outputs:
%   Folder: hc31_batch4_novelty_statistics/
%   CSVs:
%       hc31_batch4_clean_subepoch_input.csv
%       hc31_batch4_pooled_animal_rates.csv
%       hc31_batch4_exact_signflip_stats.csv
%       hc31_batch4_bootstrap_confidence_intervals.csv
%       hc31_batch4_occupancy_preserving_permutation_stats.csv
%       hc31_batch4_model_ready_long_table.csv
%       hc31_batch4_speed_adjusted_sensitivity.csv          [if speed file found]
%       hc31_batch4_summary_notes.txt
%   Figures:
%       figures/batch4_<band>_bootstrap_pooled_difference.png
%       figures/batch4_<band>_permutation_null_pooled_difference.png
%       figures/batch4_pooled_effect_summary.png
%       figures/batch4_<band>_speed_difference_sensitivity.png [if speed file found]
%
% What this batch adds:
%   1) Exact animal-level paired sign-flip tests remain the conservative
%      main inference.
%   2) Bootstrap CIs show uncertainty in the mean animal-level difference.
%   3) Occupancy-preserving permutation asks whether the observed novelty
%      difference is larger than expected if bursts were distributed between
%      novel and familiar space only according to valid moving time.
%   4) The long-format output table can be used later in R/MATLAB for a
%      mixed-effects count model such as:
%          burstCount ~ novelty + subepoch + speed + offset(log(validMovingMinutes)) + (1|animal)
%
% Notes:
%   - Subepoch 1 is excluded because the first available track section has
%     no within-subepoch familiar control region.
%   - This script keeps animals as the main independent unit.
%   - Permutation/count simulations use valid moving time to preserve
%     unequal occupancy across novel/familiar sections.
%   - If only five animals are present, a two-sided exact sign-flip test
%     cannot go below p = 0.0625 even when all animals show the same direction.

clear; clc; close all;

%% ---------------- USER SETTINGS ----------------
rootDir = pwd;

% Leave blank to auto-detect.
subepochInputFile = '';
speedInputFile = '';

eligibleSubepochs = [2 3 4];
minValidSeconds = 1;

% Number of resamples. Increase if you want smoother null distributions.
nBootstrap = 10000;
nPermutations = 10000;
randomSeed = 31;

% Band names are auto-detected from the input file. If you want to restrict
% to one or two bands, set this to a string array, e.g. ["beta_13_30Hz","beta2_23_30Hz"].
bandsToUse = strings(0,1);

outputFolderName = 'hc31_batch4_novelty_statistics';

%% ---------------- LOCATE INPUTS ----------------
rng(randomSeed);

if isempty(subepochInputFile)
    subepochInputFile = locateFile(rootDir, { ...
        'hc31_batch1_within_subepoch_animal_rates.csv', ...
        'hc31_novel_familiar_subepoch_summary.csv'});
end
if isempty(subepochInputFile) || exist(subepochInputFile, 'file') ~= 2
    error(['Could not find a novel/familiar subepoch summary. Expected ', ...
        'hc31_batch1_within_subepoch_animal_rates.csv or ', ...
        'hc31_novel_familiar_subepoch_summary.csv.']);
end

if isempty(speedInputFile)
    speedInputFile = locateFile(rootDir, {'hc31_batch3_novel_familiar_speed_by_animal_subepoch.csv'});
end
hasSpeedFile = ~isempty(speedInputFile) && exist(speedInputFile, 'file') == 2;

outDir = fullfile(rootDir, outputFolderName);
figDir = fullfile(outDir, 'figures');
if exist(outDir, 'dir') ~= 7; mkdir(outDir); end
if exist(figDir, 'dir') ~= 7; mkdir(figDir); end

fprintf('\nHC-31 Batch 4: improved novelty statistics\n');
fprintf('subepoch input: %s\n', subepochInputFile);
if hasSpeedFile
    fprintf('speed input: %s\n', speedInputFile);
else
    fprintf('speed input: not found. Speed-adjusted sensitivity output will be skipped.\n');
end
fprintf('output folder: %s\n\n', outDir);

%% ---------------- READ AND STANDARDISE SUBEPOCH TABLE ----------------
Traw = readtable(subepochInputFile);
T = standardiseSubepochTable(Traw, subepochInputFile);

% Keep only analysis subepochs with both novel and familiar valid moving time.
T = T(ismember(T.subepoch, eligibleSubepochs), :);
T = T(T.novelSeconds >= minValidSeconds & T.familiarSeconds >= minValidSeconds, :);
T = T(isfinite(T.novelBurstRatePerMinute) & isfinite(T.familiarBurstRatePerMinute), :);

if isempty(T)
    error('No eligible subepoch rows found after filtering. Check input file and eligibleSubepochs settings.');
end

if isempty(bandsToUse)
    bandsToUse = unique(T.band, 'stable');
else
    bandsToUse = string(bandsToUse);
    T = T(ismember(T.band, bandsToUse), :);
end

% Add optional speed metrics.
if hasSpeedFile
    S = readtable(speedInputFile);
    S = standardiseSpeedTable(S, speedInputFile);
    T = addSpeedToSubepochRows(T, S);
else
    T.novelMeanMovingSpeedCmS = NaN(height(T),1);
    T.familiarMeanMovingSpeedCmS = NaN(height(T),1);
    T.novelMinusFamiliarSpeedCmS = NaN(height(T),1);
end

writetable(T, fullfile(outDir, 'hc31_batch4_clean_subepoch_input.csv'));

%% ---------------- POOLED SUBEPOCHS 2-4 PER ANIMAL ----------------
pooledAnimal = poolSubepochsPerAnimal(T);
writetable(pooledAnimal, fullfile(outDir, 'hc31_batch4_pooled_animal_rates.csv'));

%% ---------------- EXACT SIGN-FLIP STATS ----------------
exactStats = table();

% A) pooled across subepochs 2-4
for b = 1:numel(bandsToUse)
    bandName = bandsToUse(b);
    Tb = pooledAnimal(pooledAnimal.band == bandName, :);
    row = exactStatsRow(Tb.novelMinusFamiliarRate, bandName, "pooled_subepochs_2_4", NaN, ...
        mean(Tb.familiarBurstRatePerMinute, 'omitnan'), mean(Tb.novelBurstRatePerMinute, 'omitnan'));
    exactStats = [exactStats; row]; %#ok<AGROW>
end

% B) within each subepoch
for b = 1:numel(bandsToUse)
    bandName = bandsToUse(b);
    for s = eligibleSubepochs
        Tb = T(T.band == bandName & T.subepoch == s, :);
        row = exactStatsRow(Tb.novelMinusFamiliarRate, bandName, "within_subepoch", s, ...
            mean(Tb.familiarBurstRatePerMinute, 'omitnan'), mean(Tb.novelBurstRatePerMinute, 'omitnan'));
        exactStats = [exactStats; row]; %#ok<AGROW>
    end
end

writetable(exactStats, fullfile(outDir, 'hc31_batch4_exact_signflip_stats.csv'));

%% ---------------- BOOTSTRAP CIs ----------------
bootstrapStats = table();
bootDistributions = struct();

for b = 1:numel(bandsToUse)
    bandName = bandsToUse(b);
    Tb = pooledAnimal(pooledAnimal.band == bandName, :);
    diffs = Tb.novelMinusFamiliarRate;
    diffs = diffs(isfinite(diffs));
    bootMeans = bootstrapMeanByAnimal(diffs, nBootstrap);
    bootDistributions.(safeFieldName(bandName)) = bootMeans;
    ci = prctile(bootMeans, [2.5 50 97.5]);
    obsMean = mean(diffs, 'omitnan');
    propLeZero = mean(bootMeans <= 0);
    propGeZero = mean(bootMeans >= 0);
    row = table(bandName, "pooled_subepochs_2_4", numel(diffs), nBootstrap, obsMean, ci(1), ci(2), ci(3), ...
        propLeZero, propGeZero, ...
        'VariableNames', {'band','comparison','nAnimals','nBootstrap','observedMeanDiff', ...
        'bootstrapCI_low_2_5','bootstrapMedian','bootstrapCI_high_97_5', ...
        'bootstrapProportionLessOrEqualZero','bootstrapProportionGreaterOrEqualZero'});
    bootstrapStats = [bootstrapStats; row]; %#ok<AGROW>
    plotBootstrapDistribution(bootMeans, obsMean, ci, bandName, figDir);
end

writetable(bootstrapStats, fullfile(outDir, 'hc31_batch4_bootstrap_confidence_intervals.csv'));

%% ---------------- OCCUPANCY-PRESERVING PERMUTATION / COUNT SIMULATION ----------------
permStats = table();
permDistributions = struct();

for b = 1:numel(bandsToUse)
    bandName = bandsToUse(b);
    Tb = T(T.band == bandName, :);
    [obsMeanDiff, nullMeanDiffs] = occupancyPreservingPermutation(Tb, nPermutations);
    nullMeanDiffs = nullMeanDiffs(isfinite(nullMeanDiffs));
    permDistributions.(safeFieldName(bandName)) = nullMeanDiffs;
    pTwo = (sum(abs(nullMeanDiffs) >= abs(obsMeanDiff)) + 1) / (numel(nullMeanDiffs) + 1);
    pNovelGreater = (sum(nullMeanDiffs >= obsMeanDiff) + 1) / (numel(nullMeanDiffs) + 1);
    nullCI = prctile(nullMeanDiffs, [2.5 50 97.5]);
    row = table(bandName, "pooled_subepochs_2_4", height(Tb), numel(unique(Tb.animal)), nPermutations, ...
        obsMeanDiff, mean(nullMeanDiffs, 'omitnan'), nullCI(1), nullCI(2), nullCI(3), pTwo, pNovelGreater, ...
        'VariableNames', {'band','comparison','nSubepochRows','nAnimals','nPermutations', ...
        'observedMeanNovelMinusFamiliar','nullMean','nullCI_low_2_5','nullMedian', ...
        'nullCI_high_97_5','pTwoSidedOccupancyPermutation','pOneSidedNovelGreater'});
    permStats = [permStats; row]; %#ok<AGROW>
    plotPermutationNull(nullMeanDiffs, obsMeanDiff, nullCI, bandName, figDir);
end

writetable(permStats, fullfile(outDir, 'hc31_batch4_occupancy_preserving_permutation_stats.csv'));

%% ---------------- MODEL-READY LONG TABLE ----------------
M = buildModelReadyLongTable(T);
writetable(M, fullfile(outDir, 'hc31_batch4_model_ready_long_table.csv'));

%% ---------------- SPEED-ADJUSTED SENSITIVITY ----------------
speedStats = table();
if hasSpeedFile
    for b = 1:numel(bandsToUse)
        bandName = bandsToUse(b);
        Tb = T(T.band == bandName, :);
        speedStats = [speedStats; speedAdjustedSensitivity(Tb, bandName, nBootstrap)]; %#ok<AGROW>
        plotSpeedSensitivity(Tb, bandName, figDir);
    end
    writetable(speedStats, fullfile(outDir, 'hc31_batch4_speed_adjusted_sensitivity.csv'));
end

%% ---------------- SUMMARY EFFECT FIGURE ----------------
plotEffectSummary(bootstrapStats, permStats, figDir);

%% ---------------- SUMMARY NOTES ----------------
notesFile = fullfile(outDir, 'hc31_batch4_summary_notes.txt');
writeSummaryNotes(notesFile, subepochInputFile, speedInputFile, hasSpeedFile, eligibleSubepochs, ...
    exactStats, bootstrapStats, permStats, speedStats, nBootstrap, nPermutations);

fprintf('\nBatch 4 complete. Outputs written to:\n%s\n', outDir);
fprintf('Main files to inspect first:\n');
fprintf('  hc31_batch4_exact_signflip_stats.csv\n');
fprintf('  hc31_batch4_bootstrap_confidence_intervals.csv\n');
fprintf('  hc31_batch4_occupancy_preserving_permutation_stats.csv\n');
fprintf('  hc31_batch4_model_ready_long_table.csv\n\n');

%% ========================================================================
%                                FUNCTIONS
% ========================================================================

function f = locateFile(rootDir, targetNames)
    f = '';
    if ischar(targetNames); targetNames = {targetNames}; end
    for i = 1:numel(targetNames)
        d = dir(fullfile(rootDir, '**', targetNames{i}));
        if ~isempty(d)
            % Prefer the shortest path / highest-level file if duplicates exist.
            paths = strings(numel(d), 1);
            depths = zeros(numel(d), 1);
            for k = 1:numel(d)
                paths(k) = string(fullfile(d(k).folder, d(k).name));
                depths(k) = count(paths(k), filesep);
            end
            [~, order] = sort(depths, 'ascend');
            f = char(paths(order(1)));
            return;
        end
    end
end

function T = standardiseSubepochTable(Traw, sourceFile)
    vars = string(Traw.Properties.VariableNames);
    reqBase = ["animal","resSaveIndex","band","subepoch","novelSeconds", ...
        "familiarSeconds","novelBurstCount","familiarBurstCount"];
    for i = 1:numel(reqBase)
        if ~any(vars == reqBase(i))
            error('Missing required column %s in %s', reqBase(i), sourceFile);
        end
    end

    T = table();
    T.animal = string(Traw.animal);
    T.resSaveIndex = double(Traw.resSaveIndex);
    T.band = string(Traw.band);
    T.subepoch = double(Traw.subepoch);
    T.novelSeconds = double(Traw.novelSeconds);
    T.familiarSeconds = double(Traw.familiarSeconds);
    T.novelBurstCount = double(Traw.novelBurstCount);
    T.familiarBurstCount = double(Traw.familiarBurstCount);

    if any(vars == "novelBurstRatePerMinute_recomputed")
        T.novelBurstRatePerMinute = double(Traw.novelBurstRatePerMinute_recomputed);
    elseif any(vars == "novelBurstRatePerMinute")
        T.novelBurstRatePerMinute = double(Traw.novelBurstRatePerMinute);
    else
        T.novelBurstRatePerMinute = safeRate(T.novelBurstCount, T.novelSeconds);
    end

    if any(vars == "familiarBurstRatePerMinute_recomputed")
        T.familiarBurstRatePerMinute = double(Traw.familiarBurstRatePerMinute_recomputed);
    elseif any(vars == "familiarBurstRatePerMinute")
        T.familiarBurstRatePerMinute = double(Traw.familiarBurstRatePerMinute);
    else
        T.familiarBurstRatePerMinute = safeRate(T.familiarBurstCount, T.familiarSeconds);
    end

    if any(vars == "novelMinusFamiliarRate_recomputed")
        T.novelMinusFamiliarRate = double(Traw.novelMinusFamiliarRate_recomputed);
    elseif any(vars == "novelMinusFamiliarRate")
        T.novelMinusFamiliarRate = double(Traw.novelMinusFamiliarRate);
    else
        T.novelMinusFamiliarRate = T.novelBurstRatePerMinute - T.familiarBurstRatePerMinute;
    end

    % Rate ratio can be useful descriptively, but keep it separate from the
    % main additive statistics.
    T.novelOverFamiliarRateRatio = safeRatio(T.novelBurstRatePerMinute, T.familiarBurstRatePerMinute);
end

function S = standardiseSpeedTable(Sraw, sourceFile)
    vars = string(Sraw.Properties.VariableNames);
    required = ["animal","resSaveIndex","subepoch","category"];
    for i = 1:numel(required)
        if ~any(vars == required(i))
            error('Missing required speed column %s in %s', required(i), sourceFile);
        end
    end
    S = table();
    S.animal = string(Sraw.animal);
    S.resSaveIndex = double(Sraw.resSaveIndex);
    S.subepoch = double(Sraw.subepoch);
    S.category = lower(string(Sraw.category));

    if any(vars == "meanMovingSpeedCmS")
        S.meanMovingSpeedCmS = double(Sraw.meanMovingSpeedCmS);
    elseif any(vars == "pooledMeanMovingSpeedCmS")
        S.meanMovingSpeedCmS = double(Sraw.pooledMeanMovingSpeedCmS);
    else
        error('Could not find meanMovingSpeedCmS or pooledMeanMovingSpeedCmS in %s', sourceFile);
    end

    if any(vars == "validMovingSeconds")
        S.validMovingSeconds = double(Sraw.validMovingSeconds);
    elseif any(vars == "pooledValidMovingSeconds")
        S.validMovingSeconds = double(Sraw.pooledValidMovingSeconds);
    else
        S.validMovingSeconds = NaN(height(S),1);
    end
end

function T = addSpeedToSubepochRows(T, S)
    T.novelMeanMovingSpeedCmS = NaN(height(T),1);
    T.familiarMeanMovingSpeedCmS = NaN(height(T),1);
    T.novelMinusFamiliarSpeedCmS = NaN(height(T),1);
    for i = 1:height(T)
        base = S.animal == T.animal(i) & S.resSaveIndex == T.resSaveIndex(i) & S.subepoch == T.subepoch(i);
        novelIdx = base & S.category == "novel";
        familiarIdx = base & S.category == "familiar";
        if any(novelIdx)
            T.novelMeanMovingSpeedCmS(i) = S.meanMovingSpeedCmS(find(novelIdx,1,'first'));
        end
        if any(familiarIdx)
            T.familiarMeanMovingSpeedCmS(i) = S.meanMovingSpeedCmS(find(familiarIdx,1,'first'));
        end
        T.novelMinusFamiliarSpeedCmS(i) = T.novelMeanMovingSpeedCmS(i) - T.familiarMeanMovingSpeedCmS(i);
    end
end

function P = poolSubepochsPerAnimal(T)
    animals = unique(T.animal, 'stable');
    bands = unique(T.band, 'stable');
    P = table();
    for a = 1:numel(animals)
        animalName = animals(a);
        for b = 1:numel(bands)
            bandName = bands(b);
            idx = T.animal == animalName & T.band == bandName;
            Tb = T(idx, :);
            if isempty(Tb); continue; end
            novelSeconds = sum(Tb.novelSeconds, 'omitnan');
            familiarSeconds = sum(Tb.familiarSeconds, 'omitnan');
            novelCount = sum(Tb.novelBurstCount, 'omitnan');
            familiarCount = sum(Tb.familiarBurstCount, 'omitnan');
            novelRate = safeRate(novelCount, novelSeconds);
            familiarRate = safeRate(familiarCount, familiarSeconds);
            speedNovel = weightedMean(Tb.novelMeanMovingSpeedCmS, Tb.novelSeconds);
            speedFamiliar = weightedMean(Tb.familiarMeanMovingSpeedCmS, Tb.familiarSeconds);
            rIndex = Tb.resSaveIndex(1);
            row = table(animalName, rIndex, bandName, novelSeconds, familiarSeconds, novelCount, familiarCount, ...
                novelRate, familiarRate, novelRate - familiarRate, safeRatio(novelRate, familiarRate), ...
                speedNovel, speedFamiliar, speedNovel - speedFamiliar, ...
                'VariableNames', {'animal','resSaveIndex','band','novelSeconds','familiarSeconds', ...
                'novelBurstCount','familiarBurstCount','novelBurstRatePerMinute', ...
                'familiarBurstRatePerMinute','novelMinusFamiliarRate', ...
                'novelOverFamiliarRateRatio','novelMeanMovingSpeedCmS', ...
                'familiarMeanMovingSpeedCmS','novelMinusFamiliarSpeedCmS'});
            P = [P; row]; %#ok<AGROW>
        end
    end
end

function row = exactStatsRow(diffs, bandName, comparison, subepoch, meanFamiliar, meanNovel)
    diffs = diffs(isfinite(diffs));
    [pTwo, nNonZero, nPositive, nNegative, nZero] = exactSignFlipTwoSided(diffs);
    minPossibleP = NaN;
    if nNonZero > 0
        minPossibleP = 2 / (2^nNonZero);
        if minPossibleP > 1; minPossibleP = 1; end
    end
    row = table(string(bandName), string(comparison), subepoch, numel(diffs), nNonZero, nPositive, nNegative, nZero, ...
        meanFamiliar, meanNovel, mean(diffs, 'omitnan'), median(diffs, 'omitnan'), sem(diffs), pTwo, minPossibleP, ...
        'VariableNames', {'band','comparison','subepoch','nAnimals','nNonZeroDiffs', ...
        'novelHigher','familiarHigher','zeroDiffs','meanFamiliarRate', 'meanNovelRate', ...
        'meanNovelMinusFamiliar','medianNovelMinusFamiliar','semNovelMinusFamiliar', ...
        'pTwoSidedExactSignFlip','minimumPossibleTwoSidedP'});
end

function [pTwo, nNonZero, nPositive, nNegative, nZero] = exactSignFlipTwoSided(diffs)
    diffs = diffs(isfinite(diffs));
    nPositive = sum(diffs > 0);
    nNegative = sum(diffs < 0);
    nZero = sum(diffs == 0);
    nNonZero = nPositive + nNegative;
    if nNonZero == 0
        pTwo = NaN;
        return;
    end
    extreme = max(nPositive, nNegative);
    % Two-sided exact binomial sign test probability of at least this many
    % signs in either direction under p = 0.5.
    tailCount = 0;
    for k = extreme:nNonZero
        tailCount = tailCount + nchoosek(nNonZero, k);
    end
    pTwo = min(1, 2 * tailCount / (2^nNonZero));
end

function bootMeans = bootstrapMeanByAnimal(diffs, nBootstrap)
    diffs = diffs(isfinite(diffs));
    n = numel(diffs);
    bootMeans = NaN(nBootstrap, 1);
    if n == 0; return; end
    for r = 1:nBootstrap
        idx = randi(n, n, 1);
        bootMeans(r) = mean(diffs(idx), 'omitnan');
    end
end

function [obsMeanDiff, nullMeanDiffs] = occupancyPreservingPermutation(Tb, nPermutations)
    % Observed statistic: pool subepochs 2-4 within each animal, calculate
    % each animal's novel-minus-familiar rate, then average across animals.
    Pobs = poolSubepochsPerAnimal(Tb);
    obsMeanDiff = mean(Pobs.novelMinusFamiliarRate, 'omitnan');
    animals = unique(Tb.animal, 'stable');
    nullMeanDiffs = NaN(nPermutations, 1);

    for p = 1:nPermutations
        Tsim = Tb;
        for r = 1:height(Tsim)
            totalCount = round(Tsim.novelBurstCount(r) + Tsim.familiarBurstCount(r));
            totalSeconds = Tsim.novelSeconds(r) + Tsim.familiarSeconds(r);
            if totalCount < 0 || totalSeconds <= 0 || ~isfinite(totalSeconds)
                Tsim.novelBurstCount(r) = NaN;
                Tsim.familiarBurstCount(r) = NaN;
                continue;
            end
            probNovel = Tsim.novelSeconds(r) / totalSeconds;
            probNovel = max(0, min(1, probNovel));
            simNovel = drawBinomial(totalCount, probNovel);
            Tsim.novelBurstCount(r) = simNovel;
            Tsim.familiarBurstCount(r) = totalCount - simNovel;
            Tsim.novelBurstRatePerMinute(r) = safeRate(Tsim.novelBurstCount(r), Tsim.novelSeconds(r));
            Tsim.familiarBurstRatePerMinute(r) = safeRate(Tsim.familiarBurstCount(r), Tsim.familiarSeconds(r));
            Tsim.novelMinusFamiliarRate(r) = Tsim.novelBurstRatePerMinute(r) - Tsim.familiarBurstRatePerMinute(r);
        end
        Psim = poolSubepochsPerAnimal(Tsim);
        if numel(unique(Psim.animal)) ~= numel(animals)
            % This should not normally happen, but keep the null robust.
            nullMeanDiffs(p) = mean(Psim.novelMinusFamiliarRate, 'omitnan');
        else
            nullMeanDiffs(p) = mean(Psim.novelMinusFamiliarRate, 'omitnan');
        end
    end
end

function k = drawBinomial(n, p)
    if n <= 0
        k = 0;
        return;
    end
    % Use binornd if available; otherwise use a simple toolbox-free fallback.
    if exist('binornd', 'file') == 2
        k = binornd(n, p);
    else
        k = sum(rand(n, 1) < p);
    end
end

function M = buildModelReadyLongTable(T)
    M = table();
    for i = 1:height(T)
        for c = 1:2
            if c == 1
                category = "familiar";
                novelty = 0;
                burstCount = T.familiarBurstCount(i);
                validSeconds = T.familiarSeconds(i);
                rate = T.familiarBurstRatePerMinute(i);
                speed = T.familiarMeanMovingSpeedCmS(i);
            else
                category = "novel";
                novelty = 1;
                burstCount = T.novelBurstCount(i);
                validSeconds = T.novelSeconds(i);
                rate = T.novelBurstRatePerMinute(i);
                speed = T.novelMeanMovingSpeedCmS(i);
            end
            validMovingMinutes = validSeconds / 60;
            if validMovingMinutes > 0
                logExposureMinutes = log(validMovingMinutes);
            else
                logExposureMinutes = NaN;
            end
            row = table(T.animal(i), T.resSaveIndex(i), T.band(i), T.subepoch(i), category, novelty, ...
                burstCount, validSeconds, validMovingMinutes, logExposureMinutes, rate, speed, ...
                'VariableNames', {'animal','resSaveIndex','band','subepoch','category','novelty', ...
                'burstCount','validMovingSeconds','validMovingMinutes','logExposureMinutes', ...
                'burstRatePerMinute','meanMovingSpeedCmS'});
            M = [M; row]; %#ok<AGROW>
        end
    end
end

function row = speedAdjustedSensitivity(Tb, bandName, nBootstrap)
    % Simple sensitivity analysis on paired subepoch differences:
    %   novel-minus-familiar burst rate ~ novel-minus-familiar speed
    % This is not the main inference and does not replace a mixed model.
    ok = isfinite(Tb.novelMinusFamiliarRate) & isfinite(Tb.novelMinusFamiliarSpeedCmS);
    D = Tb(ok, :);
    if height(D) < 4
        row = table(string(bandName), height(D), NaN, NaN, NaN, NaN, NaN, NaN, ...
            'VariableNames', {'band','nRows','unadjustedMeanDiff','speedAdjustedIntercept', ...
            'speedCoefficient','bootstrapCI_low_2_5','bootstrapMedian','bootstrapCI_high_97_5'});
        return;
    end
    y = D.novelMinusFamiliarRate;
    xSpeed = D.novelMinusFamiliarSpeedCmS;
    xSpeed = xSpeed - mean(xSpeed, 'omitnan');
    X = [ones(height(D),1), xSpeed];
    b = X \ y;
    unadjustedMean = mean(y, 'omitnan');

    animals = unique(D.animal, 'stable');
    bootB0 = NaN(nBootstrap,1);
    for r = 1:nBootstrap
        sampleAnimals = animals(randi(numel(animals), numel(animals), 1));
        Db = table();
        for a = 1:numel(sampleAnimals)
            Db = [Db; D(D.animal == sampleAnimals(a), :)]; %#ok<AGROW>
        end
        yb = Db.novelMinusFamiliarRate;
        xb = Db.novelMinusFamiliarSpeedCmS;
        xb = xb - mean(xb, 'omitnan');
        Xb = [ones(height(Db),1), xb];
        bb = Xb \ yb;
        bootB0(r) = bb(1);
    end
    ci = prctile(bootB0, [2.5 50 97.5]);
    row = table(string(bandName), height(D), unadjustedMean, b(1), b(2), ci(1), ci(2), ci(3), ...
        'VariableNames', {'band','nRows','unadjustedMeanDiff','speedAdjustedIntercept', ...
        'speedCoefficient','bootstrapCI_low_2_5','bootstrapMedian','bootstrapCI_high_97_5'});
end

function plotBootstrapDistribution(bootMeans, obsMean, ci, bandName, figDir)
    figure('Color','w','Position',[100 100 900 520]);
    histogram(bootMeans, 30, 'FaceAlpha', 0.70, 'EdgeColor','none');
    hold on;
    xline(0, '--k', 'Zero', 'LabelVerticalAlignment','bottom');
    xline(obsMean, '-r', 'Observed mean', 'LineWidth', 1.5, 'LabelVerticalAlignment','bottom');
    xline(ci(1), ':r', '2.5% CI', 'LineWidth', 1.2);
    xline(ci(3), ':r', '97.5% CI', 'LineWidth', 1.2);
    xlabel('Bootstrap mean novel-minus-familiar rate (bursts/min)');
    ylabel('Bootstrap resamples');
    title(sprintf('%s bootstrap CI for pooled subepochs 2-4', char(bandName)), 'Interpreter','none');
    grid on; box off;
    saveFigure(gcf, fullfile(figDir, sprintf('batch4_%s_bootstrap_pooled_difference.png', safeFileName(bandName))));
    close(gcf);
end

function plotPermutationNull(nullMeanDiffs, obsMeanDiff, nullCI, bandName, figDir)
    figure('Color','w','Position',[100 100 900 520]);
    histogram(nullMeanDiffs, 35, 'FaceAlpha', 0.70, 'EdgeColor','none');
    hold on;
    xline(0, '--k', 'Null mean target', 'LabelVerticalAlignment','bottom');
    xline(obsMeanDiff, '-r', 'Observed mean', 'LineWidth', 1.5, 'LabelVerticalAlignment','bottom');
    xline(nullCI(1), ':k', 'Null 2.5%', 'LineWidth', 1.2);
    xline(nullCI(3), ':k', 'Null 97.5%', 'LineWidth', 1.2);
    xlabel('Null mean novel-minus-familiar rate (bursts/min)');
    ylabel('Permutation simulations');
    title(sprintf('%s occupancy-preserving null distribution', char(bandName)), 'Interpreter','none');
    grid on; box off;
    saveFigure(gcf, fullfile(figDir, sprintf('batch4_%s_permutation_null_pooled_difference.png', safeFileName(bandName))));
    close(gcf);
end

function plotEffectSummary(bootstrapStats, permStats, figDir)
    if isempty(bootstrapStats); return; end
    bands = bootstrapStats.band;
    means = bootstrapStats.observedMeanDiff;
    lo = bootstrapStats.bootstrapCI_low_2_5;
    hi = bootstrapStats.bootstrapCI_high_97_5;
    x = 1:numel(bands);
    figure('Color','w','Position',[100 100 850 520]);
    bar(x, means, 'FaceAlpha', 0.75); hold on;
    errorbar(x, means, means-lo, hi-means, 'k', 'LineStyle','none', 'LineWidth',1.3);
    yline(0, '--k');
    set(gca, 'XTick', x, 'XTickLabel', cellstr(bands));
    ylabel('Mean novel-minus-familiar rate (bursts/min)');
    title('Batch 4 pooled novelty effect summary with bootstrap CIs');
    grid on; box off;

    % Add permutation p-values under labels if available.
    if ~isempty(permStats)
        yl = ylim;
        yText = yl(1) + 0.05 * range(yl);
        for i = 1:numel(bands)
            idx = find(permStats.band == bands(i), 1, 'first');
            if ~isempty(idx)
                text(x(i), yText, sprintf('perm p=%.3f', permStats.pTwoSidedOccupancyPermutation(idx)), ...
                    'HorizontalAlignment','center','FontSize',9);
            end
        end
    end
    saveFigure(gcf, fullfile(figDir, 'batch4_pooled_effect_summary.png'));
    close(gcf);
end

function plotSpeedSensitivity(Tb, bandName, figDir)
    ok = isfinite(Tb.novelMinusFamiliarRate) & isfinite(Tb.novelMinusFamiliarSpeedCmS);
    D = Tb(ok, :);
    if height(D) < 2; return; end
    figure('Color','w','Position',[100 100 800 520]);
    scatter(D.novelMinusFamiliarSpeedCmS, D.novelMinusFamiliarRate, 80, D.subepoch, 'filled');
    hold on;
    yline(0, '--k'); xline(0, ':k');
    if height(D) >= 4
        x = D.novelMinusFamiliarSpeedCmS;
        y = D.novelMinusFamiliarRate;
        p = polyfit(x, y, 1);
        xx = linspace(min(x), max(x), 100);
        yy = polyval(p, xx);
        plot(xx, yy, '-k', 'LineWidth', 1.3);
    end
    xlabel('Novel-minus-familiar mean moving speed (cm/s)');
    ylabel('Novel-minus-familiar burst rate (bursts/min)');
    title(sprintf('%s speed-difference sensitivity', char(bandName)), 'Interpreter','none');
    cb = colorbar; ylabel(cb, 'Subepoch');
    grid on; box off;
    saveFigure(gcf, fullfile(figDir, sprintf('batch4_%s_speed_difference_sensitivity.png', safeFileName(bandName))));
    close(gcf);
end

function writeSummaryNotes(notesFile, subepochInputFile, speedInputFile, hasSpeedFile, eligibleSubepochs, exactStats, bootstrapStats, permStats, speedStats, nBootstrap, nPermutations)
    fid = fopen(notesFile, 'w');
    if fid < 0; warning('Could not write notes file: %s', notesFile); return; end
    fprintf(fid, 'HC-31 Batch 4: improved novelty statistics\n');
    fprintf(fid, 'Subepoch input: %s\n', subepochInputFile);
    if hasSpeedFile
        fprintf(fid, 'Speed input: %s\n', speedInputFile);
    else
        fprintf(fid, 'Speed input: not found; speed-adjusted sensitivity skipped.\n');
    end
    fprintf(fid, 'Eligible subepochs: %s\n', mat2str(eligibleSubepochs));
    fprintf(fid, 'Bootstrap resamples: %d\n', nBootstrap);
    fprintf(fid, 'Occupancy-preserving permutation simulations: %d\n\n', nPermutations);

    fprintf(fid, 'What was tested:\n');
    fprintf(fid, ['This batch focuses on whether novel-section burst rates are higher than familiar-section ', ...
        'burst rates after pooling subepochs 2-4 per animal. It also provides within-subepoch exact ', ...
        'sign-flip tests, bootstrap confidence intervals, an occupancy-preserving count permutation, ', ...
        'and a model-ready long table for later GLMM analysis.\n\n']);

    fprintf(fid, 'Exact sign-flip summary:\n');
    for i = 1:height(exactStats)
        if exactStats.comparison(i) == "pooled_subepochs_2_4"
            fprintf(fid, '%s pooled 2-4: mean diff %.4f bursts/min, novel higher %d/%d nonzero, p=%.4f, minimum possible two-sided p=%.4f\n', ...
                char(exactStats.band(i)), exactStats.meanNovelMinusFamiliar(i), exactStats.novelHigher(i), ...
                exactStats.nNonZeroDiffs(i), exactStats.pTwoSidedExactSignFlip(i), exactStats.minimumPossibleTwoSidedP(i));
        end
    end
    fprintf(fid, '\nBootstrap CI summary:\n');
    for i = 1:height(bootstrapStats)
        fprintf(fid, '%s: observed mean diff %.4f, 95%% bootstrap CI [%.4f, %.4f]\n', ...
            char(bootstrapStats.band(i)), bootstrapStats.observedMeanDiff(i), ...
            bootstrapStats.bootstrapCI_low_2_5(i), bootstrapStats.bootstrapCI_high_97_5(i));
    end
    fprintf(fid, '\nOccupancy-preserving permutation summary:\n');
    for i = 1:height(permStats)
        fprintf(fid, '%s: observed mean diff %.4f, two-sided occupancy-permutation p=%.4f, one-sided novel-greater p=%.4f\n', ...
            char(permStats.band(i)), permStats.observedMeanNovelMinusFamiliar(i), ...
            permStats.pTwoSidedOccupancyPermutation(i), permStats.pOneSidedNovelGreater(i));
    end
    if hasSpeedFile && ~isempty(speedStats)
        fprintf(fid, '\nSpeed-adjusted sensitivity summary:\n');
        for i = 1:height(speedStats)
            fprintf(fid, '%s: unadjusted mean diff %.4f, speed-adjusted intercept %.4f, speed coefficient %.4f, bootstrap CI [%.4f, %.4f]\n', ...
                char(speedStats.band(i)), speedStats.unadjustedMeanDiff(i), speedStats.speedAdjustedIntercept(i), ...
                speedStats.speedCoefficient(i), speedStats.bootstrapCI_low_2_5(i), speedStats.bootstrapCI_high_97_5(i));
        end
    end
    fprintf(fid, '\nImportant interpretation notes:\n');
    fprintf(fid, ['1) The exact sign-flip tests are conservative and use animals as the independent unit. ', ...
        'With five nonzero paired differences, the smallest possible two-sided p-value is 0.0625.\n']);
    fprintf(fid, ['2) The occupancy-preserving permutation does not prove causality. It asks whether the observed ', ...
        'novel-minus-familiar rate difference is larger than expected if bursts were allocated across novel ', ...
        'and familiar categories in proportion to valid moving time.\n']);
    fprintf(fid, ['3) The model-ready long table is prepared for a later mixed-effects count model. A possible R formula is: ', ...
        'burstCount ~ novelty + subepoch + meanMovingSpeedCmS + offset(log(validMovingMinutes)) + (1|animal).\n']);
    fclose(fid);
end

function r = safeRate(counts, seconds)
    r = counts ./ seconds .* 60;
    r(~isfinite(r) | seconds <= 0) = NaN;
end

function r = safeRatio(a, b)
    r = a ./ b;
    r(~isfinite(r) | b == 0) = NaN;
end

function m = weightedMean(values, weights)
    values = double(values); weights = double(weights);
    ok = isfinite(values) & isfinite(weights) & weights > 0;
    if ~any(ok)
        m = NaN;
    else
        m = sum(values(ok) .* weights(ok)) ./ sum(weights(ok));
    end
end

function s = sem(x)
    x = x(isfinite(x));
    if numel(x) <= 1
        s = NaN;
    else
        s = std(x, 0, 'omitnan') ./ sqrt(numel(x));
    end
end

function name = safeFileName(x)
    name = char(string(x));
    name = regexprep(name, '[^A-Za-z0-9_\-]', '_');
end

function name = safeFieldName(x)
    name = safeFileName(x);
    if isempty(name) || ~isletter(name(1))
        name = ['x_' name];
    end
end

function saveFigure(fig, outPath)
    try
        exportgraphics(fig, outPath, 'Resolution', 220);
    catch
        saveas(fig, outPath);
    end
end
