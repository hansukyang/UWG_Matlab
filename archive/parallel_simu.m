CL_EPW_PATH = 'C:\Users\Jason\Desktop\Test2\Boston_commercial';
CL_EPW = 'boston_test.epw';
CL_XML_PATH = 'C:\Users\Jason\Desktop\Test2\Boston_commercial';
%CL_XML = ['boston.xml';'boston2.xml';'boston3.xml';'boston4.xml';'boston5.xml'];
CL_XML = 'boston_test.xml';


%for i=1:5
    [new_climate_file] = generateEPW_10_xml_AN10_importdata(CL_EPW_PATH,CL_EPW,CL_XML_PATH,CL_XML);
%end

