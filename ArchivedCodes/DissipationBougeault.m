function [dlu,dld] = DissipationBougeault(g,nz,z,dz,te,pt)

dlu = zeros(nz,1);
dld = zeros(nz,1);
for iz=1:nz
    zup=0.;
    dlu(iz)=z(nz+1)-z(iz)-dz(iz)/2.;
    zzz=0.;
    zup_inf=0.;
    beta=g/pt(iz);
    for izz=iz:nz-1
       dzt=(dz(izz+1)+dz(izz))/2.;
       zup=zup-beta*pt(iz)*dzt;
       zup=zup+beta*(pt(izz+1)+pt(izz))*dzt/2.;
       zzz=zzz+dzt;
       if (lt(te(iz),zup) && ge(te(iz),zup_inf))
         bbb=(pt(izz+1)-pt(izz))/dzt;
         if ne(bbb,0)
            tl=(-beta*(pt(izz)-pt(iz))+...
            sqrt( max(0.,(beta*(pt(izz)-pt(iz)))^2.+...
            2.*bbb*beta*(te(iz)-zup_inf))))/bbb/beta;
         else
         tl=(te(iz)-zup_inf)/(beta*(pt(izz)-pt(iz)));
         end            
         dlu(iz)=max(1.,zzz-dzt+tl);
       end
       zup_inf=zup;
    end
    zdo=0.;
    zdo_sup=0.;
    dld(iz)=z(iz)+dz(iz)/2.;
    zzz=0.;
    for izz=iz:-1:2
        dzt=(dz(izz-1)+dz(izz))/2.;
        zdo=zdo+beta*pt(iz)*dzt;
        zdo=zdo-beta*(pt(izz-1)+pt(izz))*dzt/2.;
        zzz=zzz+dzt;
        if (lt(te(iz),zdo) && ge(te(iz),zdo_sup))
           bbb=(pt(izz)-pt(izz-1))/dzt;
           if ne(bbb,0.)
             tl=(beta*(pt(izz)-pt(iz))+...
             sqrt( max(0.,(beta*(pt(izz)-pt(iz)))^2.+...
             2.*bbb*beta*(te(iz)-zdo_sup))))/bbb/beta;
           else
             tl=(te(iz)-zdo_sup)/(beta*(pt(izz)-pt(iz)));
           end
           dld(iz)=max(1.,zzz-dzt+tl);
        end
        zdo_sup=zdo;
    end
end  
end
