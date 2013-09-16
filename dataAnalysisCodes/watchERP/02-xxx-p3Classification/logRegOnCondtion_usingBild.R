setwd("d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciCode/dataAnalysisCodes/watchERP/02-xxx-p3Classification/")
rm(list = ls())

library(ggplot2)
library(bild)

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
str(accData1)
summary(accData1)

#################################################################################################################

pp <- ggplot( accData1, aes(nRep, correctness, colour=frequency, shape=frequency) )
pp <- pp + stat_summary(fun.data = mean_cl_normal, geom = "pointrange", width = 0.2, position = position_dodge(.5), size = 1)
pp <- pp + facet_wrap( ~subject ) 
pp <- cleanPlot(pp)
pp


source("d:/KULeuven/PhD/rLibrary/plotFactorMeans_InteractionGraphs.R")
plotFactorMeans_InteractionGraphs(accData1, c("nRep", "frequency"), "correctness")

#################################################################################################################

f0Vs857_10_12_15    = c(-4, 1, 1, 1, 1)     # oddball vs. hybrid
f857Vs10_12_15      = c(0, -3, 1, 1, 1)     # hybrid-8-57Hz vs. hybrid-10-12-15-Hz
f10Vs12_15          = c(0, 0, -2, 1, 1)     # hybrid-10Hz vs. hybrid-12-15-Hz
f12Vs15             = c(0, 0, 0, -1, 1)     # hybrid-12Hz vs. hybrid-15-Hz
contrasts(accData1$frequency) <- cbind(
  f0Vs857_10_12_15
  , f857Vs10_12_15
  , f10Vs12_15
  , f12Vs15
)

Rep1VsRep2 = c(-1, 1, 0, 0, 0, 0, 0, 0, 0, 0)
Rep2VsRep3 = c(0, -1, 1, 0, 0, 0, 0, 0, 0, 0)
Rep3VsRep4 = c(0, 0, -1, 1, 0, 0, 0, 0, 0, 0)
Rep4VsRep5 = c(0, 0, 0, -1, 1, 0, 0, 0, 0, 0)
Rep5VsRep6 = c(0, 0, 0, 0, -1, 1, 0, 0, 0, 0)
Rep6VsRep7 = c(0, 0, 0, 0, 0, -1, 1, 0, 0, 0)
Rep7VsRep8 = c(0, 0, 0, 0, 0, 0, -1, 1, 0, 0)
Rep8VsRep9 = c(0, 0, 0, 0, 0, 0, 0, -1, 1, 0)
Rep9VsRep10 = c(0, 0, 0, 0, 0, 0, 0, 0, -1, 1)

contrasts(accData1$nRepFac) <- cbind(
  Rep1VsRep2
  , Rep2VsRep3
  , Rep3VsRep4
  , Rep4VsRep5
  , Rep5VsRep6
  , Rep6VsRep7
  , Rep7VsRep8
  , Rep8VsRep9
  , Rep9VsRep10
)

#################################################################################################################
accData1$id <- accData1$subject : accData1$trial


