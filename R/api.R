#' @title FMI Lightnings Data
#' @description Get data on lightning strikes within a given time frame.
#'
#' @details Thin wrapper around \code{FMIWFSClient$getLightningStrikes()}.
#' Accessing  the \code{FMIWFSClient} is done through the \code{.session}
#' environment and the associated functions.
#' 
#' @seealso \code{\link{FMIWFSClient}}
#'
#' @param start Character start date "YYYY-MM-DD" for the query.
#' @param end Character end date "YYYY-MM-DD" for the query.
#' @param bbox Extent object defining the bounding box for the query.
#' @param crs CRS object used to project the results from EPSG:4326 (optional).
#'
#' @return SpatialPointsDataFrame object. The attribute table of the returned
#'   object contain the following fields:
#' 
#' \itemize{
#'   \item \code{cloud_indicator}: is the lighting a ground (0) or cloud (1)
#'     lightning?
#'   \item \code{ellipse_major}: ???
#'   \item \code{multiplicity}: ???
#'   \item \code{peak_current}: ???
#' }
#' 
#' @export
#' 
fmi_lightnings <- function(start, end, bbox, crs=NULL) {
  check_session()
  
  # Pass arguments on to the client
  response <- .session$client$getLightningStrikes(start, end, bbox)
  
  # If a CRS argument is provided, a transformation is requested
  if (!is.null(crs)) {
    response <- spTransform(response, crs)
  }
  
  return(response)
}