## CHANGES IN VERSION 0.2.0 (2016-01-29)

### NEW FEATURES

+ `fmi_lightnings()` is a wrapper function for 
`FMIWFSClient$getLightningStrikes()`. This is the first move towards a more
idiomatic API based on simpler functions instead of R6-methods. The core class
architecture will be retained, just the API changes.
+ With the previous change, session information, such as setting the API key,
is handled through a new `.session` environment. Associated functions 
`ìnit_session()` and `check_session()` also introduced.

### OTHER

+ FMI stations data updated (8 new rows).

## CHANGES IN VERSION 0.1.15 (2016-10-12)

### NEW FEATURES

+ `fmi_stations()` supersedes old function `fmi_weather_stations()`. The
old function can still be used. `fmi_stations()` can be used to fetch
If packages `rvest` or `XML` are available and the user is online, 
information on all FMI stations available at http://en.ilmatieteenlaitos.fi/observation-stations .
a fresh verstion of the table will be scraped and returned. If not,
a local version distributed with the package is used instead. 

### OTHER

+ Re-formatting older code.
+ Making check pass without WARNINGs and NOTEs.

## CHANGES IN VERSION 0.1.14 (2016-09-19)

### NEW FEATURES

+ `FMIWFSClient$getLightningStrikes()` is a new method used to query FMI API 
for lightning strikes within a given area and time frame.
