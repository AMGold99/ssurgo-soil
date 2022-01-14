#-------------------DESCRIPTION---------------------#

#   Executes soil data processing pipeline which
#   retrieves farmland classifications and soil shapefiles 
#   from NRCS's Web Soil Survey (SSURGO database), merges them,
#   then uploads files to google drive folder for use by ArcGIS Pro

#   Author: Asa Gold




#---------------SET GLOBAL VARIABLES----------------#


#----DIRECTORIES----#

#main directory
main_dir <- "soil_project"

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

#Specify Google email with access to target Drive directory
drive_email <- "email_here" #ex: gold1@stolaf.edu"

#Specify link to target Google Drive directory
gdrive_link <- "google_drive_link" #ex: https://drive.google.com/drive/folders/1EJRUz6hechy72-F21OvN3jCvuTjdSv0z"

#Authorize googledrive package to access your google account
if (googledrive::drive_has_token()==TRUE) {
  print("googledrive connection authorized. Proceed.")
} else {
  googledrive::drive_auth(email = drive_email)
  googledrive::drive_has_token()
  print("googledrive connection authorized. Proceed.")
}




#-------------------FOLDER CHECK--------------------#

#check that main_dir resides in highest level of R session folder system
if (file.exists(file.path(getwd(),main_dir))) {
  print("main_dir is located in top level of file system. Proceed.")
} else {
  stop("main_dir is not located in top level of file system. Double check file location before proceeding.")
}

#check that main directory contains all relevant subfolders
{
  dir_contents <- list.files(main_dir)
  subfolders <- c(zip_dir,mapunit_dir,spatial_dir,code_dir)
  
  if (sum(is.element(subfolders,dir_contents))==length(subfolders)) {
    print("All subfolders are in main directory.")
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
    print("Target directories are empty. Proceed.")
    } else {
      print(paste0(mapunit_dir, " contains: ",mapunit_contents))
      print(paste0(spatial_dir, " contains: ",spatial_contents))
      stop("Target directories not empty. Clear contents before proceeding")
  }
}


#-------------PREP STATE FILE LINKS-------------------#

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


#download, process, merge, and upload to drive (loops through all states)
for(i in 1:length(all_states_excel)) {
  
  #create df for current state with download links for each county
  current_state <- read_excel(
    file.path(getwd(),main_dir,zip_dir,all_states_excel[i]),
    col_names = c('county','fips','zip_address')) %>%
    drop_na() %>%
    mutate(link = paste0(prefix,zip_address))
  
  #retrieve current state abbr
  state_name <- as.character(state_grid[i,2])
  
  
  #set state folder paths
  mapunit_path <- file.path(getwd(), main_dir, mapunit_dir)
  spatial_path <- file.path(getwd(), main_dir, spatial_dir)
  
  
  #create state folder in mapunit
  mapunit_loc <- file.path(mapunit_path,state_name)
  dir.create(mapunit_loc, showWarnings = TRUE)
  
  #create state folder in spatial 
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
    mutate(spatial_file = paste(start,fips,ext,sep = "")) %>%
    arrange(spatial_file)
  
  
  
  #-----------DOWNLOAD mapunit and spatial files----------#
  
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
  
  
  
  #------UPLOAD finalized spatial files to google drive-------# 
  
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
  
  #delete current state folders (spatial and mapunit)
  unlink(spatial_loc, recursive = TRUE)
  unlink(mapunit_loc, recursive = TRUE)
  
  
  #free up memory space
  gc()
  
}




#---------------CITATION-----------------#
{
  
  first_dash <- stringr::str_locate_all(Sys.Date(),"-")[[1]][1]
  second_dash <- stringr::str_locate_all(Sys.Date(),"-")[[1]][2]
  
  month <- stringr::str_sub(Sys.Date(),first_dash+1,second_dash-1)
  day <- stringr::str_sub(Sys.Date(),second_dash+1,-1)
  year <- stringr::str_sub(Sys.Date(),1,4)
 
  citation <- paste0("Soil Survey Staff, Natural Resources Conservation Service, United States Department of Agriculture. Web Soil Survey. Available online at the following link: http://websoilsurvey.sc.egov.usda.gov/. Accessed ", month,"/",day,"/",year,".")
  
  print(citation)
}
