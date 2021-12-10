# STED30
Code used to build continental-scale terrain variables:

This was run on NMSU's Discovery HPC.
The following moduals(and associated dependencies) must be available to run the code:
geos/3.8.1
gdal/3.2.0
saga-gis/7.9.0

Preprocessing: 
A large-scale DEM in geotif format should be tiled. Tiling should performed using a buffered area to avoid edge contamination during variable calculation. We chose to buffer each tile by 4 km. Each DEM tile processed with the TauDEM pit remove tool to fill sinks. We also chose to smooth the DEM during preprocessing. The filled and smoothed DEM tiles should be in .tif format and named as tilefelsm.tif where tile is the tile name and felsm is added during the filling and smoothing (e.g., 010100felsm.tif). 

Each filled and smoothed tile should be placed in it's own directory. Each directory should contain the filled and smoothed DEM and a shapefile of the tile. The shapefile should NOT be buffered. It is VITAL to this code that the directory, DEM, and shapefile all have the same tile name (e.g., for the HUC6 tile 010100 there should be a directory named 010100 and within this directory there should be a DEM named 010100felsm.tif and a shapefile named 010100.shp). [the felsm DEM tile filenaming requirement can be modified or removed on line 47 of submit.sh]


Elevation Derivative Calculation: 
submit.sh - this submits a SLURM job and calls other .sh files to do the acutal calculations
 convert.sh - called by submit.sh, this converts the DEM tif file to the format requried by SAGA, then 
 common.sh  - called by submit.sh, a series of functions for trimming edges from and compressing derivatives, and for error checking. 
 saga1.sh   - called by submit.sh, this file does the actual calculations*; focalStats, releative elevation, TPI
 saga2.sh   - called by submit.sh, this file does the actual calculations*; vdcn, vd, PISR, mbi, ci, vrm
 saga3.sh   - called by submit.sh, this file does the actual calculations*; swi, twi, spi, openness, dif openness, hillshade, dah, geomorphons
 saga4.sh   - called by submit.sh, this file does the actual calculations*, morphometric features, tri, tsc
  * The calculations in these files were balanced to that each call took about the same time. This maximized computational efficienecy. 
 lut_reclass.txt - called by saga 2 to convert negative values of vdcn or vd to zero. This is just some error correcting. 

The above code serially iterates over each watershed, but the actual elevation derivative calculations are computed in parallel. To parallel compute multiple watersheds I grouped each watershed by HUC2's then submitted each HUC2 as a job. Since I could submit up to 10 jobs at one time, I had 10 watersheds calculating at once. 


Mosaicing: 
submit_mosaic_integer.sh - submits a SLURM job to mosaic integer format terrain variables
 mosaic_integer.sh - called by submit_mosaic_integer.sh; has compression options for integer format derivatives, without this option gdal_translate throws an error
 mosaic_filenames1_integer.csv - integer format filenames to mosaic

submit_mosaic.sh - submits a SLURM job to mosaic floating point format terrain variables
 mosaic.sh - called by submit_mosaic.sh; finds all file names in a .csv file, then mosaics each file and adds overviews
  mosaic_filenames2.csv - floating point format filenames to mosaic*
  mosaic_filenames3.csv - floating point format filenames to mosaic*
  mosaic_filenames4.csv - floating point format filenames to mosaic*
  mosaic_filenames5.csv - floating point format filenames to mosaic*
  mosaic_filenames6.csv - floating point format filenames to mosaic*
  mosaic_filenames7.csv - floating point format filenames to mosaic*
  mosaic_filenames8.csv - floating point format filenames to mosaic*
  mosaic_filenames9.csv - floating point format filenames to mosaic*
   * by splitting the list of filenames into 10 .csv files I was able to submit each as a job and thereby parallelize the mosaicing process. 

move.sh - moves all mosaiced files into a single folder for better file management. 

mosaic_filenames.csv - the full list of filenames. Retained for archival purposes. 

Transfer to google
file_transfer.txt - explains how to transfer files to google. 


tdl8r (for 10m variables); 
1. keep everything in .sgrd format during processing this will reduce the number of resampling steps needed. 
2. make mosaics in COG format. 
3. Prarie potholes, karst, and other real depressions. - If I can get a raster of these then I could use it to not fill these real sinks during DEM pit remove 
4. A more efficient way to do this computation would be to find a computer with more nodes and submit each watershed as an indivudal job (could probaby be done with SLURM job arrays). 
