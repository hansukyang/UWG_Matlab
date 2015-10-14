classdef ReferenceSite
    %CITY Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        lat;           % latitude (deg)
        lon;           % longitude (deg)
        height         % average obstacle height (m)
        z0r;           % rural roughness length (m)
        disp;          % rural displacement length (m)
        z;             % vertical height (m)
        dz;            % vertical discretization (m)
        nz0;           % layer number at zmt (m)
        nzref;         % layer number at zref (m)
        nzfor;         % layer number at zfor (m)
        nz10;          % layer number at zmu (m)
        nzi;           % layer number at zi_d (m)
        tempProf;      % potential temperature profile at the rural site (K)
        presProf;      % pressure profile at the rural site (Pa)
        tempRealProf;  % real temperature profile at the rural site (K)
        densityProfC;  % density profile at the center of layers (kg m-3)
        densityProfS;  % density profile at the sides of layers (kg m-3)
        windProf;      % wind profile at the rural site (m s-1)
        ublPres;       % Average pressure at the UBL (Pa)
    end
    
  
    methods
        function obj = ReferenceSite(lat,lon,height,initialTemp,initialPres,parameter)
            % class constructor
            load -ascii z_meso.txt;
            if(nargin > 0)
                obj.lat = lat;
                obj.lon = lon;
                obj.height = height;
                obj.z0r = 0.1*height;
                obj.disp = 0.5*height;
                % vertical grid at the rural site
                obj.z  = zeros(numel(z_meso)-1,1);
                obj.dz = zeros(numel(z_meso)-1,1);
                for zi=1:numel(z_meso)-1
                    obj.z(zi) = 0.5*(z_meso(zi)+z_meso(zi+1));
                    obj.dz(zi) = z_meso(zi+1) - z_meso(zi);
                end
                ll = 1;
                mm = 1;
                nn = 1;
                oo = 1;
                pp = 1;
                for iz=1:55  
                   if (obj.z(iz)>=parameter.tempHeight && ll==1) 
                      obj.nz0 = iz;
                      ll = 0;
                   end  
                   if (obj.z(iz)>=parameter.refHeight && mm==1) 
                      obj.nzref = iz;
                      mm = 0;
                   end   
                   if (obj.z(iz)>=parameter.nightBLHeight && nn==1) 
                      obj.nzfor = iz;
                      nn = 0;
                   end   
                   if (obj.z(iz)>=parameter.windHeight && oo==1) 
                      obj.nz10 = iz;
                      oo = 0;
                   end   
                   if (obj.z(iz)>=parameter.dayBLHeight && pp==1) 
                      obj.nzi = iz;
                      pp = 0;
                   end   
                end
                % vertical profiles at the rural site
                obj.tempProf = ones(1,obj.nzref)*initialTemp;
                obj.presProf = ones(1,obj.nzref)*initialPres;
                for iz=2:obj.nzref;
                   obj.presProf(iz) = (obj.presProf(iz-1)^(parameter.r/parameter.cp)-...
                       parameter.g/parameter.cp*(initialPres^(parameter.r/parameter.cp))*(1./obj.tempProf(iz)+...
                       1./obj.tempProf(iz-1))*0.5*obj.dz(iz))^(1./(parameter.r/parameter.cp));
                end
                obj.tempRealProf = ones(1,obj.nzref)*initialTemp;
                for iz=1:obj.nzref;
                   obj.tempRealProf(iz)=obj.tempProf(iz)*...
                       (obj.presProf(iz)/initialPres)^(parameter.r/parameter.cp);
                end
                obj.densityProfC = ones(1,obj.nzref);
                for iz=1:obj.nzref;
                   obj.densityProfC(iz)=obj.presProf(iz)/parameter.r/obj.tempRealProf(iz);
                end
                                obj.densityProfS = obj.densityProfC(1)*ones(1,obj.nzref+1);
                for iz=2:obj.nzref;
                   obj.densityProfS(iz)=(obj.densityProfC(iz)*obj.dz(iz-1)+...
                       obj.densityProfC(iz-1)*obj.dz(iz))/(obj.dz(iz-1)+obj.dz(iz));
                end
                obj.densityProfS(obj.nzref+1)=obj.densityProfC(obj.nzref);
                obj.windProf = ones(1,obj.nzref);
            end
        end
            
        function obj = VerticalDifussionModel( obj,forc,rural,parameter,simParam )
            % Lower boundary condition  
            obj.tempProf(1) = forc.temp;
            % compute pressure profile
            for iz=obj.nzref:-1:2
               obj.presProf(iz-1)=(obj.presProf(iz)^(parameter.r/parameter.cp)+...
                   parameter.g/parameter.cp*(forc.pres^(parameter.r/parameter.cp))*...
                   (1./obj.tempProf(iz)+1./obj.tempProf(iz-1))*...
                   0.5*obj.dz(iz))^(1./(parameter.r/parameter.cp));
            end
            % compute the real temperature profile
            for iz=1:obj.nzref
               obj.tempRealProf(iz)=obj.tempProf(iz)*...
                   (obj.presProf(iz)/forc.pres)^(parameter.r/parameter.cp);
            end
            % compute the density profile
            for iz=1:obj.nzref
               obj.densityProfC(iz)=obj.presProf(iz)/parameter.r/obj.tempRealProf(iz);
            end
            obj.densityProfS(1)=obj.densityProfC(1);
            for iz=2:obj.nzref
               obj.densityProfS(iz)=(obj.densityProfC(iz)*obj.dz(iz-1)+...
                   obj.densityProfC(iz-1)*obj.dz(iz))/(obj.dz(iz-1)+obj.dz(iz));
            end
            obj.densityProfS(obj.nzref+1)=obj.densityProfC(obj.nzref);
            % compute diffusion coefficient
            [cd,ustarRur] = DiffusionCoefficient(obj.densityProfC(1),...
                obj.z,obj.dz,obj.z0r,obj.disp,...
                obj.tempProf(1),rural.sens,obj.nzref,forc.wind,...
                obj.tempProf,parameter);
            % solve diffusion equation
            obj.tempProf = DiffusionEquation(obj.nzref,simParam.dt,...
                obj.tempProf,obj.densityProfC,obj.densityProfS,cd,obj.dz);
            % compute wind profile
            for iz=1:obj.nzref
                obj.windProf(iz) = ustarRur/parameter.vk*...
                    log((obj.z(iz)-obj.disp)/obj.z0r);
            end
            % Average pressure
            obj.ublPres = 0;
            for iz=1:obj.nzfor
                obj.ublPres = obj.ublPres +...
                    obj.presProf(iz)*obj.dz(iz)/...
                    (obj.z(obj.nzref)+obj.dz(obj.nzref)/2);
            end
        end
        
      
        
    end
    
end

