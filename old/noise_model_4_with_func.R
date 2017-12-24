#! /usr/bin/R
library(dplyr)
library(tidyr)
library(ggplot2)

source("/home/iradinsky/project/model_evaluation.R")

df <- read.csv("/home/iradinsky/project/final_noise.csv", header=TRUE) %>%
    na.omit()

## ggplots?
df %>%
    mutate(ratio=noise_complaints/(other_complaints+noise_complaints)) %>%
    ggplot(aes(x=avg_temp, y=ratio)) +
    geom_point()

sample_size <- floor(0.80 * nrow(df))

set.seed(17)
ind <- sample(seq_len(nrow(df)), size=sample_size)

train <- df[ind, ]
test <- df[-ind, ]

X_train <- model.matrix(~ avg_temp + daylight_hours + bad_weather + hours_overcast, data=train)
y_train <- cbind(train$other_complaints, train$noise_complaints)

results <- create_and_evaluate_model(X_train, y_train)
summary(results)
