function DV_PatientMetricAnalyzer( ...
    patientId, ...
    analysisType, ...
    windowSizeSeconds, ...
    overlapSeconds, ...
    filterType, ...
    metricToPlot, ...
    totalNumberOfSubplots, ...
    tickDecimateFactor, ...
    orderType, ...
    lowContrast, ...
    obtainExtremeValues, ...
    savePlots, ...
    saveVideo, ...
    averageMetrics, ...
    doNotCloseFigure, ...
    storeInHardDrive)

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
    case 4
        filterDescription = 'MPF';
    otherwise
        error('Invalid filterType: %d. filterType does not exist.', filterType);
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
hardDriveDirectory = "E:\";
dataDirectory = fullfile(baseDirectory, "Data", "Seizure_Data_" + patientId);
visualizerDirectory = fullfile(baseDirectory, "EEG_visualizer");
metricsAndMeasuresDirectory = fullfile(visualizerDirectory, "Metrics_and_measures");
additionalScriptsDirectory = fullfile(baseDirectory, "TFM_code");

if(storeInHardDrive)
    metricsPlotsDirectory = fullfile(hardDriveDirectory, "Metrics_plots");
else
    metricsPlotsDirectory = fullfile(additionalScriptsDirectory, "Metrics_plots");
end

patientPlotsFolderName = [patientPlotsFolderName, '_sp', num2str(totalNumberOfSubplots)];
rawMetricFolderName = 'Raw_metrics';
metricsPlotsFolderName = 'Metrics_plots';
filterFolderName = [filterDescription, '_data'];
videosFolderName = 'Videos';
averagedMetricsFolderName = 'Averaged_metrics';

patientMetricPlotsDirectory = fullfile(metricsPlotsDirectory, patientPlotsFolderName);
savePlotsDirectory = fullfile(patientMetricPlotsDirectory, filterFolderName);
selectedMetricDirectory = fullfile(savePlotsDirectory, metricString);
rawMetricDirectory = fullfile(savePlotsDirectory, rawMetricFolderName);
videosDirectory = fullfile(patientMetricPlotsDirectory, videosFolderName);
averagedMetricsDirectory = fullfile(patientMetricPlotsDirectory, averagedMetricsFolderName);

%% Folder creation

cd(additionalScriptsDirectory)

DV_CheckAndCreateFolder(metricsPlotsFolderName, hardDriveDirectory, additionalScriptsDirectory);
DV_CheckAndCreateFolder(patientPlotsFolderName, metricsPlotsDirectory, additionalScriptsDirectory);
DV_CheckAndCreateFolder(videosFolderName, patientMetricPlotsDirectory, additionalScriptsDirectory);
DV_CheckAndCreateFolder(averagedMetricsFolderName, patientMetricPlotsDirectory, additionalScriptsDirectory);
DV_CheckAndCreateFolder(filterFolderName, patientMetricPlotsDirectory, additionalScriptsDirectory);
DV_CheckAndCreateFolder(metricString, savePlotsDirectory, additionalScriptsDirectory);
DV_CheckAndCreateFolder(rawMetricFolderName, savePlotsDirectory, additionalScriptsDirectory);

%% Retrieve artifact diagnostics data and sort it

cd(dataDirectory);
fileToFindRegex = ['Artifact_diagnostics_of_patient_', num2str(patientId), '.xlsx'];
files = dir(fullfile(dataDirectory, '*.xlsx'));
matching_files = {};

for i = 1:length(files)
    filename = files(i).name;
    if ~isempty(regexp(filename, fileToFindRegex, 'once'))
        matching_files{end+1} = filename;
        artifactData = readmatrix(fullfile(dataDirectory, filename));
    end
end

% Provide artifact data the seizure identifier

numRows = size(artifactData, 1);
artifactData = [transpose(1:numRows), artifactData];

% Sort by descending time and remove dropout & flatline affected recordings if
% necessary

switch(orderType)
    case(1)
        timeSortedArtifactData = sortrows(artifactData, 2, 'ascend');
    case(2)
        timeSortedArtifactData = sortrows(artifactData, 2, 'descend');
    otherwise
        error('Invalid orderType: %d. orderType must be 1 or 2.', orderType);
