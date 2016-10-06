#' @title Returns bounding box surrounding Finland
#'
#' @description TBA
#'
#' @return Bounding box in WGS84 coordinate system as an \code{\link[raster]{extent}} object.
#'
#' @import raster
#' @author Jussi Jousimo \email{jvj@@iki.fi}
#' @export
getFinlandBBox <- function() {
  return(raster::extent(c(19.0900,59.3000,31.5900,70.130)))
}

patternColumnIndex <- function(spdf, pattern) {
  if (missing(spdf) | missing(pattern))
    stop("Required argument 'spdf' or 'pattern' missing.")
  return(grep(pattern, names(spdf)))
}

#' Handle and transform TimeValuePairData
#' 
#' Response data is massaged into suitable local format.
#'
#' @param layer XXX object
#' @param measurementColumnNamePattern String pattern used to match the 
#'        measurement column.
#' @param variableColumnNames String vector used to match the 
#'        variable columns.
#' @param measurementColumnName String name for the measurument column.
#' 
#' @return layer object.
#'
#' @author Jussi Jousimo \email{jvj@@iki.fi}
#' @export 
transformTimeValuePairData <- function(layer, measurementColumnNamePattern="^result_MeasurementTimeseries_point_MeasurementTVP_value\\d*$", 
                                       variableColumnNames, 
                                       measurementColumnName="measurement") {
  if (missing(layer))
    stop("Required argument 'layer' missing.")
  if (missing(variableColumnNames))
    stop("Required argument 'variableColumnNames' missing.")
  
  measurementColumnIndex <- patternColumnIndex(layer, measurementColumnNamePattern)
  names(layer)[measurementColumnIndex] <- if (length(measurementColumnIndex) > 1)
    sapply(1:length(measurementColumnIndex), function(x) paste0(measurementColumnName, x))
  else
    measurementColumnName
  layer@data$variable <- rep(variableColumnNames, length(layer) / length(variableColumnNames))
  
  return(layer)
}

#' Convert data from long to wide format.
#'
#' FIXME: this function is now somewhat specific to BsWfsElement
#' format. Function could be made more generic, or some sort of class structure
#' for different response data types needs to be implemented.
#'
#' @note response field names \code{fid}, \code{gml_id}, \code{ParameterName}
#'       and \code{ParameterValue} are hard coded. If these change, the
#'       function must be adjusted accordingly.
#'
#' @param layer Spatial* object.
#' @param idColumn String pattern used to match the gml_id column.
#' @param parameterName String name for the parameter column name.
#' @param parameterValue String name for the parameter value column.
#' 
#' @return layer object.
#' 
#' @import sp dplyr tidyr
#' @author Joona Lehtomäki \email{joona.lehtomaki@@gmail.com}
#' @export
#' 
LongToWideFormat = function(layer) {
  if (missing(layer))
    stop("Required argument 'layer' missing.")
  
  # Figure out how many parameter there are per observation. At this point,
  # there will be one row (i.e. one sp feaure, e.g. point) per parameter.
  # glm_id column has the following structure:
  #
  # BsWfsElement.1.1
  # BsWfsElement.1.2
  # BsWfsElement.2.1
  # BsWfsElement.2.2 and so on.
  #
  # Use the major number in BsWfsElement.MAJOR.MINOR to define each observation.
  # Start working with just the attribute data
  attr_data <- layer@data %>% 
    # Split gml_id into elements
    tidyr::separate(gml_id, c("gml_text", "gml_group", "gml_id_minor"), "\\.",
                    convert = TRUE) %>% 
    # Drop fid
    dplyr::select(-fid)
  
  # Check that each gml_id group has the same number of parameter entries
  gml_group_entries <- attr_data %>%
    dplyr::group_by(gml_group) %>% 
    dplyr::summarise(
      n = n()
    )
  if (length(unique(gml_group_entries$n)) != 1) {
    stop("Unequal number of parameters in gml groups")
  }
  # Get the number of parameters in each group
  n_params <- unique(gml_group_entries$n)
  
  # Keep the first MINOR in all parameter groups
  minors <- attr_data$gml_id_minor[seq(1, length(attr_data$gml_id_minor), 
                                       n_params)]
  attr_data$gml_id_minor <- rep(minors, 1, each = n_params)
  
  # Spread the parameters into individual columns
  attr_data <- attr_data %>% 
    tidyr::spread(ParameterName, ParameterValue)
  
  # Extract every Nth row in the original Spatial*DataFrame, where N is the
  # number of parameters in the gml_group. 
  layer_subset <- layer[seq(1, nrow(layer), n_params),]
  # At this point, the layer feature and attt_data row order should be the
  # same, but there's no telling. Use "gml_text", "gml_group" and 
  # "gml_id_minor" to generate a join key.
  attr_data <- attr_data %>% 
    dplyr::mutate(key = paste(gml_text, gml_group, gml_id_minor, sep = "."))
  
  # Merge the layer subset with the attribute data
  layer_subset@data <- layer_subset@data %>%
    dplyr::select(gml_id) %>% 
    dplyr::left_join(., attr_data, by = c("gml_id" = "key")) %>% 
    dplyr::select(-gml_id, -gml_id_minor, -gml_text)
  return(layer_subset)
}

