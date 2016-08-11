function [new_climate_file] = xml_inputs6(CL_EPW_PATH,CL_EPW,CL_XML_PATH,CL_XML,CL_RE_PATH,CL_RE,IN_MON,IN_DAY,IN_DUR)
% =========================================================================
%  THE URBAN WEATHER GENERATOR
% % Generate new EPW file
% =========================================================================
% Author: B. Bueno
% Packaged by J. Sullivan-Fedock
% Modified by A. Nakano & Lingfu Zhang
% latest modification 2014-10-29
% -------------------------------------------------------------------------

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
    % epwinput.values(i,:) = textscan(readin, '%f %f %f %f %f %s %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %*[^\n]', 'delimiter',',','MultipleDelimsAsOne',1);
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

% Class housecleaning
%wall
if isa(xml_input.construction.wall.materials.names,'char')
	xml_input.construction.wall.materials.names = {xml_input.construction.wall.materials.names};
end
if isa(xml_input.construction.wall.materials.thermalConductivity,'double')
	xml_input.construction.wall.materials.thermalConductivity = {xml_input.construction.wall.materials.thermalConductivity};
end
if isa(xml_input.construction.wall.materials.volumetricHeatCapacity,'double')
	xml_input.construction.wall.materials.volumetricHeatCapacity = {xml_input.construction.wall.materials.volumetricHeatCapacity};
end

%roof
if isa(xml_input.construction.roof.materials.names,'char')
	xml_input.construction.roof.materials.names = {xml_input.construction.roof.materials.names};
end
if isa(xml_input.construction.roof.materials.thermalConductivity,'double')
	xml_input.construction.roof.materials.thermalConductivity = {xml_input.construction.roof.materials.thermalConductivity};
end
if isa(xml_input.construction.roof.materials.volumetricHeatCapacity,'double')
	xml_input.construction.roof.materials.volumetricHeatCapacity = {xml_input.construction.roof.materials.volumetricHeatCapacity};
end

% road
if isa(xml_input.construction.urbanRoad.materials.names,'char')
	xml_input.construction.urbanRoad.materials.names = {xml_input.construction.urbanRoad.materials.names};
end
if isa(xml_input.construction.urbanRoad.materials.thermalConductivity,'double')
	xml_input.construction.urbanRoad.materials.thermalConductivity = {xml_input.construction.urbanRoad.materials.thermalConductivity};
end
if isa(xml_input.construction.urbanRoad.materials.volumetricHeatCapacity,'double')
	xml_input.construction.urbanRoad.materials.volumetricHeatCapacity = {xml_input.construction.urbanRoad.materials.volumetricHeatCapacity};
end

% Rural
if isa(xml_input.construction.rural.materials.names,'char')
	xml_input.construction.rural.materials.names = {xml_input.construction.rural.materials.names};
end
if isa(xml_input.construction.rural.materials.thermalConductivity,'double')
	xml_input.construction.rural.materials.thermalConductivity = {xml_input.construction.rural.materials.thermalConductivity};
end
if isa(xml_input.construction.rural.materials.volumetricHeatCapacity,'double')
	xml_input.construction.rural.materials.volumetricHeatCapacity = {xml_input.construction.rural.materials.volumetricHeatCapacity};
end

%Mass
if isa(xml_input.construction.mass.materials.names,'char')
	xml_input.construction.mass.materials.names = {xml_input.construction.mass.materials.names};
end
if isa(xml_input.construction.mass.materials.thermalConductivity,'double')
	xml_input.construction.mass.materials.thermalConductivity = {xml_input.construction.mass.materials.thermalConductivity};
end
if isa(xml_input.construction.mass.materials.volumetricHeatCapacity,'double')
	xml_input.construction.mass.materials.volumetricHeatCapacity = {xml_input.construction.mass.materials.volumetricHeatCapacity};
end

%% Reconstruct xml Materials

