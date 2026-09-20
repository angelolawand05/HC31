%% HC-31 updated Batch 4 statistics and clear significance plots
% Force-runner script.
%
% Purpose:
%   Replace the unclear original Batch 4 permutation-style figures with
%   direct animal-level statistical plots similar to bstats/bstats_sig, but
%   using the cleaned broad beta band beta_13_30Hz and the updated
%   novel/familiar outputs.
%
% Main outputs:
%   - overall beta2 versus broad beta paired animal-level test
%   - novel versus familiar paired tests for each band
%   - beta2 versus broad beta within novel and within familiar conditions
%   - subepoch novel versus familiar tests and plots
%   - first-half versus second-half tests
%   - burst-rate slope versus zero tests
%   - optional speed-control plots and speed-correlation tests if those CSVs exist
%   - optional peak-z and duration novel/familiar tests from burst table
%
% Important:
%   Main tests use animal-level paired values. The 60-s bins are not treated
%   as independent animals.

clear; clc; close all;
runnerDir = fileparts(mfilename('fullpath'));
if ~isempty(runnerDir); addpath(runnerDir, '-begin'); end

%% ---------------- Settings ----------------
projectRoot = 'C:\Users\angel\Documents\MATLAB\CRCN';
if exist(projectRoot, 'dir') ~= 7
    error('Could not find project root: %s', projectRoot);
end
cd(projectRoot);

outDir = fullfile(projectRoot, 'hc31_batch4_UPDATED_STATS');
figDir = fullfile(outDir, 'figures');
if exist(outDir, 'dir') ~= 7; mkdir(outDir); end
if exist(figDir, 'dir') ~= 7; mkdir(figDir); end

bandsWanted = ["beta_13_30Hz"; "beta2_23_30Hz"];
broadBand = "beta_13_30Hz";
beta2Band = "beta2_23_30Hz";

fprintf('\nHC-31 updated Batch 4 statistics\n');
fprintf('Project root: %s\n', projectRoot);
fprintf('Output folder: %s\n\n', outDir);

%% ---------------- Locate inputs ----------------
overTimeCsv = locate_first_file(projectRoot, { ...
    fullfile('allresults','beta_burst_over_time_outputs_BETA13_30_FUNC','hc31_beta_burst_frequency_over_time.csv'), ...
    fullfile('beta_burst_over_time_outputs_BETA13_30_FUNC','hc31_beta_burst_frequency_over_time.csv'), ...
    'hc31_beta_burst_frequency_over_time.csv'});

nfAnimalCsv = locate_first_file(projectRoot, { ...
    fullfile('allresults','beta_burst_novel_familiar_outputs_BETA13_30','hc31_novel_familiar_animal_summary.csv'), ...
    fullfile('beta_burst_novel_familiar_outputs_BETA13_30','hc31_novel_familiar_animal_summary.csv'), ...
    'hc31_novel_familiar_animal_summary.csv'});

nfSubepochCsv = locate_first_file(projectRoot, { ...
    fullfile('allresults','beta_burst_novel_familiar_outputs_BETA13_30','hc31_novel_familiar_subepoch_summary.csv'), ...
    fullfile('beta_burst_novel_familiar_outputs_BETA13_30','hc31_novel_familiar_subepoch_summary.csv'), ...
    'hc31_novel_familiar_subepoch_summary.csv'});

nfBurstCsv = locate_first_file(projectRoot, { ...
    fullfile('allresults','beta_burst_novel_familiar_outputs_BETA13_30','hc31_novel_familiar_burst_table.csv'), ...
    fullfile('beta_burst_novel_familiar_outputs_BETA13_30','hc31_novel_familiar_burst_table.csv'), ...
    'hc31_novel_familiar_burst_table.csv'});

speedAnimalCsv = locate_first_file(projectRoot, { ...
    fullfile('allresults','speed_movement_correlation_outputs','hc31_speed_novel_familiar_animal_summary.csv'), ...
    fullfile('speed_movement_correlation_outputs','hc31_speed_novel_familiar_animal_summary.csv'), ...
    'hc31_speed_novel_familiar_animal_summary.csv'});

