classdef Block
     properties
            city;           % City Name
            name;           % District name
            time;           % Time vector
            frac;           % Percentage of the configurations
            CommPer;        % Percentage of Commercial
            month;          % Month
            
            MassT;          % Mass node temperature (vector)
            MassQ;          % Mass node heat flux

            RoofT;          % Roof node temperature (vector)
            RoofA;          % Roof node absorbed solar radiation
            RoofR;          % Roof node received solar radiation
            RoofQ;          % Roof node heat flux

            WallT;          % Wall node temperature (vector)
            WallA;          % Wall node absorbed solar radiation
            WallR;          % Wall node received solar radiation
            WallQ;          % Wall node heat flux

            RoadT;          % Wall node temperature (vector)
            RoadA;          % Wall node absorbed solar radiation
            RoadR;          % Wall node received solar radiation
            RoadQ;          % Wall node heat flux
            
            canTemp;        % same as the UrbanArea/urbanVars class
            coolConsump;    % cooling energy consumption
            heatConsump;    % heating energy consumption
            ublTemp;
            sensHeat;
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

            obj.MassQ (index) = uConf.building.fluxMass;    	% mass surface heat flux (W m-2)
            obj.MassT (index,:) = uConf.mass.layerTemp;         % vector of layer temperatures (K)
            obj.coolConsump (index,:) = uConf.building.coolConsump;   % cooling energy consumption
            obj.heatConsump (index,:) = uConf.building.coolConsump;   % cooling energy consumption

            obj.RoadT (index,:) = uConf.road.layerTemp;         % vector of layer temperatures (K)
            obj.RoadA (index,:) = uConf.road.solAbs;            % vector of layer temperatures (K)
            obj.RoadR (index,:) = uConf.road.solRec;            % vector of layer temperatures (K)

            obj.RoofT (index,:) = uConf.roof.layerTemp;         % vector of layer temperatures (K)
            obj.RoofA (index) = uConf.roof.solAbs;              % solar radiation absorbed (W m-2)
            obj.RoofR (index) = uConf.roof.solRec;              % solar radiation received (W m-2)
            obj.RoofQ (index) = uConf.building.fluxRoof;        % roof surface heat flux (W m-2)

            obj.WallT (index,:) = uConf.wall.layerTemp;         % vector of layer temperatures (K)
            obj.WallA (index) = uConf.wall.solAbs;              % solar radiation absorbed (W m-2)
            obj.WallR (index) = uConf.wall.solRec;              % solar radiation received (W m-2)
            obj.WallQ (index) = uConf.building.fluxWall;        % wall surface heat flux (W m-2)
            
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