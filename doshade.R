source('f.R'); library(insol); library(rlist)
library(raster); library(chron); library(shadow)
library(stringr); library(lubridate); library(sp)
library(rgdal); library(shadow); library(rgeos)
library(dplyr); library(xlsx)

#------------------------------------------------------------------------------
#PARAMETERS
DEM <- raster("./layers/DEM.tif")
shader <- readOGR("./layers/layers.gpkg", "points_buffer_100m")
houses <- readOGR("./layers/layers.gpkg", "asentamientos")
outdir <- "./output/"
TZ <- "Europe/Berlin"
annual <- TRUE #it does from 1/1(YYYY[1]) to 31/12/AAAA[1]
annualby <- 'hour'
YYYY <- c(2019); MM <- c(1,7); DD <- c(1)
eachmin <- 60
filterSunriseSunset <- FALSE #(NOT DONE YET)

#-------------------------------------------------------------------------------
# MODIFIED RASTER --> DEMm
# DEM + the shader element (in this case a wind turbine)
shader$alt <- 180 #add alt to shader 
#la altura del objeto puede mejorarse considerando anillos a distintas alturas

rpoly <- raster(ncol = ncol(DEM), nrow = nrow(DEM))#rasterize
extent(rpoly) <- extent(DEM)
DEMm <- rasterize(shader, rpoly, 'alt')
DEMm[is.na(DEMm[])] <- 0    # replacing NA's by zero
DEMm <- DEM+DEMm #raster DEM + artifact

#-------------------------------------------------------------------------------
#GET COORDS FROM MIDPOINT FROM EXTENSION
x <- midPoint(DEM)[[1]]
y <- midPoint(DEM)[[2]]

#calculat tSeries (from personal function)
if (annual == TRUE){
    ts <- seq(from = ISOdate(YYYY[1],1,1,0,0,0,tz = TZ),
              to = ISOdate(YYYY[1],12,31,23,59,59,tz = TZ),
              by=annualby)
} else {
    ts <- tSeries(YYYY,MM,DD,eachmin,TZ)
}

#ts to julian days
tsjd <- JD(ts)
sp <- sunpos(sunvector(tsjd,y,x,0)) ## sun position

#FILTER TIMES TO CALCULATE --> daylight zenith<=90 
#IMPROVE THIS, BASED ON DALYLENGTH MUCH BETTER
if (filterSunriseSunset == TRUE){
    ts <- ts[which(sp[,2]<=90)]
    tsjd <- tsjd[which(sp[,2]<=90)]
    sp <- sp[which(sp[,2]<=90),] #(NOT USED YET...)
}

#calculate daylength
daylength(y,x,tsjd,0)

#-------------------------------------------------------------------------------
#DOSHADE AND CREATE RASTER STACK FOR DEM
#remember:doshade makes 1 as inlight and 0 inshadow, in case you wants to imitate
#grass r.sunmask.position you have to invert values
r <- stack()
for (t in 1:length(ts)){
    print(ts[t])
    sv <- sunvector(tsjd[t],y,x,0) #sunvector
    sh <- doshade(DEM,sv)
    r <- stack(r,sh)
}

#rename raster stack
names(r) <- AAAAMMDD_HHmmss(ts)

#-------------------------------------------------------------------------------
#DOSHADE AND CREATE RASTER STACK FOR DEMm
#remember:doshade makes 1 as inlight and 0 inshadow, in case you wants to imitate
#grass r.sunmask.position you have to invert values
rm <- stack()
for (t in 1:length(ts)){
    print(ts[t])
    sv <- sunvector(tsjd[t],y,x,0) #sunvector
    sh <- doshade(DEMm,sv)
    rm <- stack(rm,sh)
}

#rename raster stack
names(rm) <- AAAAMMDD_HHmmss(ts)

#-------------------------------------------------------------------------------
# DEMdif
# 0 is shadow and 1 is light and it will reversed after this
# plot(rm[[18]])
# plot(r[[18]])
# plot(abs(rm[[18]]-r[[18]])) #this plots the difference and revere value 

