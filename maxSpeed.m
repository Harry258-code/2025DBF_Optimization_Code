function [m2_speed, top_score_m2, m3_speed, top_score_m3, aoa_m2, totalDrag_m2, aoa_m3, totalDrag_m3, fuse_length] = maxSpeed(AR, w_span, battery_wh, num_passengers, num_payload, W0_m2, W0_m3, Banner_length)

m2_speed = 0;
m3_speed = 0;
aoa_m2 = 0;
aoa_m3 = 0;
totalDrag_m2 = 0;
totalDrag_m3 = 0;
fuse_length = 0;

% constants
e = .85;      % oswalds e factor
rho = 1.11; %air density, wichita historic average, kg/m^3
mu = 1.85e-5;     % at ~25 °C in Wichita

Ip1 = 6; % income per passenger
Ip2 = 2; % per pass lap
Ic1 = 10; % per cargo
Ic2 = 8; % cargo lap

Ce = 10; % base cost per lap
Cp = 0.5; % passenger cost per lap
Cc = 2;   % cargo cost per lab

top_score_m2 = 0;
top_score_m3 = 0;

% variables
% fuse_w = .127;
% fuse_h = .0939;
% fuse_cross = 4.56e-5;

[fuse_w, fuse_h, fuse_cross, sectionLength, numDucks] = fuselage('1'); % type: 1, 2.1, 3, 4


chord = w_span/AR;
w_area = chord * w_span;

EF = battery_wh / 100; % efficiency Factor
RAC = 0.05 * (w_span* 3.28) + .75; % Plane Size

Airfoil = 'SD7062'; % SD7043, S3016, AG12, AG14, AG27?

eta_prop = 0.7;   % propeller efficiency
eta_motor = 0.85; % motor efficiency
mew = eta_motor * eta_prop; % electric Efficiency

% normalizing variables
Max_Score_M2 = 1751.88; % UPDATE THIS LATER
% Max_Score_M3 = 828.49;
Max_Score_M3 = 800;

[inValidM2,fuse_length] = FuseCheck(w_span, num_passengers, sectionLength, numDucks);


%%%%%%%%%%%%%% Wing profile %%%%%%%%%%%%%%%%% 30 %
S_wet = 2 * w_span * chord * 1.1; % 2 * S_wing * wetted area Factor
FF = 1.35; % average value for form factor
Q = 1.1; % interference Factor


%%%%%%%%%%%%% Fuselage Form and Friction %%%%% 15-20%

% Skin Friction
S_wetFuse = 2 * fuse_h * fuse_length + 2 * fuse_w * fuse_length;

% Form
Cd_fuseForm = 0.2; % bulky body, not aerodynamic

%%%%%%%%%%%% tail surfaces %%%%%%%%%%%%%%%%%    5-10%

% assuming +1/3 the wing profile drag

%%%%%%%%%%%%% interference %%%%%%%%%%%%%%%%%    5-10%

% landing gear
[Cd_gear, S_gear, gear_w0] = landingGear('Arched shock'); % Arched wire, Shock wire, Arched shock

W0_m2 = W0_m2 + gear_w0;
W0_m3 = W0_m3 + gear_w0;

%%%%%%%%%%%%% Banner %%%%%%%%%%%%%%%%%%%%%%
Cd_banner = .026;
% Banner_length = 1; % .254 = 10 inches
Banner_length_in = Banner_length * 39.3701;
Banner_width = Banner_length / 5;
Banner_area = Banner_width * Banner_length; % 10 in by 2 in

%%%%%%%%% Drag Calculations %%%%%%%%%%%%%%%%%
n = 20;

%aoa = zeros(1,n);
xmin = -0.1;
xmax = 2;


%%%%%%%%%%%%% Mission 2 %%%%%%%%%%%%%%%%%%% induced 30%

