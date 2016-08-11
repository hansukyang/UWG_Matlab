classdef UBLDef
    %   Class definition for the Urban Boundary Layer (UBL)
    
    properties
        location;      % relative location within a city (N,NE,E,SE,S,SW,W,NW,C)
        charLength;    % characteristic length of the urban area (m)
        perimeter;     % urban area perimeter (m)
        urbArea;       % horizontal urban area (m2)
        orthLength;    % length of the side of the urban area orthogonal 
                       % to the wind direction (m)
        paralLength;   % length of the side of the urban area paralell 
                       % to the wind direction (m)
        ublTemp;       % urban boundary layer temperature (K)
        ublTempdx;     % urban boundary layer temperature discretization (K)
        ublEmis;       % UBL emissivity due to water vapor
        atmTemp;       % urban surface temperature (K)
        surfTemp;      % average surface temperature seen from the UBL (K)
        advHeat;       % advection heat flux (W m-2)
        radHeat;       % net radiation heat flux (W m-2)
    end
    
    methods
        function obj = UBLDef(location,charLength,initialTemp,maxdx)
            % class constructor
            if(nargin > 0)
                obj.location = location;
                obj.charLength = charLength;
                obj.perimeter = 4*charLength;
                obj.urbArea = charLength^2.;
                obj.orthLength = charLength;
                numdx = round(charLength/min(charLength,maxdx));
                obj.paralLength = charLength/numdx;
                obj.ublTemp = initialTemp;
                obj.ublTempdx = initialTemp*ones(1,numdx);
                obj.atmTemp = initialTemp;
                obj.surfTemp = initialTemp;
            end
        end  
        
        function obj = UBLModel(obj,sensHeat,RSM,rural,forc,parameter,simTime,first,second,third)
            % average urban sensible heat flux
            urbanSensHeat = 0;
            sumAreas = 0;
            for i=1:numel(obj)
                urbanSensHeat = urbanSensHeat + sensHeat(i)*obj(i).urbArea; 
                sumAreas = sumAreas + obj(i).urbArea;
            end
            urbanSensHeat = urbanSensHeat/sumAreas;
            % urban-rural sensible heat flux difference
            heatDif = max(urbanSensHeat - rural.sens,0);
            % Average air density
            refDens = 0;
            for iz=1:RSM.nzref
                refDens = refDens +...
                    RSM.densityProfC(iz)*RSM.dz(iz)/...
                    (RSM.z(RSM.nzref)+RSM.dz(RSM.nzref)/2);
            end
            forDens = 0;
            for iz=1:RSM.nzfor
                forDens = forDens +...
                    RSM.densityProfC(iz)*RSM.dz(iz)/...
                    (RSM.z(RSM.nzfor)+RSM.dz(RSM.nzfor)/2);
            end
            % ---------------------------------------------------------------------
            % Day
            % ---------------------------------------------------------------------
            if (gt(forc.dir+forc.dif,parameter.dayThreshold) && le(simTime.secDay,12*3600)) ||...
                    (gt(forc.dir+forc.dif,parameter.nightThreshold) && gt(simTime.secDay,12*3600)) ||...
                    gt(urbanSensHeat,150)
                eqTemp = RSM.tempProf(RSM.nzref);
                eqWind = RSM.windProf(RSM.nzref);
                circWind = parameter.circCoeff*(parameter.g*heatDif/parameter.cp/refDens/...
                    eqTemp*parameter.dayBLHeight)^(1./3.);
            % forced problem
%                 if gt(forc.wind,circWind) 
%                   if gt(numel(obj),1) % more than one urban area
%                     firstTemp = 0.;
%                     for i = 1:numel(first)
%                     obj(first(i)).ublTemp = DayForced(forc,obj(first(i)).ublTemp,...
%                         eqTemp,sensHeat(first(i)),simTime.dt,parameter,...
%                         refDens,eqWind,obj(first(i)).orthLength,obj(first(i)).urbArea); 
%                     firstTemp = firstTemp + obj(first(i)).ublTemp;
%                     end
%                     firstTemp = firstTemp/numel(first);
%                     secondTemp = 0.;
%                     for i = 1:numel(second)
%                     obj(second(i)).ublTemp = DayForced(forc,obj(second(i)).ublTemp,...
%                         firstTemp,sensHeat(second(i)),simTime.dt,parameter,...
%                         refDens,eqWind,obj(second(i)).orthLength,obj(second(i)).urbArea);
%                     secondTemp = secondTemp + obj(second(i)).ublTemp;
%                     end
%                     secondTemp = secondTemp/numel(second);
%                     if ne(numel(third),0)
%                         for i = 1:numel(third) 
%                             obj(third(i)).ublTemp = DayForced(forc,obj(third(i)).ublTemp,...
%                                 secondTemp,sensHeat(third(i)),simTime.dt,parameter,...
%                                 refDens,eqWind,obj(third(i)).orthLength,obj(third(i)).urbArea);
%                         end
%                     end
%                   else % One urban area
                        obj.ublTemp = DayForced(forc,obj.ublTemp,...
                        eqTemp,sensHeat,simTime.dt,parameter,...
                        refDens,eqWind,obj.orthLength,obj.urbArea);
