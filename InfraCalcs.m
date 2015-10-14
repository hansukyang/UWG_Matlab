function [road,wall,roof] = InfraCalcs(urbanArea,...
    forc,glazingRatio,road,wall,roof,parameter,canWallLWCoef,canRoadLWCoef)

% view factors
roadWallConf =(1 - urbanArea.roadConf)*(1.-glazingRatio);
wallRoadConf = urbanArea.wallConf;
% lw heat transfer coefficients
roadWallLWCoef  = 4.*(1-urbanArea.canEmis)*wall.emissivity*road.emissivity*parameter.sigma*wallRoadConf*((wall.layerTemp(1)+road.layerTemp(1))/2)^3.;
wallRoadLWCoef  = 5*(1-urbanArea.canEmis)*wall.emissivity*road.emissivity*parameter.sigma*roadWallConf*((wall.layerTemp(1)+road.layerTemp(1))/2)^3;
skyWallLWCoef  = 4.*(1-urbanArea.canEmis)*wall.emissivity*parameter.sigma*urbanArea.wallConf*((forc.skyTemp+wall.layerTemp(1))/2)^3;
skyRoadLWCoef  = 4.*(1-urbanArea.canEmis)*road.emissivity*parameter.sigma*urbanArea.roadConf*((forc.skyTemp+road.layerTemp(1))/2)^3;
skyRoofLWCoef = 4.*roof.emissivity*parameter.sigma*((forc.skyTemp+roof.layerTemp(1))/2)^3;
% surface lw radiation
roof.infra = skyRoofLWCoef*(forc.skyTemp-roof.layerTemp(1));
wall.infra = skyWallLWCoef*(forc.skyTemp-wall.layerTemp(1))+...
             roadWallLWCoef*(road.layerTemp(1)-wall.layerTemp(1))+...
             canWallLWCoef*(urbanArea.canTemp-wall.layerTemp(1));
road.infra = skyRoadLWCoef*(forc.skyTemp-road.layerTemp(1))+...
             wallRoadLWCoef*(wall.layerTemp(1)-road.layerTemp(1))+...
             canRoadLWCoef*(urbanArea.canTemp-road.layerTemp(1));

% radTemp_calc = [urbanArea(1).canTemp forc.skyTemp roof.layerTemp(1) wall.layerTemp(1) road.layerTemp(1)]; %first temp is drybulb T
% dlmwrite('Trad.csv',radTemp_calc,'delimiter',',','-append');
end 