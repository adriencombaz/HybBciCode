setwd("d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciCode/dataAnalysisCodes/watchERP_2stim/02--classify-erps-one-classifier-per-stimFreq/")
rm(list = ls())

library(ggplot2)
source("createP3CorrectnessDataset.R")
source("d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciCode/dataAnalysisCodes/deps/cleanPlot.R")

figDir = "d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciResults/watchERP_2stim/02--classify-erps-one-classifier-per-stimFreq/"

accData <- p3Dataset
accData$classifier <- "perFreq"
rm(p3Dataset)

source("d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciCode/dataAnalysisCodes/watchERP_2stim/02-classify-erps/createP3CorrectnessDataset.R")
p3Dataset$classifier <- "single"

accData <- rbind(accData, p3Dataset)
rm(p3Dataset)

accData$classifier <- as.factor(accData$classifier)
accData <- accData[ accData$condition == "train12_test345678", ]
accData$condition <- droplevels( accData$condition )
accData$run <- droplevels( accData$run )

#################################################################################################################
#################################################################################################################

pp <- ggplot( accData, aes(nRep, correctness, colour=classifier ) )
pp <- pp + stat_summary(fun.y = mean, geom="point", position = position_dodge(0.4), size = 3)
pp <- pp + stat_summary(fun.y = mean, geom="line", position = position_dodge(0.4))
pp <- pp + facet_wrap( ~subject )
pp <- pp + ylim(0, 1)
pp <- cleanPlot(pp)
print(pp)

pp <- ggplot( accData, aes(nRep, correctness, colour=classifier ) )
pp <- pp + stat_summary(fun.y = mean, geom="point", position = position_dodge(0.4), size = 3)
pp <- pp + stat_summary(fun.y = mean, geom="line", position = position_dodge(0.4))
pp <- pp + facet_grid( targetFrequency~subject )
pp <- pp + ylim(0, 1)
pp <- cleanPlot(pp)
print(pp)