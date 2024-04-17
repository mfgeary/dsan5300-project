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
