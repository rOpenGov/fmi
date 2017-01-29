# This file is a part of the fmi package (http://github.com/rOpenGov/fmi)
# in association with the rOpenGov project (ropengov.github.io)

# Copyright (C) 2016 Joona Lehtomaki. 
# All rights reserved.

# This program is open source software; you can redistribute it and/or modify 
# it under the terms of the FreeBSD License (keep this notice): 
# http://en.wikipedia.org/wiki/BSD_licenses

# This program is distributed in the hope that it will be useful, 
# but WITHOUT ANY WARRANTY; without even the implied warranty of 
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

# Create a session environment
.session <- new.env()

check_session <- function() {
  if (!exists(".session", mode = "environment")) {
    stop("No session initialized, see init_session()")
  }
}
#' Initialize a API session.
#' 
#' Creates a new session based on a provided API key. Function creates a new
#' \code{\link{FMIWFSClient}} object and assigns it to a environment called
#' \code{client}.
#' 
#' @seealso \code{\link[rwfs]{WFSClient}}, \code{\link[rwfs]{WFSCachingClient}}
#' 
#' @param apikey Character string valid key for the FMI API.
#' 
#' @author Joona Lehtomaki  \email{joona.lehtomaki@gmail.com}
#' @examples # See the vignette.
#' @export
#' 
init_session <- function(apikey) {
  client <- FMIWFSClient$new(
    FMIWFSRequest$new(apiKey = apikey)
  )
  assign("client", client, envir = .session)
}