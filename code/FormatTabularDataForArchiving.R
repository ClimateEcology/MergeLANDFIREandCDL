rm(list=ls())

##### pixel mis-match (after step 1 of geospatial workflow) as number of cells and proportion

mismatch_byyearcounty <- readRDS('./data/TechnicalValidation/pixel_mismatch_byyear_bycounty.RDS')

head(mismatch_byyearcounty)

any(is.na(mismatch_byyearcounty$CDL_Name))

mismatch_byyearcounty <- mismatch_byyearcounty %>%
  dplyr::arrange(FIPS) %>%
  dplyr::mutate(FIPS = stringr::str_pad(FIPS, 5, pad="0")) %>%# reformat FIPS to have leading zeros
  dplyr::rename(NVC_Name = NVC_SpecificClass,
                NCells_NVCClass_perCounty = NCells_Class,
                NVC_CDL_Pair = NVC_CDL_Named,
                CDL_Year = CDLYear,
                STATE = State) %>%
  dplyr::select(FIPS, STATE, CDL_Year, everything())

# some years spreadsheets are missing CDL class names
if (any(is.na(mismatch_byyearcounty$CDL_Name)))  {
  cdl_key <- read.csv('./data/TabularData/CDL_codes_names_colors_2022.csv') %>%
    rename(CDL_Name = Class_Names, CDL_Class=Codes) %>%
    dplyr::select(CDL_Name, CDL_Class) %>%
    dplyr::mutate(CDL_Class = as.character(CDL_Class))
  
  mismatch_byyearcounty <- mismatch_byyearcounty %>%
    dplyr::select(-CDL_Name) %>%
    left_join(cdl_key) %>%
    dplyr::select(FIPS, STATE, CDL_Year, CDL_Class, CDL_Name, NVC_Name, everything())
}


if (!dir.exists('./data/DataToArchive')) {
  dir.create('./data/DataToArchive')
}

mismatch_byyearcounty <- mismatch_byyearcounty %>%
  dplyr::rename(State = STATE) 

mismatch_byyearcounty %>% data.table::fwrite('./data/DataToArchive/pixel_mismatch_byyear_bycounty.csv')
any(is.na(mismatch_byyearcounty))

names(which(colSums(is.na(mismatch_byyearcounty))>0))

###### unresolved pixels

for (CDLYear in c(2012:2021)) {
  library(dplyr)
  # read county shapefile with LANDFIRE regions
  county <- sf::st_read('./data/SpatialData/us_counties_better_coasts_LFregion.shp') %>%
    dplyr::rename(LF2010_Region=LF2010_) # fix column name that was abbreviated by shp driver
  
  # read NVC/CDL pixel frequency data
  merged_freq <- read.csv(paste0('./data/PixelFreq/CDL', CDLYear, 'NVC_CountyPixelFreq.csv')) %>%
    dplyr::filter(!is.na(County)) %>%
    dplyr::group_by(State, County) %>%
    dplyr::mutate(PctCounty = (NCells/sum(NCells)) *100) %>%
    dplyr::ungroup()
  
  # are there any counties in county shapefile that are NOT in dataset on NVC pixel frequency?
  paste0(county$COUNTY, ", ", county$STATE)[!paste0(county$COUNTY, ", ", county$STATE) %in% paste0(merged_freq$County, ", ", merged_freq$State)]
  
  # join pixel frequency with LF regions
  merged_freq_sf <- county %>%
    dplyr::select(FIPS, STATE, COUNTY, LF2010_Region) %>%
    dplyr::left_join(merged_freq, by=c('STATE'='State', 'COUNTY'='County'))
  
  # join pixel frequency with LF regions
  merged_freq <- sf::st_drop_geometry(county) %>%
    dplyr::select(STATE, COUNTY, LF2010_Region) %>%
    dplyr::left_join(merged_freq, by=c('STATE'='State', 'COUNTY'='County'))
  
  
  # fill in a few missing polygons that show up on no data map
  counties <- sf::st_read('./data/SpatialData/us_counties_better_coasts.shp') %>%
    dplyr::filter(!is.na(COUNTY))
  
  nodata_freq <- merged_freq_sf %>%
    sf::st_drop_geometry() %>%
    dplyr::filter(Class == -1001)
  
  # nodata <- counties %>%
  #   dplyr::select(FIPS, STATE, COUNTY) %>%
  #   dplyr::left_join(nodata_freq) %>%
  #   tidyr::replace_na(list(PctCounty=0, NCells=0))
  
  oneyear <- sf::st_drop_geometry(nodata_freq) %>%
    dplyr::rename(MergedRasterClassName = Class) %>%
    dplyr::mutate(CDL_Year = CDLYear,
                  MergedRasterName = 'CDL/NVC mismatch, unresolved conflict') %>%
    dplyr::select(FIPS, STATE, CDL_Year, COUNTY, LF2010_Region, MergedRasterClassName, MergedRasterName, everything())
  
  if (CDLYear == 2012) {
    allyears <- oneyear
  } else if (CDLYear > 2012) {
    allyears <- rbind(allyears, oneyear)
  }
}

head(allyears)
head(mismatch_byyearcounty)

unique(allyears$CDL_Year)

allyears <- allyears %>%
  dplyr::rename(State = STATE, County = COUNTY, 
                MergedRaster_Class = MergedRasterClassName, MergedRaster_ClassName = MergedRasterName,
                Pct_Unresolved = PctCounty)

allyears %>% data.table::fwrite('./data/DataToArchive/unresolved_conflict_byyear_bycounty.csv')

sort(unique(allyears$FIPS))

any(is.na(allyears))

###### accuracy and data coverage of cdl, nvc, and merged dataset
for (CDLYear in c(2012:2021)) {
  
  accuracy_datacoverage <- readRDS(paste0('./data/TechnicalValidation/summarized_accuracy_data_CDL', 
                                          CDLYear, '_NVC_Merged.rds')) %>%
    sf::st_drop_geometry() %>%
    mutate(CDL_Year = CDLYear,
           FocalGroup=Dataset) %>%
    dplyr::select(FIPS, STATE, CDL_Year, COUNTY, FocalGroup, Dataset_Name, 
                  NCells_County, NCells_FocalGroup,
                  FocalGroup_PctCounty, WithData_PctFocalGroup, 
                  WtdProdAcc, WtdUserAcc)

  if (CDLYear == 2012)
    allyears_accuracy <- accuracy_datacoverage
  else {
    allyears_accuracy <- rbind(allyears_accuracy, accuracy_datacoverage)
  }
}


allyears_accuracy <- allyears_accuracy %>%
  dplyr::rename(State = STATE, County = COUNTY)

allyears_accuracy %>% data.table::fwrite('./data/DataToArchive/accuracy_datacoverage_byyear_bycounty.csv')

any(is.na(allyears_accuracy))

