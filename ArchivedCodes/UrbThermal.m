function urbanArea = UrbThermal(urbanArea,ublTemp,urbanUsage,forc,parameter,simParam)
    % Calculate the urban canyon temperature per The UWG (2012) Eq. 10 

    buildingTerm = zeros(4,1);
    wallTerm = zeros(2,1);
    roadTerm = zeros(3,1);
    r_air = forc.pres/(1000*0.287042*urbanArea.canTemp*(1.+1.607858*urbanArea.canHum)); % air density
    Cp_air = parameter.cp;
    Qsens_wall = 0;
    Qsens_window = 0;
    Qsens_road = 0;
    Qsens_hvac = 0;
    Qsens_traffic = 0;
    Qconv_vent = 0;
    Qir_ubl = 0;
    Qir_wall = 0;
    Qir_road = 0;
    Qconv_ubl = 0;
    
    for j = 1:numel(urbanUsage.urbanConf)
        
        % Re-naming variable for readability
        building = urbanUsage.urbanConf(j).building;
        wall = urbanUsage.urbanConf(j).wall;
        road = urbanUsage.urbanConf(j).road;
        T_indoor = building.indoorTemp;
        T_wall = wall.layerTemp(1);
        T_road = road.layerTemp(1);
        T_canyon = urbanArea.canTemp;
        T_ubl = ublTemp;
        T_sky = forc.skyTemp;
        R_glazing= building.glazingRatio;
        A_facade = urbanArea.facArea;
        A_roof = urbanArea.roofArea;
        A_road = urbanArea.roadArea;
        A_wall = (1-R_glazing)*A_facade;
        A_window = R_glazing*A_facade;
        LW_road = urbanUsage.urbanConf(j).canRoadLWCoef;
        LW_wall = urbanUsage.urbanConf(j).canWallLWCoef;
        LW_sky = urbanArea.canSkyLWCoef;
        wdth_canyon = urbanArea.canWidth;
        wdth_bld = urbanArea.bldWidth;
        hght_bld = urbanArea.bldHeight;
        Rate_vent = building.vent/3600;     % change ACH to per second
        U_window = building.uValue;
        frac_j = urbanUsage.frac(j);
        V_bldg = hght_bld*A_roof;
        Qsens_waste = building.sensWaste*building.fWaste;
        Qlat_waste = building.latWaste*building.fWaste;
        
        % Window, Vent, Waste Heat to Canyon
        buildingTerm(1) = buildingTerm(1) +...
            frac_j*(T_indoor*A_window*U_window+...          % Heat through window
                T_indoor*Rate_vent*V_bldg*r_air*Cp_air+...  % Heat from vented air 
                Qsens_waste*(wdth_canyon+wdth_bld));        % Waste heat from HVAC
        
        % Wall (no window) to Canyon
        wallTerm(1) = wallTerm(1) +...                                      
            frac_j*T_wall*(wall.aeroCond*Cp_air*r_air+LW_wall)*A_wall;      % Heat (Rad & Sens) from wall surface
                                   
        % Road to Canyon, including LW
        roadTerm(1) = roadTerm(1) +...                                     
            frac_j*T_road*(road.aeroCond*Cp_air*r_air+LW_road)*A_road;      % Heat (Rad & Sens) from road surface
        
        % Window and ventilated air
        buildingTerm(2) = buildingTerm(2) +...
            frac_j*(A_window*U_window+Rate_vent*V_bldg*r_air*Cp_air);
        
        % Wall LW term
        wallTerm(2) = wallTerm(2) +...
            frac_j*(wall.aeroCond*Cp_air*r_air+LW_wall)*A_wall;
        
        % Road to canyon LW term
        roadTerm(2) = roadTerm(2) +...
            frac_j*(road.aeroCond*Cp_air*r_air+LW_road)*A_road;
        
        % Building humidity term
        buildingTerm(3) = buildingTerm(3) +...
            frac_j*(building.indoorHum*Rate_vent*V_bldg*r_air*parameter.lv +...
                Qlat_waste*(wdth_canyon+wdth_bld));

        % Latent heat from road
        roadTerm(3) = roadTerm(3)+ frac_j*road.lat*A_road;
        
        % Building ventilation term
        buildingTerm(4) = buildingTerm(4) +...
            frac_j*Rate_vent*V_bldg*r_air*parameter.lv;
        
        % Sensible Heat Exchange
        Qsens_wall = Qsens_wall + frac_j*wall.aeroCond*Cp_air*r_air*A_wall*(T_wall-T_canyon);           % Sensible heat from wall
        Qsens_window = Qsens_window + frac_j*A_window*U_window*(T_indoor-T_canyon);                     % Sensible heat from window
        Qsens_road = Qsens_road + frac_j*road.aeroCond*Cp_air*r_air*A_road*(T_road-T_canyon);           % Sensible heat from road
        Qsens_hvac = Qsens_hvac + frac_j*Qsens_waste*(wdth_canyon+wdth_bld);                            % HVAC waste heat dumped into canyon

        % Longwave Heat Exchange
        Qir_wall = Qir_wall + frac_j*LW_wall*A_wall*(T_wall-T_canyon);     % LW heat from wall
        Qir_road = Qir_road + frac_j*LW_road*A_road*(T_road-T_canyon);     % LW heat from road
        Qir_ubl = Qir_ubl + frac_j*LW_sky*wdth_canyon*(T_sky - T_canyon);   % LW heat from sky

        % Convective (mass flow) heat exchange
        Qconv_vent = Qconv_vent + frac_j*Rate_vent*V_bldg*r_air*Cp_air*(T_indoor-T_canyon);     % Heat/mass exchange from vent
        Qconv_ubl = Qconv_ubl + frac_j*urbanArea.uExch*Cp_air*r_air*A_road*(T_ubl-T_canyon);    % Heat/mass exchange from UBL
                
    end
    
    % urban air temperature
    Ccan = Cp_air*r_air*(2*wdth_canyon*hght_bld+wdth_bld*hght_bld)/simParam.dt;  
    urbanArea.canTemp = (urbanArea.canTemp*Ccan +...
        wallTerm(1) + buildingTerm(1) + roadTerm(1)+... 
        T_ubl*urbanArea.uExch*Cp_air*r_air*A_road + ...
        T_sky*LW_sky*wdth_canyon + ...
        urbanArea.sensAnthrop*(wdth_canyon+wdth_bld)+urbanArea.treeSensHeat*A_road)/(Ccan +...
        wallTerm(2) + buildingTerm(2) + roadTerm(2) +...
        urbanArea.uExch*Cp_air*r_air*A_road + LW_sky*wdth_canyon);
    
    % urban air humidity
    Ccan = parameter.lv*r_air*(2*wdth_canyon*hght_bld+wdth_bld*hght_bld)/simParam.dt;  
    urbanArea.canHum = (urbanArea.canHum*Ccan +...
        buildingTerm(3) + roadTerm(3) +...
        forc.hum*urbanArea.uExch*parameter.lv*r_air*A_road + ...
        urbanArea.latAnthrop*(wdth_canyon+wdth_bld)+...
        urbanArea.treeLatHeat*A_road)/(Ccan +...
        buildingTerm(4) + urbanArea.uExch*parameter.lv*r_air*A_road);
    
    % Assign heat fluxes to class variables
    urbanArea.Qsens_wall = Qsens_wall;
    urbanArea.Qsens_window = Qsens_window;
    urbanArea.Qsens_road = Qsens_road;
    urbanArea.Qsens_hvac = Qsens_hvac;    
    urbanArea.Qsens_traffic = Qsens_traffic;  
    urbanArea.Qir_ubl = Qir_ubl;        
    urbanArea.Qir_wall = Qir_wall;       
    urbanArea.Qir_road = Qir_road;       
    urbanArea.Qconv_ubl = Qconv_ubl;      
    urbanArea.Qconv_vent = Qconv_vent;     

end