% Wall
% Break wall into pieces
for i902 = 1:size(xml_input.construction.wall.materials.thickness,2)
	wallGrid_t{1,i902} = xml_input.construction.wall.materials.thickness(i902);
	wallGrid_n{1,i902} = xml_input.construction.wall.materials.names(i902);
	wallGrid_c{1,i902} = xml_input.construction.wall.materials.thermalConductivity(i902);
	wallGrid_h{1,i902} = xml_input.construction.wall.materials.volumetricHeatCapacity(i902);
end
for i903 = 1:size(wallGrid_t,2)
clear Lr;
Lr = wallGrid_t{i903};
clear Lm;
if Lr <= 0.05;
                Lm(1)=Lr;
elseif Lr <= 0.1;
                Lm(1)=Lr/2;
                Lm(2)=Lr/2;
elseif Lr <= 0.2;
                Lm(1)=Lr/4;
                Lm(2)=Lr/2;
                Lm(3)=Lr/4;
else Lr <= 0.3;
                Lm(1)=Lr/6;
                Lm(2)=Lr/3;
                Lm(3)=Lr/3;
                Lm(4)=Lr/6;
end

% Reassamble wall
wallGrid_t{i903} = Lm;
clear names;
clear thermalConductivity;
clear volumetricHeatCapacity;
names = wallGrid_n{1,i903};
thermalConductivity = wallGrid_c{1,i903};
volumetricHeatCapacity = wallGrid_h{1,i903};

for j902 = 1:size(Lm,2)
	wallGrid_n{j902,i903} = names;
	wallGrid_c{j902,i903} = thermalConductivity;
	wallGrid_h{j902,i903} = volumetricHeatCapacity;
end
end
xml_input.construction.wall.materials.thickness = [];
for i904 = 1:size(wallGrid_t,2)
    xml_input.construction.wall.materials.thickness = [xml_input.construction.wall.materials.thickness wallGrid_t{i904}];
end
xml_input.construction.wall.materials.names = [];
for j905 = 1:size(wallGrid_n,2)
    for i905 = 1:size(wallGrid_n,1)
        xml_input.construction.wall.materials.names = [xml_input.construction.wall.materials.names wallGrid_n{i905,j905}];
    end
end
xml_input.construction.wall.materials.thermalConductivity = [];
for j906 = 1:size(wallGrid_c,2)
    for i906 = 1:size(wallGrid_c,1)
        xml_input.construction.wall.materials.thermalConductivity = [xml_input.construction.wall.materials.thermalConductivity wallGrid_c{i906,j906}];
    end
end
xml_input.construction.wall.materials.volumetricHeatCapacity = [];
for j907 = 1:size(wallGrid_h,2)
    for i907 = 1:size(wallGrid_h,1)
        xml_input.construction.wall.materials.volumetricHeatCapacity = [xml_input.construction.wall.materials.volumetricHeatCapacity wallGrid_h{i907,j907}];
    end
end
xml_input.construction.wall.materials.thickness = xml_input.construction.wall.materials.thickness';

%% Roof


for i902 = 1:size(xml_input.construction.roof.materials.thickness,2)
	roofGrid_t{1,i902} = xml_input.construction.roof.materials.thickness(i902);
	roofGrid_n{1,i902} = xml_input.construction.roof.materials.names(i902);
	roofGrid_c{1,i902} = xml_input.construction.roof.materials.thermalConductivity(i902);
	roofGrid_h{1,i902} = xml_input.construction.roof.materials.volumetricHeatCapacity(i902);
end
for i903 = 1:size(roofGrid_t,2)
clear Lr;
Lr = roofGrid_t{i903};
clear Lm;
if Lr <= 0.05;
                Lm(1)=Lr;
elseif Lr <= 0.1;
                Lm(1)=Lr/2;
                Lm(2)=Lr/2;
elseif Lr <= 0.2;
                Lm(1)=Lr/4;
                Lm(2)=Lr/2;
                Lm(3)=Lr/4;
