% DV_ClimExtractor: Extract and calculate averaged metric limits from EEG data.
%--------------------------------------------------------------------------
% DESCRIPTION:
%   This function extracts and calculates averaged metric limits from EEG
%   data. It processes the EEG data to obtain metric extremes for each
%   recording, then calculates the average of these extremes to derive
%   averaged metric limits.
%
% INPUTS:
%   - dataDirectory: Directory containing EEG data files.
%   - visualizerDirectory: Directory for visualizer scripts.
%   - metricsAndMeasuresDirectory: Directory for EEG metrics and measures.
%   - additionalScriptsDirectory: Directory for additional scripts.
%   - windowSizeSeconds: Size of the analysis window in seconds.
%   - overlapSeconds: Overlap duration between windows in seconds.
%   - filterType: Type of filter to apply (1 = unfiltered, 2 = low-pass filtered, 3 = high-pass filtered).
%   - totalRecordingsToAnalyze: Total number of recordings to analyze.
%   - timeSortedRecordingIds: Sorted list of recording IDs.
%
% OUTPUTS:
%   - averagedMetricLimits: A 1x3 cell array containing the averaged
%     metric limits for each metric analyzed.
% AUTHOR:
%   David Vizcarro Carretero
%--------------------------------------------------------------------------

function [metricLimits, metricsExtremeValuesList] = DV_ClimExtractor( ...
    patientId, ...
    dataDirectory, ...
    visualizerDirectory, ...
    metricsAndMeasuresDirectory, ...
    additionalScriptsDirectory, ...
    windowSizeSeconds, ...
    overlapSeconds, ...
    filterType, ...
    totalRecordingsToAnalyze, ...
    timeSortedRecordingIds)

%% Initialize variables

metricLimits = cell(1,3);
metricsExtremeValuesList = cell(3, totalRecordingsToAnalyze);

%% Obtain limits

for index = 1:totalRecordingsToAnalyze

    %% Definition of basic EEG and processing variables
    cd(dataDirectory)
    seizure = timeSortedRecordingIds(index);
    
    try
        eegData = load(sprintf('Seizure_%03d.mat', seizure));
    catch
        warning(['File ', num2str(seizure), ' does not exist. Skipping to the next iteration.']);
        continue;  % Skips to the next iteration of the loop
    end

    eegFull = eegData.data';
    fs= 400;
    [totalChannels, channelLength] = size(eegFull);
    filteredEegFullCentered = zeros(size(eegFull));

    % Substract the mean to every channel
    channelMeans = mean(eegFull, 2);
    eegFullCentered = eegFull - channelMeans;

    % Filter the channels
    for i = 1:totalChannels
        cd(visualizerDirectory)
        channelData = eegFullCentered(i, :);
        filteredChannel = DV_BandPassFilter(channelData, fs, filterType);
        filteredEegFullCentered(i, :) = filteredChannel;
    end

    % Obtain number of total windows after windowing
    windowSizeSamples = windowSizeSeconds * fs;
    overlapSamples = fs * overlapSeconds;
    totalWindows = floor((length(eegFull(1, :)) - windowSizeSamples) / (windowSizeSamples - overlapSamples)) + 1;

    %% Perform HT of signal and obtain windowed metrics

    cd(metricsAndMeasuresDirectory);
    loadPercentage = (index / length(timeSortedRecordingIds)) * 100;
    % disp(['CLIM EXTRACTOR: Analysis of recording: ', num2str(index), ' out of ', num2str(length(timeSortedRecordingIds)), ' (', num2str(loadPercentage), '%)']);

    channelsV = zeros(totalChannels, totalWindows);
    channelsM = zeros(totalChannels, totalWindows);
    channelsS = zeros(totalChannels, totalWindows);

    for i=1:totalChannels
        hilbertTransform = hilbert(filteredEegFullCentered(i, :));
        metrics = DV_EEGPhaseVelocityAnalyzer(fs, hilbertTransform(1, :), windowSizeSeconds, overlapSeconds);

        channelsV(i, :) = metrics(1, :);
        channelsM(i, :) = metrics(2, :);
        channelsS(i, :) = metrics(3, :);
    end

    for metricToAnalyze = 1:3
        switch (metricToAnalyze)
            case 1
                minMetricV = min(channelsV(:));
                maxMetricV = max(channelsV(:));
                metricsExtremeValuesList{metricToAnalyze, index} = [minMetricV, maxMetricV];
            case 2
                minMetricM = min(channelsM(:));
                maxMetricM = max(channelsM(:));
                metricsExtremeValuesList{metricToAnalyze, index} = [minMetricM, maxMetricM];
            case 3
                minMetricS = min(channelsS(:));
                maxMetricS = max(channelsS(:));
                metricsExtremeValuesList{metricToAnalyze, index} = [minMetricS, maxMetricS];
        end
    end

end

%% Perform average of limits given a metric

for metricToAnalyze = 1:3
    allMinMetrics = zeros(1, numel(metricsExtremeValuesList(metricToAnalyze, :)));
    allMaxMetrics = zeros(1, numel(metricsExtremeValuesList(metricToAnalyze, :)));
    
    for index = 1:length(metricsExtremeValuesList)
        if ~isempty(metricsExtremeValuesList{metricToAnalyze, index})
            allMinMetrics(index) = metricsExtremeValuesList{metricToAnalyze, index}(1);
            allMaxMetrics(index) = metricsExtremeValuesList{metricToAnalyze, index}(2);        
        end
    end

    medianMetricMin = median(allMinMetrics);
    medianMetricMax = median(allMaxMetrics);
    
    metricLimits{metricToAnalyze} = [medianMetricMin, medianMetricMax];
end

formattedStrings = cell(size(metricLimits));
for i = 1:numel(metricLimits)
    formattedStrings{i} = ['[', num2str(round(metricLimits{i}(1), 2)), ' ', num2str(round(metricLimits{i}(2), 2)), ']'];
end
joinedString = strjoin(formattedStrings, ' ');
finalString = ['patientsClims{', num2str(patientId), ', ', num2str(filterType), '} = {', joinedString, '};'];
disp(finalString);

cd(additionalScriptsDirectory)
end