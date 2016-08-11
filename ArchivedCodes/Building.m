classdef Building
    %   Building building class of specified building characteristics.
    
    properties
        % Building parameters
        floorHeight;        % floor height (m)
        intHeat;            % timestep internal heat gains (W m-2 bld)
        intHeatNight;       % nighttime internal heat gains (W m-2 floor)
        intHeatDay;         % daytime internal heat gains (W m-2 floor)
        intHeatFRad;        % radiant fraction of internal gains
        intHeatFLat;        % latent fraction of internal gains
        infil;              % Infiltration (ACH)
        vent;               % Ventilation (ACH)
        glazingRatio;       % glazing ratio
        uValue;             % window U-value (W m-2 K-1) (including film coeff)
        shgc;               % window SHGC
        condType;           % cooling condensation system type {'AIR', 'WATER'}
        cop;                % COP of the cooling system (nominal)
        coolSetpointDay;    % daytime indoor cooling set-point (K)
        coolSetpointNight;  % nighttime indoor cooling set-point (K)
        heatSetpointDay;    % daytime indoor heating set-point (K)
        heatSetpointNight;  % nighttime indoor heating set-point (K)
        coolCap;            % rated cooling system capacity (W m-2)
        heatCap;            % rated heating system capacity (W m-2)
        heatEff;            % heating system efficiency (-)
        mSys;               % HVAC supply mass flowrate (kg s-1 m-2)
        indoorTemp;         % indoor air temperature (K)
        indoorHum;          % indoor specific humidity (kg / kg)
        Twb;                % wetbulb temperature 
        Tdp;                % dew point 

        area_floor;         % total floor space of the BEM
        FanMax;             % max fan flow rate (m^3/s) per DOE
        nFloor;             % number of floors
        
        % Calculated values
        sensCoolDemand;     % building sensible cooling demand (W m-2)
        sensHeatDemand;     % building sensible heating demand (W m-2)
        copAdj;             % adjusted COP per temperature
        dehumDemand;        % dehumidification energy (W m-2)
        coolConsump;        % cooling energy consumption (W m-2)
        heatConsump;        % heating energy consumption (W m-2)
        sensWaste;          % sensible waste heat (W m-2)
        latWaste;           % lat waste heat (W m-2)
        fluxMass;           % mass surface heat flux (W m-2) (mass to indoor air)
        fluxWall;           % wall surface heat flux (W m-2) (wall to inside)
        fluxRoof;           % roof surface heat flux (W m-2) (roof to inside)
        fluxSolar;          % solar heat gain (W m-2) through window (SHGC)
        fluxWindow;         % heat gain/loss from window (U-value)
        fluxInterior;       % internal heat gain adjusted for latent/LW heat (W m-2)
        fluxInfil;          % heat flux from infiltration (W m-2)
        fluxVent;           % heat flux from ventilation (W m-2)
        ElecTotal;          % total electricity consumption - (W/m^2) of floor
        GasTotal;           % total gas consumption - (W/m^2) of floor
        Qhvac;              % total heat removed (sensible + latent)
        Qheat;              % total heat added (sensible only)
    end
    
    methods
        function obj = Building(floorHeight,intHeatNight,intHeatDay,intHeatFRad,...
                intHeatFLat,infil,vent,glazingRatio,uValue,shgc,...
                condType,cop,coolSetpointDay,coolSetpointNight,...
                heatSetpointDay,heatSetpointNight,coolCap,heatEff,initialTemp)
            % class constructor
                if (nargin > 0)
                    obj.floorHeight = floorHeight;
                    obj.intHeat = intHeatNight;
                    obj.intHeatNight = intHeatNight;
                    obj.intHeatDay = intHeatDay;
                    obj.intHeatFRad = intHeatFRad;    
                    obj.intHeatFLat = intHeatFLat;   
                    obj.infil = infil;      % ACH
                    obj.vent = vent;        
                    obj.glazingRatio = glazingRatio;
                    obj.uValue = uValue;
                    obj.shgc = shgc;
                    obj.condType = condType; 
                    obj.cop = cop;
                    obj.coolSetpointDay = coolSetpointDay;
                    obj.coolSetpointNight = coolSetpointNight;
                    obj.heatSetpointDay = heatSetpointDay; 
                    obj.heatSetpointNight = heatSetpointNight; 
                    obj.coolCap = coolCap;
                    obj.heatEff = heatEff;
                    obj.mSys = coolCap/1004./(min(coolSetpointDay,coolSetpointNight)-14-273.15);
                    obj.indoorTemp = initialTemp;
                    obj.indoorHum = 0.012;
                    obj.heatCap = 999;      % Default heat capacity value
                    obj.copAdj = cop;
                end
        end
        
        function obj = BEMCalc(obj,UCM,BEM,forc,parameter,simTime)
            
            % Building Energy Model (some of these can be moved up)
            obj.ElecTotal = 0;
            obj.nFloor = max(floor(UCM.bldHeight/obj.floorHeight),1);
            obj.Qheat = 0;
            obj.sensCoolDemand = 0.0;
            obj.sensHeatDemand = 0.0;
            obj.coolConsump  = 0.0;
            obj.heatConsump  = 0.0;
            obj.sensWaste = 0.0;
            obj.dehumDemand  = 0.0;
            obj.Qhvac = 0;
            Qdehum = 0;
            dens = forc.pres/(1000*0.287042*obj.indoorTemp*(1.+1.607858*obj.indoorHum));
            evapEff = 1.;                               % evaporation efficiency in the condenser
            volVent = obj.vent*obj.nFloor;              % [m3 s-1 m-2(bld)]
            volInfil = obj.infil*UCM.bldHeight/3600;    % Change of units AC/H -> [m3 s-1 m-2(bld)]
            volSWH = BEM.SWH * obj.nFloor/3600;
            T_wall = BEM.wall.layerTemp(end);           % Inner layer
            T_ceil = BEM.roof.layerTemp(end);           % Inner layer
            T_mass = BEM.mass.layerTemp(1);             % Outer layer
            T_indoor = obj.indoorTemp;                  % Indoor temp (initial)
            T_can = UCM.canTemp;                        % Canyon temperature
            
            % Normalize areas to building foot print [m^2/m^2(bld)]
            facArea = UCM.verToHor/UCM.bldDensity;      % [m2/m2(bld)]
            wallArea = facArea*(1.-obj.glazingRatio);   % [m2/m2(bld)]
            winArea = facArea*obj.glazingRatio;         % [m2/m2(bld)]
            massArea = 2*obj.nFloor-1;      % ceiling/floor (top & bottom)

            % Temperature set points (updated per building schedule)
            if simTime.secDay/3600 < parameter.nightSetEnd || simTime.secDay/3600 >= parameter.nightSetStart
                T_cool = obj.coolSetpointNight;
                T_heat = obj.heatSetpointNight;
                obj.intHeat = obj.intHeatNight*obj.nFloor;
            else
                T_cool = obj.coolSetpointDay;
                T_heat = obj.heatSetpointDay;
                obj.intHeat = obj.intHeatDay*obj.nFloor;
            end

            % Indoor convection heat transfer coefficients
            zac_in_wall = 3.076;
            zac_in_mass = 3.076;
            if (T_ceil > T_indoor)
                zac_in_ceil  = 0.948;
            elseif(T_ceil <= T_indoor);
                zac_in_ceil  = 4.040;
            else
                disp('!!!!!FATAL ERROR!!!!!!');
                return;
            end
                        
            % -------------------------------------------------------------
            % Heat fluxes (per m^2 of bld footprint)
            % -------------------------------------------------------------
            % Solar Heat Gain
            winTrans = BEM.wall.solRec*obj.shgc*winArea;
            
            % Latent heat infiltration & ventilation (W/m^2 of bld footprint)
            QLinfil = volInfil * dens * parameter.lv *(UCM.canHum - obj.indoorHum);
            QLvent = volVent * dens * parameter.lv *(UCM.canHum - obj.indoorHum);
            QLintload = obj.intHeat * obj.intHeatFLat;
                        
            % Heat/Cooling load (W/m^2 of bld footprint), if any
            obj.sensCoolDemand = max(wallArea*zac_in_wall*(T_wall-T_cool)+...
                massArea*zac_in_mass*(T_mass-T_cool)+...
                winArea*obj.uValue*(T_can-T_cool)+...
                zac_in_ceil *(T_ceil-T_cool)+...
                obj.intHeat*(1-obj.intHeatFLat)+...
                volInfil * dens*parameter.cp*(T_can-T_cool)+...
                volVent * dens*parameter.cp*(T_can-T_cool) + ...
                winTrans,0);
            obj.sensHeatDemand = max(-(wallArea*zac_in_wall*(T_wall-T_heat)+...
                massArea*zac_in_mass*(T_mass-T_heat)+...
                winArea*obj.uValue*(T_can-T_heat)+...
                zac_in_ceil*(T_ceil-T_heat)+...
                volInfil*dens*parameter.cp*(T_can-T_heat)+...
                volVent*dens*parameter.cp*(T_can-T_heat)) - winTrans - ...
                obj.intHeat*(1-obj.intHeatFLat),0);

            % -------------------------------------------------------------
            % HVAC system (cooling demand = W/m^2 bld footprint)
            % -------------------------------------------------------------
            if obj.sensCoolDemand > 0 && UCM.canTemp > 288
   
                % Cooling energy is the equivalent energy to bring a vol 
                % where sensCoolDemand = dens * Cp * x * (T_indoor - 10C) &
                % given 7.8g/kg of air at 10C, assume 7g/kg of air
                % dehumDemand = x * dens * (obj.indoorHum -
                % 0.9*0.0078)*parameter.lv
                VolCool = obj.sensCoolDemand / (dens*parameter.cp*(T_indoor-283.15));
                obj.dehumDemand = max(VolCool * dens * (obj.indoorHum - 0.9*0.0078)*parameter.lv,0);
                
                if (obj.dehumDemand + obj.sensCoolDemand) > (obj.coolCap * obj.nFloor)
                    obj.Qhvac = obj.coolCap * obj.nFloor;
                    VolCool = VolCool / (obj.dehumDemand + obj.sensCoolDemand) * (obj.coolCap * obj.nFloor);
                    obj.sensCoolDemand = obj.sensCoolDemand * (obj.coolCap * obj.nFloor) / (obj.dehumDemand + obj.sensCoolDemand);
                    obj.dehumDemand = obj.dehumDemand * (obj.coolCap * obj.nFloor) / (obj.dehumDemand + obj.sensCoolDemand);
                else
                    obj.Qhvac = obj.dehumDemand + obj.sensCoolDemand;
                end
                Qdehum = VolCool * dens * parameter.lv * (obj.indoorHum - 0.9*0.0078);
                obj.coolConsump =(max(obj.sensCoolDemand+obj.dehumDemand,0))/obj.copAdj;                
                
                % Waste heat from HVAC (per m^2 building foot print)
                if strcmp(obj.condType,'AIR')
                    obj.sensWaste = max(obj.sensCoolDemand+obj.dehumDemand,0)+obj.coolConsump;
                    obj.latWaste = 0.0;
                elseif strcmp(obj.condType,'WAT') % Not sure if this works well
                    obj.sensWaste = max(obj.sensCoolDemand+obj.dehumDemand,0)+obj.coolConsump*(1.-evapEff);
                    obj.latWaste = max(obj.sensCoolDemand+obj.dehumDemand,0)+obj.coolConsump*evapEff;
                end
                obj.coolConsump = obj.coolConsump/obj.nFloor;
                obj.sensCoolDemand = obj.sensCoolDemand/obj.nFloor;
                
            % -------------------------------------------------------------
            % Heating system (heating demand = W/m^2 bld footprint)
            % -------------------------------------------------------------
            elseif obj.sensHeatDemand > 0 && UCM.canTemp < 293

                % Assume no limit on heating capacity
                obj.Qheat = obj.sensHeatDemand;
                obj.heatConsump  = obj.sensHeatDemand / obj.heatEff;
                obj.sensWaste = obj.heatConsump - obj.Qheat;        % waste per footprint 
                obj.heatConsump = obj.heatConsump/obj.nFloor;       % adjust to be per floor area
                obj.sensHeatDemand = obj.sensHeatDemand/obj.nFloor; % adjust to be per floor area
                Qdehum = 0;
            end
                        
            % -------------------------------------------------------------
            % Evolution of the internal temperature and humidity
            % -------------------------------------------------------------
            
            % wall, mass, roof, intload, infil, vent, hvac, heat, window
            Q = obj.intHeat + winTrans + (obj.Qheat-obj.sensCoolDemand)*obj.nFloor;
            
            H1 = T_wall*wallArea*zac_in_wall + ...
                T_mass*massArea*zac_in_mass + ...
                T_ceil*zac_in_ceil + ...
                T_can*winArea*obj.uValue + ...
                T_can*volInfil * dens * parameter.cp + ...
                T_can*volVent * dens * parameter.cp;                
            
            H2 = wallArea*zac_in_wall + ...
                massArea*zac_in_mass + ...
                zac_in_ceil + ...
                winArea*obj.uValue + ...
                volInfil * dens * parameter.cp + ...
                volVent * dens * parameter.cp;                
                
            obj.indoorTemp = (H1+ Q)/H2;
            obj.indoorHum = obj.indoorHum + simTime.dt/(dens * parameter.lv * UCM.bldHeight) * (...
                QLintload + QLinfil + QLvent - Qdehum);

            % Error checking
            if obj.indoorTemp > 350 || obj.indoorTemp < 288
                disp('Something obviously went wrong... ');
            end

            % These are used for element calculation (per m^2 of element area)
            obj.fluxWall = zac_in_wall *(T_indoor - T_wall);
            obj.fluxRoof = zac_in_ceil *(T_indoor - T_ceil);
            obj.fluxMass = zac_in_mass *(T_indoor - T_mass) + (winTrans + obj.intHeat * obj.intHeatFRad)/massArea;

            % These are for record keeping only, per m^2 of floor area
            obj.fluxSolar = winTrans/obj.nFloor;
            obj.fluxWindow = winArea * obj.uValue *(T_can - T_indoor)/obj.nFloor;
            obj.fluxInterior = obj.intHeat * obj.intHeatFRad *(1.-obj.intHeatFLat)/obj.nFloor;
            obj.fluxInfil= volInfil * dens * parameter.cp *(T_can - T_indoor)/obj.nFloor;
            obj.fluxVent = volVent * dens * parameter.cp *(T_can - T_indoor)/obj.nFloor;            

            % Total Electricity/building floor area (W/m^2)
            obj.ElecTotal = obj.coolConsump + BEM.Elec + BEM.Light;

            % Waste heat to canyon, W/m^2 of building + water
            CpH20 = 4200;           % heat capacity of water
            T_hot = 49 + 273.15;    % Service water temp (assume no storage)
            obj.sensWaste = obj.sensWaste + (1/obj.heatEff-1)*(volSWH*CpH20*(T_hot - forc.waterTemp));
            
            % Gas equip per floor + water usage per floor + heating/floor
            obj.GasTotal = BEM.Gas + volSWH*CpH20*(T_hot - forc.waterTemp)/obj.nFloor/obj.heatEff + obj.heatConsump;                        

        end
    end
