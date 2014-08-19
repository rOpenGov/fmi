# This file is a part of the helsinki package (http://github.com/rOpenGov/helsinki)
# in association with the rOpenGov project (ropengov.github.io)

# Copyright (C) 2014 Jussi Jousimo / Louhos <louhos.github.com>. 
# All rights reserved.

# This program is open source software; you can redistribute it and/or modify 
# it under the terms of the FreeBSD License (keep this notice): 
# http://en.wikipedia.org/wiki/BSD_licenses

# This program is distributed in the hope that it will be useful, 
# but WITHOUT ANY WARRANTY; without even the implied warranty of 
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

#' Converts an object which can be converted to a POSIXlt object to a ISO8601 date time string.
asISO8601 <- function(dt) return(strftime(dt, "%Y-%d-%mT%H:%M:%SZ"))

#' An abstract class to build WFS request URL's.
#'
#' @import methods
#' @references See citation("fmi")
#' @author Jussi Jousimo \email{louhos@@googlegroups.com}
#' @exportClass WFSRequest
#' @export WFSRequest
WFSRequest <- setRefClass(
  "WFSRequest",
  fields = list(
    parameters = "list"
  ),
  methods = list(
    setParameters = function(...) {
      parameters <<- list(...)
      return(invisible(.self))
    },
    
    getParametersString = function() {
      x <- lapply(seq_along(parameters), function(i) paste(names(parameters)[[i]], parameters[[i]], sep="="))
      p <- paste(x, collapse="&")
      return(p)
    },
    
    getBaseURL = function() {
      stop("Unimplemented method.")
    },
    
    getURL = function(operation) {
      baseURL <- getBaseURL()
      if (is.null(baseURL) || is.na(baseURL) || baseURL == "")
        stop("Base URL has not been specified in the request object.")
      return(paste0(baseURL, "?request=", operation, "&", getParametersString()))
    }
  )
)

#' An abstract class to make requests to a WFS.
#'
#' @import methods
#' @import rgdal
#' @references See citation("fmi")
#' @author Jussi Jousimo \email{louhos@@googlegroups.com}
#' @exportClass WFSClient
#' @export WFSClient
WFSClient <- setRefClass(
  "WFSClient",
  methods = list(
    .private.listLayers = function(dataSource) {
      if (missing(dataSource))
        stop("Required argument 'dataSource' missing.")
      if (!inherits(dataSource, "character"))
        stop("Argument 'dataSource' must be a descendant of class 'character'.")
      
      layers <- rgdal::ogrListLayers(dsn=dataSource)
      if (inherits(layers, "try-error") && length(grep("Cannot open data source", layers)) == 1) {
        stop("Error in query result. Invalid query?")
      }
      return(layers)
    },
    
    .private.getLayer = function(dataSource, layer, crs=NULL, swapAxisOrder=FALSE) {
      if (missing(dataSource))
        stop("Required argument 'dataSource' missing.")
      if (missing(layer))
        stop("Required argument 'layer' missing.")
      if (!inherits(dataSource, "character"))
        stop("Argument 'dataSource' must be a descendant of class 'character'.")
      response <- rgdal::readOGR(dsn=dataSource, layer=layer, p4s=crs, swapAxisOrder=swapAxisOrder, stringsAsFactors=FALSE)
      
      return(response)
    },
    
    listLayers = function(request) {
      stop("Unimplemented method.")
    },
    
    getLayer = function(request, layer, crs=NULL, swapAxisOrder=FALSE, parameters) {
      stop("Unimplemented method.")
    },
    
    getRaster = function(request, crs, NAvalue) {
      stop("Unimplemented method.")
    }
  )
)

#' A class to stream response from a WFS.
#'
#' @import methods
#' @import rgdal
#' @references See citation("fmi")
#' @author Jussi Jousimo \email{louhos@@googlegroups.com}
#' @exportClass WFSStreamClient
#' @export WFSStreamClient
WFSStreamClient <- setRefClass(
  "WFSStreamClient",
  contains = "WFSClient",
  methods = list(
    listLayers = function(request) {
      if (missing(request))
        stop("Required argument 'request' missing.")
      if (!inherits(request, "WFSRequest"))
        stop("Argument 'request' must be a descendant of class 'WFSRequest'.")
      
      dataSourceURL <- request$getURL("getFeature")
      layers <- .private.listLayers(dataSource=dataSourceURL)
      return(layers)
    },
    
    getLayer = function(request, layer, crs=NULL, swapAxisOrder=FALSE, parameters) {
      if (missing(request))
        stop("Required argument 'request' missing.")
      if (missing(layer))
        stop("Required argument 'layer' missing.")
      if (!inherits(request, "WFSRequest"))
        stop("Argument 'request' must be a descendant of class 'WFSRequest'.")
      
      dataSourceURL <- request$getURL("getFeature")
      response <- .private.getLayer(dataSource=dataSourceURL, layer=layer, crs=crs, swapAxisOrder=swapAxisOrder)
      return(response)
    }
  )
)

