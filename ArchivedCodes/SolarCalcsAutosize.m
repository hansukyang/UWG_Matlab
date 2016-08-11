function urbanConf = SolarCalcsAutosize(urbanArea,urbanConf,...
              simParam,refSite,forc,rural)
 
    horSol = forc.dir + forc.dif;
    facAbsor = (1-urbanConf.building.glazingRatio)*(1-urbanConf.wall.albedo)+...
                urbanConf.building.glazingRatio*(1-0.75*urbanConf.building.shgc);
    roadAbsor = (1-urbanConf.road.vegCoverage)*(1-urbanConf.road.albedo)+...
                urbanConf.road.vegCoverage*(1-rural.albedo);
    % vegetation shadowing
    shadp = 0;
    % solar angles
    [tanzen,critOrient] = SolarAngles(urbanArea.canAspect,simParam.month,...
    simParam.day,simParam.secDay,simParam.inobis,refSite.lon,refSite.lat);
    % solar direct and diffuse
    roadSol = (1-shadp)*(forc.dir*(2*critOrient/pi-...
              (2/pi*urbanArea.canAspect*tanzen)*(1-cos(critOrient)))+...
              urbanArea.roadConf*forc.dif);
    bldSol = (1-shadp)*(forc.dir*(1/urbanArea.canAspect*(0.5-critOrient/pi)+...
              1/pi*tanzen*(1-cos(critOrient)))+urbanArea.wallConf*forc.dif);
    % solar reflections      
    rr = (1-roadAbsor)*roadSol;
    rw = (1-facAbsor)*bldSol;
    mr = (rr+(1-urbanArea.roadConf)*(1-roadAbsor)*(rw+urbanArea.wallConf*(1-facAbsor)*rr))/...
        (1-(1-2*urbanArea.wallConf)*(1-facAbsor)+(1-urbanArea.roadConf)*urbanArea.wallConf*(1-roadAbsor)*(1-facAbsor));
    mw = (rw+urbanArea.wallConf*(1-facAbsor)*rr)/(1-(1-2*urbanArea.wallConf)*(1-facAbsor)+...
        (1-urbanArea.roadConf)*urbanArea.wallConf*(1-roadAbsor)*(1-facAbsor));
    % receiving solar
    urbanConf.roof.solRec  = horSol;
    urbanConf.road.solRec = roadSol+(1-urbanArea.roadConf)*mw;
    urbanConf.wall.solRec = bldSol+(1-2*urbanArea.wallConf)*mw+urbanArea.wallConf*mr;
 end