%% [1] Load data and put into FieldTrip to visualise 

% get paths 
addpath 'C:/Users/Elsa Marianelli/Documents/GitHub/Ping_detection/';                   % work comp
addpath 'C:/Users/Elsa Marianelli/Documents/GitHub/DAVIDE_data_and_docs/';            % work comp
addpath '/Users/elsamarianelli/Documents/Davide Project/DAVIDE_data_and_docs';        % laptop
addpath /Users/elsamarianelli/Documents/GitHub/fieldtrip
addpath 'C:\Users\Elsa Marianelli\Documents\GitHub\fieldtrip';

% set audio data pair (list in word doc)
EEG_code   = 'EEG_71';
data_file  = [EEG_code '.TRC'];
audio      = {'audio_vid_72.wav'};             % can have more than 2 if there are multiple videos for an EEG code
delay_time = [142/1000];                       % delay of video start time compared to EEG (in s) - from word doc

% configure for preprocessing
cfg             = [];
cfg.dataset     = data_file;
cfg.channel     = 'all';
data_FT         = ft_preprocessing(cfg);       % load data into FieldTrip structure

% anonymise patient info!!
data_FT.hdr.orig.name      = 'anon';
data_FT.hdr.orig.surname   = 'anon';
data_FT.hdr.subjectname    = 'anon';

% checking different channels - MRK1+ has 1s time steps for a full cycle as reference
cfg.channel     = 'MKR1+';
ft_databrowser(cfg, data_FT);

% get sampling frequency (Fs) for later
Fs = data_FT.fsample;  

%% [2] Extract trigger times and stimulation times to save

% i) Get trigger times from audio (ping sounds) and add in appropriate delay
%    - if more than one video per EEG allows chaining of trigger times
trigTimes = [];
for i = 1:length(audio)
    trigs     = extract_trigger_times(audio{i});             % save trigger times as excel file (seconds)
    trigs     = trigs + delay_time(i);                       % add delay time to trigger times to line up with EEG  
    trigTimes = [trigTimes, trigs];                           % add onto full trig time
end

% alternatively - load pre saved file (might not have delay)
% trigTable     = readtable('audio_vid_72-triggerTimes.csv'); % alternatively extract presaved trig times
% trigTimes    = trigTable.TriggerTimes;

% ii) Stimulation times 
ex_channel_trace = data_FT.trial{1}(3,:);                    % example trace to use - looks like they all have similar activity
                                                             % in this set but check for different EEG files

% Get start and stop times for stimulation periods (with plot to check if threshold is ok) 
threshold                    = 500;                           % check plot and change appropriately
merge_gap_sec                = 2;                             % threshold for what constitutes a stimulation period
[stimTimes, artifact_matrix] = extract_stim_clusters(ex_channel_trace, data_FT.time{1}, Fs, threshold, merge_gap_sec);

% option to save as excel file for later use...
% save_trig_and_stim_times(trigTimes, stimTimes, EEG_code);

%% Epoching with 2 trial types 
%  1) during task period - no stimulation
%  2) during task period - overlap with stimulation 

% first get all possible indexes where there is a stimulation period
stimSamples     = arrayfun(@(s,e) round(s*Fs):round(e*Fs), stimTimes(:,1), stimTimes(:,2), 'UniformOutput', false);
allStimIdxs     = [stimSamples{:}];                           % flatten into a vector

% then compare these to the trig times, to get trig times in and out of stim periods
trigTimes_idx           = round(trigTimes * Fs);
trigs_during_stim       = trigTimes_idx(ismember(trigTimes_idx, allStimIdxs))';      
trigs_not_during_stim   = trigTimes_idx(~ismember(trigTimes_idx, allStimIdxs))';     

% plot to visualise and remove out of bounds - ASK DAVIDE ABOUT WHY THIS EXISTS??
out_of_bounds           = plot_EEG_with_triggers(data_FT, trigs_not_during_stim);    % also returns trigSample not out of bounds
trigs_not_during_stim   = trigs_not_during_stim(~ismember(trigs_not_during_stim, out_of_bounds)); % REMOVE out of bounds triggers

