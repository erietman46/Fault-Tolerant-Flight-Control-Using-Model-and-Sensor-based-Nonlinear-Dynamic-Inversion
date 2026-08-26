%% STEP 4 - Healthy vs Failed Comparison
% Compare MA^2, autocorrelation and variance.


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

channelThreshold = 1;      

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

%% ========================================================
%  11. VARIANCE THRESHOLD VALIDATION - ALL SIX CHANNELS
%
%  Compare healthy and failed variance signals against
%  the individual detector thresholds.
%
%  The interval 18-25 s corresponds to cruise / no
%  manoeuvring input and is used to assess false alarms.
% =========================================================

cruiseStart = 18;
cruiseEnd   = 25;

plotEnd = 40;

% Only plot the part of the simulation used for detector
% assessment. Startup transient before t_start is excluded.
idxH_plot = ...
    tH_var >= t_start & ...
    tH_var <= plotEnd;

idxF_plot = ...
    tF_var >= t_start & ...
    tF_var <= plotEnd;


figure

tl = tiledlayout(2,3, ...
    'TileSpacing','compact', ...
    'Padding','compact');

sgtitle('Variance detector validation: healthy versus failed aircraft')


for i = 1:6

    ax = nexttile;
    hold(ax,'on')
    grid(ax,'on')
    box(ax,'on')

    % -----------------------------------------------------
    % Healthy variance
    % -----------------------------------------------------

    hHealthy = plot( ...
        tH_var(idxH_plot), ...
        H_var(i,idxH_plot), ...
        'LineWidth',1.2, ...
        'DisplayName','Healthy');


    % -----------------------------------------------------
    % Failed variance
    % -----------------------------------------------------

    hFailed = plot( ...
        tF_var(idxF_plot), ...
        F_var(i,idxF_plot), ...
        '--', ...
        'LineWidth',1.2, ...
        'DisplayName','Failed');


    % -----------------------------------------------------
    % Channel-specific threshold
    % -----------------------------------------------------

    hThreshold = yline( ...
        T_var(i), ...
        '--', ...
        'LineWidth',1.4, ...
        'DisplayName','Threshold');


    % -----------------------------------------------------
    % Failure activation
    % -----------------------------------------------------

    hFailure = xline( ...
        tf, ...
        '--', ...
        'LineWidth',1.2, ...
        'DisplayName','Failure activation');


    % -----------------------------------------------------
    % Axis limits before adding cruise shading
    % -----------------------------------------------------

    xlim([t_start plotEnd])

    % Make sure zero and threshold are visible
    valuesVisible = [ ...
        H_var(i,idxH_plot), ...
        F_var(i,idxF_plot), ...
        T_var(i)];

    ymax = max(valuesVisible);

    if ymax > 0
        ylim([0 1.08*ymax])
    end


    % -----------------------------------------------------
    % Shade cruise / no-manoeuvre interval: 18-25 s
    % -----------------------------------------------------

    yl = ylim;

    hCruise = patch( ...
        [cruiseStart cruiseEnd cruiseEnd cruiseStart], ...
        [yl(1) yl(1) yl(2) yl(2)], ...
        [0.85 0.85 0.85], ...
        'FaceAlpha',0.18, ...
        'EdgeColor','none', ...
        'DisplayName','Cruise / no manoeuvre');

    % Put shading behind the signals
    uistack(hCruise,'bottom')


    % -----------------------------------------------------
    % Labels
    % -----------------------------------------------------

    title([labels{i}, ' channel'])

    xlabel('Time [s]')
    ylabel('Variance')


    % -----------------------------------------------------
    % Legend only once to avoid six identical legends
    % -----------------------------------------------------

    if i == 1

        legend( ...
            [hHealthy, ...
             hFailed, ...
             hThreshold, ...
             hFailure, ...
             hCruise], ...
            {'Healthy', ...
             'Failed', ...
             'Threshold', ...
             'Failure activation', ...
             'Cruise / no manoeuvre'}, ...
            'Location','best')

    end

end

%% ========================================================
%  Extract adaptive forgetting factor lambda
%
%  Lambda is logged with a different signal orientation
%  from Jma, Jcorr and Jvar. Therefore, first squeeze all
%  singleton dimensions and then enforce:
%
%       rows    = X,Y,Z,L,M,N
%       columns = time
% =========================================================