for x = 1:n

    alpha = xmin+(x-1)*((xmax-xmin)/(n-1));
    
    [Cl,Cd_induced] = getLiftDrag(alpha, Airfoil);
    Cd_induced = Cd_induced + (Cl^2)*2/(pi * e * AR);

    Vcruise = sqrt((2*W0_m2)/(rho * w_area * Cl));
    Vcruise = Vcruise * 1.3;
    
    %%%%% Drag
    D_induced = 1/2 * rho * Vcruise^2 * w_area * Cd_induced;

    Re = (rho * Vcruise * chord) / mu;
    
    Cf = 0.3 * 1.328/(sqrt(Re)) + 0.7 * 0.074/(Re^0.2); % Skin Friction Coefficient
    Cd_wingProfile = Cf * FF * Q * (S_wet / w_area);

    Re = (rho * Vcruise * fuse_length) / mu;
    Cf_fuse = 0.074/(Re^0.2);

    D_wingProfile = 1/2 * rho * Vcruise^2 * w_area * Cd_wingProfile;
    D_fuseSkin = 1/2 * rho * Vcruise^2 * S_wetFuse * Cf_fuse;

    D_fuseForm = 1/2 * rho * Vcruise^2 * fuse_cross * Cd_fuseForm;
    D_tail = D_wingProfile * 1/3;
    D_gear = 1/2 * rho * Vcruise^2 * S_gear * Cd_gear;

    totalDrag = D_induced + D_wingProfile + D_fuseSkin + D_fuseForm + D_tail + D_gear;
    %%%% drag %%%%%%%%%%%%%%%%%%%
    % ---------- Times (NO 36x on time) ----------
    % Distances you used: 2000 ft straight (609.6 m) + 400 ft turns (121.9 m)
    lapTime_cruise = 609.6 / Vcruise;   % straight segment at cruise
    turnTime       = 121.9 / Vcruise;   % turn arc time (same speed assumption)
    lapTime_total  = lapTime_cruise + turnTime;
    
    % ---------- Power split: induced vs parasitic ----------
    P_induced_cruise   = D_induced * Vcruise;
    P_parasitic_cruise = (totalDrag - D_induced) * Vcruise;   % wing profile + fuse + etc.
    
    % During 6g turns: induced drag ~ L^2 -> ~36x; parasitic ~ same
    P_induced_turn   = 36 * P_induced_cruise;
    P_parasitic_turn = P_parasitic_cruise;
    
    % Electrical power at propulsive efficiency mew
    P_elec_cruise = (P_induced_cruise + P_parasitic_cruise) / mew;
    P_elec_turn   = (P_induced_turn   + P_parasitic_turn)   / mew;
    
    % ---------- First-lap energy ----------
    % Keep a modest takeoff/initial segment instead of 36x on time
    % Example: ~500 ft ground + initial climb proxy
    takeoffDist_m  = 152;                     % 500 ft
    takeoffTime    = takeoffDist_m / Vcruise; % simple proxy
    E_firstLap_Wh  = (P_elec_cruise * takeoffTime) / 3600; % use cruise power as a proxy
    
    % ---------- Per-lap energy (Wh) ----------
    E_lap_Wh = (P_elec_cruise * lapTime_cruise + P_elec_turn * turnTime) / 3600;
    
    % ---------- Battery + laps ----------
    tempBattery = battery_wh - E_firstLap_Wh;
    if tempBattery < 0
        Actual_laps = 0;
    else
        % Time-limited laps (5 min) using consistent time
        time_limit = 5 * 60;
        num_laps_time = floor(time_limit / lapTime_total);
    
        % Battery-limited laps
        num_laps_batt = floor(tempBattery / E_lap_Wh);
    
        % Feasible laps are the min of time and battery constraints
        Actual_laps = max(0, min(num_laps_time, num_laps_batt));
    
        % Reduce battery by the laps actually flown
        tempBattery = tempBattery - Actual_laps * E_lap_Wh;
    end
    
    % ---------- Economics ----------
    % Your params:
    % Ip1 = 6; Ip2 = 2; Ic1 = 10; Ic2 = 8;
    % Ce = 10; Cp = 0.5; Cc = 2;  EF given elsewhere
    
    income = (num_passengers * (Ip1 + Ip2 * Actual_laps)) + ...
             (num_payload    * (Ic1 + Ic2 * Actual_laps));
    
    cost_per_lap = (Ce + num_passengers * Cp + num_payload * Cc) * EF;
    cost = Actual_laps * cost_per_lap;
    
    net_income = income - cost;
    
    % ---------- Make "more laps" always help ----------
    % 1) Check marginal net per lap; if it's negative, cap at zero to keep monotonicity
    marginal_net_per_lap = num_passengers * Ip2 + num_payload * Ic2 - cost_per_lap;
    if marginal_net_per_lap < 0
        % Option A: ignore costs when marginal is negative (pure “mission points”)
        net_income = income;             % uncomment if you want this behavior
        % Option B: or enforce zero lower bound per lap
        % net_income = (num_passengers * Ip1 + num_payload * Ic1) + ...
                     Actual_laps * max(0, marginal_net_per_lap);
    end
    
    % 2) Reward battery utilization so lower leftover battery improves score
    utilization = max(0, (battery_wh - tempBattery) / battery_wh); % 0..1
    BETA = 0.01;   % +10% boost if you land empty; tune as desired

    net_income = net_income/EF;
    
    score_m2 = (net_income / Max_Score_M2) * 1;
    
    % ---------- WCL check ----------
    WCL = (W0_m2 / 9.81) / (w_area)^1.5;
    if WCL > 20
        % score_m2 = 0;
        % inValidM2 = 1;
    end
    if Actual_laps == 0
        inValidM2 = 1;
    end

    if inValidM2 == 1
        % score_m2 = 0;
    end
    % ---------- Keep best ----------
    if (score_m2 > top_score_m2)
        top_score_m2 = score_m2;
        m2_speed     = Vcruise;
        aoa_m2       = alpha;
        totalDrag_m2 = totalDrag;
    end

