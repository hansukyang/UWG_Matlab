classdef UrbanUsage
    %URBANAREA Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        frac;          % vector of fractions of urban configurations
        urbanConf;     % vector of urban configurations
    end
    
    methods
        function obj = UrbanUsage(frac,urbanConf)
            % class constructor
            if(nargin > 0)
                if ne(numel(frac),numel(urbanConf))
                    disp('-----------------------------------------')
                    disp('ERROR: the number of fractions must match')
                    disp('the number of urban configurations');
                    disp('-----------------------------------------')
                else
                    obj.frac = frac;
                    obj.urbanConf = urbanConf;
                end
            end
        end
    end
end