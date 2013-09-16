setwd("d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciCode/dataAnalysisCodes/watchERP/02-xxx-p3Classification/")
rm(list = ls())

library(ggplot2)
library(lme4)
library(LMERConvenienceFunctions)
library(languageR)
library(reshape2)
library(car)

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


#################################################################################################################

varList <- c("subject", "frequency", "trial", "nRep", "correctness")
accData <- accData[ accData$classifier=="normal", names(accData) %in% varList ]
accData <- accData[, varList]
accData$nRepFac <- as.factor(accData$nRep)
accData <- accData[with(accData, order(subject, frequency, trial, nRep)), ]
str(accData)
summary(accData)

#################################################################################################################
# pp <- ggplot( accData, aes(nRep, correctness, colour=frequency, shape=frequency) )
# pp <- pp + stat_summary(fun.data = mean_cl_normal, geom = "pointrange", width = 0.2, position = position_dodge(.5), size = 1)
# pp <- pp + facet_wrap( ~subject ) 
# pp <- cleanPlot(pp)
# pp

pp <- ggplot( accData, aes(nRepFac, correctness, colour=frequency) )
pp <- pp + stat_summary(fun.y = mean, geom = "point", position = position_dodge(.3), size=3)
pp <- pp + stat_summary(fun.y = mean, geom = "line", aes(group=frequency), position = position_dodge(.3))
pp <- cleanPlot(pp)
pp

(pp2 <- pp + facet_wrap( ~subject ) )


varList <- c("subject", "frequency", "nRep")
dataToPlot <- ddply( 
  accData
  , varList
  , summarise
  , prob = mean(correctness)
  , odd = mean(correctness)/(1-mean(correctness)) 
  , logit1 = log(mean(correctness)/(1-mean(correctness)))
  , logit2 = logit(mean(correctness))
)
dataToPlot$nRepFac <- as.factor(dataToPlot$nRep)

dataToPlot$nRepLog <- log(dataToPlot$nRep)
ppLogit <- ggplot( dataToPlot, aes(nRepFac, logit2, colour=frequency) ) #, shape=frequency) )
ppLogit <- ppLogit + geom_point(position = position_dodge(.3), size=3)
ppLogit <- ppLogit + geom_line(aes(group=frequency))
ppLogit <- ppLogit + facet_wrap( ~subject ) 
ppLogit <- cleanPlot(ppLogit)
ppLogit

ppLogit2 <- ggplot( dataToPlot, aes(nRep, logit2, colour=frequency, shape=frequency) )
ppLogit2 <- ppLogit2 + stat_summary(fun.y = mean, geom = "line", aes(group=frequency))
ppLogit2 <- cleanPlot(ppLogit2)
ppLogit2

dataToPlot$nRepLog <- log(dataToPlot$nRep)
ppLogit3 <- ggplot( dataToPlot, aes(nRepLog, logit2, colour=frequency, shape=frequency) )
# ppLogit <- ppLogit + geom_point(position = position_dodge(.5)) + geom_line(aes(group=frequency),position = position_dodge(.5))
ppLogit3 <- ppLogit3 + geom_line(aes(group=frequency))
ppLogit3 <- ppLogit3 + facet_wrap( ~subject ) 
ppLogit3 <- cleanPlot(ppLogit3)
ppLogit3

ppLogit4 <- ggplot( dataToPlot, aes(nRepLog, logit2, colour=frequency, shape=frequency) )
ppLogit4 <- ppLogit4 + stat_summary(fun.y = mean, geom = "point")
ppLogit4 <- ppLogit4 + stat_summary(fun.y = mean, geom = "line", aes(group=frequency))
ppLogit4 <- cleanPlot(ppLogit4)
ppLogit4


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
# 
# Rep1VsRep2 = c(-1, 1, 0, 0, 0, 0, 0, 0, 0, 0)
# Rep2VsRep3 = c(0, -1, 1, 0, 0, 0, 0, 0, 0, 0)
# Rep3VsRep4 = c(0, 0, -1, 1, 0, 0, 0, 0, 0, 0)
# Rep4VsRep5 = c(0, 0, 0, -1, 1, 0, 0, 0, 0, 0)
# Rep5VsRep6 = c(0, 0, 0, 0, -1, 1, 0, 0, 0, 0)
# Rep6VsRep7 = c(0, 0, 0, 0, 0, -1, 1, 0, 0, 0)
# Rep7VsRep8 = c(0, 0, 0, 0, 0, 0, -1, 1, 0, 0)
# Rep8VsRep9 = c(0, 0, 0, 0, 0, 0, 0, -1, 1, 0)
# Rep9VsRep10 = c(0, 0, 0, 0, 0, 0, 0, 0, -1, 1)
# 
# contrasts(accData$nRepFac) <- cbind(
#   Rep1VsRep2
#   , Rep2VsRep3
#   , Rep3VsRep4
#   , Rep4VsRep5
#   , Rep5VsRep6
#   , Rep6VsRep7
#   , Rep7VsRep8
#   , Rep8VsRep9
#   , Rep9VsRep10
# )


