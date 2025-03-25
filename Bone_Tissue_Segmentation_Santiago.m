% Santiago Salas

clc;
clear;
close all;

% Folder containing DICOM files
dicomFolder = 'FILEPATH';

% Read all DICOM files from the folder
dicomFiles = dir(fullfile(dicomFolder, '*.dcm'));

% Initialize an empty 3D volume to store DICOM slices
dicomVolume = [];
for i = 1:length(dicomFiles)
    dicomFile = fullfile(dicomFolder, dicomFiles(i).name);
    dicomImage = dicomread(dicomFile);
    dicomVolume(:, :, i) = dicomImage; % Stack slices into a 3D volume
end

% Display the size of the DICOM volume
disp(['DICOM volume size: ', num2str(size(dicomVolume))]);

% Normalize the DICOM volume to the range [0, 1] for processing
dicomVolume = double(dicomVolume);
dicomVolume = (dicomVolume - min(dicomVolume(:))) / (max(dicomVolume(:)) - min(dicomVolume(:)));

% Plot a histogram of the DICOM volume to determine the threshold for bone segmentation
figure;
histogram(dicomVolume(:), 'BinMethod', 'auto');
title('Histogram of DICOM Volume');
xlim([0,0.6])
xlabel('Intensity Value');
ylabel('Frequency');

% Threshold value for bone segmentation
threshold = 0.46;

% Segment bone tissue using the threshold
boneMask = dicomVolume > threshold;

boneMask = imfill(boneMask, 'holes'); % rellena huecos de la imagen binaria. Un hueco es un conjunto de píxeles de fondo que no se puede alcanzar rellenando el fondo desde el borde de la imagen.

% Apply the mask to the original DICOM volume to isolate bone tissue
segmentedVolume = dicomVolume .* boneMask;  

% Display each slice before and after segmentation
figure;
for i = 1:size(dicomVolume, 3)
    % Original slice
    subplot(1, 2, 1);
    imshow(dicomVolume(:, :, i), []);
    title(['Original Slice ', num2str(i)]);

    % Segmented slice
    subplot(1, 2, 2);
    imshow(segmentedVolume(:, :, i), []);
    title(['Segmented Slice ', num2str(i)]);

    pause(0.01); % Pause to visualize each slice
end

% Configure colormap and transparency for 3D visualization
alpha = [0 0 0.72 1.0];
color = [0 0 0; 186 65 77; 231 208 141; 255 255 255] ./ 255;
intensity = [-900 100 400 1499];

queryPoints = linspace(min(intensity), max(intensity), 256);
alphamap = interp1(intensity, alpha, queryPoints)';
colormap = interp1(intensity, color, queryPoints);

% Define a transformation matrix to scale the image to the correct voxel dimensions
sx = 1;
sy = 1;
sz = 2.5;
A = [sx 0 0 0; 0 sy 0 0; 0 0 sz 0; 0 0 0 1];

% Create an affinetform3d object to perform the scaling
tform = affinetform3d(A);

% Perform 3D reconstruction of the segmented bone tissue
vol = volshow(dicomVolume, Colormap=colormap, Alphamap=alphamap, Transformation=tform);
