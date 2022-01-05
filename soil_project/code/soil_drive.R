#Title: Soil Drive Upload
#Author: Asa Gold
#Date: 30 Dec 2021
#Description: Uploads all completed spatial files to specified google drive

upload_to_drive <- function(excel_file,mn_dir,sp_dir,spatial_names,target_location) {
  
  #convert link to id readable by googledrive package
  gdrive_soil <- googledrive::as_id(target_location)
  
  
  #specify current state
  state <- as.character(
    stringr::str_sub(
      excel_file[ceiling(nrow(excel_file)/2),2],
      1,
      2
      )
    )
  
  #create state folder in target drive directory
  state_gdir <- googledrive::drive_mkdir(state,gdrive_soil, overwrite = FALSE)
  
  #save drive id of state folder
  state_id <- googledrive::as_id(state_gdir[[2]])
  
  
  #create county subfolders in state folder and fill them with shapefiles
  for(i in 1:nrow(excel_file)) {
    
    #specify current county
    county <- as.character(excel_file[i,2])
    
    #create county subfolder in state folder
    county_gdir <- googledrive::drive_mkdir(county,state_gdir, overwrite = FALSE)
    
    #grab current county folder id
    county_id <- googledrive::as_id(county_gdir[[2]])
    
    #set range of nested for loop
    a <- (4*i) - 3 
    b <- a + 3
    
    #nested for loop pulls each spatial file associated with the current county and uploads it to county folder
    for(j in a:b) {
      
      #specify location of spatial files to be uploaded to county subfolder in drive
      spatial_locate <- file.path(getwd(),mn_dir,sp_dir,state,county,spatial_names[j,4])
      
      #upload spatial file to county subfolder
      googledrive::drive_upload(spatial_locate,county_id, overwrite = TRUE)
      
    }
    
  }
  
}
