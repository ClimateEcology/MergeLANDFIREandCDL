
# this script is the non-function version of merge function
library(raster); library(terra); library(dplyr)

##### input parameters
datadir <- './data' # directory where tabular and spatial data are stored
buffercells <- c(3,3)  # number of cells that overlap between raster tiles (in x and y directions)
nvc_agclasses <- c(7960:7999) # classes in LANDFIRE NVC that are agriculture
verbose <- T
veglayer <- 'nvc'
##### Step 0: Setup and load data


# load table of LANDFIRE vegetation classes
if (veglayer == 'evt') {
  vegclasses_key <- read.csv(paste0(datadir, '/TabularData/US_105evt_05262011.csv')) %>%
    dplyr::mutate(VALUE = as.character(Value))
  name_column <- 'EVT_Name'; name_column <- sym(name_column)
} else if (veglayer == 'nvc') {
  vegclasses_key <- read.csv(paste0(datadir, '/TabularData/LF_200NVC_05142020.csv')) %>%
    dplyr::mutate(VALUE = as.character(VALUE))
  
  name_column <- 'NVC_Name'; name_column <- sym(name_column)
}

# read CDL class names
# cdl_classes <- read.csv(paste0(datadir, '/TabularData/NASS_classes_simple.csv')) %>% 
#   dplyr::filter(VALUE < 500)  %>% #filter out CDL classes that I created for a different project
#   dplyr::mutate(VALUE = as.character(-VALUE))

cdl_classes <- read.csv(paste0(datadir, '/TabularData/NASS_classes_pasture_is_arable.csv')) %>% 
  dplyr::mutate(VALUE = as.character(-VALUE))


# create derived parameter of window_size
window_size <- (buffercells[1]*2) + 1 # diameter of neighborhood analysis window (part 2 only)

##### Step 1: Assign pixels that exactly match

# create vectors listing which CDL classes match LANDFIRE groups 
# groups are: wheat, orchard, berries, vineyard, row crop, close-grown crop, aquaculture, pasture and hayland, and fallow/idle
if (veglayer == 'nvc') {nvc_ag <- dplyr::filter(vegclasses_key, VALUE %in% nvc_agclasses) }

agclass_match <- read.csv(paste0(datadir, '/TabularData/CDL_NVC_AgClassMatch.csv')) %>%
  dplyr::select(VALUE, CLASS_NAME, GROUP, NVC_Match1, NVC_Match2, NVC_Match3, NVC_Match4)

# names of LANDFIRE classes (simplified) that will be re-assigned
habitat_groups <- c('wheat', 'orchard', 'berries', 'vineyard', 'row_crop', 'close_grown_crop',
                    'aquaculture', 'pasture', 'fallow')
search_strings <- c('Wheat', 'Orchard', "Bush fruit and berries", 'Vineyard', 'Row Crop', 'Close Grown Crop',
                    'Aquaculture', 'Pasture', 'Fallow')

# create R objects for each LANDFIRE class listing matching CDL classes
for (i in 1:length(habitat_groups)) {
  assign(x=habitat_groups[i], value = dplyr::filter(agclass_match, grepl(NVC_Match1, pattern = search_strings[i])| 
                                                      grepl(NVC_Match2, pattern= search_strings[i])|
                                                      grepl(NVC_Match3, pattern= search_strings[i])|
                                                      grepl(NVC_Match4, pattern= search_strings[i])) %>% 
           dplyr::pull(CLASS_NAME) )
}

# Load spatial layers (NVC and CDL rasters)
# path is '../../SpatialData/FingerLakesLandUse on laptop
nvc <- terra::rast(paste0(datadir, '/SpatialData/FingerLakesLandCover/LandFire_NatVegClassification.tif')) 
cdl <- terra::rast(paste0(datadir, '/SpatialData/FingerLakesLandCover/USDA_CDL_2016_FingerLakes.tif'))

#reclassify NA values in CDL to 0 (otherwise landfire values at these locations are not preserved)
# mat <- data.frame(is=NA, becomes=0) 
# cdl <- terra::classify(cdl, rcl=mat) 

##### clip CDL and NVC to smaller area
map <- cdl

# Crop CDL and NVC to small example raster
xpct=c(0.38, 0.39) # new example extent to have mismatch pixel conflict (value of -1001 in final raster)
ypct=c(0.32, 0.33)


# xpct=c(0.675, 0.69) # new example extent to have mismatch pixel conflict (value of -1001 in final raster)
# ypct=c(0.845, 0.86)

bbox <- ext(c( (xmax(map)-xmin(map))*xpct[1] + xmin(map),  (xmax(map)-xmin(map))*xpct[2] + xmin(map),
               (ymax(map)-ymin(map))*ypct[1] + ymin(map),  (ymax(map)-ymin(map))*ypct[2] + ymin(map))
)

cdl <- terra::crop(cdl, y=bbox)
nvc <- terra::crop(nvc, y=bbox)


