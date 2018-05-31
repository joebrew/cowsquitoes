library(tidyverse)
library(tiff)
library(rgdal)
library(raster)
library(rasterVis)
library(RColorBrewer)

if('processed_data.RData' %in% dir('data')){
  load('data/processed_data.RData')
} else {
  # Read in mosquito data
  # mosq <- readGDAL('data/MOSQUITOES/africa_pr_2000_2015_2015.tif', silent = TRUE)
  mosq <- raster('data/MOSQUITOES/africa_pr_2000_2015_2015.tif')
  projection(mosq) <- "+proj=utm +zone=48 +datum=WGS84"
  mosq_original <- mosq
  values(mosq) <- dplyr::percent_rank(values(mosq)) * 100
  
  # Read in cow data
  # cow = readGDAL('data/CATTLE/Glb_Cattle_CC2006_AD.tif', silent = TRUE)
  cow <- raster('data/CATTLE/Glb_Cattle_CC2006_AD.tif')
  projection(cow) <- "+proj=utm +zone=48 +datum=WGS84"
  cow <- aggregate(cow, fact=8)
  # cow_original <- cow
  # values(cow) <- values(cow) / max(values(cow), na.rm = TRUE)
  
  # Crop cow just to africa
  cowa <- crop(cow, mosq)
  extent(cowa) <- extent(mosq)
  
  # Overlay
  cowap <- projectRaster(from = cowa, 
                         to = mosq#,
                         # method = 'ngb',
                         # res = res(mosq),
                         # crs = proj4string(mosq)
  )
  cow_original <- cowap
  # cow_original <- cowap
  values(cowap) <- dplyr::percent_rank(values(cowap)) * 100
  
  # extent(cowap) <- extent(mosq)
  # combine_function <- function(x,y){
  #   as.numeric(paste0(mean(x), '.', mean(y)))
  # }
  # combine_function <- Vectorize(combine_function)
  cowsquito <- overlay(cowap, mosq, 
                       # fun = combine_function
                       fun = prod
                       )
  
  # Combine into a spatial pixels dataframe
  cowap_small <- cowap#aggregate(cowap, fact=8)
  values(cowap_small) <- values(cowap_small) * 100
  mosq_small <- mosq#aggregate(mosq, fact = 8)
  r = brick(cowap_small,mosq_small)
  r <- as(r, "SpatialPixelsDataFrame")
  names(r@data) <- c('cattle', 'pr')
  # Round
  r@data$cattle <- round(r@data$cattle)
  r@data$cattle[is.na(r@data$cattle)] <- 0
  r@data$pr <- round(r@data$pr)
  r@data$pr[is.na(r@data$pr)] <- 0
  # Define color
  # Come up with a color matrix
  dat <- expand.grid(cattle=seq(0, 100, by=1), pr=seq(0, 100, by=1))
  dat <- within(dat, color <- rgb(green=cattle, red=pr, blue=0, maxColorValue=100))
  dat$color_number <- 1:nrow(dat)
  # # Legend
  # ggplot(dat, aes(x=cattle, y=pr)) +
  # geom_tile(aes(fill=color), color=NA) +
  # scale_fill_identity() +
  #   labs(x = 'Cattle percentile',
  #        y = 'Pr percentile') +
  #   databrew::theme_databrew()
  # # Join color key to r
  r@data <-left_join(r@data,
                     dat)
  
  # # Convert back to raster
  # color_number <- rep(NA, nrow(r@data))
  # 
  # if('color_number.RData' %in% dir('data')){
  #   load('data/color_number.RData')
  # } else {
  # 
  #   for(i in which(!is.na(r@data$color))){
  #     message(i)
  #     color_number[i] <-
  #       which(dat$color == r@data$color[i])
  #   }
  #   save(color_number,
  #        file = 'data/color_number.RData')
  # }
  # r@data$color_number <- color_number
  

  x <- SpatialPointsDataFrame(coords = coordinates(r),
                              data = r@data)
  rr <- mosq_small
  z <- rasterize(x, mosq_small, field = 'color_number')

  # Get Africa level 2 and 1 shape files and combine
  # source('get_africa_shapes_level_1.R')
  africa1 <- readOGR('africa_level_1', 'africa1')
  
  save(cow,
       cowa,
       cowap,
       cowsquito,
       mosq,
       cow_original, 
       mosq_original,
       z,
       x,
       r,
       dat,
       africa1,
       file = 'data/processed_data.RData')
}

