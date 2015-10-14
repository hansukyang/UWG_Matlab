function [dld,dls,dlk] = LengthBougeault(nz,dld,dlu,z)

dlg = zeros(nz,1);
dls = zeros(nz,1);
dlk = zeros(nz,1);
for iz=1:nz         
    dlg(iz)=(z(iz)+z(iz+1))/2.;
end

for iz=1:nz
    dld(iz)=min(dld(iz),dlg(iz));
    dls(iz)=sqrt(dlu(iz)*dld(iz));
    dlk(iz)=min(dlu(iz),dld(iz));         
end                  

end