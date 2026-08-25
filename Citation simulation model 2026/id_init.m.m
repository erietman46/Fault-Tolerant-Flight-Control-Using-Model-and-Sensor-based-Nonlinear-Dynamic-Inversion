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