clc
clear

% precision 
n = 15;

% changing variables
battery_wh = zeros(1, n); %x          battery capacity
w_span = zeros(1, n); %y              Wing span
AR = zeros(1,n); %z                   Aspect Ratio
% num_passengers = zeros(1, n); %i      Number of ducks
num_payload = zeros(1, n); %j         Number of hockey pucks
Banner_length = zeros(1, n); % k      Banner length

% values given by indices (x,y,z,j,v)
Score2 = zeros(n, n, n, n, n);
Speed2 = zeros(n, n, n, n, n);
Score3 = zeros(n, n, n, n, n);
Speed3 = zeros(n, n, n, n, n);
aoa_m2       = zeros(n, n, n, n, n);
aoa_m3       = zeros(n, n, n, n, n);
totalDrag_m2 = zeros(n, n, n, n, n);
totalDrag_m3 = zeros(n, n, n, n, n);
fuseLength = zeros(n, n, n, n, n);
gm_Time = zeros(n, n, n, n, n);
combined = zeros(n, n, n, n, n);

xmin = 30;  %capacity min (W/h)
xmax = 100;
ymin = 1.4; % wingspan (meters)
ymax = 1.52; % 3-5 ft 1.52
zmin = 3;   %Aspect Ratio
zmax = 7.8; 
% imin = 3; % Passengers
% imax = 45; 
jmin = 1; % Payload
jmax = 30; 
kmin = 1; % banner 10 inches
kmax = 5; % banner 60 inches

for x = 1:n
    for y = 1:n
        for z = 1:n
            %for i = 1:n
                for j = 1:n
                    for k = 1:n
                        b_wh = xmin+(x-1)*((xmax-xmin)/(n-1));
                        battery_wh(x) = b_wh;
    
                        S = ymin+(y-1)*((ymax-ymin)/(n-1));
                        w_span(y) = S;
    
                        Ratio = zmin+(z-1)*((zmax-zmin)/(n-1));
                        AR(z) = Ratio;
                        
                        %Passengers = imin + (i-1)*((imax-imin)/(n-1));
                        %num_passengers(i) = Passengers;
    
                        Payload = jmin + (j-1)*((jmax-jmin)/(n-1));
                        num_payload(j) = Payload;
                        %Payload = 1;

                        banner = kmin + (k-1)*((kmax-kmin)/(n-1));
                        Banner_length(k) = banner;

    
                        [Speed2(x,y,z,j,k),Score2(x,y,z,j,k),Speed3(x,y,z,j,k), Score3(x,y,z,j,k),aoa_m2(x,y,z,j,k), aoa_m3(x,y,z,j,k), totalDrag_m2(x,y,z,j,k), ...
                            totalDrag_m3(x,y,z,j,k), fuseLength(x,y,z,j,k), gm_Time(x,y,z,j,k), combined(x,y,z,j,k)] = combined_score(b_wh,S,Ratio,Payload, banner);
                    end
                end
            %end
        end
    end
end


avionics_Base = 400; % 300 grams
avionics_motor = 300; % 200 grams
avionics_battery = 700; % 600 grams 
avionics_w0 = avionics_Base + avionics_battery + avionics_motor; % total avionics weight

W0_P = 19.84; % weight in grams of ducks .7 oz
W0_C = 170.10; % weight in grams of cargo 6 oz

% num_payload = 1;

%%%%%%%%%%%%%%%% M2 %%%%%%%%%%%%%%%%%%
[maxScore2, idx] = max(Score2(:));
[xMax,yMax,zMax,jMax,kMax] = ind2sub(size(Score2), idx);

printBestConfig(xMax, yMax, zMax, jMax, kMax, ...
    battery_wh, w_span, AR, num_payload, Banner_length, ...
    W0_C, W0_P, avionics_w0, Speed2, Speed3, aoa_m2, aoa_m3, ...
    totalDrag_m2, totalDrag_m3, fuseLength, maxScore2, 'm2', gm_Time, Score2, Score3);

%%%%%%%%%%%%%%%% M3 %%%%%%%%%%%%%%%%%%
[maxScore3, idx] = max(Score3(:));
[xMax,yMax,zMax,jMax,kMax] = ind2sub(size(Score3), idx);

printBestConfig(xMax, yMax, zMax, jMax, kMax, ...
    battery_wh, w_span, AR, num_payload, Banner_length, ...
    W0_C, W0_P, avionics_w0, Speed2, Speed3, aoa_m2, aoa_m3, ...
    totalDrag_m2, totalDrag_m3, fuseLength, maxScore3, 'm3', gm_Time, Score2, Score3);

maxGMtime = max(gm_Time(:));

% Flatten the combined array
allScores = combined(:);

