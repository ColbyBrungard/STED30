#!/bin/bash

set -x

# Source common functions and variables
source ./common.sh

# Get Arguments
wsgrd="$1" # Watershed sgrd file path
wclip="$2" # Watershed clip file path
wout="$3" # Watershed output directory path

# Output Directories
tdir="$wout/saga3_temp" # temp directory
mkdir -p "$tdir"

# Set common input parameters
declare -a neighbors=("2" "4" "8" "16" "32")

#Set up timer
SECONDS=0

echo "$(date +%F\ %H:%M:%S): starting saga wetness index" 
# Saga wetness index, catchment area, modified catchment area, and catchment slope. 
#Note: using different suctions results in creating the catchment area and catchment slope twice, but it is relativley quick. 
# Since the output is the same, the catchment area and slope from the second run overwrites the output from the first run.  
# Checkpointing individual files is inefficient since mca takes so long to calculate
declare -a suction=("10" "10000")
for suc in ${suction[@]}; do
	tfile="$wout/swi_$suc.tif"
	if ! validate_gdal_files "$tfile"; then
		saga_cmd ta_hydrology 15 -DEM="$wsgrd" -WEIGHT=NULL -AREA="$tdir/ca.sgrd" -SLOPE="$tdir/cs.sgrd" -AREA_MOD="$tdir/mca_$suc.sgrd" -TWI="$tdir/swi_$suc.sgrd" -AREA_TYPE=2 -SLOPE_TYPE=0 -SLOPE_MIN=0.000000 -SLOPE_OFF=0.010000 -SLOPE_WEIGHT=1.000000 -SUCTION="$suc" 
	
		Trim_gdalwarp "$wclip" "$bufferB" "$tdir/ca.sdat" "$wout/ca.tif"
		Trim_gdalwarp "$wclip" "$bufferB" "$tdir/cs.sdat" "$wout/cs.tif"
		Trim_gdalwarp "$wclip" "$bufferB" "$tdir/mca_$suc.sdat" "$wout/mca_$suc.tif"
		Trim_gdalwarp "$wclip" "$bufferB" "$tdir/swi_$suc.sdat" "$tfile"
	fi
done 


echo "$(date +%F\ %H:%M:%S): starting topographic wetness index and stream power index" 
# Topographic wetness index and stream power index
tfile="$wout/slopeRadians.tif"
if ! validate_gdal_files "$tfile"; then
	saga_cmd ta_morphometry 0 -ELEVATION="$wsgrd" -SLOPE="$tdir/slopeRadians.sgrd" -METHOD=6 -UNIT_SLOPE=0
	Trim_gdalwarp "$wclip" "$bufferB" "$tdir/slopeRadians.sdat" "$wout/slopeRadians.tif"
fi 

tfile="$wout/twi.tif"
if ! validate_gdal_files "$tfile"; then
	saga_cmd ta_hydrology 20 -SLOPE="$tdir/slopeRadians.sgrd" -AREA="$tdir/ca.sgrd" -TWI="$tdir/twi.sgrd" -TRANS=NULL -CONV=0 -METHOD=0
	Trim_gdalwarp "$wclip" "$bufferB" "$tdir/twi.sdat" "$tfile"
fi
	
tfile="$wout/spi.tif"
if ! validate_gdal_files "$tfile"; then
	saga_cmd ta_hydrology 21 -SLOPE="$tdir/slopeRadians.sgrd" -AREA="$tdir/ca.sgrd" -SPI="$tdir/spi.sgrd" -CONV=0
	Trim_gdalwarp "$wclip" "$bufferB" "$tdir/spi.sdat" "$tfile"
fi


echo "$(date +%F\ %H:%M:%S): starting topographic openness" 
# Positive Topographic Openness
# note: linux implementation does not seem to have option for -unit so units default to radians (-UNIT=1 would be degrees), nor does it have an option for -NADIR=1.
declare -a radialLimit=("2" "32" "256")
for r in ${radialLimit[@]}; do
	tfile="$wout/po_$r.tif"
	if ! validate_gdal_files "$tfile"; then
		saga_cmd ta_lighting 5 -DEM="$wsgrd" -POS="$tdir/po_$r.sgrd" -METHOD=1 -NDIRS=8  -RADIUS="$r"
		Trim_gdalwarp "$wclip" "$bufferB" "$tdir/po_$r.sdat" "$tfile"
	fi

	tfile="$wout/no_$r.tif"
	if ! validate_gdal_files "$tfile"; then	
		saga_cmd ta_lighting 5 -DEM="$wsgrd" -NEG="$tdir/no_$r.sgrd" -METHOD=1 -NDIRS=8  -RADIUS="$r"
		Trim_gdalwarp "$wclip" "$bufferB" "$tdir/no_$r.sdat" "$tfile"
	fi 

