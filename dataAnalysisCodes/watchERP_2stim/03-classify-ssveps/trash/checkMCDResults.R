setwd("d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciCode/dataAnalysisCodes/watchERP_2stim/03-classify-ssveps/")
rm(list = ls())

library(ggplot2)
library(lme4)
library(LMERConvenienceFunctions)
library(languageR)

source("d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciCode/dataAnalysisCodes/deps/cleanPlot.R")

#################################################################################################################
for (iS in 1:5){
  filename <- sprintf("d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciProcessedData/watchERP_2stim/03-classify-ssveps/correctness_subjectS%d.txt", iS)
  accData1 <- read.csv(filename, header = TRUE, sep = ",", strip.white = TRUE)
  
  accData1$targetFrequency <- as.factor(accData1$targetFrequency)
  accData1$winnerFreqSelChan <- as.factor(accData1$winnerFreqSelChan)
  accData1$winnerFreqAllChan <- as.factor(accData1$winnerFreqAllChan)
  accData1$run <- as.factor(accData1$run)
  accData1$roundNb <- as.factor(accData1$roundNb)
  accData1$nRep <- as.factor(accData1$nRep)
  
  if (iS == 1) { accData <- accData1 }
  else { accData <- rbind(accData, accData1) }

#   temp1 <- subset(accData, select = c(subject, run, roundNb, nRep, targetFrequency) )
#   temp2 <- temp1
#   temp1$snrFreq <- 12
#   temp1$snr <- accData$snr12HzSelChan
#   temp2$snrFreq <- 15
#   temp2$snr <- accData$snr15HzSelChan
#   snrData <- rbind(temp1, temp2)
#   snrData$snrFreq <- as.factor(snrData$snrFreq) 
#   str(snrData)
#   summary(snrData)

}
  #################################################################################################################
str(accData)
summary(accData)

  pp <- ggplot( accData, aes(nRep, correctnessSelChan, colour=targetFrequency) )
#   pp <- pp + stat_summary(fun.y = mean, geom="point",  position = position_jitter(w = 0.2, h = 0), size = 3)
  pp <- pp + stat_summary(fun.y = mean, geom="point", position = position_dodge(.5), size = 1)
#   pp <- pp + stat_summary(fun.data = mean_cl_normal, geom = "pointrange", width = 0.2, position = position_dodge(.5), size = 1)
  # pp <- pp + facet_grid( trainingRun_1~trainingRun_2  )
  pp <- pp + facet_wrap( ~subject  )
  pp <- cleanPlot(pp)
  # pp <- pp + theme(legend.position=c(0.8334,0.1667))
  pp <- pp + ylim(0, 1)
  pp
  
pp2 <- ggplot( accData, aes(nRep, correctnessAllChan, colour=targetFrequency) )
#   pp <- pp + stat_summary(fun.y = mean, geom="point",  position = position_jitter(w = 0.2, h = 0), size = 3)
pp2 <- pp2 + stat_summary(fun.y = mean, geom="point", position = position_dodge(.5), size = 1)
# pp2 <- pp2 + stat_summary(fun.data = mean_cl_normal, geom = "pointrange", width = 0.2, position = position_dodge(.5), size = 1)
# pp <- pp + facet_grid( trainingRun_1~trainingRun_2  )
pp2 <- pp2 + facet_wrap( ~subject  )
pp2 <- cleanPlot(pp2)
# pp <- pp + theme(legend.position=c(0.8334,0.1667))
pp2 <- pp2 + ylim(0, 1)
pp2

# pp2 <- ggplot( snrData, aes(nRep, snr, colour=snrFreq) )
# # pp2 <- pp2 + stat_summary(fun.y = mean, geom="point",  position = position_jitter(w = 0.2, h = 0), size = 3)
# # pp <- pp + stat_summary(fun.y = mean, geom="point", position = position_dodge(.5))
# pp2 <- pp2 + stat_summary(fun.data = mean_cl_normal, geom = "pointrange", width = 0.2, position = position_dodge(.5), size = .5)
# # pp <- pp + facet_grid( trainingRun_1~trainingRun_2  )
# pp2 <- pp2 + facet_wrap( ~targetFrequency  )
# # pp <- cleanPlot(pp)
# # pp <- pp + theme(legend.position=c(0.8334,0.1667))
# # pp2 <- pp2 + ylim(0, 1)
# pp2

