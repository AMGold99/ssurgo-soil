#Title: Soil Drive
#Author: Asa Gold
#Date: 30 Dec 2021
#Description: Uploads all completed spatial files to specified google drive

upload_to_drive <- function(excel_file,mn_dir,sp_dir,spatial_names,target_location) {
  
  #convert link to id readable by googledrive package
  gdrive_soil <- googledrive::as_id(target_location)
  
  
  #create state folder within target google drive directory
  state <- as.character(
    stringr::str_sub(
      excel_file[1,2],1,2
      )
    )
  
  state_gdir <- googledrive::drive_mkdir(state,gdrive_soil, overwrite = FALSE)
  
  state_id <- googledrive::as_id(state_gdir[[2]])
  
  #create county subfolders in state folder and fill them with shapefiles
  for(i in 1:nrow(excel_file)) {
    
    #specify current county
    county <- as.character(excel_file[i,2])
    
    #create folder in NEW-soil shared drive folder (CURI > GIS > SOIL > NEW_soil)
    county_gdir <- googledrive::drive_mkdir(county,state_gdir, overwrite = FALSE)
    
    #grab current county folder id
    county_id <- googledrive::as_id(county_gdir[[2]])
    
    #set range of inner for loop
    a <- (4*i) - 3 
    b <- a + 3
    
    #inner for loop pulls each spatial file associated with the current county and uploads it to county folder
    for(j in a:b) {
      
      #specify R file path for spatial files to upload to drive
      spatial_locate <- file.path(getwd(),mn_dir,sp_dir,state,county,spatial_names[j,4])
      
      #upload geo file to current county folder
      googledrive::drive_upload(spatial_locate,county_id, overwrite = TRUE)
      
    }
    
  }
  
}
