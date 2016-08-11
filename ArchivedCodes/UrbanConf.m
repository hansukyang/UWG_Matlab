classdef BEMDef
    %   Building Energy Model (BEM) class definition
    %   Updated to remove 'UrbanUsage.m', and use it as an arrage of class
    %   JY, March, 2016
    
    properties
        building;      % 
        mass;          %
        wall;          %
        roof;          %
        road;          %
        canWallLWCoef; % canyon-wall radiation heat transfer coefficient (W m-2 K)
        canRoadLWCoef; % canyon-road radiation heat transfer coefficient (W m-2 K)
        frac;          % fraction of the urban floor space of this typology
    end
    
    methods
        function obj = BEMDef(building,mass,wall,roof,road,frac)
            % class constructor
            if(nargin > 0)
                obj.building = building;
                obj.mass = mass;
                obj.wall = wall;
                obj.roof = roof;
                obj.road = road;
                obj.frac = frac;
            end
        end
    end
end