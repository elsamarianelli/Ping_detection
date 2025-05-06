function plot_EEG_with_triggers(data_FT, trigSamples)
% PLOT_EEG_WITH_TRIGGERS plots an EEG channel with overlaid trigger markers
%
% Inputs:
%   data_FT     → FieldTrip EEG data structure
%   trigSamples → vector of sample indices (same sampling as data_FT)
%
% Example:
%   plot_EEG_with_triggers(data_FT, trigSamples)

% Get number of samples
nSamples = size(data_FT.trial{1}, 2);

% Use first channel for display (change index if you want another channel)
channel_check = data_FT.trial{1}(1, :);

% Create trigger array (zeros with ones at trigger points)
trigger_array = zeros(1, nSamples);
trigger_array(trigSamples(trigSamples <= nSamples)) = max(channel_check);

% Create figure
figure;

% Plot EEG signal on top (blue line)
plot(1:nSamples, channel_check, 'b'); hold on;

% Plot triggers first (thin red line, underneath EEG)
plot(1:nSamples, trigger_array, 'r', 'LineWidth', 1)
% Label axes and set title etc.
xlabel('Sample idx', 'FontSize', 18)
ylabel('EEG amplitude', 'FontSize', 18)
title('EEG with overlaid triggers from audio', 'FontSize', 20)
legend({'EEG channel','Extracted triggers'}, 'FontSize', 16, 'Location','best')
set(gca, 'FontSize', 16)

hold off;
end
