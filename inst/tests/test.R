library(fmi)

# In order to run the tests, save your API key to this file first.
apiKey <- readLines("inst/tests/apikey.txt")

# Download and read time-value-pair data (manual request)
request <- FMIWFSRequest(apiKey=apiKey)
request$setParameters(request="getFeature",
                      storedquery_id="fmi::observations::weather::daily::timevaluepair",
                      starttime="2014-01-01T00:00:00Z",
                      endtime="2014-01-01T00:00:00Z",
                      bbox="19.09,59.3,31.59,70.13",
                      parameters="rrday,snow,tday,tmin,tmax")
client <- FMIWFSClient()
layers <- client$listLayers(request=request)
response <- client$getLayer(request=request, layer=layers[1], crs="+proj=longlat +datum=WGS84", swapAxisOrder=TRUE, parameters=list(splitListFields=TRUE))
x <- client$transformTimeValuePairData(response=response, variableColumnNames=c("rrday","snow","tday","tmin","tmax"))

# Download and read time-value-pair data (automated request)
request <- FMIWFSRequest(apiKey=apiKey)
client <- FMIWFSClient()
response <- client$getDailyWeather(request=request, startDateTime=as.POSIXlt("2014-01-01"), endDateTime=as.POSIXlt("2014-01-01"))
plot(response)

# Download and read grib (manual request)
request <- FMIWFSRequest(apiKey=apiKey)
request$setParameters(request="getFeature",
                      storedquery_id="fmi::observations::weather::monthly::grid",
                      starttime="2012-01-01T00:00:00Z",
                      endtime="2012-02-02T00:00:00Z")
client <- FMIWFSClient()
response <- client$getRaster(request=request, parameters=list(splitListFields=TRUE))

# Stream client not supported ATM
client <- WFSStreamClient()
meta <- client$getLayer(request=request, layer="wfsns001:PointTimeSeriesObservation")

# Download and read grib (automated request)
request <- FMIWFSRequest(apiKey=apiKey)
client <- FMIWFSClient()
#response <- client$getMonthlyWeatherGrid(request, startDateTime=as.POSIXlt("2012-01-01"), endDateTime=as.POSIXlt("2012-02-02"))
response <- client$getMonthlyWeatherGrid(request, startDateTime="2012-01-01", endDateTime="2012-02-02")


# Download and read time-value-pair data with the redundant multipoint feature (manual request)
request <- FMIWFSRequest(apiKey=apiKey)
request$setParameters(request="getFeature",
                      storedquery_id="fmi::forecast::hirlam::surface::cities::timevaluepair",
                      starttime="2014-08-08T00:00:00Z",
                      endtime="2014-08-08T00:00:00Z",
                      bbox="19.09,59.3,31.59,70.13")
client <- FMIWFSClient()
layers <- client$listLayers(request=request)
# This fails
response <- client$getLayer(request=request, layer=layers[1], crs="+proj=longlat +datum=WGS84", swapAxisOrder=TRUE)
# This is ok, but needs ogr2ogr
response <- client$getLayer(request=request, layer=layers[1], crs="+proj=longlat +datum=WGS84", swapAxisOrder=TRUE, parameters=list(splitListFields=TRUE, explodeCollections=TRUE))

# TODO: handle empty responses
# TODO: handle download.file errors. sometimes download fails in the middle, but no error is returned
# TODO: clear cache on error
