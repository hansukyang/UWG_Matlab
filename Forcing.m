classdef Forcing
    %FORCING Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        deepTemp;  % deep soil temperature (K)
        infra;
        wind;
        uDir;
        hum;
        pres;
        temp;
        rHum;
        prec;      % Precipitation (m s-1)
        dir;
        dif;
        dens;
        skyTemp;
        itfor;
    end
    
    methods
        function obj = Forcing(staTemp)
            obj.deepTemp = mean(staTemp);
            obj.itfor = 1;
        end
        
        function obj = ReadForcing(obj,weather,parameter)
              obj.infra = weather.staInfra(obj.itfor);
              minWind = max(weather.staUmod(obj.itfor),parameter.windMin);
              obj.wind = min(minWind,parameter.windMax);
              obj.uDir = weather.staUdir(obj.itfor);
              obj.hum  = weather.staHum(obj.itfor);
              obj.pres = weather.staPres(obj.itfor);
              obj.temp = weather.staTemp(obj.itfor);
              obj.rHum = weather.staRhum(obj.itfor);
              obj.dir = weather.staDir(obj.itfor);
              obj.dif = weather.staDif(obj.itfor);
              obj.prec = weather.staRobs(obj.itfor)/3.6e6;
              obj.dens = obj.pres/parameter.r/obj.temp;
              obj.skyTemp =(obj.infra/parameter.sigma)^0.25;
              obj.itfor = obj.itfor +1;
        end
    end
    
end

