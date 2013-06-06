setwd("d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciCode/dataAnalysisCodes/watchERP_2stim/04-icon-detection/")

rm(list = ls())

library(ggplot2)
source("d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciCode/dataAnalysisCodes/deps/cleanPlot.R")

#################################################################################################################
#################################################################################################################
plotFactorMeans_InteractionGraphs <- function(file)
{
  fileDir = "d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciProcessedData/watchERP_2stim/04-icon-detection"
  fileext = ".txt"
  filename = file.path( fileDir, paste0(file, fileext) )
  figDir = "d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciResults/watchERP_2stim/04-icon-detection/"  
  figname = paste0(file, ".png")

  accData <- read.csv(filename, header = TRUE, sep = ",", strip.white = TRUE)
  str(accData)
  summary(accData)
  
  #################################################################################################################
  temp <- subset( accData, select = -c(correctness_ssvep, correctness))
  temp$correctnessType <- "p3"
  temp$correctness <- temp$correctness_p3
  temp <- subset( temp, select = -correctness_p3 )
  
  temp2 <- subset( accData, select = -c(correctness_p3, correctness))
  temp2$correctnessType <- "ssvep"
  temp2$correctness <- temp2$correctness_ssvep
  temp2 <- subset( temp2, select = -correctness_ssvep )
  
  temp3 <- subset( accData, select = -c(correctness_ssvep, correctness_p3))
  temp3$correctnessType <- "symbol"
  
  accData <- rbind(temp, temp2, temp3)
  accData$targetFrequency <- as.factor(accData$targetFrequency)
  
  #################################################################################################################
  pp <- ggplot( accData, aes(nRep, correctness, colour=targetFrequency ) )
  pp <- pp + stat_summary(fun.y = mean, geom="point",  position = position_jitter(w = 0.2, h = 0), size = 3)
  pp <- pp + facet_grid( correctnessType ~ subject  )
  pp <- pp + ylim(0, 1)
  pp <- cleanPlot(pp)
  pp
  
  ggsave( figname 
          , plot = pp
          , path = figDir
          , width = 30
          , height = 20
          , units = "cm"
          )

}

#################################################################################################################
#################################################################################################################

file = "train1_test2345678"
plotFactorMeans_InteractionGraphs(file)

file = "train12_test345678"
plotFactorMeans_InteractionGraphs(file)

file = "train2_test345678"
plotFactorMeans_InteractionGraphs(file)

file = "train23_test45678"
plotFactorMeans_InteractionGraphs(file)

file = "train3_test45678"
plotFactorMeans_InteractionGraphs(file)

file = "train34_test5678"
plotFactorMeans_InteractionGraphs(file)

