function [stimTimes, artifact_matrix] = extract_stim_clusters(trace, timeVec, Fs, threshold, merge_gap_sec)
%% Function to extract trigger times from audio recordings (ping detection)
%  Elsa Marianelli, UCL (2025) zcbtetm@ucl.ac.uk - Edited by Dan Bush 
%
%  This function extracts the timestamps of ping-like audio triggers from a 
%  provided audio file. It uses a template matching method based on the 
%  spectrogram of a known trigger sound to identify peaks in the full audio.
%
%  Inputs:
%  dataFile  - string, filename of the audio file (e.g., 'audio_vid_76.wav')
%
%  Outputs:
%  trigs     - vector of trigger times (in seconds) corresponding to detected
%              pings within the audio
%
%  Interactive steps:
%  - Step 1: Set a power threshold interactively to detect pings.
%  - Step 2: (Optional) Set a start time threshold to remove pre-task periods.
%
%  Additional behavior:
%  - Option to save the detected trigger times as a CSV file (interactive prompt)
%
%  Notes:
%  - Make sure the template ping audio ('actual_ping_shorter.wav') is available 
%    in the same data directory.
%  - The data directory (dataFold) is hard-coded and may need to be updated
%    depending on the computer being used.


    % Binary mask: above threshold
    threshold = 20;
    over_thresh = trace_variability > threshold;
    % Merge short gaps between clusters
    merge_gap_samples = round(merge_gap_sec * Fs);
    over_thresh = imclose(over_thresh, ones(1, merge_gap_samples));
    
    % add the ones that are too stimulated for frequency to show up
    over_thresh_outofbounds = trace > 2500; 
    % merge binary masks 
    over_thresh = (over_thresh + over_thresh_outofbounds) > 0; 
    % 
    % Find start and end indices from logical array
    diff_over = diff([0, over_thresh, 0]);
    start_idx = find(diff_over == 1);
    end_idx   = find(diff_over == -1) - 1;
    stimTimes = [timeVec(start_idx)', timeVec(end_idx)'];

    artifact_matrix = [start_idx(:), end_idx(:)];
   

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
