#' @title A class to build WFS request URL to the FMI API
#' 
#' @description TBA
#' 
#' @seealso \code{\link[rwfs]{WFSRequest}}, \code{\link[rwfs]{WFSCachingRequest}}
#' @import R6
#' @references See citation("fmi")
#' @author Jussi Jousimo \email{jvj@@iki.fi}
#' @exportClass FMIWFSRequest
#' @examples \dontrun{request <- FMIWFSRequest$new(apiKey=apiKey)}
#' @export FMIWFSRequest
FMIWFSRequest <- R6::R6Class(
  "FMIWFSRequest",
  inherit = rwfs::WFSCachingRequest,
  private = list(
    apiKey = NA,
    
    getURL = function() {
      url <- paste0("http://data.fmi.fi/fmi-apikey/", private$apiKey, "/wfs?", private$getParametersString())
      return(url)
    }
  ),
  public = list(
    initialize = function(apiKey) {
      if (missing(apiKey))
        stop("Must specify the 'apiKey' parameter.")
      private$apiKey <- apiKey
    }    
  )
)
