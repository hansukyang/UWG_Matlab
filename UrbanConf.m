classdef UrbanConf
    %URBANAREA Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        building;      % 
        mass;          %
        wall;          %
        roof;          %
        road;          %
        canWallLWCoef; % canyon-wall radiation heat transfer coefficient (W m-2 K)
        canRoadLWCoef; % canyon-road radiation heat transfer coefficient (W m-2 K)        
    end
    
    methods
        function obj = UrbanConf(building,mass,wall,roof,road)
            % class constructor
            if(nargin > 0)
                    obj.building = building;
                    obj.mass = mass;
                    obj.wall = wall;
                    obj.roof = roof;
                    obj.road = road;
            end
        end
    end
end