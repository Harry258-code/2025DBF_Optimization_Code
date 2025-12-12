% ======================================
% Sweep Wingspan (3–5 ft) & Banner Length (0.252–10 m)
% ======================================

n = 100;                         
xmin_ft = 3; xmax_ft = 5;       % wingspan range (feet)
jmin_m = 0; jmax_m = 6.05;    % banner range (meters)

% Preallocate arrays
Wingspan_ft = zeros(1, n);
Banner_ft = zeros(1, n);
Score3 = zeros(n, n);
Speed3 = zeros(n, n);

for x = 1:n
    % Wingspan in feet (for plotting)
    span_ft = xmin_ft + (x-1) * ((xmax_ft - xmin_ft) / (n - 1));
    % Convert to meters for scoring function
    span_m = span_ft * 0.3048;
    Wingspan_ft(x) = span_ft;

    for j = 1:n
        % Banner in meters (for combined_score)
        banner_m = jmin_m + (j-1) * ((jmax_m - jmin_m) / (n - 1));
        % Convert to feet for plotting
        banner_ft = banner_m / 0.3048;
        Banner_ft(j) = banner_ft;

        % Call your scoring function (everything in meters)
        [~, ~, Speed3(x,j), Score3(x,j), ~, ~, ~, ~, ~, ~, ~] = ...
            combined_score(100, span_m, 7, 1, banner_m);
    end
end

% ======================================
% Create meshgrid for plotting
% ======================================
[X, Y] = meshgrid(Banner_ft, Wingspan_ft);

figure;
surf(X, Y, Score3);
xlabel('Banner Length (ft)');
ylabel('Wingspan (ft)');
zlabel('Score (M3)');
% title('M3 Scoring vs Wingspan and Banner Length');
colorbar;
shading interp;

% ======================================
% Helper Function
% ======================================
function num_laps = numLaps(speedm2)
    track_distance = 2500;   % meters
    mission_time = 600;      % seconds
    lap_time = track_distance / speedm2;
    num_laps = floor(mission_time / lap_time);
end