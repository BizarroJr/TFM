function DV_MetricWindowAveragePlotter( ...
    eegFull, ...
    grandAverageWindowsV, ...
    grandAverageWindowsM, ...
    grandAverageWindowsS, ...
    patientId, ...
    filterDescription, ...
    averagedMetricsDirectory, ...
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
grandAveragesV = flip(grandAverageWindowsV);
grandAveragesM = flip(grandAverageWindowsM);
grandAveragesS = flip(grandAverageWindowsS);

%% Plotting grand averages for each metric as colormaps

cmap = 'hot';
periodsToAnalyze = 1; % If variable is 1,2 or 3 it will plot the average of the desired period. If it is 1:2 OR 1:3 it will plot multiple

% Plot for metric V
subplot(3, 1, 1);
imagesc(grandAveragesV);
colormap(cmap);
colorbar;
cbar = colorbar;
cbar.Label.String = 'V';
cbar.Label.FontSize = titlesFontSize;
cbar.Label.Interpreter = interpreter;
set(cbar, 'TickLabelInterpreter', interpreter);
yticks(1:totalChannels);
yticklabels(nameChannel);

% Plot for metric M
subplot(3, 1, 2);
imagesc(grandAveragesM);
colormap(cmap);
colorbar;
cbar = colorbar;
cbar.Label.String = 'M';
cbar.Label.FontSize = titlesFontSize;
cbar.Label.Interpreter = interpreter;
set(cbar, 'TickLabelInterpreter', interpreter);
yticks(1:totalChannels);
yticklabels(nameChannel);

% Plot for metric S
subplot(3, 1, 3);
imagesc(grandAveragesS);
colormap(cmap);
colorbar;
cbar = colorbar;
cbar.Label.String = 'S';
cbar.Label.FontSize = titlesFontSize;
cbar.Label.Interpreter = interpreter;
set(cbar, 'TickLabelInterpreter', interpreter);
yticks(1:totalChannels);
yticklabels(nameChannel);

%% Save figure

% DISCLAIMER: if images are saved in different sizes, DO NOT USE 2 screens,
% for whatever reason, the program fails to recognize the correct size and
% some plots are saved in one size and other in an other.

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
