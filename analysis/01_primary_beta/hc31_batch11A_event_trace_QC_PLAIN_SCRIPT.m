%% HC-31 Batch 11A: event trace QC plots
%
% Plain script version. No local functions.
%
% Purpose:
%   Create validation trace plots around selected beta2 bursts and candidate
%   awake ripple events.
%
% Each figure attempts to show:
%   1. raw LFP around the event
%   2. beta2-filtered LFP
%   3. beta2 Hilbert-envelope z trace
%   4. ripple-filtered LFP
%   5. ripple Hilbert-envelope z trace
%   6. movement speed around the event
%   7. spike raster for selected CA1 units, if spike timestamps are available
%
% Required:
%   - resSave.mat
%   - csc_files folder
%   - neuralynximport folder containing Nlx2MatCSC and readNlxHeader
%   - hc31_detected_beta_bursts.csv
%   - hc31_batch9_candidate_awake_ripples.csv
%
% Optional:
%   - hc31_batch10_run1_beta2_unit_tags.csv
%     Used to pick beta2-tagged units for the spike raster.
%
% Recommended MATLAB workaround:
%
%   clear; clc; close all; rehash;
%   [scriptFile, scriptFolder] = uigetfile('*.m', 'Select hc31_batch11A_event_trace_QC_PLAIN_SCRIPT.m');
%   cd(scriptFolder);
%   txt = fileread(fullfile(scriptFolder, scriptFile));
%   eval(txt);

clear; clc; close all; rehash;

fprintf('\nHC-31 Batch 11A: event trace QC plots\n');
fprintf('-------------------------------------\n');

%% User-editable settings

defaultRoot = getenv('HC31_DATA_ROOT');

animalIndices = 5:9;
animalIDs = {'ANM00190422','ANM204878','ANM212379','ANM228899','ANM228900'};

targetFs = 2000;              % Hz. Keeps ripple band safely below Nyquist.
traceWindowSec = 1.5;         % seconds either side of event peak
speedThresholdCmS = 5;        % used for context and beta2 baseline
lowSpeedThresholdCmS = 5;     % used for ripple-envelope baseline where possible
maxUnitsToPlot = 12;

beta2LowHz = 23;
beta2HighHz = 30;

rippleLowHz = 150;
rippleHighHz = 250;

filterOrder = 4;

%% Locate dataset root

if exist(defaultRoot, 'dir') == 7
    rootDir = defaultRoot;
else
    rootDir = uigetdir(pwd, 'Select the HC-31 root folder containing resSave.mat');
    if isequal(rootDir, 0)
        error('No dataset folder selected.');
    end
end

if exist(fullfile(rootDir, 'resSave.mat'), 'file') ~= 2
    [matFile, matFolder] = uigetfile('*.mat', 'Select resSave.mat');
    if isequal(matFile, 0)
        error('No resSave.mat selected.');
    end
    rootDir = matFolder;
end

fprintf('Dataset root:\n  %s\n', rootDir);

%% Add Neuralynx importer

if exist(fullfile(rootDir, 'neuralynximport'), 'dir') == 7
    addpath(genpath(fullfile(rootDir, 'neuralynximport')));
end
if exist(fullfile(rootDir, 'neuralynximport', 'nlximport'), 'dir') == 7
    addpath(genpath(fullfile(rootDir, 'neuralynximport', 'nlximport')));
end

if exist('Nlx2MatCSC', 'file') ~= 3 && exist('Nlx2MatCSC', 'file') ~= 2
    error(['MATLAB cannot find Nlx2MatCSC. ', ...
           'Check that neuralynximport is inside the dataset root, or add it to the MATLAB path.']);
end

%% Load resSave

S = load(fullfile(rootDir, 'resSave.mat'));
if ~isfield(S, 'resSave')
    error('The selected MAT file does not contain resSave.');
end
resSave = S.resSave;

%% Locate required event tables

