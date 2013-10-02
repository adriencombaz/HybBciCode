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
accData <- accData[, varList]

varList <- c("subject", "condition", "nRep")
accData1 <- ddply( 
  accData
  , varList
  , summarise
  , acc = mean(correctness)
  , nTrial = length(correctness)
)
accData1 <- accData1[with(accData1, order(subject, condition, nRep)), ]
accData1$nRepFac <- as.factor(accData1$nRep)

#################################################################################################################
m1 <- glmmPQL(
  fixed = acc ~ nRep*condition
  , random = ~1 | subject/condition
  , family = binomial
  , data = accData1
  , correlation=corAR1(form=~nRep)
  , weights = nTrial
  )

m0 <- glmmPQL(
  fixed = acc ~ nRep
  , random = ~1 | subject/condition
  , family = binomial
  , data = accData1
  , correlation=corAR1(form=~nRep)
  , weights = nTrial
)
