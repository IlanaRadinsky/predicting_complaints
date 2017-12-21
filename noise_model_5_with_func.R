#! /usr/bin/R
library(dplyr)
library(tidyr)
library(ggplot2)

source("/home/iradinsky/project/model_evaluation.R")

df <- read.csv("/home/iradinsky/project/final_noise_with_dow.csv", header=TRUE) %>%
    na.omit()

## ggplots?
df %>%
    mutate(ratio=noise_complaints/(other_complaints+noise_complaints)) %>%
    ggplot(aes(x=avg_temp, y=ratio)) +
    geom_point()

df %>%
    mutate(ratio=noise_complaints/(other_complaints+noise_complaints)) %>%
    ggplot(aes(x=avg_temp, y=ratio, color=day_of_week)) +
    geom_point() +
    geom_smooth()

sample_size <- floor(0.80 * nrow(df))

set.seed(17)
ind <- sample(seq_len(nrow(df)), size=sample_size)

train <- df[ind, ]
test <- df[-ind, ]

y_train <- cbind(train$other_complaints, train$noise_complaints)

X_train_1 <- model.matrix(~ avg_temp + daylight_hours + bad_weather + hours_overcast + day_of_week, data=train)

results_1 <- create_and_evaluate_model(X_train_1, y_train)
summary(results_1)

X_train_2 <- model.matrix(~ avg_temp*day_of_week + daylight_hours + bad_weather + hours_overcast, data=train)

results_2 <- create_and_evaluate_model(X_train_2, y_train)
summary(results_2)
