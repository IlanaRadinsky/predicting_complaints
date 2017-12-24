#! /usr/bin/R
library(dplyr)
library(tidyr)
library(ggplot2)
library(glmnet)
library(ROCR)
library(boot)

df <- read.csv("/home/iradinsky/project/final_noise.csv", header=TRUE) %>%
    na.omit()

# First attempt at model - no cross validation
# Using glm
sample_size <- floor(0.80 * nrow(df))

set.seed(17)
train_ind <- sample(seq_len(nrow(df)), size=sample_size)

train <- df[train_ind, ]
test <- df[-train_ind, ]

model1 <- glm(formula = perc_noise_complaints ~ avg_temp + daylight_hours + bad_weather + hours_overcast, data = train)
summary(model1)

## Second attempt at model - cross validation
## Using cv.glmnet
X_train <- model.matrix(perc_noise_complaints ~ avg_temp + daylight_hours + bad_weather + hours_overcast, data = train)
y_train <- as.matrix(train$perc_noise_complaints)

model2 <- cv.glmnet(X_train, y_train)
coef(model2, s="lambda.min")

X_test <- model.matrix(perc_noise_complaints ~ avg_temp + daylight_hours + bad_weather + hours_overcast, data = test)

with_pred <-
    test %>%
    mutate(pred=predict(model2, newx=X_test, s="lambda.min", type="response"), perc_error = abs(pred-perc_noise_complaints)/perc_noise_complaints, sq_error = (pred-perc_noise_complaints)^2) %>%
    select(perc_noise_complaints, pred, perc_error, everything())

head(with_pred)
mean(with_pred$sq_error)

summary(with_pred)
model2$cvm[model2$lambda==model2$lambda.min]

coef(model2, s="lambda.min")

## Third attempt - using glm and k-fold cross validation
model3 <- glm(perc_noise_complaints ~ avg_temp + daylight_hours + bad_weather + hours_overcast, data = df)

set.seed(17)

cv.mse.model3 = rep(0,5)

for (i in 1:5) {
    cv.mse.model3[i] = cv.glm(df, model3, K=5)$delta[1]
}

mean(cv.mse.model3)

## Fourth attempt - using glm and k-fold cross validation
## Changed y to log(y)
model4 <- glm(log(perc_noise_complaints) ~ avg_temp + daylight_hours + bad_weather + hours_overcast, data = df)

set.seed(17)

cv.mse.model4 = rep(0,5)

for (i in 1:5) {
    cv.mse.model4[i] = cv.glm(df, model4, K=5)$delta[1]
}

mean(cv.mse.model4)

## Plan for next time - look at file:///C:/MSR-DS3/coursework/week3/ML_Modeling.html
## Copy for loop to compute mse for ols, lasso, and ridge, and find the one with the lowest mse