speedSubepochCsv = locate_first_file(projectRoot, { ...
    fullfile('allresults','speed_movement_correlation_outputs','hc31_speed_novel_familiar_subepoch_summary.csv'), ...
    fullfile('speed_movement_correlation_outputs','hc31_speed_novel_familiar_subepoch_summary.csv'), ...
    'hc31_speed_novel_familiar_subepoch_summary.csv'});

speedCorrCsv = locate_first_file(projectRoot, { ...
    fullfile('allresults','speed_movement_correlation_outputs','hc31_burst_rate_speed_correlation_by_animal.csv'), ...
    fullfile('speed_movement_correlation_outputs','hc31_burst_rate_speed_correlation_by_animal.csv'), ...
    'hc31_burst_rate_speed_correlation_by_animal.csv'});

if isempty(overTimeCsv) || exist(overTimeCsv, 'file') ~= 2
    error('Could not find hc31_beta_burst_frequency_over_time.csv.');
end
if isempty(nfAnimalCsv) || exist(nfAnimalCsv, 'file') ~= 2
    error('Could not find hc31_novel_familiar_animal_summary.csv.');
end
if isempty(nfSubepochCsv) || exist(nfSubepochCsv, 'file') ~= 2
    error('Could not find hc31_novel_familiar_subepoch_summary.csv.');
end

fprintf('Using over-time table:\n%s\n\n', overTimeCsv);
fprintf('Using novel/familiar animal table:\n%s\n\n', nfAnimalCsv);
fprintf('Using novel/familiar subepoch table:\n%s\n\n', nfSubepochCsv);
if ~isempty(nfBurstCsv); fprintf('Using burst table for peak-z/duration metrics:\n%s\n\n', nfBurstCsv); end
if ~isempty(speedAnimalCsv); fprintf('Using speed animal table:\n%s\n\n', speedAnimalCsv); end
if ~isempty(speedCorrCsv); fprintf('Using speed correlation table:\n%s\n\n', speedCorrCsv); end

%% ---------------- Read and standardise core tables ----------------
T = readtable(overTimeCsv);
T.animal = string(T.animal);
T.band = normalise_band_labels(string(T.band));
T = T(ismember(T.band, bandsWanted), :);

NF = readtable(nfAnimalCsv);
NF.animal = string(NF.animal);
NF.band = normalise_band_labels(string(NF.band));
NF = NF(ismember(NF.band, bandsWanted), :);

NFS = readtable(nfSubepochCsv);
NFS.animal = string(NFS.animal);
NFS.band = normalise_band_labels(string(NFS.band));
NFS = NFS(ismember(NFS.band, bandsWanted), :);

S = compute_over_time_animal_summary(T, bandsWanted);
writetable(S, fullfile(outDir, 'hc31_batch4_updated_over_time_animal_summary.csv'));
writetable(NF, fullfile(outDir, 'hc31_batch4_updated_novel_familiar_animal_summary.csv'));
writetable(NFS, fullfile(outDir, 'hc31_batch4_updated_novel_familiar_subepoch_summary.csv'));

%% ---------------- Main statistics ----------------
statsRows = {};
statsVars = {'testName','metric','band','subgroup','comparison','nPaired','nNonZeroDifferences', ...
    'meanA','meanB','meanDifference','medianDifference','nPositive','nNegative','exactSignFlipP'};

% A) Overall beta2 vs broad beta.
[animalsPair, betaRate, beta2Rate] = paired_values_by_band(S, 'overallBurstRatePerMinute', broadBand, beta2Band);
[row, pBand] = make_stat_row('overall_band_comparison', 'burst_rate_per_min', 'beta2_minus_beta', ...
    'overall', 'beta2_23_30Hz minus beta_13_30Hz', betaRate, beta2Rate);
statsRows(end+1,:) = row; %#ok<SAGROW>
make_paired_sig_plot(betaRate, beta2Rate, animalsPair, {'beta 13-30 Hz','beta2 23-30 Hz'}, ...
    'Burst frequency (bursts/min)', 'Overall burst frequency: beta2 vs broad beta', ...
    fullfile(figDir, 'batch4_stats_overall_beta2_vs_broad_beta'), pBand);

