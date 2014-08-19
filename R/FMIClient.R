# This file is a part of the gisfin package (http://github.com/rOpenGov/gisfin)
# in association with the rOpenGov project (ropengov.github.io)

# Copyright (C) 2014 Jussi Jousimo / Louhos <louhos.github.com>. 
# All rights reserved.

# This program is open source software; you can redistribute it and/or modify 
# it under the terms of the FreeBSD License (keep this notice): 
# http://en.wikipedia.org/wiki/BSD_licenses

# This program is distributed in the hope that it will be useful, 
# but WITHOUT ANY WARRANTY; without even the implied warranty of 
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

#' @include WFSClient.R

#' A class to build WFS request URL to the FMI API.
#'
#' @import methods
#' @references See citation("fmi")
#' @author Jussi Jousimo \email{louhos@@googlegroups.com}
#' @exportClass FMIWFSRequest
#' @export FMIWFSRequest
FMIWFSRequest <- setRefClass(
  "FMIWFSRequest",
  contains = "WFSRequest",
  fields = list(
    apiKey = "character"
  ),
  methods = list(
    getBaseURL = function() {
      if (length(apiKey) == 0)
        stop("Required field 'apiKey' has not been specified.")
      baseURL <- paste0("http://data.fmi.fi/fmi-apikey/", apiKey, "/wfs")
      return(baseURL)
    }
  )
)

#' A class to make requests to the FMI open data API.
#'
#' @import methods
#' @references See citation("fmi")
#' @author Jussi Jousimo \email{louhos@@googlegroups.com}
#' @exportClass FMIWFSFileClient
#' @export FMIWFSFileClient
FMIWFSFileClient <- setRefClass(
  "FMIWFSFileClient",
  contains = c("WFSFileClient"),
  methods = list(
    getRaster = function(request, crs, NAvalue=9999) {
      layers <- listLayers(request=request)
      meta <- getLayer(request=request, layer=layers[1])
      if (is.character(meta)) return(character())
      
      destFile <- tempfile()
      success <- download.file(meta@data$fileReference, destfile=destFile)
      if (success != 0) {
        warning("Failed to download grib file.")
        return(character())
      }
      
      raster <- raster::brick(destFile)
      #raster <- shift(raster, x=-0.5*xres(raster), y=0.5*yres(raster)) # needed?
      raster::NAvalue(raster) <- NAvalue
      return(raster)
    },
    
    transformTimeValuePairData = function(response, timeColumnName="time", measurementColumnName="result.MeasurementTimeseries.point.MeasurementTVP.value", variableColumnNames) {
      if (missing(response))
        stop("Required argument 'response' missing.")
      
      data <- response@data
      data <- transform(data,
                        time=as.POSIXlt(data[,timeColumnName]),
                        measurement=data[,measurementColumnName],
                        variable=rep(variableColumnNames, nrow(response) / length(outputColumnNames)))
      response@data <- data
      return(response)
    },
    
    getLayerNames = function(startDateTime, endDateTime, by, variables) {
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
      request$setParameters(storedquery_id="fmi::observations::weather::daily::timevaluepair",
                            starttime=p$startDateTime,
                            endtime=p$endDateTime,
                            bbox=p$bbox,
                            parameters="rrday,snow,tday,tmin,tmax")
      response <- getLayer(request=request, layer="PointTimeSeriesObservation", crs="+proj=longlat +datum=WGS84", swapAxisOrder=TRUE, parameters=list(splitListFields=TRUE))
      if (is.character(response)) return(character())
      
      response <- transformTimeValuePairData(response=response, variableColumnNames=c("rrday","snow","tday","tmin","tmax"))
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
      request$setParameters(storedquery_id="fmi::observations::weather::monthly::grid",
                            starttime=p$startDateTime,
                            endtime=p$endDateTime)
      response <- getRaster(request=request)
      if (is.character(response)) return(character())
      
      names(response) <- getLayerNames(startDateTime=startDateTime,
                                       endDateTime=endDateTime,
                                       by="month",
                                       variables=c("MonthlyMeanTemperature", "MonthlyPrecipitation"))
      return(response)
    }
  )
)
