function steadystate_struct = stabilize(struct, forceStabilization)
%STABILIZE - Simulates the solution increasing the maximum time until when steady state is reached
%
% Syntax:  steadystate_struct = stabilize(struct, forceStabilization)
%
% Inputs:
%   STRUCT - a solution struct as created by PINDRIFT.
%   FORCESTABILIZATION - optional boolean, true by default, 
%     if true forces the simulation to run at least once, if false the
%     stabilization is run just when needed
%
% Outputs:
%   STEADYSTATE_STRUCT - a solution struct that reached its steady state
%
% Example:
%   ssol_i_1S_SR = stabilize(ssol_i_1S_SR, false);
%     check if the provided solution is at its stabilized steady state,
%     if so nothing is done, otherwise runs df until a stabilized solution
%     is obtained
%   ssol_i_1S_SR = stabilize(ssol_i_1S_SR);
%     runs df on the provided input, then checks if the stabilized steady
%     state has been reached and run df again until stabilization is achieved
%
% Other m-files required: pindrift, verifyStabilization
% Subfunctions: none
% MAT-files required: none
%
% See also pindrift, verifyStabilization.

% Author: Ilario Gelmetti, Ph.D. student, perovskite photovoltaics
% Institute of Chemical Research of Catalonia (ICIQ)
% Research Group Prof. Emilio Palomares
% email address: iochesonome@gmail.com
% Supervised by: Dr. Phil Calado, Dr. Piers Barnes, Prof. Jenny Nelson
% Imperial College London
% May 2018; Last revision: May 2018

%------------- BEGIN CODE --------------

% eliminate JV configuration
struct.p.JV = 0;

% shortcut
p = struct.p;

% set tpoints, just a few ones are necessary here
p.tpoints = 10;
p.tmesh_type = 2; % log spaced time mesh

% disable Ana, as the ploting done in pinana results in an error if the simulation doesn't reach the final time point
p.Ana = 0;

%% estimate a good tmax
% a tmax too short would make the solution look stable even
% if it's not; too large and the simulation could fail

max_startingtmax_ions = 10;

% for the no-ions case, the lower the light intensity the slower the
% stabilization. 1 second is ok at least down to 1E-10 suns
max_startingtmax_freecharges = 1;

% if both mobilities are set
if p.mui && p.mue_i
    p.tmax = min([max_startingtmax_ions, p.tmax*1e4, 2^(-log10(p.mui)) / 10 + 2^(-log10(p.mue_i))]);
    min_tmax = max_startingtmax_ions;
% if ionic mobility is zero but free charges mobility is set
elseif p.mue_i
    p.tmax = min([max_startingtmax_freecharges, p.tmax*1e4, 2^(-log10(p.mue_i))]);
    min_tmax = max_startingtmax_freecharges;
end

p.t0 = p.tmax / 1e8;

%% equilibrate until steady state

% initialize the output as the input, if already stable it will stay like
% this
steadystate_struct = struct;

% if forceStabilization option has not been set, don't force stabilization
if ~exist('forceStabilization', 'var')
    forceStabilization = true;
end

% anyway, even if forceStabilization was set false,
% there are some cases where the stabilization is absolutely needed
if ~forceStabilization
    % checks if the input structure reached the final time point
    if size(steadystate_struct.sol, 1) ~= steadystate_struct.p.tpoints
        % in case the provided solution did not reach the final time point,
        % force stabilization
        forceStabilization = true;
    end
    % check if the prefious step was run over sufficient time. In case it was
    % not, the solution could seem stable to verifyStabilization just because
    % the solution did not evolve much in a time that was very short
    if struct.p.tmax < p.tmax
        forceStabilization = true;
    end
end
    
% the warnings are not needed here
warning('off', 'pindrift:verifyStabilization');

while forceStabilization || ~verifyStabilization(steadystate_struct.sol, steadystate_struct.t, 1e-3) % check stability
    disp([mfilename ' - Stabilizing ' inputname(1) ' over ' num2str(p.tmax) ' s with an applied voltage of ' num2str(p.Vapp) ' V']);
    % every cycle starts from the last timepoint of the previous cycle
    steadystate_struct = pindrift(steadystate_struct, p);
    if size(steadystate_struct.sol, 1) ~= steadystate_struct.p.tpoints % simulation failed
        % if the stabilization breaks (does not reach the final time point), reduce the tmax
        p.tmax = p.tmax / 10;
        p.t0 = p.tmax / 1e8;
        forceStabilization = true;
    elseif p.tmax < min_tmax % did not run yet up to minimum time
        % if the simulation time was not enough, force next step
        p.tmax = min(p.tmax * 5, 1e4);
        p.t0 = p.tmax / 1e8;
        forceStabilization = true;
    else % normal run
        % each round, increase the simulation time by 5 times
        % (increasing it more quickly can cause some simulation to fail)
        p.tmax = min(p.tmax * 5, 1e4);
        p.t0 = p.tmax / 1e8;
        forceStabilization = false;
    end

end

% restore original Ana value
steadystate_struct.p.Ana = struct.p.Ana;

% re-enable the warnings
warning('on', 'pindrift:verifyStabilization');

%------------- END OF CODE --------------
