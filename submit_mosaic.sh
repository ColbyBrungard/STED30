#!/bin/bash

#SBATCH --job-name mosiac
#SBATCH --output slurm-%j.out
#SBATCH --ntasks=5
#SBATCH --cpus-per-task=2
#SBATCH --mem-per-cpu=32G
#SBATCH --partition=backfill
#SBATCH --time=14-1:00:00

module load gdal
module load geos

## Run Command:
# sbatch submit_mosaic.sh "input CSV file"

# Echo Commands
set -x

# Set Output Directory
desFol="mosaicedgirds_j${SLURM_JOB_ID}"
mkdir -p "$desFol"

# Set Log Directory
logFol="$desFol/logs"
mkdir -p "$logFol"

# Get Data From CSV File
csv_file="$1"
if [ -z "$csv_file" ]; then
	echo "input CSV file not specified! Stopping Run!!"
	exit 1
fi

csv_data="$(cat "$csv_file")"

for line in $csv_data ; do
    # Limit Number of Background Srun commands
    while [ "$(jobs -p | wc -l)" -ge "$SLURM_NTASKS" ]; do
        sleep 30s
    done

    # Get Mosiac File Name For Log File
    name="$(echo "$line" | awk -F',' '{print $1}' | sed 's/\.tif//')"

    # spinup task to mosiac line
    if [ ! -f "$desFol/$name.tif" ] || ! gdalinfo "$desFol/$name.tif" &>/dev/null; then
        srun --ntasks=1 --nodes=1 --exclusive ./mosaic.sh "$line" "$desFol" &> "${logFol}/mosaic.${name}.out" &
    fi
done

wait