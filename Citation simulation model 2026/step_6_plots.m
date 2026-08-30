clear;
close all;
clc;

%% ============================================================
%  STEP 6 - VALIDATION PLOTS
% =============================================================

failure_time = 60;     % [s]

%% Load all four simulations
C0 = load('classical_no_failure.mat');
CF = load('classical_failure.mat');
A0 = load('ANDI_no_failure.mat');
AF = load('ANDI_failure.mat');

%% ============================================================
%  1. STATISTICAL MONITORING METRIC
% =============================================================

% Jvar contains:
% [Jvar_X Jvar_Y Jvar_Z Jvar_L Jvar_M Jvar_N]

tJ = CF.Jvar.Time;
J  = squeeze(CF.Jvar.Data);

% Make sure time is the first dimension
if size(J,1) ~= length(tJ)
    J = J.';
end

thresholds = [CF.TX CF.TY CF.TZ CF.TL CF.TM CF.TN];

names = {'C_X','C_Y','C_Z','C_l','C_m','C_n'};

figure('Name','Monitoring metric');

tiledlayout(3,2);

for i = 1:6

    nexttile;

    plot(tJ,J(:,i),'LineWidth',1.2);
    hold on;

    yline(thresholds(i),'--','Threshold','LineWidth',1.2);
    xline(failure_time,'--','Failure','LineWidth',1.2);

    grid on;
    xlabel('Time [s]');
    ylabel('J_{var}');
    title(names{i});

end

sgtitle('Variance-based fault monitoring - Classical controller');

exportgraphics(gcf,'Fig1_monitoring_metric.png','Resolution',300);

%% ============================================================
%  2. PARAMETER CONVERGENCE
% =============================================================

tL = CF.theta_L.Time;
L  = squeeze(CF.theta_L.Data);

tN = CF.theta_N.Time;
N  = squeeze(CF.theta_N.Data);

tY = CF.theta_Y.Time;
Y  = squeeze(CF.theta_Y.Data);

if size(L,1) ~= length(tL)
    L = L.';
end

if size(N,1) ~= length(tN)
    N = N.';
end

if size(Y,1) ~= length(tY)
    Y = Y.';
end


figure('Name','Aerodynamic derivative convergence');

tiledlayout(3,2);

% ------------------------------------------------------------
% Roll moment: aerodynamic derivatives
% ------------------------------------------------------------
nexttile;

plot(tL,L(:,2),'LineWidth',1.2);
hold on;
plot(tL,L(:,3),'LineWidth',1.2);
plot(tL,L(:,4),'LineWidth',1.2);

xline(failure_time,'--','Failure');

grid on;
xlabel('Time [s]');
ylabel('Coefficient');
title('Roll moment aerodynamic derivatives');
legend('C_{l\beta}','C_{lp}','C_{lr}','Location','best');


% ------------------------------------------------------------
% Roll moment: control derivatives
% ------------------------------------------------------------
nexttile;

plot(tL,L(:,5),'LineWidth',1.4);
hold on;
plot(tL,L(:,6),'LineWidth',1.2);

xline(failure_time,'--','Failure');

grid on;
xlabel('Time [s]');
ylabel('Coefficient');
title('Roll moment control derivatives');
legend('C_{l\delta_a}','C_{l\delta_r}','Location','best');


% ------------------------------------------------------------
% Yaw moment: aerodynamic derivatives
% ------------------------------------------------------------
nexttile;

plot(tN,N(:,2),'LineWidth',1.2);
hold on;
plot(tN,N(:,3),'LineWidth',1.2);
plot(tN,N(:,4),'LineWidth',1.2);

xline(failure_time,'--','Failure');

grid on;
xlabel('Time [s]');
ylabel('Coefficient');
title('Yaw moment aerodynamic derivatives');
legend('C_{n\beta}','C_{np}','C_{nr}','Location','best');


% ------------------------------------------------------------
% Yaw moment: control derivatives
% ------------------------------------------------------------
nexttile;

plot(tN,N(:,5),'LineWidth',1.4);
hold on;
plot(tN,N(:,6),'LineWidth',1.2);

xline(failure_time,'--','Failure');

grid on;
xlabel('Time [s]');
ylabel('Coefficient');
title('Yaw moment control derivatives');
legend('C_{n\delta_a}','C_{n\delta_r}','Location','best');


% ------------------------------------------------------------
% Side-force: aerodynamic derivatives
% ------------------------------------------------------------
nexttile;

plot(tY,Y(:,2),'LineWidth',1.2);
hold on;
plot(tY,Y(:,3),'LineWidth',1.2);
plot(tY,Y(:,4),'LineWidth',1.2);

xline(failure_time,'--','Failure');

grid on;
xlabel('Time [s]');
ylabel('Coefficient');
title('Side-force aerodynamic derivatives');
legend('C_{Y\beta}','C_{Yp}','C_{Yr}','Location','best');


% ------------------------------------------------------------
% Side-force: control derivatives
% ------------------------------------------------------------
nexttile;

plot(tY,Y(:,5),'LineWidth',1.4);
hold on;
plot(tY,Y(:,6),'LineWidth',1.2);

xline(failure_time,'--','Failure');

grid on;
xlabel('Time [s]');
ylabel('Coefficient');
title('Side-force control derivatives');
legend('C_{Y\delta_a}','C_{Y\delta_r}','Location','best');

sgtitle('RLS convergence of lateral-directional derivatives');

exportgraphics(gcf,'Fig2_derivative_convergence.png','Resolution',300);

