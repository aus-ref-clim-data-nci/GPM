#!/bin/bash -l
# Copyright 2021 ARC Centre of Excellence for Climate Extremes
#
# author: Paola Petrelli <paola.petrelli@utas.edu.au>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# This script is used to concatenate GPM IMERG 30 minutes one timestep files to monthly files
# on the NCI server
# The file to concatenate are in /g/data/ia39/aus-ref-clim-data-nci/gpm/data/tmp/<year>
# original filename are like 3B-HHR.MS.MRG.3IMERG.20050119-S220000-E222959.1320.V06B.HDF5.nc
# Final dataset saved to /g/data/ia39/aus-ref-clim-data-nci/gpm/data/V06B/
# with filenames 3B-HHR.MS.MRG.3IMERG.V06B_${yr}${mn}.nc
#
# To run the script ./gpm_concat.sh
# A record of updates is kept in /g/data/ia39/aus-ref-clim-data-nci/gpm/code/concat_log.txt
#
# Last change:
# 2022-09-14
#

module load nco
module load cdo

yr=$1
mn=$2
today=$(date "+%Y-%m-%d")
# set directories
root_dir=${AUSREFDIR:-/g/data/ia39/aus-ref-clim-data-nci}
data_dir="${root_dir}/gpm/data"
code_dir="${root_dir}/gpm/code"
tmpdir="${data_dir}/tmp/${yr}" 
outdir="${data_dir}/V06B/${yr}"
mkdir -p $outdir
# run nco from temporary location
cd $tmpdir

# before proceeding save a list of filenames + modified date in file
fout="${code_dir}/mod_date_${yr}.txt"
for f in $(ls 3B-HHR.MS.MRG.3IMERG.${yr}${mn}*); do
    echo "${f} $(date -r ${f} +'%Y-%m-%d')" >> $fout
done
# to get the last day of the month
# set ${yr}/${mn}/01 add a month, remove 1 day and pass to date function
last=$(date --date="${yr}/${mn}/1 + 1 month day ago" "+%d")
# concatenate each day using cdo
# set netcdf4 classic with compression level 5 and shuffle
#last=01
for day in $(seq -w 01 $last); do
    fpath="${outdir}/3B-HHR.MS.MRG.3IMERG.V06B_${yr}${mn}${day}.nc"
    cdo --silent --no_warnings --no_history -L -s -f nc4c -z zip_4 cat 3B-HHR.MS.MRG.3IMERG.${yr}${mn}${day}*.nc tmp.nc
    ncks --cnk_dmn time,48 --cnk_dmn lat,600 --cnk_dmn lon,600 tmp.nc ${fpath} 
    rm tmp.nc
# rewrite history attribute
    hist="downloaded original files from 
      https://gpm1.gesdisc.eosdis.nasa.gov/opendap/hyrax/GPM_L3/GPM_3IMERGHH.06
      Using cdo to concatenate files, and nco to modify chunks: 
      cdo --silent --no_warnings --no_history -L -s -f nc4c -z zip_4 cat 3B-HHR.MS.MRG.3IMERG.${yr}${mn}${day}*.nc tmp.nc
      ncks --cnk_dmn time,48 --cnk_dmn lat,600 --cnk_dmn lon,600 tmp.nc ${fpath}" 
    ncatted -h -O -a history,global,o,c,"$hist" ${fpath}
done

# record in log
echo "${today} year-mn ${yr}-${mn} data concatenated by $USER" >> ${code_dir}/concat_log.txt
