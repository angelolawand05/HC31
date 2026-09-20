%% HC-31 spike/place-field linkage
% Standalone script.
%
% Purpose:
%   Start using the spike/place-field side of resSave, not only the LFP.
%   This batch asks whether units are more active during detected beta/beta2
%   bursts than during matched non-burst movement windows, and whether units
%   with novel/familiar place fields show different burst participation.
%
% Main questions:
%   1) Do CA1 units fire more during beta/beta2 burst windows than during
%      matched movement control windows?
%   2) During beta2 bursts, how many units are active at the ensemble level?
%   3) Are units with novel place fields more involved during novel beta2
%      bursts than units without novel fields?
%
% Required inputs:
%   - resSave.mat
%   - hc31_novel_familiar_burst_table.csv is preferred
%       OR hc31_detected_beta_bursts.csv as fallback
%
% Expected HC-31 fields:
%   - resSave(i).spAll(1).animal
%   - resSave(i).spEpochSep(unit,2).timeStamps   % Run1 spike times
%   - resSave(i).posMazeLin(1).data              % Run1 position/speed
%   - resSave(i).sectInt                         % Run1 subepoch time windows
%   - resSave(i).fieldInfoC{unit,subepoch}       % place-field info, optional
%
% Output folder:
%   hc31_batch8_spikes_placefield_linkage
%
% Notes:
%   - This is exploratory. It does not prove replay or plasticity.
%   - Controls are sampled from moving periods in the same subepoch and, when
%     possible, with similar movement speed.
%   - Statistics are summarised at animal level to avoid treating every unit
%     or every burst as fully independent.
clear; clc; close all;
runnerDir = fileparts(mfilename('fullpath'));
if ~isempty(runnerDir); addpath(runnerDir, '-begin'); end
%% ---------------- User settings ----------------
P = struct();
projectRoot = 'C:\Users\angel\Documents\MATLAB\CRCN';
if exist(projectRoot, 'dir') ~= 7
    error('Forced Batch 8 could not find project root: %s', projectRoot);
end
cd(projectRoot);
P.outDir = fullfile(projectRoot, 'hc31_batch8_spikes_placefield_linkage_FORCE');

% HC-31 analysed resSave entries.
P.analysedResSaveIdx = 5:9;

% Run1 is stored as epoch 2 in spEpochSep in the HC-31 example script.
% If this is wrong in a local copy, the script tries to fall back.
P.run1SpikeEpoch = 2;

% Valid movement threshold, matching the earlier LFP/burst analyses.
P.speedThresholdCmS = 5;

% Matched control sampling settings.
P.controlExcludeAroundBurstSec = 1.0;
P.speedToleranceCmS = 5.0;
P.speedToleranceFraction = 0.25;

% If a burst-duration column is missing, this default window is used.
P.defaultBurstWindowSec = 0.150;

% Main bands.
P.bandNames = {'beta_13_30Hz', 'beta2_23_30Hz'};

% Plot/export settings.
P.saveDpi = 220;
P.rngSeed = 8;

if ~exist(P.outDir, 'dir')
    mkdir(P.outDir);
end

rng(P.rngSeed);

fprintf('\nHC-31: spikes/place-field linkage FORCE runner\n');
fprintf('FORCED projectRoot: %s\n', projectRoot);
fprintf('Output folder: %s\n\n', P.outDir);

%% ---------------- Load resSave ----------------
resPath = fullfile(projectRoot, 'resSave.mat');
if exist(resPath, 'file') ~= 2
    resPath = find_first_file(projectRoot, 'resSave.mat');
end
if isempty(resPath) || exist(resPath, 'file') ~= 2
    error('Forced Batch 8 could not find resSave.mat under project root: %s', projectRoot);
end

S = load(resPath);
if ~isfield(S, 'resSave')
    error('resSave.mat was found but did not contain variable resSave: %s', resPath);
end
resSave = S.resSave;
fprintf('Loaded resSave from:\n%s\n\n', resPath);

