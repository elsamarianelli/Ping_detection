function plot_trace_with_stim_sources(trace, timeVec, stimTimes_extracted, stim_times_table)
    % Plot EEG trace, stim periods, and stim times from stim table

    figure;
    
    % Plot EEG trace
    % subplot(3,1,1);
    % plot(timeVec, trace, 'k'); hold on;
    % title('EEG Trace');
    % ylabel('Amplitude');
    % xlim([timeVec(1), timeVec(end)]);

    % Plot stim periods from extract_stim_clusters
    % subplot(2,1,1);
    for i = 1:size(stimTimes_extracted,1)
        x1 = stimTimes_extracted(i,1);
        x2 = stimTimes_extracted(i,2);
        yL = ylim;
        patch([x1 x2 x2 x1], [yL(1) yL(1) yL(2) yL(2)], ...
              [1 0.8 0.8], 'EdgeColor', 'none', 'FaceAlpha', .5);
    end
    title('EEG with Detected Stim Clusters');
    ylabel('Amplitude'); hold on;
    plot(timeVec, trace, 'b'); hold on;
   % xlim([timeVec(1), timeVec(end)]);
    hold on
    % Plot stim times from table
    % subplot(2,1,2);
    stem(stim_times_table.Start, ones(height(stim_times_table),1).*3000, 'r', 'filled');
    title('Stimulation Times from Log Table');
    ylabel('Marker');
    xlabel('Time (s)');
    %ylim([0 1.2]);
    %xlim([timeVec(1), timeVec(end)]);

    set(gcf, 'Position', [100 100 800 600]);


end
