setwd("d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciCode/dataAnalysisCodes/watchERP/04-watchSSVEP-SNR/")
rm(list = ls())
library(ggplot2)
library(reshape2)

snrDataOz <- read.csv("snrDatasetOz.csv", header = TRUE)

snrDataOz$frequency = as.factor(snrDataOz$frequency)
snrDataOz$oddball = as.factor(snrDataOz$oddball)
snrDataOz$fileNb = as.factor(snrDataOz$fileNb)
snrDataOz$trial = as.factor(snrDataOz$trial)
snrDataOz$stimDuration = as.factor(snrDataOz$stimDuration)
str(snrDataOz)
summary(snrDataOz)

dataS1 = subset( snrDataOz, subject == "S1", select = c("frequency", "oddball", "stimDuration", "snr") )
dataS1 = subset( dataS1, stimDuration == "14", select = -stimDuration )
str(dataS1)
summary(dataS1)

pp <- ggplot( dataS1 ) + geom_point( aes(frequency, snr, shape=oddball, colour=oddball), position = position_jitter(w = 0.1, h = 0)  ) 

gpBoxplot <- ggplot(dataS1)
gpBoxplot + 
  geom_boxplot(aes(x=frequency, y=snr, fill=oddball), position = position_dodge(width = .9), width=.7) + 
  scale_fill_grey(start = 0.8, end = 0.4)
