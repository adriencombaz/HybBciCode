setwd("d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciCode/dataAnalysisCodes/watchERP/04-watchSSVEP-SNR/")
rm(list = ls())
library(ggplot2)
library(reshape2)
library(grid)

source("d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciCode/dataAnalysisCodes/deps/cleanPlot.R")
source("d:/KULeuven/PhD/rLibrary/plotFactorMeans_InteractionGraphs.R")

####################################################################################################################
####################################################################################################################
generatePlots <- function(filename)
{

  fileDir <- "d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciProcessedData/watch-ERP/04-watchSSVEP-SNR"
  fullfilename <- file.path( fileDir, paste0(filename, ".csv") )
  
  resDir <- "d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciResults/watchERP/04-watchSSVEP-SNR"
  resDir <- file.path(resDir, filename)
  dir.create(resDir, showWarnings=FALSE)
  
  snrData <- read.csv(fullfilename, header = TRUE)
  
  snrData$frequency = as.factor(snrData$frequency)
  snrData$oddball = as.factor(snrData$oddball)
  snrData$fileNb = as.factor(snrData$fileNb)
  snrData$trial = as.factor(snrData$trial)
  str(snrData)
  summary(snrData)
  
  ####################################################################################################################

  pp <- ggplot( snrData, aes(stimDuration, snr, colour=oddball ) )
  pp <- pp + stat_summary(fun.data = mean_cl_normal, geom="pointrange", position = position_dodge(0.2))
  pp <- pp + facet_grid( subject ~ frequency, scales = "free_y"  )
  pp <- cleanPlot(pp)
  # pp
  
  figname = paste0("compareOddball", ".png")
  ggsave( figname 
          , plot = pp
          , path = resDir
          , width = 30
          , height = 20
          , units = "cm"
  )
  
  ####################################################################################################################
  
  pp2 <- ggplot( snrData, aes(stimDuration, snr, colour=frequency ) )
  pp2 <- pp2 + stat_summary(fun.data = mean_cl_normal, geom="pointrange", position = position_dodge(0.4))
  pp2 <- pp2 + facet_grid( oddball ~ subject, scales = "free_y"  )
  pp2 <- cleanPlot(pp2)
  # pp2
  
  figname = paste0("compareFrequencies2", ".png")
  ggsave( figname 
          , plot = pp2
          , path = resDir
          , width = 30
          , height = 20
          , units = "cm"
  )
  
  ####################################################################################################################
  
  factorList <- c("stimDuration", "frequency", "oddball")
  outcome <- "snr"
  dataframe <- snrData
  # source("d:/KULeuven/PhD/rLibrary/plotFactorMeans_InteractionGraphs.R")
  
  png(filename = file.path(resDir, "interactionGraph.png")
      , width = 30
      , height = 20
      , units = "cm"
      , res = 300
  )
  plotFactorMeans_InteractionGraphs(dataframe, factorList, outcome)
  dev.off()
  
  allSub <- levels(dataframe$subject)
  for (iS in 1:length(allSub)){
    dataToPlotSub <- subset(dataframe, subject==allSub[iS])
    
    png(filename = file.path(resDir, sprintf("interactionGraph_S%d.png", iS))
        , width = 30
        , height = 20
        , units = "cm"
        , res = 300
    )
    plotFactorMeans_InteractionGraphs(dataToPlotSub, factorList, outcome)
    dev.off()  
  }

}

####################################################################################################################
####################################################################################################################

filenames <- c( "snrDataset_O1OzO2_1Ha"
                , "snrDataset_O1OzO2_2Ha"
                , "snrDataset_Oz_1Ha"
                , "snrDataset_Oz_2Ha"
                , "snrDataset_SelChan_1Ha"
                , "snrDataset_SelChan_2Ha"
                )

for (iF in 1:length(filenames))
{
  generatePlots(filenames[iF])
}

####################################################################################################################
####################################################################################################################
