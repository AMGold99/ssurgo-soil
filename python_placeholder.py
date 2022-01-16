# draft updated 2022-01-16

# %%
import arcpy
import arcpy.mp
import numpy
import pandas as pd

# %%
aprx = arcpy.mp.ArcGISProject("CURRENT")

# %%
map = aprx.listMaps()[0]

# %%
#create list of state abbreviations

state_zip_location = r"C:\Users\gold1\Downloads\ssurgo-soil-main(1)\ssurgo-soil-main\soil_project\state_zip"
state_abbr = "state_abbr.xlsx"
abbr_location = state_zip_location + "\\" + state_abbr
abbr_xl = pd.read_excel(abbr_location,
                       names = ['state','abbr'],
                       header = None)

state_names = abbr_xl.iloc[:,1]
state_names[0]

# %%
#load current state df


current_abbr = state_names[0]

current_excel = "soil_zip_county_" + current_abbr + ".xlsx"
state_location = state_zip_location + "\\" + current_excel
counties = pd.read_excel(state_location,
                        names=["county","fips","zip_address"],
                        header=None)

counties_nona = pd.DataFrame.dropna(counties)
county_list = counties_nona.iloc[:,1]
county_list

# %%
# ignore for now; this cell loads all shpfiles into map as layers (only use if you're going to merge
# by hand, not in a Python script)
main_directory = r"G:\Shared drives\CURI - CUR\GIS\SOIL\Entire_US_soil"

state = current_abbr
county_range = range(0,len(county_list))

for i in county_range:
    
    county = county_list.iloc[i][2:5:1]
    shp_name = "soilmu_a_" + state.lower() + county + ".shp"
    shp_path = main_directory + "\\" + state + "\\" + state + county + "\\" + shp_name
    map.addDataFromPath(shp_path)

# %%
#load all current state shpfiles into gdb as feature classes
state = current_abbr

main_directory = r"G:\Shared drives\CURI - CUR\GIS\SOIL\Entire_US_soil"

for i in county_range:
    
    county = county_list.iloc[i][2:5:1]
    shp_name = "soilmu_a_" + state.lower() + county
    
    arcpy.env.workspace = main_directory + "\\" + state + "\\" + state + county
    
    arcpy.FeatureClassToFeatureClass_conversion(shp_name,
                                                r"G:\Shared drives\CURI - CUR\GIS\SOIL\python_test\python_test.gdb",
                                                shp_name[9:14:1])

# %%
layers = map.listLayers()

# %%
#merge
arcpy.management.Merge(layers,
                       "G:\Shared drives\CURI - CUR\GIS\SOIL\python_test\python_test.gdb\AL_merge")
#find a way to put in length parameter for output field farmlndcl
