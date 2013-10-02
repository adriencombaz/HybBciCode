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

accData <- accData[accData$subject == "S01", ]
accData$subject <- droplevels(accData$subject)
accData <- accData[accData$classifier == "normal", ]
accData$classifier <- droplevels(accData$classifier)

accData$trialId <- as.numeric(accData$trial : accData$condition)

#################################################################################################################

varList <- c("trialId", "condition", "nRep", "correctness")
accData <- accData[, names(accData) %in% varList ]
accData <- accData[, varList]
# accData$nRepFac <- as.factor(accData$nRep)
accData <- accData[with(accData, order(trialId, condition, nRep)), ]
str(accData)
summary(accData)


#################################################################################################################

lm1 <- bild(
  correctness ~ nRep * condition
  , data = accData
  , time = "nRep"
  , id = "trialId"
  , start = NULL
  , aggregate = condition
  , dependence = "MC1R"
)
summary(lm1)


lm0 <- bild(
  correctness ~ nRep
  , data = accData
  , time = "nRep"
  , id = "trialId"
  , start = NULL
  , aggregate = condition
  , dependence = "MC1R"
)
summary(lm0)


plot(lm1, which = 5, ylab = "probability of locomotion")
plot(lm1, which = 1)
plot(lm1, which = 2)
plot(lm1, which = 3)
plot(lm1, which = 4)