burstCsv = '';
burstCandidates = { ...
    fullfile(rootDir, 'beta_burst_over_time_outputs_BETA13_30_FUNC', 'hc31_detected_beta_bursts.csv'), ...
    fullfile(rootDir, 'beta_burst_over_time_outputs_FUNC', 'hc31_detected_beta_bursts.csv'), ...
    fullfile(rootDir, 'beta_burst_over_time_outputs_BETA13_30_FUNC', 'hc31_detected_beta_bursts.csv'), ...
    fullfile(rootDir, 'allresults', 'beta_burst_over_time_outputs_BETA13_30_FUNC', 'hc31_detected_beta_bursts.csv'), ...
    fullfile(rootDir, 'allresults', 'beta_burst_over_time_outputs_FUNC', 'hc31_detected_beta_bursts.csv') ...
    };

for q = 1:numel(burstCandidates)
    if exist(burstCandidates{q}, 'file') == 2
        burstCsv = burstCandidates{q};
        break;
    end
end

if isempty(burstCsv)
    [f,p] = uigetfile('*.csv', 'Select hc31_detected_beta_bursts.csv');
    if isequal(f,0)
        error('No beta burst CSV selected.');
    end
    burstCsv = fullfile(p,f);
end

rippleCsv = '';
rippleCandidates = { ...
    fullfile(rootDir, 'hc31_batch9_awake_ripples_beta_relationship_FORCE', 'hc31_batch9_candidate_awake_ripples.csv'), ...
    fullfile(rootDir, 'allresults', 'hc31_batch9_awake_ripples_beta_relationship_FORCE', 'hc31_batch9_candidate_awake_ripples.csv') ...
    };

for q = 1:numel(rippleCandidates)
    if exist(rippleCandidates{q}, 'file') == 2
        rippleCsv = rippleCandidates{q};
        break;
    end
end

if isempty(rippleCsv)
    [f,p] = uigetfile('*.csv', 'Select hc31_batch9_candidate_awake_ripples.csv');
    if isequal(f,0)
        fprintf('No ripple CSV selected. Ripple trace plots will be skipped.\n');
        rippleCsv = '';
    else
        rippleCsv = fullfile(p,f);
    end
end

unitTagCsv = '';
unitTagCandidates = { ...
    fullfile(rootDir, 'hc31_batch10_sleep_replay_memory_link_FORCE_V2', 'hc31_batch10_run1_beta2_unit_tags.csv'), ...
    fullfile(rootDir, 'allresults', 'hc31_batch10_sleep_replay_memory_link_FORCE_V2', 'hc31_batch10_run1_beta2_unit_tags.csv'), ...
    fullfile(rootDir, 'hc31_batch8_spikes_placefield_linkage_FORCE', 'hc31_batch8_unit_burst_participation.csv'), ...
    fullfile(rootDir, 'allresults', 'hc31_batch8_spikes_placefield_linkage_FORCE', 'hc31_batch8_unit_burst_participation.csv') ...
    };

for q = 1:numel(unitTagCandidates)
    if exist(unitTagCandidates{q}, 'file') == 2
        unitTagCsv = unitTagCandidates{q};
        break;
    end
end

fprintf('\nUsing beta burst table:\n  %s\n', burstCsv);
if ~isempty(rippleCsv)
    fprintf('Using candidate awake ripple table:\n  %s\n', rippleCsv);
end
if ~isempty(unitTagCsv)
    fprintf('Using unit tag table:\n  %s\n', unitTagCsv);
else
    fprintf('No unit tag table found. Spike rasters will use top firing units.\n');
end

BT = readtable(burstCsv);
if ~isempty(rippleCsv)
    RT = readtable(rippleCsv);
else
    RT = table();
end
if ~isempty(unitTagCsv)
    UT = readtable(unitTagCsv);
else
    UT = table();
end

%% Output folder

outDir = fullfile(rootDir, 'hc31_batch11A_event_trace_QC');
figDir = fullfile(outDir, 'figures');
if exist(outDir, 'dir') ~= 7
    mkdir(outDir);
end
if exist(figDir, 'dir') ~= 7
    mkdir(figDir);
end

