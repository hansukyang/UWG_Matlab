function W = HumFromRHumTemp(RH,T,P)

% Saturation vapour pressure from ASHRAE
C8=-5.8002206E3; C9=1.3914993; C10=-4.8640239E-2; C11=4.1764768E-5;
C12=-1.4452093E-8; C13=6.5459673;
T=T+273.15;
PWS = exp(C8/T+C9+C10*T+C11*T^2+C12*T^3+C13*log(T));

% Vapour pressure
 PW=RH*PWS/100;

% 4. Specific humidity
W = 0.62198*PW/(P-PW);

end