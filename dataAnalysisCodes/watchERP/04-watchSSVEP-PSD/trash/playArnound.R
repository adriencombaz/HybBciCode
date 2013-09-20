setwd("d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciCode/dataAnalysisCodes/watchERP/04-watchSSVEP-PSD/")
rm(list = ls())
library(ggplot2)
library(reshape2)
library(grid)
library(plyr)

source("d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciCode/dataAnalysisCodes/deps/cleanPlot.R")
source("d:/KULeuven/PhD/rLibrary/plotFactorMeans_InteractionGraphs.R")
source("d:/KULeuven/PhD/rLibrary/plotInteractionGraphs_level2.R")

fileDir <- "d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciProcessedData/watchERP/04-watchSSVEP-PSD"
filename <- "psdDataset_Oz_Ha1"

fullfilename <- file.path( fileDir, paste0(filename, ".csv") )

psdData <- read.csv(fullfilename, header = TRUE)

psdData$frequency <- as.factor(psdData$frequency)
psdData$oddball <- as.factor(psdData$oddball)
psdData$fileNb <- as.factor(psdData$fileNb)
psdData$trial <- as.factor(psdData$trial)
psdData$sqrtPsd <- sqrt(psdData$psd)


varList <- c( "subject", "frequency","oddball", "stimDuration" )
psdDataAveRun <- ddply( psdData, varList, summarise, psd = mean(psd), sqrtPsd = mean(sqrtPsd) )
psdDataAveRun$sqrtPsd2 <- sqrt(psdDataAveRun$psd)

pp <- ggplot( psdDataAveRun, aes(stimDuration, psd, colour=oddball ) )
pp <- pp + stat_summary(fun.data = mean_cl_normal, geom="pointrange", position = position_dodge(0.2))
pp <- pp + facet_wrap( ~ frequency, scales = "free_y"  )
pp <- cleanPlot(pp)

pp2 <- ggplot( psdDataAveRun, aes(stimDuration, sqrtPsd, colour=oddball ) )
pp2 <- pp2 + stat_summary(fun.data = mean_cl_normal, geom="pointrange", position = position_dodge(0.2))
pp2 <- pp2 + facet_wrap( ~ frequency, scales = "free_y"  )
pp2 <- cleanPlot(pp2)

pp3 <- ggplot( psdDataAveRun, aes(stimDuration, sqrtPsd2, colour=oddball ) )
pp3 <- pp3 + stat_summary(fun.data = mean_cl_normal, geom="pointrange", position = position_dodge(0.2))
pp3 <- pp3 + facet_wrap( ~ frequency, scales = "free_y"  )
pp3 <- cleanPlot(pp3)

pp4 <- ggplot( psdDataAveRun, aes(stimDuration, sqrtPsd, colour=oddball ) )
pp4 <- pp4 + geom_point( position = position_dodge(0.2) )
pp4 <- pp4 + facet_grid( subject ~ frequency, scales = "free_y"  )
pp4 <- cleanPlot(pp4)

