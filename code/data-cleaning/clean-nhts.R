#' Clean National Household Travel Survey Data
#' 
#' This script is designed to clean National Household Travel
#' Survey (NHTS) data. The raw data is read in and the feature names
#' are cleaned to be more interpretable. The categorical variables
#' are recoded back into their original character values using the
#' codebook in order to enhance the interpretability of the data.
#' The final data is saved as both a parquet file and a csv file in
#' the `data/clean` directory. The goal is to clean the data so that
#' it can be used for future analysis and statistical modeling.
#' 
#' @author Marion Bauman

# Load necessary libraries
library(tidyverse)
library(arrow)
library(readxl)

# Read in raw data
household <- read_csv("data/raw/hhv2pub.csv") |>
    mutate(across(everything(), as.character))
person <- read_csv("data/raw/perv2pub.csv") |>
    mutate(across(everything(), as.character))
trip <- read_csv("data/raw/tripv2pub.csv") |>
    mutate(across(everything(), as.character))
vehicle <- read_csv("data/raw/vehv2pub.csv") |>
    mutate(across(everything(), as.character))
long_distance <- read_csv("data/raw/ldtv2pub.csv") |>
    mutate(across(everything(), as.character))

# Read in the data dictionary
data_dictionary <- read_excel("data/dictionary.xlsx")

# Read in the codebook
household_codebook <- read_excel("data/codebook.xlsx", sheet = "Household")
person_codebook <- read_excel("data/codebook.xlsx", sheet = "Person")
trip_codebook <- read_excel("data/codebook.xlsx", sheet = "Trip")
vehicle_codebook <- read_excel("data/codebook.xlsx", sheet = "Vehicle")
long_distance_codebook <- read_excel("data/codebook.xlsx", sheet = "Long Distance")

clean_codebook <- function(codebook) {
    codebook |>
        select(Name, `Code / Range`, Type) |>
        rename(code_range = `Code / Range`) |>
        # Fill down the name
        fill(Name) |>
        # Fill down the type
        fill(Type) |>
        # We only need to recode categorical variables
        filter(Type == "C") |>
        mutate(
            key = str_split_fixed(code_range, "=", 2)[,1],
            value = str_split_fixed(code_range, "=", 2)[,2]
        ) |>
        mutate(key = as.character(key)) |>
        select(Name, key, value) |>
        # Nest the key and value as a tibble - we will use these to recode
        # the data later :)
        group_by(Name) |>
        nest(code_ranges = c(key, value)) |>
        ungroup()
}

# Clean the codebooks
household_codebook <- clean_codebook(household_codebook)
person_codebook <- clean_codebook(person_codebook)
trip_codebook <- clean_codebook(trip_codebook)
vehicle_codebook <- clean_codebook(vehicle_codebook)
long_distance_codebook <- clean_codebook(long_distance_codebook)

# Map the codebook to the data to recode the columns
# The codebook contains the key-value pairs for each categorical variable

recode_columns <- function(codebook, data) {
    for (i in 1:nrow(codebook)) {
        name <- codebook$Name[i]
        code_ranges <- codebook$code_ranges[[i]]
        data <- data |>
            left_join(
                code_ranges,
                by = join_by({{name}} == "key")
            ) |>
            rename("{name}_value" := "value")
    }

    # remove columns with all NA values
    data <- data %>%
        select(where(~!all(is.na(.))))
    # remove columns with all blank values
    data <- data %>%
        select(where(~!all(. == "")))

    # if a column has a _value suffix, remove the original column
    # and rename the _value column to the original column name
    new_cols <- data |>
        select(ends_with("_value")) |>
        colnames()

    for (col in new_cols) {
        orig_col <- str_remove(col, "_value")
        data <- data |>
            select(-{{orig_col}}) |>
            rename({{orig_col}} := {{col}})
    }

    return(data)
}

# Recode the columns using the codebook
household <- recode_columns(household_codebook, household)
person <- recode_columns(person_codebook, person)
trip <- recode_columns(trip_codebook, trip)
vehicle <- recode_columns(vehicle_codebook, vehicle)
long_distance <- recode_columns(long_distance_codebook, long_distance)

