% ======================================
% Sweep Payload and Banner Length to Evaluate Mission Scores
% ======================================

battery_wh = 100;                        % fixed battery capacity (Wh)
payload_range = linspace(1, 20, 20);     % payload range (kg)
banner_range = linspace(2, 10, 9);       % banner length range (m)

% Preallocate storage
M2 = zeros(length(payload_range), length(banner_range));
M3 = zeros(length(payload_range), length(banner_range));
GM = zeros(length(payload_range), length(banner_range));
Combined = zeros(1, length(payload_range));   % optimized combined per payload

% ======================================
% Evaluate All Payload / Banner Combinations
% ======================================
for i = 1:length(payload_range)
    for j = 1:length(banner_range)
        payload = payload_range(i);
        banner = banner_range(j);

        % Call scoring function (battery fixed)
        % gm_Score is the 10th output based on your original code
        [~, M2(i,j), ~, M3(i,j), ~, ~, ~, ~, ~, GM(i,j), ~] = ...
            combined_score(battery_wh, 1.52, 5, payload, banner);
    end

    % Combine all scores at this payload across banner lengths
    total_scores = M2(i,:) + M3(i,:) + GM(i,:);
    [Combined(i), bestBannerIdx] = max(total_scores);   % best banner per payload

    % Store best scores for that banner
    bestM2(i) = M2(i, bestBannerIdx);
    bestM3(i) = M3(i, bestBannerIdx);
    bestGM(i) = GM(i, bestBannerIdx);
    bestBanner(i) = banner_range(bestBannerIdx);
end

% ======================================
% Plot All Scores on a Single Y-Axis (Max = 2)
% ======================================
figure;
hold on; grid on;

plot(payload_range, bestM2, 'r--', 'LineWidth', 2);
plot(payload_range, bestM3, 'g:', 'LineWidth', 2);
plot(payload_range, bestGM, 'b-', 'LineWidth', 2);
plot(payload_range, Combined, 'k-', 'LineWidth', 2);

xlabel('Number of Pucks');
ylabel('Score');
% title('General performance vs payload (100 Wh)');
legend('M2 Score', 'M3 Score', 'Ground Mission Score', 'Combined Score', ...
       'Location', 'best');

ylim([0 2]);  % keep consistent visual scale
xlim([min(payload_range) max(payload_range)]);

hold off;