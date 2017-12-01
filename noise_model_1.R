#! /usr/bin/R
library(dplyr)
library(tidyr)
library(ggplot2)
library(glmnet)
 
df <- read.csv("/home/iradinsky/project/final_noise.csv", header=TRUE)

sample_size <- floor(0.80 * nrow(df))

set.seed(17)
train_ind <- sample(seq_len(nrow(df)), size=sample_size)

train <- df[train_ind, ]
test <- df[-train_ind, ]

X_train <- train %>%
    select(-perc_noise_complaints)

y_train <- train %>%
    select(perc_noise_complaints)

model <- cv.glmnet(X_train, y_train)
