setwd("d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciCode/dataAnalysisCodes/watchERP_2stim/03-classify-ssveps/")
rm(list = ls())

library(plyr)
library(ggplot2)
source("d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciCode/dataAnalysisCodes/deps/cleanPlot.R")
source("createSnrDatasetFnc.R")

#################################################################################################################
#################################################################################################################

figDir <- "d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciResults/watchERP_2stim/03-classify-ssveps"
dir.create(figDir, showWarnings=FALSE) 
runs <- c(3, 4, 5, 6, 7, 8)
subsetChLabel <- c("ch-O", "ch-PO-O", "ch-P-PO-O", "ch-CP-P-PO-O", "ch-C-CP-P-PO-O", "ch-all")
harmonicsLabel <- c("fund-ha1")

for (iCh in 1:length(subsetChLabel)){
  for (iHa in 1:length(harmonicsLabel)){
    
    snrData <- createSnrDatasetFnc(runs, subsetChLabel[iCh], harmonicsLabel[iHa])
    
    varList <- c( "subject", "trial", "nRep" )
    accData <- ddply( snrData, varList, summarize 
                      , targetFrequency = unique(targetFrequency)
                      , correctness = ( unique(targetFrequency) == watchedFrequency[which.max(snr)] ) * 1 
                      , run = unique(run)
                      , roundNb = unique(roundNb)
                      , nRepFac = unique(nRepFac)
    )    
    
    snrData$Channels <- subsetChLabel[iCh]
    snrData$Harmonics <- harmonicsLabel[iHa]
    accData$Channels <- subsetChLabel[iCh]
    accData$Harmonics <- harmonicsLabel[iHa]
    if ((iCh == 1) && (iHa == 1)) { 
      snrDataAll <- snrData
      accDataAll <- accData
    } else{ 
      snrDataAll <- rbind(snrDataAll, snrData) 
      accDataAll <- rbind(accDataAll, accData) 
    }    
    
  }
}

accDataAll <- accDataAll[accDataAll$Channels != "ch-O",]
accDataAll <- accDataAll[accDataAll$Channels != "ch-all",]
accDataAll <- accDataAll[accDataAll$Channels != "ch-PO-O",]

pp <- ggplot( accDataAll, aes(nRep, correctness, colour=Channels) )
pp <- pp + stat_summary(fun.y = mean, geom="point", size = 3)
pp <- pp + stat_summary(fun.y = mean, geom="line")
pp <- pp +facet_wrap( ~subject )
# pp <- pp + ylim(0.4, 1)
pp <- cleanPlot(pp)
print(pp)

pp2 <- pp +facet_grid( targetFrequency~subject )
print(pp2)