tH_lambda = healthy.lambda.Time(:);
tF_lambda = failed.lambda.Time(:);

H_lambda = squeeze(healthy.lambda.Data);
F_lambda = squeeze(failed.lambda.Data);


% ---------------------------------------------------------
% Ensure orientation is:
%
%       6 x N
%
% rows    = channels
% columns = time samples
% ---------------------------------------------------------

if size(H_lambda,1) == numel(tH_lambda)
    H_lambda = H_lambda.';
end

if size(F_lambda,1) == numel(tF_lambda)
    F_lambda = F_lambda.';
end


% ---------------------------------------------------------
% Safety checks
% ---------------------------------------------------------

if size(H_lambda,1) ~= 6
    error(['Healthy lambda does not contain 6 channels. ', ...
           'Current size is %d x %d.'], ...
           size(H_lambda,1),size(H_lambda,2))
end

if size(F_lambda,1) ~= 6
    error(['Failed lambda does not contain 6 channels. ', ...
           'Current size is %d x %d.'], ...
           size(F_lambda,1),size(F_lambda,2))
end

if size(H_lambda,2) ~= numel(tH_lambda)
    error(['Healthy lambda time dimension does not match ', ...
           'the lambda time vector.'])
end

if size(F_lambda,2) ~= numel(tF_lambda)
    error(['Failed lambda time dimension does not match ', ...
           'the lambda time vector.'])
end


fprintf('\nLambda dimensions after processing:\n')
fprintf('Healthy: %d x %d\n',size(H_lambda,1),size(H_lambda,2))
fprintf('Failed:  %d x %d\n',size(F_lambda,1),size(F_lambda,2))

%% ========================================================
%  12. ADAPTIVE FORGETTING FACTOR VALIDATION - ALL CHANNELS
%
%  Plot lambda for healthy and failed simulations.
%  The interval 18-25 s corresponds to cruise / no
%  manoeuvring input.
% =========================================================

cruiseStart = 18;
cruiseEnd   = 25;

plotStart = t_start;
plotEnd   = 40;

idxH_lambda_plot = ...
    tH_lambda >= plotStart & ...
    tH_lambda <= plotEnd;

idxF_lambda_plot = ...
    tF_lambda >= plotStart & ...
    tF_lambda <= plotEnd;

lambdaYLim = [0.997 1.0001];

figure

tl = tiledlayout(2,3, ...
    'TileSpacing','compact', ...
    'Padding','compact');

sgtitle('Adaptive forgetting factor \lambda: healthy versus failed aircraft')

for i = 1:6

    ax = nexttile;
    hold(ax,'on')
    grid(ax,'on')
    box(ax,'on')

    % -----------------------------------------------------
    % Healthy lambda
    % -----------------------------------------------------
    hHealthy = plot( ...
        tH_lambda(idxH_lambda_plot), ...
        H_lambda(i,idxH_lambda_plot), ...
        'LineWidth',1.2, ...
        'DisplayName','Healthy');

    % -----------------------------------------------------
    % Failed lambda
    % -----------------------------------------------------
    hFailed = plot( ...
        tF_lambda(idxF_lambda_plot), ...
        F_lambda(i,idxF_lambda_plot), ...
        '--', ...
        'LineWidth',1.2, ...
        'DisplayName','Failed');

    % -----------------------------------------------------
    % Failure activation
    % -----------------------------------------------------
    hFailure = xline( ...
        tf, ...
        '--', ...
        'LineWidth',1.2, ...
        'DisplayName','Failure activation');

    % -----------------------------------------------------
    % Axes
    % -----------------------------------------------------
    xlim([plotStart plotEnd])
    ylim(lambdaYLim)

    % -----------------------------------------------------
    % Cruise / no-manoeuvre interval shading
    % -----------------------------------------------------
    yl = ylim;

    hCruise = patch( ...
        [cruiseStart cruiseEnd cruiseEnd cruiseStart], ...
        [yl(1) yl(1) yl(2) yl(2)], ...
        [0.85 0.85 0.85], ...
        'FaceAlpha',0.18, ...
        'EdgeColor','none', ...
        'DisplayName','Cruise / no manoeuvre');

    uistack(hCruise,'bottom')

    % -----------------------------------------------------
    % Labels
    % -----------------------------------------------------
    title(['\lambda_{', labels{i}, '}'])
    xlabel('Time [s]')
    ylabel('\lambda')

    % -----------------------------------------------------
    % Show channel minimum in the title area
    % -----------------------------------------------------
    minHealthy = min(H_lambda(i,idxH_lambda_plot));
    minFailed  = min(F_lambda(i,idxF_lambda_plot));

    text( ...
        plotStart + 0.5, ...
        lambdaYLim(1) + 0.10*(lambdaYLim(2)-lambdaYLim(1)), ...
        sprintf('min H = %.5f\\nmin F = %.5f', ...
                minHealthy, minFailed), ...
        'FontSize',8, ...
        'VerticalAlignment','bottom')

    % -----------------------------------------------------
    % Legend only once
    % -----------------------------------------------------
    if i == 1

        legend( ...
            [hHealthy, ...
             hFailed, ...
             hFailure, ...
             hCruise], ...
            {'Healthy', ...
             'Failed', ...
             'Failure activation', ...
             'Cruise / no manoeuvre'}, ...
            'Location','best')

    end

