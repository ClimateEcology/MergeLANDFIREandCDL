

summarize_techval <- function(year, in_data) {

  oneyear <- dplyr::filter(in_data, CDLYear == year)
  
  cleaned <- dplyr::mutate(oneyear, PctTile = 1/ncells_tile) %>% 
    dplyr::filter(!is.na(FIPS)) %>% # remove mis-match points that do not have FIPS code (overlap water or other non-county polygon)
    dplyr::mutate(coord_year = (paste0(x, y, "_", CDLYear))) %>%
    dplyr::distinct(coord_year, .keep_all=T)  # remove points that are duplicated within a given CDL year
  #duplication could happen due to calculating mis-match from state tiles rather than actual state polygons, borders don't match exactly
  
  logger::log_info('Finished cleaning and remove duplicate points, starting summarize by county.')
  
  freq_bycounty <- cleaned %>% dplyr::group_by(NVC_Class, CDL_Class, CDLYear, State, FIPS) %>%
    dplyr::summarise(Mismatch_NCells = n(), Mismatch_PctTile = sum(PctTile))
  
  return(freq_bycounty)
}