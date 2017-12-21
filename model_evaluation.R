evaluate_model <- function(X_train, y_train, model1) {
    library(dplyr)
    library(tidyr)
    library(ggplot2)
    library(glmnet)
    library(ROCR)
    library(boot)
    library(scales)

    #model1 <- cv.glmnet(X_train, y_train, family="binomial")
    #coef(model1, s="lambda.min")

    predictions_model1 <- data.frame(y_train) %>%
        merge(data.frame(predict(model1, X_train, type="response", s="lambda.min")), by="row.names")
    colnames(predictions_model1) <- c("Row.names", "other", "noise", "pred")
    predictions_model1 <- predictions_model1 %>%
        mutate(actual = (noise)/(noise+other))
    head(predictions_model1)

    mse <- mean((predictions_model1$pred - predictions_model1$actual)^2)
    mse

    ## Distribution of predictions
    distribution_of_predictions <-
        predictions_model1 %>%
        ggplot(aes(x=pred)) +
        geom_histogram()

    ## Distribution of actual ratios
    distribution_of_actuals <-
        predictions_model1 %>%
        ggplot(aes(x=actual)) +
        geom_histogram()

    summary(predictions_model1)
    ## pred ranges from 0.083 to 0.168 with median 0.143
    ## actual ranges from 0.01945 to 0.57731 with median 0.12037

    model_1_stats <-
        predictions_model1 %>%
        mutate(total=noise+other, num_correct=noise*(pred>=0.12)+other*(pred<0.12))

    accuracy <-
        model_1_stats %>%
        summarise(accuracy=sum(num_correct)/sum(total),
                  baseline_accuracy=sum(noise)/sum(total))
    accuracy

    precision <-
        model_1_stats %>%
        filter(pred>=0.12) %>%
        summarise(prec=sum(noise)/sum(total))
    precision

    tpr <-
        model_1_stats %>%
        summarise(tpr=sum(noise*(pred>=0.12))/sum(noise))
    tpr

    fpr <-
        model_1_stats %>%
        summarise(fpr=sum(other*(pred>=0.12))/sum(other))
    fpr

    auc <-
        model_1_stats %>%
        summarise(auc=mean(pred>=0.12))
    auc

    ## ROC curve
    roc_data_1 <- data.frame(matrix(NA, nrow=1000, ncol=2))
    colnames(roc_data_1) <- c("tpr", "fpr")

    for (i in 1:1000) {
        thresh = i/1000
        temp <-
            model_1_stats %>%
            summarise(tpr=sum(noise*(pred>=thresh))/sum(noise),
                      fpr=sum(other*(pred>=thresh))/sum(other))

        roc_data_1[i, 'tpr'] <- temp[1,1]
        roc_data_1[i, 'fpr'] <- temp[1,2]
    }

    roc_curve <-
        roc_data_1 %>%
        ggplot(aes(x=fpr, y=tpr)) +
        geom_line() +
        xlim(0, 1) +
        geom_abline(linetype='dashed')

    ## Calibration plot
    calibration_plot <-
        model_1_stats %>%
        #group_by(predicted=round(pred*10000)/10000) %>%
        #summarise(num=sum(total), actual=sum(noise)/sum(total)) %>%
        ggplot(aes(x=pred, y=actual)) +
        geom_point() +
        geom_abline(linetype=2) +
        scale_x_continuous(labels=percent, lim=c(0.05,0.25)) +
        scale_y_continuous(labels=percent, lim=c(0,0.65)) +
        #scale_size_continuous(labels=comma) +
        labs(title='Calibration plot for Model 1',
             x = 'Predicted ratio of noise complaints/total',
             y = 'Actual ratio of noise complaints/total',
             size = 'Number of days')

    ## How accurate are we?
    b <- data.frame(c(1,1))
    b[1,1] <-
        model_1_stats %>%
        summarise(sum(noise)/sum(total))

    plot <-
        model_1_stats %>%
        arrange(desc(pred)) %>%
        mutate(cum_total=cumsum(total), perc_cum_total=cum_total/sum(total), cum_noise=cumsum(noise), perc_cum_noise=cum_noise/sum(noise)) %>%
        ggplot(aes(x=perc_cum_total, y=perc_cum_noise)) +
        geom_line() +
        scale_x_continuous(labels=percent) +
        scale_y_continuous(labels=percent) +
        labs(x="Predicted ratio of noise/total", y="Percent of noise complaints successfully identified") +
        geom_abline(linetype='dashed', color='red') +
        geom_abline(linetype='dashed', slope=(1/b[1,1]), intercept=0, color='blue')

    return(list("model"=model1,
                "df_with_predictions"=predictions_model1,
                "mse"=mse,
                "distribution_of_actuals"=distribution_of_actuals,
                "distribution_of_predictions"=distribution_of_predictions,
                "model_stats"=model_1_stats,
                "accuracy"=accuracy,
                "precision"=precision,
                "tpr"=tpr,
                "fpr"=fpr,
                "auc"=auc,
                "roc_curve"=roc_curve,
                "calibration_plot"=calibration_plot,
                "plot"=plot))
}
