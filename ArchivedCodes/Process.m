function mat = Process(xmlmat)
    % Function added by Joseph Yang
    % This function takes in the material definition from XML and creates 
    % the material class of Element type, to simplify the original script.

    mat = [];
    materials = xmlmat;
    k = xmlmat.thermalConductivity;
    Vhc = xmlmat.volumetricHeatCapacity;
    if numel(xmlmat.thickness)>1
        for j = 1:numel(xmlmat.thickness)
            mat = [mat Material(k{j},Vhc{j})];
        end
    else
        % Divide single layer into two (UWG assumes at least 2 layers)
        materials.thickness = [materials.thickness/2 materials.thickness/2];
        roadMat = [Material(k,Vhc) Material(k,Vhc)];
    end
    mat = Element(urbanRoad.albedo,urbanRoad.emissivity,materials.thickness,roadMat,...
        urbanRoad.vegetationCoverage,urbanRoad.initialTemperature + 273.15,xmlUArea.urbanRoad.inclination);
end