# Map the data dictionary to more explanatory names
data_dictionary <- data_dictionary |>
    mutate(clean_name = case_when(
        NAME == "AIRSIZE" ~ "airport_size",
        NAME == "ANNMILES" ~ "annual_miles",
        NAME == "BEGTRIP" ~ "begin_trip_date",
        NAME == "BIKESHARE22" ~ "days_used_bikeshare_last_30",
        NAME == "BIKETRANSIT" ~ "days_cycled_last_30",
        NAME == "CDIVMSAR" ~ "household_grouping",
        NAME == "CENSUS_D" ~ "census_division",
        NAME == "CENSUS_R" ~ "census_region",
        NAME == "CNTTDHH" ~ "count_household_trips",
        NAME == "CNTTDTR" ~ "count_person_trips",
        NAME == "COMMERCIALFREQ" ~ "commercial_frequency_of_veh_last_30",
        NAME == "CONDNIGH" ~ "daytime_limit_driving",
        NAME == "CONDNONE" ~ "unaffected_travel",
        NAME == "CONDPUB" ~ "limited_transit_use",
        NAME == "CONDRF" ~ "limited_transit_use_noresponse",
        NAME == "CONDRIDE" ~ "requested_rides",
        NAME == "CONDRIVE" ~ "limited_driving",
        NAME == "CONDSHARE" ~ "requested_ride_shares",
        NAME == "CONDSPEC" ~ "requires_special_transport",
        NAME == "CONDTRAV" ~ "reduce_travel_disability",
        NAME == "COV1_OHD" ~ "covid_online_delivery_impact",
        NAME == "COV1_PT" ~ "covid_public_transit_impact",
        NAME == "COV1_SCH" ~ "covid_school_travel_impact",
        NAME == "COV1_WK" ~ "covid_work_travel_impact",
        NAME == "COV2_OHD" ~ "covid_online_delivery_impact_permant",
        NAME == "COV2_PT" ~ "covid_public_transit_impact_permant",
        NAME == "COV2_SCH" ~ "covid_school_travel_impact_permant",
        NAME == "COV2_WK" ~ "covid_work_travel_impact_permant",
        NAME == "DELIVER" ~ "num_online_deliveries_last_30",
        NAME == "DELIV_FOOD" ~ "num_food_deliveries_last_30",
        NAME == "DELIV_GOOD" ~ "num_goods_deliveries_last_30",
        NAME == "DELIV_GROC" ~ "num_grocery_deliveries_last_30",
        NAME == "DELIV_PERS" ~ "num_services_deliveries_last_30",
        NAME == "DRIVE" ~ "driver_status",
        NAME == "DRIVINGOCCUPATION" ~ "drive_for_work",
        NAME == "DRIVINGVEHILCE" ~ "drive_for_work_vehicle",
        NAME == "DRVRCNT" ~ "num_drivers_in_household",
        NAME == "DRVR_FLG" ~ "driver_flag",
        NAME == "DWELTIME" ~ "time_at_destination",
        NAME == "EDUC" ~ "education_level",
        NAME == "EMPLOYMENT2" ~ "hours_worked_per_week",
        NAME == "EMPPASS" ~ "employer_pays_transit",
        NAME == "ENDTIME" ~ "end_trip_time",
        NAME == "ESCOOTERUSED" ~ "days_used_scooter_last_30",
        NAME == "EXITCDIV" ~ "exit_census_division",
        NAME == "FARCDIV" ~ "farthest_census_division_traveled",
        NAME == "FARCREG" ~ "farthest_census_region_traveled",
        NAME == "FARREAS" ~ "reason_for_travel",
        NAME == "FLAG100" ~ "all_household_completed_survey",
        NAME == "FRSTHM" ~ "started_travel_at_home",
        NAME == "GASPRICE" ~ "gas_price_at_travel_time",
        NAME == "GCDTOT" ~ "great_circle_distance_traveled",
        NAME == "GCDWORK" ~ "great_circle_distance_work",
        NAME == "GCD_FLAG" ~ "great_circle_distance_longer_than_50_miles",
        NAME == "HHACCCNT" ~ "num_household_members_on_trip",
        NAME == "HHFAMINC" ~ "household_income",
        NAME == "HHFAMINC_IMP" ~ "household_income_imputed",
        NAME == "HHMEMDRV" ~ "drove_on_trip",
        NAME == "HHRELATD" ~ "household_related",
        NAME == "HHSIZE" ~ "household_size",
        NAME == "HHVEHCNT" ~ "num_vehicles_in_household",
        NAME == "HHVEHUSETIME_DEL" ~ "days_vehicle_used_deliveries_last_30",
        NAME == "HHVEHUSETIME_OTH" ~ "days_vehicle_used_other_last_30",
        NAME == "HHVEHUSETIME_RS" ~ "days_vehicle_used_ride_shares_last_30",
        NAME == "HH_HISP" ~ "hispanic",
        NAME == "HH_RACE" ~ "race",
        NAME == "HOMEOWN" ~ "own_or_rent_home",
        NAME == "HOMETYPE" ~ "home_type",
        NAME == "HOUSEID" ~ "household_id",
        NAME == "HYBRID" ~ "hybrid_vehicle",
        NAME == "INT_FLAG" ~ "international_trip",
        NAME == "LAST30_BIKE" ~ "used_bike_last_30",
        NAME == "LAST30_BKSHR" ~ "used_bikeshare_last_30",
        NAME == "LAST30_ESCT" ~ "used_e_scooter_last_30",
        NAME == "LAST30_MTRC" ~ "used_motorcycle_last_30",
        NAME == "LAST30_PT" ~ "used_public_transit_last_30",
        NAME == "LAST30_RDSHR" ~ "used_ride_share_last_30",
        NAME == "LAST30_TAXI" ~ "used_taxi_last_30",
        NAME == "LAST30_WALK" ~ "walked_last_30",
        NAME == "LDT_FLAG" ~ "long_distance_trip",
        NAME == "LD_AMT" ~ "num_used_amtrak_last_year",
        NAME == "LD_ICB" ~ "num_used_intracity_bus_last_year",
        NAME == "LD_NUMONTRP" ~ "num_people_on_long_distance_trip",
        NAME == "LOOP_TRIP" ~ "loop_trip",
        NAME == "MAINMODE" ~ "main_mode_of_transport",
        NAME == "MAKE" ~ "vehicle_make",
        NAME == "MCTRANSIT" ~ "days_used_motorcycle_last_30",
        NAME == "MEDCOND" ~ "medical_condition",
        NAME == "MEDCOND6" ~ "medical_condition_duration",
        NAME == "MRT_DATE" ~ "date_of_most_recent_trip",
        NAME == "MSACAT" ~ "metro_area_category",
        NAME == "MSASIZE" ~ "metro_area_size",
        NAME == "NONHHCNT" ~ "num_non_household_members_on_trip",
        NAME == "NTSAWAY" ~ "num_nights_away_from_home",
        NAME == "NUMADLT" ~ "num_adults_in_household",
        NAME == "NUMONTRP" ~ "num_people_on_trip",
        NAME == "ONTD_P1" ~ "person_1_on_trip",
        NAME == "ONTD_P2" ~ "person_2_on_trip",
        NAME == "ONTD_P3" ~ "person_3_on_trip",
        NAME == "ONTD_P4" ~ "person_4_on_trip",
        NAME == "ONTD_P5" ~ "person_5_on_trip",
        NAME == "ONTD_P6" ~ "person_6_on_trip",
        NAME == "ONTD_P7" ~ "person_7_on_trip",
        NAME == "ONTD_P8" ~ "person_8_on_trip",
        NAME == "ONTD_P9" ~ "person_9_on_trip",
        NAME == "ONTD_P10" ~ "person_10_on_trip",
        NAME == "ONTP_P1" ~ "person_1_on_long_distance_trip",
        NAME == "ONTP_P2" ~ "person_2_on_long_distance_trip",
        NAME == "ONTP_P3" ~ "person_3_on_long_distance_trip",
        NAME == "ONTP_P4" ~ "person_4_on_long_distance_trip",
        NAME == "ONTP_P5" ~ "person_5_on_long_distance_trip",
        NAME == "ONTP_P6" ~ "person_6_on_long_distance_trip",
        NAME == "ONTP_P7" ~ "person_7_on_long_distance_trip",
        NAME == "ONTP_P8" ~ "person_8_on_long_distance_trip",
        NAME == "ONTP_P9" ~ "person_9_on_long_distance_trip",
        NAME == "ONTP_P10" ~ "person_10_on_long_distance_trip",
        NAME == "OUTOFTWN" ~ "away_entire_day",
        NAME == "PARK" ~ "paid_for_parking_travel_day",
        NAME == "PARK2" ~ "paid_for_parking_trip",
        NAME == "PARK2_PAMOUNT" ~ "parking_cost",
        NAME == "PARK2_PAYTYPE" ~ "parking_payment_periodicity",
        NAME == "PARKHOME" ~ "pay_home_parking",
        NAME == "PARKHOMEAMT" ~ "whether_pay_home_parking",
        NAME == "PARKHOMEAMT_PAMOUNT" ~ "home_parking_cost",
        NAME == "PARKHOMEAMT_PAYTYPE" ~ "home_parking_payment_periodicity",
        NAME == "PAYPROF" ~ "worked_last_week",
        NAME == "PERSONID" ~ "person_id",
        NAME == "PPT517" ~ "num_children_5_17",
        NAME == "PRMACT" ~ "primary_activity_not_work",
        NAME == "PROXY" ~ "proxy_respondent",
        NAME == "PSGR_FL" ~ "passenger_on_trip",
        NAME == "PTUSED" ~ "days_used_public_transit_last_30",
        NAME == "PUBTRANS" ~ "public_transit_used_on_trip",
        NAME == "QACSLAN1" ~ "non_english_language_spoken",
        NAME == "QACSLAN3" ~ "how_well_english_spoken",
        NAME == "RAIL" ~ "metro_rail_status",
        NAME == "RESP_CNT" ~ "num_respondents_in_household",
        NAME == "RET_AMZ" ~ "num_returned_amazon_dropoff_center",
        NAME == "RET_HOME" ~ "num_returned_home_pickup",
        NAME == "RET_PUF" ~ "num_returned_ups_usps_fedex",
        NAME == "RET_STORE" ~ "num_returned_store",
        NAME == "RIDESHARE22" ~ "days_used_ride_share_last_30",
        NAME == "R_AGE" ~ "respondent_age",
        NAME == "R_HISP" ~ "respondent_hispanic",
        NAME == "R_RACE" ~ "respondent_race",
        NAME == "R_RACE_IMP" ~ "respondent_race_imputed",
        NAME == "R_RELAT" ~ "respondent_relationship",
        NAME == "R_SEX" ~ "respondent_sex",
        NAME == "R_SEX_IMP" ~ "respondent_sex_imputed",
        NAME == "SAMEPLC" ~ "reason_no_travel",
        NAME == "SCHOOL1" ~ "enrolled_in_school",
        NAME == "SCHOOL1C" ~ "school_type_nontraditional",
        NAME == "SCHTRN1" ~ "school_transportation",
        NAME == "SCHTYP" ~ "school_type",
        NAME == "SEQ_TRIPID" ~ "sequential_trip_id",
        NAME == "STRATUMID" ~ "household_stratum_id",
        NAME == "STRTTIME" ~ "start_trip_time",
        NAME == "STUDE" ~ "school_program_description",
        NAME == "TAXISERVICE" ~ "days_used_taxi_last_30",
        NAME == "TDAYDATE" ~ "travel_day_date",
        NAME == "TDCASEID" ~ "trip_case_id",
        NAME == "TDWKND" ~ "weekend_trip",
        NAME == "TRAVDAY" ~ "travel_day_of_week",
        NAME == "TRIPID" ~ "trip_id",
        NAME == "TRIPPURP" ~ "trip_purpose",
        NAME == "TRNPASS" ~ "days_used_discounted_transit_last_30",
        NAME == "TRPHHVEH" ~ "vehicle_used_on_trip",
        NAME == "TRPMILES" ~ "trip_miles",
        NAME == "TRPTRANS" ~ "trip_mode",
        NAME == "TRVLCMIN" ~ "trip_duration_minutes",
        NAME == "URBAN" ~ "household_urban_classification",
        NAME == "URBANSIZE" ~ "household_urban_size",
        NAME == "URBRUR" ~ "household_urban_rural",
        NAME == "URBRUR_2010" ~ "household_urban_rural_2010",
        NAME == "USAGE1" ~ "fewer_trips_last_30",
        NAME == "USAGE2_1" ~ "fewer_trips_last_30_reason_more_deliveries",
        NAME == "USAGE2_2" ~ "fewer_trips_last_30_reason_not_feel_safe",
        NAME == "USAGE2_3" ~ "fewer_trips_last_30_reason_not_feel_clean",
        NAME == "USAGE2_4" ~ "fewer_trips_last_30_reason_not_reliable",
        NAME == "USAGE2_5" ~ "fewer_trips_last_30_reason_not_go_where_needed",
        NAME == "USAGE2_6" ~ "fewer_trips_last_30_reason_unaffordable",
        NAME == "USAGE2_7" ~ "fewer_trips_last_30_reason_health",
        NAME == "USAGE2_8" ~ "fewer_trips_last_30_reason_time",
        NAME == "USAGE2_9" ~ "fewer_trips_last_30_reason_other",
        NAME == "USAGE2_10" ~ "fewer_trips_last_30_reason_covid",
        NAME == "VEHAGE" ~ "vehicle_age",
        NAME == "VEHCASEID" ~ "vehicle_case_id",
        NAME == "VEHCOMMERCIAL" ~ "vehicle_used_for_commercial_purposes",
        NAME == "VEHCOM_DEL" ~ "vehicle_used_for_deliveries",
        NAME == "VEHCOM_OTH" ~ "vehicle_used_for_other",
        NAME == "VEHCOM_RS" ~ "vehicle_used_for_ride_shares",
        NAME == "VEHFUEL" ~ "vehicle_fuel_type",
        NAME == "VEHID" ~ "vehicle_id",
        NAME == "VEHOWNED" ~ "vehicle_owned_more_1_year",
        NAME == "VEHOWNMO" ~ "vehicle_owned_months",
        NAME == "VEHTYPE" ~ "vehicle_type",
        NAME == "VEHYEAR" ~ "vehicle_year",
        NAME == "VMT_MILE" ~ "vehicle_miles_traveled",
        NAME == "WALK" ~ "minutes_walked_from_parking",
        NAME == "WALKTRANSIT" ~ "days_walked_as_transit_last_30",
        NAME == "WEEKEND" ~ "trip_includes_weekend",
        NAME == "WHODROVE" ~ "who_drove",
        NAME == "WHODROVE_IMP" ~ "who_drove_imputed",
        NAME == "WHOMAIN" ~ "main_driver",
        NAME == "WHOPROXY" ~ "who_completed_survey",
        NAME == "WHYFROM" ~ "reason_for_travel",
        NAME == "WHYTO" ~ "reason_for_travel_to",
        NAME == "WHYTRP1S" ~ "why_trip",
        NAME == "WHYTRP90" ~ "trip_purpose_old_schema",
        NAME == "WKFMHM22" ~ "days_per_week_work_from_home",
        NAME == "WORKER" ~ "worker_status",
        NAME == "WKRCOUNT" ~ "num_workers_in_household",
        NAME == "WRKLOC" ~ "work_location",
        NAME == "WRKTRANS" ~ "work_transportation",
        NAME == "WTHHFIN" ~ "household_weight_7_day",
        NAME == "WTHHFIN2D" ~ "household_weight_2_day",
        NAME == "WTHHFIN5D" ~ "household_weight_5_day",
        NAME == "WTPERFIN" ~ "person_weight_7_day",
        NAME == "WTPERFIN2D" ~ "person_weight_2_day",
        NAME == "WTPERFIN5D" ~ "person_weight_5_day",
        NAME == "WTTRDFIN" ~ "trip_weight_7_day",
        NAME == "WTTRDFIN2D" ~ "trip_weight_2_day",
        NAME == "WTTRDFIN5D" ~ "trip_weight_5_day",
        NAME == "W_CANE" ~ "used_cane",
        NAME == "W_CHAIR" ~ "used_wheelchair",
        NAME == "W_NONE" ~ "no_assistance",
        NAME == "W_SCCH" ~ "used_blind_deaf_assistance",
        NAME == "W_WKCR" ~ "used_walker_crutches",
        NAME == "YOUNGCHILD" ~ "num_children_under_5",
        TRUE ~ NAME
    ))

