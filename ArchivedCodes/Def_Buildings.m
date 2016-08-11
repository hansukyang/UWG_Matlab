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
    0.0,...              % nighttime internal heat gains (W m-2 floor)
    25.0,...              % daytime internal heat gains (W m-2 floor)
    0.5,...               % radiant fraction of internal gains
    0.1,...               % latent fraction of internal gains
    0.1,...               % Infiltration (ACH)
    0.4,...               % Ventilation (ACH)
    0.5,...               % glazing ratio
    2.715,...             % window U-value (W m-2 K)
    0.75,...              % window solar heat gain coefficient
    'AIR',...             % cooling condensation system type {'AIR','WATER'}
    2.5,...               % COP of the cooling system
    0.0,...               % fraction of waste heat released into the canyon
    297.,...              % daytime indoor cooling set-point (K)
    300.,...              % nighttime indoor cooling set-point (K)
    295.,...              % daytime indoor heating set-point (K)
    288.,...              % nighttime indoor heating set-point (K)
    335.,...              % rated cooling system capacity (W m-2 bld)
    0.9,...               % heating system efficiency (-)
    293.);                % intial indoor temp (K)