%                   end
            % convective problem
                else
%                   if gt(numel(obj),1) % more than one urban area
%                     perUblTemp = 0.;
%                     perUblCount = 0;
%                     for i = 1:numel(obj)
%                         if strcmpi(obj(i).location,'NW')||strcmpi(obj(i).location,'N')||...
%                             strcmpi(obj(i).location,'NE')||strcmpi(obj(i).location,'E')||...
%                             strcmpi(obj(i).location,'SE')||strcmpi(obj(i).location,'S')||...
%                             strcmpi(obj(i).location,'SW')||strcmpi(obj(i).location,'W')
%                             obj(i).ublTemp = DayConv(forc,obj(i).ublTemp,...
%                                 eqTemp,sensHeat(i),simTime.dt,parameter,...
%                                 refDens,circWind,obj(i).perimeter/2,obj(i).urbArea);
%                             perUblTemp = perUblTemp + obj(i).ublTemp;
%                             perUblCount = perUblCount + 1;
%                             obj(i).ublTempdx(:)= obj(i).ublTemp;
%                         end
%                     end
%                     perUblTemp = perUblTemp/perUblCount;
%                     for i = 1:numel(obj)
%                         if strcmpi(obj(i).location,'C')
%                         obj(i).ublTemp = DayConv(forc,obj(i).ublTemp,...
%                             perUblTemp,sensHeat(i),simTime.dt,parameter,...
%                             refDens,circWind,obj(i).perimeter,obj(i).urbArea);
%                         obj(i).ublTempdx(:)= obj(i).ublTemp;
%                         end
%                     end
%                   else % One urban area
                    obj.ublTemp = DayConv(forc,obj.ublTemp,...
                        eqTemp,sensHeat,simTime.dt,parameter,...
                        refDens,circWind,obj.perimeter,obj.urbArea);
                    obj.ublTempdx(:)= obj.ublTemp;  
%                   end
                end
            % ---------------------------------------------------------------------
            % night
            % ---------------------------------------------------------------------
            else
%                if gt(numel(obj),1) % more than one urban area
%                   firstTemp = 0.;
%                   for i = 1:numel(first)
%                       [obj(first(i)).ublTemp,obj(first(i)).ublTempdx] = NightForc(obj(first(i)).ublTempdx,...
%                           sensHeat(first(i)),simTime.dt,...
%                           parameter,forDens,obj(first(i)).paralLength,obj(first(i)).charLength,...
%                           RSM,obj(first(i)).ublEmis,obj(first(i)).atmTemp,obj(first(i)).surfTemp);
%                       firstTemp = firstTemp + obj(first(i)).ublTemp;
%                   end
%                   firstTemp = firstTemp/numel(first);
%                   secondTemp = 0.;
%                   for i = 1:numel(second)
%                       [obj(second(i)).ublTemp,obj(second(i)).ublTempdx] = NightForcUrb(obj(second(i)).ublTempdx,...
%                           firstTemp,sensHeat(second(i)),simTime.dt,...
%                           parameter,forDens,obj(second(i)).paralLength,obj(second(i)).charLength,...
%                           RSM,obj(second(i)).ublEmis,obj(second(i)).atmTemp,obj(second(i)).surfTemp);     
%                       secondTemp = secondTemp + obj(second(i)).ublTemp;
%                   end
%                   secondTemp = secondTemp/numel(second);
%                   if ne(numel(third),0)
%                         for i = 1:numel(third) 
%                           [obj(third(i)).ublTemp,obj(third(i)).ublTempdx] = NightForcUrb(obj(third(i)).ublTempdx,...
%                           secondTemp,sensHeat(third(i)),simTime.dt,...
%                           parameter,forDens,obj(third(i)).paralLength,obj(third(i)).charLength,...
%                           RSM,obj(third(i)).ublEmis,obj(third(i)).atmTemp,obj(third(i)).surfTemp);
%                         end
%                   end
%                else % One urban area
                  [obj.ublTemp,obj.ublTempdx] = NightForc(obj.ublTempdx,...
                      sensHeat,simTime.dt,...
                      parameter,forDens,obj.paralLength,obj.charLength,...
                      RSM,obj.ublEmis,obj.atmTemp,obj.surfTemp);
%                end
            end
        end
    end
end

