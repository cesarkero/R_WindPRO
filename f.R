#-------------------------------------------------------------------------------
# Function tSeries
# Calculate timeSeries from a list of YYYY, MM, DD eachmin and a timezone
# need lubridate to convert time to local time
# create a 2 dim list: 1 is the time series
# is the name in format YYYYMMDD_HHmmss
tSeries <- function(YYYY, MM, DD, eachmin, TZ){
    timeSeries <- list()
    for (Y in YYYY) {
        for (M in MM){
            for (D in DD){
                for (h in seq(0:23)-1){ 
                    for (m in seq(from = 0, to = 59, by = eachmin)){
                        # filter times out of the sunrise sunset
                        timeSeries <- append(timeSeries,ISOdate(Y,M,D,h,m,s=00,TZ))
                    }
                }
            }
        }
    }
    return(timeSeries)
}

#MEJORA 
tSeries2 <- function(YYYY = c(2019), MM = c(1:12), DD = c(1:31),
                     by = '30 min', TZ = "Europe/Berlin"){
    ts <- list()
    for (Y in YYYY) {
        for (M in MM){
            for (D in DD){
                if (!is.na(ISOdate(Y,M,D,tz=TZ))){ #avoid inexistent days
                    ts <- append(ts,seq(ISOdate(Y,M,D,hour=0,tz=TZ),
                                        ISOdate(Y,M,D,hour=23,min=59,tz=TZ),
                                        by=by))
                }
            }
        }
    }
    return(ts)
}

#-------------------------------------------------------------------------------
# Function AAAAMMDD_HHmmss: 
# get values from time in POSIX format and create an string to use as name
AAAAMMDD_HHmmss <- function(x = Sys.time()){
    return(paste0(format(x, "%Y"),
                  format(x, "%m"),
                  format(x, "%d"),
                  "_",
                  format(x, "%H"),
                  format(x, "%M"),
                  format(x, "%S")))
}

#-------------------------------------------------------------------------------
# Function MidPoint
# needs rgdal
# get coords from shp or raster and returns the mid point, even changing the projection
# by default gets a proyected layer and returns a geographical point in epsg:4326
# to get just the coords use: 
    #GET COORDS FROM MIDPOINT FROM EXTENSION
    # x <- midPoint(DEM)[[1]]
    # y <- midPoint(DEM)[[2]]
midPoint <- function(layer, newepsg = TRUE, crs = CRS("+init=epsg:4326")){
    epsg1 <- crs(layer)
    epsg2 <- crs
    
    #midpoint
    x0 <- xmin(layer)+(xmax(layer)-xmin(layer))
    y0 <- ymin(layer)+(ymax(layer)-ymin(layer))
    
    #create spatial objec from coords
    t <- data.frame(lon=x0, lat=y0)
    coordinates(t) <- c("lon","lat")
    proj4string(t)<-epsg1
    t2 <- spTransform(t,epsg2)
    
    #add coords to table
    t2$x <- t2@coords[,1]
    t2$y <- t2@coords[,2]
    
    return(t2)
}

#-------------------------------------------------------------------------------
# Function AeroToAlt 
# This function gets a point layer and creates polygon with ring of the maximum 
