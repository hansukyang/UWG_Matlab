% =========================================================================
% THE URBAN WEATHER GENERATOR
% Author: B. Bueno
% latest modification 2015 - Joseph Yang (joeyang@mit.edu)
% =========================================================================
clear;

% Initialize parameters
UWGParameter;

% HVAC autosize (if specified)
Fc = fopen('data/coolCap.txt','r+');  % Not sure what this does...
for i = 1:numel(urbanArea)
    for j = 1:numel(urbanUsage(i).urbanConf)
        if autosize
            coolCap = Autosize(urbanArea(i),ublVars(i),...
                urbanUsage(i).urbanConf(j),climate_data,rural,refSite);
            fprintf(Fc,'%1.3f\n',coolCap);
            urbanUsage(i).urbanConf(j).building.coolCap = coolCap;
        else
            urbanUsage(i).urbanConf(j).building.coolCap = fscanf(Fc,'%f\n',1);
        end
    end
end
fclose(Fc);

% -------------------------------------------------------------------------         
forc = Forcing(weather.staTemp);
% -------------------------------------------------------------------------         
sensHeat = zeros(numel(urbanArea),1);
disp '==========================='
disp 'Start UWG simulation '
disp '==========================='
timeCount = 0.;
index = 0;
for it=1:simParam.nt
    
    nodenum = 0;
    timeCount=timeCount+simParam.dt;
    simParam = UpdateDate(simParam);
    
    % print file
    if eq(mod(timeCount,simParam.timePrint),0)
        
        for i = 1:numel(urbanArea)

            fprintf(F0,'%6.4f\t',urbanArea(i).canTemp);   % Canyon Temperature
            fprintf(F1,'%6.4f\t',ublVars(i).ublTemp);     % urban boundary layer temperature (K)
            fprintf(F2,'%1.2f\t',urbanArea(i).sensHeat);  % urban sensible heat (W m-2)
            fprintf(F3,'%1.2f\t',urbanArea(i).sensAnthropTot);
            fprintf(F4,'%1.2f\t',ublVars(i).advHeat);
            fprintf(F5,'%1.2f\t',ublVars(i).radHeat);
                                                         
        end
        
        fprintf(F0,'%6.4f\n',forc.temp);
        fprintf(F1,'%6.4f\n',forc.temp);
        fprintf(F2,'%6.4f\n',rural.sens);
        fprintf(F3,'\n');
        fprintf(F4,'\n');
        fprintf(F5,'\n');
    end
        
    % Read forcing from weather file
    if eq(mod(timeCount,simParam.timeForcing),0) || eq(timeCount,simParam.dt)
        if le(forc.itfor,simParam.timeMax/simParam.timeForcing)
            forc = ReadForcing(forc,weather);
            % solar calculations
            [rural,urbanArea,urbanUsage] = SolarCalcs(urbanArea,urbanUsage,...
              simParam,refSite,forc,Param,rural);
            [first,second,third] = PriorityIndex(forc.uDir,ublVars);
        end
    end
    
    % rural heat fluxes
    rural.infra = forc.infra-Param.sigma*rural.layerTemp(1)^4.;
    rural = SurfFlux( rural,forc,Param,simParam,forc.hum,forc.temp,forc.wind,2,0.);
    
    % vertical profiles of meteorological variables at the rural site
    refSite = VerticalDifussionModel(refSite,forc,rural,Param,simParam);
    for i = 1:numel(urbanArea)
        % urban heat fluxes
        [urbanArea(i),ublVars(i),urbanUsage(i),forc] = UrbFlux(urbanArea(i),ublVars(i),...
        urbanUsage(i),forc,Param,simParam,refSite);
        % urban canyon temperature and humidity
        urbanArea(i) = UrbThermal(urbanArea(i),ublVars(i).ublTemp,urbanUsage(i),forc,Param,simParam);
    end
    
    % urban boundary layer temperature
    for i=1:numel(urbanArea)
        sensHeat(i) = urbanArea(i).sensHeat;
    end
    ublVars = UrbanBoundaryLayerModel(ublVars,sensHeat,refSite,rural,forc,...
        Param,simParam,first,second,third);
    
    % print day
    if eq(mod(timeCount,3600.*24),0)
      varname = timeCount/(3600.*24);
      fprintf('DAY %g\n', varname);
    end   
    
    % Output data (for data dump)
    if eq(mod(timeCount,simParam.timePrint),0)
        index = index + 1;
        for i = 1:numel(urbanUsage)
            
            % for each sub-area in the block
            for j = 1:numel(urbanUsage(i).urbanConf)
                CityBlock(i,j) = UpdateStrct(CityBlock(i,j), urbanUsage(i).urbanConf(j),timeCount,index);
                CityBlock(i,j) = UpdateArea(CityBlock(i,j), urbanArea(i),ublVars(i),index);
            end
        end
    end
end

% Print log file
output;

fclose all;
disp '==========================='
disp 'Simulation ended correctly '
disp '==========================='