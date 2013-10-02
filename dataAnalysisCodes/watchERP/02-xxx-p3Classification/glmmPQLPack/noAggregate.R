setwd("d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciCode/dataAnalysisCodes/watchERP/02-xxx-p3Classification/")
rm(list = ls())

library(ggplot2)
library(plyr)
library(MASS)
# library(geepack)

source("createDataFrame.R")
source("d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciCode/dataAnalysisCodes/deps/cleanPlot.R")
source("d:/KULeuven/PhD/rLibrary/plotFactorMeans_InteractionGraphs.R")

##############################################################################################################################
##############################################################################################################################

aveClass <- 0
nRunsForTrain <- 2
FS <- 128
nFoldSvm <- 10
accData <- createDataFrame(aveClass, nRunsForTrain, FS, nFoldSvm)

accData <- accData[accData$subject != "S08", ]
accData$subject <- droplevels(accData$subject)

##############################################################################################################################
##############################################################################################################################

varList <- c("subject", "condition", "trial", "nRep", "correctness")
accData <- accData[ accData$classifier=="normal", names(accData) %in% varList ]
accData1 <- accData[, varList]
accData1 <- accData1[with(accData1, order(subject, condition, trial, nRep)), ]
accData1$nRepFac <- as.factor(accData1$nRep)
accData1$trialInSub <- as.factor( as.numeric( accData$condition : accData1$trial ) )

#################################################################################################################
m1 <- glmmPQL(
  fixed = correctness ~ nRep*condition
  , random = ~1 | subject/trialInSub
  , family = binomial
  , data = accData1
  , correlation=corAR1(form=~nRep)
)
