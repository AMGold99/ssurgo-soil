#-------------------DESCRIPTION---------------------#

#Executes soil data processing pipeline to
#retrieve farmland classifications and soil shapefiles 
#from NRCS's Web Soil Survey (SSURGO database),
#then uploads files to google drive folder for use by ArcGIS Pro

#Author: Asa Gold

#Date: Nov 2021 (Beta Version); Dec 2021 (Final Version)


#---------------SET GLOBAL VARIABLES----------------#


#----DIRECTORIES----#

#main directory
main_dir <- "Land_Use_Rights"

#soil excel zip reference directory
zip_dir <- "state_zip"

#mapunit repository directory
mapunit_dir <- "mapunit"

#spatial repository directory
spatial_dir <- "spatial_soil"

#code directory
code_dir <- "code"



#----CODE FILES-----#

#download code file
download_code <- "soil_extract.R"

#merge code file
merge_code <- "merge_shp.R"

#google drive code file
drive_code <- "soil_drive.R"

#set universal Web Soil Survey link prefix
prefix <- "https://websoilsurvey.sc.egov.usda.gov/DSD/Download/Cache/SSA/"



#---GOOGLE ACCOUNT AUTH----#

#specify Google email with access to target Drive directory
drive_email <- "gold1@stolaf.edu"

#Authorize googledrive package to access your google account
if (googledrive::drive_has_token()==TRUE) {
  print("googledrive connection authorized. Proceed.")
} else {
  googledrive::drive_auth(email = drive_email)
  googledrive::drive_has_token()
  print("googledrive connection authorized. Proceed.")
}


#Specify link to target Google Drive directory
gdrive_link <- "https://drive.google.com/drive/folders/1EJRUz6hechy72-F21OvN3jCvuTjdSv0z"



#-------------------FOLDER CHECK--------------------#

#check that main directory contains all relevant subfolders
{
  dir_contents <- list.files(main_dir)
  subfolders <- c(zip_dir,mapunit_dir,spatial_dir,code_dir)
  
  if (sum(is.element(subfolders,dir_contents))==length(subfolders)) {
    print("Good to go!")
  } else {
      print(paste0("Current names are: mapunit_dir = ",mapunit_dir,", spatial_dir = ",spatial_dir,", zip_dir = ",zip_dir,", and code_dir = ",code_dir,". Do these match the folder names in your session?"))
      stop("Main directory does not contain specified subfolders. Double check names of mapunit_dir, spatial_dir, zip_dir, and code_dir")
    }
  }

#ensure spatial and map directories are empty
{
  mapunit_contents <- list.files(file.path(getwd(),main_dir,mapunit_dir))
  spatial_contents <- list.files(file.path(getwd(),main_dir,spatial_dir)) 
  
  if (is_empty(mapunit_contents) &
      is_empty(spatial_contents)) {
    print("Good to go!")
  } else {
      print(paste0(mapunit_dir, " contains: ",mapunit_contents))
      print(paste0(spatial_dir, " contains: ",spatial_contents))
      stop("target directories not empty. Clear contents before proceeding")
  }
}


#--------------PREP STATE LINKS---------------------#

#load df with state abbreviations, used to create name references
state_abbr <- read_excel(file.path(main_dir,zip_dir,"state_abbr.xlsx"), 
                         col_names = c('state','abbr'))


#create df that contains all states' excel file names ('zip_name' var)
state_grid <- expand_grid(
  prefix = "soil_zip_county_",
  state = state_abbr$abbr
) %>%
  mutate(zip_name = paste0(prefix,state,".xlsx"))


#create vector of all states' excel file names
all_states_excel <- state_grid[[3]]


#-------------------EXECUTE-------------------------#




#download, process, merge, and upload to drive (all states)
for(i in 1:length(all_states_excel)) {
  
  #create df for current state with download links for each county
  current_state <- read_excel(
    file.path(getwd(),main_dir,zip_dir,all_states_excel[i]),
    col_names = c('county','fips','download')) %>%
    drop_na() %>%
    mutate(link = paste0(prefix,download))
  
  #retrieve current state abbr
  state_name <- as.character(state_grid[i,2])
  
  
  #set state folder paths
  mapunit_path <- file.path(getwd(), main_dir, mapunit_dir)
  spatial_path <- file.path(getwd(), main_dir, spatial_dir)
  
  
  #create state folders in mapunit
  mapunit_loc <- file.path(mapunit_path,state_name)
  dir.create(mapunit_loc, showWarnings = TRUE)
  
  #create state folders in spatial 
  spatial_loc <- file.path(spatial_path,state_name)
  dir.create(spatial_loc, showWarnings = TRUE)
  
  #create county folders in spatial state folders
  for(j in 1:nrow(current_state)) {
    
    current_county <- current_state[j,2]
    county_path <- file.path(spatial_loc,current_county)
    
    dir.create(county_path, showWarnings = TRUE)
    
  }
  
  #create df of all geo files (dbf, prj, shp, shx) for all counties
  sp_grid <- expand.grid(
    start = "soilmu_a_",
    fips = tolower(current_state$fips),
    ext = c(".dbf",".prj",".shp",".shx")
  ) %>%
    mutate(file = paste(start,fips,ext,sep = "")) %>%
    arrange(file)
  
  
  
  #-------DOWNLOAD mapunit and spatial files------#
  
  #set source code file path
  source_code <- file.path(getwd(),main_dir,code_dir)
  
  #source download function
  download_source <- file.path(source_code,"soil_extract.R")
  source(download_source) 
  
  #execute download function
  download_soil(
    excel_file = current_state, 
    mn_dir = main_dir, 
    mp_dir = mapunit_dir,
    sp_dir = spatial_dir,
    spatial_names = sp_grid 
  )



  #------MERGE mapunit classification with spatial files------#
 
  #source merge function
  merge_source <- file.path(source_code,"merge_shp.R")
  source(merge_source)
  
  #execute merge function
  merge_class(
    excel_file = current_state, 
    mn_dir = main_dir, 
    mp_dir = mapunit_dir, 
    sp_dir = spatial_dir
  )
  
  
  
  #------UPLOAD finalized shapefiles to specified google drive-----# 
  
  #source upload function
  upload_source <- file.path(source_code,"soil_drive.R")
  source(upload_source)
  
  
  #execute upload function
  upload_to_drive(
    excel_file = current_state,
    mn_dir = main_dir,
    sp_dir = spatial_dir,
    spatial_names = sp_grid,
    target_location = gdrive_link
  )
  
}
