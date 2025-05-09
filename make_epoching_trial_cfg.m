function [array, trigSamples] = make_epoching_trial_cfg(trigTimes, data_FT, secs_before, secs_after)
% creates cfg.trl array for FieldTrip epoching, contains begining, end, 
% and offset for that trial

% Inputs
% - trigTimes: vector of trigger times (in seconds)
% - data_FT: FieldTrip data structure (needs .fsample)
% - secs_before: seconds before trigger to include
% - secs_after: seconds after trigger to include
%
% Output
% - array to go into cfg.trl
    

    % Convert to samples
    trigSamples = round(trigTimes * data_FT.fsample);
    pretrig = round(secs_before * data_FT.fsample);
    posttrig = round(secs_after * data_FT.fsample);

    % Create trial matrix
    begsample = trigSamples - pretrig;
    endsample = trigSamples + posttrig - 1;
    offset = -pretrig * ones(size(trigSamples));

    % For cfg.trl
    array = [begsample, endsample, offset];
end
