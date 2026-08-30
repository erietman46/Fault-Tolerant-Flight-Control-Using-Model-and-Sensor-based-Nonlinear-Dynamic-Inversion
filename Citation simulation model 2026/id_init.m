% Longitudinal X
thetaX0 = zeros(5,1);
PX0     = 10000*eye(5);

% Longitudinal Z
thetaZ0 = zeros(4,1);
PZ0     = 10000*eye(4);

% Pitch moment
thetaM0 = [ ...
     1.2280209971618383e-02;
    -6.2047285966942156e-01;
    -4.5666794901955016e-01;
    -7.9818167910463400e-01
];
PM0     = 10000*eye(4);

% Lateral force
thetaY0 = zeros(6,1);
PY0     = 10000*eye(6);

% Roll moment
thetaL0 = [ ...
     7.0957952465296537e-06;
    -1.0155121539575106e-01;
    -4.2383534835366377e-01;
     9.5796939139152812e-02;
    -1.6885935304491506e-01;
     3.7231485124728590e-02
];

PL0     = 10000*eye(6);

% Yaw moment
thetaN0 = [ ...
    -4.9609095125384690e-06;
     1.3394476410940456e-01;
    -6.6154460038184107e-02;
    -1.5090063958076161e-01;
    -1.3179507592353657e-02;
    -9.0019184186074228e-02
];
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

%% Inner angular-rate PI gains

% Roll
Kp_p = 4.5;
Ki_p = 5.0;

% Pitch
Kp_q = 4.5;
Ki_q = 5.0;

% Yaw
Kp_r = 4.5;
Ki_r = 5.0;

% Outer beta controller
K_beta = 2;

% Command filter
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

%% ANDI anti-windup

Taw_p = 0.5;        % s
Taw_q = 0.5;        % s
Taw_r = 0.5;        % s

Kaw_p = 1/Taw_p;    % 2 1/s
Kaw_q = 1/Taw_q;
Kaw_r = 1/Taw_r;

%% =========================================================
% STEP 6 - Classical rate controller
% ==========================================================

% Roll rate -> aileron
Kp_p_classical = -1;
Ki_p_classical = -0.5;

% Pitch rate -> elevator
Kp_q_classical = -2;
Ki_q_classical = -0.1;

% Yaw rate -> rudder
Kp_r_classical = -2;
Ki_r_classical = -0.1;