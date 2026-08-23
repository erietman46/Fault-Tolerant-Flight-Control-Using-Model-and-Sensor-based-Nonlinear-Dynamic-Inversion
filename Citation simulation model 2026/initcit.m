% INITCITATION.M
%
%
%-----------------------------------------------------------------------------
%
% Author : Clark Borst
%
% September 2004
%
% Control and Simulation Division
% Faculty of Aerospace Engineering
% Delft University of Technology
%
%-----------------------------------------------------------------------------
%
% Version : EXPORT (for Analysis), no gear, no wind.

% Load general and Citation data
load ac_genrl;
load citdata;
load jt15data;

% Define variables in models

% logarithmic wind model
Vw915 = 0;
winddir = -27*(pi/180);

% Load trim data file
trimdatafile = 'CitTrim_AE4311_2026_V120_A7500_M4500.tri'; % also contains the c.g. position

if not(isempty(trimdatafile))
load(trimdatafile,'-mat');
% massinit = [mass, cg (1x3), Inertia (1x4)]
cit_mass = massinit(1)
cit_Inertia = massinit(5:end)
cit_cg = massinit(2:4)
% massinit(2) = 6.5;

disp(' ');
disp('**************************************');
disp('*    Citation 550 initialization     *');
disp('*                                     *');
disp('* Delft University of Technology     *');
disp('* Clark Borst, 2004                  *');
disp('* Coen de Visser, 2022               *');
disp('**************************************');
disp(' ');
disp(['Trim condition  : ' trimdatafile]);
disp(['Aircraft weight : ' num2str(massinit(1)) ' kg']);
disp(['Aircraft cg     : ' num2str(massinit(2)) ' m, ', num2str(massinit(3)) ' m, ', num2str(massinit(4)) ' m']);
disp(['Altitude        : ' num2str(x0(10)) ' m']);
disp(['Speed Vtas      : ' num2str(x0(4)) ' m/s']);
disp(['Gamma           : ' num2str(round((x0(8)-x0(5))/pi*180)) ' deg']);
disp(['Power Lever     : ' num2str(ut0(1)) ]);
disp(' ');
else
    % trim citation at new condition
end

gear_params;

