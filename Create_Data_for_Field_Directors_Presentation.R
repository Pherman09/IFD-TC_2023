# Create_Data_for_Field_Directors_Presentation.R 
#  
# This script creates the data used in the Introduction to R Course for the 
# Field Directors Conference. 
#
# Authored By: Peter Herman
# Last Edited: 05-20-23

##########
# setup  #
##########
library(survey)
library(dplyr)
library(readr)
library(sf)
library(tidycensus)

setwd(r"(C:\Users\peter\OneDrive\Documents\Work\Field_Directors\Setup)")
dir.create("Example_Datasets")

###########################################################
# Create and Export California Student Performance Data   #
###########################################################
#More info about this dataset: https://r-survey.r-forge.r-project.org/survey/html/api.html

# Load in California Data
data(api)

# Rename field so it's clearer
Raw_School_Data <- apipop %>%
  rename(school_id = cds) %>%
  mutate(cname2 = case_when(
    cname == "San Francisco" ~ "SanFrancisco",
    TRUE ~ cname
  )) %>%
  select(-cname) %>%
  rename(cname = cname2)



##############################
# Prepare Data Dictionary    #
##############################
Data_Dictionary_Raw <- read_delim("data_dictionary_raw_text.txt",delim="\t")

Data_Dictionary_Field_Names <- Data_Dictionary_Raw %>%
  mutate(row_number = 1:n()) %>%
  mutate(even_number = row_number %% 2) %>%
  filter(even_number == 0) %>%
  mutate(new_row_number = 1:n())

Data_Dictionary_Field_Values <- Data_Dictionary_Raw %>%
  mutate(row_number = 1:n()) %>%
  mutate(even_number = row_number %% 2) %>%
  filter(even_number == 1) %>%
  rename(field_definition = field_name) %>%
  filter(!field_definition == "field_definition") %>%
  mutate(new_row_number = 1:n())

Data_Dictionary_Clean <- Data_Dictionary_Field_Names %>%
  left_join(Data_Dictionary_Field_Values,"new_row_number") %>%
  select(field_name,field_definition)


#################################
# California County Shapefile   #
#################################
# More about tidycensus https://walker-data.com/tidycensus/articles/basic-usage.html
# Census API Key Signup: https://api.census.gov/data/key_signup.html
CA_Counties <- get_acs(geography = "county", 
                       variables = c(`MHIncome` = "B19013_001"), 
                       state = "CA", 
                       year = 2021,
                       geometry = TRUE) %>%
  rename(MHIncome = estimate ) %>%
  select(GEOID, NAME, MHIncome)
  

##################
# Export and ZIP #  
##################
write_delim(Raw_School_Data,"Example_Datasets/California_Academic_Performance_Index.txt",delim = "\t")
write_csv(Data_Dictionary_Clean,"Example_Datasets/California_Academic_Performance_Index_Data_Ditionary.csv")
st_write(CA_Counties,"Example_Datasets/California_Counties.geojson",delete_dsn =TRUE)

files2zip <- dir('Example_Datasets', full.names = TRUE)
zip(zipfile = 'Example_Datasets', files = files2zip)

