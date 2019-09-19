source('f.R'); library(insol); library(rlist)
library(raster); library(chron); library(shadow)
library(stringr); library(lubridate); library(sp)
library(rgdal); library(shadow); library(rgeos)
library(dplyr); library(xlsx)

#------------------------------------------------------------------------------
#PARAMETERS
DEM <- raster("./layers/DEM.tif")
DEMcontour <- readOGR("./layers/layers.gpkg", "contour")
shader <- readOGR("./layers/layers.gpkg", "points_buffer_100m")
houses <- readOGR("./layers/layers.gpkg", "asentamientos")
outdir <- "./output/"
TZ <- "Europe/Berlin"
annual <- TRUE #it does from 1/1(YYYY[1]) to 31/12/AAAA[1]
annualby <- 'hour'
YYYY <- c(2019); MM <- c(1,7); DD <- c(1)
eachmin <- 60
filterSunriseSunset <- FALSE #(NOT DONE YET)

# COMPUTER SIMULATION IN WINDPRO
# Coordinates and specifications of the dwellings;
# Coordinates and specifications of the proposed wind turbines;
# Coordinates and specifications of surrounding wind turbines, if any
# Flicker scenario (worst or real case);
# Specific year;
# Wind speed and direction data (if real case);
# Sunshine probability data (if real case);
# Height contour lines (if topographic shadow used);
# Obstacles coordinates and size, if any.

## PARAMETERS OF ROTORS
turbines <- readOGR("./layers/layers.gpkg", "points")
Rdiam <- 136 #rotor diameter in m
Rh <- 112 #rotor height
cutin <- 3 #cut-in wind speed (m/s)
cutout <- 25 #cut-out wind speed (m/s)
Rspeed <- 14 #RPM

## Shadow receptor
# mode <- "single dir" #single direction mode
mode <- "green house" #means that windows are penpendicular to all WTGs
Wh <- 1 #window height in m
Ww <- 1 #window width in m

## Simulation parameters
scenario <- "worst case"
# scenario <- "real case"

#ZVI (intervisibility to reduce elements in calc)
Eh <- 1.8 #eye height 

## RESULTS TO ACHIEVE IN WINDPRO
### Receptor name (id)
### Shadow days per year (days)
### Max Shados hours per day (hh:mm)
### Shadow hours per year (Real Case)
### Shadow hours per year (Worst Case)
### Nearest Windy points turbine

### SHADOW FLICKER MAPS

#-------------------------------------------------------------------------------
#DEM TO CONTOUR
plot(DEM)
plot(rasterToContour(DEM,z=1))