end

if strcmp(analysisType, 'clean')
    timeSortedArtifactData = timeSortedArtifactData(timeSortedArtifactData(:, 3) == 0, :); % Remove dropouts
    timeSortedArtifactData = timeSortedArtifactData(timeSortedArtifactData(:, 6) == 0, :); % Remove flatlines
end

totalRecordingsToAnalyze = length(timeSortedArtifactData);
timeSortedRecordingIds = timeSortedArtifactData(:, 1);
averageRecordingDuration = mean(timeSortedArtifactData(:, 2));

% disp(['Patient: ', num2str(patientId), ' (', filterDescription, ' - ', metricString, ') - Average recording duration: ', num2str(averageRecordingDuration)]);
disp(['Patient: ', num2str(patientId), ' (', filterDescription, ' - ', metricString, ')']);

%% Obtain Clims
% To be able to compare between recordings of a patient, color limits of
% the heatmap have to be manually established to remain constant across
% recordings in the same metric.

if(obtainExtremeValues)
    cd(additionalScriptsDirectory)
    [metricLimits, metricsExtremeValuesList] = DV_ClimExtractor( ...
        patientId, ...
        dataDirectory, ...
        additionalScriptsDirectory, ...
        metricsAndMeasuresDirectory, ...
        additionalScriptsDirectory, ...
        windowSizeSeconds, ...
        overlapSeconds, ...
        filterType, ...
        totalRecordingsToAnalyze, ...
        timeSortedRecordingIds);
end

%% Clim definition
totalPatients = 15;
totalFilterTypes = 4;

patientsClims = cell(totalPatients, totalFilterTypes); % patientsClims{patientId, filterType}

% Initialize all cells with a value of -1
for patient = 1:totalPatients
    for filter = 1:totalFilterTypes
        patientsClims{patient, filter} = -1;
    end
end

%% TO DELETE
% % Patient 1
% patientsClims{1, 1} = {[0.8 3.86] [0.05 0.66] [0.13 0.71]};
% patientsClims{1, 2} = {[0.49 1.35] [0.12 0.32] [0.1 0.25]};
% patientsClims{1, 3} = {[0.23 0.38] [1.46 1.67] [0.36 0.59]};
% 
% % Patient 2
% patientsClims{2, 1} = {[1.09 4.27] [0.04 0.35] [0.09 0.55]};
% patientsClims{2, 2} = {[0.61 1.38] [0.11 0.27] [0.1 0.24]};
% patientsClims{2, 3} = {[0.26 0.37] [1.52 1.68] [0.42 0.58]};
% 
% % Patient 3
% patientsClims{3, 1} = {[0.83 4.77] [0.06 0.95] [0.13 0.91]};
% patientsClims{3, 2} = {[0.56 1.4] [0.1 0.29] [0.09 0.25]};
% patientsClims{3, 3} = {[0.24 0.38] [1.42 1.74] [0.37 0.61]};
% 
% % Patient 4
% patientsClims{4, 1} = {[0.89 3.89] [0.03 0.47] [0.07 0.83]};
% patientsClims{4, 2} = {[0.63 1.4] [0.1 0.26] [0.08 0.24]};
% patientsClims{4, 3} = {[0.26 0.36] [1.54 1.7] [0.43 0.59]};
% 
% % Patient 5 (NO DATA)
% 
% % Patient 6 (NO DATA)
% 
% % Patient 7
% patientsClims{7, 1} = {[0.83 3.67] [0.04 0.61] [0.09 0.63]};
% patientsClims{7, 2} = {[0.55 1.35] [0.1 0.32] [0.07 0.24]};
% patientsClims{7, 3} = {[0.26 0.38] [1.49 1.68] [0.43 0.6]};
% 
% % Patient 8
% patientsClims{8, 1} = {[0.79 3.5] [0.06 0.4] [0.13 0.51]};
% patientsClims{8, 2} = {[0.46 1.4] [0.11 0.37] [0.09 0.26]};
% patientsClims{8, 3} = {[0.26 0.38] [1.5 1.66] [0.43 0.59]};
% 
% % Patient 9
% patientsClims{9, 1} = {[0.94 3.12] [0.05 0.56] [0.11 0.72]};
% patientsClims{9, 2} = {[0.55 1.39] [0.11 0.29] [0.09 0.25]};
% patientsClims{9, 3} = {[0.21 0.37] [1.48 1.66] [0.32 0.59]};
% 
% % Patient 10
% patientsClims{10, 1} = {[0.93 3.41] [0.05 0.36] [0.09 0.51]};
% patientsClims{10, 2} = {[0.58 1.39] [0.1 0.3] [0.08 0.25]};
% patientsClims{10, 3} = {[0.27 0.38] [1.5 1.67] [0.43 0.6]};
% 
% % Patient 11
% patientsClims{11, 1} = {[0.86 4.44] [0.04 0.35] [0.12 0.56]};
% patientsClims{11, 2} = {[0.55 1.34] [0.12 0.3] [0.09 0.24]};
% patientsClims{11, 3} = {[0.26 0.37] [1.44 1.66] [0.41 0.58]};
% 
% % Patient 12 (NO DATA)
% 
% % Patient 13
% patientsClims{13, 1} = {[0.94 4.2] [0.04 0.71] [0.08 0.84]};
% patientsClims{13, 2} = {[0.44 1.42] [0.1 0.31] [0.09 0.25]};
% patientsClims{13, 3} = {[0.21 0.39] [1.44 1.68] [0.32 0.59]};
% 
% % Patient 14 (NO DATA)
% 
% % Patient 15
% patientsClims{15, 1} = {[0.8 4.88] [0.03 0.39] [0.08 0.66]};
% patientsClims{15, 2} = {[0.62 1.47] [0.1 0.26] [0.07 0.26]};
% patientsClims{15, 3} = {[0.26 0.38] [1.5 1.69] [0.43 0.6]};