# reclassify a few CDL fallow cells to shrubland to create unresolvable conflict (for illustration purposes)
#cdl[cdl == 61] <- 152

# check if projections of raster tiles are the same. If not, re-project them to match.
if (terra::crs(cdl) != terra::crs(nvc)) {
  cdl <- terra::project(x=cdl, y=nvc)
}


habitat_groups <- c('wheat', 'orchard', 'berries', 'vineyard', 'row_crop', 'close_grown_crop',
                    'aquaculture', 'pasture', 'fallow')

# For each habitat group, replace LANDFIRE class with CDL pixel class (but only if CDL class matches)
for (habitat_name in habitat_groups) {
  
  # e.g replace NVC orchard class with CDL fruit tree types (when NVC orchard pixels overlap with CDL fruit tree)
  nvc_tochange <- dplyr::filter(nvc_ag, grepl(NVC_Name, 
                                              pattern= beecoSp::CapStr(gsub(habitat_name, pattern="_", replacement=" ")))|
                                  grepl(NVC_Name, pattern=habitat_name)) %>% 
    dplyr::pull(VALUE)
  
  cdl_toadd <- dplyr::filter(cdl_classes, CLASS_NAME %in% get(habitat_name)) %>% 
    dplyr::mutate(VALUE = (as.numeric(VALUE)*-1)) %>%
    dplyr::pull(VALUE)
  
  if (habitat_name == habitat_groups[[1]]) {
    veglayer_copy <- nvc
  }
  
  # create binary layer indicating landfire and cdl match
  both_orchard <- (cdl %in% cdl_toadd & veglayer_copy %in% as.numeric(nvc_tochange))
  
  if (verbose == T) {
    logger::log_info(paste0("Projection match =", terra::crs(both_orchard) == terra::crs(veglayer_copy)))
    logger::log_info(paste0("Extent match =", terra::ext(both_orchard) == terra::ext(veglayer_copy)))
  }
  
  remove <- (!both_orchard) * veglayer_copy
  add <- both_orchard * (-cdl)
  veglayer_copy <- remove + add
  if (verbose == T) { logger::log_info(paste0('finished ', habitat_name)) }
}

# reclassify remaining NVC ag cells to NA
reclass <- data.frame(agveg=nvc_agclasses, to=NA)
temp2 <- terra::classify(veglayer_copy, rcl=reclass)

if (verbose == T) {
  logger::log_info('Step 1 complete.')
  logger::log_info('Begin step 2: assign mis-matched pixel via neighborhood analysis.')
}
##### Step 2: Assign mismatched pixels based on neighborhood

# When possible, reassign remaining NVC ag classes by looking at surrounding cells

# Due to quirk of how the terra package is written, we cannot include this object as an argument to 'merge_landfire_cdl'
# terra's 'focal' function only accepts one argument 
allow_classes <- as.numeric(cdl_classes$VALUE[cdl_classes$GROUP == 'A'])

# Is the option to define crop classes working?
nvc_gapsfilled <- beecoSp::reassign_NA(map=temp2,
                     window_size=window_size, replace_any=F)

##### Step 4: Crop merged tile to extent of original tiles (remove overlap)

# create extent object that removes the buffer cells
delta_x <- terra::res(nvc_gapsfilled)[1]*buffercells[1]
delta_y <- terra::res(nvc_gapsfilled)[2]*buffercells[2]

# subtract buffer distance from tile extent
original_extent <- terra::ext(c(
terra::ext(nvc_gapsfilled)$xmin + delta_x,
terra::ext(nvc_gapsfilled)$xmax - delta_x,
terra::ext(nvc_gapsfilled)$ymin + delta_y,
terra::ext(nvc_gapsfilled)$ymax - delta_y
))

# crop tile to original extent (without buffer pixels)
nvc_gapsfilled <- terra::crop(nvc_gapsfilled, original_extent)

# cropped version of output from step 1
output_step1 <- terra::crop(temp2, original_extent)
# cropped version of CDL
cdl_tomap <- terra::crop(cdl, original_extent)

# cropped version of NVC
nvc_tomap <- terra::crop(nvc, original_extent)

sort(unique(values(nvc_gapsfilled)))

length(which(values(nvc_gapsfilled) == -1001))

plot(nvc_gapsfilled)
plot(nvc_gapsfilled == -1001)


terra::writeRaster(cdl_tomap, './data/SpatialData/ExampleSmallRasters/small_cdl.tif', overwrite=T)
terra::writeRaster(nvc_tomap, './data/SpatialData/ExampleSmallRasters/small_nvc.tif', overwrite=T)
terra::writeRaster(output_step1, './data/SpatialData/ExampleSmallRasters/merged_with_gaps.tif', overwrite=T)
terra::writeRaster(nvc_gapsfilled, './data/SpatialData/ExampleSmallRasters/merged_gapsfilled.tif', overwrite=T)

