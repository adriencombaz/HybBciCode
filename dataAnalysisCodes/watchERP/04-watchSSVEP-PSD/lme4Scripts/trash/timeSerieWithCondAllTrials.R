setwd("d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciCode/dataAnalysisCodes/watchERP/04-watchSSVEP-PSD/")
rm(list = ls())
library(ggplot2)
library(reshape2)
library(grid)
library(plyr)
library(lme4)
library(lattice)
library(mgcv) # functions to extract covariance matrix from lme: extract.lme.cov

source("d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciCode/dataAnalysisCodes/deps/cleanPlot.R")
source("d:/KULeuven/PhD/rLibrary/plotFactorMeans_InteractionGraphs.R")
source("d:/KULeuven/PhD/rLibrary/plotInteractionGraphs_level2.R")

fileDir <- "d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciProcessedData/watchERP/04-watchSSVEP-PSD"
filename <- "psdDataset_Oz_Ha1"

fullfilename <- file.path( fileDir, paste0(filename, ".csv") )

psdData <- read.csv(fullfilename, header = TRUE)

psdData$frequency         <- as.factor(psdData$frequency)
psdData$oddball           <- as.factor(psdData$oddball)
psdData$fileNb            <- as.factor(psdData$fileNb)
psdData$stimDurationFac   <- as.factor(psdData$stimDuration)
psdData$trialInSubAndCond <- as.factor(psdData$trial)
psdData$trialInSub        <- psdData$oddball:psdData$trial
psdData$trial             <- psdData$oddball:psdData$subject:psdData$trial
psdData$sqrtPsd           <- sqrt(psdData$psd)
psdData$log10Psd          <- log10(psdData$psd)
psdData$lnPsd             <- log(psdData$psd)
psdData$stimDuration      <- as.numeric(psdData$stimDuration)
psdData$stimDurationFac   <- as.factor(psdData$stimDuration)
psdData$condition <- psdData$oddball

psdData$oddball <- revalue( psdData$oddball, c("0"="odd0", "1"="odd1" ) )

psdData <- psdData[psdData$frequency=="15",]
psdData$frequency <- droplevels(psdData$frequency)
# psdData <- psdData[psdData$stimDuration!=1,]

##############################################################################################
##############################################################################################
pp2 <- ggplot( psdData, aes(stimDuration, psd, colour=oddball) )
pp2 <- pp2 + geom_point() + geom_line( aes(stimDuration, psd, group=trialInSub) )
pp2 <- pp2 + facet_wrap( ~subject, scale="free_y" )
pp2 <- cleanPlot(pp2)
pp2

pp3 <- ggplot( psdData, aes(stimDuration, sqrtPsd, colour=condition) )
pp3 <- pp3 + geom_point() + geom_line( aes(stimDuration, sqrtPsd, group=trialInSub) )
pp3 <- pp3 + facet_wrap( ~subject )
pp3 <- pp3 + xlab("time") + ylab("value")
pp3 <- cleanPlot(pp3)
pp3

##############################################################################################
##############################################################################################


fm1.lme <- lmer( sqrtPsd ~ stimDuration*oddball + (stimDuration|subject/oddball) + (1|stimDurationFac/subject), psdData )
fm1.lme <- lmer( sqrtPsd ~ stimDuration*oddball + (stimDuration|subject/trialInSubAndCond), psdData )
fm2.lme <- lmer( sqrtPsd ~ stimDuration*oddball + (stimDuration|subject/trialInSub), psdData )

plot(ranef(fm1.lme), level=2)
plot(ranef(fm1.lme), level=1)

psdData$fitted  <- fitted(fm1.lme)
psdData$res     <- residuals(fm1.lme, type="normalized")

pp4 <- ggplot( psdData, aes(stimDuration, sqrtPsd, colour=oddball) )
pp4 <- pp4 + geom_point(size=1) + geom_line( aes(stimDuration, sqrtPsd, group=trialInSub) , linetype=2, size=0.3)
pp4 <- pp4 + geom_point() + geom_line( aes(stimDuration, fitted, group=oddball), size=2 )
pp4 <- pp4 + facet_wrap( ~subject, scale="free_y" )
# pp4 <- pp4 + facet_wrap( ~subject )
pp4 <- cleanPlot(pp4)
pp4

pp5 <- ggplot( psdData, aes(stimDuration, res, colour=oddball) )
pp5 <- pp5 + geom_point() + geom_line( aes(stimDuration, res, group=trialInSub) )
pp5 <- pp5 + facet_wrap( ~subject, scale="free_y"  )
pp5 <- cleanPlot(pp5)
pp5


plot( fm1.lme, fitted(.) ~ stimDuration )
plot( fm1.lme, fitted(.) ~ stimDuration|subject )
plot( fm1.lme, fitted(.) ~ stimDuration|subject*oddball )

plot(augPred(fm1.lme), col.line = 'black')
plot(augPred(fm1.lme) | subject, col.line = 'black')

plot( fm0.lme, resid(., type="n") ~ stimDuration, abline = 0 )
plot( fm0.lme, resid(., type = "pearson") ~ stimDuration, abline = 0 )
plot( fm0.lme, resid(., type = "normalized") ~ stimDuration, abline = 0 )
plot( fm1.lme, resid(.) ~ stimDuration, abline = 0 )
plot( fm1.lme, resid(., type = "pearson") ~ stimDuration, abline = 0 )
plot( fm1.lme, resid(., type = "normalized") ~ stimDuration, abline = 0 )
plot( resid(fm1.lme, type="pearson") ~ stimDuration, abline = 0 )
plot( fm1.lme, resid(.) ~ stimDuration|oddball, abline = 0 )
plot( fm1.lme, resid(.) ~ stimDuration|subject, abline = 0 )
plot( fm1.lme, resid(.) ~ stimDuration|subject*oddball, abline = 0 )
plot( fm1.lme, resid(., type = "normalized") ~ stimDuration|subject*oddball, abline = 0 )

plot( fm1.lme, resid(., type = "normalized") ~ fitted(.), abline = 0 )
plot( fm1.lme, resid(., type = "normalized") ~ fitted(.)|oddball, abline = 0 )
plot( fm1.lme, resid(., type = "normalized") ~ fitted(.)|subject, abline = 0 )
plot( fm1.lme, resid(., type = "normalized") ~ fitted(.)|stimDuration, abline = 0 )
plot( fm1.lme, resid(., type = "normalized") ~ fitted(.)|stimDuration*oddball, abline = 0 )
plot( fm1.lme, resid(., type = "normalized") ~ fitted(.)|subject*oddball, abline = 0 )
plot( fm1.lme, resid(.) ~ fitted(.)|stimDuration*subject, abline = 0 )
plot( fm1.lme, resid(.) ~ fitted(.)|stimDuration*subject*oddball, abline = 0 )

plot(ACF(fm0.lme, maxLag = 180, resType="p"), alpha = 0.01)
plot(ACF(fm1.lme, maxLag = 180, resType="p"), alpha = 0.01)
plot(ACF(fm1.lme, maxLag = 100, resType="n"), alpha = 0.01)
plot(ACF(fm1.lme, maxLag = 100, resType="r"), alpha = 0.01)
plot(ACF(fm0.lme, resType="n"), alpha = 0.01)
plot(ACF(fm1.lme, resType="n"), alpha = 0.01)
plot(Variogram( fm1.lme, form = ~ stimDuration ))
plot(Variogram( fm1.lme, form = ~ stimDuration, resType="n", robust=T ))


