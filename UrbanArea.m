classdef UrbanArea
    %URBANAREA Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        bldHeight;     % average building height (m)
        bldDensity;    % horizontal building density (footprint)
        verToHor;      % vertical-to-horizontal urban area ratio (facade area/urban area)
        treeCoverage;  % horizontal tree density (footprint)
        sensAnthrop;   % sensible anthropogenic heat (other than from buildings) (W m-2)
        latAnthrop;    % latent anthropogenic heat (other than from buildings) (W m-2)
        sensAnthropTot;% total sensible anthropogenic heat (W m-2)
        latAnthropTot; % total latent anthropogenic heat (W m-2)
        z0u;           % urban roughness length (m)
        disp;          % urban displacement length (m)
        roadShad;      % shadowing of roads
        canWidth;      % canyon width (m)
        bldWidth;      % bld width (m)
        canAspect;     % canyon aspect ratio
        roadConf;      % road-sky configuration factors
        wallConf;      % wall-sky configuration factors
        facArea;       % facade area (m2) 
        roadArea;      % road area (m2)
        roofArea;      % roof area (m2)
        facAbsor;      % average facade absortivity
        roadAbsor;     % average road absortivity
        canTemp;       % canyon air temperature (K)
        canHum;        % canyon specific humidity (kg kg-1)
        canWind;       % urban canyon wind velocity (m s-1)
        turbU;         % canyon turbulent velocities (m s-1)
        turbV;         % canyon turbulent velocities (m s-1)
        turbW;         % canyon turbulent velocities (m s-1)
        ublTemp;       % urban boundary layer temperature (K)
        ublTempdx;     % urban boundary layer temperature discretization (K)
        ublWind;       % urban boundary layer wind velocity (m s-1)
        ustar;         % friction velocity (m s-1)
        ustarMod;      % modified friction velocity (m s-1)
        uExch;         % exchange velocity (m s-1)
        treeLatHeat;   % latent heat from trees (W m-2)
        treeSensHeat;  % sensible heat from trees (W m-2)
        sensHeat;      % urban sensible heat (W m-2)
        latHeat;       % urban latent heat (W m-2)
        canSkyLWCoef;  % canyon-sky radiation heat transfer coefficient (W m-2 K)
        windProf;      % urban wind profile
        canEmis;       % urban canyon emissivity due to water vapor
    end
    
    methods
        function obj = UrbanArea(bldHeight,...
                bldDensity,verToHor,treeCoverage,sensAnthrop,latAnthrop,...
                initialTemp,initialHum,initialWind,parameter,...
                building,wall,road,rural)
            % class constructor
            if(nargin > 0)
                obj.bldHeight = bldHeight;
                obj.bldDensity = bldDensity;
                obj.verToHor = verToHor;
                obj.treeCoverage = treeCoverage;
                obj.sensAnthrop = sensAnthrop;
                obj.latAnthrop = latAnthrop;
                obj.roadShad = min(treeCoverage/(1-bldDensity),1);
                obj.canWidth  = 2*bldHeight*(1-bldDensity)/verToHor;
                obj.bldWidth = 2*bldHeight*bldDensity/verToHor;
                obj.canAspect = bldHeight/obj.canWidth; 
                obj.roadConf = ((obj.canAspect)^2+1)^(1/2)-obj.canAspect;
                obj.wallConf = 0.5*(obj.canAspect+1-...
                    ((obj.canAspect)^2+1)^(1/2))/(obj.canAspect); 
                obj.facArea = 2*bldHeight;
                obj.roadArea = obj.canWidth;
                obj.roofArea = obj.bldWidth;
                obj.canTemp = initialTemp;
                obj.canHum = initialHum;
                obj.ublWind = max(initialWind,parameter.windMin);
                obj.canWind = initialWind;
                obj.ustar = 0.1*initialWind;
                obj.ustarMod = 0.1*initialWind;
                frontDens = verToHor/4.;
                if lt(frontDens,0.15) 
                  obj.z0u = frontDens*obj.bldHeight;
                else
                  obj.z0u = 0.15*obj.bldHeight;
                end
                if lt(frontDens,0.05) 
                  obj.disp = 3*frontDens*obj.bldHeight;
                elseif lt(frontDens,0.15)
                  obj.disp = (0.15+5.5*(frontDens-0.05))*obj.bldHeight;
                elseif lt(frontDens,1)
                  obj.disp = (0.7+0.35*(frontDens-0.15))*obj.bldHeight;
                else 
                  obj.disp = 0.5*obj.bldHeight;
                end
                obj.facAbsor = (1-building.glazingRatio)*(1-wall.albedo)+...
                building.glazingRatio*(1-0.75*building.shgc);
                obj.roadAbsor = (1-road.vegCoverage)*(1-road.albedo)+...
                road.vegCoverage*(1-rural.albedo);
                obj.sensHeat = 0.;
            end
        end  

    end
    
end

