function t = TransientConduction(t,del,hc,tc,d,flx1,bc,temp2,flx2)
    % t     : layer temperature vector
    % del   : dt (not sure why specified this way?)
    % hc    : layer vol. heat capacity vector
    % tc    : layer thermal conductivity venctor
    % d     : layer depth (thickness) vector)
    % flx1  : net heat flux on surface
    % bc    : boundary condition parameter (1 or 2)
    % temp2 : deep soil temperature (ave of air temperature)
    % flx2  : surface flux (sum of absorbed, emitted, etc.)
    
    

    % implicit coefficient
    fimp=0.5;
    % explicit coefficient
    fexp=0.5;
    % number of layers
    num = size(t,1);
    % mean thermal conductivity over distance between 2 layers
    tcp = zeros(num,1);
    % thermal capacity times layer depth
    hcp = zeros(num,1);
    % lower, main, and upper diagonals
    za = zeros(num,3);
    % RHS
    zy = zeros(num,1);
    %--------------------------------------------------------------------------
    hcp(1) = hc(1)* d(1);
    for j=2:num;
      tcp(j) = 2./(d(j-1)/tc(j-1)+d(j)/tc(j));
      hcp(j) = hc(j)*d(j);
    end
    %--------------------------------------------------------------------------
    za(1,1) = 0.;
    za(1,2) = hcp(1)/del + fimp*tcp(2);
    za(1,3) = -fimp*tcp(2);
    zy(1) = hcp(1)/del*t(1) - fexp*tcp(2)*(t(1)-t(2)) + flx1;
    %--------------------------------------------------------------------------
    for j=2:num-1;
      za(j,1) = fimp*(-tcp(j));
      za(j,2) = hcp(j)/del+ fimp*(tcp(j)+tcp(j+1));
      za(j,3) = fimp*(-tcp(j+1));
      zy(j) = hcp(j)/del*t(j)+fexp*(tcp(j)*t(j-1)-...
          tcp(j)*t(j)-tcp(j+1)*t(j)+ tcp(j+1)*t(j+1));
    end
    %--------------------------------------------------------------------------
    if eq(bc,1) % het flux
        za(num,1) = fimp*(- tcp(num) );
        za(num,2) = hcp(num)/del+ fimp* tcp(num);
        za(num,3) = 0.;
        zy(num) = hcp(num)/del*t(num) + fexp*tcp(num)*(t(num-1)-t(num)) + flx2;
    elseif eq(bc,2) % deep-temperature
        za(num,1) = 0;
        za(num,2) = 1;
        za(num,3) = 0.;
        zy(num) = temp2;
    else 
        disp('ERROR: check input parameters for TransientConduction routine')
    end   
    %--------------------------------------------------------------------------
    % zx=tridiag_ground(za,zb,zc,zy);
    zx = Invert(num,za,zy);
    t(:) = zx(:);

end