---
title: "fmi basics"
output: rmarkdown::html_vignette
vignette: >
  %\VignetteEngine{knitr::rmarkdown}
  %\VignetteIndexEntry{Vignette Title}
  %\VignetteEncoding{UTF-8}
---





Finnish Meteorological Institute (FMI) open data API client for R
===========

This R package (fmi) provides a client to access the [Finnish Meteorological Institute](http://en.ilmatieteenlaitos.fi/)
 (Ilmatieteenlaitos) [open data](http://en.ilmatieteenlaitos.fi/open-data).
This R package is a part of the [rOpenGov](http://ropengov.github.io) project.

## Installation

### Libraries

The fmi package depends on the [GDAL](http://www.gdal.org/) library and its 
[command line tools](http://www.gdal.org/ogr2ogr.html), and on `rgdal` package. 
If you have GDAL already installed, you might need to update it to newer 
version. Also, add the command line tools to the search path of your system. 
Below you can find some instructions on how to do these tasks on different 
platforms.

For `rgdal` package, please, see additional installation instructions in the
[gisfin package tutorial](https://github.com/rOpenGov/gisfin/blob/master/vignettes/gisfin_tutorial.md).

#### Linux

__Installing GDAL:__

Install `gdal` / `gdal-devel` packages using your Linux distibution's package 
manager. See [here](https://trac.osgeo.org/gdal/wiki/DownloadingGdalBinaries) on 
some pointers on where to find suitable binaries.

__Adding GDAL command line tools to your path__

In Linux, the tools should be found from the path by default after installation.
If not, use the `export` command from terminal, for example:
```
export PATH=$PATH:/usr/local/gdal/bin
```

#### OS X

__Installing GDAL:__

See [here](http://www.kyngchaos.com/software/frameworks).

__Adding GDAL command line tools to your path__

From terminal, type:
```
export PATH=$PATH:/Library/Frameworks/GDAL.framework/Programs
```

#### Windows

__Installing GDAL:__

For installing GDAL the easy way see  http://trac.osgeo.org/osgeo4w/. 

__Adding GDAL command line tools to your path__

Open System from Control Panel and select "Advanced System Settings".
Click "Environment Variables" and select "Path" variable from the list (if you 
cannot edit, you do not have the rights).

Append `;C:\Program Files (x86)\GDAL` to the value field (note the semicolon).

If you're using the OSGeo4W-installer, then you may have copy-paste semicolon 
followed by the path to GDAL __and__ the path to "gdal19.dll" e.g.

`;C:\Program Files\ms4w\tools\gdal-ogr\;C:\Program Files\ms4w\Apache\cgi-bin\`

#### ogr2ogr

Note that the actual location of GDAL may vary depending on your system. To 
test that the tools are found from the path, type the command in terminal 
(Command Prompt in Windows):

```
ogr2ogr
```
To test that you also have a recent version of GDAL:
```
ogr2ogr --help
```
You should see the options `-splitlistfields` and `-explodecollections` in the 
printed help. If not, you need to update GDAL.

### Packages

Start R and follow these steps to install the required packages:

```r
install.packages(c("devtools", "sp", "rgdal", "raster"))
library(devtools)
install_github("rOpenGov/rwfs")
```
Note that rgdal version 0.9-1 or newer is needed.
Then install the fmi package itself:

```r
install_github("rOpenGov/fmi")
```

## API key

In order to use the FMI API, you need to obtain a personal API key first.
To get the key, follow the instructions at <https://ilmatieteenlaitos.fi/rekisteroityminen-avoimen-datan-kayttajaksi>
(appears to be available only in Finnish). Enter the API key from command line:


```r
apiKey <- "ENTER YOUR API KEY HERE"
#apiKey <- readLines("apikey.txt") # Or store the key in private file
```

## Available data sets and filtering

FMI provides a brief introduction to the data sets at <http://en.ilmatieteenlaitos.fi/open-data-sets-available>.
A complete list of the available data sets and filtering parameters are described in
<http://en.ilmatieteenlaitos.fi/open-data-manual-fmi-wfs-services>.
Each data set is referenced with a stored query id, for example the id for the daily weather time series
is `fmi::observations::weather::daily::timevaluepair`. This data set contains variables for
daily precipitation rate, mean temperature, snow depth, and minimum and maximum temperature,
see the description of [`fmi::observations::weather::daily::multipointcoverage`](http://en.ilmatieteenlaitos.fi/open-data-manual-fmi-wfs-services).


```r
library(fmi)
request <- FMIWFSRequest$new(apiKey = apiKey)
```

The fmi package provides two types of queries: a manual one for direct access to the FMI API and
an automated one for a convenient access obtaining the data sets.

In the manual case, stored query id and filter parameters are given with the `setParameters` method:


```r
request$setParameters(request = "getFeature",
                      storedquery_id = "fmi::observations::weather::daily::timevaluepair",
                      starttime = "2014-01-01T00:00:00Z",
                      endtime = "2014-01-01T00:00:00Z",
                      bbox = "19.09,59.3,31.59,70.13",
                      parameters = "rrday,snow,tday,tmin,tmax")
```

The parameter `request="getFeature"` must be specified always.

For the automated case, see below.

### Client object

Queries to the FMI API are made by using the `FMIWFSClient` class object. For example, a manual request is dispatched with (continued from the previous example):


```r
client <- FMIWFSClient$new(request=request)
layers <- client$listLayers()
response <- client$getLayer(layer=layers[1], parameters=list(splitListFields=TRUE))
```

This example retrieves a list of data layers and the first layer is used to obtain the actual data. In fact, there is
only single layer.

For the same stored query, an automated request method, `getDailyWeather`, exists as well, which is a more
convenient way to retrieve the data. For example, to get all weather observations for the 1st of January in 2014:


```r
request <- FMIWFSRequest$new(apiKey=apiKey)
client <- FMIWFSClient$new(request=request)
response <- client$getDailyWeather(startDateTime="2014-01-01", endDateTime="2014-01-01", bbox=getFinlandBBox())
```

Here the function `getFinlandBBox` returns the bounding box surrounding the whole Finland.
See the package documentation in R for all available automated queries. Currently, the package supports only
a few data sets, which can be obtained using an automated query method. The rest of the stored queries are
available with the generic method `getLayer`.

As rgdal does not currently support direct queries to the FMI API, the client saves the response
to an intermedidate file first and then lets GDAL and rgdal to parse it. The `FMIWFSClient` class provides
a caching mechanism, so that the response is needed to be downloaded only once for the same subsequent queries.
The response file can be saved to a permanent location with the method `saveGMLFile` and loaded up into a
`FMIWFSClient` object again by referencing the file via a `GMLFile` object. GML files saved from the FMI API
directly can be loaded as well.

### Supported data and metadata

The fmi package supports time-value-pair and GRIB data formats. Multipoint-coverage format is not currently supported.
However, most of the multipoint-coverage data sets are availables in the time-value-pair format as well.

The automated queries attempt to associate appropriate metadata with the obtained data. The generic method `getLayer`
ignores the metadata and therefore it is left to the user to handle the metadata.
In case there is no documentation available, the metadata - or some of it - can be found from the actual XML
response retrieved from the FMI API. The XML response can be browsed by entering the query URL to a browser
or saving the response to a file first and then viewing it. A query URL can be printed from the request object
directly:


```r
request
```

For manual requests, coordinate reference system (if needed) must be specified manually by providing the `crs` argument
as a character string for the `getLayer` method. The default CRS appears to be WGS84. Furthermore, longitude and latitude
coordinates may need to be swapped, which can be done with the argument `swapAxisOrder=TRUE`. For example:


```r
response <- client$getLayer(layer="PointTimeSeriesObservation", crs="+proj=longlat +datum=WGS84", swapAxisOrder=TRUE, parameters=list(splitListFields=TRUE))
```

The last parameter `splitListFields=TRUE` asks the `ogr2ogr` tool bundled with the GDAL library
to convert the list fields to separate fields, so that rgdal can read the data properly.

### Redundant features

Some of the responses contain a redundant multipoint feature, which rgdal does not handle.
A workaround is to remove the feature using `ogr2ogr`.

In such case, `explodeCollections=TRUE` needs to be specified for the `getLayer` method, for example:


```r
response <- client$getLayer(layer="PointTimeSeriesObservation", parameters=list(explodeCollections=TRUE))
```

### Saving data and reading from file

Unprocessed data can be saved to a file with the `saveGMLFile` method and later processed by referencing
the file using a `GMLFile` object:


```r
request <- FMIWFSRequest$new(apiKey=apiKey)
client <- FMIWFSClient$new(request=request)
response <- client$getDailyWeather(startDateTime="2014-01-01", endDateTime="2014-01-02", bbox=getFinlandBBox())
tempFile <- tempfile()
client$saveGMLFile(destFile=tempFile)

request <- rwfs::GMLFile$new(tempFile)
client <- FMIWFSClient$new(request=request)
response <- client$getDailyWeather()
```

### Error handling

TODO

## Examples

### Manual request

Load the library:

```r
library(fmi)
```

Enter your API key for the examples:


```r
apiKey <- "ENTER YOUR API KEY HERE"
```

Construct a request object for the manual query:


```r
request <- FMIWFSRequest$new(apiKey = apiKey)
request$setParameters(request = "getFeature",
                      storedquery_id = "fmi::observations::weather::daily::timevaluepair",
                      starttime = "2014-01-01",
                      endtime = "2014-01-02",
                      bbox = "19.09,59.3,31.59,70.13",
                      parameters = "rrday,snow,tday,tmin,tmax")
```

The time parameters can be provided as objects that can be converted to the `POSIXlt` objects and
bbox as an `extent` object from the [`raster`](http://cran.r-project.org/web/packages/raster/index.html)
package as well.

Set up a client object and list the layers in the response:


```r
client <- FMIWFSClient$new(request = request)
layers <- client$listLayers()
```

```r
layers
```

```
## [1] "PointTimeSeriesObservation"
## attr(,"driver")
## [1] "GML"
## attr(,"nlayers")
## [1] 1
```

Parse the data from the response, which has been cached:


```r
response <- client$getLayer(layer = layers[1], crs = "+proj=longlat +datum=WGS84", 
                            swapAxisOrder = TRUE, parameters = list(splitListFields = TRUE))
```

```r
library(sp)
head(cbind(coordinates(response), response@data[,c("name1","time1","result.MeasurementTimeseries.point.MeasurementTVP.value1","time2","result.MeasurementTimeseries.point.MeasurementTVP.value2")]))
```

```
##   coords.x2 coords.x1                           name1                time1
## 1  60.12467  19.90362 Jomala Maarianhamina lentoasema 2014-01-01T00:00:00Z
## 2  60.12467  19.90362 Jomala Maarianhamina lentoasema 2014-01-01T00:00:00Z
## 3  60.12467  19.90362 Jomala Maarianhamina lentoasema 2014-01-01T00:00:00Z
## 4  60.12467  19.90362 Jomala Maarianhamina lentoasema 2014-01-01T00:00:00Z
## 5  60.12467  19.90362 Jomala Maarianhamina lentoasema 2014-01-01T00:00:00Z
## 6  59.77909  21.37479                    Parainen Utö 2014-01-01T00:00:00Z
##   result.MeasurementTimeseries.point.MeasurementTVP.value1
## 1                                                      NaN
## 2                                                      NaN
## 3                                                      3.6
## 4                                                      2.8
## 5                                                      4.5
## 6                                                      0.3
##                  time2
## 1 2014-01-02T00:00:00Z
## 2 2014-01-02T00:00:00Z
## 3 2014-01-02T00:00:00Z
## 4 2014-01-02T00:00:00Z
## 5 2014-01-02T00:00:00Z
## 6 2014-01-02T00:00:00Z
##   result.MeasurementTimeseries.point.MeasurementTVP.value2
## 1                                                      NaN
## 2                                                      NaN
## 3                                                      3.8
## 4                                                      3.3
## 5                                                      4.3
## 6                                                     -1.0
```

The data is returned as a `SpatialPointsDataFrame` object in "wide" format so that there is a row for each
variable and observation location, but for each day (two days here) there are columns for time and observation
indexed with a sequential number. The columns starting with `time` contains the time and the columns
`result_MeasurementTimeseries_point_MeasurementTVP_value` the measurements, which are organized so that
the variables `rrday, snow, tday, tmin, tmax` are repeated in the same order as specified in the request. 

### Automated request

The method `getDailyWeather` provides an automated query for the daily weather time series:


```r
request <- FMIWFSRequest$new(apiKey = apiKey)
client <- FMIWFSClient$new(request = request)
response <- client$getDailyWeather(startDateTime = "2014-01-01", endDateTime = "2014-01-02", 
                                   bbox = getFinlandBBox())
```

```r
head(cbind(coordinates(response), response@data[,c("name1","time","variable","measurement")]))
```

```
##   coords.x2 coords.x1                           name1       time variable
## 1  60.12467  19.90362 Jomala Maarianhamina lentoasema 2014-01-01    rrday
## 2  60.12467  19.90362 Jomala Maarianhamina lentoasema 2014-01-01     snow
## 3  60.12467  19.90362 Jomala Maarianhamina lentoasema 2014-01-01     tday
## 4  60.12467  19.90362 Jomala Maarianhamina lentoasema 2014-01-01     tmin
## 5  60.12467  19.90362 Jomala Maarianhamina lentoasema 2014-01-01     tmax
## 6  59.77909  21.37479                    Parainen Utö 2014-01-01    rrday
##   measurement
## 1         NaN
## 2         NaN
## 3         3.6
## 4         2.8
## 5         4.5
## 6         0.3
```
<<<<<<< HEAD

The automated method sets the known parameters automatically and returns cleaner result
by combining the data with metadata data and converting the "wide" format to long format.

### Raster

To request continuous space data manually, use the `getRaster` method, for instance:


```r
library(raster)
request <- FMIWFSRequest$new(apiKey = apiKey)
request$setParameters(request = "getFeature",
                      storedquery_id = "fmi::observations::weather::monthly::grid",
                      starttime = "2012-01-01",
                      endtime = "2012-01-01")
client <- FMIWFSClient$new(request = request)
response <- client$getRaster(parameters = list(splitListFields = TRUE))
```

The response is returned as a `RasterBrick` object of the `raster` package:


```r
response
```

```
## class       : RasterBrick 
## dimensions  : 1165, 1901, 2214665, 2  (nrow, ncol, ncell, nlayers)
## resolution  : 0.008996004, 0.008993221  (x, y)
## extent      : 15.96441, 33.06581, 59.60727, 70.08437  (xmin, xmax, ymin, ymax)
## coord. ref. : +proj=longlat +a=6371229 +b=6371229 +no_defs 
## data source : /tmp/RtmplB2Yey/file357a4821282d 
## names       : file357a4821282d.1, file357a4821282d.2
```

Set the NA value and plot the interpolated monthly mean temperature in January 2012:


```r
NAvalue(response) <- 9999
plot(response[[1]])
```

![plot of chunk request-raster-plot](figure/request-raster-plot-1.png)

There is also the automated request method `getMonthlyWeatherRaster` for obtaining monthly weather data:


```r
request <- FMIWFSRequest$new(apiKey = apiKey)
client <- FMIWFSClient$new(request = request)
response <- client$getMonthlyWeatherRaster(startDateTime = "2012-01-01", endDateTime = "2012-02-01")
```

The method sets the raster band names to match the variable name and the dates:


```r
names(response)
```

```
## [1] "MeanTemperature.2012.01.01" "MeanTemperature.2012.02.01"
## [3] "Precipitation.2012.01.01"   "Precipitation.2012.02.01"
```

## Licensing and further information

For the open data license, see <http://en.ilmatieteenlaitos.fi/open-data-licence>. Further information about
the open data and the API is provided by the FMI at <http://en.ilmatieteenlaitos.fi/open-data>.

## Citing the R package

This work can be freely used, modified and distributed under the
[Two-clause FreeBSD license](http://en.wikipedia.org/wiki/BSD\_licenses). Kindly cite the
R package as 'Jussi Jousimo et al. (C) 2014. fmi R package. URL: http://www.github.com/rOpenGov/fmi'.

## Session info

This tutorial was created with


```
## R version 3.3.2 (2016-10-31)
## Platform: x86_64-suse-linux-gnu (64-bit)
## Running under: openSUSE Tumbleweed
## 
## locale:
##  [1] LC_CTYPE=en_US.UTF-8       LC_NUMERIC=C              
##  [3] LC_TIME=C                  LC_COLLATE=fi_FI.UTF-8    
##  [5] LC_MONETARY=fi_FI.UTF-8    LC_MESSAGES=en_US.UTF-8   
##  [7] LC_PAPER=en_US.UTF-8       LC_NAME=C                 
##  [9] LC_ADDRESS=C               LC_TELEPHONE=C            
## [11] LC_MEASUREMENT=fi_FI.UTF-8 LC_IDENTIFICATION=C       
## 
## attached base packages:
## [1] stats     graphics  grDevices utils     datasets  methods   base     
## 
## other attached packages:
## [1] raster_2.5-8    sp_1.2-4        fmi_0.2.0       R6_2.2.0       
## [5] knitr_1.15.1    testthat_1.0.2  devtools_1.12.0
## 
## loaded via a namespace (and not attached):
##  [1] Rcpp_0.12.9     rwfs_0.2.0      lattice_0.20-34 digest_0.6.11  
##  [5] crayon_1.3.2    withr_1.0.2     rprojroot_1.2   grid_3.3.2     
##  [9] backports_1.0.5 magrittr_1.5    evaluate_0.10   highr_0.6      
## [13] stringi_1.1.2   rmarkdown_1.3   rgdal_1.2-5     tools_3.3.2    
## [17] stringr_1.1.0   rsconnect_0.7   yaml_2.1.14     memoise_1.0.0  
## [21] htmltools_0.3.5
```