end
%% ========================================================
%  14. RESET SIGNAL VALIDATION
%
%  Healthy simulation:
%       No reset should occur in any channel.
%
%  Failed simulation:
%       For the asymmetric aileron failure, resets should
%       occur only in Y, L and N.
%
%  Signals are vertically offset so simultaneous reset
%  pulses remain visible.
% =========================================================

load('step4_healthy_reset.mat','healthy_reset')
load('step4_failed_reset.mat','failed_reset')


% ---------------------------------------------------------
% Extract reset signals
% ---------------------------------------------------------

tH_reset = healthy_reset.reset_all.Time(:);
tF_reset = failed_reset.reset_all.Time(:);

H_reset = squeeze(healthy_reset.reset_all.Data);
F_reset = squeeze(failed_reset.reset_all.Data);


% ---------------------------------------------------------
% Force orientation:
%
%       6 x N
%
% rows    = X,Y,Z,L,M,N
% columns = time samples
% ---------------------------------------------------------

if size(H_reset,1) == numel(tH_reset) && size(H_reset,2) == 6
    H_reset = H_reset.';
end

if size(F_reset,1) == numel(tF_reset) && size(F_reset,2) == 6
    F_reset = F_reset.';
end


% ---------------------------------------------------------
% Safety checks
% ---------------------------------------------------------

if size(H_reset,1) ~= 6 || ...
        size(H_reset,2) ~= numel(tH_reset)

    error(['Healthy reset signal has unexpected dimensions. ', ...
           'Expected 6 x N, obtained %d x %d.'], ...
           size(H_reset,1),size(H_reset,2))
end


if size(F_reset,1) ~= 6 || ...
        size(F_reset,2) ~= numel(tF_reset)

    error(['Failed reset signal has unexpected dimensions. ', ...
           'Expected 6 x N, obtained %d x %d.'], ...
           size(F_reset,1),size(F_reset,2))
end


% Convert to logical reset signals
H_reset = H_reset > 0.5;
F_reset = F_reset > 0.5;


% ---------------------------------------------------------
% Plot
% ---------------------------------------------------------

figure

tl = tiledlayout(2,1, ...
    'TileSpacing','compact', ...
    'Padding','compact');

sgtitle('Covariance reset signals')


% =========================================================
% Healthy simulation
% =========================================================

ax1 = nexttile;
hold on
grid on
box on

for i = 1:6

    % Vertical offset:
    %
    % X = 0
    % Y = 1
    % Z = 2
    % L = 3
    % M = 4
    % N = 5
    %
    % A reset pulse adds 0.7 to the channel baseline.

    yReset = (i-1) + 0.7*double(H_reset(i,:));

    stairs( ...
        tH_reset, ...
        yReset, ...
        'LineWidth',1.2)

end


% Show detector arming time
xline( ...
    5, ...
    ':', ...
    'Reset logic armed', ...
    'LineWidth',1.1);


xlim([0 40])
ylim([-0.3 5.9])

yticks(0:5)
yticklabels(labels)

xlabel('Time [s]')
ylabel('RLS channel')

title('Healthy aircraft - reset enabled')


% =========================================================
% Failed simulation
% =========================================================

