function [newmat, newthickness] = procMat(materials,max_thickness,min_thickness)
    % This function processes material layer so that a material with single
    % layer thickness is divided into two and material layer that is too
    % thick is subdivided
    
    newmat = [];
    newthickness = [];

    k = materials.thermalConductivity;
    Vhc = materials.volumetricHeatCapacity;
    if numel(materials.thickness)>1
        for j = 1:numel(materials.thickness)
            % Break up each layer that's more than 5cm thick
            if materials.thickness(j) > max_thickness
                nlayers = ceil(materials.thickness(j)/max_thickness);
                for l = 1:nlayers
                    newmat = [newmat Material(k{j},Vhc{j})];
                    newthickness = [newthickness; materials.thickness(j)/nlayers];
                end
                % testing... material should be at least 1cm thick.
            elseif materials.thickness(j) < min_thickness
                newmat = [newmat Material(k{j},Vhc{j})];
                newthickness = [newthickness; min_thickness];
            else
                newmat = [newmat Material(k{j},Vhc{j})];
                newthickness = [newthickness; materials.thickness(j)];
            end
        end
    else
        % Divide single layer into two (UWG assumes at least 2 layers)
        if materials.thickness > max_thickness
            nlayers = ceil(materials.thickness/max_thickness);
            for l = 1:nlayers
                newmat = [newmat Material(k,Vhc)];
                newthickness = [newthickness; materials.thickness/nlayers];
            end
        % testing... material should be at least 1cm thick.
        elseif materials.thickness < min_thickness
            newthickness = [min_thickness/2; min_thickness/2];
            newmat = [Material(k,Vhc) Material(k,Vhc)];
        else
            newthickness = [materials.thickness/2; materials.thickness/2];
            newmat = [Material(k,Vhc) Material(k,Vhc)];
        end
    end
end