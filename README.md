# Statistical Learning Project

**DSAN 5300**

**Authors:** Marion Bauman ([@mfgeary](https://github.com/mfgeary)), Yuhan Cui, Varun Patel ([@vp472](https://github.com/vp472)), Aaron Schwall ([@aaron-schwall](https://github.com/aaron-schwall))

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

## Exploratory Data Analysis

Our EDA can be found in the `eda/` folder. It can be viewed in either `eda.html` or `eda.pdf`.

## Things to Do

- [x] Choose dataset
- [x] Clean the data
- [ ] Define data science question that will be answered with data
- [x] Exploratory data analysis
- [ ] Model the data using statistical learning
- [ ] Analyze the results
- [ ] Create poster

## Repo Organization

The repo is organized as follows:

* `data/` contains our data as well as the documentation for the data. It contains two subfolders:
    * `raw/`, which contains the raw data, and
    * `clean/`, which contains the cleaned data.
* `code/` contains all of our code for the project. It is further organized into subfolders based on the type of code/phase of the project. Current subfolders are:
    * `data-cleaning/`, which contains code for cleaning the data
    * `eda/`, which has code for doing exploratory data analysis
