function DV_PatientMetricPlotter( ...
    patientId, ...
    seizureList, ...
    batchNumber, ...
    eegList, ...
    fs, ...
    windowSizeSeconds, ...
    totalWindowsList, ...
    overlapSeconds, ...
    channelsMetricList, ...
    metricToPlot, ...
    metricsClims, ...
    filterDescription, ...
    totalNumberOfSubplots, ...
    tickDecimateFactor, ...
    savePlotsDirectory, ...
    doNotCloseFigure)

%% Gca parameters and set general title of subplots

figHandle = figure('Visible', 'off');

interpreter = 'latex';
titlesFontSize = 16;
axisFontWeight = 'bold';

set(groot,'defaultAxesTickLabelInterpreter',interpreter);
set(groot,'defaultTextInterpreter',interpreter); 
set(groot,'defaultLegendInterpreter',interpreter);

generalTitle = ['Patient ', num2str(patientId), ' (', num2str(batchNumber), ')'];
if ~isempty(filterDescription)
    generalTitle = [generalTitle, ' (', filterDescription, ')'];
end

sgtitle(generalTitle, 'Interpreter', interpreter, 'FontWeight', 'bold', 'FontSize', 16);


%% Main plot code

% Check if we are analysing last sequence of recordings. If there are any
% zeros on the list of indexes, it means we are. We discount the amount of
% zeroes to have a nicer subplot in the end.

startPlotId = batchNumber * totalNumberOfSubplots;
lastRecordingSubplots = sum(seizureList == 0);
totalNumberOfSubplots = abs(totalNumberOfSubplots - lastRecordingSubplots);