%%

switch(filterDescription)
    case 'NF'

        % No Filter data
        patientsClims{1, 1} = {[0.8 3.86] [0.05 0.66] [0.13 0.71]};
        patientsClims{2, 1} = {[1.09 4.27] [0.04 0.35] [0.09 0.55]};
        patientsClims{3, 1} = {[0.83 4.77] [0.06 0.95] [0.13 0.91]};
        patientsClims{4, 1} = {[0.89 3.89] [0.03 0.47] [0.07 0.83]};
        patientsClims{7, 1} = {[0.83 3.67] [0.04 0.61] [0.09 0.63]};
        patientsClims{8, 1} = {[0.79 3.5] [0.06 0.4] [0.13 0.51]};
        patientsClims{9, 1} = {[0.94 3.12] [0.05 0.56] [0.11 0.72]};
        patientsClims{10, 1} = {[0.93 3.41] [0.05 0.36] [0.09 0.51]};
        patientsClims{11, 1} = {[0.86 4.44] [0.04 0.35] [0.12 0.56]};
        patientsClims{13, 1} = {[0.94 4.2] [0.04 0.71] [0.08 0.84]};
        patientsClims{15, 1} = {[0.8 4.88] [0.03 0.39] [0.08 0.66]};

    case 'LPF'

        % Low-Pass Filter data
        patientsClims{1, 2} = {[0.49 1.35] [0.12 0.32] [0.1 0.25]};
        patientsClims{2, 2} = {[0.61 1.38] [0.11 0.27] [0.1 0.24]};
        patientsClims{3, 2} = {[0.56 1.4] [0.1 0.29] [0.09 0.25]};
        patientsClims{4, 2} = {[0.63 1.4] [0.1 0.26] [0.08 0.24]};
        patientsClims{7, 2} = {[0.55 1.35] [0.1 0.32] [0.07 0.24]};
        patientsClims{8, 2} = {[0.46 1.4] [0.11 0.37] [0.09 0.26]};
        patientsClims{9, 2} = {[0.55 1.39] [0.11 0.29] [0.09 0.25]};
        patientsClims{10, 2} = {[0.58 1.39] [0.1 0.3] [0.08 0.25]};
        patientsClims{11, 2} = {[0.55 1.34] [0.12 0.3] [0.09 0.24]};
        patientsClims{13, 2} = {[0.44 1.42] [0.1 0.31] [0.09 0.25]};
        patientsClims{15, 2} = {[0.62 1.47] [0.1 0.26] [0.07 0.26]};
        
    case 'HPF'

        % High-Pass Filter data
        patientsClims{1, 3} = {[0.23 0.38] [1.46 1.67] [0.36 0.59]};
        patientsClims{2, 3} = {[0.26 0.37] [1.52 1.68] [0.42 0.58]};
        patientsClims{3, 3} = {[0.24 0.38] [1.42 1.74] [0.37 0.61]};
        patientsClims{4, 3} = {[0.26 0.36] [1.54 1.7] [0.43 0.59]};
        patientsClims{7, 3} = {[0.26 0.38] [1.49 1.68] [0.43 0.6]};
        patientsClims{8, 3} = {[0.26 0.38] [1.5 1.66] [0.43 0.59]};
        patientsClims{9, 3} = {[0.21 0.37] [1.48 1.66] [0.32 0.59]};
        patientsClims{10, 3} = {[0.27 0.38] [1.5 1.67] [0.43 0.6]};
        patientsClims{11, 3} = {[0.26 0.37] [1.44 1.66] [0.41 0.58]};
        patientsClims{13, 3} = {[0.21 0.39] [1.44 1.68] [0.32 0.59]};
        patientsClims{15, 3} = {[0.26 0.38] [1.5 1.69] [0.43 0.6]};

    case 'MPF'
        
        % Mid-Pass Filter Data
        patientsClims{1, 4} = {[0.18 0.39] [0.76 0.99] [0.15 0.33]};
        patientsClims{2, 4} = {[0.24 0.38] [0.81 0.92] [0.21 0.32]};
        patientsClims{3, 4} = {[0.19 0.42] [0.89 1.13] [0.2 0.38]};
        patientsClims{4, 4} = {[0.25 0.39] [0.8 0.93] [0.2 0.33]};
        patientsClims{7, 4} = {[0.18 0.37] [0.79 0.99] [0.17 0.32]};
        patientsClims{8, 4} = {[0.24 0.37] [0.83 0.93] [0.21 0.32]};
        patientsClims{9, 4} = {[0.25 0.38] [0.8 0.9] [0.21 0.32]};
        patientsClims{10, 4} = {[0.22 0.37] [0.79 0.93] [0.19 0.32]};
        patientsClims{11, 4} = {[0.24 0.37] [0.82 0.94] [0.21 0.32]};
        patientsClims{13, 4} = {[0.19 0.38] [0.79 0.98] [0.18 0.32]};
        patientsClims{15, 4} = {[0.23 0.41] [0.77 0.94] [0.21 0.33]};

    case 'HPF2' 

        % Alternative HPF [90, 130] Hz
        patientsClims{1, 3} = {[0.2 0.34] [1.46 1.64] [0.31 0.51]}; 
        patientsClims{2, 3} = {[0.23 0.33] [1.52 1.65] [0.36 0.52]};
        patientsClims{3, 3} = {[0.21 0.33] [1.42 1.69] [0.32 0.52]};
        patientsClims{4, 3} = {[0.22 0.33] [1.54 1.66] [0.36 0.52]};
        patientsClims{7, 3} = {[0.23 0.34] [1.5 1.65] [0.37 0.52]}; 
        patientsClims{8, 3} = {[0.23 0.34] [1.5 1.63] [0.36 0.52]};
        patientsClims{9, 3} = {[0.19 0.33] [1.47 1.64] [0.29 0.51]};
        patientsClims{10, 3} = {[0.23 0.34] [1.5 1.64] [0.37 0.53]};
        patientsClims{11, 3} = {[0.23 0.33] [1.44 1.63] [0.35 0.52]};
        patientsClims{13, 3} = {[0.19 0.34] [1.44 1.65] [0.29 0.52]};
        patientsClims{15, 3} = {[0.23 0.34] [1.5 1.66] [0.36 0.52]};
