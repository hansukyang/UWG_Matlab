function autosizeCoolCap = Autosize(UCM,UBL,urbanConf,climate_data,rural,RSM,parameter)
    % ------------------------------------------------------------------------- 
    % This function autosizes the HVAC equipment based on July 15-20
    % weather data
    % ------------------------------------------------------------------------- 
    autosizeFactor = 1.2;
    autosizeCoolCap = 0.;

    % Simulation paramters
    simParamAs = SimParam(...
        300.,...            % Simulation time-step
        3600.,...           % Weather data time-step
        7,...               % Begin month
        15,...              % Begin day of the month
        5);                 % Number of days of simulation
    weatherAs = Weather(climate_data,simParamAs.timeInitial,simParamAs.timeFinal);
    forc = Forcing(weatherAs.staTemp);

    % Friendly progress display...
    disp '==========================='
    fprintf('Autosize simulation: Urban Area %s\n',UBL.location);
    fprintf('Period: month %i from day %i to day %i\n', ...
        int16(simParamAs.month),int16(simParamAs.day),int16(simParamAs.day+simParamAs.days));
    fprintf('Autosize factor: %1.1f\n', autosizeFactor);
    fprintf('Internal Heat Night %1.2f W m-2(fl), Internal Heat Day %1.2f W m-2(fl)\n',...
        urbanConf.building.intHeatNight,urbanConf.building.intHeatDay);
    fprintf('Cooling Setpoint Day %1.2f K, Cooling Setpoint Night %1.2f K\n',...
        urbanConf.building.coolSetpointDay,urbanConf.building.coolSetpointNight);

    timeCount = 0.;
    for it=1:simParamAs.nt
        timeCount=timeCount+simParamAs.dt;
        simParamAs = UpdateDate(simParamAs);
        % read forcing
        if eq(mod(timeCount,simParamAs.timeForcing),0) || eq(timeCount,simParamAs.dt)
            if le(forc.itfor,simParamAs.timeMax/simParamAs.timeForcing)
                forc = ReadForcing(forc,weatherAs,parameter);
                % solar calculations
                urbanConf = SolarCalcsAutosize(UCM,urbanConf,...
                  simParamAs,RSM,forc,rural);
            end
        end
        % urban heat fluxes
        [UCM,UBL,urbanConf,forc,parameter] = UrbFluxAutosize(UCM,UBL,urbanConf,forc,parameter,simParamAs);
        % urban boundary layer temperature
        UBL.ublTemp = forc.temp;
        % max sens energy demand
        autosizeCoolCap = max(autosizeCoolCap,autosizeFactor*urbanConf.building.sensCoolDemand);
    end
    fprintf('> Cooling capacity: %1.2f W m-2(bld)\n',autosizeCoolCap);
    disp '==========================='
end


function [UCM,UBL,BEM,forc,parameter] = UrbFluxAutosize(UCM,UBL,BEM,forc,parameter,simTime)
    
    % This function is used for HVAC autosizing function only

    UCM.canTemp = forc.temp;
    UCM.canHum = forc.hum;
    [UBL.ublEmis,UBL.atmTemp,UCM.canEmis] = InfraCalcsAir(UBL.ublTemp,...
    UBL.atmTemp,UCM.bldHeight,UCM.canWidth,UCM.canHum,UCM.canTemp,forc.pres,forc,parameter);
    UCM.canSkyLWCoef  = 4.*UCM.canEmis*parameter.sigma*((forc.skyTemp+UCM.canTemp)/2)^3.;
    
    %lw calculations
    [BEM.road,BEM.wall,BEM.roof] = InfraCalcs(UCM,...
        forc,BEM.building.glazingRatio,BEM.road,BEM.wall,...
        BEM.roof,parameter,0,0);

    % Builidng energy model
    BEM.building = BEMCalc(BEM.building,UCM,BEM,forc.pres,parameter,simTime );

    % mass
    BEM.mass.layerTemp = Conduction(BEM.mass,...
        simTime.dt,BEM.building.fluxMass,1,forc.deepTemp,0.);

    % roof
    BEM.roof = SurfFlux(BEM.roof,forc,parameter,simTime,forc.hum,UBL.ublTemp,...
        forc.wind,1,BEM.building.fluxRoof);

    % wall
    BEM.wall = SurfFlux(BEM.wall,forc,parameter,simTime,UCM.canHum,UCM.canTemp,...
        forc.wind,1,BEM.building.fluxWall);

    % road
    BEM.road = SurfFlux(BEM.road,forc,parameter,simTime,UCM.canHum,UCM.canTemp,...
        UCM.canWind,2,0.);
end

function BEM = SolarCalcsAutosize(UCM,BEM,simParam,RSM,forc,rural)
 
    horSol = forc.dir + forc.dif;
    facAbsor = (1-BEM.building.glazingRatio)*(1-BEM.wall.albedo)+...
                BEM.building.glazingRatio*(1-0.75*BEM.building.shgc);
    roadAbsor = (1-BEM.road.vegCoverage)*(1-BEM.road.albedo)+...
                BEM.road.vegCoverage*(1-rural.albedo);
    % vegetation shadowing
    shadp = 0;
    % solar angles
    [tanzen,critOrient] = SolarAngles(UCM.canAspect,simParam.month,...
        simParam.day,simParam.secDay,simParam.inobis,RSM.lon,RSM.lat);
    % solar direct and diffuse
    roadSol = (1-shadp)*(forc.dir*(2*critOrient/pi-...
              (2/pi*UCM.canAspect*tanzen)*(1-cos(critOrient)))+...
              UCM.roadConf*forc.dif);
    bldSol = (1-shadp)*(forc.dir*(1/UCM.canAspect*(0.5-critOrient/pi)+...
              1/pi*tanzen*(1-cos(critOrient)))+UCM.wallConf*forc.dif);
    % solar reflections      
    rr = (1-roadAbsor)*roadSol;
    rw = (1-facAbsor)*bldSol;
    mr = (rr+(1-UCM.roadConf)*(1-roadAbsor)*(rw+UCM.wallConf*(1-facAbsor)*rr))/...
        (1-(1-2*UCM.wallConf)*(1-facAbsor)+(1-UCM.roadConf)*UCM.wallConf*(1-roadAbsor)*(1-facAbsor));
    mw = (rw+UCM.wallConf*(1-facAbsor)*rr)/(1-(1-2*UCM.wallConf)*(1-facAbsor)+...
        (1-UCM.roadConf)*UCM.wallConf*(1-roadAbsor)*(1-facAbsor));
    % receiving solar
    BEM.roof.solRec  = horSol;
    BEM.road.solRec = roadSol+(1-UCM.roadConf)*mw;
    BEM.wall.solRec = bldSol+(1-2*UCM.wallConf)*mw+UCM.wallConf*mr;
end

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
