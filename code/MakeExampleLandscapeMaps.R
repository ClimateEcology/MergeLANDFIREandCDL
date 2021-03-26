#rm(list=ls())

source('./code/SpeciesByVegType/functions/reassign_NA.R')

crops = as.numeric(cdl_classes$VALUE[cdl_classes$GROUP == 'A'])
corn <- -1
map=temp2
xpct=c(0.60, 0.61)
ypct=c(0.48, 0.49)
window_size <- 7

bbox <- ext(c( (xmax(map)-xmin(map))*xpct[1] + xmin(map),  (xmax(map)-xmin(map))*xpct[2] + xmin(map),
               (ymax(map)-ymin(map))*ypct[1] + ymin(map),  (ymax(map)-ymin(map))*ypct[2] + ymin(map))
)

smaller_cdl <- terra::crop(cdl, y=bbox)
plot(smaller_cdl)

terra::writeRaster(smaller_cdl, './figs/ExampleLandscape_MergeLayers/small_cdl.tif')
terra::writeRaster(smaller_nvc, './figs/ExampleLandscape_MergeLayers/small_nvc.tif')
terra::writeRaster(smaller_test, './figs/ExampleLandscape_MergeLayers/small_combined_outputstep1.tif')


smaller_nvc <- terra::crop(nvc, y=bbox)
plot(smaller_nvc, range=c(7970, 7978))

View(table(values(smaller_nvc)))

sort(unique(values(smaller_test)))

range(smaller_test)
smaller_test <- terra::crop(map, y=bbox)
plot(smaller_test)

plot(is.na(smaller_test), main = 'CDL match NVC')


nocrop_map <- reassign_NA(map=temp2, xpct=xpct, ypct=ypct, 
                   window_size=window_size, crops=NA)

#assign allow_classes class so custom_modal DOES use it
allow_classes <- crops

crop_map <- reassign_NA(map=temp2, xpct=xpct, ypct=ypct, 
                             window_size=7, crops=crops)

plot(crop_map)
plot(nocrop_map)


terra::writeRaster(nocrop_map, './figs/ExampleLandscape_MergeLayers/small_outputstep2_nocrop.tif')
terra::writeRaster(crop_map, './figs/ExampleLandscape_MergeLayers/small_outputstep2_crop.tif')


