CL_EPW_PATH = 'C:\Users\anakano\Dropbox\Research\UWG\UWG_Matlab';
CL_EPW = 'sample.epw';
CL_XML_PATH = 'C:\Users\anakano\Dropbox\Research\UWG\UWG_Matlab';
CL_RE = 'success.epw'
CL_XML = {
    'sample_test.xml'
     };

for i = 1:length(CL_XML)
    currcity = '';
    %run = strcat(currcity, CL_XML{i});
    %disp(run); 
    [new_climate_file] = xml_inputs(CL_EPW_PATH,CL_EPW,CL_XML_PATH,CL_XML,CL_EPW_PATH,CL_RE)
end