else Lr <= 0.3;
                Lm(1)=Lr/6;
                Lm(2)=Lr/3;
                Lm(3)=Lr/3;
                Lm(4)=Lr/6;
end

% Reassamble roof
roofGrid_t{i903} = Lm;
clear names;
clear thermalConductivity;
clear volumetricHeatCapacity;
names = roofGrid_n{1,i903};
thermalConductivity = roofGrid_c{1,i903};
volumetricHeatCapacity = roofGrid_h{1,i903};

for j902 = 1:size(Lm,2)
	roofGrid_n{j902,i903} = names;
	roofGrid_c{j902,i903} = thermalConductivity;
	roofGrid_h{j902,i903} = volumetricHeatCapacity;
end
end
xml_input.construction.roof.materials.thickness = [];
for i904 = 1:size(roofGrid_t,2)
    xml_input.construction.roof.materials.thickness = [xml_input.construction.roof.materials.thickness roofGrid_t{i904}];
end
xml_input.construction.roof.materials.names = [];
for j905 = 1:size(roofGrid_n,2)
    for i905 = 1:size(roofGrid_n,1)
        xml_input.construction.roof.materials.names = [xml_input.construction.roof.materials.names roofGrid_n{i905,j905}];
    end
end
xml_input.construction.roof.materials.thermalConductivity = [];
for j906 = 1:size(roofGrid_c,2)
    for i906 = 1:size(roofGrid_c,1)
        xml_input.construction.roof.materials.thermalConductivity = [xml_input.construction.roof.materials.thermalConductivity roofGrid_c{i906,j906}];
    end
end
xml_input.construction.roof.materials.volumetricHeatCapacity = [];
for j907 = 1:size(roofGrid_h,2)
    for i907 = 1:size(roofGrid_h,1)
        xml_input.construction.roof.materials.volumetricHeatCapacity = [xml_input.construction.roof.materials.volumetricHeatCapacity roofGrid_h{i907,j907}];
    end
end
xml_input.construction.roof.materials.thickness = xml_input.construction.roof.materials.thickness';

%% Road
% Break road into pieces
for i902 = 1:size(xml_input.construction.urbanRoad.materials.thickness,2)
	roadGrid_t{1,i902} = xml_input.construction.urbanRoad.materials.thickness(i902);
	roadGrid_n{1,i902} = xml_input.construction.urbanRoad.materials.names(i902);
	roadGrid_c{1,i902} = xml_input.construction.urbanRoad.materials.thermalConductivity(i902);
	roadGrid_h{1,i902} = xml_input.construction.urbanRoad.materials.volumetricHeatCapacity(i902);
end
for i903 = 1:size(roadGrid_t,2)
clear Lr;
Lr = roadGrid_t{i903};
clear Lm;
if Lr <= 0.05;
                Lm(1)=Lr;
elseif Lr <= 0.1;
                Lm(1)=Lr/2;
                Lm(2)=Lr/2;
elseif Lr <= 0.2;
                Lm(1)=Lr/4;
                Lm(2)=Lr/2;
                Lm(3)=Lr/4;
else Lr <= 0.3;
                Lm(1)=Lr/6;
                Lm(2)=Lr/3;
                Lm(3)=Lr/3;
                Lm(4)=Lr/6;
end

% Reassamble road
roadGrid_t{i903} = Lm;
clear names;
clear thermalConductivity;
clear volumetricHeatCapacity;
names = roadGrid_n{1,i903};
thermalConductivity = roadGrid_c{1,i903};
volumetricHeatCapacity = roadGrid_h{1,i903};

for j902 = 1:size(Lm,2)
	roadGrid_n{j902,i903} = names;
	roadGrid_c{j902,i903} = thermalConductivity;
	roadGrid_h{j902,i903} = volumetricHeatCapacity;
end
end
xml_input.construction.urbanRoad.materials.thickness = [];
for i904 = 1:size(roadGrid_t,2)
    xml_input.construction.urbanRoad.materials.thickness = [xml_input.construction.urbanRoad.materials.thickness roadGrid_t{i904}];
