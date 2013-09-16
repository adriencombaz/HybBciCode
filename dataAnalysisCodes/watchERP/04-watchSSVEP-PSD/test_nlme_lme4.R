setwd("d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciCode/dataAnalysisCodes/watchERP/04-watchSSVEP-PSD/")
rm(list = ls())
library(ggplot2)
library(reshape2)
library(grid)
library(plyr)


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

psdData <- psdData[psdData$stimDuration==5,]
psdData <- psdData[psdData$oddball==0,]
# psdData <- psdData[psdData$frequency==15,]
varList <- c( "subject", "stimDuration" )
psdDataAveRun <- ddply( psdData, varList, summarise, psd = mean(psd) )
psdDataAveRun$sqrtPsd <- sqrt(psdDataAveRun$psd)

########################################################################################################################
########################################################################################################################
library(nlme)

aveModel    <- lme(psd ~ oddball, random = ~1|subject, data = psdDataAveRun, method="REML")
trialModel  <- lme(psd ~ oddball, random = ~1|subject, data = psdData, method="REML")

aveModel2   <- lme(psd ~ oddball, random = ~1|subject/oddball, data = psdDataAveRun, method="REML")
trialModel2 <- lme(psd ~ oddball, random = ~1|subject/oddball/frequency, data = psdData, method="REML")

trialModel3 <- lme(psd ~ oddball, random = ~1|subject/oddball, data = psdData, method="REML")

########################################################################################################################

lme1 <- lme(psd ~ oddball*frequency, random = ~1|subject/oddball/frequency, data = psdData, method="REML")
lme2 <- lme(psd ~ oddball*frequency, random = ~1|trial/subject/oddball/frequency, data = psdData, method="REML")


detach("package:nlme", unload=TRUE)
########################################################################################################################
########################################################################################################################
library(lme4)
library(LMERConvenienceFunctions)
library(languageR)

full42 <- lmer(psd ~ oddball + (1|subject), data = psdDataAveRun)
lmer1 <- lmer(psd ~ oddball*frequency + (1|subject/oddball/frequency), data = psdData)
lmer2 <- lmer(psd ~ oddball*frequency + (1|trial/subject/oddball/frequency), data = psdData)

detach("package:languageR", unload=TRUE)
detach("package:LMERConvenienceFunctions", unload=TRUE)
detach("package:lme4", unload=TRUE)

########################################################################################################################
########################################################################################################################

# lme(psd ~ oddball, random = ~1|subject/oddball, data = psdData, method="REML")
#
# GIVE EXACLTY THE SAME RESULTS AS
#
# lmer(psd ~ oddball + (1|subject/oddball), data = psdData)