%% ---------------- Load burst table ----------------
% Prefer the novel/familiar burst table for category labels, then fall back to detected bursts.
knownBurstPaths = { ...
    fullfile(projectRoot, 'allresults', 'beta_burst_novel_familiar_outputs_BETA13_30', 'hc31_novel_familiar_burst_table.csv'), ...
    fullfile(projectRoot, 'beta_burst_novel_familiar_outputs_BETA13_30', 'hc31_novel_familiar_burst_table.csv'), ...
    fullfile(projectRoot, 'allresults', 'beta_burst_novel_familiar_outputs', 'hc31_novel_familiar_burst_table.csv'), ...
    fullfile(projectRoot, 'beta_burst_novel_familiar_outputs', 'hc31_novel_familiar_burst_table.csv'), ...
    fullfile(projectRoot, 'allresults', 'beta_burst_over_time_outputs_BETA13_30_FUNC', 'hc31_detected_beta_bursts.csv'), ...
    fullfile(projectRoot, 'beta_burst_over_time_outputs_BETA13_30_FUNC', 'hc31_detected_beta_bursts.csv'), ...
    fullfile(projectRoot, 'allresults', 'beta_burst_over_time_outputs_FUNC', 'hc31_detected_beta_bursts.csv'), ...
    fullfile(projectRoot, 'beta_burst_over_time_outputs_FUNC', 'hc31_detected_beta_bursts.csv'), ...
    fullfile(projectRoot, 'allresults', 'burst_location_outputs', 'hc31_burst_locations_run1.csv'), ...
    fullfile(projectRoot, 'burst_location_outputs', 'hc31_burst_locations_run1.csv')};

burstCsv = '';
for kk = 1:numel(knownBurstPaths)
    if exist(knownBurstPaths{kk}, 'file') == 2
        burstCsv = knownBurstPaths{kk};
        break;
    end
end
if isempty(burstCsv)
    burstCsv = find_first_file(projectRoot, 'hc31_novel_familiar_burst_table.csv');
end
if isempty(burstCsv)
    burstCsv = find_first_file(projectRoot, 'hc31_detected_beta_bursts.csv');
end
if isempty(burstCsv)
    error('Could not find hc31_novel_familiar_burst_table.csv or hc31_detected_beta_bursts.csv under project root: %s', projectRoot);
end

Braw = readtable(burstCsv);
fprintf('Loaded burst table:\n%s\n', burstCsv);
fprintf('Rows: %d\n\n', height(Braw));

B = standardise_burst_table(Braw);

% Keep only valid/included rows when available.
if ismember('included', B.Properties.VariableNames)
    B = B(B.included == 1, :);
end
if ismember('isArtifact', B.Properties.VariableNames)
    B = B(B.isArtifact == 0, :);
end

B.band = normalize_band_labels(B.band);
B = B(ismember(cellstr(B.band), P.bandNames), :);

if height(B) == 0
    error('No valid beta/beta2 burst rows remained after filtering.');
end

%% ---------------- Inventory resSave spike/place fields ----------------
Inventory = build_resSave_inventory(resSave, P.analysedResSaveIdx);
writetable(Inventory, fullfile(P.outDir, 'hc31_batch8_resSave_spike_placefield_inventory.csv'));

%% ---------------- Main spike/place-field linkage ----------------
UnitRows = {};
EventRows = {};
FieldRows = {};

