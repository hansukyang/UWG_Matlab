function SAS = testSA(lon)
    SAS = zeros (24,1);
    hours = 1:1:24;
    
    for i = 1:24
        SAS (i) = value(7,1,i,lon);
    end
    plot(hours,SAS,'ro');
    title('Solar Hour Angle (lon = -110)');
    xlabel('Time of Day');
    ylabel('Degrees');
    grid;
end

function SA = value (month,day,hour,lon)

    inobis = [0,31,59,90,120,151,181,212,243,273,304,334];
    
    % universal time
    ut  = mod( 24.0+mod(hour,24.0),24.0 );
    ibis = inobis;
    
    for JI=2:12
      ibis(JI) = inobis(JI)+1;
    end
    
    % Julian day of the year
    date = day + inobis(month) - 1;
    % angular Julian day of the year
    a1 = (1.00554*date- 6.28306)*(pi/180.0);
    a2 = (1.93946*date+23.35089)*(pi/180.0);
    tsider = (7.67825*sin(a1)+10.09176*sin(a2)) / 60.0;
    % azimuthal angle
    % change angle units
    zlon = lon*(pi/180.);
    % true (absolute) Universal Time
    ztut = ut - tsider + zlon*((180./pi)/15.0);
    % hour angle in radians
    solang = (ztut-12.0)*15.0*(pi/180.);
    SA = solang*180/pi;

end