% B) Novel vs familiar for each band.
for b = 1:numel(bandsWanted)
    band = bandsWanted(b);
    [animalsPair, famRate, novRate] = paired_values_novel_familiar(NF, band, ...
        'familiarBurstRatePerMinute', 'novelBurstRatePerMinute');
    [row, pNF] = make_stat_row('novel_vs_familiar', 'burst_rate_per_min', char(band), ...
        'overall', 'novel minus familiar', famRate, novRate);
    statsRows(end+1,:) = row; %#ok<SAGROW>
    make_paired_sig_plot(famRate, novRate, animalsPair, {'Familiar','Novel'}, ...
        'Burst frequency (bursts/min)', sprintf('%s: novel vs familiar burst frequency', band), ...
        fullfile(figDir, ['batch4_stats_' char(band) '_novel_vs_familiar']), pNF);
end
make_two_panel_novel_familiar_plot(NF, bandsWanted, fullfile(figDir, 'batch4_stats_novel_vs_familiar_by_band'));

% C) Beta2 vs broad beta within novel and familiar.
categories = {'novel','familiar'};
rateFields = {'novelBurstRatePerMinute','familiarBurstRatePerMinute'};
for ci = 1:numel(categories)
    catName = categories{ci};
    rateField = rateFields{ci};
    [animalsPair, betaVals, beta2Vals] = paired_values_by_band(NF, rateField, broadBand, beta2Band);
    [row, pCat] = make_stat_row('band_comparison_within_category', 'burst_rate_per_min', ...
        'beta2_minus_beta', catName, ['beta2 minus beta within ' catName], betaVals, beta2Vals);
    statsRows(end+1,:) = row; %#ok<SAGROW>
    make_paired_sig_plot(betaVals, beta2Vals, animalsPair, {'beta 13-30 Hz','beta2 23-30 Hz'}, ...
        'Burst frequency (bursts/min)', sprintf('Band comparison within %s windows', catName), ...
        fullfile(figDir, ['batch4_stats_beta2_vs_beta_within_' catName]), pCat);
end

% D) Subepoch novel vs familiar, per band and subepoch.
subepochs = unique(NFS.subepoch);
subepochs = subepochs(isfinite(subepochs));
for b = 1:numel(bandsWanted)
    band = bandsWanted(b);
    for si = 1:numel(subepochs)
        se = subepochs(si);
        X = NFS(NFS.band == band & NFS.subepoch == se, :);
        [animalsPair, famRate, novRate] = paired_values_novel_familiar(X, band, ...
            'familiarBurstRatePerMinute', 'novelBurstRatePerMinute');
        if isempty(famRate), continue; end
        [row, ~] = make_stat_row('subepoch_novel_vs_familiar', 'burst_rate_per_min', char(band), ...
            sprintf('subepoch_%d', se), 'novel minus familiar', famRate, novRate);
        statsRows(end+1,:) = row; %#ok<SAGROW>
    end
end
make_subepoch_grid_plot(NFS, bandsWanted, fullfile(figDir, 'batch4_stats_subepoch_novel_vs_familiar_grid'));
make_subepoch_difference_trend_plot(NFS, bandsWanted, fullfile(figDir, 'batch4_stats_subepoch_novel_minus_familiar_trend'));

% E) First half vs second half for each band.
for b = 1:numel(bandsWanted)
    band = bandsWanted(b);
    X = S(S.band == band, :);
    firstVals = X.firstHalfRatePerMinute;
    secondVals = X.secondHalfRatePerMinute;
    animalsPair = X.animal;
    [row, pHalf] = make_stat_row('second_half_vs_first_half', 'burst_rate_per_min', char(band), ...
        'Run1_halves', 'second half minus first half', firstVals, secondVals);
    statsRows(end+1,:) = row; %#ok<SAGROW>
    make_paired_sig_plot(firstVals, secondVals, animalsPair, {'First half','Second half'}, ...
        'Burst frequency (bursts/min)', sprintf('%s: first vs second half of Run1', band), ...
        fullfile(figDir, ['batch4_stats_' char(band) '_first_vs_second_half']), pHalf);
