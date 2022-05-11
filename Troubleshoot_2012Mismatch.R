
library(dplyr); library(terra)

cdl12 <- terra::rast('../../SpatialData/NASS_CDL/CDL2012/2012_30m_cdls/2012_30m_cdls.img')
#cdl14 <- terra::rast('../../SpatialData/NASS_CDL/CDL2014/2014_30m_cdls/2014_30m_cdls.img')
cdl16 <- terra::rast('../../SpatialData/NASS_CDL/CDL2016/2016_30m_cdls.img')

lf <- terra::rast('../../SpatialData/LandFire/US_200NVC/Tif/us_200nvc.tif')
nvc_agclasses <- c(7960:7999)


county <- sf::st_read('./data/SpatialData/us_counties_better_coasts_LFregion.shp') %>%
  sf::st_transform(crs(cdl12))

onecounty <- dplyr::filter(county, FIPS == '04005')

az_cdl12 <- cdl12 %>% terra::crop(onecounty)
az_cdl16 <- cdl16 %>% terra::crop(onecounty)



az_lf <- lf %>% terra::crop(onecounty)

plot(az_cdl12); plot(az_cdl16)
plot(az_lf)


lf_is_ag <- az_lf %in% nvc_agclasses
plot(lf_is_ag)

cdl12_at_lfag <- az_cdl12 * lf_is_ag
cdl16_at_lfag <- az_cdl16 * lf_is_ag


cdl12_match <- terra::freq(cdl12_at_lfag)
cdl16_match <- terra::freq(cdl16_at_lfag)


# load 2012 AZ pixel mismatch data
library(dplyr); library(future)
source('./code/functions/addcounty.R')

CDLYear <- 2014
valdir <- paste0('./data/TechnicalValidation/ValidationData_AZ', CDLYear, '/')

# load NVC raster (just to grab projection information)
nvc <- raster::raster('./data/SpatialData/LANDFIRE/US_200NVC/Tif/us_200nvc.tif')
target_crs <- raster::crs(nvc)


counties <- sf::st_read('./data/SpatialData/us_counties_better_coasts.shp') %>%
  dplyr::select(STATE, COUNTY, FIPS) %>%
  dplyr::filter(!is.na(COUNTY)) # take out polygons that form coasts but are not actually land area (e.g. great lakes)

tiles <- list.files(valdir, full.names = T)

#turn on parallel processing for furrr package
future::plan(multisession)

# loop through list of points in parallel with furrr::future_walk function
assign(x= paste0('pixels',CDLYear), value= 
         furrr::future_map_dfr(.x=tiles, .f=addcounty,
                               prj=target_crs, shape=counties,
                               .options=furrr::furrr_options(seed = T)))
       
bothyears <- rbind(pixels2012, pixels2014)

cleaned12 <- dplyr::mutate(pixels2012, PctTile = 1/ncells_tile) %>% 
 dplyr::filter(!is.na(FIPS)) %>% # remove mis-match points that do not have FIPS code (overlap water or other non-county polygon)
 dplyr::filter(!duplicated(paste0(x, y))) # remove points that might be duplicated 
#duplication could happen due to calculating mis-match from state tiles rather than actual state polygons, borders don't match exactly

freq_bystate12 <- cleaned12 %>%  dplyr::group_by(NVC_Class, CDL_Class, CDLYear, State) %>%
 dplyr::summarise(Mismatch_NCells = n(), Mismatch_PctTile = sum(PctTile, rm.na=T))

freq_bycounty12 <- cleaned12 %>% dplyr::group_by(NVC_Class, CDL_Class, CDLYear, State, FIPS) %>%
 dplyr::summarise(Mismatch_NCells = n(), Mismatch_PctTile = sum(PctTile))


cleaned14 <- dplyr::mutate(pixels2014, PctTile = 1/ncells_tile) %>% 
  dplyr::filter(!is.na(FIPS)) %>% # remove mis-match points that do not have FIPS code (overlap water or other non-county polygon)
  dplyr::filter(!duplicated(paste0(x, y))) # remove points that might be duplicated 
#duplication could happen due to calculating mis-match from state tiles rather than actual state polygons, borders don't match exactly

freq_bystate14 <- cleaned14 %>%  dplyr::group_by(NVC_Class, CDL_Class, CDLYear, State) %>%
  dplyr::summarise(Mismatch_NCells = n(), Mismatch_PctTile = sum(PctTile, rm.na=T))

freq_bycounty14 <- cleaned14 %>% dplyr::group_by(NVC_Class, CDL_Class, CDLYear, State, FIPS) %>%
  dplyr::summarise(Mismatch_NCells = n(), Mismatch_PctTile = sum(PctTile))


bothyears <- rbind(pixels2012, pixels2014)

cleaned <- dplyr::mutate(bothyears, PctTile = 1/ncells_tile) %>% 
  dplyr::filter(!is.na(FIPS)) %>% # remove mis-match points that do not have FIPS code (overlap water or other non-county polygon)
  dplyr::group_by(CDLYear) %>%
  dplyr::mutate(coord = (paste0(x, y))) %>%
  dplyr::distinct(coord, .keep_all=T) # remove points that might be duplicated 
#duplication could happen due to calculating mis-match from state tiles rather than actual state polygons, borders don't match exactly

freq_bystate <- cleaned %>%  dplyr::group_by(NVC_Class, CDL_Class, CDLYear, State) %>%
  dplyr::summarise(Mismatch_NCells = n(), Mismatch_PctTile = sum(PctTile, rm.na=T))

freq_bycounty <- cleaned %>% dplyr::group_by(NVC_Class, CDL_Class, CDLYear, State, FIPS) %>%
  dplyr::summarise(Mismatch_NCells = n(), Mismatch_PctTile = sum(PctTile))


