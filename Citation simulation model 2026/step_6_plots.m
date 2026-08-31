%% STEP 6 - COMPLETE VALIDATION OF CLASSICAL AND FAULT-TOLERANT (ANDI) CONTROL
% This script is based on the signals already logged in the supplied model
% and on the four Step-6 simulation MAT-files.
%
% It produces:
%   1) Fault-monitoring metrics for all four runs (normalized by thresholds)
%   2) RLS derivative histories for the ANDI failure run
%   3) Aileron-effectiveness comparison: ANDI healthy vs ANDI failure
%   4) 2-D and 3-D trajectories for all four runs
%   5) Classical surface commands/actual surfaces vs joystick, healthy/failure
%   6) ANDI surface commands/actual surfaces vs joystick, healthy/failure
%   7) Rate and sideslip tracking after failure: classical vs ANDI
%   8) Handling-state comparison for all four runs
%   9) Trajectory-deviation comparison (failed run relative to healthy run)
%  10) Numerical summary tables saved as CSV and MAT
%
% IMPORTANT:
% - The failure is assumed to occur at 60 s.
% - detector_arm_time is only used for numerical false-alarm statistics.
%   Set it to the arming time used/justified in your Part 4 analysis.
% - The script automatically picks the newest matching MAT-file in the folder.

clear;
close all;
clc;

%% ============================================================
% USER SETTINGS
% =============================================================
failure_time      = 60;       % [s]
detector_arm_time = 5;        % [s] change if Part 4 used another value

% Windows used to quantify the identified derivatives.
% Pre-failure: after substantial estimator convergence, before the failure.
% Post-failure: after the immediate fault transient, while the aircraft is
% still in the validation maneuver.
rls_pre_window  = [50 59];     % [s]
rls_post_window = [70 90];     % [s]

outdir = 'Step6_validation_output';
if ~exist(outdir,'dir')
    mkdir(outdir);
end

%% ============================================================
% FIND AND LOAD THE FOUR MOST RECENT SIMULATION FILES
% =============================================================
d = dir('classical_no_failure*.mat');
assert(~isempty(d),'No classical_no_failure*.mat file found.');
[~,k] = max([d.datenum]);
file_C0 = d(k).name;

d = dir('classical_failure*.mat');
assert(~isempty(d),'No classical_failure*.mat file found.');
[~,k] = max([d.datenum]);
file_CF = d(k).name;

d = dir('ANDI_no_failure*.mat');
assert(~isempty(d),'No ANDI_no_failure*.mat file found.');
[~,k] = max([d.datenum]);
file_A0 = d(k).name;

d = dir('ANDI_failure*.mat');
assert(~isempty(d),'No ANDI_failure*.mat file found.');
[~,k] = max([d.datenum]);
file_AF = d(k).name;

fprintf('Loading Step-6 files:\n');
fprintf('  Classical healthy : %s\n',file_C0);
fprintf('  Classical failure : %s\n',file_CF);
fprintf('  ANDI healthy      : %s\n',file_A0);
fprintf('  ANDI failure      : %s\n\n',file_AF);

C0 = load(file_C0);
CF = load(file_CF);
A0 = load(file_A0);
AF = load(file_AF);

runs     = {C0, CF, A0, AF};
runNames = {'Classical - healthy','Classical - failure', ...
            'ANDI - healthy','ANDI - failure'};

%% ============================================================
% CHECK REQUIRED LOGGED SIGNALS
% =============================================================
requiredCommon = {'tout','yout','Jvar','theta_L','theta_N','theta_Y', ...
                  'p','q','r','beta','p_ref','q_ref','r_ref','beta_ref', ...
                  'de_joy','da_joy','dr_joy','de_actual','da_actual','dr_actual'};

for rr = 1:4
    for ss = 1:numel(requiredCommon)
        assert(isfield(runs{rr},requiredCommon{ss}), ...
            'Missing signal "%s" in run "%s".',requiredCommon{ss},runNames{rr});
    end
end

requiredClassical = {'de_classical','da_classical','dr_classical'};
for rr = 1:2
    for ss = 1:numel(requiredClassical)
        assert(isfield(runs{rr},requiredClassical{ss}), ...
            'Missing classical command "%s" in run "%s".', ...
            requiredClassical{ss},runNames{rr});
    end
end

requiredANDI = {'de_ANDI','da_ANDI','dr_ANDI'};
for rr = 3:4
    for ss = 1:numel(requiredANDI)
        assert(isfield(runs{rr},requiredANDI{ss}), ...
            'Missing ANDI command "%s" in run "%s".', ...
            requiredANDI{ss},runNames{rr});
    end
