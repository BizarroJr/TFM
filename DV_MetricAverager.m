function [preIctalPeriodAverages, ictalPeriodAverages, postIctalPeriodAverages, preIctalWindowsAverages] = DV_MetricAverager( ...
    eegFull, ...
    fs, ...
    totalWindows, ...
    recordingMetrics, ...
    windowSizeSeconds, ...
    overlapSeconds, ...
    preIctalPeriodAverages, ...
    ictalPeriodAverages, ...
    postIctalPeriodAverages, ...
    preIctalWindowsAverages)

%% Fundamental EEG variables extraction

[totalChannels, channelLength] = size(eegFull);
seizureDuration = channelLength / fs;

%% Auxiliary zones extraction

stepSize = windowSizeSeconds - overlapSeconds; % From window start to window start
windowStarts = (0:totalWindows-1) * stepSize;
tickPositions = windowStarts + windowSizeSeconds / 2;

% Establish beginning and end window zones
seizureStartSecond = 60;
seizureEndSecond = channelLength / fs - 10;

% Establish beginning and endings of ictal period
windowsContainingSeizureStart = intersect(tickPositions(windowStarts <= seizureStartSecond), tickPositions(((windowStarts + windowSizeSeconds) >= seizureStartSecond)));
windowsContainingSeizureEnd = tickPositions(((windowStarts + windowSizeSeconds) >= seizureEndSecond));
seizureStartBeginningWindowIndex = windowsContainingSeizureStart(1);
seizureStartEndingWindowIndex = windowsContainingSeizureStart(end);
seizureEndBeginningWindowIndex = windowsContainingSeizureEnd(1);

metricV = recordingMetrics{1};
metricM = recordingMetrics{2};
metricS = recordingMetrics{3};

%% Averaging across patients

% The average is performed across the whole period of time

% Averages of pre-ictal period
averagePreIctalV = mean(metricV(:, 1:seizureStartEndingWindowIndex), 2);
averagePreIctalM = mean(metricM(:, 1:seizureStartEndingWindowIndex), 2);
averagePreIctalS = mean(metricS(:, 1:seizureStartEndingWindowIndex), 2);

preIctalPeriodAverages{1} = [preIctalPeriodAverages{1}, averagePreIctalV];
preIctalPeriodAverages{2} = [preIctalPeriodAverages{2}, averagePreIctalM];
preIctalPeriodAverages{3} = [preIctalPeriodAverages{3}, averagePreIctalS];

% Averages of ictal period
averageIctalV = mean(metricV(:, seizureStartBeginningWindowIndex:seizureEndBeginningWindowIndex), 2);
averageIctalM = mean(metricM(:, seizureStartBeginningWindowIndex:seizureEndBeginningWindowIndex), 2);
averageIctalS = mean(metricS(:, seizureStartBeginningWindowIndex:seizureEndBeginningWindowIndex), 2);

ictalPeriodAverages{1} = [ictalPeriodAverages{1}, averageIctalV];
ictalPeriodAverages{2} = [ictalPeriodAverages{2}, averageIctalM];
ictalPeriodAverages{3} = [ictalPeriodAverages{3}, averageIctalS];

% Averages of post-ictal period
averagePostIctalV = mean(metricV(:, seizureEndBeginningWindowIndex:end), 2);
averagePostIctalM = mean(metricM(:, seizureEndBeginningWindowIndex:end), 2);
averagePostIctalS = mean(metricS(:, seizureEndBeginningWindowIndex:end), 2);

postIctalPeriodAverages{1} = [postIctalPeriodAverages{1}, averagePostIctalV];
postIctalPeriodAverages{2} = [postIctalPeriodAverages{2}, averagePostIctalM];
postIctalPeriodAverages{3} = [postIctalPeriodAverages{3}, averagePostIctalS];

%% Averaging across time

% The average is performed across time windows, preserving them. Only
% suitable for pre-ictal stage where number of windows is always constant

if isempty(preIctalWindowsAverages{1})
    preIctalWindowsAverages{1} = zeros(totalChannels, seizureStartEndingWindowIndex);
    preIctalWindowsAverages{2} = zeros(totalChannels, seizureStartEndingWindowIndex);
    preIctalWindowsAverages{3} = zeros(totalChannels, seizureStartEndingWindowIndex);
end

preIctalWindowsV = metricV(:, 1:seizureStartEndingWindowIndex);
preIctalWindowsM = metricM(:, 1:seizureStartEndingWindowIndex);
preIctalWindowsS = metricS(:, 1:seizureStartEndingWindowIndex);

preIctalWindowsAverages{1} = preIctalWindowsAverages{1} + preIctalWindowsV;
preIctalWindowsAverages{2} = preIctalWindowsAverages{2} + preIctalWindowsM;
preIctalWindowsAverages{3} = preIctalWindowsAverages{3} + preIctalWindowsS;

end