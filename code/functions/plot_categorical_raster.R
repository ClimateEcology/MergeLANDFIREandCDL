
plot_categorical_raster <- function(map, attribute_table, draw_legend=F) {
  # build a raster attibute table that is filtered to classes in *this* raster
  # without this, the levelplot colors do not work
  map <- raster::ratify(map)
  rat <- levels(map)[[1]]
  
  # visualize what raster colors will be
  red <- dplyr::select(attribute_table, tidyr::matches('red', ignore.case = T))
  green <- dplyr::select(attribute_table, tidyr::matches('green', ignore.case = T))
  blue <- dplyr::select(attribute_table, tidyr::matches('blue', ignore.case = T))
  class_names <- dplyr::select(attribute_table, tidyr::matches('name', ignore.case = T))
  
  color_pal <- rgb(red[,1], green[,1], blue[,1])
  pal(color_pal)
  
  
  rat$CLASS_NAME <- stringr::str_wrap(gsub(class_names[,1], pattern="Eastern Cool Temperate ",
                                           replacement = ""), width = 35)
  rat$RED <- attribute_table$RED
  rat$GREEN <- attribute_table$GREEN
  rat$BLUE <- attribute_table$BLUE
  
  m <- setValues(raster(map), map[])
  levels(m) <- rat
  
  theme <- rasterVis::rasterTheme(color_pal)
  
  if (draw_legend == T) {
  output_map <- rasterVis::levelplot(m, col.regions=color_pal, 
                                     par.settings= noMargins(theme, rightkey=T),
                                     margin=list(draw=F), 
                                     scales=list(draw=F),
                                     colorkey=T)
  } else {
    output_map <- rasterVis::levelplot(m, col.regions=color_pal, 
                                       par.settings= noMargins(theme, rightkey=T),
                                       margin=list(draw=F), 
                                       scales=list(draw=F),
                                       colorkey=F)
  }
  
  return(output_map)
}