end
xml_input.construction.urbanRoad.materials.names = [];
for j905 = 1:size(roadGrid_n,2)
    for i905 = 1:size(roadGrid_n,1)
        xml_input.construction.urbanRoad.materials.names = [xml_input.construction.urbanRoad.materials.names roadGrid_n{i905,j905}];
    end
end
xml_input.construction.urbanRoad.materials.thermalConductivity = [];
for j906 = 1:size(roadGrid_c,2)
    for i906 = 1:size(roadGrid_c,1)
        xml_input.construction.urbanRoad.materials.thermalConductivity = [xml_input.construction.urbanRoad.materials.thermalConductivity roadGrid_c{i906,j906}];
    end
end
xml_input.construction.urbanRoad.materials.volumetricHeatCapacity = [];
for j907 = 1:size(roadGrid_h,2)
    for i907 = 1:size(roadGrid_h,1)
        xml_input.construction.urbanRoad.materials.volumetricHeatCapacity = [xml_input.construction.urbanRoad.materials.volumetricHeatCapacity roadGrid_h{i907,j907}];
    end
end
xml_input.construction.urbanRoad.materials.thickness = xml_input.construction.urbanRoad.materials.thickness';

%% Rural
% Break rural into pieces
for i902 = 1:size(xml_input.construction.rural.materials.thickness,2)
	ruralGrid_t{1,i902} = xml_input.construction.rural.materials.thickness(i902);
	ruralGrid_n{1,i902} = xml_input.construction.rural.materials.names(i902);
	ruralGrid_c{1,i902} = xml_input.construction.rural.materials.thermalConductivity(i902);
	ruralGrid_h{1,i902} = xml_input.construction.rural.materials.volumetricHeatCapacity(i902);
end
for i903 = 1:size(ruralGrid_t,2)
clear Lr;
Lr = ruralGrid_t{i903};
clear Lm;
if Lr <= 0.05;
                Lm(1)=Lr;
elseif Lr <= 0.1;
                Lm(1)=Lr/2;
                Lm(2)=Lr/2;
elseif Lr <= 0.2;
                Lm(1)=Lr/4;
                Lm(2)=Lr/2;
                Lm(3)=Lr/4;
else Lr <= 0.3;
                Lm(1)=Lr/6;
                Lm(2)=Lr/3;
                Lm(3)=Lr/3;
                Lm(4)=Lr/6;
end

% Reassamble rural
ruralGrid_t{i903} = Lm;
clear names;
clear thermalConductivity;
clear volumetricHeatCapacity;
names = ruralGrid_n{1,i903};
thermalConductivity = ruralGrid_c{1,i903};
volumetricHeatCapacity = ruralGrid_h{1,i903};

for j902 = 1:size(Lm,2)
	ruralGrid_n{j902,i903} = names;
	ruralGrid_c{j902,i903} = thermalConductivity;
	ruralGrid_h{j902,i903} = volumetricHeatCapacity;
end
end
xml_input.construction.rural.materials.thickness = [];
for i904 = 1:size(ruralGrid_t,2)
    xml_input.construction.rural.materials.thickness = [xml_input.construction.rural.materials.thickness ruralGrid_t{i904}];
end
xml_input.construction.rural.materials.names = [];
for j905 = 1:size(ruralGrid_n,2)
    for i905 = 1:size(ruralGrid_n,1)
        xml_input.construction.rural.materials.names = [xml_input.construction.rural.materials.names ruralGrid_n{i905,j905}];
    end
end
xml_input.construction.rural.materials.thermalConductivity = [];
for j906 = 1:size(ruralGrid_c,2)
    for i906 = 1:size(ruralGrid_c,1)
        xml_input.construction.rural.materials.thermalConductivity = [xml_input.construction.rural.materials.thermalConductivity ruralGrid_c{i906,j906}];
    end