end

%% ============================================================
% STATE COLUMN DEFINITIONS FROM THE CITATION MODEL
% yout(:,1:12) = [p q r VTAS alpha beta phi theta psi h x_N y_E]
% =============================================================
i_p     = 1;
i_q     = 2;
i_r     = 3;
i_VTAS  = 4;
i_alpha = 5;
i_beta  = 6;
i_phi   = 7;
i_theta = 8;
i_psi   = 9;
i_h     = 10;
i_xN    = 11;
i_yE    = 12;

%% ============================================================
% 1. FAULT-MONITORING METRIC: ALL FOUR RUNS
%    Plot J_var / threshold so the threshold is always 1.
% =============================================================
thresholds = [CF.TX CF.TY CF.TZ CF.TL CF.TM CF.TN];
metricNames = {'C_X','C_Y','C_Z','C_l','C_m','C_n'};

figure('Color','w','Position',[80 60 1450 900]);
tiledlayout(3,2,'TileSpacing','compact','Padding','compact');

for ch = 1:6
    nexttile;
    hold on;

    for rr = 1:4
        R  = runs{rr};
        tJ = R.Jvar.Time(:);
        J  = squeeze(R.Jvar.Data);
        if size(J,1) ~= numel(tJ)
            J = J.';
        end

        Jnorm = J(:,ch)./thresholds(ch);
        plot(tJ,Jnorm,'LineWidth',1.15);
    end

    yline(1,'--','Threshold','LineWidth',1.1,'HandleVisibility','off');
    xline(failure_time,'--','Failure time','LineWidth',1.0,'HandleVisibility','off');
    grid on;
    xlabel('Time [s]');
    ylabel('J_{var}/T');
    title(metricNames{ch});

    if ch == 1
        legend(runNames,'Location','best');
    end
end

sgtitle('Normalized variance-based monitoring metrics - all four validation runs');
exportgraphics(gcf,fullfile(outdir,'Fig01_monitoring_all_four_normalized.png'),'Resolution',300);

%% ============================================================
% 1B. NUMERICAL FAULT-DETECTION SUMMARY
% =============================================================
maxHealthyClassical = nan(1,6);
maxHealthyANDI      = nan(1,6);
maxPreCF            = nan(1,6);
maxPostCF           = nan(1,6);
delayCF             = nan(1,6);
maxPreAF            = nan(1,6);
maxPostAF           = nan(1,6);
delayAF             = nan(1,6);

% Healthy classical - check the entire armed portion for false alarms
R = C0;
t = R.Jvar.Time(:);
J = squeeze(R.Jvar.Data);
if size(J,1) ~= numel(t), J = J.'; end
Jn = bsxfun(@rdivide,J,thresholds);
idx = t >= detector_arm_time;
maxHealthyClassical = max(Jn(idx,:),[],1);

% Healthy ANDI - check the entire armed portion for false alarms
R = A0;
t = R.Jvar.Time(:);
J = squeeze(R.Jvar.Data);
if size(J,1) ~= numel(t), J = J.'; end
Jn = bsxfun(@rdivide,J,thresholds);
idx = t >= detector_arm_time;
maxHealthyANDI = max(Jn(idx,:),[],1);

% Classical failure
R = CF;
t = R.Jvar.Time(:);
J = squeeze(R.Jvar.Data);
if size(J,1) ~= numel(t), J = J.'; end
Jn = bsxfun(@rdivide,J,thresholds);
idxPre  = t >= detector_arm_time & t < failure_time;
idxPost = t >= failure_time;
maxPreCF  = max(Jn(idxPre,:),[],1);
maxPostCF = max(Jn(idxPost,:),[],1);
for ch = 1:6
    kdet = find(t >= failure_time & Jn(:,ch) > 1,1,'first');
    if ~isempty(kdet)
        delayCF(ch) = t(kdet)-failure_time;
    end
end

% ANDI failure
R = AF;
t = R.Jvar.Time(:);
J = squeeze(R.Jvar.Data);
if size(J,1) ~= numel(t), J = J.'; end
Jn = bsxfun(@rdivide,J,thresholds);
idxPre  = t >= detector_arm_time & t < failure_time;
idxPost = t >= failure_time;
maxPreAF  = max(Jn(idxPre,:),[],1);
maxPostAF = max(Jn(idxPost,:),[],1);
for ch = 1:6
    kdet = find(t >= failure_time & Jn(:,ch) > 1,1,'first');
    if ~isempty(kdet)
        delayAF(ch) = t(kdet)-failure_time;
    end
