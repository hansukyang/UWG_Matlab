% -------------------------------------------------------------------------
% Element/Material Definitions 
% -------------------------------------------------------------------------

% [conductivity (W m-1 K-1), Vol heat capacity (J m-3 K-1)]
bldMat = Material(0.67,1.2e6);      % material (concrete? reference?)
roadMat = Material(1.0,1.6e6);      % material (asphalt? reference?)

% Define & build base elements
% [albedo, emissivity, thicknesses (m)(outer layer first),
%  materials, vegetation coverage, initial temperature (K),
%  inclination (horizontal - 1, vertical - 0) ]
wall = Element(0.2,0.9,[0.01;0.05;0.1;0.05;0.01],...
    [bldMat;bldMat;bldMat;bldMat;bldMat],0.,300.,0);
roof = Element(0.2,0.9,[0.01;0.05;0.1;0.05;0.01],...
    [bldMat;bldMat;bldMat;bldMat;bldMat],0.,300.,1);
road = Element(0.5,0.95,[0.05;0.1;0.1;0.5;0.5],...
    [roadMat;roadMat;roadMat;roadMat;roadMat],0.2,300.,1);
rural = Element(0.1,0.95,[0.05;0.1;0.1;0.5;0.5],...
    [roadMat;roadMat;roadMat;roadMat;roadMat],0.73,300.,1);
mass = Element(0.7,0.9,[0.05;0.05],[bldMat;bldMat],0.,300.,0);


% -------------------------------------------------------------------------
% Simulation Parameters
% -------------------------------------------------------------------------
cityName = 'Singapore';   % For plot/printing
LAT = 1.37;
LON = 103.98;
ELEV = 0.1;
dtSim = 300;              % Sim time step
dtWeather = 3600;         % Weather data time-step
monthName = 'July';       % For plot/printing
MONTH = 7;                % Begin month
DAY = 30;                 % Begin day of the month
NUM_DAYS = 7;             % Number of days of simulation
autosize = 0;             % Autosize HVAC 
XLSOut = strcat(cityName,'-UWG.xlsx');   % Excel output file
CityBlock (8,3) = Block(NUM_DAYS * 24,wall,roof,mass,road);

% Create simulation class (SimParam.m)
simParam = SimParam(dtSim,dtWeather,MONTH,DAY,NUM_DAYS);

