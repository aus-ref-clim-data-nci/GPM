# GPM IMERG
  
## Overview

GPM IMERG Final Precipitation L3 Half Hourly 0.1 degree x 0.1 degree V06

The Integrated Multi-satellitE Retrievals for GPM (IMERG) algorithm combines information from the GPM satellites to estimate global precipitation. IMERG is the continuation of TRMM. The latest version is the minor version 06B which combines the precipitation estimates collected by the TRMM satellite (2000 - 2015) with the estimates from the GPM satellite (2014 - present).
The monthly Global Precipitation Climatology Project (GPCP) Satellite-Gauge (SG) product over high-latitude ocean and tropical land is used to correct known biases.

The dataset has a spatial resolution of 0.1°x0.1° (roughly 10x10 km) over the globe and a temporal resolution of 30 minutes. The temporal coverage starts on 2000-06-01 to  present with about 3 months of delay (this is effectively up to 1 year for the netcdf version, see Data download section below).

The IMERG system is run twice in near-real time:

* "Early" multi-satellite product ~4 hr after observation time using only forward morphing and
* "Late" multi-satellite product ~14 hr after observation time, using both forward and backward morphing
and once after the monthly gauge analysis is received:
* "Final", satellite-gauge product ~3.5 months after the observation month, using both forward and backward morphing and including monthly gauge analyses.

For this collection only download the "final" product is downloaded. 

More information and a detailed description of the algorithm and data sources used are available on the [NASA GPM website](https://gpm.nasa.gov/data/imerg) and on the [GES DISC website](https://disc.gsfc.nasa.gov/datasets/GPM_3IMERGHH_06/summary).

## Data download

The data is downloaded from the [GESC DISC hyrax server](https://gpm1.gesdisc.eosdis.nasa.gov/opendap/hyrax/GPM_L3/GPM_3IMERGHH.06/contents.html) using the opendap protocol to get it in netcdf4 format instead of the original HDF5. This version is updated irregularly, so the delay in data availability is effectively up to a year from present.
As each original file contains only 1 timestep for ease of use the files are then concatenated in daily files using CDO and rechunked using NCO.
Updates are run with a monthly frequency via the [accessdev Jenkins server](https://accessdev.nci.org.au/jenkins/job/aus-ref-clim-data-nci/job/IMERG/).

The code used to download the files is python based, to see all the options:
```{code}
    python gpm.py --help
```
The code used to concatenate the files is a bash script calling CDO
```{code}
    ./gpm_concat.sh <yr> <mn> 
```
which runs
```{code}
cdo --silent --no_warnings --no_history -L -s -f nc4c -z zip_4 cat 3B-HHR.MS.MRG.3IMERG.${yr}${mn}${day}*.nc tmp.nc
ncks --cnk_dmn time,48 --cnk_dmn lat,600 --cnk_dmn lon,600 tmp.nc 3B-HHR.MS.MRG.3IMERG.${yr}${mn}${day}.nc 
```

A record of updates is kept in `update_log.txt` for downloads and a separate log `concat_log.txt` for the concatenation step.

## Data location

GPM IMERG V06B data in available in

```
/g/data/ia39/aus-ref-clim-data-nci/gpm/data/V06B/<yr>/<files>
```

## License

[NASA Data & Information Policy](https://science.nasa.gov/earth-science/earth-science-data/data-information-policy/)

## Data citation

Huffman, G.J., E.F. Stocker, D.T. Bolvin, E.J. Nelkin, Jackson Tan (2019), GPM IMERG Final Precipitation L3 Half Hourly 0.1 degree x 0.1 degree V06, Greenbelt, MD, Goddard Earth Sciences Data and Information Services Center (GES DISC), Accessed: [Data Access Date], 10.5067/GPM/IMERG/3B-HH/06

## References

GLOBAL PRECIPITATION MEASUREMENT PRECIPITATION PROCESSING SYSTEM, File Specification. 2020.  URL: ftp://gpmweb2.pps.eosdis.nasa.gov/pub/GPMfilespec/filespec.GPM.pdf

Jin, Daeho, Oreopoulos, Lazaros, Lee, Dongmin, Tan, Jackson, Cho, Nayeong. 2021.  Cloud-Precipitation Hybrid Regimes and their Projection onto IMERG Precipitation Data. Vol. -1, No. aop, DOI: 10.1175/JAMC-D-20-0253.1  ISSN: 1558-8424, 1558-8432 

## Acknowledgement

No statement provided.

## Author note


## Assistance

For assistance with GPM IMERG data on NCI, open a new issue at https://github.com/aus-ref-clim-data-nci/GPM/issues

NB Some of the original attributes contain slightly incorrect information and could generate warning in software that run attributes scan. As an example with cdo

Warning (cdfScanVarAttr): NetCDF: Variable not found - >Grid_time<
Warning (cdfScanVarAttr): NetCDF: Variable not found - >Grid_lon<
Warning (cdfScanVarAttr): NetCDF: Variable not found - >Grid_lat<
Warning (cdfScanVarAttr): NetCDF: Variable not found - >Grid_latv<
Warning (cdfScanVarAttr): NetCDF: Variable not found - >Grid_nv<
Warning (cdfScanVarAttr): NetCDF: Variable not found - >Grid_lonv<
Warning (cdf_set_var): Inconsistent variable definition for lat_bnds!
Warning (cdf_set_var): Inconsistent variable definition for lon_bnds!
Warning (cdf_set_var): Inconsistent variable definition for time_bnds!

These warnings can be safely ignored!


