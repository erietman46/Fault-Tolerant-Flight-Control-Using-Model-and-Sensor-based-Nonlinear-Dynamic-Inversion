%% STEP 4 - Healthy vs Failed Comparison
% Compare MA^2, autocorrelation and variance.
% Then construct six thresholds for the selected detector (MA^2).

clear
clc
close all

%% ========================================================
%  Load simulations
% =========================================================

load('Step4_healthy.mat','healthy')
load('Step4_failed.mat','failed')

%% ========================================================
%  Settings
% =========================================================

labels = {'X','Y','Z','L','M','N'};

t_start = 5;       % Ignore initialization transient
tf      = 28;      % Failure activation time

% Channel used for the first visual comparison
% X=1, Y=2, Z=3, L=4, M=5, N=6
channel = 6;

%% ========================================================
%  Extract monitoring signals
%
%  Original Simulink dimensions:
%       6 x 1 x N
%
%  After squeeze:
%       6 x N
%
%  Rows    = channels
%  Columns = time samples
% =========================================================

H_MA2  = squeeze(healthy.Jma.Data(:,1,:));
F_MA2  = squeeze(failed.Jma.Data(:,1,:));

H_corr = squeeze(healthy.Jcorr.Data(:,1,:));
F_corr = squeeze(failed.Jcorr.Data(:,1,:));

H_var  = squeeze(healthy.Jvar.Data(:,1,:));
F_var  = squeeze(failed.Jvar.Data(:,1,:));

%% Time vectors

tH_MA2  = healthy.Jma.Time(:);
tF_MA2  = failed.Jma.Time(:);

tH_corr = healthy.Jcorr.Time(:);
tF_corr = failed.Jcorr.Time(:);

tH_var  = healthy.Jvar.Time(:);
tF_var  = failed.Jvar.Time(:);

%% ========================================================
%  1. Visual comparison for one selected channel
% =========================================================

figure

tiledlayout(3,1)

% ---------------------------------------------------------
% MA^2
% ---------------------------------------------------------

nexttile

plot(tH_MA2, H_MA2(channel,:), ...
    'LineWidth',1.2)

hold on

plot(tF_MA2, F_MA2(channel,:), ...
    '--','LineWidth',1.2)

xline(tf,'k--','Failure','LineWidth',1.2)

grid on

ylabel('MA^2')

legend('Healthy','Failed','Location','best')

title(['Monitoring metrics - channel ',labels{channel}])


% ---------------------------------------------------------
% Autocorrelation
% ---------------------------------------------------------

nexttile

plot(tH_corr, H_corr(channel,:), ...
    'LineWidth',1.2)

hold on

plot(tF_corr, F_corr(channel,:), ...
    '--','LineWidth',1.2)

xline(tf,'k--','Failure','LineWidth',1.2)

grid on

ylabel('Autocorrelation')

legend('Healthy','Failed','Location','best')


% ---------------------------------------------------------
% Variance
% ---------------------------------------------------------

nexttile

plot(tH_var, H_var(channel,:), ...
    'LineWidth',1.2)

hold on

plot(tF_var, F_var(channel,:), ...
    '--','LineWidth',1.2)

xline(tf,'k--','Failure','LineWidth',1.2)

grid on

ylabel('Variance')

xlabel('Time [s]')

legend('Healthy','Failed','Location','best')


%% Link horizontal axes

ax = findall(gcf,'Type','axes');

linkaxes(ax,'x')

xlim([0 40])

%% ========================================================
%  2. Healthy envelopes
%
%  Only consider t >= 5 s so that startup transients are
%  excluded.
% =========================================================

idxH_MA2  = tH_MA2  >= t_start;
idxH_corr = tH_corr >= t_start;
idxH_var  = tH_var  >= t_start;

maxHealthy_MA2 = max( ...
    H_MA2(:,idxH_MA2), ...
    [],2);

% Autocorrelation can be positive or negative
maxHealthy_corr = max( ...
    abs(H_corr(:,idxH_corr)), ...
    [],2);

maxHealthy_var = max( ...
    H_var(:,idxH_var), ...
    [],2);

%% ========================================================
%  3. Post-failure maxima
%
%  Only consider t >= 28 s
% =========================================================

idxF_MA2  = tF_MA2  >= tf;
idxF_corr = tF_corr >= tf;
idxF_var  = tF_var  >= tf;

maxFailure_MA2 = max( ...
    F_MA2(:,idxF_MA2), ...
    [],2);

maxFailure_corr = max( ...
    abs(F_corr(:,idxF_corr)), ...
    [],2);

maxFailure_var = max( ...
    F_var(:,idxF_var), ...
    [],2);

%% ========================================================
%  4. Failure / healthy separation ratios
% =========================================================

ratio_MA2 = ...
    maxFailure_MA2 ./ maxHealthy_MA2;

ratio_corr = ...
    maxFailure_corr ./ maxHealthy_corr;

ratio_var = ...
    maxFailure_var ./ maxHealthy_var;

%% ========================================================
%  5. Healthy envelope table
% =========================================================

HealthyTable = table( ...
    labels(:), ...
    maxHealthy_MA2, ...
    maxHealthy_corr, ...
    maxHealthy_var, ...
    'VariableNames', ...
    {'Channel', ...
     'MA2_Healthy', ...
     'Corr_Healthy', ...
     'Var_Healthy'});
disp(' ')
disp('========== HEALTHY ENVELOPES ==========')
disp(HealthyTable)

%% ========================================================
%  6. Post-failure maxima table
% =========================================================

FailureTable = table( ...
    labels(:), ...
    maxFailure_MA2, ...
    maxFailure_corr, ...
    maxFailure_var, ...
    'VariableNames', ...
    {'Channel', ...
     'MA2_Failure', ...
     'Corr_Failure', ...
     'Var_Failure'});
