function [Tdb, w, phi, h, Tdp, v] = Psychrometrics (Tdb_in, w_in, P)
% Modified version of Psychometrics by Tea Zakula
% November 16, 2012
% Massachusetts Institute of Technology Building Technology Lab
% VARIABLES (2 needed as input)
% Tdb (dry bulb temperature) and Tdp(dew point temperature) in C
% w (humidity ratio) in kg/kg of dry air
% phi (relative humidity) in %
% h (enthalpy) in J/kg of dry air
% v (specific volume) in m3/kg of dry air
% P (Atmospheric Station Pressure) in Pa

c_air = 1006; %J/kg, value from ASHRAE Fundamentals
hlg = 2501000; %J/kg, value from ASHRAE Fundamentals
cw  = 1860; %J/kg, value from ASHRAE Fundamentals
% P = 101.325; %kPa, value from ASHRAE Fundamentals

P = P/1000; % convert from Pa to kPa

options = optimset('LargeScale','off','Display','off');

%++++++++++++++++++++++++++++++++++++++

Tdb = Tdb_in;
w = w_in;

% phi calculation from Tdb and w
Pw = w*P/(0.621945+w); %partial pressure of water wapor
Pws = Saturation_pressure(Tdb);
phi = Pw/Pws*100;

% enthalpy calculation from Tdb and w
h = c_air*Tdb+w*(hlg+cw*Tdb);

% specific volume calculation from Tdb and w
v = 0.287042*(Tdb+273.15)*(1+1.607858*w)/P;

%++++++++++++++++++++++++++++++++++++++

% dew point calculation from w
pw = (P*w)/(0.621945+w); % water vapor partial pressure in kPa
alpha = log(pw);
Tdp = 6.54 + 14.526*alpha+0.7389*(alpha^2)+0.09486*(alpha^3)+0.4569*(pw^0.1984); % valid for Tdp between 0 C and 93 C

% if phi>100   
%     Tdb = NaN;
%     w   = NaN;
%     phi = NaN;
%     h   =  NaN;
%     Tdp = NaN;
%     v   = NaN; 
%     
%     disp('ERROR: Point is outside the chart')
% end

    function [Pws] = Saturation_pressure(Tdb)
        T = Tdb+273.15;
        Pws = exp(-(5.8002206e3)/T+1.3914993+-(4.8640239e-2)*T+(4.1764768e-5)*(T^2)-(1.4452093e-8)*(T^3)+6.5459673*log(T)); %in Pa
        Pws = Pws/1000; % in kPa
    end
%     function result = Iteration_function_1(y)
%         Tdb_as   = y(1);
%         % phi calculation from Tdb and w
%         Pw = w*P/(0.621945+w); %partial pressure of water wapor
%         Pws = Saturation_pressure(Tdb_as);
%         phi_as = Pw/Pws*100;
%         % equation to satisfy
%         result = phi_as-phi;
%     end
%     function result = Iteration_function_2(y)
%         Tdb_as   = y(1);
%         % w calculation from Tdb and phi
%         Pws = Saturation_pressure(Tdb_as);
%         Pw = phi/100*Pws;
%         w_as = 0.621945*Pw/(P-Pw);
%         % h calculation from Tdb and w
%         h_as = c_air*Tdb_as+w_as*(hlg+cw*Tdb_as);
%         % equation to satisfy
%         result = h_as-h;
%     end

end