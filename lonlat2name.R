library(sf)
require(tibble)
require(pforeach)

find_name <- function(lon, lat, shape, target, remove_out) {
  
  if (is.na(lon) | is.na(lat)) {
    if (target != "df") {
      return(NA)
    } else if (target == "df") {
      return(tibble(lon = lon, lat = lat, prefecture = NA_character_, city = NA_character_, code = NA_real_))
    }
  }
  
  if (remove_out) {
    if (lon < 20.2531 | lon > 45.3326 | lat < 122.5557 | lat > 153.5912) {
      if (target != "df") {
        return("国外")
      } else if (target == "df") {
        return(tibble(lon = lon, lat = lat, prefecture = "国外", city = "国外", code = NA_real_))
      }
    }
  }
  
  which.row <- suppressMessages(st_contains(shape, st_point(c(lon, lat)), sparse = FALSE)) %>%  
    grep(TRUE, .)
  
  if (identical(which.row, integer(0)) == TRUE) {
    if (target != "df") {
      return("国外")
    } else if (target == "df") {
      return(tibble(lon = lon, lat = lat, prefecture = "国外", city = "国外", code = NA_real_))
    }
  } else {
    prefecture <- as.character(shape[which.row,]$N03_001)
    
    if (is.na(shape[which.row,]$N03_003)) {
      city <- as.character(shape[which.row,]$N03_004)
    } else {
      city <- paste0(as.character(shape[which.row,]$N03_003), as.character(shape[which.row,]$N03_004))
    }
    
    code <- as.numeric(shape[which.row,]$N03_007)
    
    if (target == "prefecture"){
      return(prefecture)
    } else if (target == "city") {
      return(city)
    } else if (target == "both") {
      return(paste0(prefecture, city))
    } else if (target == "code") {
      return(code)
    } else if (target == "df") {
      return(tibble(lon = lon, lat = lat, prefecture, city, code))
    }
  }
  
}

lonlat2name <- function(lon, lat, shape, target = "prefecture", remove_out = FALSE, parallel = FALSE) {
  
  if (length(lon) != length(lat)) {
    stop("The numbers of lon and lat are different.")
  }
  
  if (parallel) {
    
    if (target != "df") {
      output <- pforeach(i = 1:length(lon))({
        find_name(lon[i], lat[i], shape, target, remove_out)
      })
    } else if (target == "df") {
      output <- pforeach(i = 1:length(lon), .c = rbind)({
        find_name(lon[i], lat[i], shape, target, remove_out)
      })
    }
    
  } else {
    
    output <- NULL
    
    if (target != "df") {
      for (i in 1:length(lon)) {
        output <- c(output, find_name(lon[i], lat[i], shape, target, remove_out))
      }
    } else if (target == "df") {
      for (i in 1:length(lon)) {
        output <- rbind(output, find_name(lon[i], lat[i], shape, target, remove_out))
      }
    }
    
  }
  
  return(output)

}
