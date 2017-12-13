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
  cow_original <- cow
  values(cow) <- dplyr::percent_rank(values(cow)) * 100
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
  # extent(cowap) <- extent(mosq)
  # combine_function <- function(x,y){
  #   as.numeric(paste0(mean(x), '.', mean(y)))
  # }
  # combine_function <- Vectorize(combine_function)
  cowsquito <- overlay(cowap, mosq, 
                       # fun = combine_function
                       fun = mean
                       )
  save(cow,
       cowa,
       cowap,
       cowsquito,
       mosq,
       file = 'data/processed_data.RData')
}


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

plotter <- function(r){
  colr <- colorRampPalette(rev(brewer.pal(9, 'Spectral')))
  
  levelplot(r, 
            margin=FALSE,                       # suppress marginal graphics
            colorkey=list(
              space='bottom'#,                   # plot legend at bottom
              # labels=list(at=-5:5, font=4)      # legend ticks and labels 
            ),    
            par.settings=list(
              axis.line=list(col='transparent') # suppress axes and legend outline
            ),
            scales=list(draw=FALSE),            # suppress axis labels
            col.regions=colr#,                   # colour ramp
            # at=seq(-5, 5, len=101)
  )   
}