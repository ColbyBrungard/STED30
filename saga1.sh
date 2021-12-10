#!/bin/bash

set -x

# Source common functions and variables
source ./common.sh

# Get Arguments
wsgrd="$1" # Watershed sgrd file path
wclip="$2" # Watershed clip file path
wout="$3" # Watershed output directory path

# Output Directories
tdir="$wout/saga1_temp" # temp directory
mkdir -p "$tdir"

# Set common input parameters
declare -a neighbors=("2" "4" "8" "16" "32")

# Trim_gdalwarp "clip file path" "buffer value" "input file" "output file"

#Set up timer
SECONDS=0

echo "$(date +%F\ %H:%M:%S): starting Focal Statistics" 
# Focal Statistics. It is possible to calculate these all together in one call, but doing so prohibits checkpointing and these are the files that got corrupted.
for nbr in ${neighbors[@]}; do

	tfile="$wout/meanelev_$nbr.tif"
    if ! validate_gdal_files "$tfile"; then 
		saga_cmd statistics_grid 1 -GRID="$wsgrd" -MEAN="$tdir/meanelev_$nbr.sgrd"  -BCENTER=1 -MODE=0 -DISTANCE_WEIGHTING_DW_WEIGHTING=0 -RADIUS="$nbr" 
		Trim_gdalwarp "$wclip" "$bufferB" "$tdir/meanelev_$nbr.sdat" "$tfile"
	fi

	tfile="$wout/minelev_$nbr.tif"
    if ! validate_gdal_files "$tfile"; then 
		saga_cmd statistics_grid 1 -GRID="$wsgrd" -MIN="$tdir/minelev_$nbr.sgrd" -BCENTER=1 -MODE=0 -DISTANCE_WEIGHTING_DW_WEIGHTING=0 -RADIUS="$nbr" 
		Trim_gdalwarp "$wclip" "$bufferB" "$tdir/minelev_$nbr.sdat" "$tfile"
	fi

	tfile="$wout/diffmeanelev_$nbr.tif"
    if ! validate_gdal_files "$tfile"; then	
		saga_cmd statistics_grid 1 -GRID="$wsgrd" -DIFF="$tdir/diffmeanelev_$nbr.sgrd" -BCENTER=1 -MODE=0 -DISTANCE_WEIGHTING_DW_WEIGHTING=0 -RADIUS="$nbr" 
		Trim_gdalwarp "$wclip" "$bufferB" "$tdir/diffmeanelev_$nbr.sdat" "$tfile"
	fi

	tfile="$wout/devmeanelev_$nbr.tif"
    if ! validate_gdal_files "$tfile"; then	
		saga_cmd statistics_grid 1 -GRID="$wsgrd" -DEVMEAN="$tdir/devmeanelev_$nbr.sgrd" -BCENTER=1 -MODE=0 -DISTANCE_WEIGHTING_DW_WEIGHTING=0 -RADIUS="$nbr" 
		Trim_gdalwarp "$wclip" "$bufferB" "$tdir/devmeanelev_$nbr.sdat" "$tfile"
	fi

	tfile="$wout/stddevelev_$nbr.tif"
    if ! validate_gdal_files "$tfile"; then	
		saga_cmd statistics_grid 1 -GRID="$wsgrd" -STDDEV="$tdir/stddevelev_$nbr.sgrd" -BCENTER=1 -MODE=0 -DISTANCE_WEIGHTING_DW_WEIGHTING=0 -RADIUS="$nbr" 
		Trim_gdalwarp "$wclip" "$bufferB" "$tdir/stddevelev_$nbr.sdat" "$tfile"
	fi

	tfile="$wout/perctelev_$nbr.tif"
    if ! validate_gdal_files "$tfile"; then	
		saga_cmd statistics_grid 1 -GRID="$wsgrd" -PERCENT="$tdir/perctelev_$nbr.sgrd" -BCENTER=1 -MODE=0 -DISTANCE_WEIGHTING_DW_WEIGHTING=0 -RADIUS="$nbr" 
		Trim_gdalwarp "$wclip" "$bufferB" "$tdir/perctelev_$nbr.sdat" "$tfile"
	fi

done


echo "$(date +%F\ %H:%M:%S): starting relative elevation" 
# Grid Difference between min and mean with base elevation to get relative elevation
for nbr in ${neighbors[@]}; do
	tfile="$wout/relelev_$nbr.tif"
    if ! validate_gdal_files "$tfile"; then
		saga_cmd grid_calculus 3 -A="$wsgrd" -B="$tdir/minelev_$nbr.sgrd" -C="$tdir/relelev_$nbr.sgrd"
		Trim_gdalwarp "$wclip" "$bufferB" "$tdir/relelev_$nbr.sdat" "$tfile"
	fi

	tfile="$wout/relmeanelev_$nbr.tif"
    if ! validate_gdal_files "$tfile"; then
		saga_cmd grid_calculus 3 -A="$wsgrd" -B="$tdir/meanelev_$nbr.sgrd" -C="$tdir/relmeanelev_$nbr.sgrd"
		Trim_gdalwarp "$wclip" "$bufferB" "$tdir/relmeanelev_$nbr.sdat" "$tfile"
	fi

done


echo "$(date +%F\ %H:%M:%S): starting topographic position index" 
# MultiScale Topographic Position Index
declare -a maxscale=("2" "32")
for mx in ${maxscale[@]}; do 
	tfile="$wout/tpi_$mx.tif"
    if ! validate_gdal_files "$tfile"; then
		saga_cmd ta_morphometry 28 -DEM="$wsgrd" -TPI="$tdir/tpi_$mx.sgrd" -SCALE_MIN=1 -SCALE_NUM=2 -SCALE_MAX="$mx"
		Trim_gdalwarp "$wclip" "$bufferB" "$tdir/tpi_$mx.sdat" "$tfile"
	fi
	
done


# Cleanup Temp Files
rm -rf "$tdir"

#Print elapsed time
duration=$SECONDS
echo "It took $(($duration / 60)) minutes and $(($duration % 60)) seconds to complete Saga1."