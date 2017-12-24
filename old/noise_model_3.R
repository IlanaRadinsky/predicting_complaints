#! /usr/bin/R
library(dplyr)
library(tidyr)
library(ggplot2)
library(glmnet)
library(ROCR)
library(boot)

df <- read.csv("/home/iradinsky/project/final_noise.csv", header=TRUE) %>%
    na.omit()

sample_size <- floor(0.80 * nrow(df))

set.seed(17)
train_ind <- sample(seq_len(nrow(df)), size=sample_size)

train <- df[train_ind, ]
test <- df[-train_ind, ]

X_train <- model.matrix(perc_noise_complaints ~ avg_temp + daylight_hours + bad_weather + hours_overcast, data = train)
y_train <- as.matrix(train$perc_noise_complaints)

X_test <- model.matrix(perc_noise_complaints ~ avg_temp + daylight_hours + bad_weather + hours_overcast, data = test)
y_test <- as.matrix(test$perc_noise_complaints)

## Create dataframes for OLS
X_train_df <- train %>%
    select(-perc_noise_complaints, -date)
X_test_df <- test %>%
    select(-perc_noise_complaints, -date)

y_train_df <- train %>%
    select(perc_noise_complaints)
y_test_df <- test %>%
    select(perc_noise_complaints)

## OLS
ols <- glm(perc_noise_complaints ~ avg_temp + daylight_hours + bad_weather + hours_overcast, data = train, family = "binomial")

y_hat_train <- predict(ols, newdata = train, type="response")
y_hat_test <- predict(ols, newdata = test, type="response")

mse.ols.train <- mean((y_hat_train - train$perc_noise_complaints)^2)
mse.ols.test <- mean((y_hat_test - test$perc_noise_complaints)^2)

## LASSO
lasso <- cv.glmnet(X_train, y=as.factor(y_train), alpha = 1, family="binomial")
y_hat_train <- predict(lasso, newx = X_train, s="lambda.min", type="response")
y_hat_test <- predict(lasso, newx = X_test, s="lambda.min", type="response")

mse.lasso.train <- mean((y_hat_train - y_train)^2)
mse.lasso.test <- mean((y_hat_test - y_test)^2)

## Ridge
ridge <- cv.glmnet(X_train, y_train, alpha = 0, family="binomial")
y_hat_train <- predict(ridge, newx = X_train, s="lambda.min", type="response")
y_hat_test <- predict(ridge, newx = X_test, s="lambda.min", type="response")

mse.ridge.train <- mean((y_hat_train - y_train)^2)
mse.ridge.test <- mean((y_hat_test - y_test)^2)

## LASSO-Ridge
lr <- cv.glmnet(X_train, y_train, alpha = 0.5, family="binomial")
y_hat_train <- predict(lr, newx = X_train, s="lambda.min", type="response")
y_hat_test <- predict(lr, newx = X_test, s="lambda.min", type="response")

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
