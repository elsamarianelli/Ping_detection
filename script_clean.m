%% Code to extract audio triggers from video data for Davide
%  Written by Elsa Marianelli, edited by Daniel Bush (2025)


%% Set some parameters
% dataFold        = 'D:\Data\Davide Project\';                % Data path 
% dataFold        = '/Users/elsamarianelli/Documents/audio_pip_task'; % on laptop
dataFold        = 'C:\Users\Elsa Marianelli\Documents\GitHub\DAVIDE_audio_data';% on work computer 

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
freqLim     = 600; % Cutoff frequency

valid_f     = f > freqLim;   % Logical mask for frequencies above 600 Hz
valid_f_t   = f_t > freqLim; % Same for trigger spectrogram

s           = s(valid_f, :);   % Apply mask to full audio spectrogram
f           = f(valid_f);      % Update frequency vector

s_t         = s_t(valid_f_t, :); % Apply mask to trigger spectrogram
f_t         = f_t(valid_f_t);    % Update trigger frequency vector

%% Normalize Each Column (Time Step) in Both Spectrograms
% Normalize full spectrogram
S_norm = abs(s); % Convert to magnitude
S_norm = S_norm ./ sum(S_norm, 1); % Normalize each column to sum to 1
S_norm(:, sum(S_norm,1) == 0) = 0; % Avoid NaN issues

% Normalize trigger spectrogram
S_t_norm = abs(s_t);
S_t_norm = S_t_norm ./ sum(S_t_norm, 1);
S_t_norm(:, sum(S_t_norm,1) == 0) = 0;

%% Find Dominant Frequencies in the Trigger
p_t             = sum(S_t_norm, 2); % Total power per frequency band
[~, inds]       = sort(p_t, 'descend'); % Sort by strongest components
top_freqs       = f_t(inds(1:N)); % Select top N frequency bands

%% Use These Frequency Bands to Analyze the Full Audio Signal
top_freqs_mask  = ismember(f, top_freqs); % Create mask for selected frequencies

s_filt          = S_norm(top_freqs_mask, :); % Extract data for dominant frequencies
avg_power       = mean(s_filt, 1); % Compute mean power time series
avg_power       = avg_power / max(avg_power); % Normalize power

smth_pow        = imgaussfilt(avg_power, sigma); % Smooth the final power series
%% Generate an interactive plot to set the threshold
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
%% visialise to check correct pings being taken.
start_time =1; 
playback_with_cursor(yS, Fs, t, smth_pow, start_time, thresh)
stop(player); % Stop playback when finished

%% Save the output
[~,root]        = fileparts(dataFile);
T               = array2table(trigs','VariableNames',{'TriggerTimes'});
writetable(T,[root '-triggerTimes.csv']); clear T root