
% Cargar archivos
carpeta = 'DU01_knee_06mm'; % Nombre de la carpeta que contiene los archivos DICOM
dicoms = dir(fullfile(carpeta, '*.dcm')); % Obtener la lista de archivos DICOM

% Leer las imágenes DICOM y almacenarlas en un arreglo 3D
info = dicominfo(fullfile(carpeta, dicoms(1).name)); % Obtener información del primer archivo
imagenes = zeros(info.Rows, info.Columns, numel(dicoms), 'int16'); % Crear arreglo 3D

for i = 1:numel(dicoms)
    archivo = fullfile(carpeta, dicoms(i).name);
    imagenes(:,:,i) = dicomread(archivo); % Leer cada imagen DICOM
end

% Segmentar el tejido óseo
% Aplicar un umbral para separar el hueso del tejido blando
umbral = 1500; % Aqui se ajusta el valor según sea necesario
mascara = imagenes > umbral; % Crear una máscara binaria

% Aplicar operaciones morfológicas para eliminar ruido y tejido no relevante
mascara = bwareaopen(mascara, 50); % Eliminar objetos pequeños (ruido)
mascara = imclose(mascara, strel('sphere',2 )); % Cerrar pequeños agujeros

% Mejorar el histograma de la imagen
imagenes_mejoradas = imagenes;
for i = 1:size(imagenes, 3)
    imagenes_mejoradas(:,:,i) = histeq(imagenes(:,:,i)); % Ecualización del histograma
end

% Graficar cada porción del archivo DICOM antes y después de aplicar la máscara
figure;
for i = 1:size(imagenes, 3)
    subplot(1, 2, 1);
    imshow(imagenes(:,:,i), []); % Mostrar imagen original
    title(['Original - Slice ', num2str(i)]);

    subplot(1, 2, 2);
    imshow(mascara(:,:,i)); % Mostrar máscara
    title(['Máscara - Slice ', num2str(i)]);

    pause(0.03); % Pausa para visualización
end

% Reconstrucción 3D exclusivamente del tejido óseo
% Crear un volumen 3D solo con el tejido óseo
volumen_hueso = imagenes .* int16(mascara); % Aplicar la máscara al volumen original

% % Asegurarse de que el volumen esté en el formato correcto para volshow
volumen_hueso = double(volumen_hueso); % Convertir a tipo double
volumen_hueso = volumen_hueso ./ max(volumen_hueso(:)); % Normalizar los valores entre 0 y 1

intensity = [-900 100 400 1499];
alpha = [0 0 0.72 1.0];
color = [0 0 0; 186 65 77; 231 208 141; 255 255 255] ./255;

queryPoints = linspace(min(intensity),max(intensity),256);
alphamap = interp1(intensity,alpha,queryPoints)';
colormap = interp1(intensity,color,queryPoints);

sx = 1;
sy= 1;
sz = 2.5;
A = [sx 0 0 0; 0 sy 0 0; 0 0 sz 0; 0 0 0 1];

tform = affinetform3d(A);

% Visualizar la reconstrucción 3D usando "volshow"
figure;
vol = volshow(imagenes,Colormap=colormap,Alphamap=alphamap,Transformation=tform);
