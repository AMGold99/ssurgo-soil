#Title: Merge Shapefiles
#Author: Asa Gold
#Date: 30 Dec 2021
#Description: Merges mapunit classification data with geospatial attribute table


merge_class <- function(excel_file, mn_dir, mp_dir, sp_dir) {


  #loop through every county in current state
  for(i in 1:nrow(excel_file)) {

    #get current county
    county <- as.character(excel_file[i,2])

    #get current state
    state <- stringr::str_sub(county,1,2)


    #specify current county mapunit file name
    csv_name <- paste0(county, "mu.csv")

    #specify current county mapunit location
    csv_locate <- file.path(getwd(),
                          mn_dir,
                          mp_dir,
                          state,
                          csv_name)


    #specify current county shapefile name
    shp_name <- paste0("soilmu_a_",
                      tolower(county))

    #specify current county shapefile location
    shp_locate <- file.path(getwd(),
                          mn_dir,
                          sp_dir,
                          state,
                          county)


    #load current county shapefile
    county_shp <- rgdal::readOGR(shp_locate,
                                 shp_name)


    #load current county mapunit.csv
    county_mu <- readr::read_csv(csv_locate,
                                 show_col_types = FALSE)



    #merge shp and mu files, by MUSYM
    shp_merge <- sp::merge(county_shp,
                           county_mu,
                           by.x = "MUSYM",
                           by.y = "MUSYM"
                           )

    #save merged shpfile to current county directory
    rgdal::writeOGR(obj = shp_merge,
             dsn = shp_locate,
             layer = shp_name,
             driver = "ESRI Shapefile",
             overwrite_layer = TRUE)
    }
  
  }

