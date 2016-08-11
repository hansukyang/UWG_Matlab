classdef Block
     properties
            city;           % City Name
            name;           % District name
            time;           % Time vector
            frac;           % Percentage of the configurations
            CommPer;        % Percentage of Commercial
            month;          % Month
            
            MassT;          % Mass node temperature (vector)
            MassQin;        % Mass node heat flux (indoor)
            Q_Internal;      % Internal heat gain (lights, etc.)
            Q_Solar;          % solar heat gain (W m-2) through window (SHGC)
            Q_Window;         % heat gain/loss from window (U-value)
            Q_Interior;       % internal heat gain adjusted for latent/LW heat (W m-2)
            Q_Infil;          % heat flux from infiltration (W m-2)
            Q_HVAC;           % HVAC heat flux

            RoofT;          % Roof node temperature (vector)
            RoofA;          % Roof node absorbed solar radiation
            RoofR;          % Roof node received solar radiation
            RoofQex;        % Roof node heat flux (external)
            RoofQin;        % Roof node heat flux (indoor)
            
            WallT;          % Wall node temperature (vector)
            WallA;          % Wall node absorbed solar radiation
            WallR;          % Wall node received solar radiation
            WallQex;        % Wall node heat flux (external)
            WallQin;        % Wall node heat flux (indoor)

            RoadT;          % Wall node temperature (vector)
            RoadA;          % Wall node absorbed solar radiation
            RoadR;          % Wall node received solar radiation
            RoadQ;          % Wall node heat flux
            
            canTemp;        % same as the UCBEM/UBL class
            coolConsump;    % cooling energy consumption
            heatConsump;    % heating energy consumption
            ublTemp;        % UBL temperature
            sensHeat;       % 
            sensAnthropTot;
            advHeat;
            radHeat;
            indoorTemp;
            sensCoolDemand;
            
     end
          
     methods 
        function obj = Block (numStep,wall,roof,mass,road)
            if nargin > 0
                obj.time = zeros(numStep,1);
                WallT = zeros(numStep,numel(wall.layerTemp));
                RoofT = zeros(numStep,numel(roof.layerTemp));
                MassT = zeros(numStep,numel(mass.layerTemp));
                RoadT = zeros(numStep,numel(road.layerTemp));
                
                coolConsump = zeros (numStep,1);
                heatConsump = zeros (numStep,1);
                canTemp = zeros (numStep,1);
                ublTemp = zeros (numStep,1);
                sensHeat = zeros (numStep,1);
                sensAnthropTot = zeros (numStep,1);
                advHeat = zeros (numStep,1);
                radHeat = zeros (numStep,1);
                indoorTemp = zeros (numStep,1);
                sensCoolDemand = zeros (numStep,1);
            end
        end

        function obj = UpdateStrct(obj, uConf, tCount, index)
            
            obj.time (index) = tCount;
            obj.indoorTemp (index) = uConf.building.indoorTemp;
            obj.sensCoolDemand (index) = uConf.building.sensCoolDemand;

            obj.MassQin (index) = uConf.building.fluxMass;    	% mass surface heat flux (W m-2)
            obj.MassT (index,:) = uConf.mass.layerTemp;         % vector of layer temperatures (K)
            obj.coolConsump (index,:) = uConf.building.coolConsump;   % cooling energy consumption
            obj.heatConsump (index,:) = uConf.building.coolConsump;   % cooling energy consumption
            obj.Q_Internal (index,:) = uConf.building.intHeat;   % Building internal heat gain (W/m^2)

            obj.RoadT (index,:) = uConf.road.layerTemp;         % vector of layer temperatures (K)
            obj.RoadA (index,:) = uConf.road.solAbs;            % vector of layer temperatures (K)
            obj.RoadR (index,:) = uConf.road.solRec;            % vector of layer temperatures (K)
            obj.RoadQ (index,:) = uConf.road.sens;              % sensible heat flux (to urban canyon)
                        
            obj.RoofT (index,:) = uConf.roof.layerTemp;         % vector of layer temperatures (K)
            obj.RoofA (index) = uConf.roof.solAbs;              % solar radiation absorbed (W m-2)
            obj.RoofR (index) = uConf.roof.solRec;              % solar radiation received (W m-2)
            obj.RoofQin (index) = uConf.building.fluxRoof;      % roof surface heat flux (W m-2)
            obj.RoofQex (index,:) = uConf.road.sens;            % sensible heat flux (to urban canyon?)

            obj.WallT (index,:) = uConf.wall.layerTemp;         % vector of layer temperatures (K)
            obj.WallA (index) = uConf.wall.solAbs;              % solar radiation absorbed (W m-2)
            obj.WallR (index) = uConf.wall.solRec;              % solar radiation received (W m-2)
            obj.WallQin (index) = uConf.building.fluxWall;        % wall surface heat flux (W m-2)
            
            obj.Q_Solar (index) = uConf.building.fluxSolar;          % solar heat gain (W m-2) through window (SHGC)
            obj.Q_Window (index) = uConf.building.fluxWindow;         % heat gain/loss from window (U-value)
            obj.Q_Interior (index) = uConf.building.fluxInterior;       % internal heat gain adjusted for latent/LW heat (W m-2)
            obj.Q_Infil (index) = uConf.building.fluxInfil;          % heat flux from infiltration (W m-2)
            obj.Q_HVAC (index) = uConf.building.fluxHVAC;           % heat flux from HVAC airflow (W m-2)            
            
        end

        function obj = UpdateArea(obj, uArea, uVars, index)

            obj.canTemp (index) = uArea.canTemp;
            obj.ublTemp (index) = uVars.ublTemp;
            obj.sensHeat (index) = uArea.sensHeat;
            obj.sensAnthropTot (index) = uArea.sensAnthropTot;
            obj.advHeat (index) = uVars.advHeat;
            obj.radHeat (index) = uVars.radHeat;
        end

     end
end