% Sort in descending order
[sortedScores, sortIdx] = sort(allScores, 'descend');

% Pick top K configurations (e.g., K=5)
K = 3;
for n = 1:K
    idx = sortIdx(n);
    score = sortedScores(n);
    [xMax,yMax,zMax,jMax,kMax] = ind2sub(size(combined), idx);

    printBestConfig(xMax, yMax, zMax, jMax, kMax, ...
    battery_wh, w_span, AR, num_payload, Banner_length, ...
    W0_C, W0_P, avionics_w0, Speed2, Speed3, aoa_m2, aoa_m3, ...
    totalDrag_m2, totalDrag_m3, fuseLength, score, sprintf('Top %d', n), gm_Time, Score2, Score3);
end






function printBestConfig(xMax, yMax, zMax, jMax, kMax, ...
    battery_wh, w_span, AR, num_payload, Banner_length, ...
    W0_C, W0_P, avionics_w0, Speed2, Speed3, aoa_m2, aoa_m3, ...
    totalDrag_m2, totalDrag_m3, fuseLength, score, label, gm_Time, Score2, Score3)

    % ========= Extract best values =========
    b_wh_best       = battery_wh(xMax);
    w_span_best     = w_span(yMax) * 3.28;
    AR_best         = AR(zMax);
    Payload_best    = floor(num_payload(jMax));
    Passengers_best = Payload_best * 3;

    totalPayloadWeight = W0_C * Payload_best + W0_P * Passengers_best + avionics_w0;
    totalWeight = totalPayloadWeight * 2; % grams
    totalWeightm3 = totalWeight - (W0_C * Payload_best + W0_P * Passengers_best);
    totalWeightLbsM2 = totalWeight/1000 * 2.2;
    totalWeightLbsM3 = totalWeightm3/1000 * 2.2;

    Banner_best = Banner_length(kMax) * 3.28;
    scorem2 = Score2(xMax, yMax, zMax, jMax, kMax);
    scorem3 = Score3(xMax, yMax, zMax, jMax, kMax);
    speedm2 = Speed2(xMax, yMax, zMax, jMax, kMax);
    speedm3 = Speed3(xMax, yMax, zMax, jMax, kMax);
    aoa2 = aoa_m2(xMax, yMax, zMax, jMax, kMax);
    aoa3 = aoa_m3(xMax, yMax, zMax, jMax, kMax);
    totalDrag2 = totalDrag_m2(xMax, yMax, zMax, jMax, kMax);
    totalDrag3 = totalDrag_m3(xMax, yMax, zMax, jMax, kMax);
    fuse_Length = fuseLength(xMax, yMax, zMax, jMax, kMax) * 3.28;
    gmTime = gm_Time(xMax, yMax, zMax, jMax, kMax);
    
    track_distance = 2500;
    lap_time_m2 = track_distance / speedm2; % seconds
    lap_time_m3 = track_distance / speedm3; % seconds

    mission_time = 600; % total allowed time (s)
    num_lapsm2 = floor(mission_time / lap_time_m2);
    num_lapsm3 = floor(mission_time / lap_time_m3);

    % ========= Print results =========
    fprintf('\n=========== Best Configuration %s ===========\n', label);
    fprintf(' Max Score          : %.4f\n', score);
    fprintf(' Battery (Wh)       : %.2f\n', b_wh_best);
    fprintf(' Wingspan (ft)       : %.2f\n', w_span_best);
    fprintf(' Aspect Ratio       : %.2f\n', AR_best);
    fprintf(' Passengers         : %d', Passengers_best);
    fprintf(' \t\t\tPayload      : %.2f\n', Payload_best);
    fprintf(' Score           M2 : %.2f   \t\tM3: %.2f\n', scorem2, scorem3);
    fprintf(' Weight (lbs)    M2 : %.2f   \t\tM3: %.2f\n', totalWeightLbsM2, totalWeightLbsM3);
    fprintf(' Speed (mph)     M2 : %.2f   \t\tM3: %.2f\n', speedm2*2.247, speedm3*2.247);
    fprintf(' Number of Laps  M2 : %.2f   \t\tM3: %.2f\n', num_lapsm2, num_lapsm3);
    fprintf(' Angle of In.    M2 : %.2f   \t\tM3: %.2f\n', aoa2, aoa3);
    fprintf(' Total Drag (N)  M2 : %.2f   \t\tM3: %.2f\n', totalDrag2, totalDrag3);
    fprintf(' Banner Length      : %.2f\n', Banner_best);
    fprintf(' Fuse Length        : %.2f\n', fuse_Length);
    fprintf(' Gm Time            : %.2f\n', gmTime);
    fprintf('=============================================\n\n');
end