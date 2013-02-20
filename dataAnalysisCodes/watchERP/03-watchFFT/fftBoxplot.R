setwd("d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciCode/dataAnalysisCodes/watchERP/03-watchFFT/")
rm(list = ls())
library(ggplot2)
library(reshape2)

fftData <- read.csv("fftDataForR.csv", header = TRUE)

subset <- subset(fftData, channelR == 'Oz', select = -channelR)

subset2 <- subset(subset, subjectR == 'S1', select = -subjectR)

dataToPlot2 <- subset(subset2, select = -c(conditionR, runR))

gpBoxplot <- ggplot(dataToPlot2)
gpBoxplot + 
  geom_boxplot(aes(x=factor(frequency), y=fftValue, fill=factor(stimStyle))
               , position = position_dodge(width = .6)
               , width=.7
               , notch = TRUE ) + 
                 scale_fill_grey(start = 0.8, end = 0.4)

subset2 <- subset(subset, subjectR == 'S2', select = -subjectR)

dataToPlot2 <- subset(subset2, select = -c(conditionR, runR))

gpBoxplot <- ggplot(dataToPlot2)
gpBoxplot + 
  geom_boxplot(aes(x=factor(frequency), y=fftValue, fill=factor(stimStyle))
               , position = position_dodge(width = .6)
               , width=.7
               , notch = TRUE ) + 
                 scale_fill_grey(start = 0.8, end = 0.4)

subset2 <- subset(subset, subjectR == 'S3', select = -subjectR)

dataToPlot2 <- subset(subset2, select = -c(conditionR, runR))

gpBoxplot <- ggplot(dataToPlot2)
gpBoxplot + 
  geom_boxplot(aes(x=factor(frequency), y=fftValue, fill=factor(stimStyle))
               , position = position_dodge(width = .6)
               , width=.7
               , notch = TRUE ) + 
                 scale_fill_grey(start = 0.8, end = 0.4)
