% ======================================
% Sweep Payload to Evaluate M2 Score vs Ground Mission Time
% ======================================

n = 100;                         
battery_wh = 80;           % fixed battery capacity (Wh)
jmin = 1; jmax = 35;       % payload range (kg)

Payloads = linspace(jmin, jmax, n);
Score2 = zeros(1, n);
gm_Time2 = zeros(1, n);
Speed2 = zeros(1, n);
Score3 = zeros(n, n);
Speed3 = zeros(n, n);

for j = 1:n
    Payload = Payloads(j);

    % Call your scoring function (battery fixed at 80 Wh)
    [Speed2(j), Score2(j), Speed3(x,j), Score3(x,j), ~, ~, ~, ~, ~, gm_Time2(j), ~] = ...
        combined_score(battery_wh, 1.52, 5, Payload, 0.252);
end

% ======================================
% Plot M2 Score vs Ground Mission Time
% ======================================
figure;
plot(gm_Time2, Score2, 'LineWidth', 2);
hold on;
grid on;
xlabel('Ground Mission Score');
ylabel('Score (M2)');
title('M2 Scoring vs Ground Mission Score (80 Wh, Varying Payload)');

% Add a point at M2 score = 0.58
targetScore = 0.58;
% Find or define the corresponding gm_Time2 value (for example, interpolate)
[~, idx] = min(abs(Score2 - targetScore)); % find closest value
plot(gm_Time2(idx), Score2(idx), 'bo', 'MarkerSize', 4, 'MarkerFaceColor', 'b');