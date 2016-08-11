classdef UCMDef
    % Definition of Urban Canopy - Building Energy Model Class
    %   Detailed explanation goes here
    
    properties
        road;          % Road element class (moved from BEM)
        
        % Urban Canyon Parameters
        bldHeight;     % average building height (m)
        bldDensity;    % horizontal building density (footprint)
        verToHor;      % vertical-to-horizontal urban area ratio (facade area/urban area)
        treeCoverage;  % horizontal tree density (footprint)
        sensAnthrop;   % sensible anthropogenic heat (other than from buildings) (W m-2)
        latAnthrop;    % latent anthropogenic heat (other than from buildings) (W m-2)
        z0u;           % urban roughness length (m)
        disp;          % urban displacement length (m)
        roadShad;      % shadowing of roads
        canWidth;      % canyon width (m)
        bldWidth;      % bld width (m)
        canAspect;     % canyon aspect ratio
        roadConf;      % road-sky configuration factors
        wallConf;      % wall-sky configuration factors
        VFwallroad;    % wall-road view factor
        VFroadwall;    % road-wall view factor
        facArea;       % facade area (m2)
        roadArea;      % road area (m2)
        roofArea;      % roof area (m2) (also building area)
        facAbsor;      % average facade absortivity
        roadAbsor;     % average road absortivity
        
        % Urban Canyon Variables
        canTemp;       % canyon air temperature (db) (K)
        Tdp;           % dew point temperature 
        Twb;           % wetbulb temperature
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
        windProf;      % urban wind profile
        Q_roof;        % sensible heat flux from building roof (convective)
        Q_wall;        % sensible heat flux from building wall (convective)
        Q_window;      % sensible heat flux from building window (via U-factor)
        Q_road;        % sensible heat flux from road (convective)
        Q_hvac;        % sensible heat flux from HVAC waste 
        Q_traffic;     % sensible heat flux from traffic (net)
        Q_ubl;         % Convective heat exchange with UBL layer
        Q_vent;        % Convective heat exchange from ventilation
        SolRecWall;    % Solar received by wall
        SolRecRoof;    % Solar received by roof
        SolRecRoad;    % Solar received by road
        roadTemp;      % average road temperature (K)
        roofTemp;      % average roof temperature (K)
        wallTemp;      % average wall temperature (K)
        ElecTotal;     % Total Electricity consumption
    end
    
    methods
        function obj = UCMDef(bldHeight,bldDensity,verToHor,treeCoverage,sensAnthrop,latAnthrop,...
                initialTemp,initialHum,initialWind,parameter,r_glaze,SHGC,alb_wall,road)
            % class constructor
            if(nargin > 0)
                obj.road = road;
                obj.bldHeight = bldHeight;
                obj.verToHor = verToHor;            % for building only?
                obj.bldDensity = bldDensity;
                obj.treeCoverage = treeCoverage;
                obj.sensAnthrop = sensAnthrop;
                obj.latAnthrop = latAnthrop;
                obj.roadShad = min(treeCoverage/(1-bldDensity),1);
