tic;

% Param class definition is changed (so that the values can be seen from
% the main files
% system parameters
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
% Physical parameters
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
    
geoParam = Param(dayBLHeight,nightBLHeight,refHeight,tempHeight,windHeight,...
    circCoeff,dayThreshold,nightThreshold,treeFLat,grassFLat,vegAlbedo,...
    vegStart,vegEnd,nightStart,nightEnd,windMin,windMax,wgmax,exCoeff,maxdx,...
    g, cp, vk, r, rv, lv, pi(), sigma, waterDens, lvtt, tt, estt, cl, cpv, b, cm, colburn);

N=10;
road_a = 0.7*rand(N,1);
% glaz = rand(N,1);
mean_canT = zeros(N,1);
sum_cool = zeros(N,1);
sum_heat = zeros(N,1);
mean_indoorT = zeros(N,1);
mean_roadT = zeros(N,1);
mean_roadQ = zeros(N,1);
mean_roadS = zeros(N,1);
mean_roadR = zeros(N,1);
mean_WallS = zeros(N,1);
mean_WallR = zeros(N,1);
mean_WallT = zeros(N,1);
mean_WallQ = zeros(N,1);
mean_WallF = zeros(N,1);

for ii=1:N
     disp(num2str(ii));
% -------------------------------------------------------------------------
% Element/Material Definitions 
% -------------------------------------------------------------------------
Def_Materials             % A script with material & element definitions

% -------------------------------------------------------------------------
% Building Definitions 
% -------------------------------------------------------------------------
Def_Buildings             % A script with building definitions

% -------------------------------------------------------------------------
% Simulation Parameters
% -------------------------------------------------------------------------
cityName = 'Phoenix';   % For plot/printing
LAT = 33.45;
LON = 112.07;
% LAT = 40.71;
% LON = 74.00;
ELEV = 0.1;
dtSim = 300;              % Sim time step
dtWeather = 3600;         % Weather data time-step
monthName = 'July';       % For plot/printing
MONTH = 7;                % Begin month
DAY = 1;                 % Begin day of the month
NUM_DAYS = 30;             % Number of days of simulation
autosize = 0;             % Autosize HVAC 
XLSOut = strcat(cityName,'-UWG.xlsx');   % Excel output file
CityBlock (1,1) = Block(NUM_DAYS * 24,wall,roof,mass,road);

% Create simulation class (SimParam.m)
simParam = SimParam(dtSim,dtWeather,MONTH,DAY,NUM_DAYS);

% Read Rural weather data (EPW file - http://apps1.eere.energy.gov/)
climate_data = char('data/Phoenix.epw');
weather = Weather(climate_data,simParam.timeInitial,simParam.timeFinal);

% -------------------------------------------------------------------------
% Urban Area Definitions 
% -------------------------------------------------------------------------

% Urban Configuration [building,mass,wall,rooof,road]
confResNoAC = UrbanConf(residential,mass,wall,roof,road);
confResWAC = UrbanConf(res_wAC,mass,wall,roof,road);
confCommer = UrbanConf(commercial,mass,wall,roof,road);
% Urban Usage [Fraction of block types]
%urbanUsage1 = UrbanUsage([0.6,0.4],[confResNoAC,confResWAC]); 
%urbanUsage2 = UrbanUsage([0.8,0.12,0.08],[confCommer,confResNoAC,confResWAC]); 
urbanUsage = UrbanUsage(1.0,confCommer);                    
%urbanUsage4 = UrbanUsage([0.2,0.48,0.32],[confCommer,confResNoAC,confResWAC]); 
%urbanUsage = [urbanUsage1,urbanUsage4,urbanUsage2,urbanUsage2,urbanUsage4,...
   % urbanUsage1,urbanUsage4,urbanUsage1]; %AN- for 8 different neighborhoods

% Define Reference (ReferenceSite(lat,lon,height,initialTemp,initialPres,Param))
refSite = ReferenceSite(LAT,LON,ELEV,weather.staTemp(1),weather.staPres(1),geoParam);

% Define configurations for each neighbour
% UblVars(location,charLength,initialTemp,maxdx)
% UrbanArea(bldHeight,bldDensity,verToHor,treeCoverage,sensAnthrop,latAnthrop,...
%   initialTemp,initialHum,initialWind,Param,building,wall,road,rural)
urbanArea = UrbanArea(18.3,...     % average building height (m)
    0.58,...              % horizontal building density
    0.37,...              % vertical-to-horizontal urban area ratio
    0.08,...              % tree coverage
    8.0,...               % sensible anthropogenic heat other than buildings (W m-2)
    0.0,...               % latent anthropogenic heat other than buildings (W m-2)
    weather.staTemp(1),weather.staHum(1),weather.staUmod(1),Param,...
    commercial,wall,road,rural); 
ublVars = UblVars('C',... % location within the city (N,NE,E,SE,S,SW,W,NW,C) minimum one 'C-Center'
    3000.,...             % Characteristic length (m)
    weather.staTemp(1),geoParam.maxdx);
    
% % HVAC autosize (if specified)
% Fc = fopen('data/coolCap.txt','r+');  % Not sure what this does...
% for i = 1:numel(urbanArea)
%     for j = 1:numel(urbanUsage(i).urbanConf)
%         if autosize
%             coolCap = Autosize(urbanArea(i),ublVars(i),...
%                 urbanUsage(i).urbanConf(j),climate_data,rural,refSite);
%             fprintf(Fc,'%1.3f\n',coolCap);
%             urbanUsage(i).urbanConf(j).building.coolCap = coolCap;
%         else
%             urbanUsage(i).urbanConf(j).building.coolCap = fscanf(Fc,'%f\n',1);
%         end
%     end
% end
% fclose(Fc);

% -------------------------------------------------------------------------         
forc = Forcing(weather.staTemp);
% -------------------------------------------------------------------------         
sensHeat = zeros(numel(urbanArea),1);

timeCount = 0.;
index = 0;
for it=1:simParam.nt
    
    nodenum = 0;
    timeCount=timeCount+simParam.dt;
    simParam = UpdateDate(simParam);
    
    % Set the groud temperature as monthly average
            forc.deepTemp = 307.7; 
            
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
    rural = SurfFlux( rural,forc,Param,simParam,forc.hum,forc.temp,...
        forc.wind,2,0.);
    
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

for i = 1:numel(urbanUsage)
    for j = 1:numel(urbanUsage(i).urbanConf)
        mean_canT(ii) = mean (CityBlock(i,j).canTemp-273.15);
        sum_cool(ii) = sum (CityBlock(i,j).coolConsump)/1000;
        sum_heat(ii) = sum (CityBlock(i,j).heatConsump)/1000;
        mean_indoorT(ii) = mean (CityBlock(i,j).indoorTemp-273.15);
        mean_roadT(ii) = mean (CityBlock(i,j).RoadT(:,1)-273.15);
        mean_roadQ(ii) = mean (CityBlock(i,j).RoadQ);
        mean_roadS(ii) = mean (CityBlock(i,j).RoadS);
        mean_roadR(ii) = mean (CityBlock(i,j).RoadR);
        mean_WallS(ii) = mean (CityBlock(i,j).WallS);
        mean_WallR(ii) = mean (CityBlock(i,j).WallR);
        mean_WallT(ii) = mean (CityBlock(i,j).WallT(:,1)-273.15);
        mean_WallQ(ii) = mean (CityBlock(i,j).WallQ);
        mean_WallF(ii) = mean (CityBlock(i,j).WallF);
    end
end
end
ElapsedTime = toc;

disp '==========================='
disp 'Simulation ended correctly '
disp '==========================='

figure;
scatter(road_a,mean_canT);
grid;
xlabel('Road Albedo');
ylabel('Canyon Temperature (Deg C)');
figure;
scatter(road_a,sum_cool);
grid;
xlabel('Road Albedo');
ylabel('Cooling consumption (W/m2)');
figure;
scatter(road_a,sum_heat);
grid;
xlabel('Road Albedo');
ylabel('Heating consumption (W/m2)');
figure;
scatter(road_a,mean_indoorT);
grid;
xlabel('Road Albedo');
ylabel('Indoor Temp (Deg C)');
figure;
scatter(road_a,mean_roadT);
grid;
xlabel('Road Albedo');
ylabel('Road Temp (Deg C)');
figure;
scatter(road_a,mean_WallS);
grid;
xlabel('Road Albedo');
ylabel('Solar radiation absorbed by wall(W/m2)');
figure;
scatter(road_a,mean_WallR);
grid;
xlabel('Road Albedo');
ylabel('Solar radiation Received by wall(W/m2)');

figure;
scatter(road_a,mean_roadQ);
grid;
xlabel('Road Albedo');
ylabel('Sensible heat from road(W/m2)');
figure;
scatter(road_a,mean_WallQ);
grid;
xlabel('Road Albedo');
ylabel('Heat flux from indoor to wall surface(W/m2)');
figure;
scatter(road_a,mean_WallF);
grid;
xlabel('Road Albedo');
ylabel('Heat flux from wall surface(W/m2)');
figure;
scatter(road_a,mean_WallT);
grid;
xlabel('Road Albedo');
ylabel('Wall Temp (Deg C)');

figure;
scatter(road_a,mean_roadS);
grid;
xlabel('Road Albedo');
ylabel('Solar radiation absorbed by road(W/m2)');
figure;
scatter(road_a,mean_roadR);
grid;
xlabel('Road Albedo');
ylabel('Solar radiation Received by road(W/m2)');
