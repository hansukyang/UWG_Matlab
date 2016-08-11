% =========================================================================
%  THE URBAN WEATHER GENERATOR
% % Generate new EPW file
% =========================================================================
% Original Author: B. Bueno
% Packaged by J. Sullivan-Fedoc & modified by A. Nakano & Lingfu Zhang
% latest modification 2014-10-29
% 
% Simplified Model by Joseph Yang, 2015-11-13
% =========================================================================

fullyScripted = 1;
try
    climate_data = strcat(CL_EPW_PATH,'\',CL_EPW);
    epwPathName = CL_EPW_PATH;
    epwFileName = CL_EPW;
    [pathstr,name,ext] = fileparts(climate_data);
    epwFileExt = ext;
catch
    [epwFileName,epwPathName] = uigetfile('.epw','Select Rural EnergyPlus Weather File');
    climate_data = strcat(epwPathName,epwFileName);
    epwPathName = epwPathName(1:end-1);
    fullyScripted = 0;
end
disp(['Rural weather file selected: ',climate_data])

%% Read EPW file
epwid = fopen(climate_data);

delimiterIn = ',';
headerlinesIn = 8;
C = importdata(climate_data, delimiterIn, headerlinesIn);

for i = 1:8
    header(i) = C.textdata(i,1);
end
fclose all;
epwid = fopen(climate_data);

i = 1;
while 1
    readin = fgetl(epwid);   
    if readin == -1 break;end
    epwinput.values(i,:) = textscan(readin, '%s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %*[^\n]', 'delimiter',',','MultipleDelimsAsOne',1);
    i=i+1;
end

epwinput.values(1:8,:) = [];
fclose all;

%% Import Simulation Parameters
% XML import
try
    xml_location = strcat(CL_XML_PATH,'\',CL_XML);
catch
    [FileName,PathName] = uigetfile('.xml','Select Urban Parameter Input file');
    xml_location = strcat(PathName,FileName);
   
    fullyScripted = 0;
end
xml_input = xml_read(xml_location);
disp(['Urban Parameter file selected: ',xml_location]);

[pathstr,name,ext] = fileparts(xml_location);
xmlFileName = name;

% Create classes for ease of data manipulation
xmlTyp(1) = xml_input.typology1;
xmlTyp(2) = xml_input.typology2;
xmlTyp(3) = xml_input.typology3;
xmlTyp(4) = xml_input.typology4;
xmlParam = xml_input.parameter;
xmlUArea = xml_input.urbanArea;

% Save location
try
    new_climate_file = strcat(CL_RE_PATH,'\',CL_RE);
    newPathName = CL_RE_PATH;
    newFileName_withExt = CL_RE;
    
catch
    [newFileName_withExt,newPathName] = uiputfile('.epw','Select save location');
    new_climate_file = strcat(newPathName,newFileName_withExt);    
    newPathName = newPathName(1:end-1);
    fullyScripted = 0;
end

[new_pathstr,new_name,new_ext] = fileparts(new_climate_file);
newFileName = new_name;
disp(['Save location selected: ',new_climate_file]);

% Class housecleaning [deleted - not sure if this is needed]

%% Reconstruct xml Materials [deleted for now - see if there is a better way to do it]

%% Reconsruction for dividing up the material thickness

% Simulation paramters
simParam = SimParam(...
    300.,...                         % Simulation time-step
    3600,...                         % Weather data time-step
    xmlParam.simuStartMonth,...      % Begin month
    xmlParam.simuStartDay,...        % Begin day of the month
    xmlParam.simuDuration/365);      % Simulation duration (1day)
weather = Weather(climate_data,simParam.timeInitial,simParam.timeFinal);

%% Parameter Definition
nightSetStart =  0.25*(xmlTyp(1).building.nightSetStart+xmlTyp(2).building.nightSetStart+xmlTyp(3).building.nightSetStart+xmlTyp(4).building.nightSetStart);
nightSetEnd =  0.25*(xmlTyp(1).building.nightSetEnd+xmlTyp(2).building.nightSetEnd+xmlTyp(3).building.nightSetEnd+xmlTyp(4).building.nightSetEnd);

parameter = Param(xmlUArea.daytimeBLHeight,xmlUArea.nighttimeBLHeight,...
    xmlUArea.refHeight,xmlParam.tempHeight,xmlParam.windHeight,...
    1.2,200,50,...
    xmlUArea.treeLatent,xmlUArea.grassLatent,xmlUArea.vegAlbedo,...
    xml_input.urbanArea.vegStart,xml_input.urbanArea.vegEnd,...
    nightSetStart,nightSetEnd,...
    0.1,10,0.005,0.3,500,...
    9.81, 1004, 0.40, 287, 461.5, 2260000, pi(), 0.0000000567, 1000, 2500800, 273.16, 611.14, 4218,...
    1846.1, 9.4, 7.4, 1.09647471147);

% Define Wall (add feature to subdivide layer later)
for i = 1:4
    wallMat = [];
    materials = xmlTyp(i).construction.wall.materials;
    xwall = xmlTyp(i).construction.wall;
        
    if numel(materials.thickness) > 1
        for j = 1:numel(materials.thickness)
            wallMat = [wallMat Material(materials.thermalConductivity{j},materials.volumetricHeatCapacity{j})];
        end
    else
        materials.thickness = [materials.thickness/2 materials.thickness/2];
        wallMat = [Material(materials.thermalConductivity, materials.volumetricHeatCapacity) Material(materials.thermalConductivity, materials.volumetricHeatCapacity)]; ;
    end
    
    wall(i) = Element(xwall.albedo,xwall.emissivity,materials.thickness,wallMat,...
        xwall.vegetationCoverage,xwall.initialTemperature + 273.15,xwall.inclination);
end

%% Define Roof element
for i = 1:4
    roofMat = [];
    materials = xmlTyp(i).construction.roof.materials;
    xroof = xmlTyp(i).construction.roof;
    
    if numel(materials.thickness) > 1
        for j = 1:numel(materials.thickness)
            roofMat = [roofMat Material(materials.thermalConductivity{j},materials.volumetricHeatCapacity{j})];
        end
    else
        materials.thickness = [materials.thickness/2 materials.thickness/2];
        roofMat = [Material(materials.thermalConductivity,materials.volumetricHeatCapacity) Material(materials.thermalConductivity,materials.volumetricHeatCapacity)];
    end
    
    roof(i) = Element(xroof.albedo,xroof.emissivity,materials.thickness,roofMat,...
        xroof.vegetationCoverage,xroof.initialTemperature + 273.15,xroof.inclination);
end

% Define Mass
for i = 1:4
    massMat = [];
    materials = xmlTyp(i).construction.mass.materials;
    xmass = xmlTyp(i).construction.mass;
    
    if numel(materials.thickness) > 1
        for j = 1:numel(materials.thickness)
            massMat = [massMat Material(materials.thermalConductivity{j},materials.volumetricHeatCapacity{j})];
        end
    else
        materials.thickness = [materials.thickness/2 materials.thickness/2];
        massMat = [Material(materials.thermalConductivity,materials.volumetricHeatCapacity) Material(materials.thermalConductivity,materials.volumetricHeatCapacity)];
    end
    
    mass(i) = Element(xmass.albedo,xmass.emissivity,materials.thickness,massMat,...
        xmass.vegetationCoverage,xmass.initialTemperature + 273.15,xmass.inclination);
end

% Define Road Element
roadMat = [];
materials = xmlUArea.urbanRoad.materials;
urbanRoad = xmlUArea.urbanRoad;
if numel(materials.thickness)>1
    for j = 1:numel(materials.thickness)
        roadMat = [roadMat Material(materials.thermalConductivity{j},materials.volumetricHeatCapacity{j})];
    end
else
    materials.thickness = [materials.thickness/2 materials.thickness/2];
    roadMat = [Material(materials.thermalConductivity,materials.volumetricHeatCapacity) Material(materials.thermalConductivity,materials.volumetricHeatCapacity)];
end
road = Element(urbanRoad.albedo,urbanRoad.emissivity,materials.thickness,roadMat,...
    urbanRoad.vegetationCoverage,urbanRoad.initialTemperature + 273.15,xmlUArea.urbanRoad.inclination);

% Define Rural Element
ruralMat = [];
materials = xml_input.referenceSite.ruralRoad.materials;
ruralRoad = xml_input.referenceSite.ruralRoad;
if numel(materials.thickness)>1
    for j = 1:numel(materials.thickness)
        ruralMat = [ruralMat Material(materials.thermalConductivity{j},materials.volumetricHeatCapacity{j})];
    end
else
    materials.thickness = [materials.thickness/2 materials.thickness/2];    
    ruralMat = [Material(materials.thermalConductivity,materials.volumetricHeatCapacity) Material(materials.thermalConductivity,materials.volumetricHeatCapacity)];
end

rural = Element(ruralRoad.albedo,ruralRoad.emissivity,materials.thickness,...
    ruralMat,ruralRoad.vegetationCoverage,ruralRoad.initialTemperature + 273.15,ruralRoad.inclination);

%% Define Buildings
for i = 1:4
    typology(i) = Building(xmlTyp(i).building.floorHeight,...
        xmlTyp(i).building.nightInternalGains,...
        xmlTyp(i).building.dayInternalGains,...
        xmlTyp(i).building.radiantFraction,...
        xmlTyp(i).building.latentFraction,...
        xmlTyp(i).building.infiltration,...
        xmlTyp(i).building.ventilation,...
        xmlTyp(i).construction.glazing.glazingRatio,...
        xmlTyp(i).construction.glazing.windowUvalue,...
        xmlTyp(i).construction.glazing.windowSHGC,...
        xmlTyp(i).building.coolingSystemType,...
        xmlTyp(i).building.coolingCOP,...
        xmlTyp(i).building.heatReleasedToCanyon,...
        xmlTyp(i).building.daytimeCoolingSetPoint + 273.15,...
        xmlTyp(i).building.nighttimeCoolingSetPoint + 273.15,...
        xmlTyp(i).building.daytimeHeatingSetPoint + 273.15,...
        xmlTyp(i).building.nighttimeHeatingSetPoint + 273.15,...
        xmlTyp(i).building.coolingCapacity,...
        xmlTyp(i).building.heatingEfficiency,...
        xmlTyp(i).building.initialT + 273.15);
end

% Urban Configuration [building,mass,wall,roof,road]
urbanConf1 = UrbanConf(typology(1),mass(1),wall(1),roof(1),road);
urbanConf2 = UrbanConf(typology(2),mass(2),wall(2),roof(2),road);
urbanConf3 = UrbanConf(typology(3),mass(3),wall(3),roof(3),road);
urbanConf4 = UrbanConf(typology(4),mass(4),wall(4),roof(4),road);

%find distro
typDist = [];
typDist(1) = xmlTyp(1).dist/100;
typDist(2) = xmlTyp(2).dist/100;
typDist(3) = xmlTyp(3).dist/100;
typDist(4) = xmlTyp(4).dist/100;

% Urban Usage [Fraction of urban configurations,urban configurations]
urbanUsage = UrbanUsage(typDist,[urbanConf1, urbanConf2, urbanConf3, urbanConf4]);
   
%% Reference site class
RefSite = xml_input.referenceSite;
refSite = ReferenceSite(RefSite.latitude,RefSite.longitude,RefSite.averageObstacleHeight,...
    weather.staTemp(1),weather.staPres(1),parameter);

%% Define dominant typology
[M, I] = max(typDist);
dominantTypology = typology(I);
dominantWall = wall(I);
disp(dominantTypology);

urbanArea = UrbanArea(xml_input.urbanArea.averageBuildingHeight,...               
    xml_input.urbanArea.siteCoverageRatio,...              
    xml_input.urbanArea.facadeToSiteRatio,...              
    xml_input.urbanArea.treeCoverage,...              
    xml_input.urbanArea.nonBldgSensibleHeat,...               
    xml_input.urbanArea.nonBldgLatentAnthropogenicHeat,...               
    weather.staTemp(1),weather.staHum(1),weather.staUmod(1),parameter,...
    dominantTypology,dominantWall,road,rural); 

%% UblVars
ublVars = UblVars('C',xml_input.urbanArea.charLength,weather.staTemp(1),parameter.maxdx); 

%% HVAC autosize
autosize = 1;
Fc = fopen('coolCap.txt','r+');
for i = 1:numel(urbanArea)
    for j = 1:numel(urbanUsage(i).urbanConf)
        if autosize
            coolCap = Autosize(urbanArea(i),ublVars(i),...
                urbanUsage(i).urbanConf(j),climate_data,rural,refSite,parameter);
            fprintf(Fc,'%1.3f\n',coolCap);
            urbanUsage(i).urbanConf(j).building.coolCap = coolCap;
        else
            urbanUsage(i).urbanConf(j).building.coolCap = fscanf(Fc,'%f\n',1);
        end
    end
end
fclose(Fc);

% =========================================================================
%% Run UWG
forc = Forcing(weather.staTemp);
sensHeat = zeros(numel(urbanArea),1);

disp '==========================='
disp 'Start UWG simulation '
disp '==========================='
timeCount = 0.;
Can_Tdb = [];
Can_hum = [];

for it=1:simParam.nt    
    timeCount=timeCount+simParam.dt;
    simParam = UpdateDate(simParam);
    % print file
    if eq(mod(timeCount,simParam.timePrint),0)
        for i = 1:numel(urbanArea)
            Can_Tdb = [Can_Tdb (urbanArea(i).canTemp-273.15)];
            Can_hum = [Can_hum urbanArea(i).canHum];
            radTemp = [urbanUsage(1).urbanConf(1).wall.layerTemp(1) forc.skyTemp  urbanUsage(1).urbanConf(1).road.layerTemp(1)];
            radTemp_calc = [radTemp, urbanArea(1).bldHeight urbanArea(1).canWidth];
            filename = strcat(newPathName,'\','Trad_',newFileName,'.csv');
            dlmwrite(filename,radTemp_calc,'delimiter',',','-append');
        end
    end
    % start of Bruno's code
    % read forcing
    if eq(mod(timeCount,simParam.timeForcing),0) || eq(timeCount,simParam.dt)
        if le(forc.itfor,simParam.timeMax/simParam.timeForcing)
            forc = ReadForcing(forc,weather,parameter);
            % solar calculations
            [rural,urbanArea,urbanUsage] = SolarCalcs(urbanArea,urbanUsage,...
              simParam,refSite,forc,parameter,rural);
            [first,second,third] = PriorityIndex(forc.uDir,ublVars);
        end
    end
    % rural heat fluxes
    rural.infra = forc.infra-parameter.sigma*rural.layerTemp(1)^4.;
    rural = SurfFlux(rural,forc,parameter,simParam,forc.hum,forc.temp,forc.wind,2,0.);
    % vertical profiles of meteorological variables at the rural site
    refSite = VerticalDifussionModel(refSite,forc,rural,parameter,simParam );
    for i = 1:numel(urbanArea)
        % urban heat fluxes
        [urbanArea(i),ublVars(i),urbanUsage(i),forc] = UrbFlux(urbanArea(i),ublVars(i),...
        urbanUsage(i),forc,parameter,simParam,refSite);
        % urban canyon temperature and humidity
        urbanArea(i) = UrbThermal(urbanArea(i),ublVars(i).ublTemp,urbanUsage(i),forc,parameter,simParam);
    end
    % urban boundary layer temperature
    for i=1:numel(urbanArea)
        sensHeat(i) = urbanArea(i).sensHeat;
    end
    ublVars = UrbanBoundaryLayerModel(ublVars,sensHeat,refSite,rural,forc,...
        parameter,simParam,first,second,third);
    % print day
    if eq(mod(timeCount,3600.*24),0)
        varname = timeCount/(3600.*24);
        fprintf('DAY %g\n', varname);
        progressbar(varname/365);
    end
end
%% Write modified values to epwinput.value
for iJ = 1:size(Can_Tdb,2)
    epwinput.values{iJ,7}{1,1} = num2str(Can_Tdb(iJ),'%0.1f'); % dry bulb temperature  [°C]    
    [Tdb, w, Can_phi(iJ), h, Can_Tdp(iJ), v] = Psychrometrics(Can_Tdb(iJ), Can_hum(iJ), str2num(epwinput.values{iJ,10}{1,1}));
    epwinput.values{iJ,8}{1,1} = num2str(Can_Tdp(iJ),'%0.1f'); % dew point temperature [°C]
    epwinput.values{iJ,9}{1,1} = num2str(Can_phi(iJ),'%0.0f'); % relative humidity     [%]
end
progressbar(360/365)

%% Write new EPW file
disp('writing new EPW file');

new_climate_file = strcat(newPathName,'\',newFileName,'.epw');
epwnewid = fopen(new_climate_file,'w');
for i = 1:8
    fprintf(epwnewid,'%s\r\n',header{i});
end
for i = 1:size(epwinput.values,1)
    printme = [];
    for e = 1:34
        printme = [printme epwinput.values{i,e}{1,1} ','];
    end
    printme = [printme epwinput.values{i,e}{1,1}];
    fprintf(epwnewid,'%s\r\n',printme);
end

disp '==========================='
disp '    UWG ended correctly    '
disp '==========================='

progressbar(1)
if fullyScripted
    disp('Inputs scripted, supressing pop-up notification...')
else
    h = msgbox('Urban Weather Generation Complete','UWG 2.0','help');
end
disp(['New climate file generated: ',new_climate_file])

fclose all;