setwd("d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciCode/dataAnalysisCodes/watchERP/04-watchSSVEP-PSD/")
rm(list = ls())
library(ggplot2)
library(reshape2)
library(grid)

source("d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciCode/dataAnalysisCodes/deps/cleanPlot.R")
source("d:/KULeuven/PhD/rLibrary/plotFactorMeans_InteractionGraphs.R")
source("d:/KULeuven/PhD/rLibrary/plotInteractionGraphs_level2.R")

channels  = c("CP5",   "CP1",   "CP2",   "CP6", "P7",   "P3",   "Pz",   "P4",   "P8",  "PO3", "PO4", "O1", "Oz", "O2")
harmonics = c(1, 2)

fileDir <- "d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciProcessedData/watch-ERP/04-watchSSVEP-PSD"
resDir <- "d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciResults/watchERP/04-watchSSVEP-PSD/interactionGraphsPerChanPerHa"
dir.create(resDir, showWarnings=FALSE)

for (iCh in 1:length(channels)){
  for (iHa in 1:length(harmonics)){
    
    filename = sprintf("psdDataset_%s_Ha%d", channels[iCh], harmonics[iHa])
    fullfilename <- file.path( fileDir, paste0(filename, ".csv") )
    
    psdData <- read.csv(fullfilename, header = TRUE)
    
    psdData$frequency = as.factor(psdData$frequency)
    psdData$oddball = as.factor(psdData$oddball)
    psdData$fileNb = as.factor(psdData$fileNb)
    psdData$trial = as.factor(psdData$trial)
    psdData$psd = sqrt(psdData$psd)
    

    png(filename = file.path(resDir, sprintf("level1_ha%d_%s.png", harmonics[iHa], channels[iCh]))
        , width = 30
        , height = 20
        , units = "cm"
        , res = 300
    )
    plotFactorMeans_InteractionGraphs(psdData, c("stimDuration", "frequency", "oddball"), "psd")
    dev.off()    

    png(filename = file.path(resDir, sprintf("level2_ha%d_%s.png", iHa, channels[iCh]))
        , width = 30
        , height = 20
        , units = "cm"
        , res = 300
    )
    plotInteractionGraphs_level2(psdData, "stimDuration", "psd",  c("oddball", "frequency"))
    dev.off()      

  }
}