%                 obj.canWidth  = 2*bldHeight*(1-bldDensity)/verToHor;
%                 obj.bldWidth = 2*bldHeight*bldDensity/verToHor;
%                 obj.canAspect = bldHeight/obj.canWidth;
               obj.bldWidth = 4*bldHeight*bldDensity/verToHor; 
               obj.canWidth  = obj.bldWidth/(bldDensity^0.5);
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
                if frontDens < 0.15 
                  obj.z0u = frontDens*obj.bldHeight;
                else
                  obj.z0u = 0.15*obj.bldHeight;
                end
                if frontDens < 0.05 
                  obj.disp = 3*frontDens*obj.bldHeight;
                elseif frontDens < 0.15
                  obj.disp = (0.15+5.5*(frontDens-0.05))*obj.bldHeight;
                elseif frontDens < 1
                  obj.disp = (0.7+0.35*(frontDens-0.15))*obj.bldHeight;
                else 
                  obj.disp = 0.5*obj.bldHeight;
                end
                obj.facAbsor = (1-r_glaze)*(1-alb_wall)+r_glaze*(1-0.75*SHGC);
                obj.roadAbsor = (1-road.vegCoverage)*(1-road.albedo);
                obj.sensHeat = 0.;
            end
        end
    
        function obj = UCModel(obj,BEM,T_ubl,forc,parameter,simTime)

            % Calculate the urban canyon temperature per The UWG (2012) Eq. 10 
            buildingTerm = zeros(4,1);
            wallTerm = zeros(2,1);
            roadTerm = zeros(3,1);
            ublTerm = zeros(2,1);
            dens = forc.pres/(1000*0.287042*obj.canTemp*(1.+1.607858*obj.canHum)); % air density
            Cp_air = parameter.cp;
            obj.Q_wall = 0;
            obj.Q_window = 0;
            obj.Q_road = 0;
            obj.Q_hvac = 0;
            obj.Q_traffic = 0;
            obj.Q_vent = 0;
            obj.Q_ubl = 0;
            obj.ElecTotal = 0;
            obj.roofTemp = 0;
            obj.wallTemp = 0;
            A_facade = obj.facArea;
            A_roof = obj.roofArea;
            wdth_canyon = obj.canWidth;
            w_bld = obj.bldWidth;
            h_bld = obj.bldHeight;

            % Road to Canyon
            T_can = obj.canTemp;
            T_road = obj.road.layerTemp(1);
            A_road = obj.roadArea;
            h_conv = obj.road.aeroCond;
            H1 = T_road*h_conv*A_road;       % Heat (Sens) from road surface
            H2 = h_conv*A_road;              % 
            H1 = H1 + T_ubl*(A_road+A_roof)*obj.uExch*Cp_air*dens;
            H2 = H2 + (A_road+A_roof)*obj.uExch*Cp_air*dens;
%            roadTerm(3) = obj.road.lat*A_road;                      % Latent heat from road
            Q = 0;

            
            % Building energy output to canyon
            for j = 1:numel(BEM)

                % Re-naming variable for readability
                building = BEM(j).building;
                wall = BEM(j).wall;
                roof = BEM(j).roof;
                T_indoor = building.indoorTemp;
                T_wall = wall.layerTemp(1);
                T_roof = roof.layerTemp(1);
                R_glazing= building.glazingRatio;
                A_wall = (1-R_glazing)*A_facade;
                A_window = R_glazing*A_facade;
                Rate_vent = building.vent;
                U_window = building.uValue;
                Qsens_waste = building.sensWaste*A_roof;
                Qlat_waste = building.latWaste*A_roof;
                T_condensor = 320;
                
                H1 = H1 + BEM(j).frac*(...
                    T_indoor*A_window*U_window + ...    % window U
                    T_wall*A_wall*h_conv);              % Wall conv
                    
                H2 = H2 + BEM(j).frac*(...
                    A_window*U_window + ...
                    A_wall*h_conv); 
                    