end

FaultDetectionSummary = table(metricNames(:), ...
    maxHealthyClassical(:),maxHealthyANDI(:), ...
    maxPreCF(:),maxPostCF(:),delayCF(:), ...
    maxPreAF(:),maxPostAF(:),delayAF(:), ...
    'VariableNames',{'Metric', ...
    'MaxNorm_ClassicalHealthy','MaxNorm_ANDIHealthy', ...
    'MaxNorm_CF_Pre','MaxNorm_CF_Post','DetectionDelay_CF_s', ...
    'MaxNorm_AF_Pre','MaxNorm_AF_Post','DetectionDelay_AF_s'});

writetable(FaultDetectionSummary,fullfile(outdir,'Table01_fault_detection_summary.csv'));

%% ============================================================
% 2. RLS CONVERGENCE OF RELEVANT LATERAL-DIRECTIONAL DERIVATIVES
%    Use ANDI FAILURE, because these are the estimates used by the FTC.
% =============================================================
tL = AF.theta_L.Time(:);
L  = squeeze(AF.theta_L.Data);
if size(L,1) ~= numel(tL), L = L.'; end

tN = AF.theta_N.Time(:);
N  = squeeze(AF.theta_N.Data);
if size(N,1) ~= numel(tN), N = N.'; end

tY = AF.theta_Y.Time(:);
Y  = squeeze(AF.theta_Y.Data);
if size(Y,1) ~= numel(tY), Y = Y.'; end

figure('Color','w','Position',[80 60 1450 900]);
tiledlayout(3,2,'TileSpacing','compact','Padding','compact');

nexttile;
plot(tL,L(:,2),'LineWidth',1.15); hold on;
plot(tL,L(:,3),'LineWidth',1.15);
plot(tL,L(:,4),'LineWidth',1.15);
xline(failure_time,'--','Failure','HandleVisibility','off');
grid on; xlabel('Time [s]'); ylabel('Coefficient');
title('Roll moment aerodynamic derivatives');
legend('C_{l\beta}','C_{lp}','C_{lr}','Location','best');

nexttile;
plot(tL,L(:,5),'LineWidth',1.4); hold on;
plot(tL,L(:,6),'LineWidth',1.15);
xline(failure_time,'--','Failure','HandleVisibility','off');
grid on; xlabel('Time [s]'); ylabel('Coefficient');
title('Roll moment control derivatives');
legend('C_{l\delta_a}','C_{l\delta_r}','Location','best');

nexttile;
plot(tN,N(:,2),'LineWidth',1.15); hold on;
plot(tN,N(:,3),'LineWidth',1.15);
plot(tN,N(:,4),'LineWidth',1.15);
xline(failure_time,'--','Failure','HandleVisibility','off');
grid on; xlabel('Time [s]'); ylabel('Coefficient');
title('Yaw moment aerodynamic derivatives');
legend('C_{n\beta}','C_{np}','C_{nr}','Location','best');

nexttile;
plot(tN,N(:,5),'LineWidth',1.4); hold on;
plot(tN,N(:,6),'LineWidth',1.15);
xline(failure_time,'--','Failure','HandleVisibility','off');
grid on; xlabel('Time [s]'); ylabel('Coefficient');
title('Yaw moment control derivatives');
legend('C_{n\delta_a}','C_{n\delta_r}','Location','best');

nexttile;
plot(tY,Y(:,2),'LineWidth',1.15); hold on;
plot(tY,Y(:,3),'LineWidth',1.15);
plot(tY,Y(:,4),'LineWidth',1.15);
xline(failure_time,'--','Failure','HandleVisibility','off');
grid on; xlabel('Time [s]'); ylabel('Coefficient');
title('Side-force aerodynamic derivatives');
legend('C_{Y\beta}','C_{Yp}','C_{Yr}','Location','best');

nexttile;
plot(tY,Y(:,5),'LineWidth',1.4); hold on;
plot(tY,Y(:,6),'LineWidth',1.15);
xline(failure_time,'--','Failure','HandleVisibility','off');
grid on; xlabel('Time [s]'); ylabel('Coefficient');
title('Side-force control derivatives');
legend('C_{Y\delta_a}','C_{Y\delta_r}','Location','best');

