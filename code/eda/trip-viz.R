library(tidyverse)

# Load data
trips <- read_csv("data/clean/trip.csv")

trips |>
    filter(trip_purpose != "Not ascertained") |>
    count(trip_purpose) |>
    ggplot(aes(y = reorder(trip_purpose, n), x = n)) +
    geom_col(fill = "#002e62") +
    labs(
        title = "Trip Purpose Distribution",
        y = "Trip Purpose",
        x = "Number of Trips"
    ) +
    # wrap y axis labels
    scale_y_discrete(labels = ~stringr::str_wrap(., width = 18)) +
    scale_x_continuous(labels = scales::comma, limits = c(0, 7850)) +
    # add value labels
    geom_text(aes(label = scales::comma(n)), color = "white", hjust = 1.3, size = 3) +
    theme_minimal() +
    # make font size bigger
    theme(text = element_text(size = 12))

# Save plot
ggsave("code/poster/trip-purpose-distribution.png", width = 8, height = 5, dpi = 300)

all_data <- read_csv("models/all_probs.csv")

all_data |>
    select(NN, `Logistic Regression`, Xgboost, SVM, RF, Actual) |>
    group_by(Actual) |>
    mutate(count = n()) |>
    ungroup() |>
    pivot_longer(cols = -c(Actual, count), names_to = "Model", values_to = "Prediction") |>
    filter(Actual == Prediction) |>
    summarise(.by = c(Model, Actual, Prediction), n = n(), count = first(count)) |>
    mutate(perc = n/count) |>
    ggplot(aes(x = Actual, y = perc, color = Model)) +
    geom_point(aes(shape = Model), size = 3) +
    geom_line() +
    scale_y_continuous(labels = scales::percent) +
    labs(
        title = "Model Performance by Class",
        x = "Trip Purpose (True)",
        y = "Class Prediction Accuracy"
    ) +
    #'Home-based other (HBO)', 'Home-based shopping (HBSHP)','Home-based social/recreational (HBSOC)', 'Home-based work (HBW)','Not a home-based trip (NHB)'],
    scale_x_continuous(labels = c('Home-based\nother (HBO)', 'Home-based \nshopping (HBSHP)','Home-based social/\nrecreational (HBSOC)', 'Home-based work (HBW)', 'Not a home-based\ntrip (NHB)')) +
    theme_minimal() +
    scale_color_manual(values = c("#002e62", "#BBBCBC", "#5FA343", "#862633", "#F2A900"))

# Save plot
ggsave("code/poster/model-performance-by-class.png", width = 8, height = 5, dpi = 300)

# Visualize the certainty of the model
all_data |>
    select(-c(NN, `Logistic Regression`, Xgboost, SVM, RF)) |>
    pivot_longer(cols = -c(Actual), names_to = "Model", values_to = "Prediction") |>
    filter(Actual == as.numeric(str_split_fixed(Model, "_", 2)[, 2])) |>
    mutate(model = str_split_fixed(Model, "_", 2)[, 1]) |>
    mutate(Actual = as.character(Actual)) |>
    ggplot(aes(x = Actual, y = Prediction, color = model, group = Model)) +
    geom_boxplot(outliers = FALSE) +
    theme_minimal() +
    scale_color_manual(values = c("#002e62", "#BBBCBC", "#5FA343", "#862633", "#F2A900")) +
    scale_x_discrete(labels = c('Home-based\nother (HBO)', 'Home-based \nshopping (HBSHP)','Home-based social/\nrecreational (HBSOC)', 'Home-based work (HBW)', 'Not a home-based\ntrip (NHB)')) +
    labs(
        title = "Model Prediction Certainty by Class",
        x = "Trip Purpose (True)",
        y = "Model Prediction Certainty"
    )

# Save plot
ggsave("code/poster/model-prediction-certainty-by-class.png", width = 8, height = 5, dpi = 300)

