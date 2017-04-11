CL_EPW_PATH = 'E:\Dropbox\research\mit case study\climate change\IPCC_A2Scenarios';
CL_EPW = 'CurrentMIT-A2-2050.epw';
CL_XML_PATH = 'E:\Dropbox\research\mit case study\MITcasestudy_uwg_results';
CL_XML = {
%     'MIT30_2.xml',...
%     'MIT30_2_CASE1.xml',...
%     'MIT30_2_CASE2.xml',...
%     'MIT30_2_CASE3_INSULATION.xml',...
%     'MIT30_2_CASE4_new_designs_for_new_bldgs.xml',...
%     'MIT30_2_CASE5_case4mproved.xml'...
    'MIT30_2_CASE6_case5mproved_thickerIns,urbanroadvegupby0.25,greenroof50%,veg.xml',...
%     'MIT30_CURRENT(only_for_geometries,_rest_from_MIT30).xml',...
     };

for i = 1:length(CL_XML)
    currcity = '';
    run = strcat(currcity, CL_XML{i});
    disp(run); 
    [new_climate_file] = xml_inputs_outputTrad(CL_EPW_PATH,CL_EPW,CL_XML_PATH,run);
end
