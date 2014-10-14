#' A class to build WFS request URL to the FMI API.
#'
#' @import R6
#' @references See citation("fmi")
#' @author Jussi Jousimo \email{jvj@@iki.fi}
#' @exportClass FMIWFSRequest
#' @examples \dontrun{request <- FMIWFSRequest(apiKey=apiKey)}
#' @export FMIWFSRequest
FMIWFSRequest <- R6::R6Class(
  "FMIWFSRequest",
  inherit = rwfs::WFSRequest,
  private = list(
    apiKey = NA
  ),
  public = list(
    initialize = function(apiKey) {
      if (missing(apiKey))
        stop("Must specify the 'apiKey' parameter.")
      private$apiKey <- apiKey
    },
    
    getURL = function(operation) {
      url <- paste0("http://data.fmi.fi/fmi-apikey/", private$apiKey, "/wfs?", self$getParametersString())
      return(url)
    }
  )
)
