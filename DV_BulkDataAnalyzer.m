clear;
clc;
close all;

%% User tunable variables
analysisType = 'clean'; % Either clean or unclean. Unclean will include data with dropouts
windowSizeSeconds = 10; % In seconds
overlapSeconds = 9; % Overlap between windows
totalNumberOfSubplots = 1; % Number of plots on each file
tickDecimateFactor = 4; % Number of ticks to be removed per plot
orderType = 1; % 1-ascending, 2-descending
lowContrast = false; % Use the same color scale for a recording, to compare between metrics. Only suitable for a single recording screening.
obtainExtremeValues = false; % Gather which are all the min & max values of a metric, then perform an average
saveMetrics = true; % Save metric mat files
savePlots = false; % Save metric plots into png and mat files
saveVideo = false; % Saves video
performMetricsAverage = true; % Averages metrics and saves results, if 1, performs average, else does not. This is done to optimize code and perform this just once.
doNotCloseFigure = false; % In DV_MultiPBMPlotter, if visualize fig is 'on', closes it if false
storeInHardDrive = true;

if(obtainExtremeValues)
    savePlots = false;
    saveVideo = false;
end

processStartTime = tic;
for patientId = 1:15
    if any(patientId == [5, 6, 12, 14])
        continue
    end
    
    disp(['Processing Patient ', num2str(patientId), '...']);
    
    % Start the timer for the patient loop
    patientStartTime = tic;

    for filterType = 1:3

        if(performMetricsAverage)
            averageMetrics = true;
        else
            averageMetrics = false;
        end
        
        % Start the timer for the filter loop
        filterStartTime = tic;
        
        for metricToPlot = 1:3
            
            % Start the timer for the metric loop
            metricStartTime = tic;
            
            DV_PatientMetricAnalyzer( ...
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
                storeInHardDrive);

            averageMetrics = false; % This is done so that average is performed just once, as it will result the same for all filters
            
            % End the timer for the metric loop
            metricElapsedTime = toc(metricStartTime);
            disp(['      - Metric processing time: ', num2str(metricElapsedTime), ' seconds']);
        end
        
        % End the timer for the filter loop
        filterElapsedTime = toc(filterStartTime);
        disp(['    - Filter processing time: ', num2str(filterElapsedTime), ' seconds']);
    end
    
    % End the timer for the patient loop
    patientElapsedTime = toc(patientStartTime);
    disp(['Patient ', num2str(patientId), ' processed in ', num2str(patientElapsedTime), ' seconds']);
end

processElapsedTime = toc(processStartTime   );
disp(['Data processed in ', num2str(processElapsedTime), ' seconds']);