disp(' ')
disp('========== POST-FAILURE MAXIMA ==========')
disp(FailureTable)

%% ========================================================
%  7. Separation-ratio table
% =========================================================

RatioTable = table( ...
    labels(:), ...
    ratio_MA2, ...
    ratio_corr, ...
    ratio_var, ...
    'VariableNames', ...
    {'Channel', ...
     'MA2_Ratio', ...
     'Corr_Ratio', ...
     'Var_Ratio'});
disp(' ')
disp('========== FAILURE / HEALTHY SEPARATION ==========')
disp(RatioTable)

%% ========================================================
%  8. Summary
% =========================================================

[bestMA2,bestMA2idx] = max(ratio_MA2);

[bestCorr,bestCorridx] = max(ratio_corr);

[bestVar,bestVaridx] = max(ratio_var);

fprintf('\n========== SUMMARY ==========\n')

fprintf('Largest MA2 separation:  %.3f in channel %s\n', ...
    bestMA2,labels{bestMA2idx})

fprintf('Largest Corr separation: %.3f in channel %s\n', ...
    bestCorr,labels{bestCorridx})

fprintf('Largest Var separation:  %.3f in channel %s\n', ...
    bestVar,labels{bestVaridx})

%% ========================================================
%  9. INITIAL VARIANCE THRESHOLDS
%
%  Variance has been selected as the detector.
%
%       T_i = safetyFactor * max healthy variance
%
% =========================================================

safetyFactor = 1.5;

T_var = safetyFactor * maxHealthy_var;

TX = T_var(1);
TY = T_var(2);
TZ = T_var(3);
TL = T_var(4);
TM = T_var(5);
TN = T_var(6);

ThresholdTable = table( ...
    labels(:), ...
    maxHealthy_var, ...
    T_var, ...
    'VariableNames', ...
    {'Channel', ...
     'HealthyMax_Variance', ...
     'Threshold_Variance'});
disp(' ')
disp('========== INITIAL VARIANCE THRESHOLDS ==========')
disp(ThresholdTable)


%% ========================================================
%  10. Compare variance thresholds with post-failure maxima
% =========================================================

ThresholdCheckTable = table( ...
    labels(:), ...
    maxHealthy_var, ...
    T_var, ...
    maxFailure_var, ...
    maxFailure_var ./ T_var, ...
    'VariableNames', ...
    {'Channel', ...
     'HealthyMax', ...
     'Threshold', ...
     'FailureMax', ...
     'FailureToThreshold'});
disp(' ')
disp('========== VARIANCE THRESHOLD CHECK ==========')
disp(ThresholdCheckTable)


%% ========================================================
%  11. Plot variance threshold on failed run
%
%  Start with N channel
% =========================================================

channelThreshold = 1;       % N channel

figure

plot(tF_var, ...
     F_var(channelThreshold,:), ...
     'LineWidth',1.2)

hold on

plot(tH_var, ...
     H_var(channelThreshold,:), ...
     '--','LineWidth',1.0)

yline(T_var(channelThreshold), ...
      'r--','Threshold', ...
      'LineWidth',1.5)

xline(tf, ...
      'k--','Failure', ...
      'LineWidth',1.2)

grid on

xlim([0 40])

xlabel('Time [s]')
ylabel('Variance')

title(['Variance threshold check - ', ...
       labels{channelThreshold}, ...
       ' channel'])

legend('Failed run', ...
       'Healthy run', ...
       'Threshold', ...
       'Failure activation', ...
       'Location','best')

%% ========================================================
%  FINAL DETECTOR VALIDATION
% =========================================================

idxHealthy = tH_var >= t_start;

idxPreFailure = ...
    tF_var >= t_start & ...
    tF_var < tf;

idxPostFailure = ...
    tF_var >= tf;

% ---------------------------------------------------------
% Healthy simulation threshold crossings
% ---------------------------------------------------------

healthyCross = any( ...
    H_var(:,idxHealthy) > T_var, ...
    2);

% ---------------------------------------------------------
% False alarms in failed simulation BEFORE failure
% ---------------------------------------------------------

preFailureCross = any( ...
    F_var(:,idxPreFailure) > T_var, ...
    2);

% ---------------------------------------------------------
% Successful detections AFTER failure
% ---------------------------------------------------------

postFailureCross = any( ...
    F_var(:,idxPostFailure) > T_var, ...
    2);

% ---------------------------------------------------------
% Detection times
% ---------------------------------------------------------

tPost = tF_var(idxPostFailure);

detectionTime  = NaN(6,1);
detectionDelay = NaN(6,1);

for i = 1:6

    signalPost = F_var(i,idxPostFailure);

    k = find( ...
        signalPost > T_var(i), ...
        1,'first');

    if ~isempty(k)

        detectionTime(i) = tPost(k);

        detectionDelay(i) = ...
            detectionTime(i) - tf;

    end
end

%% Results

ValidationTable = table( ...
    labels(:), ...
    maxHealthy_var, ...
    T_var, ...
    maxFailure_var, ...
    healthyCross, ...
    preFailureCross, ...
    postFailureCross, ...
    detectionTime, ...
    detectionDelay, ...
    'VariableNames', ...
    {'Channel', ...
    'HealthyMax', ...
    'Threshold', ...
    'FailureMax', ...
    'HealthyCross', ...
    'PreFailureCross', ...
    'PostFailureCross', ...
    'DetectionTime', ...
    'DetectionDelay'});

disp(' ')
disp('========== FINAL VARIANCE DETECTOR CHECK ==========')
disp(ValidationTable)