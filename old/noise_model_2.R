#! /usr/bin/R
library(dplyr)
library(tidyr)
library(ggplot2)
library(glmnet)
library(ROCR)
library(boot)

df <- read.csv("/home/iradinsky/project/final_noise.csv", header=TRUE) %>%
    na.omit() %>%
    mutate(log_perc = log(perc_noise_complaints))

sample_size <- floor(0.80 * nrow(df))

set.seed(17)
train_ind <- sample(seq_len(nrow(df)), size=sample_size)

train <- df[train_ind, ]
test <- df[-train_ind, ]

X_train <- model.matrix(log_perc ~ avg_temp + daylight_hours + bad_weather + hours_overcast, data = train)
y_train <- as.matrix(train$log_perc)

X_test <- model.matrix(log_perc ~ avg_temp + daylight_hours + bad_weather + hours_overcast, data = test)
y_test <- as.matrix(test$log_perc)

## Create dataframes for OLS
X_train_df <- train %>%
    select(-log_perc, -perc_noise_complaints, -date)
X_test_df <- test %>%
    select(-log_perc, -perc_noise_complaints, -date)

y_train_df <- train %>%
    select(log_perc)
y_test_df <- test %>%
    select(log_perc)

## OLS
ols <- glm(log_perc ~ avg_temp + daylight_hours + bad_weather + hours_overcast, data = train)

y_hat_train <- predict(ols, newdata = train)
y_hat_test <- predict(ols, newdata = test)

mse.ols.train <- mean((y_hat_train - train$log_perc)^2)
mse.ols.test <- mean((y_hat_test - test$log_perc)^2)

## LASSO
lasso <- cv.glmnet(X_train, y_train, alpha = 1)
y_hat_train <- predict(lasso, newx = X_train, s="lambda.min")
y_hat_test <- predict(lasso, newx = X_test, s="lambda.min")

mse.lasso.train <- mean((y_hat_train - y_train)^2)
mse.lasso.test <- mean((y_hat_test - y_test)^2)

## Ridge
ridge <- cv.glmnet(X_train, y_train, alpha = 0)
y_hat_train <- predict(ridge, newx = X_train, s="lambda.min")
y_hat_test <- predict(ridge, newx = X_test, s="lambda.min")

mse.ridge.train <- mean((y_hat_train - y_train)^2)
mse.ridge.test <- mean((y_hat_test - y_test)^2)

## LASSO-Ridge
## Ridge
lr <- cv.glmnet(X_train, y_train, alpha = 0.5)
y_hat_train <- predict(lr, newx = X_train, s="lambda.min")
y_hat_test <- predict(lr, newx = X_test, s="lambda.min")

mse.lr.train <- mean((y_hat_train - y_train)^2)
mse.lr.test <- mean((y_hat_test - y_test)^2)

## Results
print(mse.ols.train)
print(mse.ols.test)
print(coef(ols))
print(summary(ols))

print(mse.lasso.train)
print(mse.lasso.test)
print(coef(lasso, s="lambda.min"))
      
print(mse.ridge.train)
print(mse.ridge.test)
print(coef(ridge, s="lambda.min"))
      
print(mse.lr.train)
print(mse.lr.test)
print(coef(lr, s="lambda.min"))
