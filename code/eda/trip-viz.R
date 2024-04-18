library(tidyverse)

# Load data
trips <- read_csv("data/clean/trip.csv")

trips |>
    filter(trip_purpose != "Not ascertained") |>
    count(trip_purpose) |>
    ggplot(aes(y = reorder(trip_purpose, n), x = n)) +
    geom_col(fill = "#002e62", width = 0.7) +
    labs(
        title = "Distribution of Trip Purpose",
        y = "Trip Purpose",
        x = "Number of Trips"
    ) +
    # wrap y axis labels
    scale_y_discrete(labels = ~stringr::str_wrap(., width = 18)) +
    scale_x_continuous(labels = scales::comma, limits = c(0, 7850)) +
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
    mutate(
        Model = case_when(
            Model == "NN" ~ "Neural Network",
            Model == "Logistic Regression" ~ "Logistic Regression",
            Model == "Xgboost" ~ "XGBoost",
            Model == "SVM" ~ "Support Vector Machine",
            Model == "RF" ~ "Random Forest"
        )
    ) |>
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
    scale_x_continuous(labels = c('Home-based\nother (HBO)', 'Home-based \nshopping (HBSHP)','Home-based social/\nrecreational (HBSOC)', 'Home-based\nwork (HBW)', 'Not a home-based\ntrip (NHB)')) +
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
    scale_color_manual(values = c("#002e62", "#BBBCBC", "#5FA343", "#862633", "#F2A900"), labels = c("Neural Network", "Logistic Regression", "XGBoost", "Support Vector Machine", "Random Forest")) +
    scale_x_discrete(labels = c('Home-based\nother (HBO)', 'Home-based \nshopping (HBSHP)','Home-based social/\nrecreational (HBSOC)', 'Home-based\nwork (HBW)', 'Not a home-based\ntrip (NHB)')) +
    labs(
        title = "Model Prediction Probability by Class",
        x = "Trip Purpose",
        y = "Predicted Probability",
        color = "Model"
    )

# Save plot
ggsave("code/poster/model-prediction-certainty-by-class.png", width = 8, height = 5, dpi = 300)

# Create ROC AUC curve in ggplot
library(tidymodels)
nn_auc <- all_data |>
    select(-c(NN, `Logistic Regression`, Xgboost, SVM, RF)) |>
    select(starts_with("NN") | Actual) |>
    mutate(Actual = as.factor(Actual)) |>
    rename(
        ".pred_0" = NN_0,
        ".pred_1" = NN_1,
        ".pred_2" = NN_2,
        ".pred_3" = NN_3,
        ".pred_4" = NN_4
    ) |>
    roc_curve(truth = Actual, c(.pred_0, .pred_1, .pred_2, .pred_3, .pred_4))
logit_auc <- all_data |>
    select(-c(NN, `Logistic Regression`, Xgboost, SVM, RF)) |>
    select(starts_with("Logit") | Actual) |>
    mutate(Actual = as.factor(Actual)) |>
    rename(
        ".pred_0" = `Logit_0`,
        ".pred_1" = `Logit_1`,
        ".pred_2" = `Logit_2`,
        ".pred_3" = `Logit_3`,
        ".pred_4" = `Logit_4`
    ) |>
    roc_curve(truth = Actual, c(.pred_0, .pred_1, .pred_2, .pred_3, .pred_4))
xgb_auc <- all_data |>
    select(-c(NN, `Logistic Regression`, Xgboost, SVM, RF)) |>
    select(starts_with("Xgboost") | Actual) |>
    mutate(Actual = as.factor(Actual)) |>
    rename(
        ".pred_0" = Xgboost_0,
        ".pred_1" = Xgboost_1,
        ".pred_2" = Xgboost_2,
        ".pred_3" = Xgboost_3,
        ".pred_4" = Xgboost_4
    ) |>
    roc_curve(truth = Actual, c(.pred_0, .pred_1, .pred_2, .pred_3, .pred_4))
svm_auc <- all_data |>
    select(-c(NN, `Logistic Regression`, Xgboost, SVM, RF)) |>
    select(starts_with("SVM") | Actual) |>
    mutate(Actual = as.factor(Actual)) |>
    rename(
        ".pred_0" = SVM_0,
        ".pred_1" = SVM_1,
        ".pred_2" = SVM_2,
        ".pred_3" = SVM_3,
        ".pred_4" = SVM_4
    ) |>
    roc_curve(truth = Actual, c(.pred_0, .pred_1, .pred_2, .pred_3, .pred_4))
rf_auc <- all_data |>
    select(-c(NN, `Logistic Regression`, Xgboost, SVM, RF)) |>
    select(starts_with("RF") | Actual) |>
    mutate(Actual = as.factor(Actual)) |>
    rename(
        ".pred_0" = RF_0,
        ".pred_1" = RF_1,
        ".pred_2" = RF_2,
        ".pred_3" = RF_3,
        ".pred_4" = RF_4
    ) |>
    roc_curve(truth = Actual, c(.pred_0, .pred_1, .pred_2, .pred_3, .pred_4))

auc_data <- bind_rows(
    nn_auc %>% mutate(Model = "Neural Network"),
    logit_auc %>% mutate(Model = "Logistic Regression"),
    xgb_auc %>% mutate(Model = "XGBoost"),
    svm_auc %>% mutate(Model = "SVM"),
    rf_auc %>% mutate(Model = "Random Forest")
)

auc_data |>
    autoplot()

auc_data |>

    mutate(.level = case_when(
        .level == "0" ~ "Home-based other (HBO)",
        .level == "1" ~ "Home-based shopping (HBSHP)",
        .level == "2" ~ "Home-based social/\nrecreational (HBSOC)",
        .level == "3" ~ "Home-based work (HBW)",
        .level == "4" ~ "Not a home-based trip (NHB)"
    )) |>
    ggplot(aes(x = 1 - specificity, y = sensitivity, color = Model)) +
    geom_path() +
    geom_abline(slope = 1, intercept = 0, linetype = "dashed", linewidth = 0.25) +
    labs(
        title = "ROC AUC Curve",
        x = "1 - Specificity",
        y = "Sensitivity"
    ) +
    theme_minimal() +
    scale_color_manual(values = c("#002e62", "#BBBCBC", "#5FA343", "#862633", "#F2A900")) +
    facet_wrap(~.level)

auc_data |>
    filter(Model == "Neural Network") |>
    ggplot(aes(x = 1 - specificity, y = sensitivity)) +
    geom_path() +
    geom_abline(slope = 1, intercept = 0, linetype = "dashed") +
    labs(
        title = "ROC AUC Curve (Neural Network)",
        x = "1 - Specificity",
        y = "Sensitivity"
    ) +
    theme_minimal() +
    scale_color_manual(values = c("#002e62", "#BBBCBC", "#5FA343", "#862633", "#F2A900"))

auc_data |>
    roc_curve
    autoplot()

# Save plot
ggsave("code/poster/roc-auc-curve.png", width = 8, height = 5, dpi = 300)

max_depth_accuracies <- read_csv("models/max_depth_accuracies.csv")

max_depth_accuracies |>
    janitor::clean_names() |>
    ggplot(aes(x = max_depth, y = testing_accuracy)) +
    geom_line(color = "#5FA343") +
    geom_point(color = "#5FA343") +
    labs(
        title = "Random Forest Max Depth vs. Accuracy",
        x = "Tree Max Depth",
        y = "Accuracy"
    ) +
    theme_minimal() 

# Save plot
ggsave("code/poster/rf-max-depth-vs-accuracy.png", width = 8, height = 5, dpi = 300)

