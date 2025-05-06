function save_trig_and_stim_times(trigTimes, stimTimes, EEG_code)
    % save_trig_and_stim_times(trigTimes, stimTimes, EEG_code)
    % Asks if you want to save an Excel file with ping and stim times
    
    % Ask user
    answer = questdlg('Do you want to save the trigger and stim times as Excel?', ...
                      'Save Excel File', 'Yes', 'No', 'No');

    if strcmp(answer, 'Yes')
        % Pad shorter arrays
        trigTimes = trigTimes(:)';  % ensure row
        maxLen = max(length(trigTimes), size(stimTimes,1));
        trigTimes(end+1:maxLen) = NaN;
        stimStarts = stimTimes(:,1);
        stimEnds = stimTimes(:,2);
        stimStarts(end+1:maxLen,1) = NaN;
        stimEnds(end+1:maxLen,1) = NaN;

        % Build table and save
        T = table(trigTimes', stimStarts, stimEnds, ...
            'VariableNames', {'Ping_times_sec','Stim_start_times_sec','Stim_end_times_sec'});
        filename = fullfile([EEG_code '_triggers_and_stim_times.xlsx']);
        writetable(T, filename);
        disp(['Excel file saved as: ' filename]);
    else
        disp('Save canceled.');
    end
end
