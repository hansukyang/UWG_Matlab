classdef Param
    %PARAMETERS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Constant)
        % system parameters
        dayBLHeight  = 700.; % daytime mixing height
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
        nightSetStart = 17;   % begin hour for night thermal set point schedule
        nightSetEnd = 8;      % end hour for night thermal set point schedule
        windMin = 0.1;        % minimum wind speed (m s-1)
        windMax = 10.;        % maximum wind speed (m s-1)
        wgmax = 0.005;        % maximum film water depth on horizontal surfaces (m)
        exCoeff = 0.3;        % exchange velocity coefficient
        maxdx = 500;          % maximum discretization length for the UBL model (m)
        % physical parameters
        g = 9.81;             % gravity
        cp = 1004.;           % heat capacity for air (constant pressure)
        vk = 0.40;            % von karman constant
        r = 287.;             % gas constant
        rv = 461.5;
        lv = 2.26e6;          % latent heat of evaporation
        pi = 3.141592653;     % pi
        sigma = 5.67e-08 ;    % Stefan Boltzmann constant
        waterDens = 1000;     % water density
        lvtt = 2.5008e6;
        tt = 273.16;
        estt = 611.14;
        cl = 4.218e3;
        cpv = 1846.1;
        b   = 9.4;           % Coefficients derived by Louis (1979)
        cm  = 7.4; 
        colburn = (0.713/0.621)^(2./3.); % (Pr/Sc)^(2/3) for Colburn analogy in water evaporation
    end
    
    methods
    end
    
end

