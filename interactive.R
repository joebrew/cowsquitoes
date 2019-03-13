
library(knitr)
opts_chunk$set(comment = NA, echo = FALSE, warning = FALSE, message = FALSE, error = FALSE, fig.align = 'center', fig.height = 4, fig.width = 7)
options(xtable.comment = FALSE)
if('done.RData' %in% dir()){
  load('done.RData')
} else {
  source('code.R')
  save.image('done.RData')
}
library(tidyverse)
library(tiff)
library(rgdal)
library(raster)
library(rasterVis)
library(RColorBrewer)

roundy <- function(x, digits = 0){
  round(as.numeric(unlist(x)), digits = digits)
}
aa@data$cowap <- roundy(aa@data$cowap, digits = 1)
aa@data$cow_original <- roundy(aa@data$cow_original, digits = 1)
aa@data$mosq_original <- roundy(aa@data$mosq_original, digits = 2)
aa@data$mosq <- roundy(aa@data$mosq, digits = 2)
aa@data$cowsquito <- roundy(aa@data$cowsquito, digits = 1)


library(leaflet.extras)
pops <- aa@data %>%
  dplyr::rename(`Cattle density (percentile)` = cowap,
                `Cattle density` = cow_original,
                `Malaria prevalence (2-10 yrs old)` = mosq_original,
                `Malaria prevalence (2-10 yrs old, percentile)` = mosq,
                `Combined cattle/malaria score (percentile)` = cowsquito,
                `Area` = NAME_1,
                `Country` = NAME_0) %>%
  dplyr::select(`Cattle density (percentile)`,
                `Cattle density`,
                `Malaria prevalence (2-10 yrs old)`,
                `Malaria prevalence (2-10 yrs old, percentile)`,
                `Combined cattle/malaria score (percentile)`,
                `Area`,
                `Country`)

popups <- lapply(rownames(pops), function(row){
  x <- pops[row.names(pops) == row,] %>% 
    dplyr::select(-Area, -Country)
  captions <- paste0(x$Area, ' ', x$Country)
  
  htmlTable::htmlTable(x, 
                       rnames = FALSE,
                       caption = captions,
                       # align = 'lr',
                       align = paste(rep("l", ncol(x)), collapse = ''),
                       format = 'html')
  
  # knitr::kable(x, 
  #              rnames = FALSE,
  #              caption = captions,
  #              align = 'lr',
  #              # align = paste(rep("l", ncol(x)), collapse = ''),
  #              format = 'html')
})

make_small <- 
  function(x){
    ((1 + percent_rank(x)) * 1.2)^2.2
  }
pal <- colorNumeric(
  palette = "YlOrRd",
  domain = aa@data$cowap)
l <- leaflet() %>%
  addProviderTiles(providers$Stamen.Toner) %>%
  addPolygons(data = aa,
              smoothFactor = 0.2,
              fill = NA,
              fillOpacity = 0,
              stroke = TRUE,
              weight = 0.5,
              # color = pal(aa@data$cowap),
              color = 'black') %>%
  addCircleMarkers(data = aa_coords@coords,
                   lng = aa_coords@coords[,1],
                   lat = aa_coords@coords[,2],
                   color = 'black',
                   weight = 0.5,
                   fillOpacity = 0.9,
                   fillColor = pal(aa@data$cowap),
                   radius = make_small(aa@data$mosq),
                   popup = popups) %>%
  addFullscreenControl() %>%
  addLegend("bottomleft", pal = pal, values = aa@data$cowap[!is.na(aa@data$cowap)],
            title = "Color = cattle density;<br>Circle size = malaria prevalence",
            opacity = 1
  )

create_column <- function(r){
  xa <- africa1
  simple <- data.frame(coordinates(xa)); names(simple) <- c('x', 'y'); simple$lng <- simple$x; simple$lat <- simple$y
  coordinates(simple) <- ~x+y
  proj4string(simple) <- proj4string(africa1)
  proj4string(r) <- proj4string(africa1)
  # a <- extract(xcowsquito, africa, fun = mean, na.rm = TRUE)
  b <- extract(r, simple, na.rm = TRUE)
  return(b)
}

