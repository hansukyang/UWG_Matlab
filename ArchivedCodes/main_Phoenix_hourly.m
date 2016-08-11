% =========================================================================
% THE URBAN WEATHER GENERATOR
% Author: B. Bueno
% latest modification 2015 - Joseph Yang (joeyang@mit.edu)
% =========================================================================
tic;
clear;
road_a = [0.1 0.5];

% -------------------------------------------------------------------------
% Param class 
% -------------------------------------------------------------------------
dayBLHeight  = 700.;  % daytime mixing height
nightBLHeight  = 80.; % Sing: 80, Bub-Cap: 50, nighttime boundary-layer height (m)
refHeight  = 150.;    % Reference height at which the vertical profile 
                      % of potential temperature is vertical
tempHeight = 2.;      % Temperature measuremnt height at the weather station (m)
windHeight = 10.;     % Air velocity measuremnt height at the weather station (m)
circCoeff = 1.2;      % Wind scaling coefficient
dayThreshold = 200;   % heat flux threshold for daytime conditions (W m-2)
nightThreshold = 50;  % heat flux threshold for nighttime conditions (W m-2)
treeFLat = 0.7;       % latent fraction of trees
grassFLat = 0.6;      % latent fraction of grass
vegAlbedo = 0.25;     % albedo of vegetation
vegStart = 1;         % begin month for vegetation participation
vegEnd = 12;          % end month for vegetation participation
nightStart = 17;      % begin hour for night thermal set point schedule
nightEnd = 8;         % end hour for night thermal set point schedule
windMin = 0.1;        % minimum wind speed (m s-1)
windMax = 10.;        % maximum wind speed (m s-1)
wgmax = 0.005;        % maximum film water depth on horizontal surfaces (m)
exCoeff = 0.3;        % exchange velocity coefficient
maxdx = 500;          % maximum discretization length for the UBL model (m)

% -------------------------------------------------------------------------
% Physical parameters
% -------------------------------------------------------------------------
g = 9.81;               % gravity
cp = 1004.;             % heat capacity for air (constant pressure)
vk = 0.40;              % von karman constant
r = 287.;               % gas constant
rv = 461.5;             %
lv = 2.26e6;            % latent heat of evaporation
sigma = 5.67e-08 ;      % Stefan Boltzmann constant
waterDens = 1000;       % water density (kg/m^3)
lvtt = 2.5008e6;        %
tt = 273.16;            %
estt = 611.14;          %
cl = 4.218e3;           %
cpv = 1846.1;           %
b = 9.4;                % Coefficients derived by Louis (1979)
cm = 7.4;               %
colburn = (0.713/0.621)^(2./3.); % (Pr/Sc)^(2/3) for Colburn analogy in water evaporation

% Create geographical parameter class
geoParam = Param(dayBLHeight,nightBLHeight,refHeight,tempHeight,windHeight,...
    circCoeff,dayThreshold,nightThreshold,treeFLat,grassFLat,vegAlbedo,...
    vegStart,vegEnd,nightStart,nightEnd,windMin,windMax,wgmax,exCoeff,maxdx,...
    g, cp, vk, r, rv, lv, pi(), sigma, waterDens, lvtt, tt, estt, cl, cpv, b, cm, colburn);

