#!/bin/bash

# Echo Bash Commands
set -x

# Set Arguments
line="$1"
desFol="$2"

# Interpret line data
fname="$(echo "$line" | awk -F',' '{print $1}')"
name="$(echo "$fname" | sed 's/\.tif//')"

# find all files that match fname and write to text file as this is needed as input to gdlabuildvrt
find . -type f -name "$fname" >> "$desFol/$name.txt"

gdalbuildvrt -input_file_list "$desFol/$name.txt" "$desFol/$name.vrt" 
# I do not create COG here because I have to add overviews after the file is created
gdal_translate --config GDAL_CACHEMAX 9999 --config GDAL_NUM_THREADS ALL_CPUS -co "TILED=YES" -co "COMPRESS=DEFLATE" -co BIGTIFF=yes "$desFol/$name.vrt" "$desFol/$name.tif"