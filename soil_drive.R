#load package
library(googledrive)

#authorize drive connection
drive_auth(email = "gold1@stolaf.edu")

#identify target master directory in CURI-CUR shared drive
NEW_soil_dir <- as_id("https://drive.google.com/drive/folders/13ZN8xT4CmVNo5zbJ7g6-9clP0dpPys6_")



#for loop starts here
for(i in 1:nrow(soil_zip)) {
  
#specify current county
county <- as.character(soil_zip[i,2])

#create folder in NEW-soil shared drive folder (CURI > GIS > SOIL > NEW_soil)
dir <- drive_mkdir(county,NEW_soil_dir, overwrite = FALSE)

#grab current county folder id
current_id <- as_id(dir[[2]])

#set range of CHILD for loop
a <- (4*i) - 3 
b <- a + 3

#CHILD for loop starts here
for(j in a:b) {
#specify R file path for spatial files to upload to drive
spatial_fp <- file.path(getwd(),"Land_Use_Rights","spatial_soil",county,file_grid[j,4])

#upload geo file to current county folder
drive_upload(spatial_fp,current_id)
    }

}
