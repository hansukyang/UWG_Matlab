classdef UCBEMDef
    % Definition of Urban Canopy - Building Energy Model Class
    %   Detailed explanation goes here
    
    properties
        % Urban Canyon Parameters
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
        % Urban Canyon Variables
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
        Qsens_wall;     % sensible heat flux from building wall (net)
        Qsens_window;   % sensible heat flux from building window (net)
        Qsens_road;     % sensible heat flux from road (net)
        Qsens_hvac;     % sensible heat flux from HVAC waste (net)
        Qsens_traffic;  % sensible heat flux from traffic (net)
        Qir_ubl;        % LW heat flux from sky (net)
        Qir_wall;       % LW heat flux from wall (net)
        Qir_road;       % LW heat flux from road (net)
        Qconv_ubl;      % Convective heat exchange with UBL layer
        Qconv_vent;     % Convective heat exchange from ventilation
    end
    
    methods
        function obj = UCBEMDef(bldHeight,bldDensity,verToHor,treeCoverage,sensAnthrop,latAnthrop,...
                initialTemp,initialHum,initialWind,parameter,building,wall,road,rural)
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
    
        function obj = UCModel(obj,ublTemp,urbanUsage,forc,parameter,simParam)
            % Calculate the urban canyon temperature per The UWG (2012) Eq. 10 

            buildingTerm = zeros(4,1);
            wallTerm = zeros(2,1);
            roadTerm = zeros(3,1);
            r_air = forc.pres/(1000*0.287042*obj.canTemp*(1.+1.607858*obj.canHum)); % air density
            Cp_air = parameter.cp;
            obj.Qsens_wall = 0;
            obj.Qsens_window = 0;
            obj.Qsens_road = 0;
            obj.Qsens_hvac = 0;
            obj.Qsens_traffic = 0;
            obj.Qconv_vent = 0;
            obj.Qir_ubl = 0;
            obj.Qir_wall = 0;
            obj.Qir_road = 0;
            obj.Qconv_ubl = 0;

            for j = 1:numel(urbanUsage.urbanConf)

                % Re-naming variable for readability
                building = urbanUsage.urbanConf(j).building;
                wall = urbanUsage.urbanConf(j).wall;
                road = urbanUsage.urbanConf(j).road;
                T_indoor = building.indoorTemp;
                T_wall = wall.layerTemp(1);
                T_road = road.layerTemp(1);
                T_canyon = obj.canTemp;
                T_ubl = ublTemp;
                T_sky = forc.skyTemp;
                R_glazing= building.glazingRatio;
                A_facade = obj.facArea;
                A_roof = obj.roofArea;
                A_road = obj.roadArea;
                A_wall = (1-R_glazing)*A_facade;
                A_window = R_glazing*A_facade;
                LW_road = urbanUsage.urbanConf(j).canRoadLWCoef;
                LW_wall = urbanUsage.urbanConf(j).canWallLWCoef;
                LW_sky = obj.canSkyLWCoef;
                wdth_canyon = obj.canWidth;
                wdth_bld = obj.bldWidth;
                hght_bld = obj.bldHeight;
                Rate_vent = building.vent/3600;     % change ACH to per second
                U_window = building.uValue;
                frac_j = urbanUsage.frac(j);
                V_bldg = hght_bld*A_roof;
                Qsens_waste = building.sensWaste*building.fWaste;
                Qlat_waste = building.latWaste*building.fWaste;

                % Window, Vent, Waste Heat to Canyon
                buildingTerm(1) = buildingTerm(1) +...
                    frac_j*(T_indoor*A_window*U_window+...          % Heat through window
                        T_indoor*Rate_vent*V_bldg*r_air*Cp_air+...  % Heat from vented air 
                        Qsens_waste*(wdth_canyon+wdth_bld));        % Waste heat from HVAC

                % Wall (no window) to Canyon
                wallTerm(1) = wallTerm(1) +...                                      
                    frac_j*T_wall*(wall.aeroCond*Cp_air*r_air+LW_wall)*A_wall;      % Heat (Rad & Sens) from wall surface

                % Road to Canyon, including LW
                roadTerm(1) = roadTerm(1) +...                                     
                    frac_j*T_road*(road.aeroCond*Cp_air*r_air+LW_road)*A_road;      % Heat (Rad & Sens) from road surface

                % Window and ventilated air
                buildingTerm(2) = buildingTerm(2) +...
                    frac_j*(A_window*U_window+Rate_vent*V_bldg*r_air*Cp_air);

                % Wall LW term
                wallTerm(2) = wallTerm(2) +...
                    frac_j*(wall.aeroCond*Cp_air*r_air+LW_wall)*A_wall;

                % Road to canyon LW term
                roadTerm(2) = roadTerm(2) +...
                    frac_j*(road.aeroCond*Cp_air*r_air+LW_road)*A_road;

                % Building humidity term
                buildingTerm(3) = buildingTerm(3) +...
                    frac_j*(building.indoorHum*Rate_vent*V_bldg*r_air*parameter.lv +...
                        Qlat_waste*(wdth_canyon+wdth_bld));

                % Latent heat from road
                roadTerm(3) = roadTerm(3)+ frac_j*road.lat*A_road;

                % Building ventilation term
                buildingTerm(4) = buildingTerm(4) +...
                    frac_j*Rate_vent*V_bldg*r_air*parameter.lv;

                % Sensible Heat Exchange
                obj.Qsens_wall = obj.Qsens_wall + frac_j*wall.aeroCond*Cp_air*r_air*A_wall*(T_wall-T_canyon);           % Sensible heat from wall
                obj.Qsens_window = obj.Qsens_window + frac_j*A_window*U_window*(T_indoor-T_canyon);                     % Sensible heat from window
                obj.Qsens_road = obj.Qsens_road + frac_j*road.aeroCond*Cp_air*r_air*A_road*(T_road-T_canyon);           % Sensible heat from road
                obj.Qsens_hvac = obj.Qsens_hvac + frac_j*Qsens_waste*(wdth_canyon+wdth_bld);                            % HVAC waste heat dumped into canyon

                % Longwave Heat Exchange
                obj.Qir_wall = obj.Qir_wall + frac_j*LW_wall*A_wall*(T_wall-T_canyon);     % LW heat from wall
                obj.Qir_road = obj.Qir_road + frac_j*LW_road*A_road*(T_road-T_canyon);     % LW heat from road
                obj.Qir_ubl = obj.Qir_ubl + frac_j*LW_sky*wdth_canyon*(T_sky - T_canyon);   % LW heat from sky

                % Convective (mass flow) heat exchange
                obj.Qconv_vent = obj.Qconv_vent + frac_j*Rate_vent*V_bldg*r_air*Cp_air*(T_indoor-T_canyon);     % Heat/mass exchange from vent
                obj.Qconv_ubl = obj.Qconv_ubl + frac_j*obj.uExch*Cp_air*r_air*A_road*(T_ubl-T_canyon);    % Heat/mass exchange from UBL

            end

            % urban air temperature
            Ccan = Cp_air*r_air*(2*wdth_canyon*hght_bld+wdth_bld*hght_bld)/simParam.dt;  
            obj.canTemp = (obj.canTemp*Ccan +...
                wallTerm(1) + buildingTerm(1) + roadTerm(1)+... 
                T_ubl*obj.uExch*Cp_air*r_air*A_road + ...
                T_sky*LW_sky*wdth_canyon + ...
                obj.sensAnthrop*(wdth_canyon+wdth_bld)+obj.treeSensHeat*A_road)/(Ccan +...
                wallTerm(2) + buildingTerm(2) + roadTerm(2) +...
                obj.uExch*Cp_air*r_air*A_road + LW_sky*wdth_canyon);

            % urban air humidity
            Ccan = parameter.lv*r_air*(2*wdth_canyon*hght_bld+wdth_bld*hght_bld)/simParam.dt;  
            obj.canHum = (obj.canHum*Ccan +...
                buildingTerm(3) + roadTerm(3) +...
                forc.hum*obj.uExch*parameter.lv*r_air*A_road + ...
                obj.latAnthrop*(wdth_canyon+wdth_bld)+...
                obj.treeLatHeat*A_road)/(Ccan +...
                buildingTerm(4) + obj.uExch*parameter.lv*r_air*A_road);

        end 
    end
end

