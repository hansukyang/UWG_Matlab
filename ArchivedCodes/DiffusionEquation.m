function co = DiffusionEquation(nz,dt,co,da,daz,cd,dz)
    % Reference?

    cddz = zeros(nz+2,1);
    a = zeros(nz,3);
    c = zeros(nz,1);
    %--------------------------------------------------------------------------
    cddz(1)= daz(1)*cd(1)/dz(1);
    for iz=2:nz
       cddz(iz) = 2.*daz(iz)*cd(iz)/(dz(iz)+dz(iz-1));
    end
    cddz(nz+1) = daz(nz+1)*cd(nz+1)/dz(nz);
    %--------------------------------------------------------------------------
    a(1,1)=0.;
    a(1,2)=1.;
    a(1,3)=0.;
    c(1)=co(1);       
    for iz=2:nz-1
       dzv=dz(iz);
       a(iz,1)=-cddz(iz)*dt/dzv/da(iz);
       a(iz,2)=1+dt*(cddz(iz)+cddz(iz+1))/dzv/da(iz);
       a(iz,3)=-cddz(iz+1)*dt/dzv/da(iz);
       c(iz)  =co(iz);             
    end    
    a(nz,1)=-1.;
    a(nz,2)=1.;
    a(nz,3)=0.;
    c(nz)  =0;
    %--------------------------------------------------------------------------
    co = Invert (nz,a,c);
                                                   
end

