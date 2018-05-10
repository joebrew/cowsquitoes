library(countrycode) #has list of ISO3 country codes built into package data
library(dplyr) #data filtering and manipulation
library(httr) 
library(tibble) 

library(rgdal) #used to create shapefile



list1 = unlist(codelist %>%  
                 filter(continent == "Africa")  %>% 
                 select(iso3c))

for (i in list1){
  urls <- lapply(list1
                 , function(i) paste0("https://biogeo.ucdavis.edu/data/gadm2.8/rds/", i, "_adm2.rds" )
  )
}


for (u in urls){
  urls <- lapply(urls, function(u) GET(u,write_disk(tempfile(fileext = ".RDS")))
  )
}

infolist1 =rownames_to_column(
  data.frame(
    as.matrix(
      unlist(
        lapply(urls, `[`, c('url', 'status_code', 'content')
               #explained at https://stackoverflow.com/questions/23758858/how-can-i-extract-elements-from-lists-of-lists-in-r
        )
      )
    )
  )
  , var = "rowname")


infolist1$rowname= gsub(".*\\.","",infolist1$rowname) 
colnames(infolist1) = c("rowname", "data1")


c1= infolist1 %>% filter(rowname == 'url') %>%  select(data1)
c2 = infolist1 %>%  filter(rowname == 'status_code') %>%  select(data1)
c3= infolist1 %>%   filter(rowname == 'content') %>%   select(data1)

infolist1 = cbind(c1,c2,c3)
rm(list=c("c1", 'c2', 'c3'))
colnames(infolist1) = c("urlx", "filestatus", "filepath")



deletelist =  as.character(unlist(infolist1%>% filter(filestatus == '404') %>%  select(filepath)))

for (p in deletelist){
  paths <-  lapply(deletelist, function(p) file.remove(p)
  )
}


combinedRDS_lev2 <- do.call('rbind', lapply(list.files(pattern = ".RDS",tempdir(),full.names = T), readRDS))

plot(combinedRDS_lev2)

#setwd(...)
writeOGR(obj=combinedRDS_lev2, dsn=getwd(), layer="africalev2", driver="ESRI Shapefile")
# getwd() #

file.remove(dir(path = tempdir(), pattern = ".RDS",full.names=TRUE))

new_urls = gsub("_adm2","_adm1",unlist(infolist1%>% filter(filestatus == '404') %>%  select(urlx) %>% mutate(urlx = as.character(urlx)))) 

nu <- new_urls
for (u in new_urls){
  message(u)
  nu <- lapply(new_urls, function(u) GET(u,write_disk(tempfile(fileext = ".RDS")))
  )
}

combinedRDS_lev1<- do.call('rbind', lapply(list.files(pattern = ".RDS",tempdir(),full.names = T), readRDS))
plot(combinedRDS_lev1)

writeOGR(obj=combinedRDS_lev1, dsn=getwd(), layer="africalev1", driver="ESRI Shapefile")
file.remove(dir(path = tempdir(), pattern = ".RDS",full.names=TRUE))
