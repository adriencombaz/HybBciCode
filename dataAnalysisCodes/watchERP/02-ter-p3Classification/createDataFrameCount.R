setwd("d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciCode/dataAnalysisCodes/watchERP/02-ter-p3Classification/")
rm(list = ls())

source("createDataFrame.R")
source("cleanPlot.R")

#################################################################################################################

allSubs   <- levels(accData$subject)
allFreqs  <- levels(accData$frequency)
allNreps  <- unique(accData$nRep)
allClassif<- levels(accData$classifier)
nSubs   <- length(allSubs)
nFreqs  <- length(allFreqs)
nReps   <- length(allNreps)
nClassif<- length(allClassif)
subject     <- rep(NA, nSubs*nFreqs*nReps*nClassif)
frequency   <- rep(NA, nSubs*nFreqs*nReps*nClassif)
nRep        <- rep(NA, nSubs*nFreqs*nReps*nClassif)
classifier  <- rep(NA, nSubs*nFreqs*nReps*nClassif)
correctnessCount <- rep(NA, nSubs*nFreqs*nReps*nClassif)
correctnessRatio <- rep(NA, nSubs*nFreqs*nReps*nClassif)

count <- 1
for (iS in 1:nSubs){
  for (iF in 1:nFreqs){
    for (iR in 1:nReps){
      for (iC in 1:nClassif){
        
        subject[count] <- allSubs[iS]
        frequency[count] <- allFreqs[iF]
        nRep[count] <- allNreps[iR]
        classifier[count] <- allClassif[iC]
        
        temp <- subset(accData, subject == allSubs[iS])
        temp <- subset(temp, frequency == allFreqs[iF])
        temp <- subset(temp, nRep == allNreps[iR])
        temp <- subset(temp, classifier == allClassif[iC])
        
        correctnessCount[count] <- sum(temp$correctness)
        correctnessRatio[count] <- sum(temp$correctness) / length((temp$correctness))
        
        count <- count+1
      }
    }
  }
}

accDataCount <- data.frame(subject, classifier, frequency, nRep, correctnessCount, correctnessRatio)

#################################################################################################################

library(ggplot2)
library(scales)
dataToPlot <- subset(accDataCount, classifier=="normal")
pp <- ggplot( dataToPlot, aes(nRep, correctnessRatio, colour=frequency, shape=frequency) )
pp <- pp + geom_point(position = position_jitter(w = 0.2, h = 0), size = 3)
pp <- pp + facet_wrap( ~subject ) 
pp <- cleanPlot(pp)
pp <- pp + theme(legend.position=c(0.8334,0.1667))
pp


pp3 <- ggplot( dataToPlot, aes(nRep, correctnessRatio, colour=frequency, shape=frequency) )
pp3 <- pp3 + stat_summary(fun.y = mean, geom="point",  position = position_jitter(w = 0.2, h = 0), size = 3)
pp3 <- cleanPlot(pp3)
pp3 <- pp3 + scale_y_continuous(limits=c(0, 3), trans=logit_trans())
pp3 <- pp3 + scale_y_continuous(limits=c(0, 3))
pp3 <- pp3 + geom_smooth(method="lm", se=F)
pp3 <- pp3 + theme(legend.position=c(0.8334,0.1667))
pp3

#################################################################################################################
# average over subjects and plot logit
allFreqs  <- levels(accData$frequency)
allNreps  <- unique(accData$nRep)
allClassif<- levels(accData$classifier)
nFreqs  <- length(allFreqs)
nReps   <- length(allNreps)
nClassif<- length(allClassif)
frequency   <- rep(NA, nFreqs*nReps*nClassif)
nRep        <- rep(NA, nFreqs*nReps*nClassif)
classifier  <- rep(NA, nFreqs*nReps*nClassif)
correctnessRatio <- rep(NA, nFreqs*nReps*nClassif)
correctnessRatioLogit <- rep(NA, nFreqs*nReps*nClassif)
for (iF in 1:nFreqs){
  for (iR in 1:nReps){
    for (iC in 1:nClassif){
      temp <- subset(accData, frequency == allFreqs[iF])
      temp <- subset(temp, nRep == allNreps[iR])
      temp <- subset(temp, classifier == allClassif[iC])

      frequency[count] <- allFreqs[iF]
      nRep[count] <- allNreps[iR]
      classifier[count] <- allClassif[iC]
      correctnessRatio[count] <- mean(temp$correctness)
      correctnessRatioLogit[count] <- log( mean(temp$correctness) / (1-mean(temp$correctness)) )
      
      count <- count+1
    }
  }
}

accDataGdMean <- data.frame(classifier, frequency, nRep, correctnessRatio, correctnessRatioLogit)

# library(scales)
dataToPlot <- subset(accDataGdMean, classifier=="normal")
pp1 <- ggplot( dataToPlot, aes(nRep, correctnessRatio, colour=frequency, shape=frequency) )
pp1 <- pp1 + geom_point(position = position_jitter(w = 0.2, h = 0), size = 3)
pp1 <- pp1 + scale_y_continuous(trans=logit_trans())
pp1 <- cleanPlot(pp1)
# pp1 + geom_smooth(method="lm", se=F)
pp1

dataToPlot <- subset(accDataGdMean, classifier=="normal")
pp2 <- ggplot( dataToPlot, aes(nRep, correctnessRatioLogit, colour=frequency, shape=frequency) )
pp2 <- pp2 + geom_point(position = position_jitter(w = 0.2, h = 0), size = 3)
pp2 <- cleanPlot(pp2)
pp2 + geom_smooth(method="lm", se=F)

#################################################################################################################

library(lme4)
accDataCount1 <- subset(accDataCount, classifier=="normal")
accDataCount1 <- subset(accDataCount1, select = -c(classifier))
# accDataCount1$nRep <- as.factor(accDataCount1$nRep)

str(accDataCount1)
summary(accDataCount1)

lmH1 <- lmer( correctnessCount ~ frequency + ( 1 | subject/nRep ), data = accDataCount1 )
lmH0 <- lmer( correctness ~ ( 1 | subject/nRep ), data = accDataCount1 )
anova(lmH0, lmH1)

#################################################################################################################

