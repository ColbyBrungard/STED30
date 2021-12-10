#!/bin/bash

#SBATCH --job-name geoproc   ## name that will show up in the queue
#SBATCH --output slurm-rerun%j.out   ## filename of the output; the %j is equal to jobID; default is slurm-[jobID].out
#SBATCH --ntasks=4  ## number of tasks (analyses) to run
#SBATCH --cpus-per-task=24  ## the number of threads allocated to each task
#SBATCH --mem-per-cpu=1000M   # memory per CPU core
#SBATCH --partition=backfill  ## the partitions to run in (comma seperated)
#SBATCH --requeue ## must be included to use backfill
#SBATCH --time=14-00:00:00  ## time for analysis (day-hour:min:sec)
##SBATCH --nodelist=discovery-c[16-35],discovery-g[2-15],discovery-hhm1,discovery-hm1
#SBATCH --mail-user cbrung@nmsu.edu
#SBATCH --mail-type ALL

## Run Command:
# sbatch submit.sh "input data dir path" "desired output path"

## Load modules
module load saga-gis/7.9.0-gcc-9.3.0-openmpi-nc2xynr
module load gdal/3.2.0-gcc-9.3.0-openmpi-2linbii
module load geos/3.8.1-gcc-9.3.0-5msky2f

# Echo bash commands
set -x

## Get input data directory (watershed tif + shp files)
datadir="$1"
if [ -z "$datadir" ]; then
	echo "input data directory not specified! Stopping Run!!"
	exit 1
fi

## Get Desired Output Directory
outdir="$2"
if [ -z "$outdir" ]; then
	echo "output data directory not specified! Stopping Run!!"
	exit 2
fi
mkdir -p "$outdir"

## Insert code, and run your programs here (use 'srun').
for watershed in $datadir/*.tif ; do
	# Get name of file without path or extension. 
	# "name1" is the full file name that matches the watershed shapefile name. 
	# "name" is the watershed with 'fel' removed from the file name. This just makes the output more sensible so I don't have to rename a whole bunch of files. 
	name1="$(basename "${watershed%.*}")"
	name="$(echo "$name1" | sed 's/felsm//')"	

	# Check if watershed has already been done	
	if [ -f "$outdir/$name.finished" ]; then
		echo "Watershed '$name' already completed! Skipping!!"
		continue
	fi

	echo "$(date +%F\ %H:%M:%S): Starting Watershed - $name"

	# Set watershed output directory
	wout="$outdir/$name"
	mkdir -p "$wout"

	# Get clip file
	pdir="$(dirname "$watershed")"
	clipfile="$pdir/$name.shp"
	
	# Convert tif to sdat/sgrd
	sdat="$wout/$name.sdat"
	if [ ! -f "$sdat" ] || [ ! -f "$wout/$name.tif" ]; then
		srun --ntasks=1 --nodes=1 --exclusive ./convert.sh "$watershed" "$clipfile" "$sdat" >> "$wout/$name.convert.j${SLURM_JOB_ID}.out" 2>&1
	fi

	# Run Saga calculations in parallel. Needs .sgrd
	sgrd="$wout/$name.sgrd"
	LUT="$datadir/lut_reclass.txt"
	srun --ntasks=1 --nodes=1 --exclusive ./saga1.sh "$sgrd" "$clipfile" "$wout" >> "$wout/$name.saga1.j${SLURM_JOB_ID}.out" 2>&1 &
	srun --ntasks=1 --nodes=1 --exclusive ./saga2.sh "$sgrd" "$clipfile" "$wout" "$LUT" >> "$wout/$name.saga2.j${SLURM_JOB_ID}.out" 2>&1 &
	srun --ntasks=1 --nodes=1 --exclusive ./saga3.sh "$sgrd" "$clipfile" "$wout" >> "$wout/$name.saga3.j${SLURM_JOB_ID}.out" 2>&1 &
	srun --ntasks=1 --nodes=1 --exclusive ./saga4.sh "$sgrd" "$clipfile" "$wout" >> "$wout/$name.saga4.j${SLURM_JOB_ID}.out" 2>&1 &

	# Wait for all parallel tasks to complete
	wait

	# Compress Results
	# Compression took many hours and did not save any space so this step commented out
	#tar -cJf "$outdir/$name.tar.xz" "$wout"
	touch "$outdir/$name.finished"

	echo "$(date +%F\ %H:%M:%S): Finished Watershed - $name"
done

# Remove Finished Files
rm -f $outdir/*.finished

