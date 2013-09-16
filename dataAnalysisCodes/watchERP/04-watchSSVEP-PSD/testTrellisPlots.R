setwd("d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciCode/dataAnalysisCodes/watchERP/04-watchSSVEP-PSD/")
rm(list = ls())
library(ggplot2)
library(reshape2)
library(grid)
library(plyr)
library(nlme)
library(lattice)

source("d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciCode/dataAnalysisCodes/deps/cleanPlot.R")
source("d:/KULeuven/PhD/rLibrary/plotFactorMeans_InteractionGraphs.R")
source("d:/KULeuven/PhD/rLibrary/plotInteractionGraphs_level2.R")

fileDir <- "d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciProcessedData/watch-ERP/04-watchSSVEP-PSD"
filename <- "psdDataset_Oz_Ha1"

fullfilename <- file.path( fileDir, paste0(filename, ".csv") )

psdData <- read.csv(fullfilename, header = TRUE)

psdData$frequency <- as.factor(psdData$frequency)
psdData$oddball <- as.factor(psdData$oddball)
psdData$fileNb <- as.factor(psdData$fileNb)
psdData$trial <- as.factor(psdData$trial)
psdData$sqrtPsd <- sqrt(psdData$psd)
psdData$stimDurationFac <- as.factor(psdData$stimDuration)

temp1 <- psdData[psdData$frequency=="10",]
temp2 <- psdData[psdData$frequency=="15",]
psdData <- rbind(temp1, temp2)

varList <- c( "subject", "frequency","oddball", "stimDuration" )
psdDataAveRun <- ddply( psdData, varList, summarise, psd = mean(psd) )
psdDataAveRun$sqrtPsd <- sqrt(psdDataAveRun$psd)

############################################################################################################
############################################################################################################

xyplot(psd ~ stimDuration|subject*frequency*oddball, data=psdDataAveRun)
