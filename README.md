# Finnish Meteorological Institute (FMI) open data API client for R

[![Build Status](https://api.travis-ci.org/rOpenGov/fmi.png)](https://travis-ci.org/rOpenGov/fmi)
[![Stories in Ready](https://badge.waffle.io/ropengov/fmi.png?label=Ready)](http://waffle.io/ropengov/fmi)

<!--
DOI has to be set separately for each package (if needed) - ask antagomir for more info
[![DOI](https://zenodo.org/badge/4203/rOpenGov/fmi.png)](https://github.com/rOpenGov/fmi)
-->

This R package (fmi) provides a client to access the [Finnish Meteorological Institute](http://en.ilmatieteenlaitos.fi/)
 (Ilmatieteenlaitos) [open data](http://en.ilmatieteenlaitos.fi/open-data).
This R package is a part of the [rOpenGov](http://ropengov.github.io) project.

+ Maintainers: [Jussi Jousimo](http://www.github.com/statguy/)
+ Contributors: [Joona Lehtomäki](http://www.github.com/jlehtoma/)
+ License: FreeBSD

## Overview

This R package provides tools to access open data from [Finnish Meteorological Institute (Ilmatieteenlaitos)](http://www.fmi.fi/en/).

For usage, check the [tutorial page](https://github.com/rOpenGov/fmi/blob/master/vignettes/fmi_tutorial.md). 

This R package is part of the [rOpenGov](http://ropengov.github.io) project.

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
```{r, eval=FALSE}
install.packages(c("devtools", "sp", "rgdal", "raster"))
library(devtools)
install_github("rOpenGov/rwfs")
```
Note that rgdal version 0.9-1 or newer is needed.
Then install the fmi package itself:
```{r, eval=FALSE}
install_github("rOpenGov/fmi")
```


## Contact

  You are welcome to:

  * [submit suggestions and bug-reports](https://github.com/ropengov/fmi/issues)
  * [submit a pull-request](https://github.com/rOpenGov/fmi/pulls)
  * compose a friendly e-mail to: [louhos@googlegroups.com](mailto:louhos@googlegroups.com)
  * join IRC at !louhos@IRCnet (Finland) and ropengov@Freenode (international)
  * follow us in social media: Louhos (Finland); rOpenGov (international)
