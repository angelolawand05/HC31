function B = hc31_batch11O_extract_beta2_context( ...
    cscFile, centerUs, settings)
% Extract event-centred 23-30 Hz beta2 envelope and burst metrics.

B = struct();
B.complete = false;
B.failureReason = "";
B.effectiveSamplingRateHz = NaN;
B.pethEnvelopeZ = nan(1,numel(settings.beta2PethCenters));
B.preMeanZ = NaN;
B.centralMeanZ = NaN;
B.earlyPostMeanZ = NaN;
B.latePostMeanZ = NaN;
B.postMinusPreZ = NaN;
B.centralMinusPreZ = NaN;
B.preBurstCount = NaN;
B.postBurstCount = NaN;
B.preBurstFraction = NaN;
B.postBurstFraction = NaN;
B.peakEnvelopeZ = NaN;

if exist(cscFile,'file') ~= 2
    B.failureReason = ...
        "CSC file does not exist: " + string(cscFile);
    return
end

loadStartUs = centerUs - ...
    settings.beta2LoadHalfWindowSec*1e6;

loadEndUs = centerUs + ...
    settings.beta2LoadHalfWindowSec*1e6;

try
    [recordTimestamps, sampleFrequencies, ...
        nValidSamples, samples, header] = ...
        Nlx2MatCSC( ...
        cscFile, ...
        [1 0 1 1 1], ...
        1, ...
        4, ...
        [loadStartUs loadEndUs]);
catch ME
    B.failureReason = ...
        "Nlx2MatCSC failed: " + string(ME.message);
    return
end

if isempty(recordTimestamps) || isempty(samples)
    B.failureReason = "No CSC data returned.";
    return
end

recordTimestamps = double(recordTimestamps(:));
samples = double(samples);

rawFs = median(double(sampleFrequencies(:)),'omitnan');

if ~isfinite(rawFs) || rawFs <= 0
    timestampDifferences = diff(recordTimestamps);
    timestampDifferences = timestampDifferences( ...
        isfinite(timestampDifferences) & ...
        timestampDifferences > 0);

    if isempty(timestampDifferences)
        B.failureReason = ...
            "Could not estimate sampling frequency.";
        return
    end

    rawFs = 1/(median(timestampDifferences)/512/1e6);
end

adBitVolts = 1;

for headerIndex = 1:numel(header)
    headerLine = string(header{headerIndex});

    if contains(headerLine,'ADBitVolts', ...
            'IgnoreCase',true)

        numericTokens = regexp( ...
            char(headerLine), ...
            '[-+]?\d*\.?\d+(?:[eE][-+]?\d+)?', ...
            'match');

        if ~isempty(numericTokens)
            candidateScale = ...
                str2double(numericTokens{end});

            if isfinite(candidateScale) && ...
                    candidateScale > 0
                adBitVolts = candidateScale;
            end
        end
    end
end

timeCells = cell(numel(recordTimestamps),1);
lfpCells = cell(numel(recordTimestamps),1);
dtUs = 1e6/rawFs;

for recordIndex = 1:numel(recordTimestamps)
    validCount = 512;

    if ~isempty(nValidSamples)
        validCount = min( ...
            512, ...
            double(nValidSamples(recordIndex)));
    end

    if validCount <= 0
        continue
    end

    timeCells{recordIndex} = ...
        recordTimestamps(recordIndex) + ...
        (0:validCount-1)'*dtUs;

    lfpCells{recordIndex} = ...
        samples(1:validCount,recordIndex) * ...
        adBitVolts * 1e6;
end

timeUs = vertcat(timeCells{:});
lfpUv = vertcat(lfpCells{:});

validMask = ...
    isfinite(timeUs) & ...
    isfinite(lfpUv);

timeUs = timeUs(validMask);
lfpUv = lfpUv(validMask);

if numel(lfpUv) < rawFs
    B.failureReason = ...
        "Insufficient valid samples.";
    return
end

[timeUs,sortOrder] = sort(timeUs);
lfpUv = lfpUv(sortOrder);
[timeUs,uniqueIndex] = unique(timeUs,'stable');
lfpUv = lfpUv(uniqueIndex);

lfpUv = lfpUv - median(lfpUv,'omitnan');

downsampleFactor = max( ...
    1, ...
    round(rawFs/settings.beta2TargetFs));

effectiveFs = rawFs/downsampleFactor;

if downsampleFactor > 1
    try
        lfpDs = decimate(lfpUv,downsampleFactor);

        timeDsUs = linspace( ...
            timeUs(1), ...
            timeUs(end), ...
            numel(lfpDs))';
    catch
        lfpDs = lfpUv(1:downsampleFactor:end);
        timeDsUs = timeUs(1:downsampleFactor:end);
    end
else
    lfpDs = lfpUv;
    timeDsUs = timeUs;
end

nCommon = min(numel(lfpDs),numel(timeDsUs));
lfpDs = double(lfpDs(1:nCommon));
timeDsUs = double(timeDsUs(1:nCommon));

if settings.beta2BandHz(2) >= effectiveFs/2
    B.failureReason = ...
        "Nyquist frequency too low for beta2.";
    return
end

