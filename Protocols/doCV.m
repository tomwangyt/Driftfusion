function sol_CV = doCV(sol_ini, light_intensity, V0, Vmax, Vmin, scan_rate, cycles, tpoints)
% Performs a cyclic voltammogram (CV) simulation
% Input arguments:
% SOL_INI = solution containing intitial conditions
% LIGHT_INTENSITY = Light intensity for bias light (Suns)
% V0 = Starting voltage (V)
% VMAX = Maximum voltage point (V)
% VMIN = Minimum voltage point (V)
% SCAN_RATE = Scan rate (Vs-1)
% CYCLES = No. of scan cycles
% TPOINTS = No. of points in output time array
% P. Calado, 2020, Imperial College London
disp('Starting DOCV')

par = sol_ini.par;

%% Set light intensity
if light_intensity > 0
    sol = lightonRs(sol_ini, light_intensity, -1, 0, 0, 10);
else
    sol = sol_ini;
end

%% Switch to V0 if different from initial conditions
% Trying to do this within the triangular wave function resulted in
% convergence issues so safer to do this here.
if V0 ~= par.Vapp
    sol = genVappStructs(sol, V0, 0);
end

%% Calculate tmax from scan rate and absolute change in voltage, deltaV
deltaV = abs(Vmax-Vmin)+abs(Vmin-Vmax)+abs(V0-Vmin);
tmax = deltaV/scan_rate;

disp('Performing cyclic voltamagram')
sol_CV = VappFunction(sol, 'tri', [V0, Vmax, Vmin, cycles, tmax/cycles], tmax, tpoints, 0);
disp('Complete')

disp('DOCV complete')
end