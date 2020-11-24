options(warn=-1)
suppressMessages(library(raster))
suppressMessages(library(sp))
suppressMessages(library(rgdal))
suppressMessages(library(glue))

library(sf)


args = commandArgs(trailingOnly=TRUE)

path = args[1]
filename = args[2]
savepath = args[3]


grid_cf = as.matrix(read.table(file=path))
r_cf <- raster(grid_cf,
               xmn=-84,
               xmx = -72,
               ymn=36,
               ymx = 44,
               crs=crs("+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0 ")
               )

writeRaster(r_cf, filename=glue('{savepath}/{filename}.tif'), format="GTiff", overwrite=TRUE))
