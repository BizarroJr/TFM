clear;
clc;
% close all;

%% User tunable variables
patientId = 11;
seizure = 242;
analysisType = 'clean'; % Either clean or unclean. Unclean will include data with dropouts
windowSizeSeconds = 10; % In seconds
overlapSeconds = 9; % Overlap between windows
filterType = 1; % 1-No filter, 2-LPF, 3-HPF
metricToPlot = 3; % 1-V, 2-M, 3-S
totalNumberOfSubplots = 1; % Number of plots on each file
tickDecimateFactor = 4; % Number of ticks to be removed per plot
orderType = 1; % 1-ascending, 2-descending
doNotCloseFigure = true;

%% Directory parameters definition

switch metricToPlot
    case 1
        metricString = 'V';
    case 2
        metricString = 'M';
    case 3
        metricString = 'S';
    otherwise
        error('Invalid metricToPlot: %d. metricToPlot must be 1, 2, or 3.', metricToPlot);
end

switch filterType
    case 1
        filterDescription = 'NF';
    case 2
        filterDescription = 'LPF';
    case 3
        filterDescription = 'HPF';
    otherwise
        error('Invalid filterType: %d. filterType must be 1, 2, or 3.', filterType);
end

switch(analysisType)
    case('clean')
        patientPlotsFolderName = ['Clean_metric_plots_for_patient_', num2str(patientId)];
    case('unclean')
        patientPlotsFolderName = ['Unclean_metric_plots_for_patient_', num2str(patientId)];
    otherwise
        error('Invalid analysis type. The analysisType must be either ''clean'' or ''unclean''.');
end

switch(orderType)
    case(1)
        patientPlotsFolderName = [patientPlotsFolderName, '_asc'];
    case(2)
        patientPlotsFolderName = [patientPlotsFolderName, '_desc'];
    otherwise
        error('Invalid orderType: %d. orderType must be 1 or 2.', orderType);
end

baseDirectory = "P:\WORK\David\UPF\TFM";
dataDirectory = fullfile(baseDirectory, "Data", "Seizure_Data_" + patientId);
visualizerDirectory = fullfile(baseDirectory, "EEG_visualizer");
metricsAndMeasuresDirectory = fullfile(visualizerDirectory, "Metrics_and_measures");
additionalScriptsDirectory = fullfile(baseDirectory, "TFM_code");
metricsPlotsDirectory = fullfile(additionalScriptsDirectory, "Metrics_plots");
patientPlotsFolderName = [patientPlotsFolderName, '_sp', num2str(totalNumberOfSubplots)];
patientMetricPlotsDirectory = fullfile(metricsPlotsDirectory, patientPlotsFolderName);
savePlotsDirectory = fullfile(patientMetricPlotsDirectory, [filterDescription, '_data']);
selectedMetricDirectory = fullfile(savePlotsDirectory, metricString);


%% Clim definition

totalPatients = 15;
totalFilterTypes = 3;

patientsClims = cell(totalPatients, totalFilterTypes); % patientsClims{patientId, filterType}

% Initialize all cells with a value of -1
for patient = 1:totalPatients
    for filter = 1:totalFilterTypes
        patientsClims{patient, filter} = -1;
    end
end

% Patient 1
patientsClims{1, 1} = {[0.8 3.86] [0.05 0.66] [0.13 0.71]};
patientsClims{1, 2} = {[0.49 1.35] [0.12 0.32] [0.1 0.25]};
patientsClims{1, 3} = {[0.23 0.38] [1.46 1.67] [0.36 0.59]};

% Patient 2
patientsClims{2, 1} = {[1.09 4.27] [0.04 0.35] [0.09 0.55]};
patientsClims{2, 2} = {[0.61 1.38] [0.11 0.27] [0.1 0.24]};
patientsClims{2, 3} = {[0.26 0.37] [1.52 1.68] [0.42 0.58]};

% Patient 3
patientsClims{3, 1} = {[0.83 4.77] [0.06 0.95] [0.13 0.91]};
patientsClims{3, 2} = {[0.56 1.4] [0.1 0.29] [0.09 0.25]};
patientsClims{3, 3} = {[0.24 0.38] [1.42 1.74] [0.37 0.61]};

% Patient 4
patientsClims{4, 1} = {[0.89 3.89] [0.03 0.47] [0.07 0.83]};
patientsClims{4, 2} = {[0.63 1.4] [0.1 0.26] [0.08 0.24]};
patientsClims{4, 3} = {[0.26 0.36] [1.54 1.7] [0.43 0.59]};

% Patient 5 (NO DATA)

% Patient 6 (NO DATA)