for currentSubplot = 1:totalNumberOfSubplots

    %% Fundamental EEG variables extraction

    eegFull = eegList{currentSubplot};
    totalWindows = totalWindowsList(currentSubplot);
    seizure = seizureList(currentSubplot);

    [totalChannels, channelLength] = size(eegFull);
    nameChannel = cell(1, totalChannels);
    seizureDuration = channelLength / fs;
    for i = 1:totalChannels
        nameChannel{i} = ['ch' num2str(i, '%02d')];
    end

    % Reverse the order to coincide with the display of the EEG
    nameChannel = flip(nameChannel);
    channelsMetricList = cellfun(@(x) flip(x), channelsMetricList, 'UniformOutput', false);
    analyzedMetric = channelsMetricList{metricToPlot, currentSubplot};
    % analyzedMetric = flipud(channelsMetricList{metricToPlot, currentSubplot});

    stepSize = windowSizeSeconds - overlapSeconds; % From window start to window start
    windowStarts = (0:totalWindows-1) * stepSize;
    tickPositions = windowStarts + windowSizeSeconds / 2;
    tickLabels = cell(1, length(tickPositions));

    for i = 1:length(tickPositions)
        tickLabels{i} = [num2str(windowStarts(i)), ' - ', num2str(windowStarts(i) + windowSizeSeconds)];
    end

    %% Auxiliary zones extraction

    % Establish DANGER zones because of boundary effect
    totalDuration = floor(channelLength / fs);
    boundaryAffectedSeconds = 0.05 * totalDuration;
    beginningBoundaryZone = boundaryAffectedSeconds;

    % The loop searches the amount of windows affected by the boundary effect,
    % since it is simmetrical, the same number of windows are affected at the
    % tail of the signal.
    affectedNumberOfWindows = -1;
    for i = 1:length(windowStarts)
        if windowStarts(i) < beginningBoundaryZone
            affectedNumberOfWindows = i;
        else
            break;
        end
    end

    beginningBoundaryZonePlotPosition = tickPositions(affectedNumberOfWindows);
    endingBoundaryZonePlotPosition = tickPositions(length(windowStarts) - affectedNumberOfWindows + 1);

    % Establish beginning and end window zones
    seizureStartSecond = 60;
    seizureEndSecond = channelLength / fs - 10;

    % Filter tick positions and labels based on window start and end times
    seizureStartTickPositions = intersect(tickPositions(windowStarts <= seizureStartSecond), tickPositions(((windowStarts + windowSizeSeconds) >= seizureStartSecond)));
    seizureEndTickPositions = tickPositions(((windowStarts + windowSizeSeconds) >= seizureEndSecond));
    seizureStartBeginningPlotPosition = seizureStartTickPositions(1);
    seizureStartEndingPlotPosition = seizureStartTickPositions(end);
    seizureEndBeginningPlotPosition = seizureEndTickPositions(1);

    tickPositions = tickPositions(1:tickDecimateFactor:end);
    tickLabels = tickLabels(1:tickDecimateFactor:end);

    %% Subplot definition

    switch metricToPlot
        case 1
            metricString = 'V';
            minMaxValues_V = metricsClims{1};
            minValue = minMaxValues_V(1);
            maxValue = minMaxValues_V(2);
        case 2
            metricString = 'M';
            minMaxValues_M = metricsClims{2};
            minValue = minMaxValues_M(1);
            maxValue = minMaxValues_M(2);
        case 3
            metricString = 'S';
            minMaxValues_S = metricsClims{3};
            minValue = minMaxValues_S(1);
            maxValue = minMaxValues_S(2);
        otherwise
            metricString = ''; % Default case
            minValue = 0;
            maxValue = 1;
    end

    subplot(totalNumberOfSubplots, 1, currentSubplot);
    imagesc(tickPositions, 1:totalChannels, analyzedMetric);
    xlabel('Time (s)', 'Interpreter', interpreter, 'FontWeight', axisFontWeight, 'FontSize', titlesFontSize);
    ylabel('Channel', 'Interpreter', interpreter, 'FontWeight', axisFontWeight, 'FontSize', titlesFontSize);
    yticks(1:totalChannels);
    yticklabels(nameChannel);
    set(gca, 'XTick', tickPositions, 'XTickLabel', tickLabels);
    cbar = colorbar;
    cbar.Label.String = metricString;
    cbar.Label.FontSize = titlesFontSize;
    cbar.Label.Interpreter = interpreter;
    set(cbar, 'TickLabelInterpreter', interpreter);

    currenPlotId = startPlotId + currentSubplot;

    title([num2str(currenPlotId - 1), '. Seizure ', num2str(seizure), ', duration ', num2str(round(seizureDuration, 2))], 'Interpreter', interpreter, 'FontWeight', axisFontWeight, 'FontSize', titlesFontSize);
    colormap('hot');
    clim(gca, [minValue, maxValue]);

    % Draw areas delimiting the boundary zones
    hold on;

    ylim_current = get(gca, 'YLim');
    xlim_current = get(gca, 'XLim');

    % For the beginning boundary zone
    x1_begin = 0;
    x2_begin = beginningBoundaryZonePlotPosition;
    x1_end = endingBoundaryZonePlotPosition;
    x2_end = xlim_current(2);
    y1 = ylim_current(1);
    y2 = ylim_current(2);
    rectangle('Position', [x1_begin, y1, x2_begin-x1_begin, y2-y1], ...
        'FaceColor', [0.8 0.8 0.8], 'EdgeColor', 'none', 'FaceAlpha', 0.3);
    line([beginningBoundaryZonePlotPosition beginningBoundaryZonePlotPosition], ylim_current, ...
        'Color',  [0 0.447 0.741], 'LineStyle', '--', 'LineWidth', 2);

    % For the ending boundary zone
    rectangle('Position', [x1_end, y1, x2_end-x1_end, y2-y1], ...
        'FaceColor', [0.8 0.8 0.8], 'EdgeColor', 'none', 'FaceAlpha', 0.3);
    line([endingBoundaryZonePlotPosition endingBoundaryZonePlotPosition], ylim_current, ...
        'Color',  [0 0.447 0.741], 'LineStyle', '--', 'LineWidth', 2);

    % Draw areas delimiting the start and end of seizure
    line([seizureStartBeginningPlotPosition seizureStartBeginningPlotPosition], ylim, 'Color',  "g", 'LineStyle', ':','LineWidth', 1.5); % Seizure start beginning
    line([seizureStartEndingPlotPosition seizureStartEndingPlotPosition], ylim, 'Color',  "g", 'LineStyle', ':','LineWidth', 1.5); % Seizure start ending
    line([seizureEndBeginningPlotPosition seizureEndBeginningPlotPosition], ylim, 'Color',  "m", 'LineStyle', ':', 'LineWidth', 1.5); % Seizure end

    hold off;
end

%% Save figure

originDirectory = pwd;
cd(savePlotsDirectory);

% figHandle = gcf;
batchNumberStr = sprintf('%03d', batchNumber);

fileTitle = [metricString, '_', filterDescription, '_patient', num2str(patientId), '_batch', batchNumberStr, '_rec', num2str(seizureList)];

figExtension = '.mat';
imageExtension = '.png';

fullFigFileName = [fileTitle, figExtension];
fullImageFileName = [fileTitle, imageExtension];

% Specify the desired width and height in inches
desiredWidthInches = 16;   % Width of the image
desiredHeightInches = 9;   % Height of the image

% Set the PaperPosition property of the figure
set(figHandle, 'PaperUnits', 'inches');
set(figHandle, 'PaperSize', [desiredWidthInches, desiredHeightInches]);
set(figHandle, 'PaperPosition', [0, 0, desiredWidthInches, desiredHeightInches]);

% Save the figure as an image
saveas(figHandle, fullImageFileName);
print(fullImageFileName, '-dpng', '-r150'); % Set DPI resolution

% Save the figure as a mat
figHandle = gcf;
save(fullFigFileName, 'figHandle');

cd(originDirectory);

if(~doNotCloseFigure)
    close all
end

end