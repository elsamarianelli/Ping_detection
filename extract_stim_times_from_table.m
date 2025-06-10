function stim_table = extract_stim_times_from_table(T, start_time_str)
% EXTRACT_STIM_TIMES_FROM_TABLE Extracts stim periods from table
%
% Inputs:
%   T               - Table with stim times (col 1) and stim text (col 5)
%   start_time_str  - Start time of video (e.g., '11:41:49')
%
% Output:
%   stim_table - Table with Start, End, Channel_1, Channel_2

    start_time = datetime(start_time_str, 'InputFormat', 'HH:mm:ss');
    n = height(T);

    % Preallocate
    start = zeros(n, 1);
    end_   = zeros(n, 1);
    ch1      = strings(n, 1);
    ch2      = strings(n, 1);

    for i = 1:n
        % Extract time only (ignore date)
        full_time = datetime(T{i,1}{1}, 'InputFormat', 'dd/MM/yyyy HH:mm:ss');
        stim_time = timeofday(full_time);
        stim_start = timeofday(start_time);
       
        % Time difference in seconds
        time_diff = seconds(stim_time - stim_start);
        start(i) = round(time_diff);

        % Parse stimulation description
        stim_str = T{i,5}{1};
        tokens = regexp(stim_str, '(?<ch1>\w+)-(?<ch2>\w+).*?(?<dur>\d+)\s*µ?sec', 'names');

        if ~isempty(tokens)
            ch1(i) = tokens.ch1;
            ch2(i) = tokens.ch2;
            dur = str2double(tokens.dur) / 1000;  % µs to ms
        else
            dur = NaN;
        end

        end_(i) = start(i) + dur;
    end

    % Output table
    stim_table = table(start, end_, ch1, ch2, ...
                       'VariableNames', {'Start', 'End', 'Channel_1', 'Channel_2'});

    clear full_time stim_time stim_start time_diff stim_str tokens dur i n
    
end