data_list <- list(arab_density, cowap, mosq)
names_list <- c('Arabiensis', 'Cattle', 'Malaria')

library(rgeos)
x_shp <- gSimplify(africa1, tol = 0.1, topologyPreserve = T)
x_shp <- SpatialPolygonsDataFrame(Sr = x_shp,
                                  data = africa1@data)
x_shp <- africa1
for(i in 1:length(data_list)){
  x_shp@data[,names_list[i]] <-
    create_column(r = data_list[[i]])
}

af <- x_shp
af_coords <- data.frame(coordinates(af)); names(af_coords) <- c('x', 'y'); coordinates(af_coords) <- ~x+y

library(leaflet.extras)
pops <- af@data %>%
  mutate(Cattle = round(Cattle, 2),
         Malaria = round(Malaria, 2),
         Arabiensis = round(Arabiensis, 2)) %>%
  dplyr::rename(`Cattle density (percentile)` = Cattle,
                # `Malaria prevalence (2-10 yrs old)` = mosq_original,
                `Malaria prevalence (2-10 yrs old, percentile)` = Malaria,
                `Arabiensis prevalence (percentile)` = Arabiensis,
                `Area` = NAME_1,
                `Country` = NAME_0) %>%
  dplyr::select(`Cattle density (percentile)`,
                # `Cattle density`,
                # `Malaria prevalence (2-10 yrs old)`,
                `Malaria prevalence (2-10 yrs old, percentile)`,
                # `Combined cattle/malaria score (percentile)`,
                `Arabiensis prevalence (percentile)`,
                `Area`,
                `Country`)

popups <- lapply(rownames(pops), function(row){
  x <- pops[row.names(pops) == row,] %>% 
    dplyr::select(-Area, -Country)
  captions <- paste0(x$Area, ' ', x$Country)
  
  htmlTable::htmlTable(x, 
                       rnames = FALSE,
                       caption = captions,
                       # align = 'lr',
                       align = paste(rep("l", ncol(x)), collapse = ''),
                       format = 'html')
})

pal <- colorNumeric(
  palette = "YlOrRd",
  domain = af@data$Cattle)
pal2 <- colorNumeric(
  palette = "Blues",
  domain = af@data$Arabiensis)

addLegendCustom <- function(map, colors, labels, sizes, opacity = 0.5, title = ''){
  colorAdditions <- paste0(colors, "; width:", sizes, "px; height:", sizes, "px")
  labelAdditions <- paste0("<div style='display: inline-block;height: ", sizes, "px;margin-top: 4px;line-height: ", sizes, "px;'>", labels, "</div>")
  
  return(addLegend(map, colors = colorAdditions, labels = labelAdditions, opacity = opacity,
                   title = title))
}
l <- leaflet() %>%
  addProviderTiles(providers$Stamen.Toner) %>%
  # Add cattle
  addPolygons(data = af,
              smoothFactor = 0.2,
              # fill = NA,
              fill = pal(af@data$Cattle),
              fillOpacity = 0.8,
              stroke = TRUE,
              weight = 0.5,
              color = pal(af@data$Cattle),
              popup = popups) %>%
  addCircleMarkers(data = af_coords@coords,
                   lng = af_coords@coords[,1],
                   lat = af_coords@coords[,2],
                   color = 'black',
                   weight = 0.5,
                   fillOpacity = 0.9,
                   fillColor = pal2(af@data$Arabiensis),
                   radius = make_small(af@data$Malaria),
                   popup = popups) %>%
  addFullscreenControl() %>%
  addLegend("bottomleft", pal = pal, values = af@data$Cattle[!is.na(af@data$Cattle)],
            title = "Cattle",
            opacity = 1
  ) %>%
  addLegend("bottomright", pal = pal2, 
            values = seq(0, 100, 20),
            # values = af@data$Arabiensis[!is.na(af@data$Arabiensis)],
            title = "Arabiensis",
            opacity = 1
  ) %>%
  addLegendCustom(colors = 'black', 
                  title = 'Malaria',
                  labels = as.character(seq(0, 100, 20)), sizes = make_small(seq(0, 100, 20)))
l
htmlwidgets::saveWidget(l, file = '~/Documents/databrew.github.io/cow3.html', selfcontained = FALSE)
