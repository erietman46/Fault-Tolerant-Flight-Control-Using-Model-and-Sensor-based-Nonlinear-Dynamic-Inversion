% Longitudinal X
thetaX0 = zeros(5,1);
PX0     = 10000*eye(5);

% Longitudinal Z
thetaZ0 = zeros(4,1);
PZ0     = 10000*eye(4);

% Pitch moment
thetaM0 = zeros(4,1);
PM0     = 10000*eye(4);

% Lateral force
thetaY0 = zeros(6,1);
PY0     = 10000*eye(6);

% Roll moment
thetaL0 = zeros(6,1);
PL0     = 10000*eye(6);

% Yaw moment
thetaN0 = zeros(6,1);
PN0     = 10000*eye(6);

% Step 3: ordinary RLS
lambda_ID = 1.0;

%% Step 4 - variance detector thresholds

TX = 2.2784e-06;
TY = 8.0633e-07;
TZ = 2.8004e-05;
TL = 7.0875e-06;
TM = 3.2564e-06;
TN = 5.4692e-07;

%% =========================================================
% STEP 5 - ANDI controller
% ==========================================================

% Inner angular-rate PI gains
Kp_p = 4;
Ki_p = 4;

Kp_q = 4;
Ki_q = 4;

Kp_r = 4;
Ki_r = 4;

% Outer beta controller
K_beta = 2;

% Command-filter time constant
tau_cmd = 0.5;

% Maximum commanded rates
p_ref_max = 20*pi/180;      % rad/s
q_ref_max = 10*pi/180;      % rad/s
r_ref_max = 10*pi/180;      % rad/s

% Maximum commanded sideslip
beta_ref_max = 5*pi/180;    % rad

% Mapping from existing pilot surface commands to rate commands
K_da_to_p    = p_ref_max/0.65;
K_de_to_q    = q_ref_max/0.35;
K_dr_to_beta = beta_ref_max/0.38;