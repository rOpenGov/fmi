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