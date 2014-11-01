#' @title Returns bounding box surrounding Finland
#'
#' @return Bounding box in WGS84 coordinate system as an \code{\link[raster]{extent}} object.
#'
#' @import raster
#' @author Jussi Jousimo \email{jvj@@iki.fi}
#' @export
getFinlandBBox <- function() raster::extent(c(19.0900,59.3000,31.5900,70.130))

patternColumnIndex <- function(spdf, pattern) {
  if (missing(spdf) | missing(pattern))
    stop("Required argument 'spdf' or 'pattern' missing.")
  return(grep(pattern, names(spdf)))
}

#' @author Jussi Jousimo \email{jvj@@iki.fi}
#' @export
transformTimeValuePairData <- function(layer, measurementColumnNamePattern="^result_MeasurementTimeseries_point_MeasurementTVP_value\\d*$", variableColumnNames) {
  if (missing(layer))
    stop("Required argument 'layer' missing.")
  if (missing(variableColumnNames))
    stop("Required argument 'variableColumnNames' missing.")
  
  measurementColumnIndex <- patternColumnIndex(layer, measurementColumnNamePattern)
  names(layer)[measurementColumnIndex] <- if (length(measurementColumnIndex) > 1)
    sapply(1:length(measurementColumnIndex), function(x) paste0("measurement", x))
  else
    "measurement"
  layer@data$variable <- rep(variableColumnNames, length(layer) / length(variableColumnNames))
  
  return(layer)
}

#' @import sp
#' @author Jussi Jousimo \email{jvj@@iki.fi}
#' @export
wideToLongFormat = function(layer, timeColumnNamePattern="^time\\d*$", measurementColumnNamePattern="^measurement\\d*$", variableColumnName="variable") {
  if (missing(layer))
    stop("Required argument 'layer' missing.")
  
  timeIndex <- patternColumnIndex(layer, timeColumnNamePattern)
  measurementIndex <- patternColumnIndex(layer, measurementColumnNamePattern)
  variableIndex <- which(names(layer) == variableColumnName)
  
  n <- length(timeIndex)
  olddf <- layer@data
  newdf <- data.frame()
  for (i in 1:n) {
    x <- data.frame(time=olddf[,timeIndex[i]],
                    olddf[,-c(timeIndex, measurementIndex, variableIndex)],
                    variable=olddf[,variableIndex], 
                    measurement=olddf[,measurementIndex[i]])
    newdf <- rbind(newdf, x)
  }

  coords <- coordinates(layer)
  newlayer <-  SpatialPointsDataFrame(coords[rep(1:nrow(coords), n),], data=newdf, proj4string=layer@proj4string)
  return(newlayer)
}

#' @author Jussi Jousimo \email{jvj@@iki.fi}
#' @export
getRasterLayerNames <- function(startDateTime, endDateTime, by, variables, dateTimeFormat="%Y-%m-%d") {
  if (missing(startDateTime) | missing(endDateTime) | missing(by) | missing(variables))
    stop("Required argument 'startDateTime' or 'endDateTime' or 'by' or 'variables' missing.")
  dateSeq <- seq.Date(as.Date(startDateTime), as.Date(endDateTime), by=by)
  x <- expand.grid(date=dateSeq, measurement=variables)
  layerNames <- do.call(function(date, measurement) paste(measurement, strftime(date, dateTimeFormat), sep="."), x)
  return(layerNames)
}

#' Get all active FMI weather stations.
#' 
#' Table of active weather stations has been manually copied from FMI web 
#' pages and is not fetched over the API. Table is provided as a csv file
#' within \code{fmi} package. 
#'
#' @return dataframe of active weather stations
#' 
#' @seealso \url{http://ilmatieteenlaitos.fi/havaintoasemat?p_p_id=stationlistingportlet_WAR_fmiwwwweatherportlets&p_p_lifecycle=0&p_p_state=normal&p_p_mode=view&p_p_col_id=column-4&p_p_col_count=1&_stationlistingportlet_WAR_fmiwwwweatherportlets_stationGroup=WEATHER}
#' 
#' @author Joona Lehtomaki \email{joona.lehtomaki@@gmail.com}
#' @export
#'
fmi_weather_stations <- function() {
  csv.file <- system.file("extdata", "weather_stations.csv", package="fmi")
  weather.stations <- read.table(csv.file, sep=";", header=TRUE, as.is=TRUE)
  return(weather.stations)
}  

#' Check if a provided ID number is a valid FMI SID.
#'
#' \code{fmisid} is a ID numbering system used by the FMI. 
#'
#' @param fmisid numeric or character ID number.
#'
#' @return logical
#' 
#' @seealso \code{\link{fmi_weather_stations}}
#' 
#' @author Joona Lehtomaki \email{joona.lehtomaki@@gmail.com}
#' @export
#'
valid_fmisid <- function(fmisid) {
  fmisid <- as.numeric(fmisid)
  weather.stations <- fmi_weather_stations()
  if (fmisid %in% weather.stations$FMISID) {
    return(TRUE)
  } else {
    return(FALSE)
  }
}