sgtitle('RLS estimates used during the ANDI failure validation run');
exportgraphics(gcf,fullfile(outdir,'Fig02_RLS_ANDI_failure.png'),'Resolution',300);

%% ============================================================
% 2B. AILERON CONTROL EFFECTIVENESS: ANDI HEALTHY VS FAILURE
% =============================================================
tL0 = A0.theta_L.Time(:);
L0  = squeeze(A0.theta_L.Data);
if size(L0,1) ~= numel(tL0), L0 = L0.'; end

tN0 = A0.theta_N.Time(:);
N0  = squeeze(A0.theta_N.Data);
if size(N0,1) ~= numel(tN0), N0 = N0.'; end

tY0 = A0.theta_Y.Time(:);
Y0  = squeeze(A0.theta_Y.Data);
if size(Y0,1) ~= numel(tY0), Y0 = Y0.'; end

figure('Color','w','Position',[120 70 1400 800]);
tiledlayout(3,1,'TileSpacing','compact','Padding','compact');

nexttile;
plot(tL0,L0(:,5),'LineWidth',1.25); hold on;
plot(tL,L(:,5),'LineWidth',1.45);
xline(failure_time,'--','Failure','HandleVisibility','off');
grid on; ylabel('C_{l\delta_a}');
title('Aileron effectiveness in roll');
legend('ANDI - healthy','ANDI - failure','Location','best');

nexttile;
plot(tN0,N0(:,5),'LineWidth',1.25); hold on;
plot(tN,N(:,5),'LineWidth',1.45);
xline(failure_time,'--','Failure','HandleVisibility','off');
grid on; ylabel('C_{n\delta_a}');
title('Aileron effectiveness in yaw');
legend('ANDI - healthy','ANDI - failure','Location','best');

nexttile;
plot(tY0,Y0(:,5),'LineWidth',1.25); hold on;
plot(tY,Y(:,5),'LineWidth',1.45);
xline(failure_time,'--','Failure','HandleVisibility','off');
grid on; xlabel('Time [s]'); ylabel('C_{Y\delta_a}');
title('Aileron effectiveness in side force');
legend('ANDI - healthy','ANDI - failure','Location','best');

sgtitle('Identified aileron control derivatives: healthy versus failed ANDI run');
exportgraphics(gcf,fullfile(outdir,'Fig02b_aileron_effectiveness_healthy_vs_failure.png'),'Resolution',300);

%% ============================================================
% 2C. NUMERICAL AILERON-EFFECTIVENESS CHANGE
% =============================================================
preL  = tL >= rls_pre_window(1)  & tL <= rls_pre_window(2);
postL = tL >= rls_post_window(1) & tL <= rls_post_window(2);
preN  = tN >= rls_pre_window(1)  & tN <= rls_pre_window(2);
postN = tN >= rls_post_window(1) & tN <= rls_post_window(2);
preY  = tY >= rls_pre_window(1)  & tY <= rls_pre_window(2);
postY = tY >= rls_post_window(1) & tY <= rls_post_window(2);

preEff  = [mean(L(preL,5),'omitnan'); mean(N(preN,5),'omitnan'); mean(Y(preY,5),'omitnan')];
postEff = [mean(L(postL,5),'omitnan'); mean(N(postN,5),'omitnan'); mean(Y(postY,5),'omitnan')];
remainingPct = 100*abs(postEff./preEff);
lossPct      = 100-remainingPct;

aileDerivNames = {'C_l_delta_a';'C_n_delta_a';'C_Y_delta_a'};
AileronEffectivenessSummary = table(aileDerivNames,preEff,postEff,remainingPct,lossPct, ...
    'VariableNames',{'Derivative','MeanPreFailure','MeanPostFailure', ...
                     'EffectivenessRemaining_pct','EffectivenessLoss_pct'});

writetable(AileronEffectivenessSummary, ...
    fullfile(outdir,'Table02_aileron_effectiveness_summary.csv'));

%% ============================================================
% 3. TRAJECTORIES - ALL FOUR RUNS
% =============================================================
figure('Color','w','Position',[100 80 1300 850]);
hold on;

for rr = 1:4
    R = runs{rr};
    plot(R.yout(:,i_yE),R.yout(:,i_xN),'LineWidth',1.4);
end

% Mark failure points only for the two failed runs.
[~,iCF] = min(abs(CF.tout(:)-failure_time));
[~,iAF] = min(abs(AF.tout(:)-failure_time));
plot(CF.yout(iCF,i_yE),CF.yout(iCF,i_xN),'o','MarkerSize',8,'LineWidth',1.4, ...
    'HandleVisibility','off');