selectionRows = {};
selectionHeader = {'animal','resSaveIndex','eventType','peakUs','startUs','endUs','peakZ','peakSpeedCmS','nUnitsPlotted','figureFile'};

%% Main loop

for ai = 1:numel(animalIndices)

    i = animalIndices(ai);
    R = resSave(i);
    animalID = animalIDs{ai};

    try
        if isfield(R, 'spAll') && ~isempty(R.spAll) && isfield(R.spAll, 'animal')
            animalID = char(R.spAll(1).animal);
        end
    catch
    end

    fprintf('\nProcessing resSave(%d): %s\n', i, animalID);

    %% Resolve CSC file for this animal

    cscFile = '';

    if strcmp(animalID, 'ANM00190422')
        cscFile = fullfile(rootDir, 'csc_files', 'ANM00190422', '2012-12-09_10-48-47', 'CSC33.ncs');
    elseif strcmp(animalID, 'ANM204878')
        cscFile = fullfile(rootDir, 'csc_files', 'ANM204878', '2013-05-11_09-32-49', 'CSC33.ncs');
    elseif strcmp(animalID, 'ANM212379')
        cscFile = fullfile(rootDir, 'csc_files', 'ANM212379', '2013-06-08_10-10-46', 'CSC53.ncs');
    elseif strcmp(animalID, 'ANM228899')
        cscFile = fullfile(rootDir, 'csc_files', 'ANM228899', '2013-11-02_10-16-53', 'CSC45.ncs');
    elseif strcmp(animalID, 'ANM228900')
        cscFile = fullfile(rootDir, 'csc_files', 'ANM228900', '2013-11-03_08-59-40', 'CSC45.ncs');
    end

    if exist(cscFile, 'file') ~= 2
        fprintf('Could not find expected CSC file for %s.\n', animalID);
        [f,p] = uigetfile('*.ncs', ['Select Run1 CSC file for ' animalID]);
        if isequal(f,0)
            fprintf('Skipping %s because no CSC file was selected.\n', animalID);
            continue;
        end
        cscFile = fullfile(p,f);
    end

    %% Run1 interval

    if isfield(R, 'sectInt')
        run1StartUs = min(R.sectInt(:));
        run1EndUs = max(R.sectInt(:));
    else
        error('resSave(%d) does not have sectInt.', i);
    end

    %% Select one representative beta2 event

    betaPeakUs = NaN;
    betaStartUs = NaN;
    betaEndUs = NaN;
    betaPeakZ = NaN;
    betaSpeed = NaN;

    btVars = BT.Properties.VariableNames;

    if any(strcmp(btVars, 'animal')) && any(strcmp(btVars, 'band')) && any(strcmp(btVars, 'burstPeakUs'))
        btAnimal = cellstr(BT.animal);
        btBand = cellstr(BT.band);

        btMask = strcmp(btAnimal, animalID) & strcmp(btBand, 'beta2_23_30Hz');

        if any(strcmp(btVars, 'excludedAsArtifact'))
            btMask = btMask & ~logical(BT.excludedAsArtifact);
        end

        Bsub = BT(btMask, :);

        if height(Bsub) > 0
            if any(strcmp(btVars, 'peakZ'))
                pz = double(Bsub.peakZ);
                good = isfinite(pz) & pz <= 12;
                if any(good)
                    Bsub = Bsub(good,:);
                    pz = double(Bsub.peakZ);
                end

                medPz = median(pz(isfinite(pz)));
                if isempty(medPz) || isnan(medPz)
                    pick = 1;
                else
                    [~, pick] = min(abs(pz - medPz));
                end
            else
                pick = max(1, round(height(Bsub)/2));
            end

            betaPeakUs = double(Bsub.burstPeakUs(pick));
            if any(strcmp(btVars, 'burstStartUs'))
                betaStartUs = double(Bsub.burstStartUs(pick));
            end
            if any(strcmp(btVars, 'burstEndUs'))
                betaEndUs = double(Bsub.burstEndUs(pick));
            end
            if any(strcmp(btVars, 'peakZ'))
                betaPeakZ = double(Bsub.peakZ(pick));
            end
            if any(strcmp(btVars, 'peakSpeedCmS'))
                betaSpeed = double(Bsub.peakSpeedCmS(pick));
            end
        end
    end

    %% Select one representative candidate awake ripple event

    ripplePeakUs = NaN;
    rippleStartUs = NaN;
    rippleEndUs = NaN;
    ripplePeakZ = NaN;
    rippleSpeed = NaN;

    if ~isempty(RT) && height(RT) > 0
        rtVars = RT.Properties.VariableNames;

        if any(strcmp(rtVars, 'animal')) && any(strcmp(rtVars, 'peakUs'))
            rtAnimal = cellstr(RT.animal);
            rtMask = strcmp(rtAnimal, animalID);

            if any(strcmp(rtVars, 'isArtifactLike'))
                rtMask = rtMask & ~logical(RT.isArtifactLike);
            end

            if any(strcmp(rtVars, 'peakSpeedCmS')) && any(strcmp(rtVars, 'peakZ'))
                preferred = rtMask & double(RT.peakSpeedCmS) <= 10 & double(RT.peakZ) <= 20;
                if any(preferred)
                    rtMask = preferred;
                end
            end

            Rsub = RT(rtMask, :);

            if height(Rsub) > 0
                if any(strcmp(rtVars, 'peakZ'))
                    pz = double(Rsub.peakZ);
                    medPz = median(pz(isfinite(pz)));
                    if isempty(medPz) || isnan(medPz)
                        pick = 1;
                    else
                        [~, pick] = min(abs(pz - medPz));
                    end
                else
                    pick = max(1, round(height(Rsub)/2));
                end

                ripplePeakUs = double(Rsub.peakUs(pick));
                if any(strcmp(rtVars, 'startUs'))
                    rippleStartUs = double(Rsub.startUs(pick));
                end
                if any(strcmp(rtVars, 'endUs'))
                    rippleEndUs = double(Rsub.endUs(pick));
                end
                if any(strcmp(rtVars, 'peakZ'))
                    ripplePeakZ = double(Rsub.peakZ(pick));
                end
                if any(strcmp(rtVars, 'peakSpeedCmS'))
                    rippleSpeed = double(Rsub.peakSpeedCmS(pick));
                end
            end
        end
    end

    if isnan(betaPeakUs) && isnan(ripplePeakUs)
        fprintf('  No beta2 or ripple events selected for %s. Skipping.\n', animalID);
        continue;
    end

    %% Load full Run1 LFP

    fprintf('  Loading Run1 LFP...\n');

    [tRec, vRec, header] = Nlx2MatCSC(cscFile, [1 0 0 0 1], 1, 4, [run1StartUs run1EndUs]);

    H = struct();
    try
        H = readNlxHeader(header);
    catch
        fprintf('  Could not parse Neuralynx header with readNlxHeader. Using raw units.\n');
    end

    tRec = double(tRec(:));
    vRec = double(vRec);
    vallRaw = double(vRec(:));

    tDiff = diff(tRec);
    mtDiff = mode(tDiff);
    noSkip = tDiff > mtDiff-2 & tDiff < mtDiff+2;

    if all(noSkip)
        FsRaw = 1/(mean(tDiff)/512/1e6);
        tallUs = linspace(tRec(1), tRec(end) + (511*(1/FsRaw)*1e6), numel(vallRaw))';
        vall = vallRaw;
    else
        warning('Records were lost. Inserting NaNs to preserve timing.');
        FsRaw = 1/(mean(tDiff(noSkip))/512/1e6);

        tVec = (tRec(1):((1/FsRaw)*1e6):(tRec(end)+(512*(1/FsRaw)*1e6)))';
        vVec = nan(numel(tVec),1);
        p = 1;

        for rr = 1:size(vRec,2)
            while p <= numel(tVec) && ~(abs(tRec(rr)-tVec(p)) < 2)
                p = p + 1;
            end

            if p + 511 <= numel(vVec)
                vVec(p:p+511) = vRec(:,rr);
            end

            p = p + 512;
        end

        tallUs = tVec;
        vall = vVec;
    end

    if isfield(H, 'ADBitVolts')
        lfpVolts = vall .* H.ADBitVolts;
        rawScaleLabel = 'Raw LFP (\muV)';
        rawPlotScale = 1e6;
    else
        lfpVolts = vall;
        rawScaleLabel = 'Raw LFP (raw units)';
        rawPlotScale = 1;
    end

    fprintf('  Raw Fs estimate: %.2f Hz\n', FsRaw);

    %% Downsample LFP

    factor = max(1, round(FsRaw / targetFs));
    FsDs = FsRaw / factor;

    validRaw = ~isnan(lfpVolts);
    if any(validRaw)
        fillValue = median(lfpVolts(validRaw));
    else
        fillValue = 0;
    end

    lfpFilled = lfpVolts;
    lfpFilled(~validRaw) = fillValue;

    if factor > 1
        try
            lfpDs = decimate(lfpFilled, factor);
        catch
            lfpDs = lfpFilled(1:factor:end);
        end
        tDsUs = tallUs(1:factor:end);
        validDs = validRaw(1:factor:end);
    else
        lfpDs = lfpFilled;
        tDsUs = tallUs;
        validDs = validRaw;
    end

    n = min([numel(lfpDs), numel(tDsUs), numel(validDs)]);
    lfpDs = lfpDs(1:n);
    tDsUs = tDsUs(1:n);
    validDs = validDs(1:n);

    fprintf('  Downsampled Fs estimate: %.2f Hz\n', FsDs);

    %% Position and speed on LFP time base

    posDs = nan(size(tDsUs));
    speedDsCmS = nan(size(tDsUs));

    try
        posU = R.posMazeLin(1);
        posData = double(posU.data);
        posT = posData(:,1);
        posDs = interp1(posT, posData(:,2), tDsUs, 'linear', NaN);

        if size(posData,2) >= 4
            velDs = interp1(posT, posData(:,4), tDsUs, 'linear', NaN);
            if isfield(posU, 'unitsPerCm') && isfield(posU, 'unitsPerSecond')
                speedDsCmS = abs(velDs) .* (1/posU.unitsPerCm) .* posU.unitsPerSecond;
            else
                speedDsCmS = abs(velDs);
            end
        end
    catch ME
        fprintf('  Could not interpolate position/speed: %s\n', ME.message);
    end

    validPosition = ~isnan(posDs) & ~isnan(speedDsCmS);
    movingMask = validDs & validPosition & speedDsCmS >= speedThresholdCmS;
    lowSpeedMask = validDs & validPosition & speedDsCmS <= lowSpeedThresholdCmS;

    %% Filter beta2 and ripple bands

    lfpForFiltering = double(lfpDs(:));
    lfpForFiltering(~isfinite(lfpForFiltering)) = median(lfpForFiltering(isfinite(lfpForFiltering)));

    if beta2HighHz >= FsDs/2
        error('Beta2 high frequency exceeds Nyquist after downsampling.');
    end
    if rippleHighHz >= FsDs/2
        error('Ripple high frequency exceeds Nyquist after downsampling. Increase targetFs.');
    end

    [bBeta, aBeta] = butter(filterOrder, [beta2LowHz beta2HighHz] ./ (FsDs/2), 'bandpass');
    beta2Filt = filtfilt(bBeta, aBeta, lfpForFiltering);
    beta2Env = abs(hilbert(beta2Filt));

    betaBase = beta2Env(movingMask & isfinite(beta2Env));
    if numel(betaBase) < 100
        betaBase = beta2Env(validDs & isfinite(beta2Env));
    end
    medBeta = median(betaBase);
    madBeta = median(abs(betaBase - medBeta));
    sigBeta = 1.4826 * madBeta;
    if sigBeta <= 0 || isnan(sigBeta)
        sigBeta = std(betaBase);
    end
    if sigBeta <= 0 || isnan(sigBeta)
        sigBeta = 1;
    end
    beta2Z = (beta2Env - medBeta) ./ sigBeta;

    [bRip, aRip] = butter(filterOrder, [rippleLowHz rippleHighHz] ./ (FsDs/2), 'bandpass');
    rippleFilt = filtfilt(bRip, aRip, lfpForFiltering);
    rippleEnv = abs(hilbert(rippleFilt));

    ripBase = rippleEnv(lowSpeedMask & isfinite(rippleEnv));
    if numel(ripBase) < 100
        ripBase = rippleEnv(validDs & isfinite(rippleEnv));
    end
    medRip = median(ripBase);
    madRip = median(abs(ripBase - medRip));
    sigRip = 1.4826 * madRip;
    if sigRip <= 0 || isnan(sigRip)
        sigRip = std(ripBase);
    end
    if sigRip <= 0 || isnan(sigRip)
        sigRip = 1;
    end
    rippleZ = (rippleEnv - medRip) ./ sigRip;

    %% Choose units for spike raster

    unitList = [];

    if ~isempty(UT) && height(UT) > 0 && any(strcmp(UT.Properties.VariableNames, 'animal')) && any(strcmp(UT.Properties.VariableNames, 'unitIndex'))
        utAnimal = cellstr(UT.animal);
        utMask = strcmp(utAnimal, animalID);

        if any(strcmp(UT.Properties.VariableNames, 'isBeta2Tagged'))
            utMask = utMask & logical(UT.isBeta2Tagged);
        end

        Usub = UT(utMask,:);

        if height(Usub) > 0
            if any(strcmp(Usub.Properties.VariableNames, 'beta2ParticipationFraction'))
                [~, ord] = sort(double(Usub.beta2ParticipationFraction), 'descend');
                Usub = Usub(ord,:);
            elseif any(strcmp(Usub.Properties.VariableNames, 'burstParticipationFraction'))
                [~, ord] = sort(double(Usub.burstParticipationFraction), 'descend');
                Usub = Usub(ord,:);
            end

            unitList = double(Usub.unitIndex);
        end
    end

    if isempty(unitList)
        try
            nUnits = size(R.spEpochSep,1);
            rates = nan(nUnits,1);
            for uu = 1:nUnits
                try
                    rates(uu) = double(R.spEpochSep(uu,2).rate);
                catch
                    rates(uu) = NaN;
                end
            end
            rates(~isfinite(rates)) = -Inf;
            [~, ord] = sort(rates, 'descend');
            unitList = ord(:);
        catch
            unitList = [];
        end
    end

    % Manual stable unique, old-MATLAB friendly.
    unitListClean = [];
    for uu = 1:numel(unitList)
        if ~any(unitListClean == unitList(uu))
            unitListClean(end+1,1) = unitList(uu); %#ok<SAGROW>
        end
    end
    unitList = unitListClean;
    if numel(unitList) > maxUnitsToPlot
        unitList = unitList(1:maxUnitsToPlot);
    end

    %% Plot selected beta2 trace and selected ripple trace

    eventTypes = {'beta2_burst','candidate_awake_ripple'};
    eventPeaks = [betaPeakUs, ripplePeakUs];
    eventStarts = [betaStartUs, rippleStartUs];
    eventEnds = [betaEndUs, rippleEndUs];
    eventPeakZs = [betaPeakZ, ripplePeakZ];
    eventSpeeds = [betaSpeed, rippleSpeed];

    for ev = 1:2

        peakUs = eventPeaks(ev);
        if isnan(peakUs)
            continue;
        end

        eventType = eventTypes{ev};
        winStartUs = peakUs - traceWindowSec*1e6;
        winEndUs = peakUs + traceWindowSec*1e6;

        seg = tDsUs >= winStartUs & tDsUs <= winEndUs;
        if sum(seg) < 20
            fprintf('  Too few samples around %s for %s. Skipping plot.\n', eventType, animalID);
            continue;
        end

        xSec = (tDsUs(seg) - peakUs) ./ 1e6;

        fig = figure('Color','w', 'Position', [100 50 1200 1000], ...
            'Name', [animalID ' ' eventType ' trace QC']);

        % 1. Raw LFP
        subplot(7,1,1);
        plot(xSec, lfpDs(seg).*rawPlotScale, 'k');
        ylabel(rawScaleLabel);
        title(sprintf('%s %s trace QC, peak z = %.2f, speed = %.2f cm/s', ...
            animalID, eventType, eventPeakZs(ev), eventSpeeds(ev)), 'Interpreter','none');
        grid on;
        yl = ylim; line([0 0], yl, 'Color', 'r', 'LineStyle', '--');

        % 2. Beta2 filtered LFP
        subplot(7,1,2);
        plot(xSec, beta2Filt(seg).*rawPlotScale, 'b');
        ylabel('Beta2 filt.');
        grid on;
        yl = ylim; line([0 0], yl, 'Color', 'r', 'LineStyle', '--');

        % 3. Beta2 envelope z
        subplot(7,1,3);
        plot(xSec, beta2Z(seg), 'b');
        hold on;
        line([min(xSec) max(xSec)], [1 1], 'Color', [0.4 0.4 0.4], 'LineStyle', ':');
        line([min(xSec) max(xSec)], [2 2], 'Color', [0.2 0.2 0.2], 'LineStyle', '--');
        ylabel('Beta2 env z');
        grid on;
        yl = ylim; line([0 0], yl, 'Color', 'r', 'LineStyle', '--');
        if ~isnan(eventStarts(ev))
            relS = (eventStarts(ev) - peakUs)/1e6;
            relE = (eventEnds(ev) - peakUs)/1e6;
            yl = ylim;
            line([relS relS], yl, 'Color', [0.6 0.6 0.6], 'LineStyle', ':');
            line([relE relE], yl, 'Color', [0.6 0.6 0.6], 'LineStyle', ':');
        end
        hold off;

        % 4. Ripple filtered LFP
        subplot(7,1,4);
        plot(xSec, rippleFilt(seg).*rawPlotScale, 'k');
        ylabel('Ripple filt.');
        grid on;
        yl = ylim; line([0 0], yl, 'Color', 'r', 'LineStyle', '--');

        % 5. Ripple envelope z
        subplot(7,1,5);
        plot(xSec, rippleZ(seg), 'k');
        hold on;
        line([min(xSec) max(xSec)], [3 3], 'Color', [0.4 0.4 0.4], 'LineStyle', '--');
        ylabel('Ripple env z');
        grid on;
        yl = ylim; line([0 0], yl, 'Color', 'r', 'LineStyle', '--');
        if ~isnan(eventStarts(ev))
            relS = (eventStarts(ev) - peakUs)/1e6;
            relE = (eventEnds(ev) - peakUs)/1e6;
            yl = ylim;
            line([relS relS], yl, 'Color', [0.6 0.6 0.6], 'LineStyle', ':');
            line([relE relE], yl, 'Color', [0.6 0.6 0.6], 'LineStyle', ':');
        end
        hold off;

        % 6. Speed
        subplot(7,1,6);
        plot(xSec, speedDsCmS(seg), 'Color', [0 0.45 0.74]);
        hold on;
        line([min(xSec) max(xSec)], [speedThresholdCmS speedThresholdCmS], 'Color', [0.4 0.4 0.4], 'LineStyle', '--');
        ylabel('Speed cm/s');
        grid on;
        yl = ylim; line([0 0], yl, 'Color', 'r', 'LineStyle', '--');
        hold off;

        % 7. Spike raster
        subplot(7,1,7);
        hold on;
        plotted = 0;
        ytickVals = [];
        ytickLabs = {};

        for uu = 1:numel(unitList)
            unitIdx = unitList(uu);
            spikeTimes = [];

            try
                if isfield(R, 'spEpochSep') && size(R.spEpochSep,1) >= unitIdx && size(R.spEpochSep,2) >= 2 && isfield(R.spEpochSep, 'timeStamps')
                    spikeTimes = double(R.spEpochSep(unitIdx,2).timeStamps(:));
                elseif isfield(R, 'spAll') && size(R.spAll,2) >= unitIdx && isfield(R.spAll, 'timeStamps')
                    spikeTimes = double(R.spAll(unitIdx).timeStamps(:));
                elseif isfield(R, 'spAll') && size(R.spAll,2) >= unitIdx && isfield(R.spAll, 'times')
                    spikeTimes = double(R.spAll(unitIdx).times(:));
                elseif isfield(R, 'spAll') && size(R.spAll,2) >= unitIdx && isfield(R.spAll, 'time')
                    spikeTimes = double(R.spAll(unitIdx).time(:));
                end
            catch
                spikeTimes = [];
            end

            if isempty(spikeTimes)
                continue;
            end

            takeSp = spikeTimes >= winStartUs & spikeTimes <= winEndUs;
            spRel = (spikeTimes(takeSp) - peakUs) ./ 1e6;

            plotted = plotted + 1;
            if ~isempty(spRel)
                plot(spRel, plotted .* ones(size(spRel)), 'k.', 'MarkerSize', 7);
            else
                plot(NaN, NaN, 'k.');
            end

            ytickVals(end+1) = plotted; %#ok<SAGROW>
            ytickLabs{end+1} = sprintf('u%d', unitIdx); %#ok<SAGROW>
        end

        if plotted == 0
            text(0, 0.5, 'No spike timestamps found for selected units', ...
                'HorizontalAlignment', 'center');
            ylim([0 1]);
        else
            ylim([0 plotted+1]);
            set(gca, 'YTick', ytickVals, 'YTickLabel', ytickLabs);
        end

        xlabel('Time from event peak (s)');
        ylabel('Unit spikes');
        grid on;
        yl = ylim; line([0 0], yl, 'Color', 'r', 'LineStyle', '--');
        hold off;

        figFile = fullfile(figDir, sprintf('%s_%s_trace_QC.png', animalID, eventType));
        print(fig, figFile, '-dpng', '-r200');

        selectionRows(end+1,:) = {animalID, i, eventType, peakUs, eventStarts(ev), eventEnds(ev), ...
            eventPeakZs(ev), eventSpeeds(ev), plotted, figFile}; %#ok<SAGROW>

        fprintf('  Saved %s trace plot:\n    %s\n', eventType, figFile);
    end

    close all;
