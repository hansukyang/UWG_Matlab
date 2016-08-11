function [tanzen,theta0] = SolarAngles (canAspect,month,day,secDay,inobis,lon,lat)

    % universal time
    ut  = mod( 24.0+mod(secDay/3600.,24.0),24.0 );
    ibis = inobis;
    for JI=2:12
      ibis(JI) = inobis(JI)+1;
    end
    % Julian day of the year
    date = day + inobis(month) - 1;
    % angular Julian day of the year
    ad = 2.0*pi*date/365.0;
    % ancillary variables
    a1 = (1.00554*date- 6.28306)*(pi/180.0);
    a2 = (1.93946*date+23.35089)*(pi/180.0);
    tsider = (7.67825*sin(a1)+10.09176*sin(a2)) / 60.0;
    % daily solar declination angle
    decsol = 0.006918-0.399912*cos(ad)+0.070257*sin(ad)...
             -0.006758*cos(2.*ad)+0.000907*sin(2.*ad)...
             -0.002697*cos(3.*ad)+0.00148 *sin(3.*ad);
    % azimuthal angle
    sindel = sin(decsol);
    cosdel = cos(decsol);
    % change angle units
    zlat = lat*(pi/180.);
    zlon = lon*(pi/180.);
    % true (absolute) Universal Time
    ztut = ut - tsider + zlon*((180./pi)/15.0);
    % hour angle in radians
    solang = (ztut-12.0)*15.0*(pi/180.);
    % cosine of the zenithal solar angle
    coszen = sin(zlat)*sindel + cos(zlat)*cosdel*cos(solang);
    % zenith solar angle
    zenith = acos(coszen);
    % tangente of solar zenithal angle
    if (abs(0.5*pi-zenith) <  1.E-6)
        if(0.5*pi-zenith > 0.)  
            tanzen = tan(0.5*pi-1.E-6); 
        end
        if(0.5*pi-zenith <= 0.) 
            tanzen = tan(0.5*pi+1.E-6); 
        end
    elseif (abs(zenith) <  1.E-6)
        tanzen = sign(1.,zenith)*tan(1.E-6);
    else
        tanzen = tan(zenith);
    end
    % critical canyon angle for which solar radiation reaches the road
    theta0 = asin( min(abs( 1./tanzen)/canAspect, 1. ) );

end
