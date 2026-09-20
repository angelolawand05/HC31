%% HC-31 Run1 beta timecourse plots - plain script for eval(fileread(...))
%
% HOW TO RUN IN YOUR MATLAB SETUP:
%
%   cd('C:\Users\angel\Documents\MATLAB\CRCN')
%   clear
%   clc
%   close all
%   rehash
%
%   txt = fileread('hc31_run1_beta_timecourse_plots_PLAIN_SCRIPT.m');
%   eval(txt)
%
% WHAT THIS SCRIPT MAKES:
%   1) One plot per rat:
%        - x-axis: Run1 time
%        - y-axis: burst frequency (bursts/min)
%        - blue line: broad beta (beta_13_30Hz)
%        - orange line: beta2 (beta2_23_30Hz)
%        - vertical dashed lines: opening times of the next Run1 subepochs
%
%   2) One averaged plot across all 5 rats:
%        - each rat's Run1 timecourse is interpolated onto a common timeline
%          with duration equal to the MEAN Run1 duration across rats
%        - this is a time-warped/interpolated average, so rats with longer
%          or shorter Run1 durations are scaled onto the same mean-duration axis
%
% EXPECTED INPUT FILES:
%   - resSave.mat
%   - beta_burst_over_time_outputs_FUNC\hc31_detected_beta_bursts.csv
%
% OUTPUT FOLDER:
%   - run1_beta_timecourse_outputs

clear; clc; close all;

%% ===================== USER SETTINGS =====================

rootDir = pwd;

resSavePath = fullfile(rootDir, 'resSave.mat');
burstFilePath = fullfile(rootDir, 'beta_burst_over_time_outputs_FUNC', 'hc31_detected_beta_bursts.csv');

animalIndices = 5:9;

broadBetaName = 'beta_13_30Hz';
beta2Name = 'beta2_23_30Hz';

% Time bin for burst-frequency timecourse
BIN_SEC = 60;

% Remove artefact-labelled bursts if such a column exists
removeArtefactBursts = true;

outDir = fullfile(rootDir, 'run1_beta_timecourse_outputs');
figDir = fullfile(outDir, 'figures');

if ~exist(outDir, 'dir')
    mkdir(outDir);
end
if ~exist(figDir, 'dir')
    mkdir(figDir);
end

fprintf('\nHC-31 Run1 beta timecourse plots\n');
fprintf('Root folder: %s\n', rootDir);
fprintf('Bin size: %.1f sec\n\n', BIN_SEC);

%% ===================== INPUT CHECKS =====================

if ~exist(resSavePath, 'file')
    error('Could not find resSave.mat at: %s', resSavePath);
end

if ~exist(burstFilePath, 'file')
    fallback1 = fullfile(rootDir, 'hc31_detected_beta_bursts.csv');
    fallback2 = fullfile(rootDir, 'outputs_hc31_beta', 'hc31_detected_beta_bursts.csv');

    if exist(fallback1, 'file')
        burstFilePath = fallback1;
    elseif exist(fallback2, 'file')
        burstFilePath = fallback2;
    else
        error(['Could not find hc31_detected_beta_bursts.csv.\nExpected path:\n%s'], burstFilePath);
    end
end

fprintf('Using resSave:\n  %s\n', resSavePath);
fprintf('Using burst table:\n  %s\n\n', burstFilePath);

%% ===================== LOAD DATA =====================

data = load(resSavePath);

if ~isfield(data, 'resSave')
    error('Loaded MAT file, but variable resSave was not found.');
end

resSave = data.resSave;
burstTable = readtable(burstFilePath);

fprintf('Loaded %d resSave entries.\n', numel(resSave));
fprintf('Loaded burst table with %d rows.\n\n', height(burstTable));

%% ===================== FIND BURST TABLE COLUMNS =====================

vars = burstTable.Properties.VariableNames;