% Read Rural weather data (EPW file - http://apps1.eere.energy.gov/)
climate_data = char('data/rural_weather_data_changi.epw');
weather = Weather(climate_data,simParam.timeInitial,simParam.timeFinal);

% Output files
F0 = fopen('outputs/sin_chg_jul_tempCan.txt','w');
F1 = fopen('outputs/sin_chg_jul_tempUbl.txt','w');
F2 = fopen('outputs/sin_chg_jul_sensHeat.txt','w');
F3 = fopen('outputs/sin_chg_jul_anthHeat.txt','w');
F4 = fopen('outputs/sin_chg_jul_advHeat.txt','w');
F5 = fopen('outputs/sin_chg_jul_radHeat.txt','w');

% Building definitions
% Residential building with AC
res_wAC = Building(3.0,... % floorHeight
    4.0,...               % nighttime internal heat gains (W m-2 floor)
    4.0,...               % daytime internal heat gains (W m-2 floor)
    0.2,...               % radiant fraction of internal gains
    0.2,...               % latent fraction of internal gains
    0.5,...               % Infiltration (ACH)
    0.0,...               % Ventilation (ACH)
    0.3,...               % glazing ratio
    2.715,...             % window U-value (W m-2 K)
    0.75,...              % window solar heat gain coefficient
    'AIR',...             % cooling condensation system type {'AIR','WATER'}
    2.5,...               % COP of the cooling system
    1.0,...               % fraction of waste heat released into the canyon
    297.,...              % daytime indoor cooling set-point (K)
    297.,...              % nighttime indoor cooling set-point (K)
    293.,...              % daytime indoor heating set-point (K)
    293.,...              % nighttime indoor heating set-point (K)
    225.,...              % rated cooling system capacity (W m-2 bld)
    0.9,...               % heating system efficiency (-)
    300.);                % intial indoor temp (K)

% Residential building without AC
residential = Building(3.0,... % floorHeight
    4.0,...               % nighttime internal heat gains (W m-2 floor)
    4.0,...               % daytime internal heat gains (W m-2 floor)
    0.2,...               % radiant fraction of internal gains
    0.2,...               % latent fraction of internal gains
    0.5,...               % Infiltration (ACH)
    0.0,...               % Ventilation (ACH)
    0.3,...               % glazing ratio
    2.715,...             % window U-value (W m-2 K)
    0.75,...              % window solar heat gain coefficient
    'AIR',...             % cooling condensation system type {'AIR','WATER'}
    2.5,...               % COP of the cooling system
    0.0,...               % fraction of waste heat released into the canyon***
    325.,...              % daytime indoor cooling set-point (K)
    325.,...              % nighttime indoor cooling set-point (K)***
    293.,...              % daytime indoor heating set-point (K)
    293.,...              % nighttime indoor heating set-point (K)
    225.,...              % rated cooling system capacity (W m-2 bld)
    0.9,...               % heating system efficiency (-)
    300.);                % intial indoor temp (K)

% Commercial building
commercial = Building(3.0,... % floorHeight
    10.0,...              % nighttime internal heat gains (W m-2 floor)
    10.0,...              % daytime internal heat gains (W m-2 floor)
    0.5,...               % radiant fraction of internal gains
    0.1,...               % latent fraction of internal gains
    0.1,...               % Infiltration (ACH)
    1.0,...               % Ventilation (ACH)
    0.5,...               % glazing ratio
    2.715,...             % window U-value (W m-2 K)
    0.75,...              % window solar heat gain coefficient
    'AIR',...             % cooling condensation system type {'AIR','WATER'}
    2.5,...               % COP of the cooling system
    0.0,...               % fraction of waste heat released into the canyon
    300.,...              % daytime indoor cooling set-point (K)
    303.,...              % nighttime indoor cooling set-point (K)
    293.,...              % daytime indoor heating set-point (K)
    293.,...              % nighttime indoor heating set-point (K)
    335.,...              % rated cooling system capacity (W m-2 bld)
    0.9,...               % heating system efficiency (-)
    300.);                % intial indoor temp (K)

bType = [Building, Building, Building];
bType(1) = res_wAC;
bType(2) = residential;
bType(3) = commercial;

% -------------------------------------------------------------------------
% Urban Area Definitions 
% -------------------------------------------------------------------------

% Urban Configuration [building,mass,wall,rooof,road]
confResNoAC = UrbanConf(residential,mass,wall,roof,road);
confResWAC = UrbanConf(res_wAC,mass,wall,roof,road);
confCommer = UrbanConf(commercial,mass,wall,roof,road);

% Urban Usage [Fraction of block types]
urbanUsage1 = UrbanUsage([0.6,0.4],[confResNoAC,confResWAC]); 
urbanUsage2 = UrbanUsage([0.8,0.12,0.08],[confCommer,confResNoAC,confResWAC]); 
urbanUsage3 = UrbanUsage(1.0,confCommer);                    
urbanUsage4 = UrbanUsage([0.2,0.48,0.32],[confCommer,confResNoAC,confResWAC]); 
urbanUsage = [urbanUsage1,urbanUsage4,urbanUsage2,urbanUsage2,urbanUsage4,...
    urbanUsage1,urbanUsage4,urbanUsage1]; %AN- for 8 different neighborhoods

% Define Reference (ReferenceSite(lat,lon,height,initialTemp,initialPres,Param))
refSite = ReferenceSite(LAT,LON,ELEV,weather.staTemp(1),weather.staPres(1),Param);

% Define configurations for each neighbour
% UblVars(location,charLength,initialTemp,maxdx)
% UrbanArea(bldHeight,bldDensity,verToHor,treeCoverage,sensAnthrop,latAnthrop,...
%   initialTemp,initialHum,initialWind,Param,building,wall,road,rural)

% Punggol
urbanArea1 = UrbanArea(26,0.379,1.55,0.19,4.0,0.0,... 
    weather.staTemp(1),weather.staHum(1),weather.staUmod(1),Param,...
    residential,wall,road,rural); 
ublVars1 = UblVars('N',4000.,weather.staTemp(1),Param.maxdx);

% urbanArea2 (undefined)
urbanArea2 = UrbanArea(26,0.379,1.55,0.19,4.0,0.0,...  
    weather.staTemp(1),weather.staHum(1),weather.staUmod(1),Param,...
    residential,wall,road,rural); 
ublVars2 = UblVars('W',6000.,weather.staTemp(1),Param.maxdx);

% Bideford
urbanArea3 = UrbanArea(26,0.538,1.639,0.191,10.0,0.0,... 
    weather.staTemp(1),weather.staHum(1),weather.staUmod(1),Param,...
    commercial,wall,road,rural);
ublVars3 = UblVars('C',1000.,weather.staTemp(1),Param.maxdx);

% Penang
urbanArea4 = UrbanArea(15.4,0.262,0.58,0.429,10.0,0.0,... 
    weather.staTemp(1),weather.staHum(1),weather.staUmod(1),Param,...
    commercial,wall,road,rural);
ublVars4 = UblVars('S',1000.,weather.staTemp(1),Param.maxdx);

% Kim Cheng
urbanArea5 = UrbanArea(10,0.443,0.828,0.152,4.0,0.0,...   
    weather.staTemp(1),weather.staHum(1),weather.staUmod(1),Param,...
    commercial,wall,road,rural);
ublVars5 = UblVars('SW',1000.,weather.staTemp(1),Param.maxdx);

% Pasir Ris
urbanArea6 = UrbanArea(36,0.258,1.745,0.281,4.0,0.0,...   
    weather.staTemp(1),weather.staHum(1),weather.staUmod(1),Param,...
    residential,wall,road,rural);
ublVars6 = UblVars('NE',3000.,weather.staTemp(1),Param.maxdx);

% Tampines
urbanArea7 = UrbanArea(36,0.291,1.663,0.14,4.0,0.0,...    
    weather.staTemp(1),weather.staHum(1),weather.staUmod(1),Param,...
    residential,wall,road,rural);
ublVars7 = UblVars('E',3000.,weather.staTemp(1),Param.maxdx);

% Limau Grove
urbanArea8 = UrbanArea(9,0.401,0.798,0.122,4.0,0.0,...   
    weather.staTemp(1),weather.staHum(1),weather.staUmod(1),Param,...
    residential,wall,road,rural);
ublVars8 = UblVars('SE',3000.,weather.staTemp(1),Param.maxdx);

% Aggregate of neighbours
urbanArea = [urbanArea1; urbanArea2; urbanArea3; urbanArea4; urbanArea5;...
    urbanArea6; urbanArea7; urbanArea8];
ublVars = [ublVars1; ublVars2; ublVars3; ublVars4; ublVars5;...
    ublVars6; ublVars7; ublVars8];