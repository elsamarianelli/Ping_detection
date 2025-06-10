%% ========================================================
%  MASTER SCRIPT: EEG STIMULATION AND TRIAL ANALYSIS
%  - Preprocessing, trigger alignment, trial epoching
%  - Separation by stimulation type & contact grouping
% =========================================================

%% [1] Setup and Initial Configuration
% ------------------------------------

% Add data and toolbox paths (adjust for laptop/work machine)
addpath('C:/Users/Elsa Marianelli/Documents/GitHub/Ping_detection/');
addpath('C:/Users/Elsa Marianelli/Documents/GitHub/DAVIDE_data_and_docs/');
addpath('/Users/elsamarianelli/Documents/Davide Project/DAVIDE_data_and_docs');
addpath('/Users/elsamarianelli/Documents/GitHub/fieldtrip');
addpath('C:/Users/Elsa Marianelli/Documents/GitHub/fieldtrip');

% Audio-video mapping (can be more than one)
EEG_code   = 'EEG_75';
data_file  = [EEG_code '.TRC'];
audio      = {'audio_vid_76.wav', 'audio_vid_77.wav'};
delay_time = [143/1000, 2480533/1000];  % delay of video vs EEG (in sec)

%% [2] Load EEG Data and Preprocess via FieldTrip
% -----------------------------------------------

cfg             = [];
cfg.dataset     = data_file;
cfg.channel     = 'all';
data_FT         = ft_preprocessing(cfg);  % Load EEG

% Anonymize patient metadata
data_FT.hdr.orig.name      = 'anon';
data_FT.hdr.orig.surname   = 'anon';
data_FT.hdr.subjectname    = 'anon';

% Launch browser for visual channel inspection
cfg.channel = [];
ft_databrowser(cfg, data_FT);

Fs = data_FT.fsample;  % Sampling frequency

%% [3] Load Stim Tables and Extract Stimulation Times 
% ---------------------------------------------------

file_path = 'Davide_Project/DAVIDE_data_and_docs/';
stim_file = 'bard_2-20230301_114215-20240820_110340_WM_stim';
stim_times_file = readtable(stim_file);

% Read ping stim labels (during stim or not) - not sure this is helpful
ping_stims = readtable('AM3_AM4');
Stimulated = ping_stims.Stimulated;

% Convert stim table to usable format (offset-adjusted)
stim_table = extract_stim_times_from_table(stim_times_file, '11:41:49');

%% [4] Trigger Detection from Audio Files
% ---------------------------------------

% Get with interactive plot
trigTimes = [];
for i = 1:length(audio)
    trigs = extract_trigger_times(audio{i});
    trigTimes = [trigTimes, trigs + delay_time(i)];
end

% OR get presaved ones
% trigTimes = [];
% for i = 1:length(audio)
%    file_name = [erase(audio{i}, '.wav') '-triggerTimes.csv'];
%    trigTable    = readtable(filename); 
%    trigTimes    = trigTable.TriggerTimes;
%    trigTimes = [trigTimes, trigs + delay_time(i)];
% end

%% [5] Extract Stimulation Windows from EEG Trace
% -----------------------------------------------

trace_idx = 3;  % 3 = Am3, 4 = Am4 (see data_FT.label for more)
merge_gap_sec = 2; % gap (in seconds) below which clusters are merged

ex_trace = data_FT.trial{1}(trace_idx, :);
timeVec  = data_FT.time{1};

[stimTimes, artifact_matrix] = extract_stim_clusters(ex_trace, timeVec, Fs, threshold, merge_gap_sec);

% option to save
% save_trig_and_stim_times(trigTimes, stimTimes, EEG_code);

%% [6] Align Extracted Stim Windows with Log Times (for visual validation)
% ------------------------------------------------------------------------

% Estimate delay between extracted and logged stim - need to set alignment
% indices manually (here the 6th extracted stimulation time aligns with the
% 2nd one from the excel file)
first = stimTimes(8, 1);
match_with = stim_table.Start(2);
delay_offset = first - match_with;

% Adjust table stim times
stim_table_new = stim_table;
stim_table_new.Start = stim_table.Start + delay_offset;
stim_table_new.End = stim_table.End + delay_offset;

