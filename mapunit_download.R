#Title: Mapunit Download
#Author: Asa Gold
#Date: 11/30/21

#load packages
library(readxl)
library(dplyr)
library(tidyverse)
library(readr)
library(filenamer)

#extend timeout option so for loop doesn't interrupt itself
options(timeout = 500)

#set common prefix for zip downloads
prefix <- "https://websoilsurvey.sc.egov.usda.gov/DSD/Download/Cache/SSA/"

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


#specify state
state <- "IA"

#specify location of file containing zip addresses
excel_scrape <- as.character(
  filenamer::filename(
    paste("soil_zip_county_",state,sep=""), 
    ext = "xlsx", 
    date = NA, 
    time = NA)
  )
scrape_location <- file.path(getwd(),"Land_Use_Rights","state_zip",excel_scrape)


#read in zip address suffixes from excel and create 'link' variable for downloads
soil_zip <- read_excel(scrape_location, col_names = c('county','fips','download')) %>%
  drop_na() %>%
  mutate(link = paste(prefix,.$download,sep = ""))


for(i in 1:nrow(soil_zip)) {

#extract download link for current county
link <- as.character(soil_zip[i,4])

#extract current county name from download link
county <- stringr::str_sub(link,
                           str_locate(link,"_SSA_")[[2]]+1,
                           str_locate(link,"_SSA_")[[2]]+5
                           )

#download current county zip file into the R session
download.file(link, 
              destfile = file.path(getwd(),"Land_Use_Rights","mapunit",county), 
              quiet = TRUE)


#unzip county file
zipF <- file.path(getwd(),"Land_Use_Rights","mapunit",county)
outDir <- file.path(getwd(),"Land_Use_Rights")
unzip(zipF,exdir=outDir)


#reads in raw mapunit txt file and appends var names
mapunit_df <- readr::read_delim(
  file.path(getwd(),"Land_Use_Rights",county,"tabular","mapunit.txt"), 
  col_names = mu_vars, 
  delim = "|",
  show_col_types = FALSE) %>%
  rename(MUSYM = "musym") %>%
  select(MUSYM,farmlndcl)

#removes zip file and unzipped file to save space
file.remove(file.path(getwd(),"Land_Use_Rights","mapunit",county))
unlink(file.path(getwd(),"Land_Use_Rights",county), recursive = TRUE)

#writes mapunit df to mapunit folder, labelled by county
write_csv(mapunit_df, file.path(getwd(),"Land_Use_Rights/mapunit",paste(county,"mu.csv",sep="")))

}