# Get the household data dictionary
hh_dict <- data_dictionary |>
    filter(!is.na(HH)) |>
    select(NAME, clean_name)

# Replace the column names in the household data, matching to the hh_dict
names(household) <- names(household) |>
    map_chr(~hh_dict$clean_name[match(.x, hh_dict$NAME)])

# Get the person data dictionary
person_dict <- data_dictionary |>
    filter(!is.na(PER)) |>
    select(NAME, clean_name)

# Replace the column names in the person data, matching to the person_dict
names(person) <- names(person) |>
    map_chr(~person_dict$clean_name[match(.x, person_dict$NAME)])

# Get the trip data dictionary
trip_dict <- data_dictionary |>
    filter(!is.na(TRIP)) |>
    select(NAME, clean_name)

# Replace the column names in the trip data, matching to the trip_dict
names(trip) <- names(trip) |>
    map_chr(~trip_dict$clean_name[match(.x, trip_dict$NAME)])

# Get the vehicle data dictionary
vehicle_dict <- data_dictionary |>
    filter(!is.na(VEH)) |>
    select(NAME, clean_name)

# Replace the column names in the vehicle data, matching to the vehicle_dict
names(vehicle) <- names(vehicle) |>
    map_chr(~vehicle_dict$clean_name[match(.x, vehicle_dict$NAME)])