% get in cfg.trl formats
% get cfg trial format (divide by Fs because func does this for you)
time_before_ping        = 0.5;                                
time_after_ping         = 1;
[formated_stim, ~]      = make_epoching_trial_cfg(trigs_during_stim / Fs, data_FT, time_before_ping, time_after_ping);
[formated_no_stim, ~]   = make_epoching_trial_cfg(trigs_not_during_stim / Fs, data_FT, time_before_ping, time_after_ping);

% add trial label for field trip 1 = during stim, 2 = not during stim
formated_stim           = [formated_stim, ones(size(formated_stim,1), 1)];            % label = 1
formated_no_stim        = [formated_no_stim, 2 * ones(size(formated_no_stim,1), 1)];   % label = 2

% Combine
cfg                     = [];
cfg.dataset             = data_file;
cfg.trl                 = [formated_stim; formated_no_stim];

% final check to remove any trials out of bounds (might be a problem if the full trial window goes out of bounds even if the trigger time wasn't)
nSamples                = size(data_FT.trial{1}, 2);
cfg.trl                 = cfg.trl(cfg.trl(:,1) >= 1 & cfg.trl(:,2) <= nSamples, :); 

% Process data
data_FT.cfg             = cfg;
data_epoched            = ft_preprocessing(cfg);

% Stim trials
cfg = [];
cfg.trials = find(data_epoched.trialinfo == 1);
data_stim = ft_selectdata(cfg, data_epoched);

% No stim trials
cfg.trials = find(data_epoched.trialinfo == 2);
data_no_stim = ft_selectdata(cfg, data_epoched);
%% [ongoing] frequency analyis  - currently with settings from FT example

cfg              = [];
cfg.output       = 'pow';
cfg.channel      = 'all';
cfg.method       = 'mtmconvol';
cfg.taper        = 'hanning';
cfg.foi          = 2:1:60;                         % analysis 2 to 30 Hz in steps of 2 Hz
cfg.t_ftimwin    = ones(length(cfg.foi),1).*0.5;   % length of time window = 0.5 sec
cfg.toi          = -1:0.05:1;

freq_anal = ft_freqanalysis(cfg, data_FT);
for i = 1:10
    figure; imagesc(freq_anal.powspctrm(i));
end

%% [ongoing] Trying to clean stimulation sections and recover underlying trace 

threshold    = 1000;
pre_points   = 3;
post_points  = 4;

cleaned_trace = clean_stimulation_periods(trace, threshold, pre_points, post_points);
%% [4] Separate data based on contacts with behavioural impairment vs all contacts in IFOF

% contacts with behavioural impairments in IFOF
behav_impairments = {'Am3', 'Am4', 'aIn4', 'aIn5', 'IFG4', 'IFG5', 'IFG6', 'IFG7'};

% BARD contacts in IFOF
all_in_IFOF      = {'Am3', 'Am4', ...
                    'aIn3', 'aIn4', 'aIn5', 'aIn6', 'aIn7', ...
                    'LpSM3', 'LpSM4', ...
                    'LaC3', 'LaC4', 'LaC5', ...
                    'IFG2', 'IFG3', 'IFG4', 'IFG5', 'IFG6', ...
                    'mOF3', 'mOF4', 'mOF5', 'mOF6', 'mOF7', 'mOF8', 'mOF9'};

% BARD contacts in AF?
in_AF            = {'pC6', 'pC7'};

% separate data into behavioural impaired IFOF electrodes and all IFOF electrodes
cfg                  = [];
cfg.channel          = behav_impairments;
behav_impairments_data = ft_selectdata(cfg, data_epoched);

cfg.channel          = all_in_IFOF;
all_in_IFOF_data     = ft_selectdata(cfg, data_epoched);