% Patient 7
patientsClims{7, 1} = {[0.83 3.67] [0.04 0.61] [0.09 0.63]};
patientsClims{7, 2} = {[0.55 1.35] [0.1 0.32] [0.07 0.24]};
patientsClims{7, 3} = {[0.26 0.38] [1.49 1.68] [0.43 0.6]};

% Patient 8
patientsClims{8, 1} = {[0.79 3.5] [0.06 0.4] [0.13 0.51]};
patientsClims{8, 2} = {[0.46 1.4] [0.11 0.37] [0.09 0.26]};
patientsClims{8, 3} = {[0.26 0.38] [1.5 1.66] [0.43 0.59]};

% Patient 9
patientsClims{9, 1} = {[0.94 3.12] [0.05 0.56] [0.11 0.72]};
patientsClims{9, 2} = {[0.55 1.39] [0.11 0.29] [0.09 0.25]};
patientsClims{9, 3} = {[0.21 0.37] [1.48 1.66] [0.32 0.59]};

% Patient 10
patientsClims{10, 1} = {[0.93 3.41] [0.05 0.36] [0.09 0.51]};
patientsClims{10, 2} = {[0.58 1.39] [0.1 0.3] [0.08 0.25]};
patientsClims{10, 3} = {[0.27 0.38] [1.5 1.67] [0.43 0.6]};

% Patient 11
patientsClims{11, 1} = {[0.86 4.44] [0.04 0.35] [0.12 0.56]};
patientsClims{11, 2} = {[0.55 1.34] [0.12 0.3] [0.09 0.24]};
patientsClims{11, 3} = {[0.26 0.37] [1.44 1.66] [0.41 0.58]};

% Patient 12 (NO DATA)

% Patient 13
patientsClims{13, 1} = {[0.94 4.2] [0.04 0.71] [0.08 0.84]};
patientsClims{13, 2} = {[0.44 1.42] [0.1 0.31] [0.09 0.25]};
patientsClims{13, 3} = {[0.21 0.39] [1.44 1.68] [0.32 0.59]};

% Patient 14 (NO DATA)

% Patient 15
patientsClims{15, 1} = {[0.8 4.88] [0.03 0.39] [0.08 0.66]};
patientsClims{15, 2} = {[0.62 1.47] [0.1 0.26] [0.07 0.26]};
patientsClims{15, 3} = {[0.26 0.38] [1.5 1.69] [0.43 0.6]};

metricsClims = patientsClims{patientId, filterType};

%% METRIC PLOTS

subplotCounter = 0;
channelsMetricList = cell(3, totalNumberOfSubplots); % 3 types of metrics x as many subplots as I may want
eegList = cell(1, totalNumberOfSubplots);
totalWindowsList = zeros(1,totalNumberOfSubplots);
seizureList = zeros(1,totalNumberOfSubplots);
batchNumber = 0;


%% Definition of basic EEG and processing variables
cd(dataDirectory)

try
    eegData = load(sprintf('Seizure_%03d.mat', seizure));
catch
    error(['File ', num2str(seizure), ' does not exist. Skipping to the next iteration.']);
end

eegFull = eegData.data';
fs= 400;
[totalChannels, channelLength] = size(eegFull);
filteredEegFullCentered = zeros(size(eegFull));
eegPhases = zeros(totalChannels, channelLength);
eegPhasesPadded = zeros(size(eegFull));

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

%% Obtain subplots

subplotCounter = subplotCounter + 1;

eegList{subplotCounter} = filteredEegFullCentered;
seizureList(subplotCounter) = seizure;
totalWindowsList(subplotCounter) = totalWindows;
channelsMetricList{1, subplotCounter} = channelsV;
channelsMetricList{2, subplotCounter} = channelsM;
channelsMetricList{3, subplotCounter} = channelsS;

DV_MetricAverager( ...
    eegFull, ...
    totalWindows, ...
    metrics, ...
    windowSizeSeconds, ...
    overlapSeconds)

if subplotCounter == totalNumberOfSubplots || index == length(timeSortedRecordingIds)
    % if subplotCounter == totalNumberOfSubplots || index == testLength
    cd(additionalScriptsDirectory)
    DV_MultiPBMPlotter( ...
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
        filterType, ...
        totalNumberOfSubplots, ...
        tickDecimateFactor, ...
        selectedMetricDirectory, ...
        doNotCloseFigure)

    % Flush values and reset variables
    subplotCounter = 0;
    batchNumber = batchNumber + 1;
    eegList = cell(1, totalNumberOfSubplots);
    channelsMetricList = cell(3, totalNumberOfSubplots);
    totalWindowsList = zeros(1,totalNumberOfSubplots);
    seizureList = zeros(1,totalNumberOfSubplots);
end

