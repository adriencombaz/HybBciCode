setwd("d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciCode/dataAnalysisCodes/watchERP/04-watchSSVEP-PSD/")
rm(list = ls())
library(ggplot2)
library(reshape2)
library(grid)

source("d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciCode/dataAnalysisCodes/deps/cleanPlot.R")
source("d:/KULeuven/PhD/rLibrary/plotFactorMeans_InteractionGraphs.R")

filename <- "fftDataset_Oz_1024fs"

fileDir <- "d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciProcessedData/watchERP/03-zzz-watchFFT"
fullfilename <- file.path( fileDir, paste0(filename, ".csv") )

resDir <- "d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciResults/watchERP/03-zzz-watchFFT"
resDir <- file.path(resDir, sprintf("%s_norm", filename))
dir.create(resDir, showWarnings=FALSE)

psdData <- read.csv(fullfilename, header = TRUE)

psdData$frequency = as.factor(psdData$frequency)
psdData$oddball = as.factor(psdData$oddball)
psdData$fileNb = as.factor(psdData$fileNb)
psdData$harmonic = as.factor(psdData$harmonic)
psdData$trial = as.factor(psdData$trial)
psdData$psd = psdData$fftVals
str(psdData)
summary(psdData)

####################################################################################################################
####################################################################################################################

pp <- ggplot( psdData[psdData$harmonic=="1",], aes(frequency, psd, colour=oddball ) )
pp <- pp + stat_summary(fun.data = mean_cl_normal, geom="pointrange", position = position_dodge(0.2))
pp <- pp + facet_wrap( ~subject  )
pp <- cleanPlot(pp)
pp

pp <- ggplot( psdData[psdData$harmonic=="1",], aes(frequency, psd, colour=oddball ) )
pp <- pp + geom_boxplot(aes(fill = oddball))
pp <- pp + facet_wrap( ~subject, scales = "free_y"  )
pp <- cleanPlot(pp)
pp

pp2 <- ggplot( psdData[psdData$harmonic=="2",], aes(frequency, psd, colour=oddball ) )
pp2 <- pp2 + stat_summary(fun.data = mean_cl_normal, geom="pointrange", position = position_dodge(0.2))
pp2 <- pp2 + facet_wrap( ~subject, scales = "free_y"  )
pp2 <- cleanPlot(pp2)
pp2

pp3 <- ggplot( psdData, aes(frequency, psd, colour=oddball ) )
pp3 <- pp3 + stat_summary(fun.data = mean_cl_normal, geom="pointrange", position = position_dodge(0.2))
pp3 <- pp3 + facet_wrap( ~harmonic, scales = "free_y"  )
pp3 <- cleanPlot(pp3)
pp3

pp3 <- ggplot( psdData, aes(frequency, psd, colour=oddball ) )
pp3 <- pp3 + geom_boxplot(aes(fill = oddball))
pp3 <- pp3 + facet_wrap( ~harmonic, scales = "free_y"  )
pp3 <- cleanPlot(pp3)
pp3

####################################################################################################################
####################################################################################################################

library(ez)

mod <- ezANOVA(
  data = psdData[psdData$harmonic=="1",]
  , dv = .(psd)
  , wid = .(subject)
  , within = .(oddball, frequency)
  , type = 2
  , detailed = TRUE
)
mod


ezPlot(
  data = psdData[psdData$harmonic=="1",]
  , dv = .(psd)
  , wid = .(subject)
  , within = .(oddball, frequency)
  , type = 2
  , x = .(frequency)
  , split = .(oddball)
)

pp <- ggplot( psdData[psdData$harmonic=="1",], aes(frequency, psd, colour=oddball ) )
pp <- pp + stat_summary(fun.data = mean_cl_normal, geom="pointrange")
pp <- pp + stat_summary(fun.y = mean, geom="line", aes(group=oddball, linetype=oddball))
pp