DEMdif <- stack()
for (t in 1:length(ts)){
    DEMdif <- stack(DEMdif,abs(rm[[t]]-r[[t]])) #reversed diff
}

names(DEMdif) <- AAAAMMDD_HHmmss(ts)

#-------------------------------------------------------------------------------
# DEMdif
# PODRIAN CALCULARSE SIMPLEMENTE LAS NUEVAS AREAS BARRIDAS POR LA SOMBRA DE LOS AEROS

#-------------------------------------------------------------------------------
# SAMPLE DEM WITH CENTROIDS
## Make centroids
h <- SpatialPointsDataFrame(gCentroid(houses, byid=TRUE), 
                                      houses@data, match.ID=FALSE)
## Sample DEMdif
flicker <- extract(DEMdif, h)

#-------------------------------------------------------------------------------
# CALCULATE RESULTS BY ID
##  METHOD OF SUMMARY IN A LIST
### 1. Iterate each row
### 2. Create a list of colnames (date_time) where value is 1
### 3. Get list of lists. Each list contains
        #- The id of the house
        #- The list of date_times where flicker occurs
        #- The count of flicker hours
flickersummlist <- list()
for (r in 1:nrow(flicker)){
    #create a datatime list for each row where value is 1
    dtlist <- list()
    for (dt in 1:ncol(flicker)){
        if (flicker[r,dt] == 1){
            dtlist <- c(dtlist, format(ts[dt])) #in this format can be added more info EST, CEST...
        }
    }
    #create counter and modify dtlist
    if(!length(dtlist)){counterlist = 0; dtlist=0} else {counterlist = length(dtlist)}

    #create vector with values: id, dtlist and total hours
    idsummary <- list(h['id'][[1]][r],
                   counterlist*(eachmin/60),
                   dtlist)
    
    #append results to flickersumm
    flickersummlist[r] <- list(idsummary)

}

## Create a data frame based on list
flickerdf = data.frame(matrix(vector(), nrow(flicker), 3,
                              dimnames=list(c(), c("id", "flickhours", "dtlist"))),
                       stringsAsFactors=F)
for (e in 1:length(flickersumm)){
    flickerdf[e,] <- list(flickersummlist[[e]][[1]],
                          flickersummlist[[e]][[2]],
                          paste(flickersummlist[[e]][[3]], collapse = ' / '))
}

#-------------------------------------------------------------------------------
# WRITE RASTERS
# create dir (useful for outputs)
newfolder <- paste0(outdir,AAAAMMDD_HHmmss(),'_doshade','/')
dir.create(newfolder, showWarnings = F)

# WRITE DEM objects
writeRaster(DEM,paste0(newfolder,'DEM'), format="GTiff", overwrite = TRUE)
# option1 --> grd with bands
writeRaster(r,paste0(newfolder,"DEM_doshade_stack.grd"), format="raster") 
# option 2 --> separated tif
writeRaster(r, paste0(newfolder,names(r)), bylayer=TRUE,format="GTiff") 

# WRITE DEMm objects
writeRaster(DEMm,paste0(newfolder,'DEMm'), format="GTiff", overwrite = TRUE)
# option1 --> grd with bands
writeRaster(rm,paste0(newfolder,"DEMm_doshade_stack.grd"), format="raster") 
# option 2 --> separated tif
writeRaster(rm, paste0(newfolder,names(rm)), bylayer=TRUE,format="GTiff") 

# WRITE DEMdif objects
# option1 --> grd with bands
writeRaster(DEMdif,paste0(newfolder,"DEMdif_doshade_stack.grd"), format="raster") 
# option 2 --> separated tif
writeRaster(DEMdif, paste0(newfolder,names(DEMdif)), bylayer=TRUE,format="GTiff") 

#-------------------------------------------------------------------------------
# WRITE SUMMARY RESULTS
write.xlsx(flickerdf, paste0(newfolder,"RESULTS.xlsx"))
