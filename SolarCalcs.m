function [rural,urbanArea,urbanUsage] = SolarCalcs(urbanArea,urbanUsage,...
              simParam,refSite,forc,parameter,rural)

    horSol = forc.dir + forc.dif;
    rural.solRec = horSol;       
    
    for i = 1:numel(urbanArea)
        % vegetation shadowing
        if lt(simParam.month,parameter.vegStart) || gt(simParam.month,parameter.vegEnd)
            shadp = 0;
        else
            shadp = urbanArea(i).roadShad;
        end
        
        % solar angles
        [tanzen,critOrient] = SolarAngles(urbanArea(i).canAspect,simParam.month,...
        simParam.day,simParam.secDay,simParam.inobis,refSite.lon,refSite.lat);
        % sky model
    %     [dir,dif] = SkyModel(forc.dir,forc.dif,atan(tanzen));
        dir = forc.dir;
        dif = forc.dif;
        
        % solar direct and diffuse
        roadSol = (1-shadp)*(dir*(2*critOrient/pi-...
                  (2/pi*urbanArea(i).canAspect*tanzen)*(1-cos(critOrient)))+...
                  urbanArea(i).roadConf*dif);
        bldSol = (1-shadp)*(dir*(1/urbanArea(i).canAspect*(0.5-critOrient/pi)+...
                  1/pi*tanzen*(1-cos(critOrient)))+urbanArea(i).wallConf*dif);
              
        % solar reflections      
        rr = (1-urbanArea(i).roadAbsor)*roadSol;
        rw = (1-urbanArea(i).facAbsor)*bldSol;
        mr = (rr+(1-urbanArea(i).roadConf)*(1-urbanArea(i).roadAbsor)*...
            (rw+urbanArea(i).wallConf*(1-urbanArea(i).facAbsor)*rr))/...
            (1-(1-2*urbanArea(i).wallConf)*(1-urbanArea(i).facAbsor)+...
            (1-urbanArea(i).roadConf)*urbanArea(i).wallConf*(1-urbanArea(i).roadAbsor)*(1-urbanArea(i).facAbsor));
        mw = (rw+urbanArea(i).wallConf*(1-urbanArea(i).facAbsor)*rr)/...
            (1-(1-2*urbanArea(i).wallConf)*(1-urbanArea(i).facAbsor)+...
            (1-urbanArea(i).roadConf)*urbanArea(i).wallConf*(1-urbanArea(i).roadAbsor)*(1-urbanArea(i).facAbsor));
        
        % receiving solar
        for j = 1:numel(urbanUsage(i).urbanConf)
            urbanUsage(i).urbanConf(j).roof.solRec  = horSol;
            urbanUsage(i).urbanConf(j).road.solRec = roadSol+(1-urbanArea(i).roadConf)*mw;
            urbanUsage(i).urbanConf(j).wall.solRec = bldSol+(1-2*urbanArea(i).wallConf)*mw+urbanArea(i).wallConf*mr;
        end
        
        % high vegetation
        urbanArea(i).treeSensHeat = (1-parameter.vegAlbedo)*(1-parameter.treeFLat)*shadp*horSol;
        urbanArea(i).treeLatHeat = (1-parameter.vegAlbedo)*parameter.treeFLat*shadp*horSol;
    end

end
