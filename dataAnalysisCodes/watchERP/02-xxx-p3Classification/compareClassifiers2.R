setwd("d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciCode/dataAnalysisCodes/watchERP/02-xxx-p3Classification/")
rm(list = ls())

library(ggplot2)
library(lme4)
library(LMERConvenienceFunctions)
library(languageR)

source("createDataFrame.R")
source("d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciCode/dataAnalysisCodes/deps/cleanPlot.R")
source("d:/KULeuven/PhD/rLibrary/plotFactorMeans_InteractionGraphs.R")

########################################################################################################################
########################################################################################################################

aveClass <- 0
nRunsForTrain <- 2
FS <- 128
nFoldSvm <- 10

accData <- createDataFrame(aveClass, nRunsForTrain, FS, nFoldSvm)

accData <- accData[accData$condition != "oddball", ]
accData$condition <- droplevels(accData$condition)
accData$frequency <- droplevels(accData$frequency)

accData <- accData[accData$classifier != "pooled",]
accData$classifier <- droplevels(accData$classifier)

accData <- accData[accData$subject != "S08", ]
accData$subject <- droplevels(accData$subject)

str(accData)
summary(accData)

########################################################################################################################
########################################################################################################################

pp <- ggplot( accData, aes(nRepFac, correctness, colour=classifier) )
pp <- pp + stat_summary(fun.y = mean, geom = "line", aes(group=classifier), width = 0.2)
pp <- pp + facet_wrap(~condition)
pp <- cleanPlot(pp)
print(pp)


########################################################################################################################
########################################################################################################################

lmH1 <- glmer( correctness ~ frequency * nRepFac * classifier + ( 1 | subject/nRepFac ), data = accData, family = binomial )
lmH0 <- glmer( correctness ~ frequency * nRepFac + ( 1 | subject/nRepFac ), data = accData, family = binomial )

########################################################################################################################
########################################################################################################################

accData <- createDataFrame(aveClass, nRunsForTrain, FS, nFoldSvm)

accData <- accData[accData$condition != "oddball", ]
accData$condition <- droplevels(accData$condition)
accData$frequency <- droplevels(accData$frequency)

accData <- accData[accData$classifier != "pooledAll",]
accData$classifier <- droplevels(accData$classifier)

accData <- accData[accData$subject != "S08", ]
accData$subject <- droplevels(accData$subject)

str(accData)
summary(accData)

########################################################################################################################
########################################################################################################################

pp <- ggplot( accData, aes(nRepFac, correctness, colour=classifier) )
pp <- pp + stat_summary(fun.y = mean, geom = "line", aes(group=classifier), width = 0.2)
pp <- pp + facet_wrap(~condition)
pp <- cleanPlot(pp)
print(pp)


########################################################################################################################
########################################################################################################################

lmH1b <- glmer( correctness ~ frequency * nRepFac * classifier + ( 1 | subject/nRepFac ), data = accData, family = binomial )
lmH0b <- glmer( correctness ~ frequency * nRepFac + ( 1 | subject/nRepFac ), data = accData, family = binomial )

########################################################################################################################
########################################################################################################################

lm1 <- glmer( correctness ~ frequency * nRepFac * classifier + ( 1 | subject/nRepFac ), data = accData, family = binomial )
lm2 <- glmer( correctness ~ (frequency + nRepFac + classifier)^2 + ( 1 | subject/nRepFac ), data = accData, family = binomial )
lm3 <- glmer( correctness ~ frequency + (nRepFac * classifier) + ( 1 | subject/nRepFac ), data = accData, family = binomial )
lm4 <- glmer( correctness ~ (frequency * nRepFac) + classifier + ( 1 | subject/nRepFac ), data = accData, family = binomial )
lm5 <- glmer( correctness ~ frequency + nRepFac + classifier + ( 1 | subject/nRepFac ), data = accData, family = binomial )
lm6 <- glmer( correctness ~ (nRepFac * classifier) + ( 1 | subject/nRepFac ), data = accData, family = binomial )
lm7 <- glmer( correctness ~ nRepFac + classifier + ( 1 | subject/nRepFac ), data = accData, family = binomial )
lm0 <- glmer( correctness ~ nRepFac + ( 1 | subject/nRepFac ), data = accData, family = binomial )
save(lm1
     , lmH2
     , lmH3
     , lmH4
     , lmH5
     , lmH6
     , lmH7
     , file = "logisticModelsClassifiers2.RData")
