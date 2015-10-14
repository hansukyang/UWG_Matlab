function autosizeCoolCap = Autosize(urbanArea,ublVars,urbanConf,climate_data,rural,refSite,parameter)

% ------------------------------------------------------------------------- 
autosizeFactor = 1.2;
autosizeCoolCap = 0.;
% -------------------------------------------------------------------------
% Simulation paramters
simParamAs = SimParam(...
    300.,...            % Simulation time-step
    3600.,...           % Weather data time-step
    7,...               % Begin month
    15,...              % Begin day of the month
    5);                 % Number of days of simulation
weatherAs = Weather(climate_data,...
    simParamAs.timeInitial,simParamAs.timeFinal);
forc = Forcing(weatherAs.staTemp);
% =========================================================================
disp '==========================='
fprintf('Autosize simulation: Urban Area %s\n', ...
    ublVars.location);
fprintf('Period: month %i from day %i to day %i\n', ...
    int16(simParamAs.month),int16(simParamAs.day),int16(simParamAs.day+simParamAs.days));
fprintf('Autosize factor: %1.1f\n', autosizeFactor);
fprintf('Internal Heat Night %1.2f W m-2(fl), Internal Heat Day %1.2f W m-2(fl)\n',...
    urbanConf.building.intHeatNight,urbanConf.building.intHeatDay);
fprintf('Cooling Setpoint Day %1.2f K, Cooling Setpoint Night %1.2f K\n',...
    urbanConf.building.coolSetpointDay,urbanConf.building.coolSetpointNight);
% =========================================================================
timeCount = 0.;
for it=1:simParamAs.nt
    timeCount=timeCount+simParamAs.dt;
    simParamAs = UpdateDate(simParamAs);
    % read forcing
    if eq(mod(timeCount,simParamAs.timeForcing),0) || eq(timeCount,simParamAs.dt)
        if le(forc.itfor,simParamAs.timeMax/simParamAs.timeForcing)
            forc = ReadForcing(forc,weatherAs,parameter);
            % solar calculations
            urbanConf = SolarCalcsAutosize(urbanArea,urbanConf,...
              simParamAs,refSite,forc,rural);
        end
    end
    % urban heat fluxes
    [urbanArea,ublVars,urbanConf,forc,parameter] = UrbFluxAutosize(urbanArea,ublVars,urbanConf,forc,parameter,simParamAs);
    % urban boundary layer temperature
    ublVars.ublTemp = forc.temp;
    % max sens energy demand
    autosizeCoolCap = max(autosizeCoolCap,autosizeFactor*urbanConf.building.sensCoolDemand);
end
fprintf('> Cooling capacity: %1.2f W m-2(bld)\n',autosizeCoolCap);
disp '==========================='
end

