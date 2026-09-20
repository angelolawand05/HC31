%% HC-31 Batch 11C: peri-event histograms and beta2 phase locking
%
% Plain script version. No local functions.
%
% Purpose:
%   Create validation plots linking CA1 unit spikes to beta2 burst timing.
%
% Outputs:
%   1. Per-animal peri-event spike histograms around beta2 burst peaks.
%   2. Matched non-burst control peri-event histograms.
%   3. Per-animal beta2 phase histograms for spikes occurring inside beta2 burst windows.
%   4. Group summary plots and CSV tables.
%
% Definitions:
%   - Beta2 burst events come from the 23-30 Hz beta2 detector.
%   - A peri-event histogram aligns spike times to beta2 burst peak time = 0.
%   - Control windows are non-burst windows from the same Run1 recording.
%   - Phase locking asks whether unit spikes during beta2 bursts occur at a preferred
%     phase of the 23-30 Hz filtered LFP.
%
% Required:
%   - resSave.mat
%   - csc_files folder
%   - neuralynximport folder with Nlx2MatCSC/readNlxHeader
%   - hc31_detected_beta_bursts.csv
%
% Optional:
%   - hc31_batch10_run1_beta2_unit_tags.csv
%     If found, the script reports beta2-tagged status for units, but it still
%     uses all units with usable Run1 spike timestamps for the main PETH/phase analyses.
%
% Recommended MATLAB workaround:
%
%   clear; clc; close all; rehash;
%   [scriptFile, scriptFolder] = uigetfile('*.m', 'Select hc31_batch11C_PETH_phase_locking_PLAIN_SCRIPT.m');
%   cd(scriptFolder);
%   txt = fileread(fullfile(scriptFolder, scriptFile));
%   eval(txt);

clear; clc; close all; rehash;

fprintf('\nHC-31 Batch 11C: peri-event histograms and beta2 phase locking\n');
fprintf('--------------------------------------------------------------\n');

%% User-editable settings

defaultRoot = getenv('HC31_DATA_ROOT');

animalIndices = 5:9;
fallbackAnimalIDs = {'ANM00190422','ANM204878','ANM212379','ANM228899','ANM228900'};

targetFs = 1000;              % Hz; sufficient for beta2 phase
beta2LowHz = 23;
beta2HighHz = 30;
filterOrder = 4;

speedThresholdCmS = 5;        % used for selecting control windows from valid moving time
pethWindowSec = 0.50;         % peri-event window on each side of event peak
pethBinSec = 0.025;           % 25 ms bins
controlExclusionSec = 0.75;   % control times must be this far from beta2 peaks
maxEventsForPETH = 500;       % keeps script fast; representative evenly spaced subset
minSpikesForPhase = 10;       % minimum spikes in beta2 burst windows for per-unit phase statistics

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

%% Locate beta burst table

