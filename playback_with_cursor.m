function playback_with_cursor(yS, Fs, t, smth_pow, start_time, threshold)
    % Playback function to visualize smoothed magnitude and play audio
    %
    % INPUTS:
    %   yS        - Audio signal
    %   Fs        - Sampling frequency
    %   t         - Time vector for the magnitude plot
    %   smth_pow  - Smoothed magnitude data
    %   start_time - Time (in seconds) to start playback from
    %   threshold - Threshold value for visualization
    %
    % Example usage:
    % playback_with_cursor(yS, Fs, t, smth_pow, 770, 0.5);

    % Find the index corresponding to start_time
    start_idx = find(t >= start_time, 1, 'first');

    % Plot Smoothed Magnitude with Threshold and Cursor
    figure;
    plot(t(start_idx:end), smth_pow(start_idx:end), 'b', 'LineWidth', 2); % Smoothed magnitude plot
    hold on;
    yline(threshold, 'r--', 'LineWidth', 2); % Red dashed threshold line
    cursor = xline(start_time, 'p', 'LineWidth', 2); % Initial cursor at start_time
    xlabel('Time (s)');
    ylabel('Normalized Magnitude');
    title('Smoothed magnitude of Trigger frequencies above threshold');
    legend('Smoothed Magnitude', 'Threshold', 'Playback Cursor');
    grid on;
    hold off;

    % Set Up Audio Player Starting at start_time
    start_sample = round(start_time * Fs);
    yS_trimmed = yS(start_sample:end); % Trim audio to start from start_time
    player = audioplayer(yS_trimmed, Fs);
    play(player);

    % Track Cursor in Real-Time
    while isplaying(player)
        % Calculate current time relative to the original audio
        current_time = start_time + (player.CurrentSample - 1) / Fs;
        cursor.Value = min(current_time, max(t)); % Keep cursor within time range
        pause(0.05); % Update every 50ms
    end

    stop(player); % Stop playback when finished
end

