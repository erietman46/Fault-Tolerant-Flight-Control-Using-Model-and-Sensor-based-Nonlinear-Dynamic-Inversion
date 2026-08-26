channel = 4;       % X=1 Y=2 Z=3 L=4 M=5 N=6
tf = 28;

figure

tiledlayout(3,1)

% Healthy
tH = healthy.Jma.Time(:);
dH = squeeze(healthy.Jma.Data);

if size(dH,1) == length(tH)
    yH = dH(:,channel);
elseif size(dH,2) == length(tH)
    yH = dH(channel,:).';
else
    error('Cannot match healthy Jma data dimensions to time.');
end

% Failed
tF = failed.Jma.Time(:);
dF = squeeze(failed.Jma.Data);

if size(dF,1) == length(tF)
    yF = dF(:,channel);
elseif size(dF,2) == length(tF)
    yF = dF(channel,:).';
else
    error('Cannot match failed Jma data dimensions to time.');
end

plot(tH,yH)
hold on
plot(tF,yF,'--')
xline(tf)
grid on
ylabel('MA^2')
legend('Healthy','Failure')


nexttile
plot(healthy.Jcorr.Time,healthy.Jcorr.Data(:,channel))
hold on
plot(failed.Jcorr.Time,failed.Jcorr.Data(:,channel),'--')
xline(tf)
grid on
ylabel('Autocorrelation')

nexttile
plot(healthy.Jvar.Time,healthy.Jvar.Data(:,channel))
hold on
plot(failed.Jvar.Time,failed.Jvar.Data(:,channel),'--')
xline(tf)
grid on
ylabel('Variance')
xlabel('Time [s]')