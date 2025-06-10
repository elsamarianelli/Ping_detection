function [data_epoched, data_stim, data_no_stim] = epoch_with_stim_and_trig_times(stimTimes, trigTimes, data_FT, time)
%% Function to epoch data based on stimulation periods and trigger times
%  Elsa Marianelli, UCL (2025) zcbtetm@ucl.ac.uk
%
%  This function epochs continuous data using provided stimulation periods
%  and trigger times. Trials are labeled as "during stimulation" or
%  "no stimulation" based on whether the trigger falls within a stimulation period.
%
%  Inputs:
%  stimTimes   - [N x 2] array of stimulation periods (start and end times in seconds)
%  trigTimes   - [M x 1] vector of trigger times (in seconds)
%  data_FT     - FieldTrip data structure (already preprocessed)
%  time        - struct with fields:
%                  .before : time (sec) before each trigger to include
%                  .after  : time (sec) after each trigger to include
%
%  Outputs:
%  data_epoched - FieldTrip data structure containing all trials, with trialinfo
%                 coded as 1 (stim) or 2 (no stim)
%  data_stim    - FieldTrip data structure containing only trials during stimulation
%  data_no_stim - FieldTrip data structure containing only trials outside stimulation

%% [1] get all possible indexes where there is a stimulation period
Fs = data_FT.fsample; % sampling frequency 
stimSamples     = arrayfun(@(s,e) round(s*Fs):round(e*Fs), stimTimes(:,1), stimTimes(:,2), 'UniformOutput', false);
allStimIdxs     = [stimSamples{:}];                           % flatten into a vector

%% [2] compare these to the trig times, to get trig times in and out of stim periods
trigTimes_idx           = round(trigTimes * Fs);
trigs_during_stim       = trigTimes_idx(ismember(trigTimes_idx, allStimIdxs))';      
trigs_not_during_stim   = trigTimes_idx(~ismember(trigTimes_idx, allStimIdxs))';     

%% [3] plot to visualise and remove out of bounds - ASK DAVIDE ABOUT WHY THIS EXISTS??
out_of_bounds           = plot_EEG_with_triggers(data_FT, trigs_not_during_stim);    % also returns trigSample not out of bounds
trigs_not_during_stim   = trigs_not_during_stim(~ismember(trigs_not_during_stim, out_of_bounds)); % REMOVE out of bounds triggers

%% [4] get cfg trial format (divide by Fs because func does this for you)
[formated_stim, ~]      = make_epoching_trial_cfg(trigs_during_stim / Fs, data_FT, time.before, time.after);
[formated_no_stim, ~]   = make_epoching_trial_cfg(trigs_not_during_stim / Fs, data_FT,  time.before, time.after);

%% [5] add trial label for field trip 1 = during stim, 2 = not during stim
formated_stim           = [formated_stim, ones(size(formated_stim,1), 1)];            % label = 1
formated_no_stim        = [formated_no_stim, 2 * ones(size(formated_no_stim,1), 1)];   % label = 2

%% [6] Combine
cfg = [];
cfg.trl = [formated_stim; formated_no_stim];

% remove any out-of-bounds trials:
nSamples = size(data_FT.trial{1}, 2);
cfg.trl = cfg.trl(cfg.trl(:,1) >= 1 & cfg.trl(:,2) <= nSamples, :);

% Now use ft_redefinetrial to epoch the existing data_FT (no need for data_file)
data_epoched = ft_redefinetrial(cfg, data_FT);

%% [9] Split into...
% 1) Stim trials
cfg = [];
cfg.trials = find(data_epoched.trialinfo == 1);
data_stim = ft_selectdata(cfg, data_epoched);

% 2) No stim trials
cfg.trials = find(data_epoched.trialinfo == 2);
data_no_stim = ft_selectdata(cfg, data_epoched);

end