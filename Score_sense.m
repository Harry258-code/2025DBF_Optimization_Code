% Define parameters
n = 100;                         
xmin = 0; xmax = 100;       
jmin = 0; jmax = 25;             

battery_wh = zeros(1, n);
num_payload = zeros(1, n);
Score2 = zeros(n, n);  % ensure 2D (battery vs payload)
Speed2 = zeros(n, n);

for x = 1:n
    b_wh = xmin + (x-1) * ((xmax - xmin) / (n - 1));
    battery_wh(x) = b_wh;

    for j = 1:n
        Payload = jmin + (j-1) * ((jmax - jmin) / (n - 1));
        num_payload(j) = Payload;

        % Call your scoring function
        [Speed2(x,j), Score2(x,j), ~, ~, ~, ~, ~, ~, ~, ~, ~] = ...
            combined_score(b_wh, 1.52, 5, Payload, 0.252);
    end
end

% Create meshgrid for plotting
[X, Y] = meshgrid(num_payload, battery_wh);

% Now plot
figure;
surf(X, Y, Score2);

xlabel('Payload Count');
ylabel('Battery Capacity (Wh)');
zlabel('Score (M2)');
title('M2 Scoring vs Passenger Count and Battery Capacity');
colorbar;
shading interp;

function[num_laps] = numLaps(speedm2)
    track_distance = 2500;
    lap_time_m2 = track_distance / speedm2; % seconds

    mission_time = 600; % total allowed time (s)
    num_laps = floor(mission_time / lap_time_m2);
end