# varList <- c("subject", "frequency", "nRep", "nRepFac")
# countData <- ddply(accData, varList, summarise, nCorrect = sum(correctness))
# lmH2 <- glmer( nCorrect ~ frequency * nRepFac + ( 1 | subject ), data = countData, family = binomial )

lmH1a <- glmer( correctness ~ frequency * nRep + ( 1 | subject ), data = accData, family = binomial )
lmH1b <- glmer( correctness ~ frequency * nRepFac + ( 1 | subject ), data = accData, family = binomial )

lmH1c <- glmer( correctness ~ frequency * nRep + ( nRep | subject ), data = accData, family = binomial )
lmH1d <- glmer( correctness ~ frequency * nRep + ( nRepFac | subject ), data = accData, family = binomial ) # Warning message: In mer_finalize(ans) : iteration limit reached without convergence (9)
lmH1e <- glmer( correctness ~ frequency * nRepFac + ( nRep | subject ), data = accData, family = binomial )
lmH1f <- glmer( correctness ~ frequency * nRepFac + ( nRepFac | subject ), data = accData, family = binomial )

save(lmH1a
     , lmH1b
     , lmH1c
     , lmH1d
     , lmH1e
     , lmH1f
     , file = "logisticModelsTemp.RData")

lmH1g <- glmer( correctness ~ frequency * nRep + ( 1 | subject/nRep ), data = accData, family = binomial ) # Error: length(f1) == length(f2) is not TRUE
lmH1h <- glmer( correctness ~ frequency * nRep + ( 1 | subject/nRepFac ), data = accData, family = binomial )
lmH1i <- glmer( correctness ~ frequency * nRepFac + ( 1 | subject/nRep ), data = accData, family = binomial ) # Error: length(f1) == length(f2) is not TRUE
lmH1j <- glmer( correctness ~ frequency * nRepFac + ( 1 | subject/nRepFac ), data = accData, family = binomial )

save( lmH1a
     , lmH1b
     , lmH1c
     , lmH1d
     , lmH1e
     , lmH1f
#      , lmH1g
     , lmH1h
#      , lmH1i
     , lmH1j
     , file="logisticModels.RData")

accData$trialInSub <- accData$frequency : accData$trial
lmH1k <- glmer( correctness ~ frequency * nRep + ( 1 | subject/trialInSub ), data = accData, family = binomial )
lmH1l <- glmer( correctness ~ frequency * nRepFac + ( 1 | subject/trialInSub ), data = accData, family = binomial )
lmH1m <- glmer( correctness ~ frequency * nRep + ( nRep | subject/trialInSub ), data = accData, family = binomial )
lmH1n <- glmer( correctness ~ frequency * nRepFac + ( nRep | subject/trialInSub ), data = accData, family = binomial ) # Warning message: In mer_finalize(ans) : false convergence (8)

save(lmH1k
     , lmH1l
     , lmH1m
     , lmH1n
     , file = "logisticModels2Temp.RData")


lmH1o <- glmer( correctness ~ frequency * nRep + ( nRepFac | subject/trialInSub ), data = accData, family = binomial ) # Warning message: In mer_finalize(ans) : false convergence (8)
lmH1p <- glmer( correctness ~ frequency * nRepFac + ( nRepFac | subject/trialInSub ), data = accData, family = binomial ) # Warning message: In mer_finalize(ans) : false convergence (8)
lmH1q <- glmer( correctness ~ frequency * nRep + ( 1 | subject/trialInSub/nRepFac ), data = accData, family = binomial ) # Number of levels of a grouping factor for the random effects is *equal* to n, the number of observations
lmH1r <- glmer( correctness ~ frequency * nRepFac + ( 1 | subject/trialInSub/nRepFac ), data = accData, family = binomial ) # Number of levels of a grouping factor for the random effects is *equal* to n, the number of observations