plot(AF.yout(iAF,i_yE),AF.yout(iAF,i_xN),'o','MarkerSize',8,'LineWidth',1.4, ...
    'HandleVisibility','off');

grid on;
axis equal;
xlabel('East position y_e [m]');
ylabel('North position x_e [m]');
legend(runNames,'Location','best');
title('Aircraft ground trajectories for the four validation runs');
exportgraphics(gcf,fullfile(outdir,'Fig03_trajectories_2D.png'),'Resolution',300);

%% 3-D trajectories
figure('Color','w','Position',[100 80 1300 850]);
hold on;
for rr = 1:4
    R = runs{rr};
    plot3(R.yout(:,i_yE),R.yout(:,i_xN),R.yout(:,i_h),'LineWidth',1.3);
end
grid on;
xlabel('East position [m]');
ylabel('North position [m]');
zlabel('Altitude [m]');
legend(runNames,'Location','best');
title('3-D validation trajectories');
view(3);
exportgraphics(gcf,fullfile(outdir,'Fig03b_trajectories_3D.png'),'Resolution',300);

%% ============================================================
% 4. CONTROL SURFACES VS JOYSTICK - CLASSICAL CONTROLLER
%    Left column: healthy. Right column: failure.
% =============================================================
surfaceNames = {'Elevator','Aileron','Rudder'};
joyFields    = {'de_joy','da_joy','dr_joy'};
actFields    = {'de_actual','da_actual','dr_actual'};
cmdFieldsC   = {'de_classical','da_classical','dr_classical'};
ylabelsSurf  = {'\delta_e [deg]','\delta_a [deg]','\delta_r [deg]'};

figure('Color','w','Position',[60 40 1500 950]);
tiledlayout(3,2,'TileSpacing','compact','Padding','compact');

classicalRuns = {C0,CF};
classicalTitles = {'Healthy','Failure'};

for row = 1:3
    for col = 1:2
        nexttile;
        R = classicalRuns{col};
        hold on;

        ts = R.(joyFields{row});
        plot(ts.Time(:),rad2deg(squeeze(ts.Data)),'--','LineWidth',1.15);

        ts = R.(cmdFieldsC{row});
        plot(ts.Time(:),rad2deg(squeeze(ts.Data)),'LineWidth',1.3);

        ts = R.(actFields{row});
        plot(ts.Time(:),rad2deg(squeeze(ts.Data)),'LineWidth',1.35);

        xline(failure_time,'--','t_f','HandleVisibility','off');
        grid on;
        ylabel(ylabelsSurf{row});
        title(sprintf('%s - %s',surfaceNames{row},classicalTitles{col}));

        if row == 3
            xlabel('Time [s]');
        end
        if row == 1 && col == 1
            legend('Joystick command','Controller command','Actual surface','Location','best');
        end
    end
end

sgtitle('Classical controller: joystick commands, controller commands and actual surfaces');
exportgraphics(gcf,fullfile(outdir,'Fig04_classical_surfaces_healthy_failure.png'),'Resolution',300);

%% ============================================================
% 5. CONTROL SURFACES VS JOYSTICK - ANDI CONTROLLER
% =============================================================
cmdFieldsA = {'de_ANDI','da_ANDI','dr_ANDI'};

figure('Color','w','Position',[60 40 1500 950]);
tiledlayout(3,2,'TileSpacing','compact','Padding','compact');

andiRuns = {A0,AF};
andiTitles = {'Healthy','Failure'};

for row = 1:3
    for col = 1:2
        nexttile;
        R = andiRuns{col};
        hold on;

        ts = R.(joyFields{row});
        plot(ts.Time(:),rad2deg(squeeze(ts.Data)),'--','LineWidth',1.15);

        ts = R.(cmdFieldsA{row});
        plot(ts.Time(:),rad2deg(squeeze(ts.Data)),'LineWidth',1.3);

        ts = R.(actFields{row});
        plot(ts.Time(:),rad2deg(squeeze(ts.Data)),'LineWidth',1.35);

        xline(failure_time,'--','t_f','HandleVisibility','off');
        grid on;
        ylabel(ylabelsSurf{row});
        title(sprintf('%s - %s',surfaceNames{row},andiTitles{col}));

        if row == 3
            xlabel('Time [s]');
        end
        if row == 1 && col == 1
            legend('Joystick command','ANDI command','Actual surface','Location','best');
        end
    end
