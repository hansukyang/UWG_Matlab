classdef Element
     properties
            albedo;          % outer surface albedo
            emissivity;      % outer surface emissivity
            layerThickness;  % vector of layer thicknesses (m)
            layerThermalCond;% vector of layer thermal conductivities (W m-1 K-1)
            layerVolHeat;    % vector of layer volumetric heat (J m-3 K-1)
            vegCoverage;     % surface vegetation coverage
            layerTemp;       % vector of layer temperatures (K)
            waterStorage;    % thickness of water film (m) (only for horizontal surfaces)
            horizontal;      % 1-horizontal, 0-vertical
            solRec;          % solar radiation received (W m-2)
            infra;           % net longwave radiation (W m-2)
            lat;             % surface latent heat flux (W m-2)
            sens;            % surface sensible heat flux (W m-2)
            solAbs;          % solar radiation absorbed (W m-2)
            aeroCond;        % aerodynamic conductance of the surface
     end
        
     methods
        function obj = Element(albedo,emissivity,layerThickness,...
                layerMaterial,vegCoverage,initialTemp,horizontal)
            % class constructor
            if(nargin > 0)
                if ne(numel(layerThickness),numel(layerMaterial))
                    disp('-----------------------------------------')
                    disp('ERROR: the number of layer thickness must')
                    disp('match the number of layer materials');
                    disp('-----------------------------------------')
                else
                    obj.albedo = albedo;
                    obj.emissivity = emissivity;
                    obj.layerThickness = layerThickness;
                    obj.layerThermalCond = zeros(numel(layerMaterial),1);
                    obj.layerVolHeat = zeros(numel(layerMaterial),1);
                    for ilayer = 1:numel(layerMaterial)
                        obj.layerThermalCond(ilayer) = layerMaterial(ilayer).thermalCond;
                        obj.layerVolHeat(ilayer) = layerMaterial(ilayer).volHeat;
                    end 
                    obj.vegCoverage = vegCoverage;
                    obj.layerTemp = initialTemp*ones(numel(layerThickness),1);
                    obj.waterStorage = 0.;
                    obj.horizontal = horizontal;
                    obj.sens = 0.;
                end
            end
        end
        
        function obj = SurfFlux(obj,forc,parameter,simParam,humRef,tempRef,...
                windRef,boundCond,intFlux)
            % air density
            dens = Density(tempRef,humRef,forc.pres);
            % sensible heat from vegetation
            vegSens = 0;
            % solar radiation and latent heat
            if (obj.horizontal)
                % aerodynamic conductance of the surface (m s-1)
                obj.aeroCond = (5.8+3.7*windRef)/parameter.cp/dens;
                % saturation specific humidity of the soil
                qtsat = qsat(obj.layerTemp(1),forc.pres,parameter);
                % evaporation (m s-1)
                if gt(obj.waterStorage,0)
                    eg = obj.aeroCond*parameter.colburn*dens*(qtsat-humRef)/parameter.waterDens;
                else
                    eg = 0;
                end
                % film water content (m)
                obj.waterStorage = min(obj.waterStorage +...
                    simParam.dt*(forc.prec-eg),parameter.wgmax);
                obj.waterStorage = max(obj.waterStorage,0);
                % latent heat from film evaporation
                soilLat = eg*parameter.waterDens*parameter.lv;
                % latent heat from vegetation
                if lt(simParam.month,parameter.vegStart) && gt(simParam.month,parameter.vegEnd)
                    obj.solAbs = (1-obj.albedo)*obj.solRec;
                    vegLat = 0;
                else
                    obj.solAbs = ((1-obj.vegCoverage)*(1-obj.albedo)+...
                        obj.vegCoverage*(1-parameter.vegAlbedo))*obj.solRec;
                    vegLat = obj.vegCoverage*parameter.grassFLat*(1-parameter.vegAlbedo)*obj.solRec;
                    vegSens = obj.vegCoverage*(1.-parameter.grassFLat)*(1-parameter.vegAlbedo)*obj.solRec;
                end
                obj.lat = soilLat + vegLat;
            else
                % aerodynamic conductance of the surface
                obj.aeroCond = (5.8+3.7*windRef)/parameter.cp/dens;
                obj.solAbs = (1-obj.albedo)*obj.solRec;
                obj.lat = 0;
            end
            % sensible heat flux
            obj.sens = vegSens + obj.aeroCond*parameter.cp*dens*(obj.layerTemp(1)-tempRef);
            % net flux
            flux = - obj.sens+obj.solAbs+obj.infra-obj.lat;
            % transient heat diffusion equation
            obj.layerTemp = TransientConduction(obj.layerTemp,...
                simParam.dt,obj.layerVolHeat,obj.layerThermalCond,...
                obj.layerThickness,flux,boundCond,forc.deepTemp,intFlux); 
        end
     end
end