function emis = UblEmis(tg,rh,ptot,xl)

    % Calculates the total emissivity of a steam-nitrogen
    % mixture using the correlation of Leckner
    % Saturation vapour pressure from ASHRAE
    C8=-5.8002206E3; C9=1.3914993; C10=-4.8640239E-2; C11=4.1764768E-5;
    C12=-1.4452093E-8; C13=6.5459673;
    ph2oSat = exp(C8/tg+C9+C10*tg+C11*tg^2+C12*tg^3+C13*log(tg));
    % Vapour partial pressure (Pa)
    ph2o=rh*ph2oSat/100;
    % CO2 partial pressure (bar)
    pco2=ptot*3.45e-4/1e5;  
    % convert partial pressure of vapour from Pa to bar
    ph2o = ph2o/1e5; 
    % convert total pressure from Pa to bar
    ptot = ptot/1e5; 
    % convert geometric path length from m to cm
    xl = xl*100; 

    cmnh2o =[-2.2118d0,-1.1987d0,0.035596d0,0.85667d0,0.93048d0,...
        -0.14391d0,-0.10838d0,-0.17156d0,0.045915d0];
    cmnh2o=reshape(cmnh2o,[3,3]);

    cmnco2 =[-3.9893d0,2.7669d0,-2.1081d0,0.39163d0,1.2710d0,-1.1090d0,...
        1.0195d0,-0.21897d0,-0.23678d0,0.19731d0,-0.19544d0,0.044644d0];  
    cmnco2=reshape(cmnco2,[4,3]);

    t=tg/1e3;

    %--H2O

    if(t<=.75)
        a=2.144;
    else
        a=1.888-2.053*log10(t);
    end
    b=1.10/t^1.4;
    c=0.5;
    palm=1.32e1*t^2;
    pe=ptot+2.56*ph2o/sqrt(t);
    pal=ph2o*xl;
    epsh2o=0.0;
    if(pal>=1.0e-3)
        pall=log10(pal);
        eps0=0.0;
        for  i=0:2
            for  j=0:2
                eps0=eps0+cmnh2o(j+1,i+1)*t^j*pall^i;
            end
        end
    eps0=exp(eps0);
    epsr=1.0-(a-1.0)*(1.0-pe)/(a+b-1.0+pe)*exp(-c*(log10(palm)-pall)^2);
    epsh2o=eps0*epsr;
    end

    %--CO2

    a=1.0d0+0.1/t^1.45;
    b=0.23;
    c=1.47;
    if(t<=.7d0)
        palm=0.054/(t*t);
    else
        palm=0.225*t*t;
    end
    pe=ptot+0.28*pco2;
    pal=pco2*xl;
    epsco2=0.0;
    if(pal>=1.0e-3)
        pal=log10(pal);
        eps0=0.0;
        for  i=0:2
            for  j=0:3
                eps0=eps0+cmnco2(j+1,i+1)*t^j*pal^i;
            end
        end
    eps0=exp(eps0);
    epsr=1.0-(a-1.0)*(1.0-pe)/(a+b-1.0+pe)*exp(-c*(log10(palm)-pal)^2);
    epsco2=eps0*epsr;
    end

    %--OVERLAP
    zeta=ph2o/(ph2o+pco2);
    pal=(ph2o+pco2)*xl;
    if(pal<=1.0)
        deps=0.0;
    else
        deps=(zeta/(1.07e1+1.01e2*zeta)-zeta^10.4/1.117e2)*(log10(pal))^2.76;
    end
    emis=epsh2o+epsco2-deps;

end
