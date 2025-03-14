%% Code to extract audio triggers from video data for Davide
%  Written by Elsa Marianelli, edited by Daniel Bush (2025)


%% Set some parameters
%dataFold        = 'D:\Data\Davide Project\';                % Data path
dataFold        = '/Users/elsamarianelli/Documents/audio_pip_task';
dataFile        = 'audio_vid_72.wav';                       % Audio file
trigFile        = 'actual_ping_shorter.wav';                % Template audio trigger
window_length   = 512;                                      % Length of the window for FFT
overlap_length  = 256;                                      % Length of overlap between windows
freqLim         = 600;                                      % Lower frequency limit (Hz)
N               = 5;                                        % Number of dominant frequencies to identify
sigma           = 15;                                       % Standard deviation for Gaussian filter (samples)


%%  Import the audio
[yS, Fs]        = audioread([dataFold filesep dataFile]);   % Import audio data, sampling frequency (Hz)
yS              = yS(:,1);                                  % Extract left audio channel

%  Import the template trigger
[yS_p, Fs_p]    = audioread([dataFold filesep trigFile]);
yS_p            = yS_p(:,1); 


%% Compute spectrograms
[s, f, t]       = spectrogram(yS, window_length, overlap_length, [], Fs); clear yS
[s_t, f_t]      = spectrogram(yS_p, window_length, overlap_length, [], Fs_p); clear yS_p

%% Find dominant frequencies in the audio trigger
p_t             = abs(s_t).^2; clear s_t
avg_p_t         = sum(p_t, 2); clear p_t
include         = f_t > freqLim; 
[~, inds]       = sort(avg_p_t(include), 'descend');
top_freqs       = f_t(include); clear f_t
top_freqs       = top_freqs(inds(1:N)); clear include inds avg_p_t
top_freqs       = ismember(f, top_freqs); clear f

%% Identify periods with these components in the full audio signal
s_filt          = s(top_freqs, :); clear s top_freqs        % Extract spectrogram data for dominant frequencies
avg_power       = mean(abs(s_filt).^2, 1); clear s_filt     % Convert to average power time series
avg_power       = avg_power / max(avg_power);               % Normalise
smth_pow        = imgaussfilt(avg_power, sigma);            % Smooth


%% Generate an interactive plot to set the threshold
figure;
go_on           = true;
thresh          = 0.3;
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
close, clear go_on t thresh smooth_pow x


%% Save the output
[~,root]        = fileparts(dataFile);
T               = array2table(trigs','VariableNames',{'TriggerTimes'});
writetable(T,[root '-triggerTimes.csv']); clear T root