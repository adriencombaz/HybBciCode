setwd("d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciCode/dataAnalysisCodes/watchERP/02-xxx-p3Classification/")
rm(list = ls())

library(ggplot2)
library(geepack)

source("createDataFrame.R")
source("d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciCode/dataAnalysisCodes/deps/cleanPlot.R")
source("d:/KULeuven/PhD/rLibrary/plotFactorMeans_InteractionGraphs.R")


aveClass <- 0
nRunsForTrain <- 2
FS <- 128
nFoldSvm <- 10

accData <- createDataFrame(aveClass, nRunsForTrain, FS, nFoldSvm)

accData <- accData[accData$subject != "S08", ]
accData$subject <- droplevels(accData$subject)


#################################################################################################################

varList <- c("subject", "frequency", "trial", "nRep", "correctness")
accData1 <- accData[ accData$classifier=="normal", names(accData) %in% varList ]
accData1 <- accData1[, varList]
accData1$nRepFac <- as.factor(accData1$nRep)
accData1 <- accData1[with(accData1, order(subject, frequency, trial, nRep)), ]
accData1$trial2 <- as.factor( as.numeric( accData1$frequency : accData1$trial ) )
str(accData1)
summary(accData1)

#################################################################################################################
m1 <- geeglm(correctness ~ nRep*frequency,
               data = accData1, id = interaction(subject, trial2),
               family = binomial, corstr = "ar1")
m1 <- geeglm(correctness ~ nRep*frequency,
             data = accData1, id = subject,
             family = binomial, corstr = "ar1")

m0 <- geeglm(correctness ~ nRep,
             data = accData1, id = interaction(subject, trial2),
             family = binomial, corstr = "ar1")

anova(m0, m1)