end
xml_input.construction.rural.materials.volumetricHeatCapacity = [];
for j907 = 1:size(ruralGrid_h,2)
    for i907 = 1:size(ruralGrid_h,1)
        xml_input.construction.rural.materials.volumetricHeatCapacity = [xml_input.construction.rural.materials.volumetricHeatCapacity ruralGrid_h{i907,j907}];
    end
end
xml_input.construction.rural.materials.thickness = xml_input.construction.rural.materials.thickness';

%% Mass
% Break mass into pieces
for i902 = 1:size(xml_input.construction.mass.materials.thickness,2)
	massGrid_t{1,i902} = xml_input.construction.mass.materials.thickness(i902);
	massGrid_n{1,i902} = xml_input.construction.mass.materials.names(i902);
	massGrid_c{1,i902} = xml_input.construction.mass.materials.thermalConductivity(i902);
	massGrid_h{1,i902} = xml_input.construction.mass.materials.volumetricHeatCapacity(i902);
end
for i903 = 1:size(massGrid_t,2)
clear Lr;
Lr = massGrid_t{i903};
clear Lm;
if Lr <= 0.05;
                Lm(1)=Lr;
elseif Lr <= 0.1;
                Lm(1)=Lr/2;
                Lm(2)=Lr/2;
elseif Lr <= 0.2;
                Lm(1)=Lr/4;
                Lm(2)=Lr/2;
                Lm(3)=Lr/4;
else Lr <= 0.3;
                Lm(1)=Lr/6;
                Lm(2)=Lr/3;
                Lm(3)=Lr/3;
                Lm(4)=Lr/6;
end

% Reassamble mass
massGrid_t{i903} = Lm;
clear names;
clear thermalConductivity;
clear volumetricHeatCapacity;
names = massGrid_n{1,i903};
thermalConductivity = massGrid_c{1,i903};
volumetricHeatCapacity = massGrid_h{1,i903};

for j902 = 1:size(Lm,2)
	massGrid_n{j902,i903} = names;
	massGrid_c{j902,i903} = thermalConductivity;
	massGrid_h{j902,i903} = volumetricHeatCapacity;
end
end
xml_input.construction.mass.materials.thickness = [];
for i904 = 1:size(massGrid_t,2)
    xml_input.construction.mass.materials.thickness = [xml_input.construction.mass.materials.thickness massGrid_t{i904}];
end
xml_input.construction.mass.materials.names = [];
for j905 = 1:size(massGrid_n,2)
    for i905 = 1:size(massGrid_n,1)
        xml_input.construction.mass.materials.names = [xml_input.construction.mass.materials.names massGrid_n{i905,j905}];
    end
end
xml_input.construction.mass.materials.thermalConductivity = [];
for j906 = 1:size(massGrid_c,2)
    for i906 = 1:size(massGrid_c,1)
        xml_input.construction.mass.materials.thermalConductivity = [xml_input.construction.mass.materials.thermalConductivity massGrid_c{i906,j906}];
    end
end
xml_input.construction.mass.materials.volumetricHeatCapacity = [];
for j907 = 1:size(massGrid_h,2)
    for i907 = 1:size(massGrid_h,1)
        xml_input.construction.mass.materials.volumetricHeatCapacity = [xml_input.construction.mass.materials.volumetricHeatCapacity massGrid_h{i907,j907}];
    end
end
xml_input.construction.mass.materials.thickness = xml_input.construction.mass.materials.thickness';

%% Simulation paramters
simParam = SimParam(...
    300.,...            % Simulation time-step
    3600,...            % Weather data time-step
    1,...   % Begin month
    1,...                 % Begin day of the month
    365);
   % xml_input.parameter.simuDuration);               % Number of days of simulation
weather = Weather(climate_data,...
    simParam.timeInitial,simParam.timeFinal);
%    xml_input.simParam.weatherDataTimeStep * 60,...  % Weather data time-step

