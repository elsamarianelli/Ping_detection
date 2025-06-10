function matchFlags = matchPingstoStimWindows(trigTimes, stim_table_new)
%%
matchFlags = zeros(length(trigTimes), 1);
stimTimes_new = stim_table_new{:, 1:2};

for i = 1:length(trigTimes)
    for j = 1:size(stimTimes_new, 1)
        if trigTimes(i) >= stimTimes_new(j,1) && trigTimes(i) <= stimTimes_new(j,2)
            matchFlags(i) = 1;
            break;
        end
    end
end

% Plot matches vs mismatches
figure;
hold on;

% Patches for stim windows
for i = 1:size(stimTimes_new,1)
    patch([stimTimes_new(i,1), stimTimes_new(i,2), stimTimes_new(i,2), stimTimes_new(i,1)], ...
          [-1, -1, 1, 1], [1 0.8 0.8], 'EdgeColor', 'none', 'FaceAlpha', 1);
end

% Plot pings
stem(trigTimes(matchFlags==0), -1*ones(sum(matchFlags==0),1), 'b', 'filled');
stem(trigTimes(matchFlags==1), -1*ones(sum(matchFlags==1),1), 'r', 'filled');
title('Ping Times vs. Stimulation Matches');
xlabel('Time (s)'); ylabel('Match');
legend('Stim Window', 'No Match', 'Match');

end