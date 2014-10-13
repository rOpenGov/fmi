#' Get all active FMI weather stations.
#' 
#' Table of active weather stations has been manually copied from FMI web 
#' pages and is not fetched over the API. Table is provided as a csv file
#' within \code{fmi} package. 
#'
#' @return dataframe of active weather stations
#' 
#' @seealso \url{http://ilmatieteenlaitos.fi/havaintoasemat?p_p_id=stationlistingportlet_WAR_fmiwwwweatherportlets&p_p_lifecycle=0&p_p_state=normal&p_p_mode=view&p_p_col_id=column-4&p_p_col_count=1&_stationlistingportlet_WAR_fmiwwwweatherportlets_stationGroup=WEATHER}
#' 
#' @author Joona Lehtomaki \email{joona.lehtomaki@@gmail.com}
#' @export
#'
fmi_weather_stations <- function() {
  csv.file <- system.file("extdata", "weather_stations.csv", package="fmi")
  weather.stations <- read.table(csv.file, sep=";", header=TRUE, as.is=TRUE)
  return(weather.stations)
}  

#' Check if a provided ID number is a valid FMI SID.
#'
#' \code{fmisid} is a ID numbering system used by the FMI. 
#'
#' @param fmisid numeric or character ID number.
#'
#' @return logical
#' 
#' @seealso \code{\link{fmi_weather_stations}}
#' 
#' @author Joona Lehtomaki \email{joona.lehtomaki@@gmail.com}
#' @export
#'
valid_fmisid <- function(fmisid) {
  fmisid <- as.numeric(fmisid)
  weather.stations <- fmi_weather_stations()
  if (fmisid %in% weather.stations$FMISID) {
    return(TRUE)
  } else {
    return(FALSE)
  }
}