setwd("d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciCode/dataAnalysisCodes/watchERP/04-watchSSVEP-SNR/")
rm(list = ls())
library(ggplot2)
library(reshape2)
library(grid)

source("d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciCode/dataAnalysisCodes/deps/cleanPlot.R")

fontsize <- 12;

snrDataOz <- read.csv("d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciProcessedData/watchERP/04-watchSSVEP-SNR/snrDatasetOz.csv", header = TRUE)

snrDataOz$frequency = as.factor(snrDataOz$frequency)
snrDataOz$oddball = as.factor(snrDataOz$oddball)
snrDataOz$fileNb = as.factor(snrDataOz$fileNb)
snrDataOz$trial = as.factor(snrDataOz$trial)
# snrDataOz$stimDuration = as.factor(snrDataOz$stimDuration)
str(snrDataOz)
summary(snrDataOz)

##############################################################################################################"

pp <- ggplot(snrDataOz,aes(stimDuration, snr, shape=oddball, colour=oddball) )
pp <- pp + geom_point( position = position_jitter(w = 0.2, h = 0), size = 3 ) 
pp <- pp + facet_grid(subject ~ frequency )
pp <- pp + geom_smooth(method="lm", aes(fill=oddball), se = F)
pp <- cleanPlot(pp)
pp



pp2 <- ggplot(snrDataOz,aes(stimDuration, snr, shape=frequency, colour=frequency) )
pp2 <- pp2 + geom_point( position = position_jitter(w = 0.2, h = 0), size = 3 ) 
pp2 <- pp2 + facet_grid( oddball ~ subject )
pp2 <- pp2 + geom_smooth(method="lm", aes(fill=frequency), se = F)
pp2 <- cleanPlot(pp2)
pp2