%% Param
parameter = Param(xml_input.urbanArea.daytimeBLHeight,...
    xml_input.urbanArea.nighttimeBLHeight,...
    xml_input.urbanArea.refHeight,...
    xml_input.parameter.tempHeight,...
    xml_input.parameter.windHeight,...
    1.2,...
    200,...
    50,...
    xml_input.urbanArea.treeLatent,...
    xml_input.urbanArea.grassLatent,...
    xml_input.urbanArea.vegAlbedo,...
    xml_input.urbanArea.vegStart,...
    xml_input.urbanArea.vegEnd,...
    xml_input.building.nightSetStart,...
    xml_input.building.nightSetEnd,...
    0.1,...
    10,...
    0.005,...
    0.3,...
    500,...
    9.81, 1004, 0.40, 287, 461.5, 2260000, 3.141592653, 0.0000000567, 1000, 2500800, 273.16, 611.14, 4218,...
    1846.1, 9.4, 7.4, 1.09647471147);


% Define Wall
wallMat = [];
disp(xml_input.construction.wall.materials.names);
for jack = 1:size(xml_input.construction.wall.materials.names,2)

    wallMat = [wallMat Material(xml_input.construction.wall.materials.thermalConductivity{jack},xml_input.construction.wall.materials.volumetricHeatCapacity{jack})];
    disp(wallMat);
end
wall = Element(xml_input.construction.wall.albedo,...
xml_input.construction.wall.emissivity,...
xml_input.construction.wall.materials.thickness,...
wallMat,...
xml_input.construction.wall.vegetationCoverage,...
xml_input.construction.wall.initialTemperature + 273.15,...
xml_input.construction.wall.inclination);

% Define Roof
roofMat = [];
for jack = 1:size(xml_input.construction.roof.materials.names,2)
	roofMat = [roofMat Material(xml_input.construction.roof.materials.thermalConductivity{jack},xml_input.construction.roof.materials.volumetricHeatCapacity{jack})];
end
roof = Element(xml_input.construction.roof.albedo,...
xml_input.construction.roof.emissivity,...
xml_input.construction.roof.materials.thickness,...
roofMat,...
xml_input.construction.roof.vegetationCoverage,...
xml_input.construction.roof.initialTemperature + 273.15,...
xml_input.construction.roof.inclination);

% Define Road
roadMat = [];
for jack = 1:size(xml_input.construction.urbanRoad.materials.names,2)
	roadMat = [roadMat Material(xml_input.construction.urbanRoad.materials.thermalConductivity{jack},xml_input.construction.urbanRoad.materials.volumetricHeatCapacity{jack})];
end
road = Element(xml_input.construction.urbanRoad.albedo,...
xml_input.construction.urbanRoad.emissivity,...
xml_input.construction.urbanRoad.materials.thickness,...
roadMat,...
xml_input.construction.urbanRoad.vegetationCoverage,...
xml_input.construction.urbanRoad.initialTemperature + 273.15,...
xml_input.construction.urbanRoad.inclination);

% Define Rural
ruralMat = [];
for jack = 1:size(xml_input.construction.rural.materials.names,2)
	ruralMat = [ruralMat Material(xml_input.construction.rural.materials.thermalConductivity{jack},xml_input.construction.rural.materials.volumetricHeatCapacity{jack})];
end
rural = Element(xml_input.construction.rural.albedo,...
xml_input.construction.rural.emissivity,...
xml_input.construction.rural.materials.thickness,...
ruralMat,...
xml_input.construction.rural.vegetationCoverage,...
xml_input.construction.rural.initialTemperature + 273.15,...
xml_input.construction.rural.inclination);

% Define Mass
massMat = [];
for jack = 1:size(xml_input.construction.mass.materials.names,2)
	massMat = [massMat Material(xml_input.construction.mass.materials.thermalConductivity{jack},xml_input.construction.mass.materials.volumetricHeatCapacity{jack})];
end
mass = Element(xml_input.construction.mass.albedo,...
xml_input.construction.mass.emissivity,...
xml_input.construction.mass.materials.thickness,...
massMat,...
xml_input.construction.mass.vegetationCoverage,...
xml_input.construction.mass.initialTemperature + 273.15,...
xml_input.construction.mass.inclination);

