# This file is a part of the fmi package (http://github.com/rOpenGov/fmi)
# in association with the rOpenGov project (ropengov.github.io)

# Copyright (C) 2014 Jussi Jousimo. 
# All rights reserved.

# This program is open source software; you can redistribute it and/or modify 
# it under the terms of the FreeBSD License (keep this notice): 
# http://en.wikipedia.org/wiki/BSD_licenses

# This program is distributed in the hope that it will be useful, 
# but WITHOUT ANY WARRANTY; without even the implied warranty of 
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

#' @title A class to retrieve and manipulate data from the FMI open API
#' 
#' @description TBA
#' 
#' @section Methods:
#' \itemize{
#'  \item \code{getDailyWeather}: Returns daily weather time-series
#'  \item \code{getLightningStrikes}: Returns lightning strikes for defined time period
#'  \item \code{getMonthlyWeatherRaster}: Returns monthly weather raster
#' }
#' @seealso \code{\link[rwfs]{WFSClient}}, \code{\link[rwfs]{WFSCachingClient}}
#' @import R6
#' @import dplyr 
#' @references See citation("fmi")
#' @author Jussi Jousimo \email{jvj@@iki.fi}, Joona Lehtomaki  \email{joona.lehtomaki@gmail.com}
#' @exportClass FMIWFSClient
#' @export FMIWFSClient
#' @examples # See the vignette.
FMIWFSClient <- R6::R6Class(
  "FMIWFSClient",
  inherit = rwfs::WFSCachingClient,
  private = list(
    processParameters = function(startDateTime = NULL, endDateTime = NULL, 
                                 bbox = NULL, fmisid = NULL) {
      if (inherits(startDateTime, "POSIXt")) {
          startDateTime <- asISO8601(startDateTime)
        }
      if (inherits(endDateTime, "POSIXt")) {
          endDateTime <- asISO8601(endDateTime)
        }
      
      if (!is.null(fmisid) && !valid_fmisid(fmisid)) {
        stop("Invalid 'fmisid' (", fmisidm, ") specified.")
      }
      
      if (!is.null(bbox)) {
        if (inherits(bbox, "Extent")) {
          bbox <- with(attributes(bbox), paste(xmin, xmax, ymin, ymax, sep = ","))
        } else {
          stop("Parameter 'bbox' must be of class 'Extent'.")
        }
      }
      return(list(startDateTime = startDateTime, endDateTime = endDateTime, 
                  fmisid = fmisid, bbox = bbox))
    },
    
    getRasterURL = function(parameters) {
      layers <- self$listLayers()
      if (length(layers) == 0) {
        return(character(0))
      }
      
      meta <- self$getLayer(layer = layers[1], parameters = parameters)
      if (is.character(meta)) {
        return(character(0))
      }
      
      return(meta@data$fileReference)
    }
  ),
  public = list(
    getDailyWeather = function(variables=c("rrday","snow","tday","tmin","tmax"), 
                               startDateTime, endDateTime, bbox=NULL, fmisid=NULL) {      
      if (inherits(private$request, "FMIWFSRequest")) {
        if (missing(startDateTime) | missing(endDateTime)) {
          stop("Arguments 'startDateTime' and 'endDateTime' must be provided.")
        }
        if (is.null(bbox) & is.null(fmisid)) {
          stop("Either argument 'bbox' or 'fmisid' must be provided.")
        }
        
        # FMISID takes precedence over bbox (usually more precise)
        if (!is.null(bbox) & !is.null(fmisid)) {
          bbox <- NULL
          warning("Both bbox and fmisid provided, using only fmisid.")
        }

        p <- private$processParameters(startDateTime = startDateTime, 
                                       endDateTime = endDateTime,
                                       bbox = bbox, 
                                       fmisid = fmisid)
        
        private$request$setParameters(request = "getFeature",
                                      storedquery_id = "fmi::observations::weather::daily::timevaluepair",
                                      starttime = p$startDateTime,
                                      endtime = p$endDateTime,
                                      bbox = p$bbox,
                                      fmisid = p$fmisid,
                                      parameters = paste(variables, collapse = ","))
      }
      
      sf_data <- self$getLayer(layer = "PointTimeSeriesObservation")
      # Add (recycled) variables as a new column
      sf_data$measurement <- variables
      
      # Split a StringList column into separate columns
      sf_data <- cbind(sf_data, do.call(rbind, sf_data$name))
      
      # Format data frame
      sf_data <- sf_data %>% 
        # Rename columns
        dplyr::rename(type = value,
                      value = result.MeasurementTimeseries.point.MeasurementTVP.value,
                      begin_position = beginPosition,
                      end_position = endPosition,
                      time_position = timePosition,
                      sub_region = X1,
                      # FIXME: No idea what these columns actually are...
                      unknown_a = X2,
                      unknown_b = X3) %>%
        # Reorder columns
        dplyr::select(gml_id, identifier, begin_position, end_position,
                      time_position, time, region, sub_region, unknown_a,
                      unknown_b, type, measurement, value) %>% 
        # Modify/transform columns
        dplyr::mutate(value = as.numeric(value)) %>% 
        # Replace NaNs with NAs
        dplyr::mutate(value = ifelse(is.nan(value), NA, value))
      # Times are reported only for the first measurement, but are the same for
      # all measuremetns. Expand values.
      # FIXME: check that this really is the case for different time periods.
      sf_data$begin_position <- sf_data[1, ]$begin_position
      sf_data$end_position <- sf_data[1, ]$end_position
      sf_data$time_position <- sf_data[1, ]$time_position
      
      # sub_region starts with region, remove that
      sf_data$sub_region <- apply(sf_data, 1, function(x) {
        gsub(paste0(x$region, " "), "", x$sub_region)
      })

      return(sf_data)
    },
    
    getLightningStrikes = function(startDateTime, endDateTime, bbox, 
                                   parameters = c("multiplicity", 
                                                  "peak_current",
                                                  "cloud_indicator", 
                                                  "ellipse_major")) {      
      if (inherits(private$request, "FMIWFSRequest")) {
        
        if (missing(startDateTime) | missing(endDateTime)) {
          stop("Arguments 'startDateTime' and 'endDateTime' must be provided.")
        }
        if (difftime(endDateTime, startDateTime, units = "hours") > 168) {
          stop("Too long time interval ", startDateTime, " to ", endDateTime, 
               " specified (no more than 168 hours allowed)")
        }
        if (is.null(bbox)) {
          stop("Argument 'bbox' must be provided.")
        }
        
        p <- private$processParameters(startDateTime = startDateTime, 
                                       endDateTime = endDateTime,
                                       bbox = bbox)
        
        private$request$setParameters(request = "getFeature",
                                      storedquery_id = "fmi::observations::lightning::simple",
                                      starttime = p$startDateTime,
                                      endtime = p$endDateTime,
                                      bbox = p$bbox,
                                      fmisid = p$fmisid,
                                      parameters = paste(parameters, 
                                                         collapse = ","))
      }
      
      response <- self$getLayer(layer = "BsWfsElement", 
                                crs = "+proj=longlat +datum=WGS84",
                                swapAxisOrder = TRUE, 
                                parameters = list(splitListFields = TRUE))
      if (is.character(response)) { 
        return(character())
      }
      
      response <- LongToWideFormat(response)
      
      return(response)
    },
    
    getMonthlyWeatherRaster = function(startDateTime, endDateTime, bbox = NULL) {
      if (inherits(private$request, "FMIWFSRequest")) {
        if (missing(startDateTime) | missing(endDateTime)) {
          stop("Arguments 'startDateTime' and 'endDateTime' must be provided.")
        }
        
        p <- private$processParameters(startDateTime = startDateTime, 
                                       endDateTime = endDateTime,
                                       bbox = bbox)
        private$request$setParameters(request = "getFeature",
                                      storedquery_id = "fmi::observations::weather::monthly::grid",
                                      starttime = p$startDateTime,
                                      endtime = p$endDateTime,
                                      bbox = p$bbox)
      }
      
      response <- self$getRaster(parameters = list(splitListFields = TRUE))
      if (is.character(response)) { 
        return(character())
      }
      NAvalue(response) <- 9999
      names(response) <- getRasterLayerNames(startDateTime = startDateTime,
                                             endDateTime = endDateTime,
                                             by = "month",
                                             variables = c("MeanTemperature", "Precipitation"))
      return(response)
    }
  )
)
