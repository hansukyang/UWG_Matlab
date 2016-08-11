function dens = Density(temp,hum,pres)
    dens = pres/(1000*0.287042*temp*(1.+1.607858*hum));
end

