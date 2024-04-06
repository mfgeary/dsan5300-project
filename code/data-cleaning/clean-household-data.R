#' Clean NHTS Household Data
#' 
#' This script cleans the NHTS household data file, preparing
#' it for future statistical analysis and modeling.
#' 
#' @author Marion Bauman

# Load necessary libraries
library(tidyverse)
library(arrow)
library(readxl)

# Load the household data
household <- read_parquet("data/clean/clean-names/household.parquet")

# Load the codebook for the household data

