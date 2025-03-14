% Load the audio file

addpath 'C:\Users\Elsa Marianelli\Desktop\audio_pip_task'

% get full audio
[yS, Fs] = audioread('audio_vid_77.wav');% audio data, sampling frequency (Hz)
y=yS(:,1); % taking first audio channel
sound(y, Fs); % Play the audio
clear sound;

% get ping audio 
[yS_p, Fs_p] = audioread('actual_ping_shorter.wav');
y_segment=yS_p(:,1); 
sound(y_segment, Fs_p);
clear sound;

% Define parameters for the spectrogram
window_length = 512; % Length of the window for FFT
overlap_length = 256; % Length of overlap between windows

% Calculate the spectrogram for the trigger ping and the full audio file
[s_p, f_p, t_p] = spectrogram(y_p, window_length, overlap_length, [], Fs_p);
[s, f, t] = spectrogram(y, window_length, overlap_length, [], Fs);

% Plot the spectrogram for the full audio
figure;
imagesc(t, f, 10*log10(abs(s))); % Convert to dB scale
axis xy; % Set the y-axis direction to be normal (low frequencies at bottom)
xlabel('Time (s)');
ylabel('Frequency (Hz)');
title('Spectrogram');
colorbar; % Add a colorbar to show intensity scale

%% taking some frequencies that are high specifically for the ping 
%  stops it picking up the talking inbetween or any loud background noises

% Compute the spectrogram for the extracted segment
[s_seg, f_seg, t_seg] = spectrogram(y_segment, 512, 256, [], Fs);
% Compute power (magnitude squared) of spectrogram
power_s_seg = abs(s_seg).^2;
% Sum power across time to get overall energy at each frequency
power_per_freq = sum(power_s_seg, 2);
% Filter out frequencies below 600 Hz (strong base frequencies for
% everything so remove these)
valid_indices = f_seg > 600; 

% Sort the power values but only for valid frequencies
[sorted_power, sorted_indices] = sort(power_per_freq(valid_indices), 'descend');

% Extract the top frequency bands 
N = 5; % Number of strongest frequency bands to extract - 5 works well enough
top_freqs = f_seg(valid_indices);
top_freqs = top_freqs(sorted_indices(1:N)); 

% Plot the spectrogram ofthe ping with top frequencies highlighted
figure;
imagesc(t_seg, f_seg, 10*log10(power_s_seg)); % Convert to dB scale
axis xy;
xlabel('Time (s)');
ylabel('Frequency (Hz)');
title('Spectrogram of Extracted Ping with Dominant Frequencies (>600 Hz)');
colorbar;
hold on;
for i = 1:N
    yline(top_freqs(i), 'r--', 'LineWidth', 2); 
end
hold off;

%% using these frequency bands to filter out pings in full audio
% Find indices of the top frequency bands in the full spectrogram
freq_indices = ismember(f, top_freqs);

% Extract spectrogram data only for these frequencies
s_filtered = s(freq_indices, :);
f_filtered = f(freq_indices);

% Compute the average magnitude across the selected frequency bands at each time step
avg_magnitude = mean(abs(s_filtered), 1); 

% Normalize and smoothing, smoothing makes it easier take timestamp when it
% first goes over threshold for one ping 
avg_magnitude = avg_magnitude / max(avg_magnitude);
sigma = 15; % Standard deviation for Gaussian filter
smoothed_magnitude = imgaussfilt(avg_magnitude, sigma);

% Plot the averaged magnitude over time to look at where to set threshold
figure;
plot(t, smoothed_magnitude, 'b', 'LineWidth', 1.5);
xlabel('Time (s)');
ylabel('Averaged Magnitude of Top Frequency Bands (>600 Hz)');
title('Averaged Spectral Magnitude Over Time for Selected Frequency Bands');
grid on;

%% take timestamps above threshold
threshold = 0.3;
time_stamp_ping = t(find(diff(smoothed_magnitude > threshold) == 1) + 1);

%% take the sections of audio in the full audio file that cross threshold, 
%  should be those with just pings (ignore those before experiment starts think they were just testing)

post_duration = 0.8; %  for audio stringing together

% Get timestamps where magnitude first exceeds threshold
threshold_times = t(find(diff(smoothed_magnitude > threshold) == 1) + 1);
writematrix(time_stamp_ping, 'threshold_times.csv'); % saves time stamps

%% to listen and see that the pings were taken out as wanted
% Convert to sample indices
sample_indices = round(threshold_times * Fs);
samples_after = round(post_duration * Fs);

% Initialize empty array for concatenated audio
y_extracted = [];

% Extract and concatenate each segment
for i = 1:length(sample_indices)
    start_sample = sample_indices(i);
    end_sample = min(start_sample + samples_after, length(y)); % Avoid exceeding array bounds
    y_extracted = [y_extracted; y(start_sample:end_sample)]; % Concatenate segments
end

% Save the extracted audio as a new file
audiowrite('extracted_audio.wav', y_extracted, Fs); % saves audio

% Play the extracted audio
sound(y_extracted, Fs);
clear sound
