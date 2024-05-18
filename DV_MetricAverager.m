function [preIctalPeriodAverages, ictalPeriodAverages, postIctalPeriodAverages] = DV_MetricAverager( ...
    eegFull, ...
    fs, ...
    totalWindows, ...
    recordingMetrics, ...
    windowSizeSeconds, ...
    overlapSeconds, ...
    preIctalPeriodAverages, ...
    ictalPeriodAverages, ...
    postIctalPeriodAverages)

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

% Filter tick positions and labels based on window start and end times
seizureStartTickPositions = intersect(tickPositions(windowStarts <= seizureStartSecond), tickPositions(((windowStarts + windowSizeSeconds) >= seizureStartSecond)));
seizureEndTickPositions = tickPositions(((windowStarts + windowSizeSeconds) >= seizureEndSecond));
seizureStartBeginningPlotPosition = seizureStartTickPositions(1);
seizureStartEndingPlotPosition = seizureStartTickPositions(end);
seizureEndBeginningPlotPosition = seizureEndTickPositions(1);

%% Averaging

metricV = recordingMetrics{1};
metricM = recordingMetrics{2};
metricS = recordingMetrics{3};

% Averages of pre-ictal period
averagePreIctalV = mean(metricV(:, 1:seizureStartBeginningPlotPosition), 2);
averagePreIctalM = mean(metricM(:, 1:seizureStartBeginningPlotPosition), 2);
averagePreIctalS = mean(metricS(:, 1:seizureStartBeginningPlotPosition), 2);

preIctalPeriodAverages{1} = [preIctalPeriodAverages{1}, averagePreIctalV];
preIctalPeriodAverages{2} = [preIctalPeriodAverages{2}, averagePreIctalM];
preIctalPeriodAverages{3} = [preIctalPeriodAverages{3}, averagePreIctalS];

% Averages of ictal period
averageIctalV = mean(metricV(:, seizureStartBeginningPlotPosition:seizureEndBeginningPlotPosition), 2);
averageIctalM = mean(metricM(:, seizureStartBeginningPlotPosition:seizureEndBeginningPlotPosition), 2);
averageIctalS = mean(metricS(:, seizureStartBeginningPlotPosition:seizureEndBeginningPlotPosition), 2);

ictalPeriodAverages{1} = [ictalPeriodAverages{1}, averageIctalV];
ictalPeriodAverages{2} = [ictalPeriodAverages{2}, averageIctalM];
ictalPeriodAverages{3} = [ictalPeriodAverages{3}, averageIctalS];

% Averages of post-ictal period
averagePostIctalV = mean(metricV(:, seizureEndBeginningPlotPosition:end), 2);
averagePostIctalM = mean(metricM(:, seizureEndBeginningPlotPosition:end), 2);
averagePostIctalS = mean(metricS(:, seizureEndBeginningPlotPosition:end), 2);

postIctalPeriodAverages{1} = [postIctalPeriodAverages{1}, averagePostIctalV];
postIctalPeriodAverages{2} = [postIctalPeriodAverages{2}, averagePostIctalM];
postIctalPeriodAverages{3} = [postIctalPeriodAverages{3}, averagePostIctalS];

end