

function [m2_speed, score_m2, m3_speed, score_m3, aoa_m2, aoa_m3, totalDrag_m2, totalDrag_m3, fuse_length, gm_Time, combined] = combined_score(battery_wh, w_span, AR, num_Payload, Banner_length)

% Fixing Values

battery_wh = battery_wh * 0.85; % safe power consumtion

% Input Variables

avionics_Base = 300; % 300 grams
avionics_motor = 200; % 200 grams
avionics_battery = 600; % 600 grams 
bannerW0 = Banner_length* 60;
avionics_w0 = avionics_Base + avionics_battery + avionics_motor + bannerW0; % total avionics weight



% calculate correct passenger num
num_Payload = floor(num_Payload);
num_passengers = num_Payload * 3;

W0_P = 19.84; % weight in grams of ducks .7 oz
W0_C = 170.10; % weight in grams of cargo 6 oz

W0_m2 = W0_C * num_Payload + W0_P * num_passengers + avionics_w0;
W0_m2 = W0_m2 * 1.6; % Assuming struc mass fraction to be 50%
W0_m3 = W0_m2 - (W0_C * num_Payload + W0_P * num_passengers);
W0_m2 = W0_m2 / 1000;

W0_m3 = W0_m3 / 1000;

W0_Nm2 = W0_m2 * 9.81;
W0_Nm3 = W0_m3 * 9.81;

[m2_speed, score_m2, m3_speed, score_m3, aoa_m2, totalDrag_m2, aoa_m3, totalDrag_m3, fuse_length] = maxSpeed(AR, w_span, battery_wh, num_passengers, num_Payload, W0_Nm2, W0_Nm3, Banner_length);
%fprintf('Score M3: %.3f', score_m3)
%%%%%%%%% Ground Mission %%%%%%%%%%%%%%
gm_Time = 12 + num_passengers * 2 + num_Payload * 1;
gm_Score = 19 / gm_Time;
gm_Time = gm_Score;
% gm_Score = 0;
combined = score_m3 + score_m2 + gm_Score;

end