mean_canT = zeros(24,2);
mean_roadT = zeros(24,2);
mean_walloutT = zeros(24,2);
mean_wallinT = zeros(24,2);
mean_indoorT = zeros(24,2);
mean_thermalLoad = zeros(24,2);
mean_transmittedSW = zeros(24,2);
mean_roadR = zeros(24,2);
mean_roofR = zeros(24,2);
mean_wallR = zeros(24,2);
for ii = 1:2
    % -------------------------------------------------------------------------
    % Element/Material Definitions 
    % -------------------------------------------------------------------------
    Def_Materials             % A script with material & element definitions

    % -------------------------------------------------------------------------
    % Simulation Parameters
    % -------------------------------------------------------------------------
    cityName = 'Phoenix';   % For plot/printing
    LAT = 33.45;
    LON = 111.983;
    ELEV = 0.1;
    dtSim = 300;              % Sim time step
    dtWeather = 3600;         % Weather data time-step
    monthName = 'Jan';       % For plot/printing
    MONTH = 7;                % Begin month
    DAY = 1;                 % Begin day of the month
    NUM_DAYS = 61;             % Number of days of simulation
    autosize = 0;             % Autosize HVAC 
    XLSOut = strcat(cityName,'-UWG.xlsx');   % Excel output file
    CityBlock (1,1) = Block(NUM_DAYS * 24,wall,roof,mass,road);

    % Create simulation class (SimParam.m)
    simParam = SimParam(dtSim,dtWeather,MONTH,DAY,NUM_DAYS);

    % Read Rural weather data (EPW file - http://apps1.eere.energy.gov/)
    climate_data = char('data/Phoenix_TMY2.epw');
    weather = Weather(climate_data,simParam.timeInitial,simParam.timeFinal);

    % % Output files
    % F0 = fopen('outputs/phx_tempCan.txt','w');
    % F1 = fopen('outputs/phx_tempUbl.txt','w');
    % F2 = fopen('outputs/phx_segrnsHeat.txt','w');
    % F3 = fopen('outputs/phx_anthHeat.txt','w');
    % F4 = fopen('outputs/phx_advHeat.txt','w');
    % F5 = fopen('outputs/phx_radHeat.txt','w');

    % -------------------------------------------------------------------------
    % Urban Area Definitions 
    % -------------------------------------------------------------------------

    % Urban Configuration [building,mass,wall,rooof,road]
    urbanUsage = BEMDef(commercial,mass,wall,roof,road,1.0);

    % Define Reference (ReferenceSite(lat,lon,height,initialTemp,initialPres,Param))
    refSite = RSMDef(LAT,LON,ELEV,weather.staTemp(1),weather.staPres(1),geoParam);

    urbanArea = UCMDef(18.3,...  % average building height (m)
        0.3519,...                  % horizontal building density
        1.2065,...                  % vertical-to-horizontal urban area ratio
        0.0,...                     % tree coverage
        0.0,...                     % sensible anthropogenic heat other than buildings (W m-2)
        0.0,...                     % latent anthropogenic heat other than buildings (W m-2)
        weather.staTemp(1),weather.staHum(1),weather.staUmod(1),geoParam,...
        commercial.glazingRatio,commercial.shgc,urbanUsage.wall.albedo,road,rural); 
    ublVars = UBLDef('C',...        % location within the city (N,NE,E,SE,S,SW,W,NW,C) minimum one 'C-Center'
        179.95,...                  % Characteristic length (m)
        weather.staTemp(1),geoParam.maxdx);

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

    %     % print file
    %     if eq(mod(timeCount,simParam.timePrint),0)
    %         
    %         for i = 1:numel(urbanArea)
    % 
    %             fprintf(F0,'%6.4f\t',urbanArea(i).canTemp);   % Canyon Temperature
    %             fprintf(F1,'%6.4f\t',ublVars(i).ublTemp);     % urban boundary layer temperature (K)
    %             fprintf(F2,'%1.2f\t',urbanArea(i).sensHeat);  % urban sensible heat (W m-2)
    %             fprintf(F3,'%1.2f\t',urbanArea(i).sensAnthropTot);
    %             fprintf(F4,'%1.2f\t',ublVars(i).advHeat);
    %             fprintf(F5,'%1.2f\t',ublVars(i).radHeat);
    %                                                          
    %         end
    %         
    %         fprintf(F0,'%6.4f\n',forc.temp);
    %         fprintf(F1,'%6.4f\n',forc.temp);
    %         fprintf(F2,'%6.4f\n',rural.sens);
    %         fprintf(F3,'\n');
    %         fprintf(F4,'\n');
    %         fprintf(F5,'\n');
    %     end

        % Read forcing from weather file
        if eq(mod(timeCount,simParam.timeForcing),0) || eq(timeCount,simParam.dt)
            if le(forc.itfor,simParam.timeMax/simParam.timeForcing)
                forc = ReadForcing(forc,weather,geoParam);
                % solar calculations
                [rural,urbanArea,urbanUsage] = SolarCalcs(urbanArea,urbanUsage,...
                  simParam,refSite,forc,geoParam,rural);
    %            [first,second,third] = PriorityIndex(forc.uDir,ublVars);
            end
        end

        % rural heat fluxes
        rural.infra = forc.infra-geoParam.sigma*rural.layerTemp(1)^4.;
        rural = SurfFlux( rural,forc,geoParam,simParam,forc.hum,forc.temp,...
            forc.wind,2,0.);

        % vertical profiles of meteorological variables at the rural site
        refSite = VDM(refSite,forc,rural,geoParam,simParam);
        for i = 1:numel(urbanArea)
            % urban heat fluxes
            [urbanArea(i),ublVars(i),urbanUsage(i),forc] = UrbFlux(urbanArea(i),ublVars(i),...
            urbanUsage(i),forc,geoParam,simParam,refSite);
            % urban canyon temperature and humidity
            urbanArea(i) = UCModel(urbanArea(i),ublVars(i).ublTemp,urbanUsage(i),forc,geoParam,simParam);
        end

        % urban boundary layer temperature
        for i=1:numel(urbanArea)
            sensHeat(i) = urbanArea(i).sensHeat;
        end
        ublVars = UBLModel(ublVars,sensHeat,refSite,rural,forc,...
            geoParam,simParam);

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
                for j = 1:numel(urbanUsage(i))
                    CityBlock(i,j) = UpdateStrct(CityBlock(i,j), urbanUsage(i),timeCount,index);
                    CityBlock(i,j) = UpdateArea(CityBlock(i,j), urbanArea(i),ublVars(i),index);
                end
            end
        end
    end

    for i = 1:numel(urbanUsage)
        for j = 1:numel(urbanUsage(i))
            canTemp = reshape(CityBlock(i,j).canTemp-273,[24,NUM_DAYS]);
            roadT = reshape(CityBlock(i,j).RoadT(:,1)-273.15,[24,NUM_DAYS]);
            wall_outT = reshape(CityBlock(i,j).WallT(:,1)-273.15,[24,NUM_DAYS]);
            wall_inT = reshape(CityBlock(i,j).WallT(:,3)-273.15,[24,NUM_DAYS]);
            indoorT = reshape(CityBlock(i,j).indoorTemp-273.15,[24,NUM_DAYS]);
            thermalLoad = reshape (CityBlock(i,j).coolConsump+CityBlock(i,j).heatConsump,[24,NUM_DAYS]);
            %coolLoad = reshape (CityBlock(i,j).coolConsump,[NUM_DAYS,24]);
            %heatLoad = reshape (CityBlock(i,j).heatConsump,[NUM_DAYS,24]);
            transmittedSW = reshape (CityBlock(i,j).WallS*0.14,[24,NUM_DAYS]);
            roadR = reshape (CityBlock(i,j).RoadR,[24,NUM_DAYS]);
            roofR = reshape (CityBlock(i,j).RoofR,[24,NUM_DAYS]);
            wallR = reshape (CityBlock(i,j).WallR,[24,NUM_DAYS]);

            jcanTemp = canTemp(:,31:61);
            jroadT = roadT(:,31:61);
            jwall_outT = wall_outT(:,31:61);
            jwall_inT = wall_inT(:,31:61);
            jindoorT = indoorT(:,31:61);
            jthermalLoad = thermalLoad(:,31:61);
            jtransmittedSW = transmittedSW(:,31:61);
            jroadR = roadR(:,31:61);
            jroofR = roofR(:,31:61);
            jwallR = wallR(:,31:61);

            mean_canT(:,ii) = mean(jcanTemp,2);
            mean_roadT(:,ii)= mean(jroadT,2);
            mean_walloutT(:,ii) = mean(jwall_outT,2);
            mean_wallinT(:,ii) = mean(jwall_inT,2);
            mean_indoorT(:,ii) = mean(jindoorT,2);
            mean_thermalLoad(:,ii)= -mean(jthermalLoad,2);
            mean_transmittedSW(:,ii)= mean(jtransmittedSW,2);
            mean_roadR(:,ii)= mean(jroadR,2);
            mean_roofR(:,ii)= mean(jroofR,2);
            mean_wallR(:,ii)= mean(jwallR,2);
        end
    end
end

%%%%%% Direct solar radiation %%%%%%%
DirectR = reshape(weather.staDir,[24,NUM_DAYS]);
jDirectR = DirectR(:,31:61);
mean_DirectR = mean(jDirectR,2);
figure;
x = 1:24;
plot(x,mean_DirectR,'-ko');
xlim([1 24]);
ax = gca;
ax.XTick = [0 6 12 18 24];
xlabel('Hour');
ylabel('Direct Solar Radiation (W/m2)');


%%%%%%%%%%%

figure;
x = 1:24;
plot(x,mean_canT(:,1),'-ko',x,mean_canT(:,2),'-go');
xlim([1 24]);
ylim([30 44]);
ax = gca;
ax.XTick = [0 6 12 18 24];
xlabel('Hour');
ylabel('Canyon Temp (Deg C)');

figure;
x = 1:24;
plot(x,mean_roadT(:,1),'-ko',x,mean_roadT(:,2),'-go');
xlim([1 24]);
ylim([30 72]);
ax = gca;
ax.XTick = [0 6 12 18 24];
xlabel('Hour');
ylabel('Ground Temp (Deg C)');

figure;
x = 1:24;
plot(x,mean_walloutT(:,1),'-ko',x,mean_walloutT(:,2),'-go');
xlim([1 24]);
ylim([28 54]);
ax = gca;
ax.XTick = [0 6 12 18 24];
xlabel('Hour');
ylabel('Outside Wall Temp (Deg C)');

figure;
x = 1:24;
plot(x,mean_wallinT(:,1),'-ko',x,mean_wallinT(:,2),'-go');
xlim([1 24]);
ylim([25 33]);
ax = gca;
ax.XTick = [0 6 12 18 24];
xlabel('Hour');
ylabel('Inside Wall Temp (Deg C)');

figure;
x = 1:24;
plot(x,mean_indoorT(:,1),'-k+',x,mean_indoorT(:,2),'-go');
xlim([1 24]);
ax = gca;
ax.XTick = [0 6 12 18 24];
xlabel('Hour');
ylabel('Indoor Temp (Deg C)');

figure;
x = 1:24;
plot(x,mean_transmittedSW(:,1),'-ko',x,mean_transmittedSW(:,2),'-go');
xlim([1 24]);
ylim([0 18]);
ax = gca;
ax.XTick = [0 6 12 18 24];
xlabel('Hour');
ylabel('Transmitted Shortwave Radiation (W/m2)');

figure;
x = 1:24;
plot(x,mean_thermalLoad(:,1),'-k+',x,mean_thermalLoad(:,2),'-go');
xlim([1 24]);
ylim([-80 -2]);
ax = gca;
ax.XTick = [0 6 12 18 24];
xlabel('Hour');
ylabel('Thermal load (W/m2)');

figure;
x = 1:24;
plot(x,mean_roadR(:,1),'-ko',x,mean_roadR(:,2),'-go');
xlim([1 24]);
ax = gca;
ax.XTick = [0 6 12 18 24];
xlabel('Hour');
ylabel('Radiation received by road (W/m2)');

figure;
x = 1:24;
plot(x,mean_roofR(:,1),'-ko',x,mean_roofR(:,2),'-go');
xlim([1 24]);
ax = gca;
ax.XTick = [0 6 12 18 24];
xlabel('Hour');
ylabel('Radiation received by roof (W/m2)');

figure;
x = 1:24;
plot(x,mean_wallR(:,1),'-ko',x,mean_wallR(:,2),'-go');
xlim([1 24]);
ax = gca;
ax.XTick = [0 6 12 18 24];
xlabel('Hour');
ylabel('Radiation received by wall (W/m2)');

% StaT = reshape (weather.staTemp-273.15,[24,NUM_DAYS]);
% StaT = mean(StaT,2);
% figure;
% x = 1:24;
% plot(x,StaT,'-k+');
% xlim([1 24]);
% ax = gca;
% ax.XTick = [0 6 12 18 24];
% xlabel('Hour');
% ylabel('Rural Temp (Deg C)');

fclose(F0);
fclose(F1);
fclose(F2);
fclose(F3);
fclose(F4);
fclose(F5);
ElapsedTime = toc

disp '==========================='
disp 'Simulation ended correctly '
disp '==========================='



