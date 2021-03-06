rm(list = ls())
library(ggplot2)
library(reshape2)
library(grid)
library(plyr)
library(lme4)
library(LMERConvenienceFunctions)
library(languageR)
library(lattice)

source("d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciCode/dataAnalysisCodes/deps/cleanPlot.R")
source("d:/KULeuven/PhD/rLibrary/plotFactorMeans_InteractionGraphs.R")
source("d:/KULeuven/PhD/rLibrary/plotInteractionGraphs_level2.R")

fileDir <- "d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciProcessedData/watchERP/04-watchSSVEP-PSD"

# filename <- "psdDataset_Oz_Ha1"
# fullfilename <- file.path( fileDir, paste0(filename, ".csv") )
# psdData <- read.csv(fullfilename, header = TRUE)
# psdData$harmonic <- "fundamental"

filename <- "psdDataset_Oz_Ha2"
fullfilename <- file.path( fileDir, paste0(filename, ".csv") )
psdData <- read.csv(fullfilename, header = TRUE)
# psdData2$harmonic <- "firstHarm"

# psdData <- rbind(psdData, psdData2)

psdData$frequency         <- as.factor(psdData$frequency)
psdData$oddball           <- as.factor(psdData$oddball)
psdData$fileNb            <- as.factor(psdData$fileNb)
psdData$stimDurationFac   <- as.factor(psdData$stimDuration)
psdData$trialInSubAndFreqAndCond <- as.factor(psdData$trial)
psdData$trialInSubAndFreq        <- psdData$oddball:psdData$trial
psdData$trialInSubAndCond        <- psdData$frequency:psdData$trial
psdData$trialInFreq       <- psdData$subject:psdData$oddball:psdData$trial
psdData$trialInSub        <- psdData$oddball:psdData$frequency:psdData$trial
psdData$trial             <- psdData$subject:psdData$oddball:psdData$frequency:psdData$trial
psdData$sqrtPsd           <- sqrt(psdData$psd)
psdData$log10Psd          <- log10(psdData$psd)
psdData$lnPsd             <- log(psdData$psd)
psdData$stimDuration      <- as.numeric(psdData$stimDuration)
psdData$stimDurationFac   <- as.factor(psdData$stimDuration)
psdData$condition <- psdData$oddball

psdData$oddball <- revalue( psdData$oddball, c("0"="odd0", "1"="odd1" ) )


psdData <- psdData[with(psdData, order(subject, oddball, trialInSubAndCond, stimDuration)), ]
