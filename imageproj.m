colorImage = imread('images.jpg');
figure; imshow(colorImage); title('Original image')
grayImage = rgb2gray(colorImage);
mserRegions = detectMSERFeatures(grayImage,'RegionAreaRange',[150 2000]);
mserRegionsPixels = vertcat(cell2mat(mserRegions.PixelList)); 
figure; imshow(colorImage); hold on;
plot(mserRegions, 'showPixelList', true,'showEllipses',false);
title('MSER regions');
mserMask = false(size(grayImage));
ind = sub2ind(size(mserMask), mserRegionsPixels(:,2), mserRegionsPixels(:,1));
mserMask(ind) = true;
edgeMask = edge(grayImage, 'Canny');
edgeAndMSERIntersection = edgeMask & mserMask; 
figure; imshowpair(edgeMask, edgeAndMSERIntersection, 'montage'); 
title('Canny edges and intersection of canny edges with MSER regions')
[~, gDir] = imgradient(grayImage);
gradientGrownEdgesMask = helperGrowEdges(edgeAndMSERIntersection, gDir, 'LightTextOnDark');
figure; imshow(gradientGrownEdgesMask); title('Edges grown along gradient direction')
edgeEnhancedMSERMask = ~gradientGrownEdgesMask & mserMask; 
figure; imshowpair(mserMask, edgeEnhancedMSERMask, 'montage'); 
title('Original MSER regions and segmented MSER regions')
connComp = bwconncomp(edgeEnhancedMSERMask); 
stats = regionprops(connComp,'Area','Eccentricity','Solidity');
regionFilteredTextMask = edgeEnhancedMSERMask;
regionFilteredTextMask(vertcat(connComp.PixelIdxList{[stats.Eccentricity] > .995})) = 0;
regionFilteredTextMask(vertcat(connComp.PixelIdxList{[stats.Area] < 150 | [stats.Area] > 2000})) = 0;
regionFilteredTextMask(vertcat(connComp.PixelIdxList{[stats.Solidity] < .4})) = 0;
figure; imshowpair(edgeEnhancedMSERMask, regionFilteredTextMask, 'montage'); 
title('Text candidates before and after region filtering')
distanceImage    = bwdist(~regionFilteredTextMask);
strokeWidthImage = helperStrokeWidth(distanceImage);
figure; imshow(strokeWidthImage); 
caxis([0 max(max(strokeWidthImage))]); axis image, colormap('jet'), colorbar;
title('Visualization of text candidates stroke width')
connComp = bwconncomp(regionFilteredTextMask);
afterStrokeWidthTextMask = regionFilteredTextMask;
for i = 1:connComp.NumObjects
    strokewidths = strokeWidthImage(connComp.PixelIdxList{i});
    if std(strokewidths)/mean(strokewidths) > 0.35
        afterStrokeWidthTextMask(connComp.PixelIdxList{i}) = 0;
    end
end
figure; imshowpair(regionFilteredTextMask, afterStrokeWidthTextMask,'montage'); 
title('Text candidates before and after stroke width filtering')
se1=strel('disk',25);
se2=strel('disk',7);

afterMorphologyMask = imclose(afterStrokeWidthTextMask,se1);
afterMorphologyMask = imopen(afterMorphologyMask,se2);
displayImage = colorImage; 
displayImage(~repmat(afterMorphologyMask,1,1,3)) = 0;
figure; imshow(displayImage); title('Image region under mask created by joining individual characters')
areaThreshold = 5000; 
connComp = bwconncomp(afterMorphologyMask);
stats = regionprops(connComp,'BoundingBox','Area');
boxes = round(vertcat(stats(vertcat(stats.Area) > areaThreshold).BoundingBox));
for i=1:size(boxes,1)
    figure;
    imshow(imcrop(colorImage, boxes(i,:)));
    title('Text region')
end
boxes=im2bw(boxes);
ocrtxt = ocr(afterStrokeWidthTextMask, boxes); 
ocrtxt.Text 
displayEndOfDemoMessage(mfilename)