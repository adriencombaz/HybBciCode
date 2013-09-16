setwd("d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciCode/dataAnalysisCodes/watchERP/02-xxx-p3Classification/")
rm(list = ls())

library(ggplot2)
library(lme4)
library(LMERConvenienceFunctions)
library(languageR)

source("createDataFrame.R")
source("d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciCode/dataAnalysisCodes/deps/cleanPlot.R")
source("d:/KULeuven/PhD/rLibrary/plotFactorMeans_InteractionGraphs.R")


aveClass <- 0
nRunsForTrain <- 2
FS <- 128
nFoldSvm <- 10

accData <- createDataFrame(aveClass, nRunsForTrain, FS, nFoldSvm)

accData <- accData[accData$subject != "S08", ]
accData$subject <- droplevels(accData$subject)

str(accData)
summary(accData)


#################################################################################################################

# accData <- subset(accData, classifier=="normal")
# accData <- subset(accData, select = -c(classifier, foldTest))
varList <- c("subject", "frequency", "trial", "nRep", "correctness", "condition", "roundNb", "nRepWithinSub")
accData <- accData[ accData$classifier=="normal", varList ]
accData$nRepFac <- as.factor(accData$nRep)
# accData <- accData[ accData$subject!="S9", ]
# accData$subject <- droplevels(accData$subject)
accData <- accData[with(accData, order(subject, frequency, trial, nRep)), ]

str(accData)
summary(accData)

#################################################################################################################

pp <- ggplot( accData, aes(nRep, correctness, colour=condition, shape=condition) )
# pp <- pp + stat_summary(fun.y = mean, geom="point",  position = position_jitter(w = 0.2, h = 0), size = 3)
# pp <- pp + stat_summary(fun.y = mean, geom="point", position = position_dodge(.5))
pp <- pp + stat_summary(fun.data = mean_cl_normal, geom = "pointrange", width = 0.2, position = position_dodge(.5), size = 1)
pp <- pp + facet_wrap( ~subject ) 
pp <- cleanPlot(pp)
# pp <- pp + theme(legend.position=c(0.8334,0.1667))
pp

#################################################################################################################

source("d:/KULeuven/PhD/rLibrary/plotFactorMeans_InteractionGraphs.R")
plotFactorMeans_InteractionGraphs(accData, c("nRep", "frequency"), "correctness")

#################################################################################################################

# f0Vs857_10_12_15    = c(-4, 1, 1, 1, 1)     # oddball vs. hybrid
# f857Vs10_12_15      = c(0, -3, 1, 1, 1)     # hybrid-8-57Hz vs. hybrid-10-12-15-Hz
# f10Vs12_15          = c(0, 0, -2, 1, 1)     # hybrid-10Hz vs. hybrid-12-15-Hz
# f12Vs15             = c(0, 0, 0, -1, 1)     # hybrid-12Hz vs. hybrid-15-Hz
# contrasts(accData$frequency) <- cbind(
#   f0Vs857_10_12_15
#   , f857Vs10_12_15
#   , f10Vs12_15
#   , f12Vs15
# )

allReps <- unique(accData$nRep)
nReps <- length(allReps)
pVals0 <- vector(mode="numeric", length=nReps)
pVals <- vector(mode="numeric", length=nReps)

###############################################################################################################
###############################################################################################################

for (iR in 1:nReps)
{  
  subData <- accData[accData$nRep==iR,]
  
  lmH0 <- lmer( correctness ~ frequency + ( 1 | subject ), data = subData, family = binomial )
  lmH1 <- lmer( correctness ~ frequency + ( 1 | subject/frequency ), data = subData, family = binomial )
  lmH1b <- lmer( correctness ~ frequency + ( frequency | subject ), data = subData, family = binomial )
  lmH0a <- lmer( correctness ~ frequency + ( 1 | subject/(frequency:trial) ), data = subData, family = binomial )
  lmH1a <- lmer( correctness ~ frequency + ( 1 | subject/frequency/trial ), data = subData, family = binomial )
  
#   tete <- pacf( resid( lmH1 ) )
#   plot( fitted(lmH1), residuals(lmH1) )
#   abline(h=0)
  
  lmH2 <- lmer( correctness ~ 1 + ( 1 | subject/frequency ), data = subData, family = binomial )
  
  temp <- anova(lmH0, lmH1)
  pVals0[iR] <- temp[2,7]
  temp <- anova(lmH1, lmH2)
  pVals[iR] <- temp[2,7]
}

subData <- accData[accData$nRep==2,]
pp<-ggplot(subData, aes(frequency, correctness))
pp<-pp + stat_summary(fun.y=mean, geom=("point"))
pp<-pp + stat_summary(fun.y=mean, geom=("line"), aes(group=1), size=2)
pp<-pp + stat_summary(fun.y=mean, geom=("point"), aes(group=subject, colour=subject))
pp<-pp + stat_summary(fun.y=mean, geom=("line"), aes(group=subject, colour=subject))
pp

logitFun <- function(x){ return( logit( mean(x) ) )}
pp2<-ggplot(subData, aes(frequency, correctness))
pp2<-pp2 + stat_summary(fun.y=logitFun, geom=("point"))
pp2<-pp2 + stat_summary(fun.y=logitFun, geom=("line"), aes(group=1), size=2)
pp2<-pp2 + stat_summary(fun.y=logitFun, geom=("point"), aes(group=subject, colour=subject))
pp2<-pp2 + stat_summary(fun.y=logitFun, geom=("line"), aes(group=subject, colour=subject))
pp2

subData$fitted <- fitted(lmH0)