animalCandidates = {'animal','Animal','animal_id','animalID','rat','ratID','resSaveAnimal'};
bandCandidates = {'band','Band','freqBand','frequency_band','betaBand'};
timeCandidates = {'peak_time','peakTime','peak_time_s','peakTimeS', ...
                  'peak_time_sec','peakTimeSec','peak_time_us','peakTimeUs', ...
                  'peak_timestamp','peakTimestamp','burst_peak_time','burstPeakTime', ...
                  'burst_peak_us','burstPeakUs'};
artefactCandidates = {'is_artifact','isArtefact','isArtifact', ...
                      'artifact','artefact','artifactFlag','artefactFlag', ...
                      'excluded_as_artifact','excludedAsArtifact'};

animalCol = '';
bandCol = '';
timeCol = '';
artefactCol = '';

for c = 1:numel(animalCandidates)
    for v = 1:numel(vars)
        if strcmpi(vars{v}, animalCandidates{c})
            animalCol = vars{v};
        end
    end
end

for c = 1:numel(bandCandidates)
    for v = 1:numel(vars)
        if strcmpi(vars{v}, bandCandidates{c})
            bandCol = vars{v};
        end
    end
end

for c = 1:numel(timeCandidates)
    for v = 1:numel(vars)
        if strcmpi(vars{v}, timeCandidates{c})
            timeCol = vars{v};
        end
    end
end

for c = 1:numel(artefactCandidates)
    for v = 1:numel(vars)
        if strcmpi(vars{v}, artefactCandidates{c})
            artefactCol = vars{v};
        end
    end
end

normVars = cell(size(vars));
for v = 1:numel(vars)
    normVars{v} = lower(regexprep(vars{v}, '[^a-zA-Z0-9]', ''));
end

if isempty(animalCol)
    for c = 1:numel(animalCandidates)
        target = lower(regexprep(animalCandidates{c}, '[^a-zA-Z0-9]', ''));
        for v = 1:numel(vars)
            if strcmp(normVars{v}, target)
                animalCol = vars{v};
            end
        end
    end
end

if isempty(bandCol)
    for c = 1:numel(bandCandidates)
        target = lower(regexprep(bandCandidates{c}, '[^a-zA-Z0-9]', ''));
        for v = 1:numel(vars)
            if strcmp(normVars{v}, target)
                bandCol = vars{v};
            end
        end
    end
end

if isempty(timeCol)
    for c = 1:numel(timeCandidates)
        target = lower(regexprep(timeCandidates{c}, '[^a-zA-Z0-9]', ''));
        for v = 1:numel(vars)
            if strcmp(normVars{v}, target)
                timeCol = vars{v};
            end
        end
    end
end

if isempty(artefactCol)
    for c = 1:numel(artefactCandidates)
        target = lower(regexprep(artefactCandidates{c}, '[^a-zA-Z0-9]', ''));
        for v = 1:numel(vars)
            if strcmp(normVars{v}, target)
                artefactCol = vars{v};
            end
        end
    end
end

