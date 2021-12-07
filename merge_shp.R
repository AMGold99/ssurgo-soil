#Title: Merge Shapefiles
#Author: Asa Gold
#Date: 12/2/21


#load packages
library(sp)
library(rgdal)
library(readr)


#for loop to merge all county spatial files
for(i in 1:nrow(soil_zip)) {

#grab current county
county <- as.character(soil_zip[i,2])

#specify current county mapunit file name
csv_name <- paste(county,
                  "mu.csv",
                  sep = "")

#specify current county mapunit path
csv_path <- file.path(getwd(),
                      "Land_Use_Rights",
                      "mapunit",
                      csv_name
                      )

#specify current county shapefile name
shp_name <- paste("soilmu_a_",
                  tolower(county),
                  sep = ""
                  )

#specify current county shapefile path
shp_path <- file.path(getwd(),
                      "Land_Use_Rights",
                      "spatial_soil",
                      county
                      )


#load current county shp file
shpload <- rgdal::readOGR(shp_path,
                          shp_name
                          )


#load current county mapunit.csv
county_mu <- read_csv(csv_path,
                      show_col_types = FALSE
                      )



#merge shp and mu files, by MUSYM
shp_merge <- sp::merge(shpload,
                       county_mu, 
                       by.x = "MUSYM", 
                       by.y = "MUSYM"
                       )

#save merged shpfile to current county directory
writeOGR(shp_merge,
         dsn = shp_path,
         layer = shp_name, 
         driver = "ESRI Shapefile",
         overwrite_layer = TRUE
         )

}