%Find January Average Temperature
% janSum = 0;
% for i901 = 1:744
% valueTemp = str2num(epwinput.values{i901,7}{1,1});
% janSum = janSum + valueTemp;
% end
% janMean = janSum / 744;

%% CHANGE FROM HERE:
%% Define Buildings (Temporary Hack - zones identical)
residential = Building(xml_input.building.floorHeight,...
xml_input.building.nightInternalGains,...
xml_input.building.dayInternalGains,...
xml_input.building.radiantFraction,...
xml_input.building.latentFraction,...
xml_input.building.infiltration,...
xml_input.building.ventilation,...
xml_input.construction.glazing.glazingRatio,...
xml_input.construction.glazing.windowUvalue,...
xml_input.construction.glazing.windowSHGC,...
xml_input.building.coolingSystemType,...
xml_input.building.coolingCOP,...
xml_input.building.heatReleasedToCanyon,...
xml_input.building.daytimeCoolingSetPoint + 273.15,...
xml_input.building.nighttimeCoolingSetPoint + 273.15,...
xml_input.building.daytimeHeatingSetPoint + 273.15,...
xml_input.building.nighttimeHeatingSetPoint + 273.15,...
xml_input.building.coolingCapacity,...
xml_input.building.heatingEfficiency,...
xml_input.building.initialT + 273.15);

disp(residential);
% janMean + 273.15);
% xml_input.building.intialIndoorTemp + 273.15);
%{
res_wAC = Building(xml_input.building.floorHeight,...
xml_input.building.nightInternalGains,...
xml_input.building.dayInternalGains,...
xml_input.building.radiantFraction,...
xml_input.building.latentFraction,...
xml_input.building.infiltration,...
xml_input.building.ventilation,...
xml_input.building.glazingRatio,...
xml_input.building.windowUvalue,...
xml_input.building.windowSHGC,...
xml_input.building.coolingSystemType,...
xml_input.building.coolingCOP,...
xml_input.building.heatReleasedToCanyon,...
xml_input.building.daytimeCoolingSetPoint + 273.15,...
xml_input.building.nighttimeCoolingSetPoint + 273.15,...
xml_input.building.daytimeHeatingSetPoint + 273.15,...
xml_input.building.nighttimeHeatingSetPoint + 273.15,...
xml_input.building.coolingCapacity,...
xml_input.building.heatingEfficiency,...
xml_input.building.initialT + 273.15);
% janMean + 273.15);
% xml_input.building.intialIndoorTemp + 273.15);

commercial = Building(xml_input.building.floorHeight,...
xml_input.building.nightInternalGains,...
xml_input.building.dayInternalGains,...
xml_input.building.radiantFraction,...
xml_input.building.latentFraction,...
xml_input.building.infiltration,...
xml_input.building.ventilation,...
xml_input.building.glazingRatio,...
xml_input.building.windowUvalue,...
xml_input.building.windowSHGC,...
xml_input.building.coolingSystemType,...
xml_input.building.coolingCOP,...
xml_input.building.heatReleasedToCanyon,...
xml_input.building.daytimeCoolingSetPoint + 273.15,...
xml_input.building.nighttimeCoolingSetPoint + 273.15,...
xml_input.building.daytimeHeatingSetPoint + 273.15,...
xml_input.building.nighttimeHeatingSetPoint + 273.15,...
xml_input.building.coolingCapacity,...
xml_input.building.heatingEfficiency,...
xml_input.building.initialT + 273.15);
% janMean + 273.15);
% xml_input.building.intialIndoorTemp + 273.15);
%}
% Urban Configuration [building,mass,wall,rooof,road]
urbanConf1 = UrbanConf(residential,mass,wall,roof,road);
%urbanConf2 = UrbanConf(res_wAC,mass,wall,roof,road);
%urbanConf3 = UrbanConf(commercial,mass,wall,roof,road);
% Urban Usage [Fraction of urban configurations,urban configurations]
% AN - need to change this section, change the above commercial and resi inputs as well as add xml input section when running different neighborhood
% configurations
urbanUsage = UrbanUsage(1.0, urbanConf1);

