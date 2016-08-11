% Process data - this outputs Excel file and generates a number of default 
% plots.

close all;
load UWGdump.mat;

% Notes - plot for 1 week only?
% Plot A1: Weather data (time vs. EPW rural temp, Canyon temp)

% Convert time from seconds into days
time = time / (3600*24);

%-----------------------------------------------
% PLOT 1: Temperature & Radiation 
%-----------------------------------------------
figure;
subplot(2,1,1);
plot (time,[WeatherData.temp]-273.15,time,Can_Tdb,time,[ublVarData.ublTemp]-273.15);
legend ('Rural','Canyon','UBL');
grid;
title ('Weather Plot - Temperature and Radiation');
ylabel ('Deg C');
xlabel ('Day');

subplot(2,1,2);
plot (time,[WeatherData.infra],time,[WeatherData.dir],time,[WeatherData.dif],time,[WeatherData.dir]+[WeatherData.dif]);
legend ('LW','Dir','Diff','Dir+Diff');
grid;
ylabel ('W/m^2');
xlabel ('Day');

%-----------------------------------------------
% PLOT 1b: UHI Effect
%-----------------------------------------------
figure;
subplot(2,1,1);
plot (time,[WeatherData.temp]-273.15,time,Can_Tdb);
legend ('Rural','Canyon');
grid;
title ('Weather Plot - Temperature and UHI');
ylabel ('Deg C');
xlabel ('Day');

subplot(2,1,2);
plot (time,Can_Tdb - ([WeatherData.temp]-273.15));
legend ('Urban - Rural Temperature');
grid;
ylabel ('Deg C');
xlabel ('Day');


%-----------------------------------------------
% PLOT 2: Humidity
%-----------------------------------------------
figure;
subplot(2,1,1);
plot (time,[WeatherData.rHum],time,Can_phi);
legend ('Rural','Canyon');
grid;
title ('Weather Plot - Humidity');
ylabel ('Relative (%)');
xlabel ('Day');

subplot(2,1,2);
plot (time,[WeatherData.hum],time,Can_hum);
legend ('Rural','Canyon');
grid;
ylabel ('Specific (kg/kg)');
xlabel ('Day');

%-----------------------------------------------
% PLOT 3: Temperature & Humidity
%-----------------------------------------------

figure;
subplot(2,1,1);
plot (time,[WeatherData.temp]-273.15,time,Can_Tdb);
legend ('Rural','Canyon');
grid;
title ('Weather Plot - Temperature and Precipitation');
ylabel ('Deg C');
xlabel ('Day');

subplot(2,1,2);
plot (time,[WeatherData.prec]);
grid;
ylabel ('Precipitation');
xlabel ('Day');

%-----------------------------------------------
% PLOT 4: Heat Forcing & Road temperature
%-----------------------------------------------

figure;
subplot(2,1,1);
hold on;
for i = 1:numel(CityBlock)
    plot (time,CityBlock(1,i).RoadA);
end
grid;
title ('Weather Plot - Temperature and Road Surface Temp');
ylabel ('W/m^2');
xlabel ('Day');

subplot(2,1,2);
hold on;
for i = 1:numel(CityBlock)
    plot(time,CityBlock(1,i).RoadT-273.15)
end
grid
ylabel ('Deg C');
xlabel ('Day');

%-----------------------------------------------
% PLOT 5: Heat Forcing & Roof temperature
%-----------------------------------------------

figure;
subplot(2,1,1);
hold on;
for i = 1:numel(CityBlock)
    plot (time,CityBlock(1,i).RoofA,'r',time,CityBlock(1,i).RoofQ,'b');
end
grid;
title ('Weather Plot - Temperature and Roof Temp');
ylabel ('W/m^2');
xlabel ('Day');

subplot(2,1,2);
hold on;
for i = 1:numel(CityBlock)
    plot(time,CityBlock(1,i).RoofT-273.15)
end
grid
ylabel ('Deg C');
xlabel ('Day');

%-----------------------------------------------
% PLOT 6: Heat Forcing & Wall temperature
%-----------------------------------------------

figure;
subplot(2,1,1);
hold on;
for i = 1:numel(CityBlock)
    plot (time,CityBlock(1,i).WallA,time,CityBlock(1,i).WallQ);
end
grid;
title ('Weather Plot - Temperature and Wall Temp');
ylabel ('W/m^2');
xlabel ('Day');

subplot(2,1,2);
hold on;
for i = 1:numel(CityBlock)
    plot(time,CityBlock(1,i).WallT-273.15)
end
grid
ylabel ('Deg C');
xlabel ('Day');

%-----------------------------------------------
% PLOT 7: Temperature & Mass temperature
%-----------------------------------------------

figure;
subplot(2,1,1);
plot (time,[WeatherData.temp]-273.15,time,Can_Tdb);
legend ('Rural','Canyon');
grid;
title ('Weather Plot - Temperature and Mass Temp');
ylabel ('Deg C');
xlabel ('Day');

subplot(2,1,2);
hold on;
for i = 1:numel(CityBlock)
    plot(time,CityBlock(1,i).MassT-273.15)
end
grid;
ylabel ('Deg C');
xlabel ('Day');

%-----------------------------------------------
% PLOT 8: Antropogenic Heat
%-----------------------------------------------

figure;
subplot(2,1,1);
hold on;
for i = 1:numel(CityBlock)
    plot(time,CityBlock(1,i).sensAnthropTot)
end
legend('sensAnthropTot');
grid;
ylabel ('W/m^2');
xlabel ('Day');

subplot(2,1,2);
hold on;
for i = 1:numel(CityBlock)
    plot(time,CityBlock(1,i).coolConsump,'r',time,CityBlock(1,i).sensCoolDemand,'b',time,CityBlock(1,i).heatConsump)
end
legend('coolConsump');
grid;
ylabel ('W/m^2');
xlabel ('Day');