done


echo "$(date +%F\ %H:%M:%S): starting differential openness" 
# Differential Openness
for r in ${radialLimit[@]}; do
	tfile="$wout/diffopen_$r.tif"
	if ! validate_gdal_files "$tfile"; then
		saga_cmd grid_calculus 3 -A="$tdir/po_$r.sgrd" -B="$tdir/no_$r.sgrd" -C="$tdir/diffopen_$r.sgrd"
		Trim_gdalwarp "$wclip" "$bufferB" "$tdir/diffopen_$r.sdat" "$tfile"
	fi
done


echo "$(date +%F\ %H:%M:%S): starting analytical hillshade"
#analytical hillshade 
tfile="$wout/hs_st.tif"
if ! validate_gdal_files "$tfile"; then
	saga_cmd ta_lighting 0 -ELEVATION="$wsgrd" -SHADE="$tdir/hs_stA.sgrd" -METHOD=0 -POSITION=0 -AZIMUTH=335.000000 -DECLINATION=45.000000 -EXAGGERATION=1.000000 -UNIT=1
	Trim_gdalwarp "$wclip" "$bufferB" "$tdir/hs_stA.sdat" "$tfile"
fi

tfile="$wout/hs_cs.tif"
if ! validate_gdal_files "$tfile"; then
	saga_cmd ta_lighting 0 -ELEVATION="$wsgrd" -SHADE="$tdir/hs_csA.sgrd" -METHOD=5 -POSITION=0 -AZIMUTH=335.000000 -DECLINATION=45.000000 -EXAGGERATION=1.000000 -UNIT=1
	Trim_gdalwarp "$wclip" "$bufferB" "$tdir/hs_csA.sdat" "$tfile"
fi


echo "$(date +%F\ %H:%M:%S): starting Diurnal Anisotropic Heating"
#Diurnal Anisotropic Heating 
tfile="$wout/dah.tif"
if ! validate_gdal_files "$tfile"; then	
	saga_cmd ta_morphometry 12 -DEM="$wsgrd" -DAH="$tdir/dahA.sgrd" -ALPHA_MAX=225	
	Trim_gdalwarp "$wclip" "$bufferB" "$tdir/dahA.sdat" "$tfile"
fi 


echo "$(date +%F\ %H:%M:%S): starting Geomorphons multiscale"
# Geomorphons multiscale
declare -a geomorph_M=("30" "300")
for M in ${geomorph_M[@]}; do
	tfile="$wout/gmrph_ms_$M.tif"
    if ! validate_gdal_files "$tfile"; then
		saga_cmd ta_lighting 8 -DEM="$wsgrd" -GEOMORPHONS="$tdir/gmrph_ms_$M.sgrd" -THRESHOLD=1.000000 -METHOD=0 -DLEVEL="$M"
		Trim_gdalwarp_byte "$wclip" "$bufferB" "$tdir/gmrph_ms_$M.sdat" "$tfile"
	fi 
	
done


echo "$(date +%F\ %H:%M:%S): starting Geomorphons radius"
# Geomorphons radius
declare -a geomorph_L=("30" "300" "3000")
for L in ${geomorph_L[@]}; do
	tfile="$wout/gmrph_r_$L.tif"
    if ! validate_gdal_files "$tfile"; then
		saga_cmd ta_lighting 8 -DEM="$wsgrd" -GEOMORPHONS="$tdir/gmrph_r_$L.sgrd" -THRESHOLD=1.000000 -METHOD=1 -RADIUS="$L" 
		Trim_gdalwarp_byte "$wclip" "$bufferB" "$tdir/gmrph_r_$L.sdat" "$tfile"
	fi 
	
done


# Cleanup Temp Files
rm -rf "$tdir"

#Print elapsed time
duration=$SECONDS
echo "It took $(($duration / 60)) minutes and $(($duration % 60)) seconds to complete Saga3."