#' A class to cache response from a WFS to a file.
#'
#' @import methods
#' @import rgdal
#' @import raster
#' @references See citation("fmi")
#' @author Jussi Jousimo \email{louhos@@googlegroups.com}
#' @exportClass WFSFileClient
#' @export WFSFileClient
WFSFileClient <- setRefClass(
  "WFSFileClient",
  contains = "WFSClient",
  fields = list(
    cachedDataSourceURL = "character",
    cachedResponseFile = "character"
  ),
  methods = list(
    initialize = function(...) {
      callSuper(...)
      cachedDataSourceURL <<- ""
      cachedResponseFile <<- ""
    },
    
    saveGMLFile = function(destFile) {
      if (missing(destFile))
        stop("Required argument 'destFile' missing.")
      if (length(cachedResponseFile) == 0 || !file.exists(cachedResponseFile))
        stop("Response file missing. No query has been made?")
      file.copy(cachedResponseFile, destFile)
      return(invisible(.self))
    },
    
    loadGMLFile = function(fromFile) {
      if (missing(fromFile))
        stop("Required argument 'fromFile' missing.")
      if (!file.exists(fromFile))
        stop("File does not exist.")
      cachedResponseFile <<- fromFile
      return(invisible(.self))
    },
    
    cacheResponse = function(dataSourceURL) {
      if (missing(dataSourceURL))
        stop("Required argument 'dataSourceURL' missing.")
      if (!inherits(dataSourceURL, "character"))
        stop("Argument 'dataSourceURL' must be a descendant of class 'dataSourceURL'.")
      
      if (cachedDataSourceURL != dataSourceURL) {
        cachedDataSourceURL <<- dataSourceURL
        cachedResponseFile <<- tempfile()
        success <- download.file(dataSourceURL, cachedResponseFile, "internal")
        if (success != 0) {
          warning("Query failed.")
          return(character())
        }
      }
      return(invisible(.self))
    },
    
    convert = function(sourceFile, layer, parameters) {
      destFile <- tempfile()
      errorCode <- system(paste("ogr2ogr -f GML", parameters, destFile, cachedResponseFile, layer))
      if (errorCode != 0) {
        stop("Conversion failed.")
      }
      unlink(cachedResponseFile)
      cachedResponseFile <<- destFile
      return(invisible(.self))
    },
    
    listLayers = function(request) {
      if (!missing(request))
        cacheResponse(dataSource=request$getURL("getFeature"))
      else {
        if (cachedResponseFile == "")
          stop("Specify 'request' argument or load file with 'loadGLMFile'.")
      }
      layers <- .private.listLayers(dataSource=cachedResponseFile)
      return(layers)
    },
    
    getLayer = function(request, layer, crs=NULL, swapAxisOrder=FALSE, parameters) {
      if (!missing(request))
        cacheResponse(dataSourceURL=request$getURL("getFeature"))
      else {
        if (cachedResponseFile == "")
          stop("Specify 'request' argument or load file with 'loadGLMFile'.")        
      }
      if (!missing(parameters)) {
        ogr2ogrParams <- ""
        # Not needed for rgdal >= 0.9.1
        #if (!is.null(parameters$splitListFields) && parameters$splitListFields)
        #  ogr2ogrParams <- paste(ogr2ogrParams, "-splitlistfields")
        if (!is.null(parameters$explodeCollections) && parameters$explodeCollections)
          ogr2ogrParams <- paste(ogr2ogrParams, "-explodecollections")
        if (ogr2ogrParams != "")
          convert(layer=layer, parameters=ogr2ogrParams)
      }
      response <- .private.getLayer(dataSource=cachedResponseFile, layer=layer, crs=crs, swapAxisOrder=swapAxisOrder)
      return(response)
    }
  )
)
