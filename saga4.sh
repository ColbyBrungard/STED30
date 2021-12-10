#!/bin/bash

set -x

# Source common functions and variables
source ./common.sh

# Get Arguments
wsgrd="$1" # Watershed sgrd file path
wclip="$2" # Watershed clip file path
wout="$3" # Watershed output directory path

# Output Directories
tdir="$wout/saga4_temp" # temp directory
mkdir -p "$tdir"

# Set common input parameters
declare -a neighbors=("2" "4" "8" "16" "32")

#Set up timer
SECONDS=0

echo "$(date +%F\ %H:%M:%S): starting Multiscale Morphometric Features"
# Multiscale Morphometric Features
for nbr in ${neighbors[@]}; do

	tfile="$wout/morpfeat_$nbr.tif"
    if ! validate_gdal_files "$tfile"; then
		saga_cmd ta_morphometry 23 -DEM="$wsgrd" -FEATURES="$tdir/morpfeat_$nbr.sgrd"  -TOL_SLOPE=1.000000 -TOL_CURVE=0.000100 -EXPONENT=0.000000 -ZSCALE=1.000000 -CONSTRAIN=0 -SIZE="$nbr" 
		Trim_gdalwarp_byte "$wclip" "$bufferB" "$tdir/morpfeat_$nbr.sdat" "$tfile"
	fi	

	tfile="$wout/genelev_$nbr.tif"
    if ! validate_gdal_files "$tfile"; then
		saga_cmd ta_morphometry 23 -DEM="$wsgrd" -ELEVATION="$tdir/genelev_$nbr.sgrd" -TOL_SLOPE=1.000000 -TOL_CURVE=0.000100 -EXPONENT=0.000000 -ZSCALE=1.000000 -CONSTRAIN=0 -SIZE="$nbr" 
		Trim_gdalwarp "$wclip" "$bufferB" "$tdir/genelev_$nbr.sdat" "$tfile"
	fi	

	tfile="$wout/aspct_$nbr.tif"
    if ! validate_gdal_files "$tfile"; then	
		saga_cmd ta_morphometry 23 -DEM="$wsgrd" -ASPECT="$tdir/aspct_$nbr.sgrd" -TOL_SLOPE=1.000000 -TOL_CURVE=0.000100 -EXPONENT=0.000000 -ZSCALE=1.000000 -CONSTRAIN=0 -SIZE="$nbr" 
		Trim_gdalwarp "$wclip" "$bufferB" "$tdir/aspct_$nbr.sdat" "$tfile"
	fi	

	tfile="$wout/sl_$nbr.tif"
    if ! validate_gdal_files "$tfile"; then	
		saga_cmd ta_morphometry 23 -DEM="$wsgrd" -SLOPE="$tdir/sl_$nbr.sgrd" -TOL_SLOPE=1.000000 -TOL_CURVE=0.000100 -EXPONENT=0.000000 -ZSCALE=1.000000 -CONSTRAIN=0 -SIZE="$nbr" 
		Trim_gdalwarp "$wclip" "$bufferB" "$tdir/sl_$nbr.sdat" "$tfile"
	fi	

	tfile="$wout/profc_$nbr.tif"
    if ! validate_gdal_files "$tfile"; then	
		saga_cmd ta_morphometry 23 -DEM="$wsgrd" -PROFC="$tdir/profc_$nbr.sgrd" -TOL_SLOPE=1.000000 -TOL_CURVE=0.000100 -EXPONENT=0.000000 -ZSCALE=1.000000 -CONSTRAIN=0 -SIZE="$nbr" 
		Trim_gdalwarp "$wclip" "$bufferB" "$tdir/profc_$nbr.sdat" "$tfile"
	fi	

	tfile="$wout/planc_$nbr.tif"
    if ! validate_gdal_files "$tfile"; then	
		saga_cmd ta_morphometry 23 -DEM="$wsgrd" -PLANC="$tdir/planc_$nbr.sgrd" -TOL_SLOPE=1.000000 -TOL_CURVE=0.000100 -EXPONENT=0.000000 -ZSCALE=1.000000 -CONSTRAIN=0 -SIZE="$nbr" 
		Trim_gdalwarp "$wclip" "$bufferB" "$tdir/planc_$nbr.sdat" "$tfile"
	fi	

	tfile="$wout/longc_$nbr.tif"
    if ! validate_gdal_files "$tfile"; then	
		saga_cmd ta_morphometry 23 -DEM="$wsgrd" -LONGC="$tdir/longc_$nbr.sgrd" -TOL_SLOPE=1.000000 -TOL_CURVE=0.000100 -EXPONENT=0.000000 -ZSCALE=1.000000 -CONSTRAIN=0 -SIZE="$nbr" 
		Trim_gdalwarp "$wclip" "$bufferB" "$tdir/longc_$nbr.sdat" "$tfile"
	fi	

	tfile="$wout/crosc_$nbr.tif"
    if ! validate_gdal_files "$tfile"; then	
		saga_cmd ta_morphometry 23 -DEM="$wsgrd" -CROSC="$tdir/crosc_$nbr.sgrd" -TOL_SLOPE=1.000000 -TOL_CURVE=0.000100 -EXPONENT=0.000000 -ZSCALE=1.000000 -CONSTRAIN=0 -SIZE="$nbr" 
		Trim_gdalwarp "$wclip" "$bufferB" "$tdir/crosc_$nbr.sdat" "$tfile"
	fi	

	tfile="$wout/maxc_$nbr.tif"
    if ! validate_gdal_files "$tfile"; then	
		saga_cmd ta_morphometry 23 -DEM="$wsgrd" -MAXIC="$tdir/maxc_$nbr.sgrd" -TOL_SLOPE=1.000000 -TOL_CURVE=0.000100 -EXPONENT=0.000000 -ZSCALE=1.000000 -CONSTRAIN=0 -SIZE="$nbr" 
		Trim_gdalwarp "$wclip" "$bufferB" "$tdir/maxc_$nbr.sdat" "$tfile"
	fi	

	tfile="$wout/minc_$nbr.tif"
    if ! validate_gdal_files "$tfile"; then	
		saga_cmd ta_morphometry 23 -DEM="$wsgrd" -MINIC="$tdir/minc_$nbr.sgrd" -TOL_SLOPE=1.000000 -TOL_CURVE=0.000100 -EXPONENT=0.000000 -ZSCALE=1.000000 -CONSTRAIN=0 -SIZE="$nbr" 
		Trim_gdalwarp "$wclip" "$bufferB" "$tdir/minc_$nbr.sdat" "$tfile"
	fi
	
