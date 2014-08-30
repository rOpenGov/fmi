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

WFSRequest <- getFromNamespace("WFSRequest", "rwfs")
WFSFileClient <- getFromNamespace("WFSFileClient", "rwfs")

#' A class to build WFS request URL to the FMI API.
#'
#' @import methods
#' @references See citation("fmi")
#' @author Jussi Jousimo \email{jvj@@iki.fi}
#' @exportClass FMIWFSRequest
#' @export FMIWFSRequest
FMIWFSRequest <- setRefClass(
  "FMIWFSRequest",
  contains = "WFSRequest",
  fields = list(
    apiKey = "character"
  ),
  methods = list(
    getURL = function(operation) {
      if (length(apiKey) == 0)
        stop("Required field 'apiKey' has not been specified for the constructor.")
      url <- paste0("http://data.fmi.fi/fmi-apikey/", apiKey, "/wfs?", getParametersString())
      return(url)
    }
  )
)

#' A class to make requests to the FMI open data API.
#'
#' @import methods
#' @import raster
#' @references See citation("fmi")
#' @author Jussi Jousimo \email{jvj@@iki.fi}
#' @exportClass FMIWFSClient
#' @export FMIWFSClient
FMIWFSClient <- setRefClass(
  "FMIWFSClient",
  contains = c("WFSFileClient"),
  methods = list(
    getRasterURL = function(request, parameters) {
      layers <- listLayers(request=request)
      if (length(layers) == 0) return(character(0))
      
      meta <- getLayer(request=request, layer=layers[1], parameters=parameters)
      if (is.character(meta)) return(character(0))
      
      return(meta@data$fileReference)
    },
    
    transformTimeValuePairData = function(response, timeColumnName="time", measurementColumnName="result_MeasurementTimeseries_point_MeasurementTVP_value", variableColumnNames) {
      if (missing(response))
        stop("Required argument 'response' missing.")
      if (missing(variableColumnNames))
        stop("Required argument 'variableColumnNames' missing.")
      
      data <- response@data
      data <- transform(data,
                        time=data[,timeColumnName],
                        measurement=data[,measurementColumnName],
                        variable=rep(variableColumnNames, nrow(response) / length(variableColumnNames)))
      response@data <- data

      return(response)
    },
    
    getRasterLayerNames = function(startDateTime, endDateTime, by, variables) {
      dateSeq <- seq.Date(as.Date(startDateTime), as.Date(endDateTime), by=by)
      x <- expand.grid(date=dateSeq, measurement=variables)
      layerNames <- do.call(function(date, measurement) paste(measurement, date, sep="."), x)
      return(layerNames)
    },
    
    processParameters = function(startDateTime=NULL, endDateTime=NULL, bbox=NULL) {
      if (inherits(startDateTime, "POSIXt")) startDateTime <- asISO8601(startDateTime)
      if (inherits(endDateTime, "POSIXt")) endDateTime <- asISO8601(endDateTime)
      if (inherits(bbox, "Extent")) bbox <- with(attributes(bbox), paste(xmin, xmax, ymin, ymax, sep=","))
      return(list(startDateTime=startDateTime, endDateTime=endDateTime, bbox=bbox))
    },
    
    getDailyWeather = function(request, startDateTime, endDateTime, bbox=raster::extent(c(19.0900,59.3000,31.5900,70.130))) {
      if (missing(request))
        stop("Required argument 'request' missing.")
      if (missing(startDateTime))
        stop("Required argument 'startDateTime' missing.")
      if (missing(endDateTime))
        stop("Required argument 'endDateTime' missing.")
      
      p <- processParameters(startDateTime=startDateTime, endDateTime=endDateTime, bbox=bbox)
      request$setParameters(request="getFeature",
                            storedquery_id="fmi::observations::weather::daily::timevaluepair",
                            starttime=p$startDateTime,
                            endtime=p$endDateTime,
                            bbox=p$bbox,
                            parameters="rrday,snow,tday,tmin,tmax")
      response <- getLayer(request=request, layer="PointTimeSeriesObservation", crs="+proj=longlat +datum=WGS84", swapAxisOrder=TRUE, parameters=list(splitListFields=TRUE))
      if (is.character(response)) return(character())
      
      response <- transformTimeValuePairData(response=response, variableColumnNames=c("rrday","snow","tday","tmin","tmax"))
      # TODO: set name1 ... name3 column names
      
      return(response)
    },
    
    getMonthlyWeatherGrid = function(request, startDateTime, endDateTime) {
      if (missing(request))
        stop("Required argument 'request' missing.")
      if (missing(startDateTime))
        stop("Required argument 'startDateTime' missing.")
      if (missing(endDateTime))
        stop("Required argument 'endDateTime' missing.")
      
      p <- processParameters(startDateTime=startDateTime, endDateTime=endDateTime)
      request$setParameters(request="getFeature",
                            storedquery_id="fmi::observations::weather::monthly::grid",
                            starttime=p$startDateTime,
                            endtime=p$endDateTime)
      response <- getRaster(request=request, parameters=list(splitListFields=TRUE))
      if (is.character(response)) return(character())
      
      names(response) <- getRasterLayerNames(startDateTime=startDateTime,
                                             endDateTime=endDateTime,
                                             by="month",
                                             variables=c("MonthlyMeanTemperature", "MonthlyPrecipitation"))
      return(response)
    }
  )
)
