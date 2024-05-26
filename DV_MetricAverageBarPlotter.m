function DV_MetricAverageBarPlotter( ...
    eegFull, ...
    grandAveragesV, ...
    grandAveragesM, ...
    grandAveragesS, ...
    patientId, ...
    filterDescription, ...
    directoryToSave, ...
    doNotCloseFigure)

%% Gca parameters and set general title of subplots

figHandle = figure('Visible', 'on'); % Change on & off to let the figure be seen 

interpreter = 'latex';
titlesFontSize = 16;
axisFontWeight = 'bold';

set(groot,'defaultAxesTickLabelInterpreter',interpreter);
set(groot,'defaultLegendInterpreter',interpreter);

generalTitle = ['Patient ', num2str(patientId), ', averaged metrics'];
if ~isempty(filterDescription)
    generalTitle = [generalTitle, ' (', filterDescription, ')'];
end

sgtitle(generalTitle, 'Interpreter', interpreter, 'FontWeight', 'bold', 'FontSize', 16);

%% Fundamental EEG variables extraction

[totalChannels, channelLength] = size(eegFull);
nameChannel = cell(1, totalChannels);
for i = 1:totalChannels
    nameChannel{i} = ['ch' num2str(i, '%02d')];
end

% Reverse the order to coincide with the display of the EEG
nameChannel = flip(nameChannel);
grandAveragesV = flip(grandAveragesV);
grandAveragesM = flip(grandAveragesM);
grandAveragesS = flip(grandAveragesS);

%% Plotting grand averages for each metric as barplots

periodsToAnalyze = 1:3; % If variable is 1,2 or 3 it will plot the average of the desired period. If it is 1:2 OR 1:3 it will plot multiple
xticksLabels = {'Pre-Ictal Period', 'Ictal Period', 'Post-Ictal Period'};
colors = [0 1 0; 1 0 0; 0 0 1]; % Green, Red, Blue

periodsToAnalyze = 1:3; % If variable is 1,2 or 3 it will plot the average of the desired period. If it is 1:2 OR 1:3 it will plot multiple

% Generate channel names
totalChannels = size(grandAveragesV, 1);
nameChannel = cell(1, totalChannels);
for i = 1:totalChannels
    nameChannel{i} = ['ch' num2str(i, '%02d')];
end

% Define colors for each period
colors = [0 1 0; 1 0 0; 0 0 1]; % Green, Red, Blue

% Plot for metric V
subplot(3, 1, 1);
data = grandAveragesV(:, periodsToAnalyze)';
b = bar(data, 'grouped');
title('V', 'Interpreter', interpreter, 'FontWeight', axisFontWeight, 'FontSize', titlesFontSize);
set(gca, 'XTickLabel', xticksLabels(periodsToAnalyze));
ylabel('Average Value', 'Interpreter', interpreter, 'FontSize', titlesFontSize);

% Change bar colors
for i = 1:numel(b)
    b(i).FaceColor = 'flat'; 
    b(i).CData = colors; 
end

% Plot for metric M
subplot(3, 1, 2);
barHandles = bar(grandAveragesM(:, periodsToAnalyze)', 'FaceColor', 'flat');
title('M', 'Interpreter', interpreter, 'FontWeight', axisFontWeight, 'FontSize', titlesFontSize);
set(gca, 'XTickLabel', xticksLabels(periodsToAnalyze));
ylabel('Average Value', 'Interpreter', interpreter, 'FontSize', titlesFontSize);

for i = 1:numel(barHandles)
    barHandles(i).FaceColor = 'flat'; 
    barHandles(i).CData = colors; 
end

% Plot for metric S
subplot(3, 1, 3);
barHandles = bar(grandAveragesS(:, periodsToAnalyze)', 'FaceColor', 'flat');
title('S', 'Interpreter', interpreter, 'FontWeight', axisFontWeight, 'FontSize', titlesFontSize);
set(gca, 'XTickLabel', xticksLabels(periodsToAnalyze));
ylabel('Average Value', 'Interpreter', interpreter, 'FontSize', titlesFontSize);

for i = 1:numel(barHandles)
    barHandles(i).FaceColor = 'flat'; 
    barHandles(i).CData = colors; 
end

%% Save figure

originDirectory = pwd;
cd(directoryToSave);

fileTitle = ['AvgMetrics_', filterDescription, '_patient', num2str(patientId), '_periods', num2str(length(periodsToAnalyze))];
imageExtension = '.png';
fullImageFileName = [fileTitle, imageExtension];

% Specify the desired width and height in inches
desiredWidthInches = 16;
desiredHeightInches = 9;

% Set the PaperPosition property of the figure
set(figHandle, 'PaperUnits', 'inches');
set(figHandle, 'PaperSize', [desiredWidthInches, desiredHeightInches]);
set(figHandle, 'PaperPosition', [0, 0, desiredWidthInches, desiredHeightInches]);

% Save the figure as an image
saveas(figHandle, fullImageFileName);
print(fullImageFileName, '-dpng', '-r150'); % Set DPI resolution

cd(originDirectory);

if(~doNotCloseFigure)
    close all
end

end