%                 Q = Q + BEM(j).frac*(...
%                     Qsens_waste*A_roof + ...
            end
                
            obj.canTemp = (H1 + Q)/H2;
            obj.Q_road = h_conv*(T_road-obj.canTemp)*(1-obj.bldDensity);  % Sensible heat from road (W/m^2 of urban area)
            obj.Q_ubl = obj.uExch*Cp_air*dens*(T_ubl-obj.canTemp);
            obj.Q_wall = h_conv*(T_wall-obj.canTemp)*(obj.verToHor);


%                 % Window, Vent, HVAC waste Heat to Canyon
%                 buildingTerm(1) = buildingTerm(1) + BEM(j).frac *...
%                     (T_indoor*A_window*U_window + ...               % Heat through window
%                     - T_indoor*A_roof*building.nFloor*(building.fluxInfil+building.fluxVent) +...    % Heat from vented air
%                     T_condensor*Qsens_waste*w_bld);                                     % Waste heat from HVAC
%                 buildingTerm(2) = buildingTerm(2) + BEM(j).frac * ...
%                     (A_window*U_window + A_roof*building.nFloor*(building.fluxInfil+building.fluxVent) + Qsens_waste*w_bld);
% 
%                 % Wall surface to Canyon
%                 wallTerm(1) = wallTerm(1) + BEM(j).frac *...
%                     (T_wall*wall.aeroCond*A_wall + ...
%                     T_wall*wall.solRec*A_window*(1-building.shgc));    % Solar heat not transmitted through window
%                 wallTerm(2) = wallTerm(2) + BEM(j).frac *...
%                     (wall.aeroCond*A_wall + wall.solRec*A_window*(1-building.shgc));
%                 
%                 % Building humidity term
%                 buildingTerm(3) = buildingTerm(3) + BEM(j).frac*...
%                     (building.indoorHum*Rate_vent*V_bldg*dens*parameter.lv + Qlat_waste*w_bld);
%                 buildingTerm(4) = buildingTerm(4) + BEM(j).frac*...
%                     Rate_vent*V_bldg*dens*parameter.lv;
% 
%                 % FOR DATA OUTPUT 
% %                obj.Q_wall = obj.Q_wall + BEM(j).frac*(wall.aeroCond*Cp_air*dens*A_wall*(T_wall-T_can) + wall.solRec*A_window*(1-building.shgc));   % Sensible heat from wall
%                 obj.Q_wall = obj.Q_wall + BEM(j).frac*(wall.aeroCond*A_wall*(T_wall-T_can));   % Sensible heat from wall
%                 obj.Q_window = obj.Q_window + BEM(j).frac*A_window*U_window*(T_indoor-T_can);            % Sensible heat from window
%                 obj.Q_roof = obj.Q_roof + BEM(j).frac*roof.aeroCond*A_roof*(T_roof-T_can);
%                 obj.Q_hvac = obj.Q_hvac + BEM(j).frac*Qsens_waste*w_bld;   % HVAC waste heat dumped into canyon, incl. SWH & gas
%                 obj.Q_vent = obj.Q_vent + BEM(j).frac*(-1)*building.nFloor*(building.fluxInfil + building.fluxVent)*w_bld;     % Heat/mass exchange from vent
%                 
%                 % Energy 
%                 obj.ElecTotal = obj.ElecTotal + BEM(j).ElecTotal/1e6;   % Electricity Demand (MW)
%                 obj.roofTemp = obj.roofTemp + BEM(j).frac*T_roof;       % Average urban roof temperature
%                 obj.wallTemp = obj.wallTemp + BEM(j).frac*T_wall;       % Average urban wall temperature
%             end
%             

            % urban air temperature

            treeTerm(1) = T_can*obj.treeSensHeat*(A_road+A_roof)*obj.treeCoverage;
            treeTerm(2) = obj.treeSensHeat*(A_road+A_roof)*obj.treeCoverage;
            anthroTerm(1) = 320*obj.sensAnthrop*(A_road+A_roof);
            anthroTerm(2) = obj.sensAnthrop*(A_road+A_roof);
            Ccan = Cp_air*dens*(2*wdth_canyon*h_bld+w_bld*h_bld)/simTime.dt;
            
            obj.canTemp = (buildingTerm(1) + wallTerm(1) + roadTerm(1)+ ... 
                ublTerm(1) + treeTerm(1) + anthroTerm(1))/...
                (Ccan + buildingTerm(2) + wallTerm(2) + roadTerm(2) + ...
                ublTerm(2)+ treeTerm(2) + anthroTerm(2));
                        
            % urban air humidity assumed to be the same as rural
            obj.canHum = forc.hum;

            % Scale by the area of the urban area for W/m^2 output & other
            % calcs.
            obj.Q_wall = obj.Q_wall/(A_road+A_roof);
            obj.Q_window = obj.Q_window/(A_road+A_roof);
            obj.Q_road = obj.Q_road/(A_road+A_roof);
            obj.Q_hvac = obj.Q_hvac/(A_road+A_roof);
            obj.Q_vent = obj.Q_vent/(A_road+A_roof);
            obj.Q_roof = obj.Q_roof/(A_road+A_roof);     
            
        end 
    end
end

