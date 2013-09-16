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
harmonicsLabel <- c("fund","fund-ha1")

#################################################################################################################
#################################################################################################################

for (iCh in 1:length(subsetChLabel)){
  for (iHa in 1:length(harmonicsLabel)){
    
    subFigDir <- file.path(figDir, sprintf("%s_%s", subsetChLabel[iCh], harmonicsLabel[iHa]))
    dir.create(subFigDir, showWarnings=FALSE) 
    
    snrData <- createSnrDatasetFnc(runs, subsetChLabel[iCh], harmonicsLabel[iHa])
    
    varList <- c( "subject", "trial", "nRep" )
    accData <- ddply( snrData, varList, summarize 
                      , targetFrequency = unique(targetFrequency)
                      , correctness = ( unique(targetFrequency) == watchedFrequency[which.max(snr)] ) * 1 
                      , run = unique(run)
                      , roundNb = unique(roundNb)
                      , nRepFac = unique(nRepFac)
    )    
    
    #################################################################################################################
    #################################################################################################################
    #                                              PER SUBJECT
    #################################################################################################################
    #################################################################################################################

    #################################################################################################################
    # correctness
    figfilename <- file.path(figDir, sprintf("corrPerSub_%s_%s.png", subsetChLabel[iCh], harmonicsLabel[iHa]) )
    png( filename = figfilename
         , width=1920, height=1200, units="px"
    )
    
    pp <- ggplot( accData, aes(nRep, correctness, colour=targetFrequency) )
    pp <- pp + stat_summary(fun.y = mean, geom="point", size = 3)
    pp <- pp + stat_summary(fun.y = mean, geom="line")
    pp <- pp +facet_wrap( ~subject )
    pp <- pp + ylim(0, 1)
    pp <- cleanPlot(pp)
    print(pp)
    dev.off()
    
    #################################################################################################################
    # snr
    figfilename <- file.path(figDir, sprintf("snrPerSub_%s_%s.png", subsetChLabel[iCh], harmonicsLabel[iHa]) )
    png( filename = figfilename
         , width=1920, height=1200, units="px"
    )
    
    pp <- ggplot( snrData, aes(nRep, snr, colour=targetFrequency, shape=isTarget) )
    pp <- pp + stat_summary(fun.y = mean, geom="point", size = 3)
    pp <- pp + stat_summary(fun.y = mean, geom="line")
    pp <- pp +facet_wrap( ~subject, scales = "free" )
    pp <- cleanPlot(pp)
    print(pp)
    dev.off()
    
    #################################################################################################################
    #################################################################################################################
    #                                         PER SUBJECT PER RUN
    #################################################################################################################
    #################################################################################################################
    
    #################################################################################################################
    # correctness
    figfilename <- file.path(subFigDir, "corrPerSubPerRun.png" )
    png( filename = figfilename
         , width=1920, height=1200, units="px"
    )
    
    pp <- ggplot( accData, aes(nRep, correctness, colour=targetFrequency) )
    pp <- pp + stat_summary(fun.y = mean, geom="point", position = position_dodge(0.2), size = 3)
    pp <- pp + stat_summary(fun.y = mean, geom="line", position = position_dodge(0.2))
    pp <- pp +facet_grid( subject ~ run )
    pp <- pp + ylim(0, 1)
    pp <- cleanPlot(pp)
    print(pp)
    dev.off()
    
    #################################################################################################################
    # snr
    figfilename <- file.path(subFigDir, "snrPerSubPerRun.png" )
    png( filename = figfilename
         , width=1920, height=1200, units="px"
    )
    
    pp <- ggplot( snrData, aes(nRep, snr, colour=watchedFrequency, shape=isTarget) )
    pp <- pp + stat_summary(fun.y = mean, geom="point", position = position_dodge(0.2), size = 3)
    pp <- pp + stat_summary(fun.y = mean, geom="line", position = position_dodge(0.2))
    pp <- pp +facet_grid( subject ~ run, scales = "free_y" )
    pp <- cleanPlot(pp)
    print(pp)
    dev.off()
    
    #################################################################################################################
    #################################################################################################################
    #                                 PER RUN PER ROUND FOR EACH SUBJECT
    #################################################################################################################
    #################################################################################################################
    
    #################################################################################################################
    # correctness
    subjects <- levels(snrData$subject)
    nSub <- length(subjects)
    
    for (iS in 1:nSub){ 
      
      figfilename <- file.path(subFigDir, sprintf("corrPerRunPerRound_%s.png", subjects[iS] ))
      png( filename = figfilename
           , width=1920, height=1200, units="px"
      )
      
      subDataset <- accData[ accData[ , "subject"] == subjects[iS],  ]
      pp <- ggplot( subDataset, aes(nRep, correctness, colour=targetFrequency ) )
      pp <- pp + geom_point(size = 3)
      pp <- pp + geom_line()
      pp <- pp +facet_grid( run ~ roundNb )
      pp <- pp + ylim(0, 1)
      pp <- cleanPlot(pp)
      print(pp)
      dev.off()
      
    }    
    
    #################################################################################################################
    # snr
    subjects <- levels(snrData$subject)
    nSub <- length(subjects)
    
    for (iS in 1:nSub){
      
      figfilename <- file.path(subFigDir, sprintf("snrPerRunPerRound_%s.png", subjects[iS] ))
      png( filename = figfilename, width=1920, height=1200, units="px" )
      
      subDataset <- snrData[ snrData[ , "subject"] == subjects[iS],  ]
      pp <- ggplot( subDataset, aes(nRep, snr, colour=watchedFrequency, shape=isTarget ) )
      pp <- pp + geom_point(position = position_dodge(0.2), size = 3)
      pp <- pp + geom_line(position = position_dodge(0.2))
      pp <- pp +facet_grid( run ~ roundNb )
      pp <- cleanPlot(pp)
      print(pp)
      dev.off()
      
    }
 

  }
}

#################################################################################################################
#################################################################################################################
#                                 PER CHANNEL SET AND HARMONICS
#################################################################################################################
#################################################################################################################

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

#################################################################################################################
# correctness
figfilename <- file.path(figDir, "corrPerChAndHa.png" )
png( filename = figfilename
     , width=1920, height=1200, units="px"
)

pp <- ggplot( accDataAll, aes(nRep, correctness, colour=targetFrequency) )
pp <- pp + stat_summary(fun.y = mean, geom="point", size = 3)
pp <- pp + stat_summary(fun.y = mean, geom="line")
pp <- pp +facet_wrap( Channels~Harmonics )
pp <- pp + ylim(0, 1)
pp <- cleanPlot(pp)
print(pp)
dev.off()

#################################################################################################################
# snr
figfilename <- file.path(figDir, "snrPerChAndHa.png")
png( filename = figfilename
     , width=1920, height=1200, units="px"
)

pp <- ggplot( snrDataAll, aes(nRep, snr, colour=targetFrequency, shape=isTarget) )
pp <- pp + stat_summary(fun.y = mean, geom="point", size = 3)
pp <- pp + stat_summary(fun.y = mean, geom="line")
pp <- pp +facet_wrap( Channels~Harmonics, scales = "free" )
pp <- cleanPlot(pp)
print(pp)
dev.off()