% Visual alignment
plot_trace_with_stim_sources(ex_trace, timeVec, stimTimes, stim_table_new)

%% [7] Match Pings to Stim Windows
% --------------------------------
matchFlags = matchPingstoStimWindows(trigTimes, stim_table_new);

%% [8] Epoch Data into triggers which occured Stim and No-Stim Trials
% --------------------------------------------

% Get stim indices in samples
stimSamples = arrayfun(@(s,e) round(s*Fs):round(e*Fs), ...
    stimTimes(:,1), stimTimes(:,2), 'UniformOutput', false);
allStimIdxs = [stimSamples{:}];

trigSamples_idx = round(trigTimes * Fs);
in_stim         = ismember(trigSamples_idx, allStimIdxs);

trigs_during_stim     = trigSamples_idx(in_stim)';
trigs_not_during_stim = trigSamples_idx(~in_stim)';

% Remove out-of-bound triggers
out_of_bounds = plot_EEG_with_triggers(data_FT, trigs_not_during_stim);
trigs_not_during_stim = setdiff(trigs_not_during_stim, out_of_bounds);

% Create FieldTrip .trl structures
time_before = 0.5;
time_after  = 1;

[trl_stim, ~]    = make_epoching_trial_cfg(trigs_during_stim/Fs, data_FT, time_before, time_after);
[trl_no_stim, ~] = make_epoching_trial_cfg(trigs_not_during_stim/Fs, data_FT, time_before, time_after);

% Add labels: 1 = stim, 2 = no stim
trl_stim    = [trl_stim, ones(size(trl_stim,1), 1)];
trl_no_stim = [trl_no_stim, 2 * ones(size(trl_no_stim,1), 1)];

cfg = [];
cfg.dataset = data_file;
cfg.trl     = [trl_stim; trl_no_stim];

% Remove out-of-bounds trials
nSamples = size(data_FT.trial{1}, 2);
cfg.trl  = cfg.trl(cfg.trl(:,1) >= 1 & cfg.trl(:,2) <= nSamples, :);

% Epoch
data_FT.cfg = cfg;
data_epoched = ft_preprocessing(cfg);

% Separate stim vs no stim
cfg = [];
cfg.trials = find(data_epoched.trialinfo == 1);
data_stim = ft_selectdata(cfg, data_epoched);

cfg.trials = find(data_epoched.trialinfo == 2);
data_no_stim = ft_selectdata(cfg, data_epoched);

%% [9] Clean Stim Artifacts from Epoched Trials
% this should only really apply to the stimulus trials - as the non
% stimulus period trials should have any high frequency activity
% ---------------------------------------------

threshold    = 1000;
pre_points   = 3;
post_points  = 4;

cleaned_data = data_epoched;

for trialIdx = 1:length(data_epoched.trial)
    trial_data = data_epoched.trial{trialIdx};
    for chanIdx = 1:size(trial_data,1)
        trace = trial_data(chanIdx, :);
        cleaned_trace = clean_stimulation_periods(trace, threshold, pre_points, post_points);
        cleaned_data.trial{trialIdx}(chanIdx, :) = cleaned_trace;
    end
end


%% [extra] Separate by Anatomical Contact Groups
% -------------------------------------------

behav_impairments = {'Am3', 'Am4', 'aIn4', 'aIn5', 'IFG4', 'IFG5', 'IFG6', 'IFG7'};
all_in_IFOF = {'Am3', 'Am4', ...
               'aIn3', 'aIn4', 'aIn5', 'aIn6', 'aIn7', ...
               'LpSM3', 'LpSM4', ...
               'LaC3', 'LaC4', 'LaC5', ...
               'IFG2', 'IFG3', 'IFG4', 'IFG5', 'IFG6', ...
               'mOF3', 'mOF4', 'mOF5', 'mOF6', 'mOF7', 'mOF8', 'mOF9'};

cfg = [];
cfg.channel = behav_impairments;
behav_impairments_data = ft_selectdata(cfg, data_epoched);

cfg.channel = all_in_IFOF;
all_in_IFOF_data = ft_selectdata(cfg, data_epoched);