# Read in arabiensis data
arab <- readOGR('data/VECTORS/13071_2010_245_MOESM1_ESM/Additional file 1 - African, Euro-ME EO shapefiles/', 'arabiensis')


# ggplot(dat, aes(x=red, y=blue)) + 
  # geom_tile(aes(fill=mix), color="white") + 
  # scale_fill_identity()

# plot(cow)
# levelplot(cow)
# levelplot(cow, par.settings = GrTheme)
# levelplot(cow, par.settings = magmaTheme)
# levelplot(cow, par.settings = BuRdTheme)
# 
# gplot(cow) +  
#   geom_tile(aes(fill=factor(value),alpha=0.8)) + 
#   # geom_polygon(data=OR, aes(x=long, y=lat, group=group), 
#   #              fill=NA,color="grey50", size=1)+
#   coord_equal()

# colr <- colorRampPalette(rev(brewer.pal(9, 'Spectral')))
# 
# levelplot(cow, 
#           margin=FALSE,                       # suppress marginal graphics
#           colorkey=list(
#             space='bottom'#,                   # plot legend at bottom
#             # labels=list(at=-5:5, font=4)      # legend ticks and labels 
#           ),    
#           par.settings=list(
#             axis.line=list(col='transparent') # suppress axes and legend outline
#           ),
#           scales=list(draw=FALSE),            # suppress axis labels
#           col.regions=colr#,                   # colour ramp
#           # at=seq(-5, 5, len=101)
#           )            # colour ramp breaks

plotter <- function(r, colr = NULL, no_legend = FALSE){
  if(is.null(colr)){
    colr <- colorRampPalette(rev(brewer.pal(9, 'Spectral')))
  }
  if(no_legend){
    colorkey <- FALSE
  } else {
    colorkey <- list(
      space='bottom'#,                   # plot legend at bottom
      # labels=list(at=-5:5, font=4)      # legend ticks and labels 
    ) 
  }
  
  levelplot(r, 
            margin=FALSE,                       # suppress marginal graphics
            colorkey= colorkey,
            par.settings=list(
              axis.line=list(col='transparent') # suppress axes and legend outline
            ),
            scales=list(draw=FALSE),            # suppress axis labels
            col.regions=colr#,                   # colour ramp
            # at=seq(-5, 5, len=101)
  )   
}

# Leaflet map
if('more_data.RData' %in% dir()){
  load('more_data.RData')
} else {
  # Subset the level 1 data just to arabiensis area
  aa <- raster::intersect(x = arab,
                          y = africa1)
  aa_coords <- coordinates(aa)
  aa_coords <- data.frame(aa_coords)
  names(aa_coords) <- c('lng', 'lat')
  aa@data <- cbind(aa@data, aa_coords)
  coordinates(aa_coords) <- ~lng+lat
  
  
  # Get values
  a <- cowap
  values(a)[is.infinite(values(a))] <- NA 
  proj4string(a) <- proj4string(arab)
  aa@data$cowap <- extract(x = a, y = aa, fun = mean, na.rm = TRUE)
  
  a <- mosq
  values(a)[is.infinite(values(a))] <- NA 
  proj4string(a) <- proj4string(arab)
  aa@data$mosq <- extract(x = a, y = aa, fun = mean, na.rm = TRUE)
  
  a <- cowsquito
  values(a)[is.infinite(values(a))] <- NA 
  proj4string(a) <- proj4string(arab)
  aa@data$cowsquito <- extract(x = a, y = aa, fun = mean, na.rm = TRUE)
  
  a <- mosq_original
  values(a)[is.infinite(values(a))] <- NA 
  proj4string(a) <- proj4string(arab)
  aa@data$mosq_original <- extract(x = a, y = aa, fun = mean, na.rm = TRUE)
  
  a <- cow_original
  values(a)[is.infinite(values(a))] <- NA 
  proj4string(a) <- proj4string(arab)
  aa@data$cow_original <- extract(x = a, y = aa, fun = mean, na.rm = TRUE)
  
  
  save(aa, aa_coords, 
       file = 'more_data.RData')
}
library(leaflet)
              