ax2 = nexttile;
hold on
grid on
box on

for i = 1:6

    yReset = (i-1) + 0.7*double(F_reset(i,:));

    stairs( ...
        tF_reset, ...
        yReset, ...
        'LineWidth',1.2)

end


% Detector arming
xline( ...
    5, ...
    ':', ...
    'Reset logic armed', ...
    'LineWidth',1.1);


% Failure activation
xline( ...
    tf, ...
    '--', ...
    'Failure', ...
    'LineWidth',1.2);


xlim([0 40])
ylim([-0.3 5.9])

yticks(0:5)
yticklabels(labels)

xlabel('Time [s]')
ylabel('RLS channel')

title('Aileron hardover - reset enabled')


% Keep both panels on identical time axis
linkaxes([ax1 ax2],'x')

%% ========================================================
%  15. RLS COVARIANCE RESET VALIDATION - L CHANNEL
%
%  Show trace(P_L) around the failure and overlay the
%  L-channel reset pulse.
%
%  A large increase in trace(P_L) demonstrates that the
%  covariance matrix is reinitialized and the estimator
%  becomes sensitive to new data again.
% =========================================================

tP_L = failed_reset.P_L.Time(:);

P_L_raw = failed_reset.P_L.Data;


% ---------------------------------------------------------
% Identify which dimension corresponds to time
% ---------------------------------------------------------

Psize = size(P_L_raw);

timeDim = find(Psize == numel(tP_L),1,'last');

if isempty(timeDim)

    error(['Could not identify the time dimension of P_L. ', ...
           'Number of time samples = %d.'], ...
           numel(tP_L))

end


% ---------------------------------------------------------
% Move time dimension to the end
%
% Target:
%
%       6 x 6 x N
% ---------------------------------------------------------

allDims = 1:ndims(P_L_raw);

matrixDims = allDims(allDims ~= timeDim);

P_L_ordered = permute( ...
    P_L_raw, ...
    [matrixDims timeDim]);

P_L_ordered = squeeze(P_L_ordered);


% ---------------------------------------------------------
% Safety check
% ---------------------------------------------------------

if size(P_L_ordered,1) ~= 6 || ...
        size(P_L_ordered,2) ~= 6 || ...
        size(P_L_ordered,3) ~= numel(tP_L)

    error(['P_L could not be converted to 6 x 6 x N. ', ...
           'Current dimensions are %s.'], ...
           mat2str(size(P_L_ordered)))

end


% ---------------------------------------------------------
% Calculate trace(P_L) for every time sample
% ---------------------------------------------------------

trace_P_L = zeros(numel(tP_L),1);

for k = 1:numel(tP_L)

    trace_P_L(k) = trace(P_L_ordered(:,:,k));

end


% ---------------------------------------------------------
% Find first L reset after failure
%
% Channel order:
% X=1, Y=2, Z=3, L=4, M=5, N=6
% ---------------------------------------------------------

Lchannel = 4;

idxLReset = find( ...
    F_reset(Lchannel,:) & ...
    tF_reset.' >= tf, ...
    1, ...
    'first');


if isempty(idxLReset)

    warning('No L-channel reset was found after the failure.')

    tResetL = NaN;

else

    tResetL = tF_reset(idxLReset);

end


% ---------------------------------------------------------
% Plot
% ---------------------------------------------------------

figure

% =========================================================
% Left axis: covariance
% =========================================================

yyaxis left

plot( ...
    tP_L, ...
    trace_P_L, ...
    'LineWidth',1.4)

ylabel('trace(P_L)')

grid on
box on

hold on


% Failure activation
xline( ...
    tf, ...
    '--', ...
    'Failure', ...
    'LineWidth',1.2);


% Actual L reset time
if ~isnan(tResetL)

    xline( ...
        tResetL, ...
        ':', ...
        'L reset', ...
        'LineWidth',1.2);

end


% =========================================================
% Right axis: reset pulse
% =========================================================

yyaxis right

stairs( ...
    tF_reset, ...
    double(F_reset(Lchannel,:)), ...
    'LineWidth',1.2)

ylabel('reset_L')

ylim([-0.05 1.2])


% =========================================================
% Final formatting
% =========================================================

xlim([27 31])

xlabel('Time [s]')

title('L-channel covariance reset after aileron hardover')