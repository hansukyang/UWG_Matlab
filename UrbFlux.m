function [urbanArea,ublVars,urbanUsage,forc] = UrbFlux(urbanArea,ublVars,...
        urbanUsage,forc,parameter,simParam,refSite)

    urbanArea.sensHeat = 0.;
    urbanArea.latHeat = 0.;
    urbanArea.sensAnthropTot = 0.;
    urbanArea.latAnthropTot = 0.;
    [ublVars.ublEmis,ublVars.atmTemp,urbanArea.canEmis] = InfraCalcsAir(ublVars.ublTemp,...
        ublVars.atmTemp,urbanArea.bldHeight,urbanArea.canWidth,urbanArea.canHum,urbanArea.canTemp,refSite.ublPres,forc,parameter);
    urbanArea.canSkyLWCoef  = 4.*urbanArea.canEmis*parameter.sigma*((forc.skyTemp+urbanArea.canTemp)/2)^3.;
    ublVars.surfTemp = 0.;
    
    for j = 1:numel(urbanUsage.urbanConf)
        %lw calculations
        urbanUsage.urbanConf(j).canWallLWCoef  = 4.*urbanArea.canEmis*urbanUsage.urbanConf(j).wall.emissivity*parameter.sigma*((urbanUsage.urbanConf(j).wall.layerTemp(1)+urbanArea.canTemp)/2)^3.;
        urbanUsage.urbanConf(j).canRoadLWCoef  = 4.*urbanArea.canEmis*urbanUsage.urbanConf(j).road.emissivity*parameter.sigma*((urbanUsage.urbanConf(j).road.layerTemp(1)+urbanArea.canTemp)/2)^3.;
        [urbanUsage.urbanConf(j).road,urbanUsage.urbanConf(j).wall,...
            urbanUsage.urbanConf(j).roof] = InfraCalcs(urbanArea,...
        forc,urbanUsage.urbanConf(j).building.glazingRatio,...
        urbanUsage.urbanConf(j).road,urbanUsage.urbanConf(j).wall,...
        urbanUsage.urbanConf(j).roof,parameter,...
        urbanUsage.urbanConf(j).canWallLWCoef,urbanUsage.urbanConf(j).canRoadLWCoef);
        % builidng energy model
        urbanUsage.urbanConf(j).building = BuildingEnergyModel(urbanUsage.urbanConf(j).building,...
            urbanArea,urbanUsage.urbanConf(j).roof,urbanUsage.urbanConf(j).wall,...
            urbanUsage.urbanConf(j).building,urbanUsage.urbanConf(j).mass,forc.pres,parameter,simParam );
        % mass
        urbanUsage.urbanConf(j).mass.layerTemp = TransientConduction(urbanUsage.urbanConf(j).mass.layerTemp,...
            simParam.dt,urbanUsage.urbanConf(j).mass.layerVolHeat,urbanUsage.urbanConf(j).mass.layerThermalCond,...
            urbanUsage.urbanConf(j).mass.layerThickness,urbanUsage.urbanConf(j).building.fluxMass,1,forc.deepTemp,0.);
        % roof
        urbanUsage.urbanConf(j).roof = SurfFlux( urbanUsage.urbanConf(j).roof,...
            forc,parameter,simParam,forc.hum,ublVars.ublTemp,...
            forc.wind,1,urbanUsage.urbanConf(j).building.fluxRoof);
        % wall
        urbanUsage.urbanConf(j).wall = SurfFlux( urbanUsage.urbanConf(j).wall,...
            forc,parameter,simParam,urbanArea.canHum,urbanArea.canTemp,...
            forc.wind,1,urbanUsage.urbanConf(j).building.fluxWall);
        % road
        urbanUsage.urbanConf(j).road = SurfFlux( urbanUsage.urbanConf(j).road,...
            forc,parameter,simParam,urbanArea.canHum,urbanArea.canTemp,...
            urbanArea.canWind,2,0.);
        % surface temperature
        ublVars.surfTemp = ublVars.surfTemp +...
            urbanUsage.frac(j)*urbanUsage.urbanConf(j).roof.layerTemp(1)*urbanArea.bldDensity+...
            urbanUsage.frac(j)*urbanUsage.urbanConf(j).road.layerTemp(1)*(1-urbanArea.bldDensity)*(1-urbanArea.canEmis);
        % urban sensible heat flux
        urbanArea.sensHeat  = urbanArea.sensHeat +...
            urbanUsage.frac(j)*urbanUsage.urbanConf(j).roof.sens*urbanArea.bldDensity +...
            urbanUsage.frac(j)*urbanUsage.urbanConf(j).road.sens*(1-urbanArea.bldDensity) +...
            urbanUsage.frac(j)*urbanUsage.urbanConf(j).wall.sens*urbanArea.verToHor +...
            urbanUsage.frac(j)*urbanUsage.urbanConf(j).building.sensWaste;
        % urban latent heat flux
        urbanArea.latHeat  = urbanArea.latHeat +...
            urbanUsage.frac(j)*urbanUsage.urbanConf(j).roof.lat*urbanArea.bldDensity +...
            urbanUsage.frac(j)*urbanUsage.urbanConf(j).road.lat*(1-urbanArea.bldDensity) +...
            urbanUsage.frac(j)*urbanUsage.urbanConf(j).wall.lat*urbanArea.verToHor +...
            urbanUsage.frac(j)*urbanUsage.urbanConf(j).building.latWaste;
        % urban sensible anthropogenic heat flux
        urbanArea.sensAnthropTot  = urbanArea.sensAnthropTot +...
            urbanUsage.frac(j)*urbanUsage.urbanConf(j).building.intHeat*urbanArea.bldDensity +...
            urbanUsage.frac(j)*urbanUsage.urbanConf(j).building.heatConsump*urbanArea.bldDensity +...
            urbanUsage.frac(j)*urbanUsage.urbanConf(j).building.coolConsump*urbanArea.bldDensity;
    end
    % surface temperature
    ublVars.surfTemp = ublVars.surfTemp + urbanArea.canTemp*(1-urbanArea.bldDensity)*urbanArea.canEmis;
    % advection heat flux
    forDens = 0;
    intAdv1 = 0;
    intAdv2 = 0;
    for iz=1:refSite.nzfor
        forDens = forDens +...
            refSite.densityProfC(iz)*refSite.dz(iz)/...
            (refSite.z(refSite.nzfor)+refSite.dz(refSite.nzfor)/2);
      intAdv1 = intAdv1 + refSite.windProf(iz)*refSite.tempProf(iz)*refSite.dz(iz);
      intAdv2 = intAdv2 + refSite.windProf(iz)*refSite.dz(iz);
    end
    % parlength = ublVars.paralLength
    % forcdens = forDens
    % intadv1 = intAdv1
    % intadv2 = intAdv2
    % urbarea = urbanArea.urbArea
    ublVars.advHeat = ublVars.paralLength*parameter.cp*forDens*(intAdv1-ublVars.ublTemp*intAdv2)/ublVars.urbArea;
    % net LW radiation heat flux
    ublVars.radHeat = 4.*ublVars.ublEmis*parameter.sigma*((ublVars.atmTemp+ublVars.ublTemp)/2)^3*(ublVars.atmTemp-ublVars.ublTemp)+...
        4.*ublVars.ublEmis*parameter.sigma*((ublVars.surfTemp+ublVars.ublTemp)/2)^3*(ublVars.surfTemp-ublVars.ublTemp);
    % urban sensible heat flux
    urbanArea.sensHeat  = urbanArea.sensHeat +...
        urbanArea.sensAnthrop + urbanArea.treeSensHeat;
    % urban latent heat flux
    urbanArea.latHeat  = urbanArea.latHeat +...
        urbanArea.latAnthrop + urbanArea.treeLatHeat;
    % urban sensible anthropogenic heat flux
    urbanArea.sensAnthropTot  = urbanArea.sensAnthropTot+urbanArea.sensAnthrop;
    % urban latent anthropogenic heat flux
    urbanArea.latAnthropTot  = urbanArea.latAnthropTot+urbanArea.latAnthrop;
    % Urban blending height
    zrUrb = 2.0*urbanArea.bldHeight;
    % Reference height
    zref = refSite.z(refSite.nzref);
    % Reference wind speed
    windUrb = forc.wind*log(zref/refSite.z0r)/log(parameter.windHeight/refSite.z0r)*...
        log(zrUrb/urbanArea.z0u)/log(zref/urbanArea.z0u);
    % Friction velocity
    urbanArea.ustar = parameter.vk*windUrb/log((zrUrb-urbanArea.disp)/urbanArea.z0u);
    % Canyon density
    dens = Density(urbanArea.canTemp,urbanArea.canHum,forc.pres);
    % Convective scaling velocity)
    wstar = (parameter.g*max(urbanArea.sensHeat,0)*zref/dens/parameter.cp/urbanArea.canTemp)^(1/3);
    % Modified friction velocity
    urbanArea.ustarMod = max(urbanArea.ustar,wstar);
    % Exchange velocity
    urbanArea.uExch = parameter.exCoeff*urbanArea.ustarMod;

    % Canyon wind speed, Eq. 27 Chp. 3 Hanna and Britter, 2002, assuming 
    % CD = 1 and lambda_f = verToHor/4
    urbanArea.canWind = urbanArea.ustarMod*(urbanArea.verToHor/8)^(-1/2);

    % Canyon turbulent velocities
    urbanArea.turbU = 2.4*urbanArea.ustarMod;
    urbanArea.turbV = 1.9*urbanArea.ustarMod;
    urbanArea.turbW = 1.3*urbanArea.ustarMod;
    
    % Urban wind profile
    urbanArea.windProf = ones(1,refSite.nzref);
    for iz=1:refSite.nzref
        urbanArea.windProf(iz) = urbanArea.ustar/parameter.vk*...
        log((refSite.z(iz)+urbanArea.bldHeight-urbanArea.disp)/urbanArea.z0u);
    end
end
