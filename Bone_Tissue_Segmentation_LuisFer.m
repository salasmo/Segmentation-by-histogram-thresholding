%Luis Fernando Molina
clear all; close; clc;

carpeta = 'DU01_knee_06mm'; 
dicoms = dir(fullfile(carpeta, '*.dcm'));
% Estas dos líneas son para guardar todos los DICOMs en una misma variable

rodilla = []; 
% Esta variable tiene un conjunto en blanco para llenarlo con los DICOMs
% en orden para después hacerla en 3D

for i = 1:numel(dicoms)
    donde_estan = fullfile(carpeta, dicoms(i).name); 
    dicom_todos = dicomread(donde_estan); 
    rodilla(:, :, i) = dicom_todos; 
end
% Este ciclo for es para acomodar cada DICOM en la lista de i elementos
% con dimensiones: (o sea 512 x 512 pixeles)

rodilla_double =  im2double(rodilla); 
%DICOMS originales a double

x_min = min(rodilla_double(:));
x_max = max(rodilla_double(:));
rodilla_normal = (rodilla_double - x_min) / (x_max - x_min);
%Profundidad de pixeles de los DICOMS normalizada

rodilla_normal(351:end, :, :) = 0; 
%Quité valores aprox de la cama


% Máscara
rodilla_mascara = (rodilla_normal > 0.435);
rodilla_rank = zeros(size(rodilla_mascara));
for j = 1:size(rodilla_mascara, 3)
    rodilla_rank(:, :, j) = ordfilt2(rodilla_mascara(:, :, j), 5, ones(3, 3));
end

% Segmentación: Máscara
rodilla_seg = rodilla_normal.*rodilla_rank;

%
figure;
for i = 1:size(rodilla_double, 3)
    subplot(1, 3, 1);
    imshow(rodilla_double(:, :, i), []);
    title('Cortes Originales ');
    subplot(1, 3, 2);
    imshow(rodilla_mascara(:, :, i), []);
    title('Máscara');
    subplot(1, 3, 3);
    imshow(rodilla_seg(:, :, i), []);
    title('Cortes Segmentados');
    pause(0.01)
end
% Este ciclofor es para ir proyectando cada DICOM con su corte segmentado 
% y poder irlo comparando uno por uno

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
vol = volshow(rodilla_seg,Colormap=colormap,Alphamap=alphamap,Transformation=tform);