end

sgtitle('Fault-tolerant ANDI: joystick commands, controller commands and actual surfaces');
exportgraphics(gcf,fullfile(outdir,'Fig05_ANDI_surfaces_healthy_failure.png'),'Resolution',300);

%% ============================================================
% 6. DIRECT RATE/SIDESLIP TRACKING COMPARISON IN THE FAILED RUNS
%    Left: classical failure. Right: ANDI failure.
% =============================================================
actualFields = {'p','q','r','beta'};
refFields    = {'p_ref','q_ref','r_ref','beta_ref'};
trackTitles  = {'Roll rate p','Pitch rate q','Yaw rate r','Sideslip \beta'};
trackYlabels = {'p [deg/s]','q [deg/s]','r [deg/s]','\beta [deg]'};
failedRuns   = {CF,AF};
failedNames  = {'Classical - failure','ANDI - failure'};

figure('Color','w','Position',[50 30 1500 1050]);
tiledlayout(4,2,'TileSpacing','compact','Padding','compact');

for row = 1:4
    for col = 1:2
        nexttile;
        R = failedRuns{col};
        hold on;

        tsA = R.(actualFields{row});
        tsR = R.(refFields{row});

        plot(tsR.Time(:),rad2deg(squeeze(tsR.Data)),'--','LineWidth',1.15);
        plot(tsA.Time(:),rad2deg(squeeze(tsA.Data)),'LineWidth',1.3);

        xline(failure_time,'--','Failure','HandleVisibility','off');
        grid on;
        ylabel(trackYlabels{row});
        title(sprintf('%s: %s',failedNames{col},trackTitles{row}));

        if row == 4
            xlabel('Time [s]');
        end
        if row == 1
            legend('Reference','Actual','Location','best');
        end
    end
end

sgtitle('Rate and sideslip tracking: classical versus fault-tolerant control');
exportgraphics(gcf,fullfile(outdir,'Fig06_rate_sideslip_tracking_failed_runs.png'),'Resolution',300);

%% ============================================================
% 6B. NUMERICAL TRACKING-ERROR SUMMARY FOR ALL FOUR RUNS
% =============================================================
RMSpre     = nan(4,4);
RMSpost    = nan(4,4);
MaxErrPost = nan(4,4);

for rr = 1:4
    R = runs{rr};

    for ss = 1:4
        tsA = R.(actualFields{ss});
        tsR = R.(refFields{ss});

        tA = tsA.Time(:);
        a  = squeeze(tsA.Data); a = a(:);
        tR = tsR.Time(:);
        ref = squeeze(tsR.Data); ref = ref(:);

        % Interpolate the reference onto the actual-signal time grid.
        refI = interp1(tR,ref,tA,'linear','extrap');
        errDeg = rad2deg(a-refI);

        idxPre  = tA >= detector_arm_time & tA < failure_time;
        idxPost = tA >= failure_time;

        RMSpre(rr,ss)     = sqrt(mean(errDeg(idxPre).^2,'omitnan'));
        RMSpost(rr,ss)    = sqrt(mean(errDeg(idxPost).^2,'omitnan'));
        MaxErrPost(rr,ss) = max(abs(errDeg(idxPost)),[],'omitnan');
    end
end

TrackingSummary = table(runNames(:), ...
    RMSpre(:,1),RMSpost(:,1),MaxErrPost(:,1), ...
    RMSpre(:,2),RMSpost(:,2),MaxErrPost(:,2), ...
    RMSpre(:,3),RMSpost(:,3),MaxErrPost(:,3), ...
    RMSpre(:,4),RMSpost(:,4),MaxErrPost(:,4), ...
    'VariableNames',{'Run', ...
    'RMS_p_pre_deg_s','RMS_p_post_deg_s','MaxAbsErr_p_post_deg_s', ...
    'RMS_q_pre_deg_s','RMS_q_post_deg_s','MaxAbsErr_q_post_deg_s', ...
    'RMS_r_pre_deg_s','RMS_r_post_deg_s','MaxAbsErr_r_post_deg_s', ...
    'RMS_beta_pre_deg','RMS_beta_post_deg','MaxAbsErr_beta_post_deg'});

writetable(TrackingSummary,fullfile(outdir,'Table03_tracking_summary.csv'));

%% ============================================================
% 7. HANDLING-STATE COMPARISON: ALL FOUR RUNS
%    These variables make loss of control / recovery directly visible.
% =============================================================
figure('Color','w','Position',[60 40 1500 950]);
tiledlayout(3,2,'TileSpacing','compact','Padding','compact');

