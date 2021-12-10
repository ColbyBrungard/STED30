#!/bin/bash

# echo commands
set -x

# Get Arguments
wtif="$1" # Watershed tif file path
wclip="$2" # Watershed clip file path
sdat="$3" # sdat output file

# Covert tif to sgrd
# -wo NUM_THREADS=$SLURM_CPUS_PER_TASK
gdalwarp --config GDAL_CACHEMAX 1000 -wm 1000 -multi -tr 30 30 -r cubic -dstnodata -99999 -of SAGA "$wtif" "$sdat"

# Convert modified sdat back to tif
# -wo NUM_THREADS=$SLURM_CPUS_PER_TASK -co NUM_THREADS=$SLURM_CPUS_PER_TASK
name="$(basename "${sdat%.*}")"
bdir="$(dirname "$sdat")"
tif="$bdir/$name.tif"

gdalwarp --config GDAL_CACHEMAX 1000 -wm 1000 -multi -cutline "$wclip" -crop_to_cutline -tr 30 30 -r cubic -co COMPRESS=LZW -co PREDICTOR=3 -dstnodata '-3.4e+38' -of GTiff "$sdat" "$tif"