end

if(lowContrast)
    metricsClims = patientsClims{patientId, 1};
else
    metricsClims = patientsClims{patientId, filterType};
end

%% METRIC ANALYSIS
%% Metric plotting

if(savePlots)
    tic

    subplotCounter = 0;
    channelsMetricList = cell(3, totalNumberOfSubplots); % 3 types of metrics x as many subplots as I may want
    eegList = cell(1, totalNumberOfSubplots);
    totalWindowsList = zeros(1,totalNumberOfSubplots);
    seizureList = zeros(1,totalNumberOfSubplots);
    batchNumber = 0;

    for index = 1:length(timeSortedRecordingIds)

        %% Definition of basic EEG and processing variables
        cd(dataDirectory)
        seizure = timeSortedRecordingIds(index);
        seizureFilename = sprintf('Seizure_%03d.mat', seizure);
        metricFilename = sprintf('Metrics_%03d.mat', seizure);

        try
            eegData = load(seizureFilename);
        catch
            warning(['File ', num2str(seizure), ' does not exist. Skipping to the next iteration.']);
            continue;  % Skips to the next iteration of the loop
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
            cd(additionalScriptsDirectory)
            channelData = eegFullCentered(i, :);
            filteredChannel = DV_BandPassFilter(channelData, fs, filterType);
            filteredEegFullCentered(i, :) = filteredChannel;
        end

        % Obtain number of total windows after windowing
        windowSizeSamples = windowSizeSeconds * fs;
        overlapSamples = fs * overlapSeconds;
        totalWindows = floor((length(eegFull(1, :)) - windowSizeSamples) / (windowSizeSamples - overlapSamples)) + 1;

        loadPercentage = (index / length(timeSortedRecordingIds)) * 100;
        disp(['(', metricString, ' - ' , filterDescription, ') Analysis of recording ', num2str(timeSortedRecordingIds(index)), ': ', num2str(index), ...
            ' out of ', num2str(length(timeSortedRecordingIds)), ' (', num2str(loadPercentage), '%)']);

        %% Perform HT of signal and obtain windowed metrics
        metricMatFilePath = fullfile(rawMetricDirectory, metricFilename);

        if ~exist(metricMatFilePath, 'file')

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

            recordingMetrics = cell(3, 1);
            recordingMetrics{1} = channelsV;
            recordingMetrics{2} = channelsM;
            recordingMetrics{3} = channelsS;

            save(fullfile(rawMetricDirectory, metricFilename), 'recordingMetrics');
        else
            recordingMetrics = load(metricMatFilePath);
            recordingMetrics = recordingMetrics.recordingMetrics;
        end

        %% Obtain subplots

        subplotCounter = subplotCounter + 1;

        eegList{subplotCounter} = filteredEegFullCentered;
        seizureList(subplotCounter) = seizure;
        totalWindowsList(subplotCounter) = totalWindows;
        channelsMetricList{1, subplotCounter} = recordingMetrics{1};
        channelsMetricList{2, subplotCounter} = recordingMetrics{2};
        channelsMetricList{3, subplotCounter} = recordingMetrics{3};

        if subplotCounter == totalNumberOfSubplots || index == length(timeSortedRecordingIds)
            % if subplotCounter == totalNumberOfSubplots || index == testLength
            cd(additionalScriptsDirectory)
            DV_PatientMetricPlotter( ...
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

    end
    toc

end
%% Metric averaging

if(averageMetrics == 1)

    preIctalPeriodAverages = {[], [], []};
    ictalPeriodAverages = {[], [], []};
    postIctalPeriodAverages = {[], [], []};
    preIctalWindowsAverages = {[], [], []};

    for index = 1:length(timeSortedRecordingIds)
        %% Definition of basic EEG and processing variables
        cd(dataDirectory)
        seizure = timeSortedRecordingIds(index);
        seizureFilename = sprintf('Seizure_%03d.mat', seizure);
        metricFilename = sprintf('Metrics_%03d.mat', seizure);

        try
            eegData = load(seizureFilename);
        catch
            warning(['File ', num2str(seizure), ' does not exist. Skipping to the next iteration.']);
            continue;  % Skips to the next iteration of the loop
        end

        metricMatFilePath = fullfile(rawMetricDirectory, metricFilename);
        
        if exist(metricMatFilePath, 'file')
            recordingMetrics = load(metricMatFilePath);
            recordingMetrics = recordingMetrics.recordingMetrics;
        else
            error("Please save metric results to obtain averages!")
        end

        % Obtain number of total windows after windowing
        eegFull = eegData.data';
        fs= 400;
        windowSizeSamples = windowSizeSeconds * fs;
        overlapSamples = fs * overlapSeconds;
        totalWindows = floor((length(eegFull(1, :)) - windowSizeSamples) / (windowSizeSamples - overlapSamples)) + 1;

        cd(additionalScriptsDirectory);

        [preIctalPeriodAverages, ictalPeriodAverages, postIctalPeriodAverages,preIctalWindowsAverages] = DV_MetricAverager( ...
            eegFull, ...
            fs, ...
            totalWindows, ...
            recordingMetrics, ...
            windowSizeSeconds, ...
            overlapSeconds, ...
            preIctalPeriodAverages, ...
            ictalPeriodAverages, ...
            postIctalPeriodAverages, ...
            preIctalWindowsAverages);
        
    end

    % Grand averages obtention

    grandAveragesV = zeros(16, 3);
    grandAveragesM = zeros(16, 3);
    grandAveragesS = zeros(16, 3);

    % Calculate grand averages for each period and metric
    grandAveragesV(:, 1) = mean(preIctalPeriodAverages{1}, 2);
    grandAveragesV(:, 2) = mean(ictalPeriodAverages{1}, 2);
    grandAveragesV(:, 3) = mean(postIctalPeriodAverages{1}, 2);

    grandAveragesM(:, 1) = mean(preIctalPeriodAverages{2}, 2);
    grandAveragesM(:, 2) = mean(ictalPeriodAverages{2}, 2);
    grandAveragesM(:, 3) = mean(postIctalPeriodAverages{2}, 2);

    grandAveragesS(:, 1) = mean(preIctalPeriodAverages{3}, 2);
    grandAveragesS(:, 2) = mean(ictalPeriodAverages{3}, 2);
    grandAveragesS(:, 3) = mean(postIctalPeriodAverages{3}, 2);

    % Calculate grand averages for each window
    validRecordings = length(timeSortedRecordingIds);
    grandAverageWindowsV = preIctalWindowsAverages{1} / validRecordings;
    grandAverageWindowsM = preIctalWindowsAverages{2} / validRecordings;
    grandAverageWindowsS = preIctalWindowsAverages{3} / validRecordings;

    DV_MetricAveragePlotter( ...
        eegFull, ...
        grandAveragesV, ...
        grandAveragesM, ...
        grandAveragesS, ...
        patientId, ...
        filterDescription, ...
        averagedMetricsDirectory, ...
        doNotCloseFigure)

    DV_MetricWindowAveragePlotter( ...
        eegFull, ...
        grandAverageWindowsV, ...
        grandAverageWindowsM, ...
        grandAverageWindowsS, ...
        patientId, ...
        filterDescription, ...
        averagedMetricsDirectory, ...
        doNotCloseFigure)

end

%% Output video

if(saveVideo)

    cd(selectedMetricDirectory)

    videoFolder = videosDirectory;
    videoFileName = fullfile(videoFolder, [metricString, '_', filterDescription, '_patient', num2str(patientId)]);
    pngFiles = dir(['*', metricString, '*.png']);

    % Create a video object

    outputVideo = VideoWriter(videoFileName, 'Motion JPEG AVI');
    outputVideo.FrameRate = 1;
    open(outputVideo);

    for i = 1:numel(pngFiles)
        img = imread(pngFiles(i).name);
        writeVideo(outputVideo, img);
    end

    close(outputVideo);

end

cd(additionalScriptsDirectory)

end