end
make_first_second_panel_plot(S, bandsWanted, fullfile(figDir, 'batch4_stats_first_vs_second_half_by_band'));

% F) Slope vs zero for each band.
for b = 1:numel(bandsWanted)
    band = bandsWanted(b);
    X = S(S.band == band, :);
    zeroVals = zeros(height(X), 1);
    slopeVals = X.slopeBurstRatePerMinutePerMinute;
    [row, ~] = make_stat_row('slope_vs_zero', 'burst_rate_slope', char(band), ...
        'Run1_time', 'slope minus zero', zeroVals, slopeVals);
    statsRows(end+1,:) = row; %#ok<SAGROW>
end
make_slope_plot(S, bandsWanted, fullfile(figDir, 'batch4_stats_burst_rate_slope_vs_zero'));

%% ---------------- Optional event-metric stats from burst table ----------------
if ~isempty(nfBurstCsv) && exist(nfBurstCsv, 'file') == 2
    BT = readtable(nfBurstCsv);
    BT.animal = string(BT.animal);
    BT.band = normalise_band_labels(string(BT.band));
    if ismember('category', BT.Properties.VariableNames)
        BT.category = lower(string(BT.category));
    else
        BT.category = repmat("all", height(BT), 1);
    end
    if ismember('includedInNovelFamiliarAnalysis', BT.Properties.VariableNames)
        BT = BT(BT.includedInNovelFamiliarAnalysis == 1, :);
    end
    BT = BT(ismember(BT.band, bandsWanted), :);

    EventMetricSummary = make_event_metric_summary(BT);
    writetable(EventMetricSummary, fullfile(outDir, 'hc31_batch4_updated_event_metric_summary.csv'));

    for b = 1:numel(bandsWanted)
        band = bandsWanted(b);
        for metricName = ["medianPeakZ", "medianBurstDurationS"]
            X = EventMetricSummary(EventMetricSummary.band == band, :);
            animalsHere = unique(X.animal, 'stable');
            famVals = nan(numel(animalsHere),1);
            novVals = nan(numel(animalsHere),1);
            for a = 1:numel(animalsHere)
                famRow = X.animal == animalsHere(a) & X.category == "familiar";
                novRow = X.animal == animalsHere(a) & X.category == "novel";
                if any(famRow), famVals(a) = X.(metricName)(find(famRow,1)); end
                if any(novRow), novVals(a) = X.(metricName)(find(novRow,1)); end
            end
            [row, pMetric] = make_stat_row('event_metric_novel_vs_familiar', char(metricName), char(band), ...
                'overall', ['novel minus familiar ' char(metricName)], famVals, novVals);
            statsRows(end+1,:) = row; %#ok<SAGROW>

            if metricName == "medianPeakZ"
                yLabel = 'Median burst peak z';
                suffix = 'peakZ';
            else
                yLabel = 'Median burst duration (s)';
                suffix = 'duration';
            end
            make_paired_sig_plot(famVals, novVals, animalsHere, {'Familiar','Novel'}, yLabel, ...
                sprintf('%s: %s novel vs familiar', band, yLabel), ...
                fullfile(figDir, ['batch4_stats_' char(band) '_' suffix '_novel_vs_familiar']), pMetric);
        end
    end
end

%% ---------------- Optional speed-control stats ----------------
if ~isempty(speedAnimalCsv) && exist(speedAnimalCsv, 'file') == 2
    SP = readtable(speedAnimalCsv);
    SP.animal = string(SP.animal);
    writetable(SP, fullfile(outDir, 'hc31_batch4_updated_speed_novel_familiar_animal_summary.csv'));

    [row, pSpeed] = make_stat_row('speed_novel_vs_familiar', 'moving_speed_cm_s', 'speed', ...
        'overall', 'novel moving speed minus familiar moving speed', ...
        SP.familiarMeanSpeedMovingCmS, SP.novelMeanSpeedMovingCmS);
    statsRows(end+1,:) = row; %#ok<SAGROW>
    make_paired_sig_plot(SP.familiarMeanSpeedMovingCmS, SP.novelMeanSpeedMovingCmS, SP.animal, ...
        {'Familiar','Novel'}, 'Mean moving speed (cm/s)', ...
        'Movement speed control: novel vs familiar', ...
        fullfile(figDir, 'batch4_stats_speed_novel_vs_familiar'), pSpeed);
