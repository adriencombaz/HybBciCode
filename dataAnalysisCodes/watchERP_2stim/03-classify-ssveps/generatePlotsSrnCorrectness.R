setwd("d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciCode/dataAnalysisCodes/watchERP_2stim/03-classify-ssveps/")
rm(list = ls())

library(plyr)
library(ggplot2)
source("d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciCode/dataAnalysisCodes/deps/cleanPlot.R")


# harmonics <- c(0, 1)
# figDir <- "d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciResults/watchERP_2stim/03-classify-ssveps"
# figDir <- file.path(figDir, "subsetCh1")
# dir.create(figDir, showWarnings=FALSE)  

#################################################################################################################
#################################################################################################################
#################################################################################################################
generateSnrCorrPlots <- function(subsetCh, harmonics, figDir, tag)
{
  for (iS in 1:6){
    filename  <- sprintf("d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciProcessedData/watchERP_2stim/03-classify-ssveps/snrs_subjectS%d.txt", iS)
    snrDataiS   <- read.csv(filename, header = TRUE, sep = ",", strip.white = TRUE)  
    
    snrDataiS$run               <- as.factor(snrDataiS$run)
    snrDataiS$roundNb           <- as.factor(snrDataiS$roundNb)
#     snrDataiS$nRep              <- as.factor(snrDataiS$nRep)    
    snrDataiS$targetFrequency   <- as.factor(snrDataiS$targetFrequency)
    snrDataiS$watchedFrequency  <- as.factor(snrDataiS$watchedFrequency)
    snrDataiS$harmonic          <- as.factor(snrDataiS$harmonic)
    
    if (identical(subsetCh, "all")){ snrDataiS <- snrDataiS[ snrDataiS$harmonic %in% harmonics, ] }
    else{ snrDataiS <- snrDataiS[ snrDataiS$channel %in% subsetCh & snrDataiS$harmonic %in% harmonics, ] }
    snrDataiS$channel <- droplevels( snrDataiS$channel )
    snrDataiS$harmonic <- droplevels( snrDataiS$harmonic )

    varList <- c( "subject", "run","roundNb", "nRep", "targetFrequency", "watchedFrequency", "snr" )
    snrDataiS <- snrDataiS[ , (names(snrDataiS) %in% varList)]

    varList <- c( "subject", "run","roundNb", "nRep", "targetFrequency", "watchedFrequency" )
    snrDataiS <- ddply(snrDataiS, varList, summarize, snr = mean(snr))

    varList <- c( "subject", "run","roundNb", "nRep" )
    accDataiS <- ddply( snrDataiS, varList, summarize, 
                        targetFrequency = unique(targetFrequency), 
                       correctness = ( unique(targetFrequency) == watchedFrequency[which.max(snr)] ) * 1 )

#     snrData12Hz <- snrDataiS[ snrDataiS$watchedFrequency==12, ]
#     snrData15Hz <- snrDataiS[ snrDataiS$watchedFrequency==15, ]
#     varList <- c( "subject", "run","roundNb", "targetFrequency", "nRep" )
#     accDataCheck <- snrData12Hz[ , (names(snrDataiS) %in% varList) ]
#     accDataCheck$correctness <- matrix(data=NA, nrow=nrow(accDataCheck), ncol=1)
#     for (runId in levels(accDataCheck$run)){
#       temp <- accDataCheck[ accDataCheck$run==runId, ]
#       temp12Hz <- snrData12Hz[ snrData12Hz$run==runId, ]
#       temp15Hz <- snrData15Hz[ snrData15Hz$run==runId, ]
#       for (roundId in levels(temp$roundNb)){
#         temp2 <- temp[ temp$roundNb==roundId, ]
#         temp12Hz2 <- temp12Hz[ temp12Hz$roundNb==roundId, ]
#         temp15Hz2 <- temp15Hz[ temp15Hz$roundNb==roundId, ]
#         for (repId in levels(temp$nRep)){
#           temp3 <- temp2[ temp2$nRep==repId, ]
#           temp12Hz3 <- temp12Hz2[ temp12Hz2$nRep==repId, ]
#           temp15Hz3 <- temp15Hz2[ temp15Hz2$nRep==repId, ]
#           if (temp3$targetFrequency == 12){ if (temp12Hz3$snr>temp15Hz3$snr){corr=1} else{corr=0} }
#           if (temp3$targetFrequency == 15){ if (temp12Hz3$snr<temp15Hz3$snr){corr=1} else{corr=0} }
#           accDataCheck$correctness[ accDataCheck$run==runId & accDataCheck$roundNb==roundId & accDataCheck$nRep==repId, ] = corr
#         }
#       }
#     }

    if (iS == 1) { 
      snrData <- snrDataiS
      accData <- accDataiS
    }
    else { 
      snrData <- rbind(snrData, snrDataiS) 
      accData <- rbind(accData, accDataiS) 
    }


  }

  snrData$isTarget <- (snrData$watchedFrequency == snrData$targetFrequency)*1
  snrData$isTarget <- as.factor(snrData$isTarget)

#   
#   
# }

#################################################################################################################
#################################################################################################################
#                           SNR PER RUN/ROUND FOR EACH SUBJECT
#################################################################################################################
#################################################################################################################
subjects <- levels(snrData$subject)
nSub <- length(subjects)
figDirPix <- file.path( figDir, sprintf("perRound_%s", tag) )
dir.create(figDirPix, showWarnings=FALSE)

for (iS in 1:nSub){
  
  figfilename <- file.path(figDirPix, sprintf("detail_snr_perRound_%s.png", subjects[iS] ))
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

#################################################################################################################
#################################################################################################################
#                           CORRECTNESS PER RUN/ROUND FOR EACH SUBJECT
#################################################################################################################
#################################################################################################################
subjects <- levels(snrData$subject)
nSub <- length(subjects)
figDirPix <- file.path( figDir, sprintf("perRound_%s", tag) )

for (iS in 1:nSub){ 
  
  figfilename <- file.path(figDirPix, sprintf("detail_corr_perRound_%s.png", subjects[iS] ))
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
#################################################################################################################
#                           CORRECTNESS PER RUN FOR EACH SUBJECT
#################################################################################################################
#################################################################################################################  
figfilename <- file.path(figDir, sprintf("detail_corr_perRun_%s.png", tag) )
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
#################################################################################################################
#                           SNR PER RUN FOR EACH SUBJECT
#################################################################################################################
#################################################################################################################
figfilename <- file.path(figDir, sprintf("detail_snr_perRun_%s.png", tag) )
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
#                                   CORRECTNESS PER SUBJECT
#################################################################################################################
#################################################################################################################
figfilename <- file.path(figDir, sprintf("detail_corr_perSub_%s.png", tag) )
png( filename = figfilename
     , width=1920, height=1200, units="px"
)

pp <- ggplot( accData, aes(nRep, correctness, colour=targetFrequency) )
pp <- pp + stat_summary(fun.y = mean, geom="point", size = 3)
pp <- pp + stat_summary(fun.y = mean, geom="line")
# pp <- pp + stat_summary(fun.y = mean, geom="point", position = position_dodge(0.2), size = 3)
# pp <- pp + stat_summary(fun.y = mean, geom="line", position = position_dodge(0.2))
#   pp <- pp + geom_point(position = position_dodge(0.2), size = 3)
#   pp <- pp + geom_line(position = position_dodge(0.2))
pp <- pp +facet_wrap( ~subject )
pp <- pp + ylim(0, 1)
pp <- cleanPlot(pp)
print(pp)
dev.off()

#################################################################################################################
#################################################################################################################
#                                   SNR PER SUBJECT
#################################################################################################################
#################################################################################################################
figfilename <- file.path(figDir, sprintf("detail_snr_perSub_%s.png", tag) )
png( filename = figfilename
     , width=1920, height=1200, units="px"
)

pp <- ggplot( snrData, aes(nRep, snr, colour=targetFrequency, shape=isTarget) )
pp <- pp + stat_summary(fun.y = mean, geom="point", size = 3)
pp <- pp + stat_summary(fun.y = mean, geom="line")
# pp <- pp + stat_summary(fun.y = mean, geom="point", position = position_dodge(0.2), size = 3)
# pp <- pp + stat_summary(fun.y = mean, geom="line", position = position_dodge(0.2))
#   pp <- pp + geom_point(position = position_dodge(0.2), size = 3)
#   pp <- pp + geom_line(position = position_dodge(0.2))
pp <- pp +facet_wrap( ~subject, scales = "free" )
pp <- cleanPlot(pp)
print(pp)
dev.off()

}

#################################################################################################################
#################################################################################################################
#################################################################################################################

subsetCh1 <- c( "O1", "Oz", "O2" )
subsetCh2 <- c( "PO3", "PO4", "O1", "Oz", "O2" )
subsetCh3 <- c( "CP5", "CP1", "CP2", "CP6", "P7", "P3", "Pz", "P4", "P8", "PO3", "PO4", "O1", "Oz", "O2" )
subsetCh4 <- c( "C3", "Cz", "C4", "CP5", "CP1", "CP2", "CP6", "P7", "P3", "Pz", "P4", "P8", "PO3", "PO4", "O1", "Oz", "O2" )
subsetCh5 <- "all"
subsetCh <- list(subsetCh1, subsetCh2, subsetCh3, subsetCh4, subsetCh5)

harmonics <- c(0, 1)

# figDir <- "d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciResults/watchERP_2stim/03-classify-ssveps"
# figDir <- file.path(figDir, "subsetCh1")
# dir.create(figDir, showWarnings=FALSE)  
# generateSnrCorrPlots(subsetCh[[1]], harmonics, figDir)

for (ii in 1:length(subsetCh)){
  figDir <- "d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciResults/watchERP_2stim/03-classify-ssveps"
#   figDir <- file.path(figDir, sprintf("subsetCh%d", ii))
  tag = sprintf("subsetCh%d", ii)
  dir.create(figDir, showWarnings=FALSE)  
  generateSnrCorrPlots(subsetCh[[ii]], harmonics, figDir, tag)
}


