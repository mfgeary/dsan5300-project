# Statistical Learning Project

**DSAN 5300**

**Authors:** Marion Bauman ([@mfgeary](https://github.com/mfgeary)), Yuhan Cui, Varun Patel ([@vp472](https://github.com/vp472)), Aaron Schwall ([@aaron-schwall](https://github.com/aaron-schwall))

[![Review Assignment Due Date](https://classroom.github.com/assets/deadline-readme-button-24ddc0f5d75046c5622901739e7c5dd533143b0c8e959d652212380cedb1ea36.svg)](https://classroom.github.com/a/nEmJfSBb)

## Data Source

We are using the National Household Travel Survey (NHTS) data from 2022 for our project. The data can be found at [https://nhts.ornl.gov/downloads](https://nhts.ornl.gov/downloads) and the data dictionary can be found at [https://nhts.ornl.gov/documentation](https://nhts.ornl.gov/documentation). The NHTS is a survey on U.S. travel, conducted by the U.S. Department of Transportation (USDOT) Federal Highway Administration.

## Clean Data

There are 5 total datasets that result from the National Household Travel Survey (NHTS). These datasets are separated by different units of analysis. The datasets are as follows:
* `household`, which is the cleaned version of `hhv2pub.csv`, represents data on the household level. Each row represents one household. The id variable is `household_id`.
* `person`, the cleaned version of `perv2pub.csv`, codifies data on the person level. Each row represents one person. This has a `person_id` and is linked to the household with `household_id`.
* `trip`, the cleaned version of `tripv2pub.csv`, contains data on the trip leve. Each row is one trip taken, with `trip_id` as the unique identifier for each trip. This is linked to the household and the person(s) on the trip by `household_id` and `person_id`, respectively.
* `vehicle`, the cleaned version of `vehv2pub.csv`, has data on the vehicles used to conduct travel. Each row represents a vehicle, identified with `vehicle_id`. The vehicles are linked to a household with the `household_id`.
* `long_distance` is the cleaned version of `ldtv2pub.csv`. This contains data on long distance travel, defined as trips that exceed 50 miles in distance.

Note that all datasets are stored as both parquet for preservation of data types and csv for ease of use.

## Things to Do

- [x] Choose dataset
- [x] Clean the data
- [x] Define data science question that will be answered with data
- [x] Exploratory data analysis
- [x] Model the data using statistical learning
- [x] Analyze the results
- [x] Create poster
- [ ] Write paper
    - [ ] Introduction (`paper/paper-content/_introduction.qmd`)
    - [ ] Methods (`paper/paper-content/_methods.qmd`)
    - [ ] Results (`paper/paper-content/_results.qmd`)
    - [ ] Discussion (`paper/paper-content/_discussion.qmd`)
    - [ ] Conclusion (`paper/paper-content/_conclusion.qmd`)

## Repo Organization

The repo is organized as follows:

* `data/` contains our data as well as the documentation for the data. It contains two subfolders:
    * `raw/`, which contains the raw data
    * `clean/`, which contains the cleaned data
    * `resources/`, which includes documentation for the NHTS and related NHTS resources
* `code/` contains all of our code for the project. It is further organized into subfolders based on the type of code/phase of the project. Current subfolders are:
    * `data-cleaning/`, which contains code for cleaning the data
    * `eda/`, which has code for doing exploratory data analysis
    * `modeling/`, which contains code for all statistical learning modeling
    * `poster/`, which holds all code for creating and reproducing our final poster for the poster presentation
* `final-models/` contains the final models, stored as pickle files, and their final predictions (both as classes and as probabilities)
* `paper/` contains the code for generating our final paper using Quarto. The final paper is stored in `final-paper.qmd`, and sourced from the nested files:
    * `_extensions/` houses the relevant Quarto extensions. This includes a modified extension for styling our final paper as a professional article
    * `paper-content/` contains the text for our paper split into multiple Quarto files
    * `imgs/` holds the images for our final paper