stateCols   = [i_phi i_theta i_beta i_alpha i_VTAS i_h];
stateTitles = {'Bank angle \phi','Pitch angle \theta','Sideslip \beta', ...
               'Angle of attack \alpha','True airspeed V_{TAS}','Altitude h'};
stateYLabs  = {'\phi [deg]','\theta [deg]','\beta [deg]','\alpha [deg]', ...
               'V_{TAS} [m/s]','h [m]'};

for ss = 1:6
    nexttile;
    hold on;
    for rr = 1:4
        R = runs{rr};
        t = R.tout(:);
        y = R.yout(:,stateCols(ss));
        if ss <= 4
            y = rad2deg(y);
        end
        plot(t,y,'LineWidth',1.15);
    end
    xline(failure_time,'--','Failure time','HandleVisibility','off');
    grid on;
    xlabel('Time [s]');
    ylabel(stateYLabs{ss});
    title(stateTitles{ss});
    if ss == 1
        legend(runNames,'Location','best');
    end
end

sgtitle('Handling-state comparison for all four validation runs');
exportgraphics(gcf,fullfile(outdir,'Fig07_handling_states_all_four.png'),'Resolution',300);

%% ============================================================
% 7B. NUMERICAL HANDLING-QUALITY / SAFETY SUMMARY
% =============================================================
maxAbsP     = nan(4,1);
maxAbsQ     = nan(4,1);
maxAbsR     = nan(4,1);
maxAbsBeta  = nan(4,1);
maxAbsPhi   = nan(4,1);
maxAbsTheta = nan(4,1);
maxVTAS     = nan(4,1);
minAltitude = nan(4,1);
altitudeLoss = nan(4,1);
finalAltitude = nan(4,1);

for rr = 1:4
    R = runs{rr};
    t = R.tout(:);
    idxPost = t >= failure_time;
    [~,ifail] = min(abs(t-failure_time));

    maxAbsP(rr)     = max(abs(rad2deg(R.yout(idxPost,i_p))),[],'omitnan');
    maxAbsQ(rr)     = max(abs(rad2deg(R.yout(idxPost,i_q))),[],'omitnan');
    maxAbsR(rr)     = max(abs(rad2deg(R.yout(idxPost,i_r))),[],'omitnan');
    maxAbsBeta(rr)  = max(abs(rad2deg(R.yout(idxPost,i_beta))),[],'omitnan');
    maxAbsPhi(rr)   = max(abs(rad2deg(R.yout(idxPost,i_phi))),[],'omitnan');
    maxAbsTheta(rr) = max(abs(rad2deg(R.yout(idxPost,i_theta))),[],'omitnan');
    maxVTAS(rr)     = max(R.yout(idxPost,i_VTAS),[],'omitnan');
    minAltitude(rr) = min(R.yout(idxPost,i_h),[],'omitnan');
    altitudeLoss(rr)= R.yout(ifail,i_h)-minAltitude(rr);
    finalAltitude(rr)=R.yout(end,i_h);
end

HandlingSummary = table(runNames(:),maxAbsP,maxAbsQ,maxAbsR,maxAbsBeta, ...
    maxAbsPhi,maxAbsTheta,maxVTAS,minAltitude,altitudeLoss,finalAltitude, ...
    'VariableNames',{'Run','MaxAbs_p_post_deg_s','MaxAbs_q_post_deg_s', ...
    'MaxAbs_r_post_deg_s','MaxAbs_beta_post_deg','MaxAbs_phi_post_deg', ...
    'MaxAbs_theta_post_deg','Max_VTAS_post_m_s','MinAltitude_post_m', ...
    'AltitudeLossFromFailure_m','FinalAltitude_m'});

writetable(HandlingSummary,fullfile(outdir,'Table04_handling_summary.csv'));

%% ============================================================
% 8. TRAJECTORY DEVIATION CAUSED BY THE FAILURE
%    Compare each failed run with its own healthy baseline.
% =============================================================
% Classical: interpolate healthy trajectory onto failed time vector.
tCF = CF.tout(:);
xC0i = interp1(C0.tout(:),C0.yout(:,i_xN),tCF,'linear','extrap');
yC0i = interp1(C0.tout(:),C0.yout(:,i_yE),tCF,'linear','extrap');
hC0i = interp1(C0.tout(:),C0.yout(:,i_h), tCF,'linear','extrap');

