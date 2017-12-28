evaluate_model <- function(X, y, model) {
    library(dplyr)
    library(tidyr)
    library(ggplot2)
    library(glmnet)
    library(ROCR)
    library(boot)
    library(scales)

    predictions_model <- data.frame(y) %>%
        merge(data.frame(predict(model, X, type="response", s="lambda.min")), by="row.names")
    colnames(predictions_model) <- c("Row.names", "other", "noise", "pred")
    predictions_model <- predictions_model %>%
        mutate(actual = (noise)/(noise+other))
    head(predictions_model)

    # Mean squared error
    mse <- mean((predictions_model$pred - predictions_model$actual)^2)
    mse

    ## Distribution of predictions
    distribution_of_predictions <-
        predictions_model %>%
        ggplot(aes(x=pred)) +
        geom_histogram() +
        scale_x_continuous(labels=percent) +
        scale_y_continuous(labels=percent) +
        labs(title="Distribution of Predicted Ratios of # Noise Complaints / Total # Complaints",
             x="Predicted ratio of noise/total",
             y="# of Days")

    ## Distribution of actual ratios
    distribution_of_actuals <-
        predictions_model %>%
        ggplot(aes(x=actual)) +
        geom_histogram() +
        scale_x_continuous(labels=percent) +
        scale_y_continuous(labels=percent) +
        labs(title="Distribution of Actual Ratios of # Noise Complaints / Total # Complaints",
             x="Predicted ratio of noise/total",
             y="# of Days")

    ## Combined distributions
    combined_distributions <-
        predictions_model %>%
        ggplot() +
        geom_histogram(aes(x=actual, fill="r"), alpha=0.5) +
        geom_histogram(aes(x=pred, fill="b"), alpha=0.5) +
        scale_x_continuous(labels=percent) +
        scale_y_continuous(labels=comma) +
        scale_colour_manual(name="", values=c("r"="red", "b"="blue"), labels=c("b"="Predicted", "r"="Actual")) +
        scale_fill_manual(name="", values=c("r"="red", "b"="blue"), labels=c("b"="Predicted", "r"="Actual")) +
        labs(title="Distribution of Predicted vs. Actual Ratios of # Noise Complaints / Total # Complaints",
             x="Ratio of noise/total",
             y="# of Days")

        

    thresh = 0.18
    model_1_stats <-
        predictions_model %>%
        mutate(total=noise+other, num_correct=noise*(pred>=thresh)+other*(pred<thresh))

    accuracy <-
        model_1_stats %>%
        summarise(accuracy=sum(num_correct)/sum(total),
                  baseline_accuracy=sum(noise)/sum(total))
    accuracy

    precision <-
        model_1_stats %>%
        filter(pred>=thresh) %>%
        summarise(prec=sum(noise)/sum(total))
    precision

    tpr <-
        model_1_stats %>%
        summarise(tpr=sum(noise*(pred>=thresh))/sum(noise))
    tpr

    fpr <-
        model_1_stats %>%
        summarise(fpr=sum(other*(pred>=thresh))/sum(other))
    fpr

    auc <-
        model_1_stats %>%
        summarise(auc=mean(pred>=thresh))
    auc

    ## ROC curve
    roc_data_1 <- data.frame(matrix(NA, nrow=1000, ncol=2))
    colnames(roc_data_1) <- c("tpr", "fpr")

    for (i in 1:1000) {
        t = i/1000
        temp <-
            model_1_stats %>%
            summarise(tpr=sum(noise*(pred>=t))/sum(noise),
                      fpr=sum(other*(pred>=t))/sum(other))

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
        group_by(predicted=round(pred*10^8)/10^8) %>%
        summarise(num=sum(total), actual=sum(noise)/sum(total)) %>%
        ggplot(aes(x=predicted, y=actual, size=num)) +
        geom_point() +
        geom_abline(linetype=2) +
        scale_x_continuous(labels=percent, lim=c(0.05,0.25)) +
        scale_y_continuous(labels=percent, lim=c(0,0.65)) +
        scale_size_continuous(labels=comma) +
        labs(title='Calibration plot for Logistic Regression Model',
             x = 'Predicted ratio of # noise complaints/# total complaints',
             y = 'Actual ratio of # noise complaints/# total complaints',
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

    return(list("model"=model,
                "df_with_predictions"=predictions_model,
                "mse"=mse,
                "distribution_of_actuals"=distribution_of_actuals,
                "distribution_of_predictions"=distribution_of_predictions,
                "combined_distributions"=combined_distributions,
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
