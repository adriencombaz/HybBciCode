setwd("d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciCode/dataAnalysisCodes/watchERP/04-watchSSVEP-PSD/")
rm(list = ls())
library(ggplot2)
library(reshape2)
library(grid)
library(plyr)
library(nlme)
library(lattice)

source("d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciCode/dataAnalysisCodes/deps/cleanPlot.R")

####################################################################################################
sigmaTrInt <- 257
sigmaTrSlo <- 90
sigmaSubInt <- 276
sigmaSubSlo <- 96
sigmaResid <- 185
roTrIntSlo <- -0.20
roSubIntSlo <- -0.11
####################################################################################################

nSub <- 8
nCond <- 2
nTrialsPerSubAndCond <- 12
nTrialsPerSub <- nTrialsPerSubAndCond*nCond
nTrials <- nTrialsPerSubAndCond*nSub*nCond
timePoints <- 1:14
nTimePoints <- length(timePoints)

beta0 <- 148 # intercept
beta1 <- 219  # slope
beta2 <- 31  # shift in intercept for 2nd condition
beta3 <- 20  # shift in slope for 2nd condition

sigmaSubInt <- 20 # between-subject intercept variablity
sigmaSubSlo <- 25 # between-subject slope variablity
sigmaTrInt <- 10  # mean between-trial intercept varibility (mean over subjects)
sigmaTrSlo <- 20  # mean between-trial slope varibility (mean over subjects)
sigmaSub_sigmaTrInt <- 2 # between-subject variability of the between-trial intercept variability
sigmaSub_sigmaTrSlo <- 3 # between-subject variability of the between-trial slope variability
sigmaResid <- 30

sigmaTrInt_perSub <- rnorm(nSub, mean=sigmaTrInt, sd=sigmaSub_sigmaTrInt) # between-trial intercept varibility for each subject
sigmaTrSlo_perSub <- rnorm(nSub, mean=sigmaTrSlo, sd=sigmaSub_sigmaTrSlo) # between-trial slope varibility for each subject

bSubInt <- rnorm(nSub, mean=0, sd=sigmaSubInt)
bSubSlo <- rnorm(nSub, mean=0, sd=sigmaSubSlo)
bTrInt <- matrix(data=NA, nrow=nTrialsPerSub, ncol=nSub)
bTrSlo <- matrix(data=NA, nrow=nTrialsPerSub, ncol=nSub)
for (iS in 1:nSub){
  bTrInt[,iS] <- rnorm(nTrialsPerSub, mean=0, sd=sigmaTrInt_perSub[iS])
  bTrSlo[,iS] <- rnorm(nTrialsPerSub, mean=0, sd=sigmaTrSlo_perSub[iS])
}

residNoise <- rnorm(nTrials*nTimePoints, mean=0, sd=sigmaResid)


####################################################################################################
####################################################################################################

value   <- vector(mode="numeric", length=nTrials*nTimePoints)
subject <- vector(mode="character", length=nTrials*nTimePoints)
trial   <- vector(mode="character", length=nTrials*nTimePoints)
trialInSub <- vector(mode="character", length=nTrials*nTimePoints)
trialInSubInCond <- vector(mode="character", length=nTrials*nTimePoints)
time    <- vector(mode="numeric", length=nTrials*nTimePoints)
condition <- vector(mode="character", length=nTrials*nTimePoints)

ind <- 1
indTrial <- 1
for (iS in 1:nSub){
  for (iCond in 1:nCond){
    for (iT in 1:nTrialsPerSubAndCond){
      for (iTp in 1:nTimePoints){
        value[ind] <- beta0 + beta2*(iCond-1) + bTrInt[(iCond-1)*nTrialsPerSubAndCond+iT, iS] + bSubInt[iS] +
          timePoints[iTp] * ( beta1 + beta3*(iCond-1) + bTrSlo[(iCond-1)*nTrialsPerSubAndCond+iT, iS] + bSubSlo[iS] ) +
          residNoise[(indTrial-1)*nTimePoints + iTp]
        subject[ind] <- sprintf("S%.2d", iS)
        trialInSubInCond[ind] <- sprintf("Tr%.2d", iT)
        trialInSub[ind] <- sprintf("Tr%.2d", (iCond-1)*nTrialsPerSubAndCond+iT)
        trial[ind] <- sprintf("Tr%.2d", indTrial)
        time[ind] <- timePoints[iTp]
        condition[ind] <- sprintf("C%d", iCond-1)
        ind <- ind+1
      }
      indTrial <- indTrial+1
    }
  }
}

art <- data.frame(trial, subject, condition, trialInSub, trialInSubInCond, time, value)


####################################################################################################
####################################################################################################

pp1 <- ggplot( art, aes(time, value, colour=condition) )
pp1 <- pp1 + geom_point() + geom_line( aes(time, value, group=trialInSub) )
pp1 <- pp1 + facet_wrap( ~subject )
pp1 <- cleanPlot(pp1)
pp1



####################################################################################################
####################################################################################################

