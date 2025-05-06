function cfg = make_epoching_trial_cfg(trigTimes, data_FT, secs_before, secs_after)
    % make_trial_cfg: creates cfg.trl for FieldTrip epoching
    % 
    % Inputs:
    % - trigTimes: vector of trigger times (in seconds)
    % - data_FT: FieldTrip data structure (needs .fsample)
    % - secs_before: seconds before trigger to include
    % - secs_after: seconds after trigger to include
    %
    % Output:
    % - cfg: struct with .trl field ready for ft_preprocessing

    % Convert to samples
    trigSamples = round(trigTimes * data_FT.fsample);
    pretrig = round(secs_before * data_FT.fsample);
    posttrig = round(secs_after * data_FT.fsample);

    % Create trial matrix
    begsample = trigSamples - pretrig;
    endsample = trigSamples + posttrig - 1;
    offset = -pretrig * ones(size(trigSamples));

    % Build cfg
    cfg = [];
    cfg.trl = [begsample, endsample, offset];
    cfg.channel = [];  % include all channels (or set to subset later)
end
