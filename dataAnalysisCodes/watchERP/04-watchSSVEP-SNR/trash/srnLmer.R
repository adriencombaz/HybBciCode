setwd("d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciCode/dataAnalysisCodes/watchERP/04-watchSSVEP-SNR/")
rm(list = ls())
library(ggplot2)
library(reshape2)
library(grid)

source("d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciCode/dataAnalysisCodes/deps/cleanPlot.R")
source("d:/KULeuven/PhD/rLibrary/plotFactorMeans_InteractionGraphs.R")

filename <- snrDataset_O1OzO2_1Ha

####################################################################################################################
####################################################################################################################
# logisticReg <- function(filename)
# {
  
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
  
  
# }

####################################################################################################################
####################################################################################################################

# filenames <- c( "snrDataset_O1OzO2_1Ha"
#                 , "snrDataset_O1OzO2_2Ha"
#                 , "snrDataset_Oz_1Ha"
#                 , "snrDataset_Oz_2Ha"
#                 , "snrDataset_SelChan_1Ha"
#                 , "snrDataset_SelChan_2Ha"
# )
# 
# for (iF in 1:length(filenames))
# {
#   logisticReg(filenames[iF])
# }

####################################################################################################################
####################################################################################################################
