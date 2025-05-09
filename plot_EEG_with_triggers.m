function out_of_bounds = plot_EEG_with_triggers(data_FT, trigSamples)
% plots the trigger times extracted form the audio over the EEG
% data (with the stimulation high frequency periods) and also any triggers
% that go "out of bounds" of the EEG data... 
% also returns the triggers which are out of bounds to remove from epoching later

    % Get number of samples
    nSamples = size(data_FT.trial{1}, 2);
    
    % Use first channel for display
    channel_check = data_FT.trial{1}(1, :);
    
    % Create trigger array (zeros with ones at trigger points)
    trigger_array = zeros(1, nSamples);
    trigger_array(trigSamples(trigSamples <= nSamples)) = max(channel_check);
    
    % Create figure
    figure;
    
    % Plot EEG signal
    plot(1:nSamples, channel_check, 'b'); 
    hold on;
    
    % Plot triggers inside EEG length
    plot(1:nSamples, trigger_array, 'r', 'LineWidth', 1)
    
    % Plot out-of-bounds triggers (not cutting triggers short)?
    out_of_bounds = trigSamples(trigSamples > nSamples);

    for i = 1:length(out_of_bounds)
        x = out_of_bounds(i);
        % Plot a vertical dashed line at the out-of-bounds trigger position
        xline(x, 'm--', 'LineWidth', 1.5);
    end
    
    % Labels etc.
    xlabel('Sample idx', 'FontSize', 18)
    ylabel('EEG amplitude', 'FontSize', 18)
    title('EEG with overlaid triggers from audio', 'FontSize', 20)
    legend({'EEG channel', 'Extracted triggers', 'Out-of-bounds triggers'}, ...
            'FontSize', 16, 'Location','best')
    set(gca, 'FontSize', 16)
    
    hold off;

end