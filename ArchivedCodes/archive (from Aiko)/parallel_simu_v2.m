CL_EPW_PATH = 'C:\Users\Jason\Desktop\Test2\Boston_commercial';
CL_EPW = 'boston_test.epw';
CL_XML_PATH = 'C:\Users\Jason\Desktop\Test2\Boston_commercial';
CL_XML = {'boston_test.xml', 'boston_test2.xml', 'boston_test3.xml'};

for i = 1:length(CL_XML)
    curcity = CL_XML{i};
    disp(curcity);
    [new_climate_file] = generateEPW_10_xml_AN10_importdata(CL_EPW_PATH,CL_EPW,CL_XML_PATH,curcity);
end