%(end of Hack)

%% Reference site
refSite = ReferenceSite(xml_input.referenceSite.latitude,...
    xml_input.referenceSite.longitude,...
    xml_input.referenceSite.averageObstacleHeight,...
    weather.staTemp(1),weather.staPres(1),parameter);

%% Urban areas
% AN - also need to assign for each of new urban usages - last line "resi"
% as well
urbanArea = UrbanArea(xml_input.urbanArea.averageBuildingHeight,...               
    xml_input.urbanArea.horizontalBuildingDensity,...              
    xml_input.urbanArea.verticalToHorizontalUrbanAreaRatio,...              
    xml_input.urbanArea.treeCoverage,...              
    xml_input.urbanArea.nonBldgSensibleHeat,...               
    xml_input.urbanArea.nonBldgLatentAnthropogenicHeat,...               
    weather.staTemp(1),weather.staHum(1),weather.staUmod(1),parameter,...
    residential,wall,road,rural); 

%% UblVars
% AN - also need to assign for each of new urban usages
ublVars = UblVars('C',...
    xml_input.urbanArea.charLength,...
    weather.staTemp(1),parameter.maxdx); 

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
% John's code, no printfile section
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
            
            %output values for radTemp
            %radTemp_calc = [urbanArea(1).canTemp forc.skyTemp urbanUsage(1).urbanConf(1).wall.layerTemp(1) urbanUsage(1).urbanConf(1).road.layerTemp(1) urbanArea(1).canWidth];
            radTemp = [urbanUsage(1).urbanConf(1).wall.layerTemp(1) forc.skyTemp  urbanUsage(1).urbanConf(1).road.layerTemp(1)];
            radTemp_calc = [radTemp, urbanArea(1).bldHeight urbanArea(1).canWidth];
            filename = strcat('Trad_',xmlFileName,'.csv');
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
    rural = SurfFlux( rural,forc,parameter,simParam,forc.hum,forc.temp,...
        forc.wind,2,0.);
    % vertical profiles of meteorological variables at the rural site
    refSite = VerticalDifussionModel( refSite,forc,...
        rural,parameter,simParam );
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
      
% end of bruno's code
    
      progressbar(varname/365)
    end
end
%% Write modified values to epwinput.value

disp('Calculating new Temperature and humidity values')
for iJ = 1:size(Can_Tdb,2)
    epwinput.values{iJ,7}{1,1} = num2str(Can_Tdb(iJ),'%0.1f'); % dry bulb temperature  [°C]
    
    [Tdb, w, Can_phi(iJ), ~, Can_Tdp(iJ), v] = Psychrometrics(Can_Tdb(iJ), Can_hum(iJ), str2num(epwinput.values{iJ,10}{1,1}));
    
    epwinput.values{iJ,8}{1,1} = num2str(Can_Tdp(iJ),'%0.1f'); % dew point temperature [°C]
    epwinput.values{iJ,9}{1,1} = num2str(Can_phi(iJ),'%0.0f'); % relative humidity     [%]
end

    progressbar(360/365)
disp '==========================='
disp '    UWG ended correctly    '
disp '==========================='


%% Write new EPW file

%from old xml code /needed
disp('writing new EPW file')

new_climate_file = strcat(epwPathName,'\',xmlFileName,'.epw');
if exist(new_climate_file)
delete(new_climate_file)
end

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
%end of old xml code

progressbar(1)
if fullyScripted
    disp('Inputs scripted, supressing pop-up notification...')
else
    h = msgbox('Urban Weather Generation Complete','UWG 2.0','help');
end
disp(['New climate file generated: ',new_climate_file])

fclose all;
end