end

%%%%%%%%%%%%% Mission 3 %%%%%%%%%%%%%%%%%%% induced 30%
m = 1;
for x = 1:m
    % alpha = xmin+(x-1)*((xmax-xmin)/(n-1));
    alpha = aoa_m2;
    [Cl,Cd_induced] = getLiftDrag(alpha, Airfoil);
    Cd_induced = Cd_induced + (Cl^2)*2/(pi * e * AR);

    Vcruise = sqrt((2*W0_m3)/(rho * w_area * Cl));
    Vcruise = Vcruise*1.3;
    %Vcruise = 26.8224;
    
    %%% drag
    D_induced = 1/2 * rho * Vcruise^2 * w_area * Cd_induced;

    Re = (rho * Vcruise * chord) / mu;
    
    Cf = 0.3 * 1.328/(sqrt(Re)) + 0.7 * 0.074/(Re^0.2); % Skin Friction Coefficient
    Cd_wingProfile = Cf * FF * Q * (S_wet / w_area);

    Re = (rho * Vcruise * fuse_length) / mu;
    Cf_fuse = 0.074/(Re^0.2);

    D_wingProfile = 1/2 * rho * Vcruise^2 * w_area * Cd_wingProfile;
    D_fuseSkin = 1/2 * rho * Vcruise^2 * S_wetFuse * Cf_fuse;
    D_fuseForm = 1/2 * rho * Vcruise^2 * fuse_cross * Cd_fuseForm;
    D_banner = 1/2 * rho * Vcruise^2 * Banner_area * Cd_banner;
    D_tail = D_wingProfile * 1/3;
    D_gear = 1/2 * rho * Vcruise^2 * S_gear * Cd_gear;

    totalDrag = D_induced + D_wingProfile + D_fuseSkin + D_fuseForm + D_tail + D_gear + D_banner;
    %%% drag
    % ======== M3: consistent time, realistic turn power, sane takeoff ========
    
    % --- Times (NO 6x on time) ---
    lapTime_cruise = 609.6 / Vcruise;   % 2000 ft straight
    turnTime       = 121.9 / Vcruise;   % 400 ft of turns
    lapTime_total  = lapTime_cruise + turnTime;
    
    % --- Power split: induced vs. parasitic ---
    % Requires D_induced and totalDrag already computed above
    % Cruise electrical power
    P_elec_cruise = (totalDrag * Vcruise) / mew;
    P_elec_takeoff = (totalDrag - D_banner) * Vcruise / mew;
    
    
    % Turn electrical power: induced ~36x in 6g turns; parasitic ~unchanged
    % P_turn = ((D_parasitic) + 36*D_induced) * V / mew
    P_elec_turn = ((totalDrag - D_induced) + 36 * D_induced) * Vcruise / mew;
    
    % --- Takeoff / first-lap energy (modest) ---
    takeoffDist_m = 152;                          % 500 ft
    takeoffTime   = takeoffDist_m / Vcruise;      % simple proxy
    E_firstLap_Wh = (P_elec_takeoff * takeoffTime) / 3600;
    
    % --- Per-lap energy (Wh) ---
    E_lap_Wh = (P_elec_cruise * lapTime_cruise + P_elec_turn * turnTime) / 3600;
    
    % --- Battery/time feasibility ---
    tempBattery = battery_wh - E_firstLap_Wh;
    time_limit  = 5 * 60;
    
    if tempBattery < 0
        Actual_laps = 0;
    else
        num_laps_time = floor(time_limit / lapTime_total);
        num_laps_batt = floor(tempBattery / E_lap_Wh);
        Actual_laps   = max(0, min(num_laps_time, num_laps_batt));
        tempBattery   = tempBattery - Actual_laps * E_lap_Wh; %#ok<NASGU> % (if you want to log leftover)
    end
    
    Actual_laps = floor(Actual_laps);

    % --- Scoring (more laps → higher score) ---
    score_m3 = (Actual_laps * Banner_length_in / RAC) / Max_Score_M3;
    
    if inValidM2 == 1
        score_m3 = 0;
    end

    if (score_m3 > top_score_m3)
        top_score_m3 = score_m3;
        m3_speed     = Vcruise;
        aoa_m3       = alpha;
        totalDrag_m3 = totalDrag;
    end
    % fprintf('Banner: %.2f, RAC: %.2f, Laps: %d, Score: %.3f\n', ...
        % Banner_length_in, RAC, Actual_laps, score_m3);