done 


echo "$(date +%F\ %H:%M:%S): starting terrain ruggedness index"
# Terrain Ruggedness Index
for nbr in ${neighbors[@]}; do
	tfile="$wout/tri_$nbr.tif"
    if ! validate_gdal_files "$tfile"; then
		saga_cmd ta_morphometry 16 -DEM="$wsgrd" -TRI="$tdir/tri_$nbr.sgrd" -MODE=0 -RADIUS="$nbr"
		Trim_gdalwarp "$wclip" "$bufferB" "$tdir/tri_$nbr.sdat" "$tfile"
	fi 

done


echo "$(date +%F\ %H:%M:%S): starting terrain surface convexity"
# Terrain Surface Convexity
for nbr in ${neighbors[@]}; do
	tfile="$wout/tsc_$nbr.tif"
    if ! validate_gdal_files "$tfile"; then
		saga_cmd ta_morphometry 21 -DEM="$wsgrd" -CONVEXITY="$tdir/tsc_$nbr.sgrd" -KERNEL=1 -TYPE=0 -EPSILON=0.010000 -METHOD=1 -SCALE="$nbr"
		Trim_gdalwarp "$wclip" "$bufferB" "$tdir/tsc_$nbr.sdat" "$tfile"
	fi 
	
done


# Cleanup Temp Files
rm -rf "$tdir"

#Print elapsed time
duration=$SECONDS
echo "It took $(($duration / 60)) minutes and $(($duration % 60)) seconds to complete Saga4."