# Get the long distance data dictionary
long_distance_dict <- data_dictionary |>
    filter(!is.na(LDT)) |>
    select(NAME, clean_name)

# Replace the column names in the long distance data, matching to the long_distance_dict
names(long_distance) <- names(long_distance) |>
    map_chr(~long_distance_dict$clean_name[match(.x, long_distance_dict$NAME)])

# change data type to numeric using data dictionary
for (i in 1:nrow(data_dictionary)) {
    clean_name <- data_dictionary$clean_name[i]
    type <- data_dictionary$TYPE[i]
    if (type == "N" & clean_name %in% names(household)) {
        household[[clean_name]] <- as.numeric(household[[clean_name]])
    }
    if (type == "N" & clean_name %in% names(person)) {
        person[[clean_name]] <- as.numeric(person[[clean_name]])
    }
    if (type == "N" & clean_name %in% names(trip)) {
        trip[[clean_name]] <- as.numeric(trip[[clean_name]])
    }
    if (type == "N" & clean_name %in% names(vehicle)) {
        vehicle[[clean_name]] <- as.numeric(vehicle[[clean_name]])
    }
    if (type == "N" & clean_name %in% names(long_distance)) {
        long_distance[[clean_name]] <- as.numeric(long_distance[[clean_name]])
    }
}

# Change the date columns to date type
household <- household |>
    mutate(travel_day_date = ym(travel_day_date))

person <- person |>
    mutate(travel_day_date = ym(travel_day_date))

trip <- trip |>
    mutate(travel_day_date = ym(travel_day_date))

vehicle <- vehicle |>
    mutate(travel_day_date = ym(travel_day_date))

long_distance <- long_distance |>
    mutate(
        travel_day_date = ym(travel_day_date)
    )

# Save the cleaned data as parquet and csv
household |> write_parquet("data/clean/household.parquet")
household |> write_csv("data/clean/household.csv")
person |> write_parquet("data/clean/person.parquet")
person |> write_csv("data/clean/person.csv")
trip |> write_parquet("data/clean/trip.parquet")
trip |> write_csv("data/clean/trip.csv")
vehicle |> write_parquet("data/clean/vehicle.parquet")
vehicle |> write_csv("data/clean/vehicle.csv")
long_distance |> write_parquet("data/clean/long_distance.parquet")
long_distance |> write_csv("data/clean/long_distance.csv")