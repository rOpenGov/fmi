## CHANGES IN VERSION 0.1.15 (2016-10-12)

### NEW FEATURES

+ `fmi_stations()` supersedes old function `fmi_weather_stations()`. The
old function can still be used. `fmi_stations()` can be used to fetch
information on all FMI stations available at http://en.ilmatieteenlaitos.fi/observation-stations .
If packages `rvest` or `XML` are available and the user is online, 
a fresh verstion of the table will be scraped and returned. If not,
a local version distributed with the package is used instead. 


### OTHER

+ Making check pass without WARNINGs and most of NOTEs.

## CHANGES IN VERSION 0.1.14 (2016-09-19)

### NEW FEATURES

+ `FMIWFSClient$getLightningStrikes()` is a new method used to query FMI API 
for lightning strikes within a given area and time frame.
