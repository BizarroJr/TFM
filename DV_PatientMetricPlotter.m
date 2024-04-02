clear;
clc;
close all;

for filterType = 1:3
    % for metricToPlot = 1:3

    %% User tunable variables
    patientId = 8;
    analysisType = 'clean'; % Either clean or unclean. Unclean will include data with dropouts
    windowSizeSeconds = 10; % In seconds
    overlapSeconds = 9; % Overlap between windows
    % filterType = 1; % 1-No filter, 2-LPF, 3-HPF
    metricToPlot = 3; % 1-V, 2-M, 3-S
    totalNumberOfSubplots = 5; % Number of plots on each file
    tickDecimateFactor = 4; % Number of ticks to be removed per plot
    obtainExtremeValues = false; % Gather which are all the min & max values of a metric, then perform an average
    savePlots = true; % Save metric plots into png and mat files
    saveVideo = true; % Saves video

    switch metricToPlot
        case 1
            metricString = 'V';
        case 2
            metricString = 'M';
        case 3
            metricString = 'S';
        otherwise
            error('Invalid metricToPlot: %d. filterType must be 1, 2, or 3.', metricToPlot);
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

    %% Directory parameters definition

    baseDirectory = "P:\WORK\David\UPF\TFM";
    dataDirectory = fullfile(baseDirectory, "Data", "Seizure_Data_" + patientId);
    visualizerDirectory = fullfile(baseDirectory, "EEG_visualizer");
    metricsAndMeasuresDirectory = fullfile(visualizerDirectory, "Metrics_and_measures");
    additionalScriptsDirectory = fullfile(baseDirectory, "Additional_scripts");
    metricsPlotsDirectory = fullfile(additionalScriptsDirectory, "Metrics_plots");

    % Define where the plots will be saved

    switch(analysisType)
        case('clean')
            patientMetricPlotsDirectory = fullfile(metricsPlotsDirectory, ['Clean_metric_plots_for_patient_', num2str(patientId)]);
        case('unclean')
            patientMetricPlotsDirectory = fullfile(metricsPlotsDirectory, ['Unclean_metric_plots_for_patient_', num2str(patientId)]);
        otherwise
            error('Invalid analysis type. The analysisType must be either ''clean'' or ''unclean''.');
    end

    savePlotsDirectory = fullfile(patientMetricPlotsDirectory, [filterDescription, '_data']);
    selectedMetricDirectory = fullfile(savePlotsDirectory, metricString);

    %% Folder creation

    cd(additionalScriptsDirectory)

    metricsPlotsFolderName = 'Metrics_plots';
    cleanedMetricPlotsFolderName = ['Clean_metric_plots_for_patient_', num2str(patientId)];
    uncleanedMetricPlotsFolderName = ['Unclean_metric_plots_for_patient_', num2str(patientId)];
    filterFolderName = [filterDescription, '_data'];

    DV_CheckAndCreateFolder(metricsPlotsFolderName)
    DV_CheckAndCreateFolder(cleanedMetricPlotsFolderName, metricsPlotsDirectory, additionalScriptsDirectory)
    DV_CheckAndCreateFolder(uncleanedMetricPlotsFolderName, metricsPlotsDirectory, additionalScriptsDirectory)
    DV_CheckAndCreateFolder(filterFolderName, patientMetricPlotsDirectory, additionalScriptsDirectory)
    DV_CheckAndCreateFolder(metricString, savePlotsDirectory, additionalScriptsDirectory)

    %% Retrieve diagnostics data and sort it

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

    % Sort by descending time and remove dropout affected recordings if
    % necessary
    timeSortedArtifactData = sortrows(artifactData, 2, 'descend');
    if strcmp(analysisType, 'clean')
        timeSortedArtifactData = timeSortedArtifactData(timeSortedArtifactData(:, 3) <= 0, :);
    end
    totalRecordingsToAnalyze = length(timeSortedArtifactData);
    timeSortedRecordingIds = timeSortedArtifactData(:, 1);

    %% Obtain Clims
    % To be able to compare between recordings of a patient, color limits of
    % the heatmap have to be manually established to remain constant across
    % recordings in the same metric.

    if(obtainExtremeValues)
        cd(additionalScriptsDirectory)
        [metricLimits, metricsExtremeValuesList] = DV_ClimExtractor( ...
            patientId, ...
            dataDirectory, ...
            visualizerDirectory, ...
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
    totalFilterTypes = 3;

    patientsClims = cell(totalPatients, totalFilterTypes); % patientsClims{patientId, filterType}

    % Initialize all cells with a value of -1
    for patient = 1:totalPatients
        for filter = 1:totalFilterTypes
            patientsClims{patient, filter} = -1;
        end
    end
    
    % Patient 2
    patientsClims{2, 1} = {[1.09 4.27] [0.04 0.35] [0.09 0.55]};
    patientsClims{2, 2} = {[0.61 1.38] [0.11 0.27] [0.1 0.24]};
    patientsClims{2, 3} = {[0.26 0.37] [1.52 1.68] [0.42 0.58]};

    % Patient 8
    patientsClims{8, 1} = {[0.79 3.5] [0.06 0.4] [0.13 0.51]};
    patientsClims{8, 2} = {[0.46 1.4] [0.11 0.37] [0.09 0.26]};
    patientsClims{8, 3} = {[0.26 0.38] [1.5 1.66] [0.43 0.59]};

    % Patient 11
    patientsClims{11, 1} = {[0.86 4.44] [0.04 0.35] [0.12 0.56]};
    patientsClims{11, 2} = {[0.55 1.34] [0.12 0.3] [0.09 0.24]};
    patientsClims{11, 3} = {[0.26 0.37] [1.44 1.66] [0.41 0.58]};

    metricsClims = patientsClims{patientId, filterType};

    %% METRIC PLOTS

    if(savePlots)
        tic

        subplotCounter = 0;
        channelsMetricList = cell(3, totalNumberOfSubplots); % 3 types of metrics x as many subplots as I may want
        eegList = cell(1, totalNumberOfSubplots);
        totalWindowsList = zeros(1,totalNumberOfSubplots);
        seizureList = zeros(1,totalNumberOfSubplots);
        batchNumber = 0;
        % testLength = 7;

        for index = 1:length(timeSortedRecordingIds)
            % for index = 1:testLength

            %% Definition of basic EEG and processing variables
            cd(dataDirectory)
            seizure = timeSortedRecordingIds(index);

            try
                eegData = load(sprintf('Seizure_%03d.mat', seizure));
            catch
                warning(['File ', seizure, ' does not exist. Skipping to the next iteration.']);
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
            disp(['(', metricString, ' - ' , filterDescription, ') Analysis of recording ', num2str(timeSortedRecordingIds(index)), ': ', num2str(index), ...
                ' out of ', num2str(length(timeSortedRecordingIds)), ' (', num2str(loadPercentage), '%)']);

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
                    selectedMetricDirectory)

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

    %% Output video

    if(saveVideo)

        cd(selectedMetricDirectory)
        
        videoFolder = patientMetricPlotsDirectory;
        videoFileName = fullfile(videoFolder, [metricString, '_', filterDescription, '_patient', num2str(patientId)]);
        pngFiles = dir(['*', metricString, '*.png']);

        % Create a video object

        outputVideo = VideoWriter(videoFileName, 'Motion JPEG AVI');
        outputVideo.FrameRate = 1/2;
        open(outputVideo);

        for i = 1:numel(pngFiles)
            img = imread(pngFiles(i).name);
            writeVideo(outputVideo, img);
        end

        close(outputVideo);

    end

    cd(additionalScriptsDirectory)

    % end
end