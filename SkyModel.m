function [dir,dif] = SkyModel(dir,dif,zen)
% Extracted from EP Engineering Reference, p. 142
% zen - solar zenith angle (rad)
% extraterrestrial irradiance
extIrrad = 1353;
kap = 1.041;
% air mass (Kasten and Young 1989)
m = 1/(cos(zen)+0.50572*(96.07995-180/pi*zen)^(-1.6364));
% horizontal irradiance
horIrrad = dif + dir*sin(pi/2-zen);
%  sky clearness factor
eps = ((horIrrad+dir)/horIrrad+kap*zen^3)/(1+kap*zen^3);
if eps<1.000
    F11 = 0.;
    F12 = 0.;
    F13 = 0.;
elseif eps<1.065
    F11 = -0.0083117;
    F12 = 0.5877285;
    F13 = -0.0620636;
elseif eps<1.230
    F11 = 0.1299457;
    F12 = 0.6825954;
    F13 = -0.1513752;
elseif eps<1.500
    F11 = 0.3296958;
    F12 = 0.4868735;
    F13 = -0.2210958;
elseif eps<1.950
    F11 = 0.5682053;
    F12 = 0.1874525;
    F13 = -0.2951290;
elseif eps<2.800
    F11 = 0.8730280;
    F12 = -0.3920403;
    F13 = -0.3616149;
elseif eps<4.500
    F11 = 1.1326077;
    F12 = -1.2367284;
    F13 = -0.4118494;
elseif eps<6.200
    F11 = 1.0601591;
    F12 = -1.5999137;
    F13 = -0.3589221;
else
    F11 = 0.6777470;
    F12 = -0.3272588;
    F13 = -0.2504286;
end
% sky brightness factor 
del = horIrrad*m/extIrrad;
% circumsolar brightening coefficient
F1 = F11+F12*del+F13*zen;
% irradiance on surface from circumsolar region
circIrrad = max(horIrrad*F1,0);
% updated diffuse horizontal
dif = max(dif-circIrrad,0);
% updated direct normal
b = max(0.87,cos(zen));
dir = max(dir+circIrrad/b,0);

end