dxC = CF.yout(:,i_xN)-xC0i;
dyC = CF.yout(:,i_yE)-yC0i;
dhC = CF.yout(:,i_h)-hC0i;
errC_horizontal = sqrt(dxC.^2+dyC.^2);
errC_3D         = sqrt(dxC.^2+dyC.^2+dhC.^2);

% ANDI: interpolate healthy trajectory onto failed time vector.
tAF = AF.tout(:);
xA0i = interp1(A0.tout(:),A0.yout(:,i_xN),tAF,'linear','extrap');
yA0i = interp1(A0.tout(:),A0.yout(:,i_yE),tAF,'linear','extrap');
hA0i = interp1(A0.tout(:),A0.yout(:,i_h), tAF,'linear','extrap');

dxA = AF.yout(:,i_xN)-xA0i;
dyA = AF.yout(:,i_yE)-yA0i;
dhA = AF.yout(:,i_h)-hA0i;
errA_horizontal = sqrt(dxA.^2+dyA.^2);
errA_3D         = sqrt(dxA.^2+dyA.^2+dhA.^2);

figure('Color','w','Position',[100 100 1350 700]);
tiledlayout(2,1,'TileSpacing','compact','Padding','compact');

nexttile;
plot(tCF,errC_horizontal,'LineWidth',1.35); hold on;
plot(tAF,errA_horizontal,'LineWidth',1.35);
xline(failure_time,'--','Failure','HandleVisibility','off');
grid on; ylabel('Horizontal deviation [m]');
title('Failure-induced horizontal trajectory deviation');
legend('Classical','ANDI','Location','best');

nexttile;
plot(tCF,errC_3D,'LineWidth',1.35); hold on;
plot(tAF,errA_3D,'LineWidth',1.35);
xline(failure_time,'--','Failure','HandleVisibility','off');
grid on; xlabel('Time [s]'); ylabel('3-D deviation [m]');
title('Failure-induced 3-D trajectory deviation');
legend('Classical','ANDI','Location','best');

sgtitle('Deviation of each failed trajectory from its healthy baseline');
exportgraphics(gcf,fullfile(outdir,'Fig08_trajectory_deviation.png'),'Resolution',300);

idxCFpost = tCF >= failure_time;
idxAFpost = tAF >= failure_time;

TrajectoryDeviationSummary = table( ...
    {'Classical';'ANDI'}, ...
    [max(errC_horizontal(idxCFpost),[],'omitnan'); max(errA_horizontal(idxAFpost),[],'omitnan')], ...
    [errC_horizontal(end); errA_horizontal(end)], ...
    [max(errC_3D(idxCFpost),[],'omitnan'); max(errA_3D(idxAFpost),[],'omitnan')], ...
    [errC_3D(end); errA_3D(end)], ...
    'VariableNames',{'Controller','MaxHorizontalDeviation_m','FinalHorizontalDeviation_m', ...
    'Max3DDeviation_m','Final3DDeviation_m'});

writetable(TrajectoryDeviationSummary, ...
    fullfile(outdir,'Table05_trajectory_deviation_summary.csv'));

%% ============================================================
% 9. SAVE ALL NUMERICAL RESULTS TO ONE MAT FILE
% =============================================================
save(fullfile(outdir,'Step6_validation_summary.mat'), ...
    'FaultDetectionSummary','AileronEffectivenessSummary', ...
    'TrackingSummary','HandlingSummary','TrajectoryDeviationSummary', ...
    'failure_time','detector_arm_time','rls_pre_window','rls_post_window');

%% ============================================================
% 10. PRINT THE MOST IMPORTANT TABLES TO THE COMMAND WINDOW
% =============================================================
fprintf('\n============================================================\n');
fprintf('STEP 6 VALIDATION SUMMARY\n');
fprintf('============================================================\n');

fprintf('\n--- Fault monitoring (normalized by threshold) ---\n');
disp(FaultDetectionSummary);

fprintf('\n--- Identified aileron effectiveness ---\n');
disp(AileronEffectivenessSummary);

fprintf('\n--- Rate / sideslip tracking ---\n');
disp(TrackingSummary);

fprintf('\n--- Handling / safety metrics ---\n');
disp(HandlingSummary);

fprintf('\n--- Failed-vs-healthy trajectory deviation ---\n');
disp(TrajectoryDeviationSummary);

fprintf('\nAll figures and CSV tables were written to:\n  %s\n',outdir);
fprintf('Done.\n');
