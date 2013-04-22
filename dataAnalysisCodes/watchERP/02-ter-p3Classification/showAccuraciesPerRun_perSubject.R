setwd("d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciCode/dataAnalysisCodes/watchERP/02-ter-p3Classification/")
rm(list = ls())
library(ggplot2)
library(nlme)
library(ez)
library(reshape2)
library(lme4)
library(LMERConvenienceFunctions)
library(languageR)
library(Hmisc)

source("d:/KULeuven/PhD/rLibrary/plot_set.R")

iS <- 8

# for (iS in 1:1)
# {
  filename <- sprintf("d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciProcessedData/watch-ERP/02-ter-p3Classification/LinSvm/subject_S%d/Results_forLogisiticRegression.txt", iS)
  accData1 <- read.csv(filename, header = TRUE, sep = ",", strip.white = TRUE)
  accData1$nAverages = as.factor(accData1$nAverages )
  accData1$foldTrain = as.factor(accData1$foldTrain )
  accData1$foldTest = as.factor(accData1$foldTest )
  accData1 <- subset( accData1, conditionTrain == conditionTest )
  accData1$condition = accData1$conditionTrain;
  accData1 <- subset(accData1, select = -c(conditionTrain, conditionTest))
  
  pp <- ggplot( accData1, aes(nAverages, correctness, colour=foldTest) )
#   pp <- pp + geom_point( position = position_jitter(w = 0.2, h = 0.4), size = 3  )
  pp <- pp + stat_summary(fun.y = sum, geom = "line", aes(group=foldTest))
  pp <- pp + facet_wrap( ~foldTrain + condition, ncol = length(levels(accData1$condition)) )
#   pp <- pp + facet_wrap( foldTrain ~ condition )
  pp
  
pp <- ggplot( accData1, aes(nAverages, correctness, colour=foldTrain) )
pp <- pp + stat_summary(fun.y = sum, geom = "line", aes(group=foldTrain))
pp <- pp + facet_wrap( ~foldTest + condition, ncol = length(levels(accData1$condition)) )
pp

# }

temp = subset(accData1, foldTrain==1, select=-c(foldTrain, subject))
temp2 = subset(temp, condition=="oddball", select=-condition)
temp2$foldTest <- droplevels(temp2)$foldTest

str(temp2)

pp <- ggplot( temp2, aes(nAverages, correctness, colour=foldTest) )
# pp <- pp + geom_point( position = position_jitter(w = 0.2, h = 0.4), size = 3  )
pp <- pp + stat_summary(fun.y = mean, geom = "point")
pp <- pp + stat_summary(fun.y = mean, geom = "line", aes(group=foldTest))
pp