end

%% Save selection table and README

if ~isempty(selectionRows)
    selectionTable = cell2table(selectionRows, 'VariableNames', selectionHeader);
    writetable(selectionTable, fullfile(outDir, 'hc31_batch11A_selected_trace_events.csv'));
end

readmeFile = fullfile(outDir, 'README_hc31_batch11A_event_trace_QC.txt');
fid = fopen(readmeFile, 'w');
fprintf(fid, 'HC-31 Batch 11A event trace QC plots\n');
fprintf(fid, '=====================================\n\n');
fprintf(fid, 'This batch creates example trace plots around selected beta2 bursts and candidate awake ripple events.\n\n');
fprintf(fid, 'Each trace attempts to show raw LFP, beta2-filtered LFP, beta2 envelope z, ripple-filtered LFP, ripple envelope z, speed, and a CA1 unit spike raster.\n\n');
fprintf(fid, 'Beta2 events are selected from hc31_detected_beta_bursts.csv, using non-artifact beta2_23_30Hz events.\n');
fprintf(fid, 'Ripple events are selected from hc31_batch9_candidate_awake_ripples.csv, preferring non-artifact-like, lower-speed, non-extreme peak-z events when available.\n\n');
fprintf(fid, 'The ripple panels are QC only. Candidate ripple detections are algorithmic detections from the ripple-band envelope and are not manually confirmed sharp-wave ripples.\n\n');
fprintf(fid, 'Important limitation: if the spike raster panel is empty, the script could not identify compatible spike timestamp fields for that unit/animal. The LFP trace panels can still be used for detector validation.\n\n');
fprintf(fid, 'Output folder:\n%s\n', outDir);
fclose(fid);

fprintf('\nDone. Batch 11A trace QC outputs saved to:\n  %s\n', outDir);