end

if ~isempty(speedSubepochCsv) && exist(speedSubepochCsv, 'file') == 2
    SPS = readtable(speedSubepochCsv);
    SPS.animal = string(SPS.animal);
    writetable(SPS, fullfile(outDir, 'hc31_batch4_updated_speed_novel_familiar_subepoch_summary.csv'));
    make_speed_subepoch_trend_plot(SPS, fullfile(figDir, 'batch4_stats_speed_subepoch_novel_minus_familiar_trend'));

    subepochsSpeed = unique(SPS.subepoch);
    subepochsSpeed = subepochsSpeed(isfinite(subepochsSpeed));
    for si = 1:numel(subepochsSpeed)
        se = subepochsSpeed(si);
        X = SPS(SPS.subepoch == se, :);
        [row, ~] = make_stat_row('speed_subepoch_novel_vs_familiar', 'moving_speed_cm_s', 'speed', ...
            sprintf('subepoch_%d', se), 'novel moving speed minus familiar moving speed', ...
            X.familiarMeanSpeedMovingCmS, X.novelMeanSpeedMovingCmS);
        statsRows(end+1,:) = row; %#ok<SAGROW>
    end
end

if ~isempty(speedCorrCsv) && exist(speedCorrCsv, 'file') == 2
    SC = readtable(speedCorrCsv);
    SC.animal = string(SC.animal);
    SC.band = normalise_band_labels(string(SC.band));
    SC = SC(ismember(SC.band, bandsWanted), :);
    writetable(SC, fullfile(outDir, 'hc31_batch4_updated_speed_burst_correlation_by_animal.csv'));

    for b = 1:numel(bandsWanted)
        band = bandsWanted(b);
        X = SC(SC.band == band, :);
        [row, ~] = make_stat_row('speed_burst_correlation_vs_zero', 'fisher_z_speed_burst_rate', char(band), ...
            'overall', 'Fisher z compared with zero', zeros(height(X),1), X.fisherZ);
        statsRows(end+1,:) = row; %#ok<SAGROW>
    end
    [animalsPair, betaZ, beta2Z] = paired_values_by_band(SC, 'fisherZ', broadBand, beta2Band);
    [row, pCorr] = make_stat_row('speed_correlation_band_comparison', 'fisher_z_speed_burst_rate', ...
        'beta2_minus_beta', 'overall', 'beta2 Fisher z minus beta Fisher z', betaZ, beta2Z);
    statsRows(end+1,:) = row; %#ok<SAGROW>
    make_paired_sig_plot(betaZ, beta2Z, animalsPair, {'beta 13-30 Hz','beta2 23-30 Hz'}, ...
        'Fisher z(speed vs burst rate)', 'Speed-burst correlation by band', ...
        fullfile(figDir, 'batch4_stats_speed_burst_correlation_beta2_vs_beta'), pCorr);
end

%% ---------------- Write final stats table and README ----------------
Stats = cell2table(statsRows, 'VariableNames', statsVars);
writetable(Stats, fullfile(outDir, 'hc31_batch4_updated_stats_summary.csv'));

write_batch4_updated_readme(outDir, overTimeCsv, nfAnimalCsv, nfSubepochCsv, nfBurstCsv, speedAnimalCsv, speedCorrCsv);

fprintf('\nSaved updated stats table:\n%s\n', fullfile(outDir, 'hc31_batch4_updated_stats_summary.csv'));
fprintf('Saved updated figures to:\n%s\n', figDir);
fprintf('Done.\n');
