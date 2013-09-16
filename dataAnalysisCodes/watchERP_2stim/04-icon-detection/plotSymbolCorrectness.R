setwd("d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciCode/dataAnalysisCodes/watchERP_2stim/04-icon-detection/")

rm(list = ls())
library(ggplot2)
source("createSymbolCorrectnessDatasetFnc.R")
source("d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciCode/dataAnalysisCodes/deps/cleanPlot.R")

figDir = "d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciResults/watchERP_2stim/04-icon-detection/"

trainRuns     <- c(1,2)
subsetChTag   <- "ch-CP-P-PO-O"
harmonicsTag  <- "fund-ha1"
FS            <- 128
nFoldSvm      <- 10

accDataset <- createSymbolCorrectnessDatasetFnc(trainRuns, subsetChTag, harmonicsTag, FS, nFoldSvm)

accDataset$nRepFac <- as.factor(accDataset$nRep)
symbData <- accDataset[ accDataset$type=="symbol", ]

pp <- ggplot( symbData, aes(nRepFac, 100*correctness, colour=subject ) )
pp <- pp + stat_summary(fun.y = mean, geom="point", position = position_dodge(0.4), shape = 20, size = 3)
pp <- pp + stat_summary(fun.y = mean, geom="line", position = position_dodge(0.4), aes(group=subject))
pp <- pp + ylim(0, 100)
pp <- cleanPlot(pp)
print(pp)

pp <- ggplot( accDataset, aes(nRepFac, 100*correctness, colour=type ) )
pp <- pp + stat_summary(fun.y = mean, geom="point", position = position_dodge(0.4), shape = 20, size = 3)
pp <- pp + stat_summary(fun.y = mean, geom="line", position = position_dodge(0.4), aes(group=type))
pp <- pp + facet_wrap(~subject)
pp <- pp + ylim(0, 100)
pp <- cleanPlot(pp)
print(pp)

#################################################################################################################
#################################################################################################################
#                                   GRAND AVERAGE ACCURACIES
#################################################################################################################
#################################################################################################################
figfilename <- file.path(figDir, "symbAccuracy_grandAverage.png")
png( filename = figfilename
     , width=1920, height=1200, units="px"
)

pp <- ggplot( symbData, aes(nRep, correctness, colour=targetFrequency ) )
pp <- pp + stat_summary(fun.y = mean, geom="point", position = position_dodge(0.4), shape = 20, size = 3)
pp <- pp + stat_summary(fun.y = mean, geom="line", position = position_dodge(0.4))
pp <- pp + ylim(0, 1)
pp <- cleanPlot(pp)
print(pp)
dev.off()

#################################################################################################################
#################################################################################################################
#                                       ACCURACIES PER SUBJECT
#################################################################################################################
#################################################################################################################
figfilename <- file.path(figDir, "symbAccuracy.png")
png( filename = figfilename
     , width=1920, height=1200, units="px"
)
pp <- ggplot( symbData, aes(nRep, correctness, colour=targetFrequency ) )
pp <- pp + stat_summary(fun.y = mean, geom="point", position = position_dodge(0.4), shape = 20, size = 3)
pp <- pp + stat_summary(fun.y = mean, geom="line", position = position_dodge(0.4))
pp <- pp + facet_wrap( ~subject )
pp <- pp + ylim(0, 1)
pp <- cleanPlot(pp)
print(pp)
dev.off()


pp <- ggplot( symbData, aes(nRepFac, 100*correctness, colour=subject ) )
pp <- pp + stat_summary(fun.y = mean, geom="point", position = position_dodge(0.4), shape = 20, size = 3)
pp <- pp + stat_summary(fun.y = mean, geom="line", position = position_dodge(0.4), aes(group=subject))
pp <- pp + ylim(0, 100)
pp <- cleanPlot(pp)
print(pp)

#################################################################################################################
#################################################################################################################
#                                 DETAILS PER RUN / ROUND
#################################################################################################################
#################################################################################################################

subjects <- levels(symbData$subject)
nSub <- length(subjects)

for (iS in 1:nSub){ 
  
  figfilename <- file.path(figDir, sprintf("detail_corr_perRound_%s.png", subjects[iS] ))
  png( filename = figfilename
       , width=1920, height=1200, units="px"
  )
  
  subDataset_iS <- symbData[ symbData[ , "subject"] == subjects[iS],  ]
  pp <- ggplot( subDataset_iS, aes(nRep, correctness, colour=targetFrequency ) )
  pp <- pp + geom_point(size = 3)
  pp <- pp + geom_line()
  pp <- pp +facet_grid( testingRun ~ roundNb )
  pp <- pp + ylim(0, 1)
  pp <- cleanPlot(pp)
  print(pp)
  dev.off()
  
}

#################################################################################################################
#################################################################################################################
#                                 DETAILS PER RUN
#################################################################################################################
#################################################################################################################
subjects <- levels(symbData$subject)
nSub <- length(subjects)

figfilename <- file.path(figDir, sprintf("detail_corr_perRun.png") )
png( filename = figfilename
     , width=1920, height=1200, units="px"
)

pp <- ggplot( symbData, aes(nRep, correctness, colour=targetFrequency) )
pp <- pp + stat_summary(fun.y = mean, geom="point", position = position_dodge(0.2), size = 3)
pp <- pp + stat_summary(fun.y = mean, geom="line", position = position_dodge(0.2))
pp <- pp +facet_grid( subject ~ testingRun )
pp <- pp + ylim(0, 1)
pp <- cleanPlot(pp)
print(pp)
dev.off()
