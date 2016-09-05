function qsat = qsat(temp,pres,parameter) 

gamw = (parameter.cl - parameter.cpv) / parameter.rv;
betaw = (parameter.lvtt/parameter.rv) + (gamw * parameter.tt);
alpw = log(parameter.estt) + (betaw /parameter.tt) + (gamw *log(parameter.tt));
work2 = parameter.r/parameter.rv;
foes = zeros(size(temp));
work1= zeros(size(temp));
qsat = zeros(size(temp));
for i=1:size(temp)
  % saturation vapor pressure
  foes(i) = exp( alpw - betaw/temp(i) - gamw*log(temp(i))  );
  work1(i)    = foes(i)/pres(i);
  % saturation humidity
  qsat(i) = work2*work1(i) / (1.+(work2-1.)*work1(i));
end

end

