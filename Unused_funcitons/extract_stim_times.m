function stimTimes = extract_stim_clusters(trace, timeVec, sigma, threshold, merge_gap_sec)
    % trace           → raw EEG signal
    % timeVec         → time axis (same length as trace)
    % sigma           → Gaussian smoothing width (for denoising)
    % threshold       → amplitude threshold to detect stimulation periods
    % merge_gap_sec   → gap (in seconds) below which clusters are merged

    % Smooth the trace
    smth_trace = imgaussfilt(trace, sigma);

    % Binary mask: above threshold
    over_thresh = smth_trace > threshold;

    % Calculate sampling frequency
    Fs = 1 / mean(diff(timeVec));

    % Merge short gaps between clusters
    merge_gap_samples = round(merge_gap_sec * Fs);
    over_thresh = imclose(over_thresh, ones(1, merge_gap_samples));

    % Find start and end indices
    diff_over = diff([0, over_thresh, 0]);
    start_idx = find(diff_over == 1);
    end_idx   = find(diff_over == -1) - 1;

    % Convert to times
    stimTimes = [timeVec(start_idx)', timeVec(end_idx)'];
end
