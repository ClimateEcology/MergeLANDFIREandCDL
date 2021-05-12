
reassign_NA <- function(map, xpct, ypct, window_size, crops=NA) {
  
  # specify allow_classes is a global variable (necessary for futures package to work)
  allow_classes
  
  bbox <- ext(c( (xmax(map)-xmin(map))*xpct[1] + xmin(map),  (xmax(map)-xmin(map))*xpct[2] + xmin(map),
                 (ymax(map)-ymin(map))*ypct[1] + ymin(map),  (ymax(map)-ymin(map))*ypct[2] + ymin(map))
  )
  
  smaller_test <- terra::crop(map, y=bbox)

    if (any(is.na(crops))) {
      
      #use custom function, but specify which classes can be returned as the mode.
      #If the allowed classes don't exist, return -1001
      pooey <- terra::focal(smaller_test, na.only=T, w=window_size, fun='modal', 
                            na.rm=T)

    } else if (!any(is.na(crops))) {
      
      #use custom function, but specify which classes can be returned as the mode.
      #If the allowed classes don't exist, return -1001
      pooey <- terra::focal(smaller_test, na.only=T, w=window_size, fun='custom_modal', 
                            na.rm=T)
    }
  
  return(pooey)
}


custom_modal <- function(x, na.rm, ...) { 
  
  # retrieve list of allowable classes from the global environment
  # this is a sub-optimal solution because it require configuring the global env correctly
  # BUT focal does not accept more than two arguements, so I don't see any other way to do this...
  
  allow_classes <- get('allow_classes', pryr::where('allow_classes'))
  
  if (any(x %in% allow_classes)) {
    
    #reassign dis-allowed classes to NA
    x[!x %in% allow_classes] <- NA
    
    #calculate mode of remaining (not NA) values
    mo <- terra::modal(x, na.rm=T, ties='random')
    return(mo)
    
  } else {
    
    return(-1001)
    
  }
}