try
    [bBeta2,aBeta2] = butter( ...
        settings.beta2FilterOrder, ...
        settings.beta2BandHz/(effectiveFs/2), ...
        'bandpass');

    beta2Filtered = filtfilt( ...
        bBeta2,aBeta2,lfpDs);
catch ME
    B.failureReason = ...
        "Beta2 filtering failed: " + ...
        string(ME.message);
    return
end

beta2Envelope = abs(hilbert(beta2Filtered));

smoothSamples = max( ...
    1, ...
    round(settings.beta2EnvelopeSmoothSec* ...
    effectiveFs));

beta2Envelope = movmean( ...
    beta2Envelope, ...
    smoothSamples, ...
    'omitnan');

relativeSec = (timeDsUs-centerUs)/1e6;

baselineMask = ...
    abs(relativeSec) >= ...
        settings.beta2BaselineExclusionSec & ...
    abs(relativeSec) <= ...
        settings.beta2LoadHalfWindowSec-0.1 & ...
    isfinite(beta2Envelope);

baselineValues = beta2Envelope(baselineMask);

if numel(baselineValues) < ...
        round(0.5*effectiveFs)
    baselineValues = beta2Envelope( ...
        isfinite(beta2Envelope));
end

baselineMedian = ...
    median(baselineValues,'omitnan');

baselineMad = median( ...
    abs(baselineValues-baselineMedian), ...
    'omitnan');

baselineSigma = 1.4826*baselineMad;

if ~isfinite(baselineSigma) || ...
        baselineSigma <= 0
    baselineSigma = ...
        std(baselineValues,'omitnan');
end

if ~isfinite(baselineSigma) || ...
        baselineSigma <= 0
    baselineSigma = 1;
end

envelopeZ = ...
    (beta2Envelope-baselineMedian) ./ ...
    baselineSigma;

for binIndex = 1:numel(settings.beta2PethCenters)
    binMask = ...
        relativeSec >= ...
            settings.beta2PethEdges(binIndex) & ...
        relativeSec < ...
            settings.beta2PethEdges(binIndex+1);

    if any(binMask)
        B.pethEnvelopeZ(binIndex) = ...
            mean(envelopeZ(binMask),'omitnan');
    end
end

preMask = ...
    relativeSec >= settings.beta2PreWindow(1) & ...
    relativeSec < settings.beta2PreWindow(2);

centralMask = ...
    relativeSec >= settings.beta2CentralWindow(1) & ...
    relativeSec < settings.beta2CentralWindow(2);

earlyPostMask = ...
    relativeSec >= settings.beta2EarlyPostWindow(1) & ...
    relativeSec < settings.beta2EarlyPostWindow(2);

latePostMask = ...
    relativeSec >= settings.beta2LatePostWindow(1) & ...
    relativeSec < settings.beta2LatePostWindow(2);

B.preMeanZ = mean(envelopeZ(preMask),'omitnan');
B.centralMeanZ = mean(envelopeZ(centralMask),'omitnan');
B.earlyPostMeanZ = ...
    mean(envelopeZ(earlyPostMask),'omitnan');
B.latePostMeanZ = ...
    mean(envelopeZ(latePostMask),'omitnan');

B.postMinusPreZ = ...
    B.earlyPostMeanZ-B.preMeanZ;

B.centralMinusPreZ = ...
    B.centralMeanZ-B.preMeanZ;

displayMask = ...
    abs(relativeSec) <= ...
    settings.beta2PethHalfWindowSec;

B.peakEnvelopeZ = ...
    max(envelopeZ(displayMask),[],'omitnan');

aboveThreshold = ...
    envelopeZ >= settings.beta2BurstThresholdZ;

transitions = diff([false;aboveThreshold(:);false]);
burstStarts = find(transitions == 1);
burstEnds = find(transitions == -1)-1;

burstDurations = ...
    (burstEnds-burstStarts+1)/effectiveFs;

validBursts = ...
    burstDurations >= settings.beta2BurstMinDurationSec;

burstStarts = burstStarts(validBursts);
burstEnds = burstEnds(validBursts);

burstPeakTimes = nan(numel(burstStarts),1);

for burstIndex = 1:numel(burstStarts)
    burstRows = ...
        burstStarts(burstIndex):burstEnds(burstIndex);

    [~,relativePeakIndex] = ...
        max(envelopeZ(burstRows));

    peakRow = ...
        burstRows(relativePeakIndex);

    burstPeakTimes(burstIndex) = ...
        relativeSec(peakRow);
end

B.preBurstCount = sum( ...
    burstPeakTimes >= settings.beta2PreWindow(1) & ...
    burstPeakTimes < settings.beta2PreWindow(2));

B.postBurstCount = sum( ...
    burstPeakTimes >= ...
        settings.beta2EarlyPostWindow(1) & ...
    burstPeakTimes < ...
        settings.beta2EarlyPostWindow(2));

B.preBurstFraction = mean( ...
    aboveThreshold(preMask),'omitnan');

B.postBurstFraction = mean( ...
    aboveThreshold(earlyPostMask),'omitnan');

B.complete = true;
B.failureReason = "";
B.effectiveSamplingRateHz = effectiveFs;

end