#' Convert data from long to wide format
#'
#' FIXME: this function is now somewhat specific to PointTimeSeriesObservation
#' format. Function could be made more generic, or some sort of class structure
#' for different response data types needs to be implemented.
#'
#' @param layer XXX object.
#' @param timeColumnNamePattern String pattern used to match the 
#'        time column.
#' @param measurementColumnNamePattern String pattern used to match the 
#'        measurement column.
#' @param variableColumnName String name for the variable column name.
#' 
#' @return layer object.
#' 
#' @import sp
#' @author Jussi Jousimo \email{jvj@@iki.fi}
#' @export
wideToLongFormat = function(layer, timeColumnNamePattern = "^time\\d*$", 
                            measurementColumnNamePattern = "^measurement\\d*$", 
                            variableColumnName = "variable") {
  if (missing(layer))
    stop("Required argument 'layer' missing.")
  
  timeIndex <- patternColumnIndex(layer, timeColumnNamePattern)
  measurementIndex <- patternColumnIndex(layer, measurementColumnNamePattern)
  variableIndex <- which(names(layer) == variableColumnName)
  n <- length(timeIndex)
  olddf <- layer@data
  newdf <- data.frame()
  for (i in 1:n) {
    x <- data.frame(time = olddf[,timeIndex[i]],
                    olddf[,-c(timeIndex, measurementIndex, variableIndex)],
                    variable = olddf[,variableIndex], 
                    measurement = olddf[,measurementIndex[i]])
    newdf <- rbind(newdf, x)
  }

  coords <- coordinates(layer)
  newlayer <-  SpatialPointsDataFrame(coords[rep(1:nrow(coords), n),], 
                                      data = newdf, 
                                      proj4string = layer@proj4string)
  return(newlayer)
}

#' Return available rasters layer names
#' 
#' Query is filtered with start and end dates.
#'
#' @param startDateTime String start date.
#' @param endDateTime String end date.
#' @param by TBA.
#' @param variables TBA.
#' @param dateTimeFormat TBA.
#' 
#' @return character vector of raster layer names.
#'
#' @author Jussi Jousimo \email{jvj@@iki.fi}
#' @export
getRasterLayerNames <- function(startDateTime, endDateTime, by, variables, 
                                dateTimeFormat="%Y-%m-%d") {
  if (missing(startDateTime) | missing(endDateTime) | missing(by) | missing(variables))
    stop("Required argument 'startDateTime' or 'endDateTime' or 'by' or 'variables' missing.")
  dateSeq <- seq.Date(as.Date(startDateTime), as.Date(endDateTime), by = by)
  x <- expand.grid(date = dateSeq, measurement = variables)
  layerNames <- do.call(function(date, measurement) paste(measurement, 
                                                          strftime(date, 
                                                                   dateTimeFormat), 
                                                          sep = "."), x)
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
#' @importFrom utils read.table
#' 
#' @author Joona Lehtomaki \email{joona.lehtomaki@@gmail.com}
#' @export
#'
fmi_weather_stations <- function() {
  csv.file <- system.file("extdata", "weather_stations.csv", package = "fmi")
  weather.stations <- read.table(csv.file, sep = ";", header = TRUE, 
                                 dec = ",", as.is = TRUE)
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
