% -------------------------------------------------------------------------
% Element/Material Definitions 
% -------------------------------------------------------------------------

% Define Materials 
% % [conductivity (W m-1 K-1), Vol heat capacity (J m-3 K-1)]
% bldMat = Material(0.67,1.2e6);      % material (concrete? reference?)
% roadMat = Material(1.0,1.6e6);      % material (asphalt? reference?)
% 
% % Define & build base elements 
% % [albedo, emissivity, thicknesses (m)(outer layer first),
% %  materials, vegetation coverage, initial temperature (K),
% %  inclination (horizontal - 1, vertical - 0) ]
% wall = Element(0.2,0.9,[0.01;0.05;0.1;0.05;0.01],...
%     [bldMat;bldMat;bldMat;bldMat;bldMat],0.,300.,0);
% roof = Element(0.2,0.9,[0.01;0.05;0.1;0.05;0.01],...
%     [bldMat;bldMat;bldMat;bldMat;bldMat],0.,300.,1);
% road = Element(0.5,0.95,[0.05;0.1;0.1;0.5;0.5],...
%     [roadMat;roadMat;roadMat;roadMat;roadMat],0.2,300.,1);
% rural = Element(0.1,0.95,[0.05;0.1;0.1;0.5;0.5],...
%     [roadMat;roadMat;roadMat;roadMat;roadMat],0.73,300.,1);
% mass = Element(0.7,0.9,[0.05;0.05],[bldMat;bldMat],0.,300.,0);

% Materials
	% thermal conductivity (W m-1 K-1)
	% volumetric heat capacity (J m-3 K-1)
brick = Material(1.3,1.58e6);
concrete = Material(1.51,1.50e6);
insulation = Material(0.038,5.2e4);
wood = Material(0.93,1.2e6);
asphalt = Material(0.75,1.94e6);
stones = Material(0.95,2.0e6);
soil = Material(0.4,1.4e6);
drywall = Material(0.17,1.4e6);
plywood = Material(0.12,1.4e6);
plenum = Material(0.025,1.4e6);
% Massive elements
	% albedo
	% emissivity
	% thicknesses (m)(outer layer first)
	% materials
	% vegetation coverage
	% initial temperature (K)
	% inclination (horizontal - 1, vertical - 0)
wall = Element(0.25,0.9,[0.1;0.089;0.013],...
    [brick;insulation;drywall],0.,293.,0);
roof = Element(0.25,0.9,[0.019;0.1;0.2;0.013],...
    [plywood;plenum;insulation;drywall],0.,293.,1);
% if road_a(ii)<0.2
% road = Element(road_a(ii),0.95,[0.2;0.2],...
%     [asphalt;stones],0.0,293.,1);
% else 
%     road = Element(road_a(ii),0.95,[0.2;0.2],...
%     [concrete;stones],0.0,293.,1);
% end
road = Element(road_a(ii),0.95,[0.05;0.05;0.05;0.05;0.05;0.05;0.05;0.05;0.05;0.05],...
    [asphalt;asphalt;asphalt;asphalt;stones;stones;stones;stones;soil;soil],0.0,293.,1);
% road = Element(0.1,0.95,[0.2;0.2],...
%    [asphalt;stones],0.0,293.,1);
rural = Element(0.15,0.96,[0.05;0.1;0.1;0.5;0.5],...
    [stones;stones;soil;soil;soil],0.8,293.,1);
mass = Element(0.7,0.9,[0.05;0.05],[concrete;concrete],0.,293.,0);

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
commercial = Building(4.6,... % floorHeight
    0.0,...              % nighttime internal heat gains (W m-2 floor)
    25.0,...              % daytime internal heat gains (W m-2 floor)
    0.5,...               % radiant fraction of internal gains
    0.1,...               % latent fraction of internal gains
    0.1,...               % Infiltration (ACH)
    0.4,...               % Ventilation (ACH)
    0.3,...               % glazing ratio
    2.715,...             % window U-value (W m-2 K)
    0.75,...              % window solar heat gain coefficient
    'AIR',...             % cooling condensation system type {'AIR','WATER'}
    2.5,...               % COP of the cooling system
    0.0,...               % fraction of waste heat released into the canyon
    297.,...              % daytime indoor cooling set-point (K)
    300.,...              % nighttime indoor cooling set-point (K)
    295.,...              % daytime indoor heating set-point (K)
    293.,...              % nighttime indoor heating set-point (K)
    335.,...              % rated cooling system capacity (W m-2 bld)
    0.9,...               % heating system efficiency (-)
    293.);                % intial indoor temp (K)