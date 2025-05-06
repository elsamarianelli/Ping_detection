function [stimTimes, artifact_matrix] = extract_stim_clusters(trace, timeVec, Fs, threshold, merge_gap_sec)
    % trace           - raw EEG signal
    % timeVec         - time axis (same length as trace)
    % threshold       - amplitude threshold to detect stimulation periods
    % merge_gap_sec    gap (in seconds) below which clusters are merged


    % Binary mask: above threshold
    over_thresh = trace > threshold;
    % Find start and end indices from logical array
    diff_over = diff([0, over_thresh, 0]);
    start_idx = find(diff_over == 1);
    end_idx   = find(diff_over == -1) - 1;
    
    % Combine into artifact matrix for later use in interpolation funciton
    artifact_matrix = [start_idx(:), end_idx(:)];

    % Merge short gaps between clusters
    merge_gap_samples = round(merge_gap_sec * Fs);
    over_thresh = imclose(over_thresh, ones(1, merge_gap_samples));

    % Find start and end indices
    diff_over = diff([0, over_thresh, 0]);
    start_idx = find(diff_over == 1);
    end_idx   = find(diff_over == -1) - 1;

    % Convert to times
    stimTimes = [timeVec(start_idx)', timeVec(end_idx)'];

    figure;
    plot(timeVec, trace, 'b'); hold on;

    % Loop over stim periods and add shaded patches
    for i = 1:size(stimTimes,1)
        x1 = stimTimes(i,1);
        x2 = stimTimes(i,2);
        yLimits = ylim; % get current y-axis limits

        % Draw shaded patch
        patch([x1 x2 x2 x1], [yLimits(1) yLimits(1) yLimits(2) yLimits(2)], ...
              [1 0.8 0.8], 'FaceAlpha', 0.7, 'EdgeColor', 'none');
    end

    xlabel('Time (s)', 'FontSize', 12);
    ylabel('Amplitude', 'FontSize', 12);
    title('EEG trace with stimulation periods', 'FontSize', 14);
    hold off;

end
