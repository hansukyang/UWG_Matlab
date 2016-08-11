function UBL = UBLModel(UBL,sensHeat,refSite,rural,forc,...
        parameter,simParam,first,second,third)
    % average urban sensible heat flux
    urbanSensHeat = 0;
    sumAreas = 0;
    for i=1:numel(UBL)
        urbanSensHeat = urbanSensHeat + sensHeat(i)*UBL(i).urbArea; 
        sumAreas = sumAreas + UBL(i).urbArea;
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
          if gt(numel(UBL),1) % more than one urban area
            firstTemp = 0.;
            for i = 1:numel(first)
            UBL(first(i)).ublTemp = DayForced(forc,UBL(first(i)).ublTemp,...
                eqTemp,sensHeat(first(i)),simParam.dt,parameter,...
                refDens,eqWind,UBL(first(i)).orthLength,UBL(first(i)).urbArea); 
            firstTemp = firstTemp + UBL(first(i)).ublTemp;
            end
            firstTemp = firstTemp/numel(first);
            secondTemp = 0.;
            for i = 1:numel(second)
            UBL(second(i)).ublTemp = DayForced(forc,UBL(second(i)).ublTemp,...
                firstTemp,sensHeat(second(i)),simParam.dt,parameter,...
                refDens,eqWind,UBL(second(i)).orthLength,UBL(second(i)).urbArea);
            secondTemp = secondTemp + UBL(second(i)).ublTemp;
            end
            secondTemp = secondTemp/numel(second);
            if ne(numel(third),0)
                for i = 1:numel(third) 
                    UBL(third(i)).ublTemp = DayForced(forc,UBL(third(i)).ublTemp,...
                        secondTemp,sensHeat(third(i)),simParam.dt,parameter,...
                        refDens,eqWind,UBL(third(i)).orthLength,UBL(third(i)).urbArea);
                end
            end
          else % One urban area
                UBL.ublTemp = DayForced(forc,UBL.ublTemp,...
                eqTemp,sensHeat,simParam.dt,parameter,...
                refDens,eqWind,UBL.orthLength,UBL.urbArea);
          end
    % convective problem
        else
%             disp('day-conv')
          if gt(numel(UBL),1) % more than one urban area
            perUblTemp = 0.;
            perUblCount = 0;
            for i = 1:numel(UBL)
                if strcmpi(UBL(i).location,'NW')||strcmpi(UBL(i).location,'N')||...
                    strcmpi(UBL(i).location,'NE')||strcmpi(UBL(i).location,'E')||...
                    strcmpi(UBL(i).location,'SE')||strcmpi(UBL(i).location,'S')||...
                    strcmpi(UBL(i).location,'SW')||strcmpi(UBL(i).location,'W')
                    UBL(i).ublTemp = DayConv(forc,UBL(i).ublTemp,...
                        eqTemp,sensHeat(i),simParam.dt,parameter,...
                        refDens,circWind,UBL(i).perimeter/2,UBL(i).urbArea);
                    perUblTemp = perUblTemp + UBL(i).ublTemp;
                    perUblCount = perUblCount + 1;
                    UBL(i).ublTempdx(:)= UBL(i).ublTemp;
                end
            end
            perUblTemp = perUblTemp/perUblCount;
            for i = 1:numel(UBL)
                if strcmpi(UBL(i).location,'C')
                UBL(i).ublTemp = DayConv(forc,UBL(i).ublTemp,...
                    perUblTemp,sensHeat(i),simParam.dt,parameter,...
                    refDens,circWind,UBL(i).perimeter,UBL(i).urbArea);
                UBL(i).ublTempdx(:)= UBL(i).ublTemp;
                end
            end
          else % One urban area
            UBL.ublTemp = DayConv(forc,UBL.ublTemp,...
                eqTemp,sensHeat,simParam.dt,parameter,...
                refDens,circWind,UBL.perimeter,UBL.urbArea);
            UBL.ublTempdx(:)= UBL.ublTemp;  
          end
        end
    % ---------------------------------------------------------------------
    % night
    % ---------------------------------------------------------------------
    else
       if gt(numel(UBL),1) % more than one urban area
          firstTemp = 0.;
          for i = 1:numel(first)
              [UBL(first(i)).ublTemp,UBL(first(i)).ublTempdx] = NightForc(UBL(first(i)).ublTempdx,...
                  sensHeat(first(i)),simParam.dt,...
                  parameter,forDens,UBL(first(i)).paralLength,UBL(first(i)).charLength,...
                  refSite,UBL(first(i)).ublEmis,UBL(first(i)).atmTemp,UBL(first(i)).surfTemp);
              firstTemp = firstTemp + UBL(first(i)).ublTemp;
          end
          firstTemp = firstTemp/numel(first);
          secondTemp = 0.;
          for i = 1:numel(second)
              [UBL(second(i)).ublTemp,UBL(second(i)).ublTempdx] = NightForcUrb(UBL(second(i)).ublTempdx,...
                  firstTemp,sensHeat(second(i)),simParam.dt,...
                  parameter,forDens,UBL(second(i)).paralLength,UBL(second(i)).charLength,...
                  refSite,UBL(second(i)).ublEmis,UBL(second(i)).atmTemp,UBL(second(i)).surfTemp);     
              secondTemp = secondTemp + UBL(second(i)).ublTemp;
          end
          secondTemp = secondTemp/numel(second);
          if ne(numel(third),0)
                for i = 1:numel(third) 
                  [UBL(third(i)).ublTemp,UBL(third(i)).ublTempdx] = NightForcUrb(UBL(third(i)).ublTempdx,...
                  secondTemp,sensHeat(third(i)),simParam.dt,...
                  parameter,forDens,UBL(third(i)).paralLength,UBL(third(i)).charLength,...
                  refSite,UBL(third(i)).ublEmis,UBL(third(i)).atmTemp,UBL(third(i)).surfTemp);
                end
          end
       else % One urban area
          [UBL.ublTemp,UBL.ublTempdx] = NightForc(UBL.ublTempdx,...
              sensHeat,simParam.dt,...
              parameter,forDens,UBL.paralLength,UBL.charLength,...
              refSite,UBL.ublEmis,UBL.atmTemp,UBL.surfTemp);
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