end

function psat = psat(temp,parameter)
    gamw  = (parameter.cl - parameter.cpv) / parameter.rv;
    betaw = (parameter.lvtt/parameter.rv) + (gamw * parameter.tt);
    alpw = log(parameter.estt) + (betaw /parameter.tt) + (gamw *log(parameter.tt));
    psat = zeros(size(temp));
    for jj=1:size(temp)
        psat = exp(alpw - betaw/temp - gamw*log(temp));
    end
end

%         function obj = BEMCalc(obj,UCM,BEM,forc,parameter,simTime)
%             
%             % Building Energy Model (some of these can be moved up)
%             obj.ElecTotal = 0;
%             obj.nFloor = max(floor(UCM.bldHeight/obj.floorHeight),1);
%             obj.Qheat = 0;
%             obj.sensCoolDemand = 0.0;
%             obj.sensHeatDemand = 0.0;
%             obj.coolConsump  = 0.0;
%             obj.heatConsump  = 0.0;
%             obj.sensWaste = 0.0;
%             obj.dehumDemand  = 0.0;
%             obj.Qhvac = 0;
%             Qdehum = 0;
%             dens = forc.pres/(1000*0.287042*obj.indoorTemp*(1.+1.607858*obj.indoorHum));
%             evapEff = 1.;                               % evaporation efficiency in the condenser
%             volVent = obj.vent*obj.nFloor;              % [m3 s-1 m-2(bld)]
%             volInfil = obj.infil*UCM.bldHeight/3600;    % Change of units AC/H -> [m3 s-1 m-2(bld)]
%             volSWH = BEM.SWH * obj.nFloor/3600;
%             T_wall = BEM.wall.layerTemp(end);           % Inner layer
%             T_ceil = BEM.roof.layerTemp(end);           % Inner layer
%             T_mass = BEM.mass.layerTemp(1);             % Outer layer
%             T_indoor = obj.indoorTemp;                  % Indoor temp (initial)
%             T_can = UCM.canTemp;                        % Canyon temperature
%             
%             % Normalize areas to building foot print [m^2/m^2(bld)]
%             facArea = UCM.verToHor/UCM.bldDensity;      % [m2/m2(bld)]
%             wallArea = facArea*(1.-obj.glazingRatio);   % [m2/m2(bld)]
%             winArea = facArea*obj.glazingRatio;         % [m2/m2(bld)]
%             massArea = 2*obj.nFloor-1;      % ceiling/floor (top & bottom)
% 
%             % Temperature set points (updated per building schedule)
%             if simTime.secDay/3600 < parameter.nightSetEnd || simTime.secDay/3600 >= parameter.nightSetStart
%                 T_cool = obj.coolSetpointNight;
%                 T_heat = obj.heatSetpointNight;
%                 obj.intHeat = obj.intHeatNight*obj.nFloor;
%             else
%                 T_cool = obj.coolSetpointDay;
%                 T_heat = obj.heatSetpointDay;
%                 obj.intHeat = obj.intHeatDay*obj.nFloor;
%             end
% 
%             % Indoor convection heat transfer coefficients
%             zac_in_wall = 3.076;
%             zac_in_mass = 3.076;
%             if (T_ceil > T_indoor)
%                 zac_in_ceil  = 0.948;
%             elseif(T_ceil <= T_indoor);
%                 zac_in_ceil  = 4.040;
%             else
%                 disp('!!!!!FATAL ERROR!!!!!!');
%                 return;
%             end
%                         
%             % -------------------------------------------------------------
%             % Heat fluxes (per m^2 of bld footprint)
%             % -------------------------------------------------------------
%             % Solar Heat Gain & Window
%             winTrans = BEM.wall.solRec*obj.shgc*winArea;
%             Qwindow = winArea * obj.uValue *(T_can - T_indoor);
%             
%             % Infiltration & Ventilation (W/m^2 of bld footprint)
%             Qinfil = volInfil * dens * parameter.cp *(T_can - T_indoor);
%             QLinfil = volInfil * dens * parameter.lv *(UCM.canHum - obj.indoorHum);
%             Qvent = volVent * dens * parameter.cp *(T_can - T_indoor);
%             QLvent = volVent * dens * parameter.lv *(UCM.canHum - obj.indoorHum);
%             
%             % Roof, wall, mass (Ceiling)(W/m^2 of bld footprint)
%             Qwall = wallArea * zac_in_wall *(T_wall - T_indoor);            
%             Qroof = zac_in_ceil *(T_ceil - T_indoor);
%             Qmass = massArea * zac_in_mass *(T_mass - T_indoor);
%             
%             % Internal Load
%             Qintload = obj.intHeat *(1 - obj.intHeatFLat);
%             QLintload = obj.intHeat * obj.intHeatFLat;
%                         
%             % Heat/Cooling load (W/m^2 of bld footprint), if any
%             obj.sensCoolDemand = max(wallArea*zac_in_wall*(T_wall-T_cool)+...
%                 massArea*zac_in_mass*(T_mass-T_cool)+...
%                 winArea*obj.uValue*(T_can-T_cool)+...
%                 zac_in_ceil *(T_ceil-T_cool)+...
%                 obj.intHeat*(1-obj.intHeatFLat)+...
%                 volInfil * dens*parameter.cp*(T_can-T_cool)+...
%                 volVent * dens*parameter.cp*(T_can-T_cool) + ...
%                 winTrans,0);
%             obj.sensHeatDemand = max(-(wallArea*zac_in_wall*(T_wall-T_heat)+...
%                 massArea*zac_in_mass*(T_mass-T_heat)+...
%                 winArea*obj.uValue*(T_can-T_heat)+...
%                 zac_in_ceil*(T_ceil-T_heat)+...
%                 volInfil*dens*parameter.cp*(T_can-T_heat)+...
%                 volVent*dens*parameter.cp*(T_can-T_heat)) - winTrans - ...
%                 obj.intHeat*(1-obj.intHeatFLat),0);
% 
%             if obj.sensHeatDemand < 0
%                 a = 1;
%             end
%             % -------------------------------------------------------------
%             % HVAC system (cooling demand = W/m^2 bld footprint)
%             % -------------------------------------------------------------
%             if obj.sensCoolDemand > 0 && UCM.canTemp > 288
%    
%                 % Adjust nominal building COP per Bruno (2012), B.17
% %                 [~, ~, ~, ~, obj.Tdp, ~] = Psychrometrics (T_indoor, obj.indoorHum, forc.pres);
% % %             obj.Twb = wet_bulb(T_indoor,obj.Tdp+273.15,pres);    % wetbulb temperature
% % %             Twi = obj.Twb - 273.15;     % Indoor wetbulb temperature
% % %             Tci = T_can - 273.15;       % Outdoor drybulb temperature
% %                 % A rough estimate for now - change to a look up table later,
% %                 % because the above code is very slow.
% %                 obj.Twb = T_indoor - (T_indoor - (obj.Tdp+273.15))/3;
% %                 Twi = obj.Twb - 273.15;
% %                 Tci = T_can - 273.15;
% %                 obj.copAdj = obj.cop/(0.3424+0.0349*Twi+(-0.000624)*Twi^2+0.00498*Tci+0.000438*Tci^2+(-0.000728)*Twi*Tci);
%                 
%                 % Cooling energy is the equivalent energy to bring a vol 
%                 % where sensCoolDemand = dens * Cp * x * (T_indoor - 10C) &
%                 % given 7.8g/kg of air at 10C, assume 7g/kg of air
%                 % dehumDemand = x * dens * (obj.indoorHum -
%                 % 0.9*0.0078)*parameter.lv
%                 VolCool = obj.sensCoolDemand / (dens*parameter.cp*(T_indoor-283.15));
%                 obj.dehumDemand = max(VolCool * dens * (obj.indoorHum - 0.9*0.0078)*parameter.lv,0);
%                 
%                 if (obj.dehumDemand + obj.sensCoolDemand) > (obj.coolCap * obj.nFloor)
%                     obj.Qhvac = obj.coolCap * obj.nFloor;
%                     VolCool = VolCool / (obj.dehumDemand + obj.sensCoolDemand) * (obj.coolCap * obj.nFloor);
%                 else
%                     obj.Qhvac = obj.dehumDemand + obj.sensCoolDemand;
%                 end
%                 Qdehum = VolCool * dens * parameter.lv * (obj.indoorHum - 0.9*0.0078);
% 
% %                 T_supply = T_mix - obj.sensCoolDemand/obj.mSys/parameter.cp;
% %                 % Supply specific humidity (assuming RH90%)
% %                 pq_sys = min(0.62198 * 0.9 * psat(T_supply,parameter) /...
% %                     (pres-0.9 * psat(T_supply,parameter)),zq_mix);
% %                 obj.dehumDemand = obj.mSys*parameter.lv*(zq_mix-pq_sys);
%                 obj.coolConsump =(max(obj.sensCoolDemand+obj.dehumDemand,0))/obj.copAdj;                
%                 
%                 % Waste heat from HVAC (per m^2 building foot print)
%                 if strcmp(obj.condType,'AIR')
%                     obj.sensWaste = max(obj.sensCoolDemand+obj.dehumDemand,0)+obj.coolConsump;
%                     obj.latWaste = 0.0;
%                 elseif strcmp(obj.condType,'WAT') % Not sure if this works well
%                     obj.sensWaste = max(obj.sensCoolDemand+obj.dehumDemand,0)+obj.coolConsump*(1.-evapEff);
%                     obj.latWaste = max(obj.sensCoolDemand+obj.dehumDemand,0)+obj.coolConsump*evapEff;
%                 end
%                 obj.coolConsump = obj.coolConsump/obj.nFloor;
%                 obj.sensCoolDemand = obj.sensCoolDemand/obj.nFloor;
%                 
%             % -------------------------------------------------------------
%             % Heating system (heating demand = W/m^2 bld footprint)
%             % -------------------------------------------------------------
%             elseif obj.sensHeatDemand > 0 && UCM.canTemp < 293
% 
%                 % Assume no limit on heating capacity
%                 obj.Qheat = obj.sensHeatDemand;
%                 obj.heatConsump  = obj.sensHeatDemand / obj.heatEff;
%                 obj.sensWaste = obj.heatConsump - obj.Qheat;        % waste per footprint 
%                 obj.heatConsump = obj.heatConsump/obj.nFloor;       % adjust to be per floor area
%                 obj.sensHeatDemand = obj.sensHeatDemand/obj.nFloor; % adjust to be per floor area
%                 Qdehum = 0;
%             end
%             
%             % Waste heat to canyon, W/m^2 of building + water
%             CpH20 = 4200;           % heat capacity of water
%             T_hot = 49 + 273.15;    % Service water temp (assume no storage)
%             obj.sensWaste = obj.sensWaste + (1/obj.heatEff-1)*(volSWH*CpH20*(T_hot - forc.waterTemp));
%             
%             % Gas equip per floor + water usage per floor + heating/floor
%             obj.GasTotal = BEM.Gas + volSWH*CpH20*(T_hot - forc.waterTemp)/obj.nFloor/obj.heatEff + obj.heatConsump;
%             
%             % -------------------------------------------------------------
%             % Heat fluxes (normalized to m^2 of building)
%             % -------------------------------------------------------------
%             
%             % These are used for element calculation (per m^2 of element area)
%             obj.fluxWall = zac_in_wall *(T_indoor - T_wall);
%             obj.fluxRoof = zac_in_ceil *(T_indoor - T_ceil);
%             obj.fluxMass = zac_in_mass *(T_indoor - T_mass) + (winTrans + obj.intHeat * obj.intHeatFRad)/massArea;
%             
%             % These are for record keeping only, per floor area
%             obj.fluxSolar = winTrans/obj.nFloor;
%             obj.fluxWindow = winArea * obj.uValue *(T_can - T_indoor)/obj.nFloor;
%             obj.fluxInterior = obj.intHeat * obj.intHeatFRad *(1.-obj.intHeatFLat)/obj.nFloor;
%             obj.fluxInfil= volInfil * dens * parameter.cp *(T_can - T_indoor)/obj.nFloor;
%             obj.fluxVent = volVent * dens * parameter.cp *(T_can - T_indoor)/obj.nFloor;
%             
%             % -------------------------------------------------------------
%             % Evolution of the internal temperature and humidity
%             % -------------------------------------------------------------
%             obj.indoorTemp = T_indoor +simTime.dt/(dens * parameter.cp * UCM.bldHeight) * (...
%                 Qwall + Qmass + Qwindow + Qroof+ Qintload + Qinfil+ Qvent - ...
%                 obj.Qhvac + obj.Qheat + winTrans);
%             obj.indoorHum = obj.indoorHum + simTime.dt/(dens * parameter.lv * UCM.bldHeight) * (...
%                 QLintload + QLinfil + QLvent - Qdehum);
%             
%             % Total Electricity/building floor area (W/m^2)
%             obj.ElecTotal = obj.coolConsump + BEM.Elec + BEM.Light;
%             
%             % Error checking
%             if obj.indoorTemp > 350 || obj.indoorTemp < 250
%                 disp('Something obviously went wrong... ');
%             end
%         end
%     end

