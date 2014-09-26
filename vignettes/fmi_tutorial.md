

Finnish Meteorological Institute (FMI) open data API client for R
===========

This R package (fmi) provides a client to access the [Finnish Meteorological Institute](http://en.ilmatieteenlaitos.fi/)
 (Ilmatieteenlaitos) [open data](http://en.ilmatieteenlaitos.fi/open-data).
This R package is a part of the [rOpenGov](http://ropengov.github.io) project.

## Installation

### Libraries

The fmi package depends on the [GDAL](http://www.gdal.org/) library and its [command line tools](http://www.gdal.org/ogr2ogr.html).
Please, see the installation instructions in the [gisfin package tutorial](https://github.com/rOpenGov/gisfin/blob/master/vignettes/gisfin_tutorial.md)
to install GDAL. If you have GDAL already installed, you might need to update it to newer version.
Also, add the command line tools to the search path of your system as follows:

#### Linux

In Linux, the tools should be found from the path by default after installation.
If not, use the `export` command from terminal, for example:
```
export PATH=$PATH:/usr/local/gdal/bin
```

#### OS X

From terminal, type:
```
export PATH=$PATH:/Library/Frameworks/GDAL.framework/Programs
```

#### Windows

Open System from Control Panel and select "Advanced System Settings".
Click "Environment Variables" and select "Path" Variable from the list.
Append `;C:\Program Files (x86)\GDAL` to the value field (note the semicolon).

#### ogr2ogr

Note that the actual location of GDAL may vary depending on your system. To test that the tools are found from the path,
type the command in terminal (Command Prompt in Windows):
```
ogr2ogr
```
To test that you also have a recent version of GDAL:
```
ogr2ogr --help
```
You should see the options `-splitlistfields` and `-explodecollections` in the printed help.
If not, you need to update GDAL.

### Packages

Start R and follow these steps to install the required packages:

```r
install.packages(c("devtools", "rgdal"))
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
(appears to be available only in Finnish).
Enter the API key from command line:

```r
apiKey <- "ENTER YOUR API KEY HERE"
```

<!-- To run this vignette, save the API key to the vignette directory in the `apikey.txt` file first. -->


## Available data sets and filtering

FMI provides a brief introduction to the data sets at <http://en.ilmatieteenlaitos.fi/open-data-sets-available>.
A complete list of the available data sets and filtering parameters are described in
<http://en.ilmatieteenlaitos.fi/open-data-manual-fmi-wfs-services>.
Each data set is referenced with a stored query id, for example the id for the daily weather time series
is `fmi::observations::weather::daily::timevaluepair`. This data set contains variables for
daily precipitation rate, mean temperature, snow depth, and minimum and maximum temperature,
see the description of [`fmi::observations::weather::daily::multipointcoverage`](http://en.ilmatieteenlaitos.fi/open-data-manual-fmi-wfs-services).
The data can be filtered with a number of parameters specific to each data set.
For example, the starting and the ending dates are provided by the `starttime` and `endtime`
parameters for the weather observations.

## Usage

### Request object

Queries to the FMI API are specified using an object of the class `FMIWFSRequest`. To initialize the object, type:

```r
library(fmi)
request <- FMIWFSRequest(apiKey=apiKey)
```

The fmi package provides two types of queries: a manual one for direct access to the FMI API and
an automated one for a convenient access obtaining the data sets.

In the manual case, stored query id and filter parameters are given with the `setParameters` method:

```r
request$setParameters(request="getFeature",
                      storedquery_id="fmi::observations::weather::daily::timevaluepair",
                      starttime="2014-01-01T00:00:00Z",
                      endtime="2014-01-01T00:00:00Z",
                      bbox="19.09,59.3,31.59,70.13",
                      parameters="rrday,snow,tday,tmin,tmax")
```
The parameter `request="getFeature"` must be specified always.

For the automated case, see below.

### Client object

Queries to the FMI API are made by using the `FMIWFSClient` class object. For example, a manual request is dispatched with
(continued from the previous example):

```r
client <- FMIWFSClient()
layers <- client$listLayers(request=request)
response <- client$getLayer(request=request, layer=layers[1], parameters=list(splitListFields=TRUE))
```
This example retrieves a list of data layers and the first layer is used to obtain the actual data. In fact, there is
only single layer.

For the same stored query, an automated request method, `getDailyWeather`, exists as well, which is a more
convenient way to retrieve the data. For example, to get all weather observations for the 1st of January in 2014:

```r
request <- FMIWFSRequest(apiKey=apiKey)
client <- FMIWFSClient()
response <- client$getDailyWeather(request=request, startDateTime="2014-01-01", endDateTime="2014-01-01")
```
See the package documentation in R for all available automated queries. Currently, the package supports only
a few data sets, which can be obtained using an automated query method. The rest of the stored queries are
available with the generic method `getLayer`.

As rgdal does not currently support direct queries to the FMI API in most cases, the client saves the response
to an intermedidate file first and then lets GDAL and rgdal to parse it. The `FMIWFSClient` class provides
a caching mechanism, so that the response is needed to be downloaded only once for the same subsequent queries.
The response file can be saved to a permanent location with the method `saveGMLFile` and loaded up into a
`FMIWFSClient` object again with the `loadGMLFile` method.

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
response <- client$getLayer(request=request, layer="PointTimeSeriesObservation", crs="+proj=longlat +datum=WGS84", swapAxisOrder=TRUE, parameters=list(splitListFields=TRUE))
```

### Redundant features

Some of the responses may contain a redundant multipoint feature, which rgdal does not handle.
A workaround is to remove the feature using the `ogr2ogr` tool bundled with the GDAL library.
In such case, `explodeCollections=TRUE` needs to be specified for the `getLayer` method, for example:

```r
response <- client$getLayer(request=request, layer="PointTimeSeriesObservation", parameters=list(explodeCollections=TRUE))
```

### Continuous time measurements

TODO

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
request <- FMIWFSRequest(apiKey=apiKey)
request$setParameters(request="getFeature",
                      storedquery_id="fmi::observations::weather::daily::timevaluepair",
                      starttime="2014-01-01",
                      endtime="2014-01-01",
                      bbox="19.09,59.3,31.59,70.13",
                      parameters="rrday,snow,tday,tmin,tmax")
```
The time parameters can be provided as objects that can be converted to the `POSIXlt` objects and
bbox as an `extent` object from the [`raster`](http://cran.r-project.org/web/packages/raster/index.html)
package as well.

Set up a client object and list the layers in the response:

```r
client <- FMIWFSClient()
layers <- client$listLayers(request=request)
```

```r
layers
```

```
## [1] "PointTimeSeriesObservation" "Location"                  
## attr(,"driver")
## [1] "GML"
## attr(,"nlayers")
## [1] 2
```

Parse the data from the response, which has been cached:

```r
response <- client$getLayer(request=request, layer=layers[1], crs="+proj=longlat +datum=WGS84", swapAxisOrder=TRUE, parameters=list(splitListFields=TRUE))
```

```
## OGR data source with driver: GML 
## Source: "/tmp/user/1012574/Rtmp1hxRS0/file291c6aab439b", layer: "PointTimeSeriesObservation"
## with 950 features and 12 fields
## Feature type: wkbPoint with 2 dimensions
```

```r
head(as.data.frame(response)[,c("x","y","name1","time","result_MeasurementTimeseries_point_MeasurementTVP_value")])
```

```
##       x     y                           name1                 time
## 1 19.90 60.12 Jomala Maarianhamina lentoasema 2014-01-01T00:00:00Z
## 2 19.90 60.12 Jomala Maarianhamina lentoasema 2014-01-01T00:00:00Z
## 3 19.90 60.12 Jomala Maarianhamina lentoasema 2014-01-01T00:00:00Z
## 4 19.90 60.12 Jomala Maarianhamina lentoasema 2014-01-01T00:00:00Z
## 5 19.90 60.12 Jomala Maarianhamina lentoasema 2014-01-01T00:00:00Z
## 6 21.37 59.78                    Parainen Utö 2014-01-01T00:00:00Z
##   result_MeasurementTimeseries_point_MeasurementTVP_value
## 1                                                     NaN
## 2                                                     NaN
## 3                                                     3.6
## 4                                                     2.8
## 5                                                     4.5
## 6                                                     0.3
```
The data is returned as a `SpatialPointsDataFrame` object in long format, i.e. there is a row
for each variable and observation. The column `result.MeasurementTimeseries.point.MeasurementTVP.value`
contains the measurements, which are organized such that the variables `rrday, snow, tday, tmin, tmax` are
repeated in the same order as specified in the request.

### Automated request

The method `getDailyWeather` provides an automated query for the daily weather time series:

```r
request <- FMIWFSRequest(apiKey=apiKey)
client <- FMIWFSClient()
response <- client$getDailyWeather(request=request, startDateTime=as.POSIXlt("2014-01-01"), endDateTime=as.POSIXlt("2014-01-02"))
```

```r
head(as.data.frame(response)[,c("x","y","name1","time1","variable","measurement1","measurement2")])
```

```
##       x     y                           name1                time1
## 1 19.90 60.12 Jomala Maarianhamina lentoasema 2014-01-01T00:00:00Z
## 2 19.90 60.12 Jomala Maarianhamina lentoasema 2014-01-01T00:00:00Z
## 3 19.90 60.12 Jomala Maarianhamina lentoasema 2014-01-01T00:00:00Z
## 4 19.90 60.12 Jomala Maarianhamina lentoasema 2014-01-01T00:00:00Z
## 5 19.90 60.12 Jomala Maarianhamina lentoasema 2014-01-01T00:00:00Z
## 6 21.37 59.78                    Parainen Utö 2014-01-01T00:00:00Z
##   variable measurement1 measurement2
## 1    rrday          NaN          NaN
## 2     snow          NaN          NaN
## 3     tday          3.6          3.8
## 4     tmin          2.8          3.3
## 5     tmax          4.5          4.3
## 6    rrday          0.3         -1.0
```
The automated method associates the data with the metadata and the result looks cleaner. Multiple measurements
from the same locations are indexed with 1,2,... and in this case there are two days and one measurement for each
day.

### Raster

To request a grid in the GRIB format manually, use the `getRaster` method, for instance:

```r
library(raster)
request <- FMIWFSRequest(apiKey=apiKey)
request$setParameters(request="getFeature",
                      storedquery_id="fmi::observations::weather::monthly::grid",
                      starttime="2012-01-01",
                      endtime="2012-01-01")
client <- FMIWFSClient()
response <- client$getRaster(request=request, parameters=list(splitListFields=TRUE))
```
The response is returned as a `RasterBrick` object of the `raster` package:

```r
response
```

```
## class       : RasterBrick 
## dimensions  : 1165, 1901, 2214665, 2  (nrow, ncol, ncell, nlayers)
## resolution  : 0.008996, 0.008993  (x, y)
## extent      : 15.97, 33.07, 59.6, 70.08  (xmin, xmax, ymin, ymax)
## coord. ref. : +proj=longlat +a=6371229 +b=6371229 +no_defs 
## data source : /tmp/user/1012574/Rtmp1hxRS0/file291c10a0498d 
## names       : file291c10a0498d.1, file291c10a0498d.2
```
Set the NA value and plot the interpolated monthly mean temperature in January 2012:

```r
NAvalue(response) <- 9999
plot(response[[1]])
```

![plot of chunk request-raster-plot](figure/request-raster-plot.png) 

There is also the automated request method `getMonthlyWeatherGrid` for obtaining monthly weather data.

## Licensing and further information

For the open data license, see <http://en.ilmatieteenlaitos.fi/open-data-licence>. Further information about
the open data and the API is provided by the FMI at <http://en.ilmatieteenlaitos.fi/open-data>.

## Citing the R package

This work can be freely used, modified and distributed under the
[Two-clause FreeBSD license](http://en.wikipedia.org/wiki/BSD\_licenses). Kindly cite the
R package as 'Jussi Jousimo (C) 2014. fmi R package. URL: http://www.github.com/rOpenGov/fmi'.

## Session info

This tutorial was created with


```
## R version 3.1.1 (2014-07-10)
## Platform: x86_64-pc-linux-gnu (64-bit)
## 
## locale:
##  [1] LC_CTYPE=fi_FI.UTF-8       LC_NUMERIC=C              
##  [3] LC_TIME=en_GB.UTF-8        LC_COLLATE=en_GB.UTF-8    
##  [5] LC_MONETARY=fi_FI.UTF-8    LC_MESSAGES=en_GB.UTF-8   
##  [7] LC_PAPER=en_GB.UTF-8       LC_NAME=C                 
##  [9] LC_ADDRESS=C               LC_TELEPHONE=C            
## [11] LC_MEASUREMENT=en_GB.UTF-8 LC_IDENTIFICATION=C       
## 
## attached base packages:
## [1] stats     graphics  grDevices utils     datasets  methods   base     
## 
## other attached packages:
## [1] knitr_1.6     raster_2.2-31 fmi_0.1.01    rwfs_0.1.01   rgdal_0.9-1  
## [6] sp_1.0-14    
## 
## loaded via a namespace (and not attached):
## [1] evaluate_0.5.3  formatR_0.10    grid_3.1.1      lattice_0.20-29
## [5] markdown_0.7    stringr_0.6.2   tools_3.1.1
```
