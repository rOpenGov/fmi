

Finnish Meteorological Institute (FMI) open data API client for R
===========

This R package provides a client to access the [Finnish Meteorological Institute (Ilmatieteenlaitos)](http://en.ilmatieteenlaitos.fi/)
[open data](http://en.ilmatieteenlaitos.fi/open-data).
This R package is part of the [rOpenGov](http://ropengov.github.io) project.

## Installation

### Libraries

The `fmi` package depends on the [GDAL](http://www.gdal.org/) library and its [command line tools](http://www.gdal.org/ogr2ogr.html).
Please, see the installation instructions in the [gisfin package tutorial](https://github.com/rOpenGov/gisfin/blob/master/vignettes/gisfin_tutorial.md)
to install GDAL. Add the command line tools to the search path of your system as follows:

#### Linux

In Linux, the tools should be found from the path by default after installation.
If not, use the `export` command from the terminal, for example:
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

Note that the actual location may vary depending on your system. To test that the tools are found, in terminal type the command:
```
ogr2ogr
```

### Packages

Start R and follow these steps to install the associated packages first:


```r
install.packages(c("devtools", "gdal"))
library(devtools)
install_github("rOpenGov/rwfs")
```

Then install the `fmi` package:


```r
install_github("rOpenGov/fmi")
```

## API key

In order to use the FMI API, you need to obtain a personal API key first.
To get the key, follow the instructions at <https://ilmatieteenlaitos.fi/rekisteroityminen-avoimen-datan-kayttajaksi>
(appears to be available only in Finnish). Enter the key to R:


```r
apiKey <- "ENTER YOUR API KEY HERE"
```

## Available data sets and filtering

FMI provides a brief introduction to the data sets at <http://en.ilmatieteenlaitos.fi/open-data-sets-available>
and a complete list of the available data sets and filtering parameters are described in
<http://en.ilmatieteenlaitos.fi/open-data-manual-fmi-wfs-services>.
Each data set is referenced with an associated stored query id, for example the id for the daily weather time series
is `fmi::observations::weather::daily::timevaluepair`. This data set contains variables for
daily precipitation rate, mean temperature, snow depth, and minimum and maximum temperature.
The data can be filtered with a number of parameters specific to each data set,
for example the starting and the ending dates are provided by the `starttime` and `endtime`
parameters for the weather observations (see below for the details).

## Usage

### Request object

Queries to the FMI API are specified using the `FMIWFSRequest` class. To initialize an object, type:

```r
request <- FMIWFSRequest(apiKey=apiKey)
```

The `fmi` package provides two types of queries: manual one for direct access to the FMI API and
automated one for a convenient access obtaining the data sets.

In the manual case, stored query id and filter parameters are given with the `setParameters` method:

```r
request$setParameters(request="getFeature",
                      storedquery_id="fmi::observations::weather::daily::timevaluepair",
                      starttime="2014-01-01T00:00:00Z",
                      endtime="2014-01-01T00:00:00Z",
                      bbox="19.09,59.3,31.59,70.13",
                      parameters="rrday,snow,tday,tmin,tmax")
```
The parameter `request="getFeature"` must be always specified.

In the automated case, the client class (see below) provides methods to access the data sets
in a convenient way. Filtering parameters are specified as arguments for the methods.

### Client object

Queries to the FMI API are made by using the `FMIWFSClient` class. For example, a manual requests is made with
(continued from the previous example):

```r
client <- FMIWFSClient()
layers <- client$listLayers(request=request)
response <- client$getLayer(request=request, layer=layers[1])
```
This example retrieves a list of layers and the first layer is used to obtain the actual data.

For the stored query `fmi::observations::weather::daily::timevaluepair`, an automated request is provided by the client.
To get all weather observations for the 1st of January in 2014:

```r
request <- FMIWFSRequest(apiKey=apiKey)
client <- FMIWFSClient()
response <- client$getDailyWeather(request=request, startDateTime="2014-01-01", endDateTime="2014-01-01")
```
See the package documentation in R for all automated queries.

Currently, the package supports only a few data sets, which can be obtained directly with a specific method
such as the `getDailyWeather`. The rest of the data sets are available with the generic method `getLayer`.

As `rgdal` does not currently support direct queries to the FMI API in most cases, the client saves the response
to an intermedidate file first and then parses it. The `FMIWFSClient` class provides a caching mechanism, so that
the response is needed to be downloaded only once for the same subsequent queries. The response file can be saved
to a permanent location with the method `saveGMLFile` and loaded up into a `FMIWFSClient` object again with the
`loadGMLFile` method.

### Supported data and metadata

The `fmi` package supports time-value-pair and GRIB data formats. Multipoint-coverage format is not currently supported.
However, most of the multipoint-coverage data sets are availables in the time-value-pair format as well.

The automated queries attempt to associate appropriate metadata with the obtained data. The generic method `getLayer`
does not associate the metadata and therefore it is left to the user to determine the metadata.
In case there is no documentation available, the metadata can be obtained by examining the actual XML response
from the FMI API. The XML response can be browsed by entering the query URL to a browser or saving the response
to a file first.

The query URL can be printed from the request object, by typing:

```r
request
```
A query response is possible to save with the `saveGMLFile` method to an user specified location as mentioned
earlier.

Furthermore, for manual requests, coordinate reference system (if needed) must be specified manually by providing
the `crs` argument for the `getLayer` method. The default CRS appears to be WGS84. Also, longitude and latitude
coordinates may need to be swapped, which can be done with the argument `swapAxisOrder=TRUE`. For example

```r
response <- getLayer(request=request, layer="PointTimeSeriesObservation", crs="+proj=longlat +datum=WGS84", swapAxisOrder=TRUE, parameters=list(splitListFields=TRUE))
```

### Redundant features

Some of the data sets may contain a redundant multipoint feature, which `rgdal` does not handle.
A workaround is to remove the feature using the `ogr2ogr` tool bundled with the GDAL library.
In such case, `explodeCollections=TRUE` needs to be specified for the `getLayer` method, for example

```r
response <- client$getLayer(request=request, layer="PointTimeSeriesObservation", parameters=list(explodeCollections=TRUE))
```

### Old version of rgdal

The `rgdal` package older than version 0.9-1 does not support list data types and therefore `splitListFields=TRUE`
must be provided, e.g.

```r
response <- client$getLayer(request=request, layer="PointTimeSeriesObservation", parameters=list(splitListFields=TRUE))
```

## Examples

### Manual request

Load the library:

```r
library(fmi)
```

Read your api key from a file located in the default directory:

```r
apiKey <- readLines("apikey.txt")
```

Construct a request object for a manual query:

```r
request <- FMIWFSRequest(apiKey=apiKey)
request$setParameters(request="getFeature",
                      storedquery_id="fmi::observations::weather::daily::timevaluepair",
                      starttime="2014-01-01",
                      endtime="2014-01-01",
                      bbox="19.09,59.3,31.59,70.13",
                      parameters="rrday,snow,tday,tmin,tmax")
```
The time parameters can be provided as `POSIXlt` objects and bbox as an `extent` object from
the [`raster`](http://cran.r-project.org/web/packages/raster/index.html) package as well.

Set up the client object and list the layers in the response:

```r
client <- FMIWFSClient()
layers <- client$listLayers(request=request)
```

```r
layers
```

```
## [1] "PointTimeSeriesObservation"
```

Now, parse the data from the response, which has been cached:

```r
response <- client$getLayer(request=request, layer=layers[1], crs="+proj=longlat +datum=WGS84", swapAxisOrder=TRUE)
```

```
## OGR data source with driver: GML 
## Source: "/var/folders/h4/gf7jwm5j4h73224sdw6_903h0000gn/T//RtmpfFuecQ/file14c0f450e79d1", layer: "PointTimeSeriesObservation"
## with 945 features and 10 fields, of which 1 list fields
## Feature type: wkbPoint with 2 dimensions
```

```r
head(as.data.frame(response)[,c("coords.x1","coords.x2","name1","time","result.MeasurementTimeseries.point.MeasurementTVP.value")])
```

```
##   coords.x1 coords.x2                           name1                 time
## 1     19.90     60.12 Jomala Maarianhamina lentoasema 2014-01-01T00:00:00Z
## 2     19.90     60.12 Jomala Maarianhamina lentoasema 2014-01-01T00:00:00Z
## 3     19.90     60.12 Jomala Maarianhamina lentoasema 2014-01-01T00:00:00Z
## 4     19.90     60.12 Jomala Maarianhamina lentoasema 2014-01-01T00:00:00Z
## 5     19.90     60.12 Jomala Maarianhamina lentoasema 2014-01-01T00:00:00Z
## 6     21.37     59.78                    Parainen Utö 2014-01-01T00:00:00Z
##   result.MeasurementTimeseries.point.MeasurementTVP.value
## 1                                                     NaN
## 2                                                     NaN
## 3                                                     3.6
## 4                                                     2.8
## 5                                                     4.5
## 6                                                     0.3
```

The data is returned as a `SpatialPointsDataFrame` object in long format, i.e. there is a row
for each variable. The column `result.MeasurementTimeseries.point.MeasurementTVP.value` contains
the measurements, which are organized such that the variables `rrday, snow, tday, tmin, tmax` are
repeated as specified in the request parameter `parameters`.

### Automated request

The method `getDailyWeather` provides an automated query for the same daily weather time series:

```r
client <- FMIWFSClient()
response <- client$getDailyWeather(request=request, startDateTime=as.POSIXlt("2014-01-01"), endDateTime=as.POSIXlt("2014-01-01"))
```

```r
head(as.data.frame(response)[,c("coords.x1","coords.x2","name1","time","variable","measurement")])
```

```
##   coords.x1 coords.x2                           name1       time variable
## 1     19.90     60.12 Jomala Maarianhamina lentoasema 2014-01-01    rrday
## 2     19.90     60.12 Jomala Maarianhamina lentoasema 2014-01-01     snow
## 3     19.90     60.12 Jomala Maarianhamina lentoasema 2014-01-01     tday
## 4     19.90     60.12 Jomala Maarianhamina lentoasema 2014-01-01     tmin
## 5     19.90     60.12 Jomala Maarianhamina lentoasema 2014-01-01     tmax
## 6     21.37     59.78                    Parainen Utö 2014-01-01    rrday
##   measurement
## 1         NaN
## 2         NaN
## 3         3.6
## 4         2.8
## 5         4.5
## 6         0.3
```
The automated method associates the data with the metadata and the result looks clearer.

### Raster

To request a grid in the GRIB format manually, use the `getRaster` method, for instance:

```r
request$setParameters(request="getFeature",
                      storedquery_id="fmi::observations::weather::monthly::grid",
                      starttime="2012-01-01",
                      endtime="2012-01-01")
client <- FMIWFSClient()
response <- client$getRaster(request=request)
```
The response is returned as a `RasterBrick` object of the `raster` package:

```r
response
```

```
## class       : RasterBrick 
## dimensions  : 1165, 1901, 2214665, 2  (nrow, ncol, ncell, nlayers)
## resolution  : 0.008996, 0.008993  (x, y)
## extent      : 15.96, 33.07, 59.61, 70.08  (xmin, xmax, ymin, ymax)
## coord. ref. : +proj=longlat +a=6371229 +b=6371229 +no_defs 
## data source : /private/var/folders/h4/gf7jwm5j4h73224sdw6_903h0000gn/T/RtmpfFuecQ/file14c0f1c870485 
## names       : file14c0f1c870485.1, file14c0f1c870485.2
```
Interpolated montly mean temperature in January 2012:

```r
plot(response[[1]])
```

![plot of chunk request-raster-plot](figure/request-raster-plot.png) 

### Error handling

TODO

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
## Platform: x86_64-apple-darwin13.1.0 (64-bit)
## 
## locale:
## [1] en_GB.UTF-8/en_GB.UTF-8/en_GB.UTF-8/C/en_GB.UTF-8/en_GB.UTF-8
## 
## attached base packages:
## [1] stats     graphics  grDevices utils     datasets  methods   base     
## 
## other attached packages:
## [1] rgdal_0.9-1 sp_1.0-15   knitr_1.6   fmi_0.1.01  rwfs_0.1.01
## 
## loaded via a namespace (and not attached):
##  [1] digest_0.6.4     evaluate_0.5.5   formatR_0.10     grid_3.1.1      
##  [5] htmltools_0.2.4  lattice_0.20-29  markdown_0.7     raster_2.2-31   
##  [9] rmarkdown_0.2.50 stringr_0.6.2    tools_3.1.1
```
