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

#Set up timer
SECONDS=0

echo "$(date +%F\ %H:%M:%S): mosaicking $(name)"

# buildvrt
gdalbuildvrt -input_file_list "$desFol/$name.txt" "$desFol/$name.vrt" 

# mosaic and compress
gdal_translate --config GDAL_CACHEMAX 9999 --config GDAL_NUM_THREADS ALL_CPUS -co "TILED=YES" -co "COMPRESS=DEFLATE" -co "PREDICTOR=3" -co BIGTIFF=yes "$desFol/$name.vrt" "$desFol/$name.tif"

# add overviews so drawing takes less time. This adds about 10 GB to each mosaiced file.
gdaladdo -r average --config COMPRESS_OVERVIEW JPEG --config PHOTOMETRIC_OVERVIEW YCBCR --config INTERLEAVE_OVERVIEW PIXEL --config GDAL_NUM_THREADS ALL_CPUS "$desFol/$name.tif" 2 4 8 16 32 64 128

#Print elapsed time
duration=$SECONDS
echo "It took $(($duration / 60)) minutes and $(($duration % 60)) seconds to mosaic and add overviews for $(name)"