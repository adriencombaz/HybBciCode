setwd("d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciCode/dataAnalysisCodes/watchERP_2stim/02-classify-erps/")
rm(list = ls())

library(ggplot2)
library(lme4)
library(LMERConvenienceFunctions)
library(languageR)

source("d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciCode/dataAnalysisCodes/deps/cleanPlot.R")
plotResults <- function(dataframe, figureTag)
{
  
  pp <- ggplot( dataframe, aes(nAverages, correctness, colour=targetFrequency) )
  pp <- pp + stat_summary(fun.y = mean, geom="point",  position = position_jitter(w = 0.2, h = 0), size = 3)
  pp <- pp + facet_wrap( ~testingRun  )
  pp <- pp + ylim(0, 1)
  pp
  
  
  
  
}

#################################################################################################################
#################################################################################################################
nRunsForTrain <- 1

for (iS in 1:2){
  filename <- sprintf("d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciProcessedData/watchERP_2stim/02-classify-erps/linSvm_%dRunsForTrain/subject_S%d/Results_forLogisiticRegression.txt", nRunsForTrain, iS)
  accData1 <- read.csv(filename, header = TRUE, sep = ",", strip.white = TRUE)
  
  accData1$targetFrequency <- as.factor(accData1$targetFrequency)
  accData1$trainingRun_1 <- as.factor(accData1$trainingRun_1)
  accData1$foldInd <- as.factor(accData1$foldInd)
  accData1$testingRun <- as.factor(accData1$testingRun)
  accData1$roundNb <- as.factor(accData1$roundNb)
  
  accData <- accData1
  accData <- subset(accData1, trainingRun_1 == 1)

  if (iS == 1) { accDataAllSub <- accData }
  else { accDataAllSub <- rbind(accDataAllSub, accData) }
  
}
plotResults(accDataAllSub, "train1_Test2-8")  


#################################################################################################################
#################################################################################################################


nRunsForTrain <- 2
#################################################################################################################
for (iS in 1:1){
  filename <- sprintf("d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciProcessedData/watchERP_2stim/02-classify-erps/linSvm_%dRunsForTrain/subject_S%d/Results_forLogisiticRegression.txt", nRunsForTrain, iS)
  accData1 <- read.csv(filename, header = TRUE, sep = ",", strip.white = TRUE)
  
  accData1$targetFrequency <- as.factor(accData1$targetFrequency)
  accData1$trainingRun_1 <- as.factor(accData1$trainingRun_1)
  accData1$foldInd <- as.factor(accData1$foldInd)
  accData1$testingRun <- as.factor(accData1$testingRun)
  accData1$roundNb <- as.factor(accData1$roundNb)
  
  accData <- accData1
#   accData <- subset(accData1, trainingRun_1 == 1)
  accData <- subset(accData1, trainingRun_1 == 3)
  accData <- subset(accData1, trainingRun_2 == 4)
  accData <- subset(accData, testingRun != 1)
  accData <- subset(accData, testingRun != 2)
  # accData <- subset(accData, testingRun != 2)
  # accData$trainingRun_1 <- droplevels(accData$trainingRun_1)
  # accData$testingRun <- droplevels(accData$testingRun)
  # accData$foldInd <- droplevels(accData$foldInd)
  
  str(accData)
  summary(accData)
  
  #################################################################################################################
  
  pp <- ggplot( accData, aes(nAverages, correctness, colour=targetFrequency) )
  pp <- pp + stat_summary(fun.y = mean, geom="point",  position = position_jitter(w = 0.2, h = 0), size = 3)
  # pp <- pp + stat_summary(fun.y = mean, geom="point", position = position_dodge(.5))
  # pp <- pp + stat_summary(fun.data = mean_cl_normal, geom = "pointrange", width = 0.2, position = position_dodge(.5), size = 1)
  # pp <- pp + facet_grid( trainingRun_1~trainingRun_2  )
  pp <- pp + facet_wrap( ~testingRun  )
  # pp <- cleanPlot(pp)
  # pp <- pp + theme(legend.position=c(0.8334,0.1667))
  pp <- pp + ylim(0, 1)
  pp
  
  if (iS == 1) { accDataAllSub <- accData }
  else { accDataAllSub <- rbind(accDataAllSub, accData) }

}

str(accDataAllSub)
summary(accDataAllSub)

pp2 <- ggplot( accDataAllSub, aes(nAverages, correctness, colour=targetFrequency) )
pp2 <- pp2 + stat_summary(fun.y = mean, geom="point",  position = position_jitter(w = 0.2, h = 0), size = 3)
pp2 <- pp2 + facet_wrap( ~subject )
# pp <- cleanPlot(pp)
# pp <- pp + theme(legend.position=c(0.8334,0.1667))
pp2 <- pp2 + ylim(0, 1)
pp2
