classdef UblVars
    %URBANAREA Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        location;      % relative location within a city (N,NE,E,SE,S,SW,W,NW,C)
        charLength;    % characteristic length of the urban area (m)
        perimeter;     % urban area perimeter (m)
        urbArea;       % horizontal urban area (m2)
        orthLength;    % length of the side of the urban area orthogonal 
                       % to the wind direction (m)
        paralLength;   % length of the side of the urban area paralell 
                       % to the wind direction (m)
        ublTemp;       % urban boundary layer temperature (K)
        ublTempdx;     % urban boundary layer temperature discretization (K)
        ublEmis;       % UBL emissivity due to water vapor
        atmTemp;       % urban surface temperature (K)
        surfTemp;      % average surface temperature seen from the UBL (K)
        advHeat;       % advection heat flux (W m-2)
        radHeat;       % net radiation heat flux (W m-2)
    end
    
    methods
        function obj = UblVars(location,charLength,initialTemp,maxdx)
            % class constructor
            if(nargin > 0)
                obj.location = location;
                obj.charLength = charLength;
                obj.perimeter = 4*charLength;
                obj.urbArea = charLength^2.;
                obj.orthLength = charLength;
                numdx = round(charLength/min(charLength,maxdx));
                obj.paralLength = charLength/numdx;
                obj.ublTemp = initialTemp;
                obj.ublTempdx = initialTemp*ones(1,numdx);
                obj.atmTemp = initialTemp;
                obj.surfTemp = initialTemp;
            end
        end  

    end
    
end