burstCsv = '';
burstCandidates = { ...
    fullfile(rootDir, 'beta_burst_over_time_outputs_BETA13_30_FUNC', 'hc31_detected_beta_bursts.csv'), ...
    fullfile(rootDir, 'beta_burst_over_time_outputs_FUNC', 'hc31_detected_beta_bursts.csv'), ...
    fullfile(rootDir, 'allresults', 'beta_burst_over_time_outputs_BETA13_30_FUNC', 'hc31_detected_beta_bursts.csv'), ...
    fullfile(rootDir, 'allresults', 'beta_burst_over_time_outputs_FUNC', 'hc31_detected_beta_bursts.csv'), ...
    fullfile(rootDir, 'hc31_detected_beta_bursts.csv') ...
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

BT = readtable(burstCsv);
fprintf('\nUsing beta burst table:\n  %s\n', burstCsv);

%% Locate optional unit tag table

unitTagCsv = '';
unitTagCandidates = { ...
    fullfile(rootDir, 'hc31_batch10_sleep_replay_memory_link_FORCE_V2', 'hc31_batch10_run1_beta2_unit_tags.csv'), ...
    fullfile(rootDir, 'allresults', 'hc31_batch10_sleep_replay_memory_link_FORCE_V2', 'hc31_batch10_run1_beta2_unit_tags.csv'), ...
    fullfile(rootDir, 'hc31_batch10_run1_beta2_unit_tags.csv') ...
    };

for q = 1:numel(unitTagCandidates)
    if exist(unitTagCandidates{q}, 'file') == 2
        unitTagCsv = unitTagCandidates{q};
        break;
    end
end

if ~isempty(unitTagCsv)
    UT = readtable(unitTagCsv);
    fprintf('Using optional unit tag table:\n  %s\n', unitTagCsv);
else
    UT = table();
    fprintf('No optional unit tag table found. Proceeding with all units with usable Run1 spikes.\n');
end

%% Resolve beta burst columns

btVars = BT.Properties.VariableNames;

animalCol = '';
if any(strcmp(btVars, 'animal')); animalCol = 'animal'; end

bandCol = '';
if any(strcmp(btVars, 'band')); bandCol = 'band'; end

peakCol = '';
peakCandidates = {'burstPeakUs','peakUs','eventPeakUs','peakTimeUs'};
for c = 1:numel(peakCandidates)
    if any(strcmp(btVars, peakCandidates{c}))
        peakCol = peakCandidates{c};
        break;
    end
end

startCol = '';
startCandidates = {'burstStartUs','startUs','eventStartUs'};
for c = 1:numel(startCandidates)
    if any(strcmp(btVars, startCandidates{c}))
        startCol = startCandidates{c};
        break;
    end
end

endCol = '';
endCandidates = {'burstEndUs','endUs','eventEndUs'};
for c = 1:numel(endCandidates)
    if any(strcmp(btVars, endCandidates{c}))
        endCol = endCandidates{c};
        break;
    end
end

if isempty(animalCol) || isempty(bandCol) || isempty(peakCol)
    fprintf('Available beta burst columns:\n');
    disp(btVars');
    error('Could not identify animal, band, and burst peak columns in beta burst table.');
end

%% Output folders

outDir = fullfile(rootDir, 'hc31_batch11C_PETH_phase_locking');
figDir = fullfile(outDir, 'figures');

if exist(outDir, 'dir') ~= 7
    mkdir(outDir);
end
if exist(figDir, 'dir') ~= 7
    mkdir(figDir);
end

%% Storage

pethEdges = -pethWindowSec:pethBinSec:pethWindowSec;
pethCenters = pethEdges(1:end-1) + pethBinSec/2;

allPethRows = {};
pethHeader = {'animal','resSaveIndex','timeFromBeta2PeakSec','burstSpikeRateHzPerUnit','controlSpikeRateHzPerUnit','burstMinusControlHzPerUnit','nEvents','nControls','nUnits'};

animalSummaryRows = {};
animalSummaryHeader = {'animal','resSaveIndex','nUnits','nUnitsWithRun1Spikes','nBeta2EventsTotal','nBeta2EventsUsed','nControlEventsUsed','nSpikesInBurstWindows','animalPhaseMeanVectorLength','animalPhasePreferredRad','animalPhaseRayleighZ','animalPhaseRayleighP','pethFigure','phaseFigure'};

unitPhaseRows = {};
unitPhaseHeader = {'animal','resSaveIndex','unitIndex','isBeta2Tagged','nRun1Spikes','nSpikesInBeta2Windows','phaseMeanVectorLength','preferredPhaseRad','rayleighZ','rayleighP'};

groupBurstPETH = [];
groupControlPETH = [];
groupAnimals = {};

%% Main loop

for ai = 1:numel(animalIndices)

    i = animalIndices(ai);
    R = resSave(i);
    animalID = fallbackAnimalIDs{ai};

    try
        if isfield(R, 'spAll') && ~isempty(R.spAll) && isfield(R.spAll, 'animal')
            animalID = char(R.spAll(1).animal);
        end
    catch
    end

    fprintf('\nProcessing resSave(%d): %s\n', i, animalID);

    %% Run1 interval

    if isfield(R, 'sectInt')
        run1StartUs = min(double(R.sectInt(:)));
        run1EndUs = max(double(R.sectInt(:)));
    else
        fprintf('  No sectInt for %s. Skipping.\n', animalID);
        continue;
    end

    %% Select valid beta2 events

    btAnimal = string(BT.(animalCol));
    btBand = string(BT.(bandCol));

    btMask = btAnimal == string(animalID) & btBand == "beta2_23_30Hz";

    if any(strcmp(btVars, 'excludedAsArtifact'))
        btMask = btMask & ~logical(BT.excludedAsArtifact);
    end

    Bsub = BT(btMask, :);

    if height(Bsub) == 0
        fprintf('  No beta2 events for %s. Skipping.\n', animalID);
        continue;
    end

    betaPeakUs = double(Bsub.(peakCol));
    betaPeakUs = betaPeakUs(isfinite(betaPeakUs));
    betaPeakUs = betaPeakUs(betaPeakUs >= run1StartUs & betaPeakUs <= run1EndUs);
    betaPeakUs = sort(betaPeakUs(:));

    if isempty(betaPeakUs)
        fprintf('  No finite beta2 peak times inside Run1 for %s. Skipping.\n', animalID);
        continue;
    end

    if ~isempty(startCol) && ~isempty(endCol)
        betaStartUsRaw = double(Bsub.(startCol));
        betaEndUsRaw = double(Bsub.(endCol));
        goodRows = isfinite(double(Bsub.(peakCol))) & double(Bsub.(peakCol)) >= run1StartUs & double(Bsub.(peakCol)) <= run1EndUs;
        betaStartUs = betaStartUsRaw(goodRows);
        betaEndUs = betaEndUsRaw(goodRows);
        betaPeakForWindows = double(Bsub.(peakCol));
        betaPeakForWindows = betaPeakForWindows(goodRows);
    else
        betaPeakForWindows = betaPeakUs;
        betaStartUs = betaPeakUs - 75e3;
        betaEndUs = betaPeakUs + 75e3;
    end

    betaStartUs = betaStartUs(:);
    betaEndUs = betaEndUs(:);
    betaPeakForWindows = betaPeakForWindows(:);

    validWin = isfinite(betaStartUs) & isfinite(betaEndUs) & isfinite(betaPeakForWindows) & betaEndUs > betaStartUs;
    betaStartUs = betaStartUs(validWin);
    betaEndUs = betaEndUs(validWin);
    betaPeakForWindows = betaPeakForWindows(validWin);

    nBetaTotal = numel(betaPeakUs);

    % Use representative evenly spaced subset for PETH to avoid over-weighting very dense animals.
    if numel(betaPeakUs) > maxEventsForPETH
        idxPick = round(linspace(1, numel(betaPeakUs), maxEventsForPETH));
        betaPethPeaksUs = betaPeakUs(idxPick);
    else
        betaPethPeaksUs = betaPeakUs;
    end

    %% Get position speed for control windows

    posT = [];
    speedCmS = [];

    try
        posU = R.posMazeLin(1);
        posData = double(posU.data);
        posT = posData(:,1);

        if size(posData,2) >= 4
            vel = posData(:,4);
            if isfield(posU, 'unitsPerCm') && isfield(posU, 'unitsPerSecond')
                speedCmS = abs(vel) .* (1/posU.unitsPerCm) .* posU.unitsPerSecond;
            else
                speedCmS = abs(vel);
            end
        end
    catch
        posT = [];
        speedCmS = [];
    end

    controlPeaksUs = [];

    if ~isempty(posT) && ~isempty(speedCmS)
        ctrlMask = posT >= run1StartUs + pethWindowSec*1e6 & ...
                   posT <= run1EndUs - pethWindowSec*1e6 & ...
                   isfinite(speedCmS) & speedCmS >= speedThresholdCmS;

        candidateCtrl = posT(ctrlMask);
        if ~isempty(candidateCtrl)
            keepCtrl = true(size(candidateCtrl));

            % Exclude times close to beta2 burst peaks.
            % Old-MATLAB-safe loop.
            for cc = 1:numel(candidateCtrl)
                if any(abs(betaPeakUs - candidateCtrl(cc)) <= controlExclusionSec*1e6)
                    keepCtrl(cc) = false;
                end
            end

            candidateCtrl = candidateCtrl(keepCtrl);

            if ~isempty(candidateCtrl)
                nControlsWanted = min(numel(betaPethPeaksUs), numel(candidateCtrl));
                idxCtrl = round(linspace(1, numel(candidateCtrl), nControlsWanted));
                controlPeaksUs = candidateCtrl(idxCtrl);
            end
        end
    end

    if isempty(controlPeaksUs)
        % Fallback: use evenly spaced Run1 times far enough from edges.
        candidateCtrl = linspace(run1StartUs + pethWindowSec*1e6, run1EndUs - pethWindowSec*1e6, max(10, numel(betaPethPeaksUs)*2))';
        keepCtrl = true(size(candidateCtrl));
        for cc = 1:numel(candidateCtrl)
            if any(abs(betaPeakUs - candidateCtrl(cc)) <= controlExclusionSec*1e6)
                keepCtrl(cc) = false;
            end
        end
        candidateCtrl = candidateCtrl(keepCtrl);
        nControlsWanted = min(numel(betaPethPeaksUs), numel(candidateCtrl));
        if nControlsWanted > 0
            idxCtrl = round(linspace(1, numel(candidateCtrl), nControlsWanted));
            controlPeaksUs = candidateCtrl(idxCtrl);
        end
    end

    %% Extract unit spike times

    unitIndices = [];

    if isfield(R, 'spEpochSep')
        try
            unitIndices = (1:size(R.spEpochSep,1))';
        catch
            unitIndices = [];
        end
    end

    if isempty(unitIndices) && isfield(R, 'spAll')
        try
            unitIndices = (1:numel(R.spAll))';
        catch
            unitIndices = [];
        end
    end

    if isempty(unitIndices)
        fprintf('  No unit structure found for %s. Skipping unit PETH/phase.\n', animalID);
        continue;
    end

    nUnits = numel(unitIndices);
    spikeCell = cell(nUnits,1);
    nRun1Spikes = zeros(nUnits,1);
    unitsWithSpikes = false(nUnits,1);

    for uii = 1:nUnits
        unitIdx = unitIndices(uii);
        sp = [];

        try
            if isfield(R, 'spEpochSep') && size(R.spEpochSep,1) >= unitIdx && size(R.spEpochSep,2) >= 2
                if isfield(R.spEpochSep, 'timeStamps')
                    sp = double(R.spEpochSep(unitIdx,2).timeStamps(:));
                elseif isfield(R.spEpochSep, 'timestamps')
                    sp = double(R.spEpochSep(unitIdx,2).timestamps(:));
                elseif isfield(R.spEpochSep, 'times')
                    sp = double(R.spEpochSep(unitIdx,2).times(:));
                elseif isfield(R.spEpochSep, 'time')
                    sp = double(R.spEpochSep(unitIdx,2).time(:));
                end
            end
        catch
            sp = [];
        end

        if isempty(sp)
            try
                if isfield(R, 'spAll') && numel(R.spAll) >= unitIdx
                    if isfield(R.spAll, 'timeStamps')
                        sp = double(R.spAll(unitIdx).timeStamps(:));
                    elseif isfield(R.spAll, 'timestamps')
                        sp = double(R.spAll(unitIdx).timestamps(:));
                    elseif isfield(R.spAll, 'times')
                        sp = double(R.spAll(unitIdx).times(:));
                    elseif isfield(R.spAll, 'time')
                        sp = double(R.spAll(unitIdx).time(:));
                    end
                end
            catch
                sp = [];
            end
        end

        sp = sp(isfinite(sp));
        sp = sp(sp >= run1StartUs & sp <= run1EndUs);
        sp = sort(sp(:));

        spikeCell{uii} = sp;
        nRun1Spikes(uii) = numel(sp);
        unitsWithSpikes(uii) = ~isempty(sp);
    end

    goodUnits = find(unitsWithSpikes);
    nUnitsWithRun1Spikes = numel(goodUnits);

    if nUnitsWithRun1Spikes == 0
        fprintf('  No Run1 spikes found for %s. Skipping.\n', animalID);
        continue;
    end

    %% PETH counts around beta2 peaks and controls

    burstCounts = zeros(1, numel(pethEdges)-1);
    controlCounts = zeros(1, numel(pethEdges)-1);

    nEventsUsed = numel(betaPethPeaksUs);
    nControlsUsed = numel(controlPeaksUs);

    for gu = 1:numel(goodUnits)
        sp = spikeCell{goodUnits(gu)};

        for ev = 1:nEventsUsed
            rel = (sp - betaPethPeaksUs(ev)) ./ 1e6;
            rel = rel(rel >= -pethWindowSec & rel <= pethWindowSec);
            if ~isempty(rel)
                burstCounts = burstCounts + histcounts(rel, pethEdges);
            end
        end

        for ev = 1:nControlsUsed
            rel = (sp - controlPeaksUs(ev)) ./ 1e6;
            rel = rel(rel >= -pethWindowSec & rel <= pethWindowSec);
            if ~isempty(rel)
                controlCounts = controlCounts + histcounts(rel, pethEdges);
            end
        end
    end

    burstRate = burstCounts ./ max(1, (nEventsUsed * nUnitsWithRun1Spikes * pethBinSec));
    controlRate = controlCounts ./ max(1, (nControlsUsed * nUnitsWithRun1Spikes * pethBinSec));
    diffRate = burstRate - controlRate;

    for bb = 1:numel(pethCenters)
        allPethRows(end+1,:) = {animalID, i, pethCenters(bb), burstRate(bb), controlRate(bb), diffRate(bb), nEventsUsed, nControlsUsed, nUnitsWithRun1Spikes}; %#ok<SAGROW>
    end

    groupBurstPETH(end+1,:) = burstRate; %#ok<SAGROW>
    groupControlPETH(end+1,:) = controlRate; %#ok<SAGROW>
    groupAnimals{end+1,1} = animalID; %#ok<SAGROW>

    %% Plot per-animal PETH

    fig = figure('Color','w', 'Position', [100 100 1050 650], 'Name', [animalID ' beta2 PETH']);

    subplot(2,1,1);
    plot(pethCenters, burstRate, 'LineWidth', 2);
    hold on;
    plot(pethCenters, controlRate, 'LineWidth', 2);
    yl = ylim;
    line([0 0], yl, 'Color','k', 'LineStyle','--');
    xlabel('Time from beta2 burst peak or control time (s)');
    ylabel('Spike rate (Hz/unit)');
    title(sprintf('%s: unit peri-event histogram around beta2 burst peaks', animalID), 'Interpreter','none');
    legend({'beta2 burst windows','matched non-burst controls'}, 'Location','best');
    grid on;
    hold off;

    subplot(2,1,2);
    plot(pethCenters, diffRate, 'k', 'LineWidth', 2);
    yl = ylim;
    line([0 0], yl, 'Color',[0.5 0.5 0.5], 'LineStyle','--');
    line([min(pethCenters) max(pethCenters)], [0 0], 'Color',[0.5 0.5 0.5], 'LineStyle',':');
    xlabel('Time from beta2 burst peak (s)');
    ylabel('Burst minus control (Hz/unit)');
    title('Difference curve');
    grid on;

    pethFigFile = fullfile(figDir, [animalID '_beta2_spike_PETH_burst_vs_control.png']);
    print(fig, pethFigFile, '-dpng', '-r200');
    close(fig);

    fprintf('  Saved PETH figure:\n    %s\n', pethFigFile);

    %% Load LFP and compute beta2 phase

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
        [f,p] = uigetfile('*.ncs', ['Select Run1 CSC file for ' animalID]);
        if isequal(f,0)
            fprintf('  No CSC selected for %s. Skipping phase locking.\n', animalID);
            continue;
        end
        cscFile = fullfile(p,f);
    end

    fprintf('  Loading Run1 LFP for beta2 phase...\n');

    try
        [tRec, vRec, header] = Nlx2MatCSC(cscFile, [1 0 0 0 1], 1, 4, [run1StartUs run1EndUs]);
    catch ME
        fprintf('  Could not load Run1 CSC for phase locking: %s\n', ME.message);
        continue;
    end

    tRec = double(tRec(:));
    vRec = double(vRec);
    if isempty(tRec) || isempty(vRec)
        fprintf('  Empty LFP read for %s. Skipping phase locking.\n', animalID);
        continue;
    end

    vallRaw = double(vRec(:));

    try
        H = readNlxHeader(header);
    catch
        H = struct();
    end

    tDiff = diff(tRec);
    mtDiff = mode(tDiff);
    noSkip = tDiff > mtDiff-2 & tDiff < mtDiff+2;

    if all(noSkip)
        FsRaw = 1/(mean(tDiff)/512/1e6);
        tallUs = linspace(tRec(1), tRec(end) + (511*(1/FsRaw)*1e6), numel(vallRaw))';
        vall = vallRaw;
    else
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
        lfp = vall .* H.ADBitVolts;
    else
        lfp = vall;
    end

    validRaw = isfinite(lfp);
    if any(validRaw)
        fillValue = median(lfp(validRaw));
    else
        fillValue = 0;
    end

    lfpFilled = lfp;
    lfpFilled(~validRaw) = fillValue;

    factor = max(1, round(FsRaw / targetFs));
    FsDs = FsRaw / factor;

    if factor > 1
        try
            lfpDs = decimate(lfpFilled, factor);
        catch
            lfpDs = lfpFilled(1:factor:end);
        end
        tDsUs = tallUs(1:factor:end);
    else
        lfpDs = lfpFilled;
        tDsUs = tallUs;
    end

    n = min(numel(lfpDs), numel(tDsUs));
    lfpDs = double(lfpDs(1:n));
    tDsUs = double(tDsUs(1:n));

    if beta2HighHz >= FsDs/2
        fprintf('  Downsampled Fs too low for beta2 phase. Skipping phase locking.\n');
        continue;
    end

    [bBeta, aBeta] = butter(filterOrder, [beta2LowHz beta2HighHz] ./ (FsDs/2), 'bandpass');
    betaFilt = filtfilt(bBeta, aBeta, lfpDs);
    betaPhase = angle(hilbert(betaFilt));

    %% Unit phase locking

    allSpikePhases = [];

    % Optional beta2 tag lookup
    utAnimalCol = '';
    utUnitCol = '';
    utTaggedCol = '';

    if ~isempty(UT) && height(UT) > 0
        utVars = UT.Properties.VariableNames;
        if any(strcmp(utVars, 'animal')); utAnimalCol = 'animal'; end
        if any(strcmp(utVars, 'unitIndex')); utUnitCol = 'unitIndex'; end
        if any(strcmp(utVars, 'isBeta2Tagged')); utTaggedCol = 'isBeta2Tagged'; end
    end

    for gu = 1:numel(goodUnits)

        unitIdx = unitIndices(goodUnits(gu));
        sp = spikeCell{goodUnits(gu)};
        if isempty(sp)
            continue;
        end

        inAnyBurst = false(size(sp));

        for ev = 1:numel(betaStartUs)
            inAnyBurst = inAnyBurst | (sp >= betaStartUs(ev) & sp <= betaEndUs(ev));
        end

        spBurst = sp(inAnyBurst);

        ph = [];
        if ~isempty(spBurst)
            ph = interp1(tDsUs, betaPhase, spBurst, 'nearest', NaN);
            ph = ph(isfinite(ph));
        end

        allSpikePhases = [allSpikePhases; ph(:)]; %#ok<AGROW>

        isTagged = NaN;
        if ~isempty(utAnimalCol) && ~isempty(utUnitCol) && ~isempty(utTaggedCol)
            try
                utMask = string(UT.(utAnimalCol)) == string(animalID) & double(UT.(utUnitCol)) == double(unitIdx);
                if any(utMask)
                    isTagged = double(any(logical(UT.(utTaggedCol)(utMask))));
                end
            catch
                isTagged = NaN;
            end
        end

        nPh = numel(ph);
        if nPh >= minSpikesForPhase
            csum = sum(cos(ph));
            ssum = sum(sin(ph));
            Rsum = sqrt(csum^2 + ssum^2);
            rbar = Rsum / nPh;
            pref = atan2(ssum, csum);
            rayZ = nPh * rbar^2;
            rayP = exp(sqrt(1 + 4*nPh + 4*(nPh^2 - Rsum^2)) - (1 + 2*nPh));
        else
            rbar = NaN;
            pref = NaN;
            rayZ = NaN;
            rayP = NaN;
        end

        unitPhaseRows(end+1,:) = {animalID, i, unitIdx, isTagged, numel(sp), nPh, rbar, pref, rayZ, rayP}; %#ok<SAGROW>
    end

    %% Animal-level phase summary

    nAnimalPhase = numel(allSpikePhases);

    if nAnimalPhase >= minSpikesForPhase
        csum = sum(cos(allSpikePhases));
        ssum = sum(sin(allSpikePhases));
        Rsum = sqrt(csum^2 + ssum^2);
        animalMVL = Rsum / nAnimalPhase;
        animalPref = atan2(ssum, csum);
        animalRayZ = nAnimalPhase * animalMVL^2;
        animalRayP = exp(sqrt(1 + 4*nAnimalPhase + 4*(nAnimalPhase^2 - Rsum^2)) - (1 + 2*nAnimalPhase));
    else
        animalMVL = NaN;
        animalPref = NaN;
        animalRayZ = NaN;
        animalRayP = NaN;
    end

    %% Phase histogram figure

    fig = figure('Color','w', 'Position', [100 100 1100 650], 'Name', [animalID ' beta2 phase locking']);

    subplot(2,1,1);
    if ~isempty(allSpikePhases)
        phaseEdges = linspace(-pi, pi, 25);
        histogram(allSpikePhases, phaseEdges, 'Normalization', 'probability');
        hold on;
        xref = linspace(-pi, pi, 200);
        y = (sin(xref) + 1);
        y = y ./ max(y);
        yl = ylim;
        plot(xref, y .* yl(2) .* 0.35, 'k--', 'LineWidth', 1);
        line([animalPref animalPref], yl, 'Color', 'r', 'LineStyle', '--');
        xlabel('Beta2 phase at spike time (radians)');
        ylabel('Probability');
        title(sprintf('%s: spike phase during beta2 burst windows, MVL = %.3f, Rayleigh p = %.3g', animalID, animalMVL, animalRayP), 'Interpreter','none');
        legend({'spike phase distribution','phase reference','preferred phase'}, 'Location','best');
        grid on;
        hold off;
    else
        text(0.5, 0.5, 'No spikes found inside beta2 burst windows', 'HorizontalAlignment','center');
        axis off;
    end

    subplot(2,1,2);
    % Unit-level MVL scatter.
    if ~isempty(unitPhaseRows)
        tempUnit = [];
        tempMVL = [];
        tempP = [];
        for rr = 1:size(unitPhaseRows,1)
            if strcmp(unitPhaseRows{rr,1}, animalID)
                tempUnit(end+1) = unitPhaseRows{rr,3}; %#ok<SAGROW>
                tempMVL(end+1) = unitPhaseRows{rr,7}; %#ok<SAGROW>
                tempP(end+1) = unitPhaseRows{rr,10}; %#ok<SAGROW>
            end
        end

        validUnit = isfinite(tempMVL);
        if any(validUnit)
            plot(tempUnit(validUnit), tempMVL(validUnit), 'ko', 'MarkerFaceColor', [0.7 0.7 0.7]);
            hold on;
            sig = validUnit & tempP < 0.05;
            if any(sig)
                plot(tempUnit(sig), tempMVL(sig), 'ro', 'MarkerFaceColor', 'r');
            end
            xlabel('Unit index');
            ylabel('Mean vector length');
            title('Per-unit phase-locking strength');
            legend({'units','Rayleigh p < 0.05'}, 'Location','best');
            grid on;
            hold off;
        else
            text(0.5, 0.5, 'No units had enough burst-window spikes for phase statistics', 'HorizontalAlignment','center');
            axis off;
        end
    else
        axis off;
    end

    phaseFigFile = fullfile(figDir, [animalID '_beta2_phase_locking_spike_phase.png']);
    print(fig, phaseFigFile, '-dpng', '-r200');
    close(fig);

    fprintf('  Saved phase-locking figure:\n    %s\n', phaseFigFile);

    animalSummaryRows(end+1,:) = {animalID, i, nUnits, nUnitsWithRun1Spikes, nBetaTotal, nEventsUsed, nControlsUsed, nAnimalPhase, animalMVL, animalPref, animalRayZ, animalRayP, pethFigFile, phaseFigFile}; %#ok<SAGROW>
end

%% Save tables

if ~isempty(allPethRows)
    pethTable = cell2table(allPethRows, 'VariableNames', pethHeader);
    writetable(pethTable, fullfile(outDir, 'hc31_batch11C_peri_event_histogram_by_animal.csv'));
end

if ~isempty(unitPhaseRows)
    unitPhaseTable = cell2table(unitPhaseRows, 'VariableNames', unitPhaseHeader);
    writetable(unitPhaseTable, fullfile(outDir, 'hc31_batch11C_unit_beta2_phase_locking.csv'));
end

if ~isempty(animalSummaryRows)
    animalSummaryTable = cell2table(animalSummaryRows, 'VariableNames', animalSummaryHeader);
    writetable(animalSummaryTable, fullfile(outDir, 'hc31_batch11C_animal_summary.csv'));
end

%% Group summary figures

if ~isempty(groupBurstPETH)

    meanBurst = nanmean(groupBurstPETH, 1);
    meanControl = nanmean(groupControlPETH, 1);
    semBurst = nanstd(groupBurstPETH, 0, 1) ./ sqrt(size(groupBurstPETH,1));
    semControl = nanstd(groupControlPETH, 0, 1) ./ sqrt(size(groupControlPETH,1));

    fig = figure('Color','w', 'Position', [100 100 1050 650], 'Name', 'Group beta2 PETH');

    subplot(2,1,1);
    hold on;
    fill([pethCenters fliplr(pethCenters)], [meanBurst-semBurst fliplr(meanBurst+semBurst)], [0.8 0.8 1], 'EdgeColor','none', 'FaceAlpha', 0.5);
    fill([pethCenters fliplr(pethCenters)], [meanControl-semControl fliplr(meanControl+semControl)], [1 0.85 0.75], 'EdgeColor','none', 'FaceAlpha', 0.5);
    plot(pethCenters, meanBurst, 'b', 'LineWidth', 2);
    plot(pethCenters, meanControl, 'Color', [0.85 0.33 0.1], 'LineWidth', 2);
    yl = ylim;
    line([0 0], yl, 'Color','k', 'LineStyle','--');
    xlabel('Time from beta2 burst peak or control time (s)');
    ylabel('Spike rate (Hz/unit)');
    title('Group mean unit peri-event histogram');
    legend({'burst SEM','control SEM','beta2 burst windows','matched controls'}, 'Location','best');
    grid on;
    hold off;

    subplot(2,1,2);
    diffGroup = groupBurstPETH - groupControlPETH;
    meanDiff = nanmean(diffGroup, 1);
    semDiff = nanstd(diffGroup, 0, 1) ./ sqrt(size(diffGroup,1));
    hold on;
    fill([pethCenters fliplr(pethCenters)], [meanDiff-semDiff fliplr(meanDiff+semDiff)], [0.85 0.85 0.85], 'EdgeColor','none', 'FaceAlpha', 0.5);
    plot(pethCenters, meanDiff, 'k', 'LineWidth', 2);
    yl = ylim;
    line([0 0], yl, 'Color','k', 'LineStyle','--');
    line([min(pethCenters) max(pethCenters)], [0 0], 'Color',[0.5 0.5 0.5], 'LineStyle',':');
    xlabel('Time from beta2 burst peak (s)');
    ylabel('Burst minus control (Hz/unit)');
    title('Group difference curve');
    grid on;
    hold off;

    groupPethFig = fullfile(figDir, 'ALL_ANIMALS_beta2_spike_PETH_group_summary.png');
    print(fig, groupPethFig, '-dpng', '-r200');
    close(fig);
end

if ~isempty(animalSummaryRows)

    mvls = [];
    pvals = [];
    labels = {};
    for rr = 1:size(animalSummaryRows,1)
        labels{end+1} = animalSummaryRows{rr,1}; %#ok<SAGROW>
        mvls(end+1) = animalSummaryRows{rr,9}; %#ok<SAGROW>
        pvals(end+1) = animalSummaryRows{rr,12}; %#ok<SAGROW>
    end

    fig = figure('Color','w', 'Position', [100 100 1000 500], 'Name', 'Animal beta2 phase-locking summary');

    subplot(1,2,1);
    bar(mvls);
    set(gca, 'XTick', 1:numel(labels), 'XTickLabel', labels);
    xtickangle(45);
    ylabel('Animal-level mean vector length');
    title('Spike phase locking to beta2 during burst windows');
    grid on;

    subplot(1,2,2);
    negLogP = -log10(pvals);
    bar(negLogP);
    hold on;
    line([0.5 numel(labels)+0.5], [-log10(0.05) -log10(0.05)], 'Color','r', 'LineStyle','--');
    set(gca, 'XTick', 1:numel(labels), 'XTickLabel', labels);
    xtickangle(45);
    ylabel('-log10 Rayleigh p');
    title('Rayleigh test summary');
    grid on;
    hold off;

    groupPhaseFig = fullfile(figDir, 'ALL_ANIMALS_beta2_phase_locking_summary.png');
    print(fig, groupPhaseFig, '-dpng', '-r200');
    close(fig);
end

%% README

readmeFile = fullfile(outDir, 'README_hc31_batch11C_PETH_phase_locking.txt');
fid = fopen(readmeFile, 'w');
fprintf(fid, 'HC-31 Batch 11C: peri-event histograms and beta2 phase locking\n');
fprintf(fid, '================================================================\n\n');
fprintf(fid, 'Purpose:\n');
fprintf(fid, '- Validate whether CA1 unit spikes are temporally related to beta2 burst timing.\n');
fprintf(fid, '- Create PETH plots around beta2 burst peaks and matched non-burst control times.\n');
fprintf(fid, '- Create phase-locking plots for spikes occurring inside beta2 burst windows.\n\n');
fprintf(fid, 'PETH method:\n');
fprintf(fid, '- Events are valid non-artifact beta2_23_30Hz burst peaks.\n');
fprintf(fid, '- Spikes from all units with usable Run1 spike timestamps are aligned to event time zero.\n');
fprintf(fid, '- Counts are converted to spike rate in Hz per unit.\n');
fprintf(fid, '- Control windows are non-burst windows from valid Run1 moving periods when possible.\n\n');
fprintf(fid, 'Phase-locking method:\n');
fprintf(fid, '- Run1 LFP is filtered in 23-30 Hz.\n');
fprintf(fid, '- Hilbert phase of the beta2-filtered LFP is sampled at spike times.\n');
fprintf(fid, '- Only spikes occurring inside beta2 burst start/end windows are used for phase-locking.\n');
fprintf(fid, '- Mean vector length and an approximate Rayleigh p-value are reported.\n\n');
fprintf(fid, 'Limitations:\n');
fprintf(fid, '- This is an association/validation analysis, not causal evidence.\n');
fprintf(fid, '- High firing units may contribute many spikes to pooled phase histograms.\n');
fprintf(fid, '- Phase-locking estimates are less reliable for units with few spikes inside burst windows.\n');
fprintf(fid, '- Control windows are algorithmically selected and are not perfect behavioural matches.\n\n');
fprintf(fid, 'Output folder:\n%s\n', outDir);
fclose(fid);

fprintf('\nDone. Batch 11C outputs saved to:\n  %s\n', outDir);
