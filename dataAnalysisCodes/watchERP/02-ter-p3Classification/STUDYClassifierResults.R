setwd("d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciCode/dataAnalysisCodes/watchERP/02-ter-p3Classification/")
rm(list = ls())
library(ggplot2)
library(reshape2)
library(ez)

accData <- read.csv("d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciProcessedData/watch-ERP/02-ter-p3Classification/LinSvm/subject_S3/Results.txt", header = TRUE)
accData$nAverages = as.factor(accData$nAverages)
str(accData)
summary(accData)

# for (levTest in levels(accData$conditionTest)) {
#   temp <- subset(accData, conditionTest == levTest, select = c("conditionTrain", "nAverages", "accuracy") )
# 
#   barplot <- ggplot(temp)
#   #barplot <- barplot + geom_bar( aes(nAverages, accuracy, fill=conditionTrain), position = "dodge"  )
#   barplot <- barplot + geom_point( aes(nAverages, accuracy, shape=conditionTrain, colour=conditionTrain), position = position_jitter(w = 0.1, h = 0)  ) 
#   barplot
# }

barplot <- ggplot(accData)
barplot <- barplot + geom_point( aes(nAverages, accuracy, shape=conditionTrain, colour=conditionTrain), position = position_jitter(w = 0.1, h = 0)  ) 
barplot <- barplot + facet_wrap( ~conditionTest )
barplot