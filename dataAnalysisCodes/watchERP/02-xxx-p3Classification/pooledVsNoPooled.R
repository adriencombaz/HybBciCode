setwd("d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciCode/dataAnalysisCodes/watchERP/02-xxx-p3Classification/")
rm(list = ls())

library(ggplot2)
library(lme4)
library(LMERConvenienceFunctions)
library(languageR)

source("createDataFrame.R")
source("d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciCode/dataAnalysisCodes/deps/cleanPlot.R")
source("d:/KULeuven/PhD/rLibrary/plotFactorMeans_InteractionGraphs.R")


aveClass <- 0
nRunsForTrain <- 2
FS <- 128
nFoldSvm <- 10

accData <- createDataFrame(aveClass, nRunsForTrain, FS, nFoldSvm)

accData <- accData[accData$condition != "oddball", ]
accData$condition <- droplevels(accData$condition)
accData$frequency <- droplevels(accData$frequency)

accData <- accData[accData$subject != "S08", ]
accData$subject <- droplevels(accData$subject)

str(accData)
summary(accData)

pp <- ggplot( accData, aes(nRep, correctness, colour=condition) )
pp <- pp + stat_summary(fun.y = mean, geom = "line", aes(linetype=classifier), width = 0.2)
pp <- cleanPlot(pp)
print(pp)

pp2 <- pp + facet_wrap(~subject)
print(pp2)

pp <- ggplot( accData, aes(nRep, correctness, colour=classifier) )
pp <- pp + stat_summary(fun.y = mean, geom = "line", aes(group=classifier), width = 0.2)
pp <- cleanPlot(pp)
pp <- pp + facet_grid(condition~subject)
print(pp)


pp <- ggplot( accData, aes(nRep, correctness, colour=classifier, shape=condition) )
pp <- pp + stat_summary(fun.y = mean, geom="point", position = position_dodge(.5), size = 3)
pp <- pp + facet_wrap( ~subject ) 
pp <- cleanPlot(pp)
pp

