function [Kt,ustar] = DiffusionCoefficient(rho,z,dz,z0,disp,...
    tempRur,heatRur,nz,uref,th,parameter)

% Initialization
Kt = zeros(1,nz+1);
ws = zeros(1,nz);
te = zeros(1,nz);
% Friction velocity (Louis 1979)
ustar = parameter.vk*uref/log((10.-disp)/z0);
% Monin-Obukhov length
lengthRur = max(- rho*parameter.cp*ustar^3*tempRur/parameter.vk/parameter.g/heatRur,-50);
% Unstable conditions
if gt(heatRur,1e-2)
    % Convective velocity scale
    wstar = (parameter.g*heatRur*parameter.dayBLHeight/rho/parameter.cp/tempRur)^(1/3);
    % Wind profile function
    phi_m = (1-8.*0.1*parameter.dayBLHeight/lengthRur)^(-1./3.);
    for iz=1:nz
        % Mixed-layer velocity scale
        ws(iz) = (ustar^3+phi_m*parameter.vk*wstar^3*z(iz)/parameter.dayBLHeight)^(1./3.);
        % TKE approximation
        te(iz) = max(ws(iz)^2.,0.01);
    end 
% Stable and neutral conditions
else
    for iz=1:nz
        % TKE approximation
        te(iz) = max(ustar^2.,0.01);
    end 
end
% lenght scales (l_up, l_down, l_k, l_eps)
[dlu,dld] = DissipationBougeault(parameter.g,nz,z,dz,te,th);
[dld,dls,dlk]= LengthBougeault(nz,dld,dlu,z);
% Boundary-layer diffusion coefficient
for iz=1:nz
   Kt(iz) = 0.4*dlk(iz)*sqrt(te(iz));
end
Kt(nz+1) = Kt(nz);

end