function [stimTimes, artifact_matrix] = extract_stim_clusters(trace, timeVec, Fs, merge_gap_sec)
% function to extract stimulaiton periods direct from EEG trace (for
% comparison with those provdided in Davide Excel file) 

% [1] get periods with very high frequency
    % Binary mask: above threshold
    % Parameters
    window_size = 5;  % number of past points to average
    n = length(trace);
    
    % Preallocate variability array
    trace_variability = nan(1, n);  % first 'window_size' values will be NaN
    
    % Compute variability
    for t = (window_size + 1):n
        mean_prev = mean(trace(t - window_size:t - 1));
        trace_variability(t) = abs(trace(t) - mean_prev);
    end

    % get periods over variability threshold
    threshold = 20;
    over_thresh = trace_variability > threshold;

    % Merge short gaps between clusters
    merge_gap_samples = round(merge_gap_sec * Fs);
    over_thresh = imclose(over_thresh, ones(1, merge_gap_samples));

 % [2] get periods where stimulation is so high its just a block... don't
 % get caught in high frequency ^
    % add the ones that are too stimulated for frequency to show up
    over_thresh_outofbounds = trace > 2500; 

 % [3] merge binary masks 
    over_thresh = (over_thresh + over_thresh_outofbounds) > 0; 
    
    % Find start and end indices from logical array
    diff_over = diff([0, over_thresh, 0]);
    start_idx = find(diff_over == 1);
    end_idx   = find(diff_over == -1) - 1;
    stimTimes = [timeVec(start_idx)', timeVec(end_idx)'];

    artifact_matrix = [start_idx(:), end_idx(:)];
% [4] visualise
    figure;
    plot(timeVec, trace, 'b'); hold on;

    % Loop over stim periods and add shaded patches
    for i = 1:size(stimTimes,1)
        x1 = stimTimes(i,1);
        x2 = stimTimes(i,2);
        yLimits = ylim; % get current y-axis limits

        % Draw shaded patch
        patch([x1 x2 x2 x1], [yLimits(1) yLimits(1) yLimits(2) yLimits(2)], ...
              [1 0.8 0.8], 'FaceAlpha', 0.9, 'EdgeColor', 'none');
    end


    xlabel('Time (s)', 'FontSize', 12);
    ylabel('Amplitude', 'FontSize', 12);
    title('EEG trace with stimulation periods', 'FontSize', 14);
    hold off;

end
