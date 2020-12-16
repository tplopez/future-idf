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
polygonspath = args[4]
save_geojson = args[5]


grid_cf = as.matrix(read.table(file=glue("{path}/{f}")))
r_cf <- raster(grid_cf,
               xmn=-84,
               xmx = -72,
               ymn=36,
               ymx = 44,
               crs=crs("+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0 ")
            )

polygons <- st_read(polygonspath)
polygons <- st_as_sf(polygons)

v <- exact_extract(r_cf, polygons, fun='mean')
v_sd <- exact_extract(r_cf, polygons, fun='stdev')

v <- signif(v, 3)
v_sd <- signif(v_sd, 5)

polygons$mean <- as.vector(v)
polygons$sd <- as.vector(v_sd)

if (save_geojson == TRUE){
    county_json <- geojson_json(counties)
    county_json_clipped <- ms_clip(county_json, bbox = c(-84, 36, -72, 44))

    geojson_write(county_json_clipped, file = glue('{savepath}/{geojsonfile}.geojson'))
} else {

    writeRaster(r_cf, filename=glue('{savepath}/{filename}.tif'), format="GTiff", overwrite=TRUE))

}
