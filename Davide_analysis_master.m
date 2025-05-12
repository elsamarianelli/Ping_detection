%% Master script for preprocessing and epoching EEG 
%  Elsa Marianelli, UCL (2025) zcbtetm@ucl.ac.uk
%
%  This script loads EEG data (Micromed TRC files), extracts trigger times from
%  audio files (pings), and identifies periods of electrical stimulation in the EEG.
%  It then epochs the data based on trigger times, separating trials into:
%   1) during stimulation, and
%   2) not during stimulation.
%
%  Steps (so far):
%  [1] Load EEG data into FieldTrip structure, anonymise
%  [2] Extract trigger times from audio (with optional delay correction) and 
%      identify stimulation periods from the EEG trace
%  [3] Seperate data into trial types for analysis accoridng to wether the
%      trigger time happened during stimulation period
%
%  Dependencies:
%  - FieldTrip toolbox
%  - extract_trigger_times.m
%  - extract_stim_clusters.m
%  - clean_stimulation_periods.m
%  - epoch_with_stim_and_trig_times.m
%  - plot_EEG_with_triggers.m (for visual checks)

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
    trigs     = extract_trigger_times(audio{i});  % save trigger times as excel file (seconds)
    trigs     = trigs + delay_time(i);            % add delay time to trigger times to line up with EEG  
    trigTimes = [trigTimes, trigs];               % add onto full trig time
end

% alternatively - load pre saved file (might not have delay)
% trigTable     = readtable('audio_vid_72-triggerTimes.csv');
% trigTimes    = trigTable.TriggerTimes;

% ii) Stimulation times 
ex_channel_trace = data_FT.trial{1}(3,:);          % example trace to use - looks like they all have similar activity
                                                   % in this set but check for different EEG files

% Get start and stop times for stimulation periods (with plot to check if threshold is ok) 
threshold                    = 500;                % check plot and change appropriately
merge_gap_sec                = 2;                  % threshold for what constitutes a stimulation period
[stimTimes, artifact_matrix] = extract_stim_clusters( ...
    ex_channel_trace, data_FT.time{1}, Fs, threshold, merge_gap_sec);

% option to save as excel file for later use...
% save_trig_and_stim_times(trigTimes, stimTimes, EEG_code);

%% [3] Epoching with 2 trial types 

%  1) during task period - no stimulation
%  2) during task period - overlap with stimulation 

% start by cleaning the data from the stimulation periods for each channel
threshold    = 1000;    % thresholf for what is considered a "stimulation" peak
pre_points   = 3;       % how many sample indexes before peak to remove
post_points  = 4;       % how many sample indexes after peak to remove

cleaned_trace = clean_stimulation_periods( ...
    trace, threshold, pre_points, post_points);


% get trial segments for both period (and data_epoched with is both
% together but with the trial type code 1 or 2 in trialinfo)
time.before = .5; % time before ping trigger to start trial
time.after  = 1;  % time after pint trigger to start trial

% (PLOT function for trigs and trace example overlayed in here)
[data_epoched, data_stim, data_no_stim] = epoch_with_stim_and_trig_times(...
    stimTimes, trigTimes, data_FT, time);     

%% [ongoing] Trying to clean stimulation sections and recover underlying trace 

threshold    = 1000;    % thresholf for what is considered a "stimulation" peak
pre_points   = 3;       % how many sample indexes before peak to remove
post_points  = 4;       % how many sample indexes after peak to remove

cleaned_trace = clean_stimulation_periods( ...
    trace, threshold, pre_points, post_points);

%% [4] ... Separate data based on contacts with behavioural impairment vs all contacts in IFOF

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
