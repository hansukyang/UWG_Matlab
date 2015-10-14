function ublVars = UrbanBoundaryLayerModel(ublVars,sensHeat,refSite,rural,forc,...
        parameter,simParam,first,second,third)
    % average urban sensible heat flux
    urbanSensHeat = 0;
    sumAreas = 0;
    for i=1:numel(ublVars)
        urbanSensHeat = urbanSensHeat + sensHeat(i)*ublVars(i).urbArea; 
        sumAreas = sumAreas + ublVars(i).urbArea;
    end
    urbanSensHeat = urbanSensHeat/sumAreas;
    % urban-rural sensible heat flux difference
    heatDif = max(urbanSensHeat - rural.sens,0);
    % Average air density
    refDens = 0;
    for iz=1:refSite.nzref
        refDens = refDens +...
            refSite.densityProfC(iz)*refSite.dz(iz)/...
            (refSite.z(refSite.nzref)+refSite.dz(refSite.nzref)/2);
    end
    forDens = 0;
    for iz=1:refSite.nzfor
        forDens = forDens +...
            refSite.densityProfC(iz)*refSite.dz(iz)/...
            (refSite.z(refSite.nzfor)+refSite.dz(refSite.nzfor)/2);
    end
    % ---------------------------------------------------------------------
    % day
    % ---------------------------------------------------------------------
    if (gt(forc.dir+forc.dif,parameter.dayThreshold) && le(simParam.secDay,12*3600)) ||...
            (gt(forc.dir+forc.dif,parameter.nightThreshold) && gt(simParam.secDay,12*3600)) ||...
            gt(urbanSensHeat,150)
        eqTemp   = refSite.tempProf(refSite.nzref);
        eqWind   = refSite.windProf(refSite.nzref);
        circWind = parameter.circCoeff*(parameter.g*heatDif/parameter.cp/refDens/...
            eqTemp*parameter.dayBLHeight)^(1./3.);
    % forced problem
        if gt(forc.wind,circWind) 
%             disp('day-forc')
          if gt(numel(ublVars),1) % more than one urban area
            firstTemp = 0.;
            for i = 1:numel(first)
            ublVars(first(i)).ublTemp = DayForced(forc,ublVars(first(i)).ublTemp,...
                eqTemp,sensHeat(first(i)),simParam.dt,parameter,...
                refDens,eqWind,ublVars(first(i)).orthLength,ublVars(first(i)).urbArea); 
            firstTemp = firstTemp + ublVars(first(i)).ublTemp;
            end
            firstTemp = firstTemp/numel(first);
            secondTemp = 0.;
            for i = 1:numel(second)
            ublVars(second(i)).ublTemp = DayForced(forc,ublVars(second(i)).ublTemp,...
                firstTemp,sensHeat(second(i)),simParam.dt,parameter,...
                refDens,eqWind,ublVars(second(i)).orthLength,ublVars(second(i)).urbArea);
            secondTemp = secondTemp + ublVars(second(i)).ublTemp;
            end
            secondTemp = secondTemp/numel(second);
            if ne(numel(third),0)
                for i = 1:numel(third) 
                    ublVars(third(i)).ublTemp = DayForced(forc,ublVars(third(i)).ublTemp,...
                        secondTemp,sensHeat(third(i)),simParam.dt,parameter,...
                        refDens,eqWind,ublVars(third(i)).orthLength,ublVars(third(i)).urbArea);
                end
            end
          else % One urban area
                ublVars.ublTemp = DayForced(forc,ublVars.ublTemp,...
                eqTemp,sensHeat,simParam.dt,parameter,...
                refDens,eqWind,ublVars.orthLength,ublVars.urbArea);
          end
    % convective problem
        else
