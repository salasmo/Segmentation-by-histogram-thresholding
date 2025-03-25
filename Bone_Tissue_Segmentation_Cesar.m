clear all
close all
clc

addpath("C:\Users\chati\Downloads\MATLAB\DU01_knee_06mm\");
names=dir('C:\Users\chati\Downloads\MATLAB\DU01_knee_06mm\*.dcm');

for i=1:size(names,1) %Leo y guardo cada archivo DICOM en la variable R
    R(:,:,i)=dicomread(names(i).name);
end 

kneeC=im2double(R);%Guardo los valores de la matriz R en la varible knee2 y los vuelvo de doble precisión para poder trabajar con decimales si es necesario
x_min=min(kneeC(:));
x_max=max(kneeC(:));
kneeCl=(kneeC-x_min)/(x_max-x_min);%Con los limites detectados de los valores de la matriz de cada dicom los divido entre si para normalizarlos entre valores de 0 y 1

mask42=(kneeCl> 0.450);%Creo una mascara binaria para segmentar los valores de cada pixel entre valores mayores a 0.450 y menores que el mismo

for j = 1:size(mask42, 3)
    knee3(:, :, j) = ordfilt2(mask42(:, :, j), 3, ones(3, 3));
end

Kneef=mask42.*knee3;%Aplico la mascara creada 

figure();%Visualizamos la mascara creada, las imagen originales y las imagenes finales
for i = 1:size(kneeC, 3)
    subplot(1, 3, 1), imshow(kneeC(:, :, i), []);
    subplot(1, 3, 2), imshow(mask42(:, :, i), []);
    subplot(1, 3, 3), imshow(Kneef(:, :, i), []);
    pause(0.05);
end

intensity = [0 20 40 120 220 1024];
alpha = [0 0 0.15 0.3 0.38 0.5];
color = [0 0 0; 43 0 0; 103 37 20; 199 155 97; 216 213 201; 255 255 255]/255;
queryPoints = linspace(min(intensity),max(intensity),256);
alphamap = interp1(intensity,alpha,queryPoints)';
colormap = interp1(intensity,color,queryPoints);

sx = 1;
sy= 1;
sz = 2.5;

A = [sx 0 0 0; 0 sy 0 0; 0 0 sz 0; 0 0 0 1];
tform = affinetform3d(A);
vol = volshow(Kneef,Colormap=colormap,Alphamap=alphamap,Transformation=tform);
