#prettier combined vegetation map of Finger Lakes. Couldn't get this to work in markdown

rm(list=ls())

veglayer <- 'evt'
load(paste0('./data/CombinedVegCDLRasters/combined', veglayer, 'raster.RDA'))
rasterVis::levelplot(combined, att='Class_Name')

