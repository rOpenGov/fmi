#' @title Returns bounding box surrounding Finland
#'
#' @description TBA
#'
#' @return Bounding box in WGS84 coordinate system as an \code{\link[raster]{extent}} object.
#'
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
transformTimeValuePairData <- function(layer, 
                                       measurementColumnNamePattern=NULL, 
                                       variableColumnNames, 
                                       measurementColumnName="measurement") {
  if (missing(layer)) {
    stop("Required argument 'layer' missing.")
  }
  if (is.null(measurementColumnNamePattern)) {
    measurementColumnNamePattern <- "^result_MeasurementTimeseries_point_MeasurementTVP_value\\d*$"
  }
  if (missing(variableColumnNames)) {
    stop("Required argument 'variableColumnNames' missing.")
  }
  
  measurementColumnIndex <- patternColumnIndex(layer, measurementColumnNamePattern)
  names(layer)[measurementColumnIndex] <- if (length(measurementColumnIndex) > 1)
    sapply(1:length(measurementColumnIndex), function(x) paste0(measurementColumnName, x))
  else
    measurementColumnName
  layer@data$variable <- rep(variableColumnNames, length(layer) / length(variableColumnNames))
  
  return(layer)
}

# Declare globalVariables to prevent check from complaining about
# NSE
utils::globalVariables(c("gml_id", "fid", "gml_group", "n",
                         "ParameterName", "ParameterValue", "gml_text", 
                         "gml_id_minor", "."))

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
#' 
#' @importFrom magrittr %>%
#' 
#' @return layer object.
#' 
#' @author Joona Lehtomaki \email{joona.lehtomaki@@gmail.com}
#' @export
#' 
LongToWideFormat = function(layer) {
  if (missing(layer)) {
    stop("Required argument 'layer' missing.")
  }
    
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
                            measurementColumnNamePattern = "^measurement", 
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
  
  coords <- sp::coordinates(layer)
  newlayer <-  sp::SpatialPointsDataFrame(coords[rep(1:nrow(coords), n),], 
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

# function fmi_station()

# Reading the local version included within the package is separated into its
# own function, since it's also used for tests.
.fmi_stations_local <- function() {
  system.file("extdata", "fmi_stations.csv", package = "fmi") %>%
    utils::read.csv(as.is = TRUE) %>%
    tibble::as_tibble()
}

# Declare globalVariables to prevent check from complaining about
# NSE
utils::globalVariables(c("Elevation", "FMISID", "LPNN", "WMO",
                         "Lat", "Lon", "Started"))


# Use a closure for function fmi_station() in order to cache the results.
.fmi_stations_closure <- function() {
  cached_stations <- NULL
  function(groups=NULL, quiet=FALSE) {
    stations <- NULL
    if (!is.null(cached_stations)) {
      stations <- cached_stations
    } else {
      tryCatch({
        installed_packages <- rownames(utils::installed.packages())
        if (any(c("rvest", "XML") %in% installed_packages)) {
          station_url <- "http://en.ilmatieteenlaitos.fi/observation-stations"
          if ("rvest" %in% installed_packages) {
            stations <- xml2::read_html(station_url) %>%
              rvest::html_table() %>%
              `[[`(1L) %>%
              tibble::as_tibble() %>%
              dplyr::mutate(
                Elevation = Elevation %>% sub(pattern = "\n.*$", replacement = "") %>%
                  as.integer()
              )
          } else if ("XML" %in% installed_packages) {
            stations <- XML::readHTMLTable(station_url, which = 1L,
                stringsAsFactors = FALSE) %>%
              tibble::as_tibble() %>%
              dplyr::mutate(
                FMISID = FMISID %>% as.integer(),
                LPNN = LPNN %>% as.integer(),
                WMO = WMO %>% as.integer(),
                Lat = Lat %>% as.numeric(),
                Lon = Lon %>% as.numeric(),
                Elevation = Elevation %>% sub(pattern = "\n.*$", replacement = "") %>%
                  as.integer(),
                Started = Started %>% as.integer()
              )
          }
          # Groups can contain multiple values, but html_table() and
          # readHTMLable() both lose the separating '<br />'. Since group names
          # seem to start with an uppercase letter, use that to separate them.
          # It seems that the order in which they are returned can vary, so
          # sort them in alphabetical order to get consistent results
          # (important for the test that checks whether the included local copy
          # is still up-to-date with the online version).
          stations$Groups <- stations$Groups %>%
            sub(pattern = "([a-z])([A-Z])", replacement = "\\1;\\2") %>%
            strsplit(";") %>%
            lapply(sort) %>%
            lapply(paste, collapse = ", ") %>%
            unlist()
          cached_stations <<- stations
          if (!quiet) {
            message("Station list downloaded from ", station_url)
          }
        } else {
          if (!quiet) {
            message("Package rvest or XML required for downloading.")
          }
        }
      }, error = function(e) {
        if (!quiet) {
          message("Error downloading from ", station_url)
        }
      })
    }
    if (is.null(stations)) {
      if (!quiet) {
        message("Using local copy instead.")
      }
      stations <- .fmi_stations_local()
    }
    if (!is.null(groups)) {
      indexes <- lapply(groups, grep, x = stations$Groups) %>%
        unlist() %>%
        sort() %>%
        unique()
      stations <- stations[indexes, ]
    }
    stations
  }
}
#' Get a list of active FMI observation stations.
#' 
#' A table of active observation stations is downloaded from the website of
#' Finnish Meteorological Institute, if package \pkg{rvest} or package \pkg{XML}
#' is installed. If neither is, or if the download fails for any other reason, a
#' local copy provided as a csv file within the \pkg{fmi} package is used.
#'
#' \code{fmi_weather_stations()} is a deprecated alias for
#' \code{fmi_stations(groups="Weather stations")}.
#'
#' @param groups a character vector of observation station groups to subset for
#' @param quiet whether to suppress printing of diagnostic messages
#'
#' @return a \code{data.frame} of active observation stations
#' 
#' @seealso \url{http://en.ilmatieteenlaitos.fi/observation-stations}
#'
#' @author Joona Lehtomaki \email{joona.lehtomaki@@gmail.com},
#' Ilari Scheinin
#'
#' @importFrom magrittr %>%
#' 
#' @export
#'
#' @aliases fmi_weather_stations
#'
fmi_stations <- .fmi_stations_closure()

#' @export
fmi_weather_stations <- function() {
  .Deprecated('fmi_stations(groups="Weather stations")')
  fmi_stations(groups = "Weather stations")
}

#' Check if a provided ID number is a valid FMI SID.
#'
#' \code{fmisid} is a ID numbering system used by the FMI. 
#'
#' @param fmisid numeric or character ID number.
#'
#' @return logical
#' 
#' @seealso \code{\link{fmi_stations}}
#' 
#' @author Joona Lehtomaki \email{joona.lehtomaki@@gmail.com}
#' @export
#'
valid_fmisid <- function(fmisid) {
  if (is.null(fmisid)) {
    return(FALSE)
  } else {
    fmisid <- as.numeric(fmisid)
    stations <- fmi_stations()
    if (fmisid %in% stations$FMISID) {
      return(TRUE)
    } else {
      return(FALSE)
    }
  }
}
