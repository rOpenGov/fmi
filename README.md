# Finnish Meteorological Institute (FMI) open data API client for R

[![Build Status](https://api.travis-ci.org/rOpenGov/fmi.png)](https://travis-ci.org/rOpenGov/fmi)
[![AppVeyor Status](https://ci.appveyor.com/api/projects/status/github/rOpenGov/fmi?branch=master&svg=true)](https://ci.appveyor.com/project/rOpenGov/fmi)
[![Stories in Ready](https://badge.waffle.io/ropengov/fmi.png?label=Ready)](http://waffle.io/ropengov/fmi)
[![Join the chat at https://gitter.im/rOpenGov/fmi](https://badges.gitter.im/rOpenGov/fmi.svg)](https://gitter.im/rOpenGov/fmi?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)
[![codecov](https://codecov.io/gh/rOpenGov/fmi/branch/master/graph/badge.svg)](https://codecov.io/gh/rOpenGov/fmi)  
[![Watch on GitHub][github-watch-badge]][github-watch]
[![Star on GitHub][github-star-badge]][github-star]
[![Follow](https://img.shields.io/twitter/follow/ropengov.svg?style=social)](https://twitter.com/intent/follow?screen_name=ropengov)  

<!--
DOI has to be set separately for each package (if needed) - ask antagomir for more info
[![DOI](https://zenodo.org/badge/4203/rOpenGov/fmi.png)](https://github.com/rOpenGov/fmi)
-->

This [rOpenGov](http://ropengov.github.io) R package (`fmi`) provides a client to access [Finnish Meteorological Institute (Ilmatieteenlaitos)](http://www.fmi.fi/en/) [open data](http://en.ilmatieteenlaitos.fi/open-data).

+ Maintainer: [Joona Lehtomäki](http://www.github.com/jlehtoma/)
+ Original author: [Jussi Jousimo](http://www.github.com/statguy/)
+ Co-authors: [Leo Lahti](http://www.github.com/antagomir/), Ilari Scheinin
+ [Full contributor list](https://github.com/rOpenGov/fmi/graphs/contributors)
+ License: FreeBSD

## Usage

For usage, check the [tutorial page](https://github.com/rOpenGov/fmi/blob/master/vignettes/fmi_tutorial.md). Also check these examples of getting FMI [lightning data](http://rpubs.com/jlehtoma/210761) and [gridded observation (raster) data](http://rpubs.com/jlehtoma/221026). 

## Installation

`fmi` relies on [`rwfs`](https://github.com/rOpenGov/rwfs) package for 
interfacing with the FMI WFS (Web Feature Service) API. `rwfs` in turn relies
on [`sf`](https://CRAN.R-project.org/package=sf) package for the actual 
geospatial operations. Neither `fmi` nor `rwfs` are yet on CRAN, but you can
install them directly from GitHub using `devtools`:

```{r, eval=FALSE}
install.packages(devtools)
library(devtools)
devtools::install_github("rOpenGov/rwfs")
devtools::install_github("rOpenGov/fmi")
```


## Contact

  You are welcome to:

  * [Use issue tracker](https://github.com/ropengov/fmi/issues) for feedback and bug reports.
  * [Send pull requests](https://github.com/rOpenGov/fmi/pulls)
  * [Star us on the Github page](https://github.com/ropengov/fmi)
  * [Join the discussion in Gitter](https://gitter.im/rOpenGov/fmi)  



[github-watch-badge]: https://img.shields.io/github/watchers/ropengov/fmi.svg?style=social
[github-watch]: https://github.com/ropengov/fmi/watchers
[github-star-badge]: https://img.shields.io/github/stars/ropengov/fmi.svg?style=social
[github-star]: https://github.com/ropengov/fmi/stargazers
[twitter]: https://twitter.com/intent/tweet?text=Check%20out%20fmi!%20%E2%9C%A8%20Recognize%20all%20contributors,%20not%20just%20the%20ones%20who%20commit%20code%20%E2%9C%A8%20https://github.com/ropengov/fmi%20%F0%9F%A4%97
[twitter-badge]: https://img.shields.io/twitter/url/https/github.com/ropengov/fmi.svg?style=social