for ri = P.analysedResSaveIdx
    if ri > numel(resSave)
        continue;
    end

    R = resSave(ri);
    animal = get_animal_name(R, ri);
    fprintf('\nAnimal %s | resSave(%d)\n', animal, ri);

    if ~isfield(R, 'spEpochSep') || isempty(R.spEpochSep)
        warning('No spEpochSep field for %s. Skipping animal.', animal);
        continue;
    end
    if ~isfield(R, 'posMazeLin') || isempty(R.posMazeLin)
        warning('No posMazeLin field for %s. Skipping animal.', animal);
        continue;
    end
    if ~isfield(R, 'sectInt') || isempty(R.sectInt)
        warning('No sectInt field for %s. Skipping animal.', animal);
        continue;
    end

    % Spike epoch selection.
    sp = R.spEpochSep;
    nUnits = size(sp, 1);
    runEpoch = P.run1SpikeEpoch;
    if size(sp, 2) < runEpoch
        runEpoch = 1;
    end

    % Position and speed.
    posU = R.posMazeLin(1);
    [posT, posLin, speedCmS] = extract_position_speed(posU);
    validMove = isfinite(posT) & isfinite(posLin) & isfinite(speedCmS) & speedCmS >= P.speedThresholdCmS;

    sectInt = double(R.sectInt);
    if max(abs(sectInt(:))) < 1e6
        sectInt = sectInt .* 1e6; % convert seconds to microseconds if needed
    end

    % Unit spike times and place-field summary.
    unitInfo = summarise_units_and_fields(R, nUnits, runEpoch, sectInt);
    for u = 1:nUnits
        FieldRows(end+1, :) = {animal, ri, u, unitInfo(u).run1SpikeCount, ...
            unitInfo(u).run1RateHz, unitInfo(u).nFields, unitInfo(u).nNovelFields, ...
            unitInfo(u).nFamiliarFields, unitInfo(u).hasNovelField, ...
            unitInfo(u).hasFamiliarField}; %#ok<SAGROW>
    end

    animalBursts = B(strcmp(string(B.animal), string(animal)) | B.resSaveIndex == ri, :);
    if height(animalBursts) == 0
        warning('No burst rows matched %s / resSave(%d).', animal, ri);
        continue;
    end

    for bi = 1:numel(P.bandNames)
        band = string(P.bandNames{bi});
        BB = animalBursts(animalBursts.band == band, :);
        if height(BB) == 0
            continue;
        end

        % Standardise missing category.
        if ~ismember('category', BB.Properties.VariableNames)
            BB.category = repmat("all", height(BB), 1);
        end
        BB.category = lower(string(BB.category));
        BB.category(BB.category ~= "novel" & BB.category ~= "familiar") = "all";

        % Fill subepoch from sectInt if missing.
        if ~ismember('subepoch', BB.Properties.VariableNames) || all(isnan(BB.subepoch))
            BB.subepoch = assign_subepoch(BB.peakUs, sectInt);
        end

        % Define burst windows.
        [burstStartUs, burstEndUs, durationS] = burst_windows_from_table(BB, P);

        % Matched non-burst control windows.
        [ctrlStartUs, ctrlEndUs, ctrlCenterUs, ctrlSpeedCmS] = sample_matched_control_windows( ...
            BB.peakUs, durationS, BB.subepoch, BB.peakSpeedCmS, sectInt, posT, speedCmS, ...
            validMove, BB.peakUs, P);

        validCtrl = isfinite(ctrlStartUs) & isfinite(ctrlEndUs);
        fprintf('  %s: %d bursts, %d matched controls\n', band, height(BB), nnz(validCtrl));

        categories = ["all", "novel", "familiar"];
        for ci = 1:numel(categories)
            cat = categories(ci);
            if cat == "all"
                useBurst = true(height(BB), 1);
            else
                useBurst = BB.category == cat;
            end
            useBurst = useBurst & isfinite(burstStartUs) & isfinite(burstEndUs) & validCtrl;

            if nnz(useBurst) == 0
                continue;
            end

            bStart = burstStartUs(useBurst);
            bEnd   = burstEndUs(useBurst);
            cStart = ctrlStartUs(useBurst);
            cEnd   = ctrlEndUs(useBurst);
            eventDur = durationS(useBurst);

            % Event-level ensemble activity.
            eventActiveBurst = zeros(numel(bStart), 1);
            eventSpikesBurst = zeros(numel(bStart), 1);
            eventActiveCtrl  = zeros(numel(bStart), 1);
            eventSpikesCtrl  = zeros(numel(bStart), 1);

            unitBurstCountsTotal = zeros(nUnits, 1);
            unitCtrlCountsTotal  = zeros(nUnits, 1);
            unitBurstParticip    = zeros(nUnits, 1);
            unitCtrlParticip     = zeros(nUnits, 1);

            for u = 1:nUnits
                st = unitInfo(u).spikeTimesUs;
                bCounts = count_spikes_in_intervals(st, bStart, bEnd);
                cCounts = count_spikes_in_intervals(st, cStart, cEnd);

                unitBurstCountsTotal(u) = sum(bCounts);
                unitCtrlCountsTotal(u)  = sum(cCounts);
                unitBurstParticip(u) = mean(bCounts > 0);
                unitCtrlParticip(u)  = mean(cCounts > 0);

                eventActiveBurst = eventActiveBurst + double(bCounts > 0);
                eventSpikesBurst = eventSpikesBurst + bCounts;
                eventActiveCtrl  = eventActiveCtrl  + double(cCounts > 0);
                eventSpikesCtrl  = eventSpikesCtrl  + cCounts;
            end

            for e = 1:numel(bStart)
                EventRows(end+1, :) = {animal, ri, char(band), char(cat), e, ...
                    bStart(e), bEnd(e), cStart(e), cEnd(e), ...
                    eventDur(e), eventActiveBurst(e), eventActiveCtrl(e), ...
                    eventSpikesBurst(e), eventSpikesCtrl(e)}; %#ok<SAGROW>
            end

            totalBurstTimeS = sum((bEnd - bStart) ./ 1e6, 'omitnan');
            totalCtrlTimeS  = sum((cEnd - cStart) ./ 1e6, 'omitnan');

            for u = 1:nUnits
                burstFR = unitBurstCountsTotal(u) / max(totalBurstTimeS, eps);
                ctrlFR  = unitCtrlCountsTotal(u)  / max(totalCtrlTimeS, eps);

                UnitRows(end+1, :) = {animal, ri, u, char(band), char(cat), ...
                    nnz(useBurst), totalBurstTimeS, totalCtrlTimeS, ...
                    unitInfo(u).run1SpikeCount, unitInfo(u).run1RateHz, ...
                    unitBurstCountsTotal(u), unitCtrlCountsTotal(u), ...
                    burstFR, ctrlFR, burstFR - ctrlFR, ...
                    unitBurstParticip(u), unitCtrlParticip(u), ...
                    unitBurstParticip(u) - unitCtrlParticip(u), ...
                    unitInfo(u).nFields, unitInfo(u).nNovelFields, unitInfo(u).nFamiliarFields, ...
                    unitInfo(u).hasNovelField, unitInfo(u).hasFamiliarField}; %#ok<SAGROW>
            end
        end
    end
