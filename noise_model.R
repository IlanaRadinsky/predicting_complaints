#! /usr/bin/R
library(dplyr)
library(tidyr)
library(ggplot2)
library(glmnet)
library(scales)

source("model_evaluation.R")

df <- read.csv("final_noise_with_dow.csv", header=TRUE) %>%
    na.omit() %>%
    mutate(ratio=noise_complaints/(other_complaints+noise_complaints))

## ggplots!
## avg_temp vs. ratio
## -> hard to see a clear trend
df %>%
    ggplot(aes(x=avg_temp, y=ratio)) +
    geom_point()

## avg_temp vs. ratio split by day_of_week
## -> clear trends!
pdf("final_plot_1.pdf")
df %>%
    ggplot(aes(x=avg_temp, y=ratio, color=as.factor(day_of_week))) +
    geom_point() +
    geom_smooth() +
    scale_y_continuous(labels=percent) +
    labs(title='Average Temperature vs. Ratio of Noise Complaints',
         x='Average Temperature (F)',
         y='# noise complaints / # total complaints',
         color='Day of week')
dev.off()

## daylight_hours vs. ratio split by day_of_week
## -> clear trends, but x-axis looks weird bc daylight_hours
##    are only whole-number values
df %>%
    ggplot(aes(x=daylight_hours, y=ratio, color=day_of_week)) +
#    geom_point() +
    geom_smooth()

df %>%
    ggplot(aes(x=avg_temp, y=ratio, color=as.factor(daylight_hours))) +
    geom_point() +
    geom_smooth()

df %>%
    ggplot(aes(x=avg_temp, y=ratio, color=as.factor(daylight_hours))) +
    facet_wrap(~ day_of_week) +
    geom_point() +
    geom_smooth()

df %>%
    ggplot(aes(x=avg_temp, y=ratio, color=day_of_week)) +
    facet_wrap(~ as.factor(daylight_hours)) +
    geom_point() +
    geom_smooth()

## avg_temp vs. ratio split by gloomy_today
df %>%
    ggplot(aes(x=avg_temp, y=ratio, color=as.factor(gloomy_today))) +
    geom_point() +
    geom_smooth()

## avg_temp vs. ratio split by gloomy_past_two_days
df %>%
    ggplot(aes(x=avg_temp, y=ratio, color=as.factor(gloomy_past_two_days))) +
    geom_point() +
    geom_smooth()

## avg_temp vs. ratio split by gloomy_past_three_days
df %>%
    ggplot(aes(x=avg_temp, y=ratio, color=as.factor(gloomy_past_three_days))) +
    geom_point() +
    geom_smooth()

## avg_temp vs. ratio split by bad_weather
df %>%
    ggplot(aes(x=avg_temp, y=ratio, color=as.factor(bad_weather))) +
    geom_point() +
    geom_smooth()

## Model Setup
sample_size <- floor(0.80 * nrow(df))

set.seed(17)
ind <- sample(seq_len(nrow(df)), size=sample_size)

train <- df[ind, ]
test <- df[-ind, ]

y_train <- cbind(train$other_complaints, train$noise_complaints)
y_test <- cbind(test$other_complaints, test$noise_complaints)

## MODEL 1
## Train
X_train_1 <- model.matrix(~ avg_temp + daylight_hours + bad_weather + gloomy_today + gloomy_past_two_days + gloomy_past_three_days + day_of_week, data=train)

model1 <- cv.glmnet(X_train_1, y_train, family="binomial")
coef(model1, s="lambda.min")

results_train1 <- evaluate_model(X_train_1, y_train, model1)
summary(results_train1)

## Test
X_test_1 <- model.matrix(~ avg_temp + daylight_hours + bad_weather + gloomy_today + gloomy_past_two_days + gloomy_past_three_days + day_of_week, data=test)

results_test1 <- evaluate_model(X_test_1, y_test, model1)

## MODEL 2
## Train
X_train_2 <- model.matrix(~ avg_temp*day_of_week + daylight_hours + bad_weather + gloomy_today + gloomy_past_two_days + gloomy_past_three_days, data=train)

model2 <- cv.glmnet(X_train_2, y_train, family="binomial")
coef(model2, s="lambda.min")

results_train2 <- evaluate_model(X_train_2, y_train, model2)
summary(results_train2)

## Test
X_test_2 <- model.matrix(~ avg_temp*day_of_week + daylight_hours + bad_weather + gloomy_today + gloomy_past_two_days + gloomy_past_three_days, data=test)

results_test2 <- evaluate_model(X_test_2, y_test, model2)
summary(results_test2)

## MODEL 3
## Train
X_train_3 <- model.matrix(~ avg_temp*day_of_week*daylight_hours + bad_weather + gloomy_today + gloomy_past_two_days + gloomy_past_three_days, data=train)

model3 <- cv.glmnet(X_train_3, y_train, family="binomial")
coef(model3, s="lambda.min")

results_train3 <- evaluate_model(X_train_3, y_train, model3)
summary(results_train3)

## Test
X_test_3 <- model.matrix(~ avg_temp*day_of_week*daylight_hours + bad_weather + gloomy_today + gloomy_past_two_days + gloomy_past_three_days, data=test)

results_test3 <- evaluate_model(X_test_3, y_test, model3)
summary(results_test3)

pdf("final_plot_2.pdf")
results_train3$calibration_plot
dev.off()
