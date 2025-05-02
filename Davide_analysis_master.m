%% [1] load data and get trigger times

% set audio data pair 
data_file = 'EEG_75.TRC';
audio = 'audio_vid_76.wav';

% load data in field trip format
path = 'C:/Users/Elsa Marianelli/Documents/GitHub/Ping_detection/';
cfg = [];
cfg.dataset = data_file;
cfg.channel = 'all'; 
cfg.reref = 'yes';  % re-referencing?
cfg.refmethod = 'avg'; % not sure which method to use
cfg.refchannel = 'all';
data_avg = ft_preprocessing(cfg);

% checking different channels...use to look for possible trigger file? 
cfg = [];
cfg.channel = 'MKR1+'; % trigger channel?
ft_databrowser(cfg, data_avg);

% select trigger times from corresponding audio by thresholding and save as
% excel file 
trigTimes = extract_trigger_times(audio); % save trigger times as excel file
                                          % alternatively extract presaved trig times
trigTable = readtable('audio_vid_76-triggerTimes.csv');
trigTimes_sec = trigTable.TriggerTimes;   % seconds

% check that the trig times aline with the data from a random channel
nSamples = size(data_avg.trial{1}, 2);
channel_check = data_avg.trial{1}(1, :); 
figure;
plot(1:nSamples, channel_check)
hold on; 
trigger_array = zeros(1, nSamples); trigger_array(trigSamples) =1000;
plot(1:nSamples, trigger_array(1,1:nSamples), 'r'); hold off

%% [2] Epoch data

% set trail segmenting parameters 
secs_before = .5; % seconds before
secs_after= 1;    % seconds after

% convert to EEG sampling frequency/ pre and post trial times to time stamps
trigSamples = round(trigTimes_sec * data_FT.fsample);
pretrig = round(secs_before * data_FT.fsample);   
posttrig = round(secs_after * data_FT.fsample); 

% generate trial input to cfg for field trip epoching
begsample = trigSamples - pretrig;
endsample = trigSamples + posttrig - 1;
offset = -pretrig * ones(size(trigSamples));
trl = [begsample, endsample, offset];
cfg.trl = trl;

% process data with trial epochs 
data_epoched = ft_preprocessing(cfg);

%% [4] define the contacts of interest and seperate data accordingly

%contacts with behavioural impariments in IFOF
behav_impairments = {'Am3', 'Am4', 'aIn4', 'aIn5', 'IFG4', 'IFG5', 'IFG6', 'IFG7'};

% BARD contacts in IFOF
all_in_IFOF = {'Am3', 'Am4', ...
                 'aIn3', 'aIn4', 'aIn5', 'aIn6', 'aIn7', ...
                 'LpSM3', 'LpSM4', ...
                 'LaC3', 'LaC4', 'LaC5', ...
                 'IFG2', 'IFG3', 'IFG4', 'IFG5', 'IFG6', ...
                 'mOF3', 'mOF4', 'mOF5', 'mOF6', 'mOF7', 'mOF8', 'mOF9'};

% BARD contacts in AF?
in_AF = {'pC6', 'pC7'};

% seperate data into behavioural impaired IFOF electrodes and all IFOF
% electrodes
cfg = []; 
cfg.channel = behav_impairments;
behav_impairments_data = ft_selectdata(cfg, data_epoched);

cfg.channel = all_in_IFOF;
all_in_IFOF_data = ft_selectdata(cfg, data_epoched);
