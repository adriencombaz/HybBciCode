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
####################################################################################################

nSub <- 20;#8
nCond <- 2
nTrialsPerSubAndCond <- 30#12
nTrials <- nTrialsPerSubAndCond*nSub*nCond
timePoints <- 1:14
nTimePoints <- length(timePoints)

beta0 <- 148
beta1 <- 219
beta2 <- -31
beta3 <- -20

sigmaTrInt <- 257
sigmaTrSlo <- 90
sigmaSubInt <- 276
sigmaSubSlo <- 96
sigmaResid <- 185
roTrIntSlo <- -0.20
roSubIntSlo <- -0.11

bTrInt <- rnorm(nTrials, mean=0, sd=sigmaTrInt)
bTrSloTemp <- rnorm(nTrials, mean=0, sd=sigmaTrSlo)
bTrSlo <- roTrIntSlo*bTrInt + (1-roTrIntSlo)*bTrSloTemp
bSubInt <- rnorm(nSub, mean=0, sd=sigmaSubInt)
bSubSloTemp <- rnorm(nSub, mean=0, sd=sigmaSubSlo)
bSubSlo <- roSubIntSlo*bSubInt + (1-roSubIntSlo)*bSubSloTemp
residNoise <- rnorm(nTrials*nTimePoints, mean=0, sd=sigmaResid)

####################################################################################################
####################################################################################################

value   <- vector(mode="numeric", length=nTrials*nTimePoints)
subject <- vector(mode="character", length=nTrials*nTimePoints)
time    <- vector(mode="numeric", length=nTrials*nTimePoints)
condition <- vector(mode="character", length=nTrials*nTimePoints)
trial   <- vector(mode="character", length=nTrials*nTimePoints)
trialInSub <- vector(mode="character", length=nTrials*nTimePoints)
trialInSubAndCond <- vector(mode="character", length=nTrials*nTimePoints)

indTr <- 1
for (iS in 1:nSub){
  indTrInSub <- 1
  for (iCond in 1:nCond){
    for (iT in 1:nTrialsPerSubAndCond){
      for (iTp in 1:nTimePoints){
        id <- (indTr-1)*nTimePoints + iTp
        value[id] <- beta0 + beta2*(iCond-1) + bTrInt[indTr] + bSubInt[iS] +
                      timePoints[iTp] * ( beta1 + beta3*(iCond-1) + bTrSlo[indTr] + bSubSlo[iS] ) +
                      residNoise[id]
        subject[id]    <- sprintf("S%.2d", iS)
        time[id]       <- iTp
        condition[id]  <- sprintf("C%d", iCond-1)
        trial[id]      <- sprintf("S%.2d-C%d-Tr%.2d", iS, iCond-1, iT)
        trialInSub[id] <- sprintf("S%.2d-Tr%.2d", iS, iT)
        trialInSubAndCond[id] <- sprintf("Tr%.2d", iT)
      }
      indTr <- indTr+1
      indTrInSub <- indTrInSub+1
    }
  }
}

# art <- data.frame(subject, condition, trialInSubAndCond, time, value, trial, trialInSub)
art <- data.frame(subject, time, trialInSubAndCond, condition, value, trial, trialInSub)
art <- art[with(art, order(subject, condition, trialInSubAndCond, time)), ]
art$timeFac <- as.factor(art$time)

####################################################################################################
####################################################################################################

pp1 <- ggplot( art, aes(time, value, colour=condition) )
pp1 <- pp1 + geom_point() + geom_line(  aes(time, value, group=trial)  )
pp1 <- pp1 + facet_wrap( ~subject )
pp1 <- cleanPlot(pp1)
pp1


# pp <- ggplot( psdData, aes(time, psd, colour=condition ) )
# pp <- pp + stat_summary(fun.data = mean_cl_normal, geom="pointrange", position = position_dodge(0.2))
# pp <- pp + facet_grid( subject ~ frequency, scales = "free_y"  )
# pp <- cleanPlot(pp)

####################################################################################################
####################################################################################################

# artGp <- groupedData(value ~ time | subject/condition, data = art)
# plot(artGp)
cs1 <- corCAR1(form=~time|subject/condition/trialInSubAndCond)
cs1 <- Initialize( cs1, data = art )
cm <- corMatrix( cs1 )

####################################################################################################
####################################################################################################

fm0.lme <- lme(
  value~time*condition
  , data=art
  , random = ~time|subject/condition
  , control = list(opt="optim")
)

fm2.lme<-update(fm0.lme, corr = corCAR1(form=~time|subject/condition/trialInSubAndCond))

fm1.lme <- lme(
  value~time*condition
  , data=art
  , random = ~time|subject/condition
  , corr = corGaus(form=~time|subject/condition/trialInSubAndCond)
  , control = list(opt="optim")
)

fm2.lme <- lme(
  value~time*condition
  , data=art
  , random = ~time|subject/condition
  , corr = corAR1(form=~time|subject/condition/trialInSubAndCond)
  , control = list(opt="optim")
)


plot( fm1.lme, fitted(.) ~ time|subject )
plot( fm1.lme, fitted(.) ~ time|subject*condition )
plot(augPred(fm1.lme), col.line = 'black')
plot(augPred(fm1.lme, primary="time"), col.line = 'black')
plot(augPred(fm1.lme) | subject)
plot( fm1.lme, resid(.) ~ time|trial*subject, abline = 0 )
plot( fm1.lme, resid(.) ~ time|subject, abline = 0 )
plot( fm1.lme, resid(.) ~ time|condition, abline = 0 )
plot( fm1.lme, resid(.) ~ time|subject*condition, abline = 0 )
plot( fm1.lme, resid(., type="n") ~ time, abline = 0 )
plot( fm1.lme, resid(., type="n") ~ fitted(.), abline = 0 )
plot( fm1.lme, resid(.) ~ fitted(.)|condition, abline = 0 )
plot( fm1.lme, resid(.) ~ fitted(.)|subject, abline = 0 )
plot( fm1.lme, resid(.) ~ fitted(.)|time, abline = 0 )
plot( fm1.lme, resid(.) ~ fitted(.)|time*condition, abline = 0 )
plot( fm1.lme, resid(.) ~ fitted(.)|subject*condition, abline = 0 )
plot( fm1.lme, resid(.) ~ fitted(.)|time*subject, abline = 0 )
plot(ACF(fm1.lme, maxLag = 10, resType="n"), alpha = 0.01)
plot(ACF(fm1.lme, maxLag = 400, resType="n"), alpha = 0.01)
plot(Variogram( fm1.lme, form = ~ time ))
plot(Variogram( fm1.lme, form = ~ time, resType="n", robust=T ))
