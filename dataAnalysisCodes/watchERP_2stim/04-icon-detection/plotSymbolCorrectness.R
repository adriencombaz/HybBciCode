setwd("d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciCode/dataAnalysisCodes/watchERP_2stim/04-icon-detection/")

rm(list = ls())
library(ggplot2)
source("createSymbolCorrectnessDataset.R")
source("d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciCode/dataAnalysisCodes/deps/cleanPlot.R")

figDir = "d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciResults/watchERP_2stim/04-icon-detection/"

accDataset$nRep <- as.numeric(accDataset$nRep)
symbData <- accDataset[ accDataset$type=="symbol", ]

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
  pp <- pp +facet_grid( run ~ roundNb )
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
subjects <- levels(subDataset$subject)
nSub <- length(subjects)

figfilename <- file.path(figDir, sprintf("detail_corr_perRun.png") )
png( filename = figfilename
     , width=1920, height=1200, units="px"
)

pp <- ggplot( symbData, aes(nRep, correctness, colour=targetFrequency) )
pp <- pp + stat_summary(fun.y = mean, geom="point", position = position_dodge(0.2), size = 3)
pp <- pp + stat_summary(fun.y = mean, geom="line", position = position_dodge(0.2))
pp <- pp +facet_grid( subject ~ run )
pp <- pp + ylim(0, 1)
pp <- cleanPlot(pp)
print(pp)
dev.off()
