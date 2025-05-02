%% Code to extract audio triggers from video data for Davide
%  Written by Elsa Marianelli, edited by Daniel Bush (2025)

%% Set some parameters
% dataFold        = 'D:\Data\Davide Project\';                % Data path 
% dataFold        = '/Users/elsamarianelli/Documents/audio_pip_task'; % on laptop
dataFold        = 'C:\Users\Elsa Marianelli\Documents\GitHub\DAVIDE_data_and_docs';% on work computer 

dataFile        = 'audio_vid_76.wav';                       % Audio file
trigFile        = 'actual_ping_shorter.wav';                % Template audio trigger
window_length   = 512;                                      % Length of the window for FFT
overlap_length  = 256;                                      % Length of overlap between windows
freqLim         = 600;                                      % Lower frequency limit (Hz)
N               = 5;                                        % Number of dominant frequencies to identify
sigma           = 18;                                       % Standard deviation for Gaussian filter (samples)

%%  Import the audio
[yS, Fs]        = audioread([dataFold filesep dataFile]);   % Import audio data, sampling frequency (Hz)
yS              = yS(:,1);                                  % Extract left audio channel

%  Import the template trigger
[yS_p, Fs_p]    = audioread([dataFold filesep trigFile]);
yS_p            = yS_p(:,1); 

%% Compute spectrograms
[s, f, t]   = spectrogram(yS, window_length, overlap_length, [], Fs); 
[s_t, f_t]  = spectrogram(yS_p, window_length, overlap_length, [], Fs_p); 

%% Remove Frequencies Below 600 Hz
freqLim = 600; % Cutoff frequency

valid_f = f > freqLim;  % Logical mask for frequencies above 600 Hz
s = s(valid_f, :);      % Apply mask to full audio spectrogram
f = f(valid_f);         % Update frequency vector
s_t = s_t(valid_f, :);  % Apply mask to trigger spectrogram
f_t = f;                % Since f_t is now the same filtered range

%% Normalize Each Column (Time Step) in Both Spectrograms
S_norm = abs(s) ./ max(sum(abs(s), 1), eps);        % Normalize full spectrogram, avoiding division by zero
S_t_norm = abs(s_t) ./ max(sum(abs(s_t), 1), eps);  % Normalize trigger spectrogram, avoiding NaNs

%% Find Dominant Frequencies in the Trigger
[~, inds] = maxk(sum(S_t_norm, 2), N);              % Select top N strongest frequency bands
top_freqs = f(inds);                                % Extract the corresponding frequency values

%% Use These Frequency Bands to Analyze the Full Audio Signal
top_freqs_mask = any(f == top_freqs', 2);           % Faster alternative to ismember()

s_filt = S_norm(top_freqs_mask, :); % Extract spectrogram data for dominant frequencies
avg_power = mean(s_filt, 1) / max(mean(s_filt, 1)); % Compute and normalize mean power time series

smth_pow = imgaussfilt(avg_power, sigma);           % Smooth the final power series

%% Generate an interactive plot to set the threshold
% remember when you press outside the x axis you have to make sure to do it
% inline with where you want the threshold to be.
figure;
go_on           = true;
thresh          = 0.34;
while go_on
    plot(t, smth_pow, 'b', 'LineWidth', 1.5), hold on
    plot(t,thresh*ones(size(t)),'r--')
    trigs       = regionprops(smth_pow>thresh,'PixelIdxList');
    trigs       = cellfun(@(x) t(min(x)),{trigs(:).PixelIdxList});
    scatter(trigs,thresh*ones(size(trigs)),500,'r.'), hold off    
    xlabel('Time (s)','FontSize',24), ylabel('Smoothed Trigger Power (au)'), grid on
    title('Click outside the x-axis to accept trigger times')
    [x,thresh]  = ginput(1);
    if x<min(t) || x>max(t)
        go_on   = false;
    end    
end
close, clear go_on x

%% Visualise to check correct pings being taken
start_time =1590;                                % change this to skip over talking bits
playback_with_cursor(yS, Fs, t, smth_pow, start_time, thresh)
stop(player);                                 % Stop playback when finished

%% Save the output
[~,root]        = fileparts(dataFile);
T               = array2table(trigs','VariableNames',{'TriggerTimes'});
writetable(T,[root '-triggerTimes.csv']); clear T root