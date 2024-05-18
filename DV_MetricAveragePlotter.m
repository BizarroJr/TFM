function DV_MetricAveragePlotter( ...
    eegFull, ...
    grandAveragesV, ...
    grandAveragesM, ...
    grandAveragesS, ...
    patientId, ...
    filterDescription, ...
    patientMetricPlotsDirectory, ...
    doNotCloseFigure)

%% Gca parameters and set general title of subplots

figHandle = figure('Visible', 'off'); % Change on & off to let the figure be seen 

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

%% Plotting grand averages for each metric as colormaps

cmap = 'hot';
periodsToAnalyze = 1;
xticksLabels = {'Pre-Ictal Period', 'Ictal Period', 'Post-Ictal Period'};
middleTick = periodsToAnalyze;

% Plot for metric V
subplot(3, 1, 1);
imagesc(grandAveragesV(:, periodsToAnalyze));
colormap(cmap);
colorbar;
cbar = colorbar;
cbar.Label.String = 'V';
cbar.Label.FontSize = titlesFontSize;
cbar.Label.Interpreter = interpreter;
set(cbar, 'TickLabelInterpreter', interpreter);
yticks(1:totalChannels);
yticklabels(nameChannel);
xticks(middleTick);
xticklabels(xticksLabels);

% Plot for metric M
subplot(3, 1, 2);
imagesc(grandAveragesM(:, periodsToAnalyze));
colormap(cmap);
colorbar;
cbar = colorbar;
cbar.Label.String = 'M';
cbar.Label.FontSize = titlesFontSize;
cbar.Label.Interpreter = interpreter;
set(cbar, 'TickLabelInterpreter', interpreter);
yticks(1:totalChannels);
yticklabels(nameChannel);
xticks(middleTick);
xticklabels(xticksLabels);

% Plot for metric S
subplot(3, 1, 3);
imagesc(grandAveragesS(:, periodsToAnalyze));
colormap(cmap);
colorbar;
cbar = colorbar;
cbar.Label.String = 'S';
cbar.Label.FontSize = titlesFontSize;
cbar.Label.Interpreter = interpreter;
set(cbar, 'TickLabelInterpreter', interpreter);
yticks(1:totalChannels);
yticklabels(nameChannel);
xticks(middleTick);
xticklabels(xticksLabels);

%% Save figure

originDirectory = pwd;
cd(patientMetricPlotsDirectory);

fileTitle = ['AvgMetrics_', filterDescription, '_patient', num2str(patientId), '_periods', num2str(length(periodsToAnalyze))];
imageExtension = '.png';
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
print(fullImageFileName, '-dpng', '-r300'); % 300 DPI resolution

cd(originDirectory);

if(~doNotCloseFigure)
    close all
end

end
