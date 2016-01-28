CL_EPW_PATH = 'C:\sim\UWG_Matlab\data';
CL_EPW = 'Phoenix.epw';
CL_XML_PATH = 'C:\sim\UWG_Matlab\data';
CL_RE = 'success.epw';
CL_XML = {
    'BackBayStation_Test2.xml'
%    'jacobian.m'
     };

for i = 1:length(CL_XML)
    [new_climate_file] = xml_new(CL_EPW_PATH,CL_EPW,CL_XML_PATH,CL_XML{i},CL_EPW_PATH,CL_RE);
end