if isempty(animalCol) || isempty(bandCol) || isempty(timeCol)
    fprintf('Available burst table columns:\n');
    disp(vars');
    error('Could not identify required animal, band, or time columns.');
end

fprintf('Detected columns:\n');
fprintf('  animal column: %s\n', animalCol);
fprintf('  band column:   %s\n', bandCol);
fprintf('  time column:   %s\n', timeCol);

if isempty(artefactCol)
    fprintf('  artefact column: not found\n\n');
else
    fprintf('  artefact column: %s\n\n', artefactCol);
end

%% ===================== CONVERT ANIMAL/BAND COLUMNS =====================

rawAnimal = burstTable.(animalCol);
rawBand = burstTable.(bandCol);

if isnumeric(rawAnimal)
    animalVals = arrayfun(@num2str, rawAnimal(:), 'UniformOutput', false);
elseif iscell(rawAnimal)
    animalVals = cell(numel(rawAnimal), 1);
    for q = 1:numel(rawAnimal)
        if isnumeric(rawAnimal{q})
            animalVals{q} = num2str(rawAnimal{q});
        else
            animalVals{q} = char(rawAnimal{q});
        end
    end
else
    try
        animalVals = cellstr(rawAnimal);
    catch
        animalVals = cellstr(string(rawAnimal));
    end
    animalVals = animalVals(:);
end

if isnumeric(rawBand)
    bandVals = arrayfun(@num2str, rawBand(:), 'UniformOutput', false);
elseif iscell(rawBand)
    bandVals = cell(numel(rawBand), 1);
    for q = 1:numel(rawBand)
        if isnumeric(rawBand{q})
            bandVals{q} = num2str(rawBand{q});
        else
            bandVals{q} = char(rawBand{q});
        end
    end
else
    try
        bandVals = cellstr(rawBand);
    catch
        bandVals = cellstr(string(rawBand));
    end
    bandVals = bandVals(:);
end

%% ===================== OPTIONAL ARTEFACT REMOVAL =====================

if removeArtefactBursts && ~isempty(artefactCol)

    rawArtefact = burstTable.(artefactCol);
    artefactMask = false(height(burstTable), 1);

    if islogical(rawArtefact)
        artefactMask = rawArtefact(:);
    elseif isnumeric(rawArtefact)
        artefactMask = rawArtefact(:) ~= 0;
    else
        try
            artefactText = cellstr(rawArtefact);
        catch
            artefactText = cellstr(string(rawArtefact));
        end
        artefactText = lower(artefactText(:));

        for q = 1:numel(artefactText)
            if strcmp(artefactText{q}, 'true') || strcmp(artefactText{q}, '1') || ...
               strcmp(artefactText{q}, 'yes') || strcmp(artefactText{q}, 'y') || ...
               strcmp(artefactText{q}, 'artifact') || strcmp(artefactText{q}, 'artefact') || ...
               strcmp(artefactText{q}, 'excluded')
                artefactMask(q) = true;
            end
        end
    end

    keepRows = ~artefactMask;
    nBefore = height(burstTable);

    burstTable = burstTable(keepRows, :);
    animalVals = animalVals(keepRows);
    bandVals = bandVals(keepRows);

    fprintf('Removed %d artefact-labelled burst rows.\n\n', nBefore - height(burstTable));
end

%% ===================== MAIN PER-RAT TIMECOURSES =====================

% We will store everything in cell arrays/struct-like containers
ratIDs = {};
ratDurationSec = [];
ratTimeCentersSec = {};
ratBroadRates = {};
ratBeta2Rates = {};
ratOpenTimesSec = {};

rowRat = {};
rowTimeSec = [];
rowBroadRate = [];
rowBeta2Rate = [];

for ai = 1:numel(animalIndices)

    idx = animalIndices(ai);

    if idx > numel(resSave)
        warning('resSave(%d) does not exist. Skipping.', idx);
        continue;
    end

    R = resSave(idx);

    animalID = sprintf('resSave_%d', idx);

    if isfield(R, 'spAll')
        try
            if ~isempty(R.spAll) && isfield(R.spAll, 'animal')
                animalID = char(R.spAll(1).animal);
            end
        catch
        end
    end

    if strcmp(animalID, sprintf('resSave_%d', idx))
        if idx == 5
            animalID = 'ANM00190422';
        elseif idx == 6
            animalID = 'ANM204878';
        elseif idx == 7
            animalID = 'ANM212379';
        elseif idx == 8
            animalID = 'ANM228899';
        elseif idx == 9
            animalID = 'ANM228900';
        end
    end

    if ~isfield(R, 'sectInt')
        warning('resSave(%d) is missing sectInt. Skipping.', idx);
        continue;
    end

    sectInt = double(R.sectInt);

    if size(sectInt, 2) ~= 2
        sectInt = reshape(sectInt, [], 2);
    end

    run1Start = sectInt(1, 1);
    run1End = sectInt(end, 2);

    if isfield(R, 'posMazeLin')
        posU = R.posMazeLin(1);
        if isstruct(posU) && isfield(posU, 'data')
            posData = double(posU.data);
        else
            posData = double(posU);
        end
        posTime = posData(:, 1);
        goodTime = posTime(isfinite(posTime));
        if numel(goodTime) >= 5
            dtNative = median(diff(goodTime));
            if dtNative > 100
                timeUnitsPerSecond = 1e6;
            else
                timeUnitsPerSecond = 1;
            end
        else
            timeUnitsPerSecond = 1e6;
        end
    else
        if median(diff(run1Start:run1End)) > 100
            timeUnitsPerSecond = 1e6;
        else
            timeUnitsPerSecond = 1;
        end
    end

    run1DurationSec = (run1End - run1Start) ./ timeUnitsPerSecond;
    openTimesNative = sectInt(2:end, 1);
    openTimesSec = (openTimesNative - run1Start) ./ timeUnitsPerSecond;

    edgesNative = run1Start : (BIN_SEC .* timeUnitsPerSecond) : run1End;
    if isempty(edgesNative) || numel(edgesNative) < 2
        edgesNative = [run1Start, run1End];
    elseif edgesNative(end) < run1End
        edgesNative = [edgesNative, run1End];
    elseif edgesNative(end) > run1End
        edgesNative(end) = run1End;
    end

    if numel(edgesNative) < 2
        warning('Run1 window for %s was too short. Skipping.', animalID);
        continue;
    end

    centersNative = (edgesNative(1:end-1) + edgesNative(2:end)) ./ 2;
    centersSec = (centersNative - run1Start) ./ timeUnitsPerSecond;
    binDurSec = diff(edgesNative) ./ timeUnitsPerSecond;

    animalMask = strcmp(animalVals, animalID);

    if ~any(animalMask)
        animalMask = false(numel(animalVals), 1);
        for q = 1:numel(animalVals)
            if ~isempty(strfind(animalVals{q}, animalID))
                animalMask(q) = true;
            end
        end
    end

    if ~any(animalMask)
        numericAnimalVals = str2double(animalVals);
        animalMask = numericAnimalVals == idx;
    end

    burstTimesThisAnimal = double(burstTable.(timeCol));

    broadMask = animalMask & strcmp(bandVals, broadBetaName) & ...
        burstTimesThisAnimal >= run1Start & burstTimesThisAnimal <= run1End;

    beta2Mask = animalMask & strcmp(bandVals, beta2Name) & ...
        burstTimesThisAnimal >= run1Start & burstTimesThisAnimal <= run1End;

    broadTimes = burstTimesThisAnimal(broadMask);
    beta2Times = burstTimesThisAnimal(beta2Mask);

    broadCounts = histcounts(broadTimes, edgesNative);
    beta2Counts = histcounts(beta2Times, edgesNative);

    broadRate = broadCounts ./ binDurSec .* 60;
    beta2Rate = beta2Counts ./ binDurSec .* 60;

    fprintf('Processed %s | Run1 duration %.1f sec | broad bursts %d | beta2 bursts %d\n', ...
        animalID, run1DurationSec, sum(broadCounts), sum(beta2Counts));

    ratIDs{end+1, 1} = animalID; %#ok<SAGROW>
    ratDurationSec(end+1, 1) = run1DurationSec; %#ok<SAGROW>
    ratTimeCentersSec{end+1, 1} = centersSec; %#ok<SAGROW>
    ratBroadRates{end+1, 1} = broadRate; %#ok<SAGROW>
    ratBeta2Rates{end+1, 1} = beta2Rate; %#ok<SAGROW>
    ratOpenTimesSec{end+1, 1} = openTimesSec; %#ok<SAGROW>

    for rr = 1:numel(centersSec)
        rowRat{end+1, 1} = animalID; %#ok<SAGROW>
        rowTimeSec(end+1, 1) = centersSec(rr); %#ok<SAGROW>
        rowBroadRate(end+1, 1) = broadRate(rr); %#ok<SAGROW>
        rowBeta2Rate(end+1, 1) = beta2Rate(rr); %#ok<SAGROW>
    end

    % ----- Per-rat figure -----
    f = figure('Color', 'w', 'Position', [100 100 900 520]);
    hold on;

    plot(centersSec, broadRate, '-o', 'LineWidth', 1.8, 'MarkerSize', 5);
    plot(centersSec, beta2Rate, '-o', 'LineWidth', 1.8, 'MarkerSize', 5);

    yl = ylim;
    if all(~isfinite(yl)) || yl(1) == yl(2)
        yl = [0 1];
        ylim(yl);
    end

    for k = 1:numel(openTimesSec)
        line([openTimesSec(k) openTimesSec(k)], yl, 'LineStyle', '--', 'LineWidth', 1.2);
    end

    xlabel(sprintf('Run1 time (s), %d-s bins', round(BIN_SEC)));
    ylabel('Burst frequency (bursts/min)');
    title(sprintf('%s: Run1 burst frequency over time', animalID), 'Interpreter', 'none');
    legend({'Broad beta (13-30 Hz)','Beta2 (23-30 Hz)','Next subepoch opened'}, 'Location', 'best');
    grid on;
    xlim([0 run1DurationSec]);

    saveas(f, fullfile(figDir, [animalID '_run1_beta_timecourse.png']));
    close(f);
end

%% ===================== SAVE PER-RAT TIMECOURSE TABLE =====================

if isempty(rowRat)
    error('No rat timecourses were generated.');
end

timecourseTable = table(rowRat, rowTimeSec, rowBroadRate, rowBeta2Rate, ...
    'VariableNames', {'animal','timeSec','broadBetaRatePerMin','beta2RatePerMin'});

writetable(timecourseTable, fullfile(outDir, 'run1_beta_timecourses_by_rat.csv'));

%% ===================== AVERAGED / INTERPOLATED PLOT =====================

nRats = numel(ratIDs);
meanRun1DurationSec = mean(ratDurationSec);

% Common interpolated axis
N_COMMON = 200;
commonTimeSec = linspace(0, meanRun1DurationSec, N_COMMON);
commonProgress = commonTimeSec ./ meanRun1DurationSec;

broadInterpAll = nan(nRats, N_COMMON);
beta2InterpAll = nan(nRats, N_COMMON);

maxOpenCount = 0;
for i = 1:nRats
    maxOpenCount = max(maxOpenCount, numel(ratOpenTimesSec{i}));
end

scaledOpenMatrix = nan(nRats, maxOpenCount);

for i = 1:nRats

    durationThis = ratDurationSec(i);

    centersSec = ratTimeCentersSec{i};
    broadRate = ratBroadRates{i};
    beta2Rate = ratBeta2Rates{i};
    openTimesSec = ratOpenTimesSec{i};

    if durationThis <= 0
        continue;
    end

    ownProgress = centersSec ./ durationThis;

    % Pad endpoints so interpolation covers full 0..1 interval
    if isempty(ownProgress)
        continue;
    end

    ownProgressPad = [0, ownProgress(:)', 1];
    broadPad = [broadRate(1), broadRate(:)', broadRate(end)];
    beta2Pad = [beta2Rate(1), beta2Rate(:)', beta2Rate(end)];

    % Ensure monotonic unique x-values
    [ownProgressPad, uniqIdx] = unique(ownProgressPad);
    broadPad = broadPad(uniqIdx);
    beta2Pad = beta2Pad(uniqIdx);

    broadInterpAll(i, :) = interp1(ownProgressPad, broadPad, commonProgress, 'linear');
    beta2InterpAll(i, :) = interp1(ownProgressPad, beta2Pad, commonProgress, 'linear');

    if ~isempty(openTimesSec)
        scaledOpenTimes = openTimesSec ./ durationThis .* meanRun1DurationSec;
        scaledOpenMatrix(i, 1:numel(scaledOpenTimes)) = scaledOpenTimes;
    end
end

meanBroad = nan(1, N_COMMON);
meanBeta2 = nan(1, N_COMMON);

for j = 1:N_COMMON
    x = broadInterpAll(:, j);
    x = x(isfinite(x));
    if ~isempty(x)
        meanBroad(j) = mean(x);
    end

    x = beta2InterpAll(:, j);
    x = x(isfinite(x));
    if ~isempty(x)
        meanBeta2(j) = mean(x);
    end
end

meanOpenTimes = nan(1, maxOpenCount);
for k = 1:maxOpenCount
    x = scaledOpenMatrix(:, k);
    x = x(isfinite(x));
    if ~isempty(x)
        meanOpenTimes(k) = mean(x);
    end
end

avgTable = table(commonTimeSec(:), meanBroad(:), meanBeta2(:), ...
    'VariableNames', {'interpolatedTimeSec','meanBroadBetaRatePerMin','meanBeta2RatePerMin'});
writetable(avgTable, fullfile(outDir, 'run1_beta_timecourse_average_interpolated.csv'));

if maxOpenCount > 0
    openTable = table((1:maxOpenCount)', meanOpenTimes(:), ...
        'VariableNames', {'subepochOpeningIndex','meanInterpolatedOpeningTimeSec'});
    writetable(openTable, fullfile(outDir, 'run1_mean_interpolated_subepoch_openings.csv'));
end

f = figure('Color', 'w', 'Position', [100 100 980 560]);
hold on;

plot(commonTimeSec, meanBroad, 'LineWidth', 2.4);
plot(commonTimeSec, meanBeta2, 'LineWidth', 2.4);

yl = ylim;
if all(~isfinite(yl)) || yl(1) == yl(2)
    yl = [0 1];
    ylim(yl);
end

for k = 1:numel(meanOpenTimes)
    if isfinite(meanOpenTimes(k))
        line([meanOpenTimes(k) meanOpenTimes(k)], yl, 'LineStyle', '--', 'LineWidth', 1.2);
    end
end

xlabel('Interpolated Run1 time (s, scaled to mean Run1 duration)');
ylabel('Mean burst frequency (bursts/min)');
title(sprintf('Average Run1 burst frequency across %d rats (interpolated to mean duration %.1f s)', ...
    nRats, meanRun1DurationSec));
legend({'Broad beta (13-30 Hz)','Beta2 (23-30 Hz)','Mean subepoch opening'}, 'Location', 'best');
grid on;
xlim([0 meanRun1DurationSec]);

saveas(f, fullfile(figDir, 'ALL_RATS_average_interpolated_run1_beta_timecourse.png'));
close(f);

%% ===================== SUMMARY TABLE =====================

summaryAnimal = table(ratIDs, ratDurationSec, ...
    'VariableNames', {'animal','run1DurationSec'});
writetable(summaryAnimal, fullfile(outDir, 'run1_duration_summary.csv'));

%% ===================== FINISH =====================

fprintf('\nDone.\n');
fprintf('Output folder:\n  %s\n\n', outDir);
fprintf('Figures saved in:\n  %s\n\n', figDir);
fprintf('Files created:\n');
fprintf('  - run1_beta_timecourses_by_rat.csv\n');
fprintf('  - run1_beta_timecourse_average_interpolated.csv\n');
fprintf('  - run1_duration_summary.csv\n');
fprintf('  - one per-rat PNG figure\n');
fprintf('  - one averaged interpolated PNG figure\n\n');
fprintf('Note on the final averaged plot:\n');
fprintf('  Each rat''s Run1 timecourse was scaled/interpolated onto a common time axis\n');
fprintf('  with duration equal to the mean Run1 duration across rats.\n');
fprintf('  This is the time-warped average you asked for.\n\n');
