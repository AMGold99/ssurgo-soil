#Title: Soil Download Function
#Author: Asa Gold
#Date: 29 Dec 2021
#Description: Downloads and extracts mapunit and spatial files

#------------------SET PRELIM OPTIONS/VARS---------------------#

#extend timeout option so for loop doesn't interrupt itself
options(timeout = 500)

#sets vars names for mapunit.txt (identical for every county)
mu_vars <- c("musym",
             "muname",
             "mukind",
             "mustatus",
             "muacres",
             "mapunitlfw_l",
             "mapunitlfw_r",
             "mapunitlfw_h",
             "mapunitpfa_l",
             "mapunitpfa_r",
             "mapunitpfa_h",
             "farmlndcl",
             "muhelcl",
             "muwathelcl",
             "muwndhelcl",
             "interpfocus",
             "invesintens",
             "iacornsr",
             "nhiforsoigrp",
             "nhspiagr",
             "vtsepticsyscl",
             "mucertstat",
             "lkey",
             "mukey")


#------------------------DOWNLOAD FUNCTION--------------------#

download_soil <- function(excel_file, mn_dir, mp_dir, sp_dir, spatial_names) {

  for(i in 1:nrow(excel_file)) {

    #extract download link for current county
    link <- as.character(excel_file[i,4])

    #extract current county name from download link
    county <- excel_file[i,2]
    
    state <- stringr::str_sub(county,1,2)
    
    #set path to where temporary download will reside
    temp_path <- file.path(getwd(),mn_dir,mp_dir,state,county)
    
    #set path to where temporary spatial 

    #download current county zip file into the R session
    utils::download.file(link, 
                     destfile = temp_path, 
                     quiet = FALSE)

    #unzip county file
    zipF <- temp_path
    outDir <- file.path(getwd(),mn_dir,mp_dir)
    utils::unzip(zipF,
          exdir = outDir,
          overwrite = FALSE
          )
    

    
    #------MAPUNIT DOWNLOAD------#
    
    #reads in raw mapunit txt file and appends var names
    mapunit_df <- readr::read_delim(
        file.path(getwd(),mn_dir,mp_dir,county,"tabular","mapunit.txt"), 
        col_names = mu_vars, 
        delim = "|",
        show_col_types = FALSE) %>%
      dplyr::rename(MUSYM = "musym") %>%
      dplyr::select(MUSYM,farmlndcl)

    #writes mapunit df to mapunit state folder, labelled by county
    final_path <- file.path(getwd(),mn_dir,mp_dir,state,paste0(county,"mu.csv"))
    readr::write_csv(mapunit_df, final_path)

    
    
    #-------SPATIAL DOWNLOAD-----#
    
    #set parameters for spatial loop
    a <- (4*i) - 3 
    b <- a + 3
    
    
    #extract all four geo files from downloaded and unzipped spatial folder
    for(j in a:b) {
      spatial_retrieve <- file.path(getwd(),mn_dir,mp_dir,county,"spatial",spatial_names[j,ncol(spatial_names)])
      spatial_dest <- file.path(getwd(),mn_dir,sp_dir,state,county)
      file.copy(from = spatial_retrieve,
                to = spatial_dest
      )
    }
    

    #------REMOVE CURRENT COUNTY FOLDER-----#
    
    #delete zip file
    file.remove(temp_path)
    
    #delete unzipped folder
    linked_loc <- file.path(outDir,county)
    if(linked_loc == outDir | linked_loc == file.path(getwd(),mn_dir)) {
      stop("Warning! Major directories were almost deleted. Adjust mapunit_download.R to avoid accidential deletion")
    } else {
      unlink(linked_loc, recursive = TRUE)
    }
    
  }
  
}