end

%% ---------------- Write tables ----------------
if isempty(FieldRows)
    warning('No field/unit rows were created.');
    FieldSummary = table();
else
    FieldSummary = cell2table(FieldRows, 'VariableNames', { ...
        'animal','resSaveIndex','unitIndex','run1SpikeCount','run1RateHz', ...
        'nFields','nNovelFields','nFamiliarFields','hasNovelField','hasFamiliarField'});
    writetable(FieldSummary, fullfile(P.outDir, 'hc31_batch8_unit_placefield_summary.csv'));
end

if isempty(UnitRows)
    warning('No unit burst-participation rows were created.');
    UnitSummary = table();
else
    UnitSummary = cell2table(UnitRows, 'VariableNames', { ...
        'animal','resSaveIndex','unitIndex','band','category','nEvents', ...
        'totalBurstTimeS','totalControlTimeS','run1SpikeCount','run1RateHz', ...
        'burstSpikeCount','controlSpikeCount','burstFiringRateHz','controlFiringRateHz', ...
        'burstMinusControlFiringRateHz','burstParticipationFraction', ...
        'controlParticipationFraction','burstMinusControlParticipationFraction', ...
        'nFields','nNovelFields','nFamiliarFields','hasNovelField','hasFamiliarField'});
    writetable(UnitSummary, fullfile(P.outDir, 'hc31_batch8_unit_burst_participation.csv'));
end

if isempty(EventRows)
    EventSummary = table();
else
    EventSummary = cell2table(EventRows, 'VariableNames', { ...
        'animal','resSaveIndex','band','category','eventNumber', ...
        'burstStartUs','burstEndUs','controlStartUs','controlEndUs','durationS', ...
        'nActiveUnitsBurst','nActiveUnitsControl','nSpikesBurst','nSpikesControl'});
    writetable(EventSummary, fullfile(P.outDir, 'hc31_batch8_event_ensemble_activity.csv'));
end

%% ---------------- Animal-level summaries and stats ----------------
if exist('UnitSummary','var') && ~isempty(UnitSummary)
    AnimalUnitSummary = make_animal_unit_summary(UnitSummary);
    writetable(AnimalUnitSummary, fullfile(P.outDir, 'hc31_batch8_animal_level_unit_summary.csv'));

    StatsSummary = make_batch8_stats_summary(AnimalUnitSummary);
    writetable(StatsSummary, fullfile(P.outDir, 'hc31_batch8_animal_level_stats_summary.csv'));
else
    AnimalUnitSummary = table();
    StatsSummary = table();
end

if exist('EventSummary','var') && ~isempty(EventSummary)
    AnimalEventSummary = make_animal_event_summary(EventSummary);
    writetable(AnimalEventSummary, fullfile(P.outDir, 'hc31_batch8_animal_level_event_summary.csv'));
else
    AnimalEventSummary = table();
end

%% ---------------- Figures ----------------
if exist('UnitSummary','var') && ~isempty(UnitSummary)
    make_batch8_unit_figures(UnitSummary, AnimalUnitSummary, P);
end
if exist('EventSummary','var') && ~isempty(EventSummary)
    make_batch8_event_figures(AnimalEventSummary, P);
end
if exist('FieldSummary','var') && ~isempty(FieldSummary)
    make_batch8_field_figures(FieldSummary, P);
end

write_batch8_readme(P, burstCsv);

fprintf('\nBatch 8 complete.\n');
fprintf('Outputs saved in:\n%s\n', P.outDir);

%% ========================================================================
%% Local functions
%% ========================================================================
