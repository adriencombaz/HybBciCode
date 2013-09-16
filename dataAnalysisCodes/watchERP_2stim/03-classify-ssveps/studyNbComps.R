setwd("d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciCode/dataAnalysisCodes/watchERP_2stim/03-classify-ssveps/")
rm(list = ls())

library(plyr)
library(ggplot2)
source("d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciCode/dataAnalysisCodes/deps/cleanPlot.R")
source("createSnrDatasetFnc.R")

#################################################################################################################
#################################################################################################################

runs <- c(1, 2, 3, 4, 5, 6, 7, 8)
subsetChLabel <- c("ch-O", "ch-PO-O", "ch-P-PO-O", "ch-CP-P-PO-O", "ch-C-CP-P-PO-O", "ch-all")
nChanPerSubset <- c(3, 5, 10, 14, 15, 32)
harmonicsLabel <- c("fund","fund-ha1")

#################################################################################################################
#################################################################################################################
for (iCh in 1:length(subsetChLabel)){
  for (iHa in 1:length(harmonicsLabel)){
    
    nCompData <- createSnrDatasetFnc(runs, subsetChLabel[iCh], harmonicsLabel[iHa])

    varList <- c( "subject", "trial", "nRep" )
    nCompData <- ddply( nCompData, varList, summarize 
                      , nCompSP = unique(nCompSP)
                      )    
    
    nCompData$Channels <- subsetChLabel[iCh]
    nCompData$nChannels <- nChanPerSubset[iCh]
    nCompData$Harmonics <- harmonicsLabel[iHa]
    if ((iCh == 1) && (iHa == 1)) { 
      nCompDataAll <- nCompData
    } else{ 
      nCompDataAll <- rbind(nCompDataAll, nCompData) 
    }    
    
  }
}
nCompDataAll$Channels <- as.factor(nCompDataAll$Channels)
nCompDataAll$nChannels <- as.factor(nCompDataAll$nChannels)
nCompDataAll$Harmonics <- as.factor(nCompDataAll$Harmonics)
nCompDataAll$ChHa <- nCompDataAll$Channels : nCompDataAll$Harmonics

#################################################################################################################
#################################################################################################################
pp <- ggplot( nCompDataAll, aes(nRep, nCompSP, colour=Harmonics, shape=nChannels) )
pp <- pp + stat_summary(fun.data = mean_cl_normal, geom="pointrange", position = position_dodge(0.2), size = 1)
pp <- pp + stat_summary(fun.data = mean_cl_normal, geom="line", aes(group=ChHa), position = position_dodge(0.2))
pp <- cleanPlot(pp)
print(pp)

pp2 <- ggplot( nCompDataAll, aes(nRep, nCompSP, colour=Harmonics) )
pp2 <- pp2 + stat_summary(fun.data = mean_cl_normal, geom="pointrange", position = position_dodge(0.2), size = 1)
pp2 <- pp2 + stat_summary(fun.data = mean_cl_normal, geom="line", aes(group=Harmonics), position = position_dodge(0.2))
pp2 <- pp2 +facet_wrap( ~nChannels, scales="free" )
pp2 <- cleanPlot(pp2)
print(pp2)