save(lmH1k
     , lmH1l
     , lmH1m
     , lmH1n
     , lmH1o
     , lmH1p
     , lmH1q
     , lmH1r
     , file = "logisticModels2.RData")


lmH2 <- glmer( correctness ~ frequency * nRep + ( 1 | subject/trial ), data = accData, family = binomial )
lmH3 <- glmer( correctness ~ frequency * nRep + ( 1 | subject/frequency ), data = accData, family = binomial )

######################################################################################################################
######################################################################################################################
lmH0j <- glmer( correctness ~ nRepFac + ( 1 | subject/nRepFac ), data = accData, family = binomial )
anova(lmH0j, lmH1j)

######################################################################################################################
######################################################################################################################

lmH1 <- lmH1j
accData$fitted  <- fitted(lmH1)
accData$logitFitted  <- logit(fitted(lmH1))
accData$res     <- residuals(lmH1, type="normalized")
accData$res2    <- residuals(lmH1)
accData$fitPlusRes  <- accData$fitted + accData$res2


varList <- c("subject", "frequency", "nRep")
temp <- ddply( 
  accData
  , varList
  , summarise
  , logitObs = logit(mean(correctness))
  , logitFit = logit(mean(fitted))
  , res      = mean(res)
)


ppRes <- ggplot( accData, aes(nRep, res, colour=trial) )
ppRes <- ppRes + geom_line(aes(group=trial))
ppRes <- ppRes + facet_grid( subject~frequency, scales="free" )
ppRes <- cleanPlot(ppRes)
ppRes

pp4 <- ggplot( accData )
pp4 <- pp4 + stat_summary(fun.y = mean, geom = "point", shape=16, aes(nRep, correctness, colour=frequency))
pp4 <- pp4 + stat_summary(fun.y = mean, geom = "line", aes(nRep, fitted, colour=frequency))
pp4 <- pp4 + facet_wrap( ~subject )
pp4 <- cleanPlot(pp4)
pp4

pp5 <- ggplot( accData )
pp5 <- pp5 + stat_summary(fun.y = mean, geom = "point", shape=1, aes(nRep, correctness))
pp5 <- pp5 + stat_summary(fun.y = mean, geom = "line", aes(nRep, fitted), colour="red")
pp5 <- pp5 + facet_grid( subject~frequency )
pp5 <- cleanPlot(pp5)
pp5

logitFun <- function(x){ return( logit( mean(x) ) )}
pp6 <- ggplot( accData )
pp6 <- pp6 + stat_summary(fun.y = logitFun, geom = "point", shape=16, aes(nRep, correctness, colour=frequency))
pp6 <- pp6 + stat_summary(fun.y = mean, geom = "line", aes(nRep, logitFitted, colour=frequency))
pp6 <- pp6 + facet_wrap( ~subject )
pp6 <- cleanPlot(pp6)
pp6

pp7 <- ggplot( accData )
pp7 <- pp7 + stat_summary(fun.y = logitFun, geom = "point", shape=1, aes(nRep, correctness))
pp7 <- pp7 + stat_summary(fun.y = mean, geom = "line", aes(nRep, logitFitted), colour="red")
pp7 <- pp7 + facet_grid( subject~frequency )
pp7 <- cleanPlot(pp7)
pp7

accData$fitted2  <- fitted(lmH2)
accData$res2     <- residuals(lmH2, type="normalized")
accData$fitPlusRes2  <- accData$fitted2 + accData$res2


pp4 <- ggplot( accData )
pp4 <- pp4 + stat_summary(fun.y = mean, geom = "line", aes(nRep, correctness))
pp4 <- pp4 + stat_summary(fun.y = mean, geom = "line", aes(nRep, fitted2), colour="red")
pp4 <- pp4 + stat_summary(fun.y = mean, geom = "line", aes(nRep, fitPlusRes2), colour="green")
pp4 <- pp4 + facet_grid( subject~frequency )
pp4 <- cleanPlot(pp4)
pp4


