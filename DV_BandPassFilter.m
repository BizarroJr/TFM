function filtered_signal = DV_BandPassFilter(signal, fs, type)
    % DV_BandPassFilter: Apply Butterworth bandpass filter to a signal
    %
    % Inputs:
    %   signal: Input signal
    %   fs: Sampling frequency (Hz)
    %   f_low: Lower cutoff frequency of the filter (Hz)
    %   f_high: Higher cutoff frequency of the filter (Hz)
    %   order: Filter order (default is 4)
    %
    % Output:
    %   filtered_signal: Filtered output signal
    
switch type

    case 1 % No filter
        filtered_signal = signal;

    case 2 % LPF
        freqLF = [4 30];
        orderLF = round(3 * (fs / freqLF(1))); % filter order for LF
        fir1CoefLF = fir1(orderLF, [freqLF(1), freqLF(2)] / (fs / 2)); % filter coeff. for LF
        filtered_signal = filtfilt(fir1CoefLF, 1, signal);

    case 3 % HPF
        freqHF = [80 150]; % Original HPF
        % freqHFO = [90 130]; % HPF2
        orderHFO = round(3 * (fs / freqHF(1))); % filter order for HF
        fir1CoefHFO = fir1(orderHFO, [freqHF(1), freqHF(2)] / (fs / 2)); % filter coeff. for HF
        filtered_signal = filtfilt(fir1CoefHFO, 1, signal);

    case 4 % MPF
        freqMF = [40 80]; % Mid-frequency range
        orderMF = round(3 * (fs / freqMF(1))); % filter order for MF
        fir1CoefMF = fir1(orderMF, [freqMF(1), freqMF(2)] / (fs / 2)); % filter coeff. for MF
        filtered_signal = filtfilt(fir1CoefMF, 1, signal);

    otherwise
        error('Unknown filter type.');
end

end
