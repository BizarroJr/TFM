clc;
clear;
close all;

%% Define paths
baseDirectory = "P:\WORK\David\UPF\TFM";
visualizerDirectory = fullfile(baseDirectory, "EEG_visualizer\");
metricsAndMeasuresDirectory = visualizerDirectory + "Metrics_and_measures";
additionalScriptsDirectory = fullfile(baseDirectory, "TFM_code");

%% Data under analysis

% patientId = "11";
% dataRecord = "53";
% patientId = "11";
% dataRecord = "2";
% patientId = "8";
% dataRecord = "057";
patientId = "11";
dataRecord = "2";

%% Load data
dataDirectory = fullfile(baseDirectory, "Data", "Seizure_Data_" + patientId);
cd(dataDirectory);
fullEeg = load(sprintf('Seizure_%03d.mat', str2double(dataRecord)));
cd(visualizerDirectory);

%% Main program

% Customizable features
secondsToVisualize = inf;
plotColor = 'k';
fontSize = 12;
axisFontSize = 50;
offsetY = 1500;
yTickSpacing = 900; % Value may need changes for different totalChannels
doPlot = 1;

% Preprocess EEG data
fs = 400;
fullEeg = fullEeg.data';
%fullEeg = filter_(fullEeg, fs);

% Define channel names
[M, N] = size(fullEeg);
totalChannels = M;
channelLength = N;
channelNames = cell(1, totalChannels);
for i = 1:totalChannels
    channelNames{i} = ['ch' num2str(i, '%02d')];
end

% Initialize variables
samplesToVisualize = secondsToVisualize * fs;
if(samplesToVisualize > N)
    samplesToVisualize = N;
end
name_channel = channelNames;
names = [];
fs = 400;
time = 0:1/fs:(1/fs) * (size(fullEeg, 2) - 1);
offsetedEeg = offset(fullEeg);
eegToShow= offsetedEeg(:, 1:samplesToVisualize);

%% SANDBOX: CHANNEL AVERAGER

metricV = recordingMetrics{1};
metricM = recordingMetrics{2};
metricS = recordingMetrics{3};

preIctalStage
%% SANDBOX: SPECTROGRAM

%% All in one

% windowSizeSeconds = 10;
% overlapSeconds = 9;
%
% windowLength = windowSizeSeconds * fs;
% overlapLength = overlapSeconds * fs;
%
% % All channels at once
%
% figure;
% for i = 1:size(eegToShow, 1)
%     % Compute spectrogram for the current channel
%     [s, f, t] = spectrogram(eegToShow(i,:), windowLength, overlapLength, [], fs);
%     % Plot spectrogram in the i-th subplot
%     subplot(4, 4, i);
%     surf(t, f, 10*log10(abs(s)), 'EdgeColor', 'none');
%     axis tight;
%     view(0, 90);
%     xlabel('Time (s)');
%     ylabel('Frequency (Hz)');
%     title(['Channel ', num2str(i)]);
%     colorbar;
% end

%% One spectrogram, scrollable, non-shared colorbar

% windowSizeSeconds = 10;
% overlapSeconds = 9;
%
% windowLength = windowSizeSeconds * fs;
% overlapLength = overlapSeconds * fs;
%
% % Initialize index for current channel
% currentChannelIndex = 1;
%
% % Create figure
% fig = figure;
%
% % Set up initial spectrogram plot for the first channel
% [s, f, t] = spectrogram(eegToShow(currentChannelIndex,:), windowLength, overlapLength, [], fs);
% surf(t, f, 10*log10(abs(s)), 'EdgeColor', 'none');
% axis tight;
% view(0, 90);
% xlabel('Time (s)');
% ylabel('Frequency (Hz)');
% title(['Channel ', num2str(currentChannelIndex)]);
% colorbar;
%
% % Wait for arrow key press to move to next or previous channel
% while true
%     % Wait for key press
%     [~, ~, button] = ginput(1);
%
%     % Move to next or previous channel based on arrow key pressed
%     if button == 28 % Left arrow key
%         currentChannelIndex = currentChannelIndex - 1;
%     elseif button == 29 % Right arrow key
%         currentChannelIndex = currentChannelIndex + 1;
%     end
%
%     % Ensure currentChannelIndex stays within bounds
%     currentChannelIndex = mod(currentChannelIndex - 1, size(eegToShow, 1)) + 1;
%
%     % Update spectrogram plot for the new channel
%     [s, f, t] = spectrogram(eegToShow(currentChannelIndex,:), windowLength, overlapLength, [], fs);
%     surf(t, f, 10*log10(abs(s)), 'EdgeColor', 'none');
%     axis tight;
%     view(0, 90);
%     xlabel('Time (s)');
%     ylabel('Frequency (Hz)');
%     title(['Channel ', num2str(currentChannelIndex)]);
%     colorbar;
% end

%% One spectrogram, scrollable, shared colorbar

windowSizeSeconds = 2;
overlapSeconds = 1.5;
colormapColor = 'jet';

windowLength = windowSizeSeconds * fs;
overlapLength = overlapSeconds * fs;

% Initialize a cell array to store spectrograms for all channels
spectrograms = cell(size(eegToShow, 1), 1);

% Create figure
fig = figure;

% Compute spectrograms for all channels
for i = 1:size(eegToShow, 1)
    [s, f, t] = spectrogram(eegToShow(i,:), windowLength, overlapLength, [], fs);
    spectrograms{i} = 10*log10(abs(s)); % Store spectrogram in cell array
end

% Find maximum and minimum values across all spectrograms excluding -Inf and Inf
maxVals = cellfun(@(x) max(x(x < Inf)), spectrograms); % Exclude Inf values
minVals = cellfun(@(x) min(x(x > -Inf)), spectrograms); % Exclude -Inf values
maxVal = max(maxVals);
minVal = min(minVals);

% Establish beginning and end window zones
seizureStartSecond = 60;
seizureEndSecond = channelLength / fs - 10;

% Initialize index for current channel
currentChannelIndex = 1;

% Set up initial spectrogram plot for the first channel
surf(t, f, spectrograms{currentChannelIndex}, 'EdgeColor', 'none');
axis tight;
view(0, 90);
xlabel('Time (s)');
ylabel('Frequency (Hz)');
title(['Channel ', num2str(currentChannelIndex)]);

% Colorbar properties
colormap(colormapColor);
cbar = colorbar;
cbar.Label.String = 'Power (dB)';
clim([minVal, maxVal]);

% Draw vertical lines indicating the beginning and end zones
line([seizureStartSecond, seizureStartSecond], ylim, 'Color', 'g', 'LineWidth', 1.5, 'LineStyle', '--', 'ZData', ones(1,2)*100);
line([seizureEndSecond, seizureEndSecond], ylim, 'Color', 'r', 'LineWidth', 1.5, 'LineStyle', '--', 'ZData', ones(1,2)*100);

cd(additionalScriptsDirectory)

while true
    % Wait for mouse click or key press
    waitforbuttonpress;

    % Get the key pressed
    key = fig.CurrentKey;

    % Move to next or previous channel based on arrow key pressed
    if strcmp(key, 'leftarrow')
        currentChannelIndex = currentChannelIndex - 1;
    elseif strcmp(key, 'rightarrow')
        currentChannelIndex = currentChannelIndex + 1;
    end

    % Ensure currentChannelIndex stays within bounds
    currentChannelIndex = mod(currentChannelIndex - 1, size(eegToShow, 1)) + 1;

    % Update spectrogram plot for the new channel
    surf(t, f, spectrograms{currentChannelIndex}, 'EdgeColor', 'none');
    axis tight;
    view(0, 90);
    xlabel('Time (s)');
    ylabel('Frequency (Hz)');
    title(['Channel ', num2str(currentChannelIndex)]);

    % Draw vertical lines indicating the beginning and end zones
    line([seizureStartSecond, seizureStartSecond], ylim, 'Color', 'g', 'LineWidth', 1.5, 'LineStyle', '--', 'ZData', ones(1,2)*100);
    line([seizureEndSecond, seizureEndSecond], ylim, 'Color', 'r', 'LineWidth', 1.5, 'LineStyle', '--', 'ZData', ones(1,2)*100);

    % Colorbar properties
    colormap(colormapColor);
    cbar = colorbar;
    cbar.Label.String = 'Power (dB)';
    clim([minVal, maxVal]);
end


