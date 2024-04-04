#!/bin/bash -l
# Copyright 2021 ARC Centre of Excellence for Climate Extremes
#
# authors: 
# Sam Green <sam.green@unsw.edu.au>
# Paola Petrelli <paola.petrelli@utas.edu.au>
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
# The script can also be run in parallel when submitting a job to Gadi
# A record of updates is kept in /g/data/ia39/aus-ref-clim-data-nci/gpm/code/concat_log.txt
#
# Date created: 02-11-2023
#

module load parallel
module load nco
module load cdo

yr=2023
total_days=$(is_leap_year "$yr" && echo "366" || echo "365")
#total_days=356

execute_tasks () {
    i=$1

    root_dir="/g/data/ia39/aus-ref-clim-data-nci/gpm/data/"
    outdir="$root_dir/V07/$yr/"

    if [ -d "$outdir" ]; then
        echo "Directory $outdir exists."
    else
        echo "Directory $outdir does not exist. Creating now..."
        mkdir -p "$outdir" || { echo "Failed to create directory $outdir" >&2; exit 1; }
    fi

    ii=$(printf "%03d" $i)
    dt=$(date -d "01/01/$yr +$i days -1 day" "+%Y%m%d")

    tmpdir="$root_dir/tmp/$yr/$ii/"
    f_in=$tmpdir/3B-HHR.MS.MRG.3IMERG.*.V07B.HDF5.nc4
    f_out=$outdir/3B-HHR.MS.MRG.3IMERG.$dt.V07B.nc

    if [ -f "$f_out" ]; then
        echo "$f_out exists already skipping"
    else 
        echo "Concatenating day $i in year $yr"
        # Concatenate all files from a day together, save as a tmp.nc file
        cdo --silent --no_warnings --no_history -L -s -f nc4c -z zip_4 cat $f_in $outdir/tmp_$i.nc
        # Re-chunk the tmp.nc file
        echo "Concatenating complete, now re-chunking...."
        ncks --cnk_dmn time,48 --cnk_dmn lat,600 --cnk_dmn lon,600 $outdir/tmp_$i.nc $f_out
        rm $outdir/tmp_$i.nc
        # rewrite history attribute
        hist="downloaded original files from 
            https://gpm1.gesdisc.eosdis.nasa.gov/opendap/GPM_L3/GPM_3IMERGHH.07
            Using cdo to concatenate files, and nco to modify chunks: 
            cdo --silent --no_warnings --no_history -L -s -f nc4c -z zip_4 cat $f_in $outdir/tmp_$i.nc
            ncks --cnk_dmn time,48 --cnk_dmn lat,600 --cnk_dmn lon,600 tmp.nc $f_out"
        # Add what we've done into the history attribute in the file. 
        ncatted -h -O -a history,global,o,c,"$hist" ${f_out}
    fi
}

export yr
export -f execute_tasks

# Run the code in parallel for an pbs job:
#seq $total_days | parallel -j 48 execute_tasks {}

# Run the code in serial
execute_tasks $total_days