function ublTemp = DayForced(forc,ublTemp,eqTemp,sensHeat,dt,parameter,refDens,wind,orthLength,area)
    surfCoef = sensHeat*dt/parameter.dayBLHeight/parameter.cp/refDens*1.4;
    radCoef = -forc.infra*dt/parameter.dayBLHeight/parameter.cp/refDens*1.4;
    advCoef  = orthLength*wind*dt/area*1.4;
    ublTemp = (surfCoef + advCoef*eqTemp + ublTemp + radCoef)/(1 + advCoef); 
end

function ublTemp = DayConv(forc,ublTemp,eqTemp,sensHeat,dt,parameter,refDens,circWind,perimeter,area)
    surfCoef = sensHeat*dt/parameter.dayBLHeight/parameter.cp/refDens*1.4;
    radCoef = -forc.infra*dt/parameter.dayBLHeight/parameter.cp/refDens*1.4;
    advCoef  = perimeter*circWind*dt/area*1.4;
    ublTemp = (surfCoef + advCoef*eqTemp + ublTemp + radCoef)/(1 + advCoef);
end

function [ublTemp,ublTempdx] = NightForc(ublTempdx,sensHeat,dt,parameter,...
    forDens,paralLength,charLength,RSM,ublEmis,atmTemp,surfTemp)  
      radCoef1 = 4.*ublEmis*parameter.sigma*((atmTemp+mean(ublTempdx))/2)^3.*dt/...
          parameter.nightBLHeight/parameter.cp/forDens*1.4;
      radCoef2 = 4.*ublEmis*parameter.sigma*((surfTemp+mean(ublTempdx))/2)^3.*dt/...
          parameter.nightBLHeight/parameter.cp/forDens*1.4;
      surfCoef = sensHeat*dt/parameter.nightBLHeight/parameter.cp/forDens*1.4;
      intAdv1 = 0;
      for iz=1:RSM.nzfor
          intAdv1 = intAdv1 + RSM.windProf(iz)*RSM.tempProf(iz)*RSM.dz(iz);
      end
      advCoef1 = 1.4*dt/paralLength/parameter.nightBLHeight*intAdv1;
      intAdv2 = 0;
      for iz=1:RSM.nzfor
          intAdv2 = intAdv2 + RSM.windProf(iz)*RSM.dz(iz);
      end
      advCoef2 = 1.4*dt/paralLength/parameter.nightBLHeight*intAdv2;
      ublTempdx(1) = (surfCoef + advCoef1 + ublTempdx(1) + radCoef1*atmTemp + radCoef2*surfTemp)/(1 + advCoef2 + radCoef1 + radCoef2);    
      ublTemp   = ublTempdx(1);
      for i=2:(charLength/paralLength)
         eqTemp   = ublTempdx(i-1);
         ublTempdx(i) = (surfCoef + advCoef2*eqTemp + ublTempdx(i) + radCoef1*atmTemp + radCoef2*surfTemp)/(1 + advCoef2 + radCoef1 + radCoef2); 
         ublTemp = ublTemp + ublTempdx(i);
      end
      ublTemp = ublTemp/charLength*paralLength;
end

function [ublTemp,ublTempdx] = NightForcUrb(ublTempdx,eqTemp,sensHeat,dt,parameter,...
    forDens,paralLength,charLength,RSM,ublEmis,atmTemp,surfTemp)  
      radCoef1 = 4.*ublEmis*parameter.sigma*((atmTemp+mean(ublTempdx))/2)^3.*dt/...
          parameter.nightBLHeight/parameter.cp/forDens*1.4;
      radCoef2 = 4.*ublEmis*parameter.sigma*((surfTemp+mean(ublTempdx))/2)^3.*dt/...
          parameter.nightBLHeight/parameter.cp/forDens*1.4;
      surfCoef = sensHeat*dt/parameter.nightBLHeight/parameter.cp/forDens*1.4;
      intAdv1 = 0;
      for iz=1:RSM.nzfor
          intAdv1 = intAdv1 + RSM.windProf(iz)*RSM.dz(iz);
      end
      advCoef1 = 1.4*dt/paralLength/parameter.nightBLHeight*intAdv1;
      ublTempdx(1) = (surfCoef + advCoef1*eqTemp + ublTempdx(1) + radCoef1*atmTemp + radCoef2*surfTemp)/(1 + advCoef1 + radCoef1 + radCoef2);    
      ublTemp   = ublTempdx(1);
      for i=2:(charLength/paralLength)
         eqTemp   = ublTempdx(i-1);
         ublTempdx(i) = (surfCoef + advCoef1*eqTemp + ublTempdx(i) + radCoef1*atmTemp + radCoef2*surfTemp)/(1 + advCoef1 + radCoef1 + radCoef2); 
         ublTemp = ublTemp + ublTempdx(i);
      end
      ublTemp = ublTemp/charLength*paralLength;
end