%             disp('day-conv')
          if gt(numel(ublVars),1) % more than one urban area
            perUblTemp = 0.;
            perUblCount = 0;
            for i = 1:numel(ublVars)
                if strcmpi(ublVars(i).location,'NW')||strcmpi(ublVars(i).location,'N')||...
                    strcmpi(ublVars(i).location,'NE')||strcmpi(ublVars(i).location,'E')||...
                    strcmpi(ublVars(i).location,'SE')||strcmpi(ublVars(i).location,'S')||...
                    strcmpi(ublVars(i).location,'SW')||strcmpi(ublVars(i).location,'W')
                    ublVars(i).ublTemp = DayConv(forc,ublVars(i).ublTemp,...
                        eqTemp,sensHeat(i),simParam.dt,parameter,...
                        refDens,circWind,ublVars(i).perimeter/2,ublVars(i).urbArea);
                    perUblTemp = perUblTemp + ublVars(i).ublTemp;
                    perUblCount = perUblCount + 1;
                    ublVars(i).ublTempdx(:)= ublVars(i).ublTemp;
                end
            end
            perUblTemp = perUblTemp/perUblCount;
            for i = 1:numel(ublVars)
                if strcmpi(ublVars(i).location,'C')
                ublVars(i).ublTemp = DayConv(forc,ublVars(i).ublTemp,...
                    perUblTemp,sensHeat(i),simParam.dt,parameter,...
                    refDens,circWind,ublVars(i).perimeter,ublVars(i).urbArea);
                ublVars(i).ublTempdx(:)= ublVars(i).ublTemp;
                end
            end
          else % One urban area
            ublVars.ublTemp = DayConv(forc,ublVars.ublTemp,...
                eqTemp,sensHeat,simParam.dt,parameter,...
                refDens,circWind,ublVars.perimeter,ublVars.urbArea);
            ublVars.ublTempdx(:)= ublVars.ublTemp;  
          end
        end
    % ---------------------------------------------------------------------
    % night
    % ---------------------------------------------------------------------
    else
       if gt(numel(ublVars),1) % more than one urban area
          firstTemp = 0.;
          for i = 1:numel(first)
              [ublVars(first(i)).ublTemp,ublVars(first(i)).ublTempdx] = NightForc(ublVars(first(i)).ublTempdx,...
                  sensHeat(first(i)),simParam.dt,...
                  parameter,forDens,ublVars(first(i)).paralLength,ublVars(first(i)).charLength,...
                  refSite,ublVars(first(i)).ublEmis,ublVars(first(i)).atmTemp,ublVars(first(i)).surfTemp);
              firstTemp = firstTemp + ublVars(first(i)).ublTemp;
          end
          firstTemp = firstTemp/numel(first);
          secondTemp = 0.;
          for i = 1:numel(second)
              [ublVars(second(i)).ublTemp,ublVars(second(i)).ublTempdx] = NightForcUrb(ublVars(second(i)).ublTempdx,...
                  firstTemp,sensHeat(second(i)),simParam.dt,...
                  parameter,forDens,ublVars(second(i)).paralLength,ublVars(second(i)).charLength,...
                  refSite,ublVars(second(i)).ublEmis,ublVars(second(i)).atmTemp,ublVars(second(i)).surfTemp);     
              secondTemp = secondTemp + ublVars(second(i)).ublTemp;
          end
          secondTemp = secondTemp/numel(second);
          if ne(numel(third),0)
                for i = 1:numel(third) 
                  [ublVars(third(i)).ublTemp,ublVars(third(i)).ublTempdx] = NightForcUrb(ublVars(third(i)).ublTempdx,...
                  secondTemp,sensHeat(third(i)),simParam.dt,...
                  parameter,forDens,ublVars(third(i)).paralLength,ublVars(third(i)).charLength,...
                  refSite,ublVars(third(i)).ublEmis,ublVars(third(i)).atmTemp,ublVars(third(i)).surfTemp);
                end
          end
       else % One urban area
          [ublVars.ublTemp,ublVars.ublTempdx] = NightForc(ublVars.ublTempdx,...
              sensHeat,simParam.dt,...
              parameter,forDens,ublVars.paralLength,ublVars.charLength,...
              refSite,ublVars.ublEmis,ublVars.atmTemp,ublVars.surfTemp);
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
    forDens,paralLength,charLength,refSite,ublEmis,atmTemp,surfTemp)  
  radCoef1 = 4.*ublEmis*parameter.sigma*((atmTemp+mean(ublTempdx))/2)^3.*dt/...
      parameter.nightBLHeight/parameter.cp/forDens*1.4;
  radCoef2 = 4.*ublEmis*parameter.sigma*((surfTemp+mean(ublTempdx))/2)^3.*dt/...
      parameter.nightBLHeight/parameter.cp/forDens*1.4;
  surfCoef = sensHeat*dt/parameter.nightBLHeight/parameter.cp/forDens*1.4;
  intAdv1 = 0;
  for iz=1:refSite.nzfor
      intAdv1 = intAdv1 + refSite.windProf(iz)*refSite.tempProf(iz)*refSite.dz(iz);
  end
  advCoef1 = 1.4*dt/paralLength/parameter.nightBLHeight*intAdv1;
  intAdv2 = 0;
  for iz=1:refSite.nzfor
      intAdv2 = intAdv2 + refSite.windProf(iz)*refSite.dz(iz);
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
    forDens,paralLength,charLength,refSite,ublEmis,atmTemp,surfTemp)  
  radCoef1 = 4.*ublEmis*parameter.sigma*((atmTemp+mean(ublTempdx))/2)^3.*dt/...
      parameter.nightBLHeight/parameter.cp/forDens*1.4;
  radCoef2 = 4.*ublEmis*parameter.sigma*((surfTemp+mean(ublTempdx))/2)^3.*dt/...
      parameter.nightBLHeight/parameter.cp/forDens*1.4;
  surfCoef = sensHeat*dt/parameter.nightBLHeight/parameter.cp/forDens*1.4;
  intAdv1 = 0;
  for iz=1:refSite.nzfor
      intAdv1 = intAdv1 + refSite.windProf(iz)*refSite.dz(iz);
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

