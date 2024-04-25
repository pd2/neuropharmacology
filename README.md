# neuropharmacology
MATLAB scripts process the neuropharmacology results documented in an excel sheet

Each excel file is pertaining to 1 drug and each sheet pertains to 1 experiment trial.

### Inputs:
paths to input and output folders, 
excel file name to process
list of drugs to process

### Author :- 
Pradeep D, Institute of Neuroscience, Newcastle University, Newcastle-upon-Tyne, UK

(C) Copyright 2014 - All rights reserved with Newcastle University



These MATLAB scripts perform the following actions:

read the data from an excel file 
* listing 3 parameters - power, frequency, and area under curve values for each electrode as a time series
* listing population data (mean, s.e.m values) of 3 parameters - power, frequency, and area under curve values

plot the results for each parameter either with or without normalization w.r.t control reading 
* One plot per trial  with all electrodes ? data points are circled if they stabilize as per a set tolerance criteria
* One plot for each parameter at population level
* One plot combining all parameters using population data for each drug

Output an Excel sheet for each drug with 
* population data (mean, s.e.m values) for each parameter as a (reference) time series
* Sample size ? number of slices and number of animals

