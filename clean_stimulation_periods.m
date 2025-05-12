function cleaned_trace = clean_stimulation_periods(trace, threshold, pre_points, post_points)
%% Function to remove stimulation artifacts from EEG trace
%  Elsa Marianelli, UCL (2025) zcbtetm@ucl.ac.uk
%
%  Removes large transient artifacts caused by manual 
%  stimulation in EEG recordings. Detected spikes are masked and then 
%  interpolated to recover the underlying signal as smoothly as possible.
%  Plots for visualisation. Intended for preprocessing EEG prior to epoching 
%  or feature extraction.
%
%  Inputs:
%  trace        - 1D vector, raw EEG signal from a single channel
%  threshold    - scalar, amplitude threshold to detect stimulation peaks
%  pre_points   - number of points before each peak to mask
%  post_points  - number of points after each peak to mask
%
%  Outputs:
%  cleaned_trace - 1D vector, EEG trace with stimulation periods removed
%                  and interpolated

    % [1] Find threshold crossings (rising edge)
    crossings = find(diff(trace > threshold) == 1);
    
    % [2] Initialize peak list
    peak_idxs = zeros(size(crossings));
    
    % [3] Loop over each crossing to find the peak after it
    for i = 1:length(crossings)
        idx = crossings(i);
        % Look ahead until trace drops back below threshold or reach end
        next_idx = idx + 1;
        while next_idx < length(trace) && trace(next_idx) > threshold
            next_idx = next_idx + 1;
        end
        % Find the peak between idx and next_idx
        [~, rel_peak_idx] = max(trace(idx:next_idx));
        peak_idxs(i) = idx + rel_peak_idx - 1;
    end
    
    % [4] Create mask (1 = keep, 0 = remove)
    mask = ones(size(trace)).*1;
    
    for i = 1:length(peak_idxs)
        peak_idx = peak_idxs(i);
        start_idx = max(1, peak_idx - pre_points);
        end_idx   = min(length(trace), peak_idx + post_points);
        mask(start_idx:end_idx) = nan;
    end
    
    new_trace = trace.*mask;
    figure; plot(new_trace)
    
    % [5] interpolate 
    
    valid_idx = find(~isnan(new_trace)); % Find valid indices
    nan_idx = find(isnan(new_trace));    % find Nans
    
    % Initialize cleaned_trace as a copy
    cleaned_trace = new_trace;
    
    % Interpolate over NaNs (linear)
    cleaned_trace(nan_idx) = interp1(valid_idx, new_trace(valid_idx), nan_idx, 'linear', 'extrap');
    
    % plot to visualise
    figure;  plot(trace); hold on; plot(cleaned_trace); hold off;

end