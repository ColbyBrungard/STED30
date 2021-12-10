#!/bin/bash

#SBATCH --job-name movef   ## name that will show up in the queue
#SBATCH --output slurm-%j.out   ## filename of the output; the %j is equal to jobID; default is slurm-[jobID].out
#SBATCH --ntasks=1  ## number of tasks (analyses) to run
#SBATCH --cpus-per-task=2  ## the number of threads allocated to each task
#SBATCH --mem-per-cpu=1000M   # memory per CPU core
#SBATCH --partition=interactive  ## the partitions to run in (comma seperated)
##SBATCH --requeue ## must be included to use backfill
#SBATCH --time=01-00:00:00  ## time for analysis (day-hour:min:sec)
##SBATCH --nodelist=discovery-c[16-35],discovery-g[2-15],discovery-hhm1,discovery-hm1
#SBATCH --mail-user cbrung@nmsu.edu
#SBATCH --mail-type ALL

         
mv mosaicedgirds_j1585219/*.tif /home/cbrung/CONUS  
mv mosaicedgirds_j1585220/*.tif /home/cbrung/CONUS  
mv mosaicedgirds_j1585226/*.tif /home/cbrung/CONUS  
mv mosaicedgirds_j1585227/*.tif /home/cbrung/CONUS          
mv mosaicedgirds_j1585237/*.tif /home/cbrung/CONUS          
mv mosaicedgirds_j1585221/*.tif /home/cbrung/CONUS   
mv mosaicedgirds_j1585222/*.tif /home/cbrung/CONUS   
mv mosaicedgirds_j1585223/*.tif /home/cbrung/CONUS   
mv mosaicedgirds_j1585224/*.tif /home/cbrung/CONUS   
mv mosaicedgirds_j1585225/*.tif /home/cbrung/CONUS  
