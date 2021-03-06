CL_EPW_PATH = 'C:\Users\Jason\Desktop\Test2\Boston_commercial';
CL_EPW = 'boston.epw';
CL_XML_PATH = 'C:\Users\Jason\Desktop\Test2\Boston_commercial';
CL_XML = {'Boston_Commercial-avgBldgHeight_High.xml',...
    'Boston_Commercial-avgObstacleHeight_High.xml', 'Boston_Commercial-avgObstacleHeight_Low.xml',...
    'Boston_Commercial-charLength_High.xml', 'Boston_Commercial-charLength_Low.xml',...
    'Boston_Commercial-coolingCapacity_High.xml','Boston_Commercial-coolingCapacity_Low.xml',...
    'Boston_Commercial-floorHeight_High.xml','Boston_Commercial-floorHeight_Low.xml'...
    'Boston_Commercial-hBDensity_High.xml','Boston_Commercial-hBDensity_Low.xml',...
    'Boston_Commercial-heatReleasedToCanyon_High.xml','Boston_Commercial-heatReleasedToCanyon_Low.xml',...
    'Boston_Commercial-initialT_High.xml','Boston_Commercial-initialT_Low.xml',...
    'Boston_Commercial-LatentAnthroHeat_High.xml','Boston_Commercial-LatentAnthroHeat_Low.xml',...
    'Boston_Commercial-roofVegCoverage_High.xml','Boston_Commercial-roofVegCoverage_Low.xml',...
    'Boston_Commercial-ruralRoadAlbedo_High.xml','Boston_Commercial-ruralRoadAlbedo_Low.xml',...
    'Boston_Commercial-ruralRoadK_High.xml','Boston_Commercial-ruralRoadK_Low.xml',...
    };

for i = 1:length(CL_XML)
    curcity = CL_XML{i};
    disp(curcity);
    [new_climate_file] = generateEPW_10_xml_AN10_importdata(CL_EPW_PATH,CL_EPW,CL_XML_PATH,curcity);
end