%% Aileron effectiveness only

figure('Name','Aileron control effectiveness');

tiledlayout(3,1);

nexttile;
plot(tL,L(:,5),'LineWidth',1.5);
xline(failure_time,'--','Failure');
grid on;
ylabel('C_{l\delta_a}');
title('Aileron effectiveness in roll');

nexttile;
plot(tN,N(:,5),'LineWidth',1.5);
xline(failure_time,'--','Failure');
grid on;
ylabel('C_{n\delta_a}');
title('Aileron effectiveness in yaw');

nexttile;
plot(tY,Y(:,5),'LineWidth',1.5);
xline(failure_time,'--','Failure');
grid on;
xlabel('Time [s]');
ylabel('C_{Y\delta_a}');
title('Aileron effectiveness in side force');

sgtitle('Identified aileron control derivatives');

exportgraphics(gcf,'Fig2b_aileron_effectiveness.png','Resolution',300);

%% ============================================================
%  3. TRAJECTORIES - ALL FOUR RUNS
% =============================================================

% Classical healthy
x_C0 = C0.yout(:,11);
y_C0 = C0.yout(:,12);

% Classical failed
x_CF = CF.yout(:,11);
y_CF = CF.yout(:,12);

% ANDI healthy
x_A0 = A0.yout(:,11);
y_A0 = A0.yout(:,12);

% ANDI failed
x_AF = AF.yout(:,11);
y_AF = AF.yout(:,12);


figure('Name','Ground trajectories');

plot(y_C0,x_C0,'LineWidth',1.4);
hold on;

plot(y_CF,x_CF,'LineWidth',1.4);
plot(y_A0,x_A0,'LineWidth',1.4);
plot(y_AF,x_AF,'LineWidth',1.4);

grid on;
axis equal;

xlabel('East position y_e [m]');
ylabel('North position x_e [m]');

legend( ...
    'Classical - healthy', ...
    'Classical - failure', ...
    'ANDI - healthy', ...
    'ANDI - failure', ...
    'Location','best');

title('Aircraft trajectories for the four validation runs');

exportgraphics(gcf,'Fig3_trajectories.png','Resolution',300);

%% Find failure indices

[~,iCF] = min(abs(CF.tout - failure_time));
[~,iAF] = min(abs(AF.tout - failure_time));

hold on;

plot(y_CF(iCF),x_CF(iCF),'o','MarkerSize',8,'LineWidth',1.5);
plot(y_AF(iAF),x_AF(iAF),'o','MarkerSize',8,'LineWidth',1.5);

%% Optional 3-D trajectories

h_C0 = C0.yout(:,10);
h_CF = CF.yout(:,10);
h_A0 = A0.yout(:,10);
h_AF = AF.yout(:,10);

figure;

plot3(y_C0,x_C0,h_C0,'LineWidth',1.3);
hold on;
plot3(y_CF,x_CF,h_CF,'LineWidth',1.3);
plot3(y_A0,x_A0,h_A0,'LineWidth',1.3);
plot3(y_AF,x_AF,h_AF,'LineWidth',1.3);

grid on;
axis equal;

xlabel('East position [m]');
ylabel('North position [m]');
zlabel('Altitude [m]');

legend( ...
    'Classical - healthy', ...
    'Classical - failure', ...
    'ANDI - healthy', ...
    'ANDI - failure', ...
    'Location','best');

title('3-D validation trajectories');

exportgraphics(gcf,'Fig3b_trajectories_3D.png','Resolution',300);

%% ============================================================
%  4. CONTROL SURFACES VS JOYSTICK INPUTS
% =============================================================

figure('Name','Classical control surface commands');

tiledlayout(3,1);


%% Elevator
nexttile;

plot(CF.de_joy.Time, ...
    rad2deg(CF.de_joy.Data), ...
    '--','LineWidth',1.2);

hold on;

plot(CF.de_classical.Time, ...
    rad2deg(CF.de_classical.Data), ...
    'LineWidth',1.3);

xline(failure_time,'--','Failure');

grid on;

ylabel('\delta_e [deg]');
title('Elevator');
legend('Joystick command','Classical controller','Location','best');


%% Aileron
nexttile;

plot(CF.da_joy.Time, ...
    rad2deg(CF.da_joy.Data), ...
    '--','LineWidth',1.2);

hold on;

plot(CF.da_classical.Time, ...
    rad2deg(CF.da_classical.Data), ...
    'LineWidth',1.3);

plot(CF.da_actual.Time, ...
    rad2deg(CF.da_actual.Data), ...
    'LineWidth',1.5);

xline(failure_time,'--','Failure');

grid on;

ylabel('\delta_a [deg]');
title('Aileron');

legend( ...
    'Joystick command', ...
    'Controller command', ...
    'Actual failed aileron', ...
    'Location','best');


%% Rudder
nexttile;

plot(CF.dr_joy.Time, ...
    rad2deg(CF.dr_joy.Data), ...
    '--','LineWidth',1.2);

hold on;

plot(CF.dr_classical.Time, ...
    rad2deg(CF.dr_classical.Data), ...
    'LineWidth',1.3);

xline(failure_time,'--','Failure');

grid on;

xlabel('Time [s]');
ylabel('\delta_r [deg]');
title('Rudder');

legend('Joystick command','Classical controller','Location','best');


sgtitle('Classical controller: joystick commands and surface deflections');

exportgraphics(gcf,'Fig4_classical_controls.png','Resolution',300);