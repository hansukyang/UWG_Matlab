classdef Building
    %   Building building class of specified building characteristics.
    
    properties
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
        cop;                % COP of the cooling system
        fWaste;             % fraction of waste heat released into the canyon
        coolSetpointDay;    % daytime indoor cooling set-point (K)
        coolSetpointNight;  % nighttime indoor cooling set-point (K)
        heatSetpointDay;    % daytime indoor heating set-point (K)
        heatSetpointNight;  % nighttime indoor heating set-point (K)
        coolCap;            % rated cooling system capacity (W m-2)
        heatEff;            % heating system efficiency (-)
        mSys;               % HVAC supply mass flowrate (kg s-1 m-2)
        indoorTemp;         % indoor air temperature (K)
        indoorHum;          % indoor specific humidity (kg m-3)
        sensCoolDemand;     % building sensible cooling demand (W m-2)
        sensHeatDemand;     % building sensible heating demand (W m-2)
        dehumDemand;        % dehumidification energy (W m-2)
        coolConsump;        % cooling energy consumption (W m-2)
        heatConsump;        % heating energy consumption (W m-2)
        sensWaste;          % sensible waste heat (W m-2)
        latWaste;           % lat waste heat (W m-2)
        fluxMass;           % mass surface heat flux (W m-2)
        fluxWall;           % wall surface heat flux (W m-2)
        fluxRoof;           % roof surface heat flux (W m-2)
    end
    
    methods
        function obj = Building(floorHeight,intHeatNight,intHeatDay,intHeatFRad,...
                intHeatFLat,infil,vent,glazingRatio,uValue,shgc,...
                condType,cop,fWaste,coolSetpointDay,coolSetpointNight,...
                heatSetpointDay,heatSetpointNight,coolCap,...
                heatEff,initialTemp)
            % class constructor
                if(nargin > 0)
                    obj.floorHeight = floorHeight;
                    obj.intHeat = intHeatNight;
                    obj.intHeatNight = intHeatNight;
                    obj.intHeatDay = intHeatDay;
                    obj.intHeatFRad = intHeatFRad;    
                    obj.intHeatFLat = intHeatFLat;   
                    obj.infil = infil;    
                    obj.vent = vent;   
                    obj.glazingRatio = glazingRatio;
                    obj.uValue = uValue;
                    obj.shgc = shgc;
                    obj.condType = condType; 
                    obj.cop = cop;        
                    obj.fWaste = fWaste;     
                    obj.coolSetpointDay = coolSetpointDay;
                    obj.coolSetpointNight = coolSetpointNight;
                    obj.heatSetpointDay = heatSetpointDay; 
                    obj.heatSetpointNight = heatSetpointNight; 
                    obj.coolCap = coolCap;
                    obj.heatEff = heatEff;
                    obj.mSys = coolCap/1004./(min(coolSetpointDay,coolSetpointNight)-14-273.15);
                    obj.indoorTemp = initialTemp;
                    obj.indoorHum = 0.012;
                end
        end
        
        function obj = BuildingEnergyModel( obj,urbanArea,roof,wall,...
                window,mass,pres,parameter,simParam )
            % number of floors
            floorNum = urbanArea.bldHeight/obj.floorHeight;
            % set points
            if lt(simParam.secDay/3600.,parameter.nightSetEnd) || ge(simParam.secDay/3600.,parameter.nightSetStart)
                coolsetpoint = obj.coolSetpointNight;
                heatsetpoint = obj.heatSetpointNight;
                obj.intHeat = obj.intHeatNight*floorNum;
            else
                coolsetpoint = obj.coolSetpointDay;
                heatsetpoint = obj.heatSetpointDay;
                obj.intHeat = obj.intHeatDay*floorNum;
            end
            % air density
            dens = Density(obj.indoorTemp,obj.indoorHum,pres);
            % evaporation efficiency in the condenser
            evapEff = 1.;
            % Change of units AC/H -> [m3 s-1 m-2(bld)]
            volVent = obj.vent*urbanArea.bldHeight/3600;
            volInfil    = obj.infil*urbanArea.bldHeight/3600;
            % number of layers
            iroof  = size(roof.layerTemp,1);
            iwall  = size(wall.layerTemp,1);
            % [m2(wall)/m2(bld)]
            wallArea = urbanArea.verToHor*(1.-window.glazingRatio)/urbanArea.bldDensity;
            % [m2(win)/m2(bld)]
            winArea = urbanArea.verToHor*window.glazingRatio/urbanArea.bldDensity;
            % [m2(win)/m2(bld)]
            facArea = urbanArea.verToHor/urbanArea.bldDensity;
            % [m2(mass)/m2(bld)]
            massArea = 2*floorNum-1;
            % -------------------------------------------------------------
            % Solar radiation transmitted through windows
            winTrans = wall.solRec*0.6*window.shgc*window.glazingRatio*...
                urbanArea.verToHor/urbanArea.bldDensity;
            % -------------------------------------------------------------
            % Indoor convection heat transfer coefficients
            % disp(roof.layerTemp(iroof));
            zac_in_wall = 3.076;
            zac_in_mass = zac_in_wall;
            if (roof.layerTemp(iroof) > obj.indoorTemp)
                zac_in_roof  = 0.948;
            elseif(roof.layerTemp(iroof) <= obj.indoorTemp);
                zac_in_roof  = 4.040;
            else
                disp(roof.layerTemp(iroof));
                disp(obj.indoorTemp);
                disp('----------------------')
                disp('!!!!!FATAL ERROR!!!!!!');
                disp('----------------------')
            end
            % Mean radiant temperature
            radTemp = (mass.layerTemp(1)*massArea + wall.layerTemp(iwall)*wallArea+...
                roof.layerTemp(iroof))/(massArea + wallArea+ 1.);
            %display(radTemp);
            %dlmwrite('Trad.csv',radTemp,'delimiter',',','-append');
            % Radiation heat transfer coefficient [W m-2 K-1]
            radHTC   = 0.9*0.9*4*parameter.sigma*radTemp^3;
            % View factors
            far = urbanArea.bldHeight/floorNum/urbanArea.bldWidth;
            Faux = (far + 1-sqrt(far^2+1))/far;
            f_wall_mass = Faux*(2*floorNum-1)/(2*floorNum);
            f_mass_wall = facArea*f_wall_mass/massArea;
            f_wall_roof = Faux/(2*floorNum);
            f_roof_wall = facArea*f_wall_roof/1.;
            f_roof_mass = sqrt(far^2+1)-far;
            f_mass_roof = 1.*f_roof_mass/massArea;
            % -------------------------------------------------------------
            % Building energy demand
            % -------------------------------------------------------------
            zac_in_roof  = 0.948;
            obj.sensCoolDemand = wallArea*zac_in_wall*(wall.layerTemp(iwall)-coolsetpoint)+...
                massArea*zac_in_mass*(mass.layerTemp(1)-coolsetpoint)+...
                winArea*window.uValue*(urbanArea.canTemp-coolsetpoint)+...
                zac_in_roof *(roof.layerTemp(iroof)-coolsetpoint)+...
                obj.intHeat *(1-obj.intHeatFRad)*(1-obj.intHeatFLat)+...
                volInfil*dens*parameter.cp*(urbanArea.canTemp-coolsetpoint)+...
                volVent*dens*parameter.cp*(urbanArea.canTemp-coolsetpoint);
            obj.sensHeatDemand=-(wallArea*zac_in_wall*(wall.layerTemp(iwall)-heatsetpoint)+...
                massArea*zac_in_mass*(mass.layerTemp(1)-heatsetpoint)+...
                winArea*window.uValue*(urbanArea.canTemp-heatsetpoint)+...
                zac_in_roof*(roof.layerTemp(iroof)-heatsetpoint)+...
                obj.intHeat*(1-obj.intHeatFRad)*(1-obj.intHeatFLat)+...
                volInfil*dens*parameter.cp*(urbanArea.canTemp-heatsetpoint)+...
                volVent*dens*parameter.cp*(urbanArea.canTemp-heatsetpoint));
            % -------------------------------------------------------------
            % HVAC system
            % -------------------------------------------------------------
            % Mixing conditions
            zxmix  = volVent*dens/obj.mSys;
            zt_mix = zxmix*urbanArea.canTemp +(1.-zxmix)*obj.indoorTemp;
            zq_mix = zxmix*urbanArea.canHum +(1.-zxmix)*obj.indoorHum;
            % -------------------------------------------------------------
            %     Cooling system
            % -------------------------------------------------------------
            if(obj.sensCoolDemand >= 0.0)
                % supply air temperature
                pt_sys = zt_mix - obj.sensCoolDemand/obj.mSys/parameter.cp;
                % Supply specific humidity (assuming RH90%)
                pq_sys = min(0.62198 * 0.9 * psat(pt_sys,parameter) /...
                    (pres-0.9 * psat(pt_sys,parameter)),zq_mix);
                % Dehumidification energy
                obj.dehumDemand = obj.mSys*parameter.lv*(zq_mix-pq_sys);
                % cooling energy consumption
                obj.coolConsump  =(max(obj.sensCoolDemand+obj.dehumDemand,0))/ obj.cop;
                % waste heat
                if strcmp(obj.condType,'AIR')
                  obj.sensWaste = max(obj.sensCoolDemand+obj.dehumDemand,0)+obj.coolConsump;
                  obj.latWaste = 0.0;
                elseif strcmp(obj.condType,'WAT')
                  obj.sensWaste = max(obj.sensCoolDemand+obj.dehumDemand,0)+obj.coolConsump*(1.-evapEff);
                  obj.latWaste = max(obj.sensCoolDemand+obj.dehumDemand,0)+obj.coolConsump*evapEff;
                end
                % heating consumption
                obj.sensHeatDemand = 0.0;
                obj.heatConsump = 0.0;
            % -------------------------------------------------------------    
            %     Heating system
            % -------------------------------------------------------------
            elseif(obj.sensHeatDemand > 0.0) ;
                pt_sys = zt_mix + obj.sensHeatDemand/obj.mSys/parameter.cp;
                pq_sys = zq_mix;
                obj.heatConsump  = obj.sensHeatDemand / obj.heatEff;
                obj.sensWaste = obj.heatConsump - obj.sensHeatDemand;
                obj.latWaste = 0.0;
                obj.sensCoolDemand = 0.0;
                obj.coolConsump = 0.0;
                obj.dehumDemand = 0.0;
            else
                pt_sys = zt_mix;
                pq_sys = zq_mix;
                obj.sensCoolDemand = 0.0;
                obj.sensHeatDemand = 0.0;
                obj.coolConsump  = 0.0;
                obj.heatConsump  = 0.0;
                obj.sensWaste = 0.0;
                obj.latWaste = 0.0;
                obj.dehumDemand  = 0.0;
            end
            obj.sensWaste = obj.sensWaste*urbanArea.bldDensity;
            obj.latWaste = obj.latWaste*urbanArea.bldDensity;
            % -------------------------------------------------------------
            % Evolution of the internal temperature and humidity
            % -------------------------------------------------------------
            obj.indoorTemp = obj.indoorTemp +simParam.dt/(dens * parameter.cp * urbanArea.bldHeight) *(...
                wallArea * zac_in_wall *(wall.layerTemp(iwall) - obj.indoorTemp)+...
                massArea * zac_in_mass *(mass.layerTemp(1) - obj.indoorTemp)+...
                winArea  * window.uValue *(urbanArea.canTemp - obj.indoorTemp)+...
                zac_in_roof *(roof.layerTemp(iroof) - obj.indoorTemp)+...
                obj.intHeat *(1 - obj.intHeatFRad) *(1 - obj.intHeatFLat)+...
                volInfil * dens * parameter.cp *(urbanArea.canTemp - obj.indoorTemp)+...
                obj.mSys * parameter.cp * (pt_sys - obj.indoorTemp));
            obj.indoorHum = obj.indoorHum +simParam.dt/(dens * parameter.lv * urbanArea.bldHeight) *(...
                obj.intHeat * obj.intHeatFLat + volInfil * dens * parameter.lv *(urbanArea.canHum - obj.indoorHum)+...
                obj.mSys * parameter.lv *(pq_sys - obj.indoorHum));
            % -------------------------------------------------------------
            % Heat fluxes from indoor to surfaces
            % -------------------------------------------------------------
            obj.fluxWall  = zac_in_wall *(obj.indoorTemp - wall.layerTemp(iwall))+...
                radHTC * f_wall_mass *(mass.layerTemp(1) - wall.layerTemp(iwall))+...
                radHTC * f_wall_roof *(roof.layerTemp(iroof) - wall.layerTemp(iwall));
            obj.fluxRoof  = zac_in_roof *(obj.indoorTemp - roof.layerTemp(iroof))+...
                radHTC * f_roof_mass *(mass.layerTemp(1) - roof.layerTemp(iroof))+...
                radHTC * f_roof_wall *(wall.layerTemp(iwall)- roof.layerTemp(iroof));
            obj.fluxMass  = zac_in_mass *(obj.indoorTemp - mass.layerTemp(1))+...
                radHTC * f_mass_wall *(wall.layerTemp(iwall)- mass.layerTemp(1))+...
                radHTC * f_mass_roof *(roof.layerTemp(iroof)- mass.layerTemp(1))+...
                obj.intHeat * obj.intHeatFRad *(1.-obj.intHeatFLat)/ massArea +...
                winTrans / massArea;
        end
    end
end

