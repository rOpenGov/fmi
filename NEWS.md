## CHANGES IN VERSION 0.1.15 (2016-09-20)

### NEW FEATURES

+ `fmi_lightnings` is a wrapper function for 
`FMIWFSClient$getLightningStrikes()`. This is the first move towards a more
idiomatic API based on simpler functions instead of R6-methods. The core class
architecture will be retained, just the API changes.
+ With the previous change, session information, such as setting the API key,
is handled through a new `.session` environment. Associated functions 
`ìnit_session()` and `check_session()` also introduced.


### OTHER

+ Re-formatting older code.
+ Making check pass without WARNINGs and most of NOTEs.

## CHANGES IN VERSION 0.1.14 (2016-09-19)

### NEW FEATURES

+ `FMIWFSClient$getLightningStrikes()` is a new method used to query FMI API 
for lightning strikes within a given area and time frame.
