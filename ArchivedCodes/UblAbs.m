function abs = UblAbs(tg,tsurf,rh,ptot,xl)

    % Calculates the total absorptivity of a steam-nitrogen
    % mixture using the correlation of Leckner
    xlad = xl*tsurf/tg;
    emis = UblEmis(tg,rh,ptot,xlad);
    tfac = sqrt(tg/tsurf);
    abs = emis*tfac;

end
