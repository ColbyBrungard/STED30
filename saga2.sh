#!/bin/bash
# This script implements calculations that take a moderate amount of time to calculate

set -x

# Source common functions and variables
source ./common.sh

# Get Arguments
wsgrd="$1" # Watershed sgrd file path
wclip="$2" # Watershed clip file path
wout="$3" # Watershed output directory path
LUT="$4" # lookup table

# Output Directories
tdir="$wout/saga2_temp" # temp directory
mkdir -p "$tdir"

# Set common input parameters
declare -a orders=("2" "3" "4" "5" "6")
declare -a neighbors=("2" "4" "8" "16" "32")

#Set up timer
SECONDS=0

echo "$(date +%F\ %H:%M:%S): starting vertical distance to channel network" 
# Vertical distance to channel network
for order in ${orders[@]}; do
	if validate_gdal_files "$wout/strordr_$order.tif" "$wout/vdcn_$order.tif" "$wout/bl_$order.tif"; then
		continue
	fi 

	saga_cmd ta_channels 5 -DEM="$wsgrd" -ORDER="$tdir/strordr_$order.sgrd" -THRESHOLD="$order"
	saga_cmd ta_channels 3 -ELEVATION="$wsgrd" -CHANNELS="$tdir/strordr_$order.sgrd" -DISTANCE="$tdir/vdcn_$order.sgrd" -BASELEVEL="$tdir/bl_$order.sgrd" -THRESHOLD=100.000000 -MAXITER=0 -NOUNDERGROUND=1
	saga_cmd grid_tools 12 -INPUT="$tdir/vdcn_$order.sgrd" -OUTPUT="$tdir/vdcn_$order.sgrd" -METHOD=1 -RANGE="$LUT"

	Trim_gdalwarp_byte "$wclip" "$bufferB" "$tdir/strordr_$order.sdat" "$wout/strordr_$order.tif"
	Trim_gdalwarp "$wclip" "$bufferB" "$tdir/vdcn_$order.sdat" "$wout/vdcn_$order.tif"
	Trim_gdalwarp "$wclip" "$bufferB" "$tdir/bl_$order.sdat" "$wout/bl_$order.tif"

done


echo "$(date +%F\ %H:%M:%S): starting valley depth" 
# Valley Depth
for order in ${orders[@]}; do
    tfile="$wout/rdgh_$order.tif"
    if ! validate_gdal_files "$tfile"; then
		saga_cmd ta_channels 7 -ELEVATION="$wsgrd" -VALLEY_DEPTH="$tdir/vd_$order.sgrd" -RIDGE_LEVEL="$tdir/rdgh_$order.sgrd" -THRESHOLD=100.000000 -MAXITER=0 -NOUNDERGROUND=1 -ORDER="$order"
		Trim_gdalwarp "$wclip" "$bufferB" "$tdir/rdgh_$order.sdat" "$tfile"
    fi

	tfile="$wout/vd_$order.tif"
	if ! validate_gdal_files "$tfile"; then
		saga_cmd grid_tools 12 -INPUT="$tdir/vd_$order.sgrd" -OUTPUT="$tdir/vd_$order.sgrd" -METHOD=1 -RANGE="$LUT"
		Trim_gdalwarp "$wclip" "$bufferB" "$tdir/vd_$order.sdat" "$tfile"
	fi
done

echo "$(date +%F\ %H:%M:%S): starting potential solar radiation" 
# Potential Incoming Solar Radiation. It would be nice to checkpoint both diffuse and direct, but it takes so very long. 
declare -a days=("2021-01-22" "2021-02-22" "2021-03-22" "2021-04-22" "2021-05-22" "2021-06-22" "2021-07-22" "2021-08-22" "2021-09-22" "2021-10-22" "2021-11-22" "2021-12-22")
for day in ${days[@]}; do
	tfile="$wout/pisrdif_$day.tif"
	if ! validate_gdal_files "$tfile"; then
		saga_cmd ta_lighting 2 -GRD_DEM="$wsgrd" -GRD_DIRECT="$tdir/pisrdir_$day.sdat" -GRD_DIFFUS="$tdir/pisrdif_$day.sdat" -SOLARCONST=1367.000000 -LOCALSVF=1 -UNITS=0 -SHADOW=1 -LOCATION=1 -PERIOD=1 -HOUR_RANGE_MIN=0.000000 -HOUR_RANGE_MAX=24.000000 -HOUR_STEP=4.000000 -METHOD=2 -LUMPED=70.000000 -DAY="$day" 
	
		Trim_gdalwarp "$wclip" "$bufferB" "$tdir/pisrdir_$day.sdat" "$wout/pisrdir_$day.tif"
		Trim_gdalwarp "$wclip" "$bufferB" "$tdir/pisrdif_$day.sdat" "$tfile"
	fi
done


echo "$(date +%F\ %H:%M:%S): starting mass balance index" 
# Mass Balance Index
declare -a tcurves=("0.001" "0.01" "0.1")
for tcurve in ${tcurves[@]}; do
	tfile="$wout/mbi_$tcurve.tif"
	if ! validate_gdal_files "$tfile"; then
		saga_cmd ta_morphometry 10 -DEM="$wsgrd" -MBI="$tdir/mbi_$tcurve.sgrd" -TSLOPE=15.0 -TCURVE="$tcurve"
		Trim_gdalwarp "$wclip" "$bufferB" "$tdir/mbi_$tcurve.sdat" "$tfile"
	fi

done 


echo "$(date +%F\ %H:%M:%S): starting convergence index"
#Convergence Index
for nbr in ${neighbors[@]}; do 
	tfile="$wout/ci_$nbr.tif"
	if ! validate_gdal_files "$tfile"; then
		saga_cmd ta_morphometry 2 -ELEVATION="$wsgrd" -CONVERGENCE="$tdir/ci_$nbr.sgrd" -SLOPE=0 -DIFFERENCE=0 -DISTANCE_WEIGHTING_DW_WEIGHTING=0 -RADIUS="$nbr" 
		Trim_gdalwarp "$wclip" "$bufferB" "$tdir/ci_$nbr.sdat" "$tfile"
	fi 
	
done 


echo "$(date +%F\ %H:%M:%S): starting vector ruggedness measure"
# Vector Ruggedness Measure
for nbr in ${neighbors[@]}; do
	tfile="$wout/vrm_$nbr.tif"
	if ! validate_gdal_files "$tfile"; then
		saga_cmd ta_morphometry 17 -DEM="$wsgrd" -VRM="$tdir/vrm_$nbr.sgrd" -MODE=0 -DW_WEIGHTING=0 -RADIUS="$nbr" 
		Trim_gdalwarp "$wclip" "$bufferB" "$tdir/vrm_$nbr.sdat" "$tfile"
	fi 
	
done

# Cleanup Temp Files
rm -rf "$tdir"

#Print elapsed time
duration=$SECONDS
echo "It took $(($duration / 60)) minutes and $(($duration % 60)) seconds to complete Saga2."