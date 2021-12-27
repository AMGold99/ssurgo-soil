#Title: Spatial Download
#Author: Asa Gold
#Date: 12/2/2021


#create df of all geo file names (dbf, prj, shp, shx) for all counties
file_grid <- expand.grid(
  start = "soilmu_a_",
  fips = tolower(soil_zip$fips),
  ext = c(".dbf",".prj",".shp",".shx")
  ) %>%
  mutate(file = paste(start,fips,ext,sep = "")) %>%
  arrange(file)

#create county directories to fill with spatial files [ONLY RUN ONCE]
#create_path <- file.path(getwd(),"Land_Use_Rights","spatial_soil")
#for(i in 1:nrow(soil_zip)) {
#    c_file <- as.character(soil_zip[i,2])
#    path <- file.path(create_path,c_file)
#    dir.create(path,showWarnings = TRUE) 
#}





#this for loop (and its child) downloads each county file and 
#deposits geo mu files into spatial_soil folders
for(i in 1:nrow(soil_zip)) {
  link <- as.character(soil_zip[i,4])
  
  #extract current county name from download link
  county <- stringr::str_sub(link,
                             str_locate(link,"_SSA_")[[2]]+1,
                             str_locate(link,"_SSA_")[[2]]+5
  )
  
  #specify destination for zip download
  dest <- file.path(getwd(),"Land_Use_Rights","spatial_soil",county,county)
  
  #download zip and send to dest
  download.file(link, 
                destfile = dest, 
                quiet = FALSE)
  
  #unzip zipped download
  zipF <- dest
  outDir <- file.path(getwd(),"Land_Use_Rights")
  unzip(zipF,exdir=outDir)
  
  #set parameters for child loop range
  a <- (4*i) - 3 
  b <- a + 3
  
  #extract all four geo files from current county folder
  for(j in a:b) {
    spatial_fp <- file.path(getwd(),"Land_Use_Rights",county,"spatial",file_grid[j,4])
    spatial_dest <- file.path(getwd(),"Land_Use_Rights","spatial_soil",county)
    file.copy(from = spatial_fp,
              to = spatial_dest
    )
  }
  
  #delete current county unzipped folder
  unlink(file.path(getwd(),"Land_Use_Rights",county), recursive = TRUE)
  
  #delete current county zip file
  file.remove(dest)
  
}
