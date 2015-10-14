function [ublEmis,atmTemp,canEmis] = InfraCalcsAir(ublTemp,...
    atmTemp,bldHeight,canWidth,canHum,canTemp,refPres,forc,parameter)

% UBL emissivity
ublEmis = UblEmis(ublTemp,forc.rHum,refPres,parameter.nightBLHeight);
% upper UBL absorptivity
ublAbsUp = UblAbs(ublTemp,atmTemp,forc.rHum,refPres,parameter.nightBLHeight);
% atmospheric temperature
ublEmisFlux = parameter.sigma*ublTemp^4*ublEmis;
if ublEmisFlux>forc.infra || (1-ublAbsUp)<0.1
    atmTemp = (forc.infra/parameter.sigma)^0.25;
else
    atmTemp = ((forc.infra-ublEmisFlux)/(1-ublAbsUp)/parameter.sigma)^0.25;
end
% mean beam length (m)
le = 3.6*bldHeight*canWidth/(2*bldHeight+2*canWidth);
% vapor pressure in the canyon
ph2o = forc.pres*canHum/(canHum+0.62198);
% Saturation vapour pressure from ASHRAE
C8=-5.8002206E3; C9=1.3914993; C10=-4.8640239E-2; C11=4.1764768E-5;
C12=-1.4452093E-8; C13=6.5459673;
tg = canTemp;
ph2oSat = exp(C8/tg+C9+C10*tg+C11*tg^2+C12*tg^3+C13*log(tg));
% Relative humidity
rh=ph2o/ph2oSat*100;
% canyon air emissivity
canEmis = UblEmis(tg,rh,forc.pres,le);

end