end


end

function[Cl, Cd] = getLiftDrag(alpha, type)
    switch type
        case 'SD7043'
            Cl = 0.0858 * alpha + 0.2996;
            Cd = 0.000166 * alpha^2 + -0.000446 * alpha + 0.009955;
        case 'SD7062'
            Cl = 0.0760 * alpha + 0.3072;
            Cd = 0.000083 * alpha^2 + -0.000166 * alpha + 0.009195;
        case 'S3016'
            % Cl = 0.0856 * alpha + 0.1186;
            % Cd = 0.000169 * alpha^2 + -0.000374 * alpha + 0.008576;
            Cl = 0.0769 * alpha + 0.1189;
            Cd = 0.000098 * alpha^2 + -0.000155 * alpha + 0.006029;
        case 'S6063'
            Cl =  0.0773 * alpha + 0.1041;
            Cd = 0.002808 * alpha^2 + -0.018236 * alpha + 0.022731;
        case 'AG12'
            % Cl = 0.0809 * alpha + 0.1559;
            % Cd = 0.000201 * alpha^2 + -0.000411 * alpha + 0.005507;
            Cl = 0.0771 * alpha + 0.1502;
            Cd = 0.000184 * alpha^2 + -0.000449 * alpha + 0.005463;
        case 'AG14'
            Cl = 0.0809 * alpha + 0.1719;
            Cd = 0.000195 * alpha^2 + -0.000364 * alpha + 0.005477;
        case 'AG27'
            fprintf('Error: Not yet Implemented');
            exit(0);
        case 'E221'
            Cl = 0.0770 * alpha + 0.0558;
            Cd = 0.000132 * alpha^2 + -0.000610 * alpha + 0.007256;
    end
end

function[fuse_w, fuse_h, fuse_cross, sectionLength, numDucks] = fuselage(type)
    switch type
        case '1'
            numDucks = 6;
            sectionLength = .27117;
            fuse_w = .127;
            fuse_h = .0635;
            fuse_cross = fuse_w * fuse_h;
        case '2.1'
            numDucks = 3;
            sectionLength = .2209;
            fuse_w = .0762;
            fuse_h = .0762;
            fuse_cross = fuse_w * fuse_h;
        case '3'
            numDucks = 6;
            sectionLength = .1905;
            fuse_w = .127;
            fuse_h = .0939;
            fuse_cross = fuse_w * fuse_h;
        case '4'
            numDucks = 9;
            sectionLength = .27117;
            fuse_w = .1905;
            fuse_h = .0635;
            fuse_cross = fuse_w * fuse_h;
    end
end

% landing gear
function[Cd_gear, S_gear, gear_w0] = landingGear(type) % fairing, no_fairing
    switch type    
        case 'Arched wire'
            Cd_gear = 0.189;
            S_gear = 8.568e-3;
            gear_w0 = 0.142;
        case 'Shock wire'
            Cd_gear = .573;
            S_gear = 2.787e-3;
            gear_w0 = 0.183;          
        case 'Arched shock'
            Cd_gear = 0.132;
            S_gear = 8.916e-3;
            gear_w0 = 0.173;
    end
end