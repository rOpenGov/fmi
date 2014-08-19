library(fmi)

# In order to run the tests, save your API key to this file first.
apiKey <- readLines("inst/tests/apikey.txt")

# Download and read time-value-pair data (manual request)
request <- FMIWFSRequest(apiKey=apiKey)
request$setParameters(storedquery_id="fmi::observations::weather::daily::timevaluepair",
                      starttime="2014-01-01T00:00:00Z",
                      endtime="2014-01-01T00:00:00Z",
                      bbox="19.09,59.3,31.59,70.13",
                      parameters="rrday,snow,tday,tmin,tmax")
client <- FMIWFSFileClient()
layers <- client$listLayers(request=request)
response <- client$getLayer(request=request, layer=layers[1], crs="+proj=longlat +datum=WGS84", swapAxisOrder=TRUE)
x <- client$transformTimeValuePairData(response=response, variableColumnNames=c("rrday","snow","tday","tmin","tmax"))

# Download and read time-value-pair data (automated request)
request <- FMIWFSRequest(apiKey=apiKey)
client <- FMIWFSFileClient()
response <- client$getDailyWeather(request=request, startDateTime=as.POSIXlt("2014-01-01"), endDateTime=as.POSIXlt("2014-01-01"))
plot(response)

# Download and read grib (manual request)
request <- FMIWFSRequest(apiKey=apiKey)
request$setParameters(storedquery_id="fmi::observations::weather::monthly::grid",
                      starttime="2012-01-01T00:00:00Z",
                      endtime="2012-02-02T00:00:00Z")
client <- FMIWFSFileClient()
response <- client$getRaster(request=request)

# Download and read grib (automated request)
request <- FMIWFSRequest(apiKey=apiKey)
client <- FMIWFSFileClient()
response <- client$getMonthlyWeatherGrid(request, startDateTime=as.POSIXlt("2012-01-01"), endDateTime=as.POSIXlt("2012-02-02"))

# Download and read time-value-pair data with the redundant multipoint feature (manual request)
request <- FMIWFSRequest(apiKey=apiKey)
request$setParameters(storedquery_id="fmi::forecast::hirlam::surface::cities::timevaluepair",
                      starttime="2014-08-08T00:00:00Z",
                      endtime="2014-08-08T00:00:00Z",
                      bbox="19.09,59.3,31.59,70.13")
client <- FMIWFSFileClient()
layers <- client$listLayers(request=request)
# This fails
response <- client$getLayer(request=request, layer=layers[1], crs="+proj=longlat +datum=WGS84", swapAxisOrder=TRUE)
# This is ok, but needs ogr2ogr
response <- client$getLayer(request=request, layer=layers[1], crs="+proj=longlat +datum=WGS84", swapAxisOrder=TRUE, parameters=list(explodeCollections=TRUE))

# TODO: handle empty responses
# TODO: handle download.file errors
# TODO: clear cache on error
# TODO: test streaming client with stat.fi API
