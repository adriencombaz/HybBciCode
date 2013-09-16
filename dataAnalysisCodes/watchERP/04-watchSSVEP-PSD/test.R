setwd("d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciCode/dataAnalysisCodes/watchERP/04-watchSSVEP-PSD/")
rm(list = ls())
library(ggplot2)
library(reshape2)
library(grid)
library(plyr)
library(nlme)
library(lattice)
library(mgcv) # functions to extract covariance matrix from lme: extract.lme.cov

source("d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciCode/dataAnalysisCodes/deps/cleanPlot.R")
source("d:/KULeuven/PhD/rLibrary/plotFactorMeans_InteractionGraphs.R")
source("d:/KULeuven/PhD/rLibrary/plotInteractionGraphs_level2.R")

fileDir <- "d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciProcessedData/watch-ERP/04-watchSSVEP-PSD"
filename <- "psdDataset_Oz_Ha1"

fullfilename <- file.path( fileDir, paste0(filename, ".csv") )

psdData <- read.csv(fullfilename, header = TRUE)

psdData$frequency <- as.factor(psdData$frequency)
psdData$oddball <- as.factor(psdData$oddball)
psdData$fileNb <- as.factor(psdData$fileNb)
psdData$trial <- as.factor(psdData$trial)
psdData$sqrtPsd <- sqrt(psdData$psd)
psdData$log10Psd <- log10(psdData$psd)
psdData$lnPsd <- log(psdData$psd)
psdData$stimDurationFac <- as.factor(psdData$stimDuration)
psdData$trial2 <- psdData$oddball:psdData$trial
psdData$trial3 <- psdData$oddball:psdData$subject:psdData$trial

psdData$oddball <- revalue( psdData$oddball, c("0"="odd0", "1"="odd1" ) )


psdData <- psdData[psdData$frequency=="15",]
psdData$frequency <- droplevels(psdData$frequency)
psdData <- psdData[psdData$stimDuration!=1,]
# psdData5 <- psdData[psdData$stimDuration==5,]
# psdData10 <- psdData[psdData$stimDuration==10,]
# psdData <- rbind(psdData1, psdData5, psdData10)

varList <- c( "subject", "stimDuration", "stimDurationFac", "oddball", "trial", "sqrtPsd", "psd", "lnPsd", "log10Psd", "trial2", "trial3" )
psdData <- psdData[ , names(psdData) %in% varList]
psdData <- psdData[with(psdData, order(subject, stimDuration, oddball, trial)), ]

varList <- c( "subject", "stimDuration", "stimDurationFac", "oddball" )
psdDataMeanTrial <- ddply( psdData, varList, summarise, psd = mean(psd) )
psdDataMeanTrial$sqrtPsd <- sqrt(psdDataMeanTrial$psd)
psdDataMeanTrial$trialInSub <- psdDataMeanTrial$subject : psdDataMeanTrial$oddball

psdDataSingleTrial <- psdData[psdData$trial=="tr06",]
psdDataSingleTrial$trial <- droplevels(psdDataSingleTrial$trial)

################################################################################################################
################################################################################################################
psdData$trialInSub <- psdData$trial : psdData$oddball
# pp2 <- ggplot( psdData, aes(stimDuration, sqrtPsd, colour=oddball) )
pp2 <- ggplot( psdData, aes(stimDuration, psd, colour=oddball) )
pp2 <- pp2 + geom_point() + geom_line( aes(stimDuration, psd, group=trialInSub) )
# pp2 <- pp2 + facet_wrap( ~subject )
pp2 <- pp2 + facet_wrap( ~subject, scale="free_y" )
pp2 <- cleanPlot(pp2)
pp2

pp3 <- ggplot( psdData, aes(stimDuration, sqrtPsd, colour=oddball) )
pp3 <- pp3 + geom_point() + geom_line( aes(stimDuration, sqrtPsd, group=trialInSub) )
pp3 <- pp3 + facet_wrap( ~subject )
pp3 <- cleanPlot(pp3)
pp3

pp4 <- ggplot( psdDataMeanTrial, aes(stimDuration, psd, colour=oddball) )
pp4 <- pp4 + geom_point() + geom_line( aes(stimDuration, psd, group=oddball) )
pp4 <- pp4 + facet_wrap( ~subject, scale="free_y" )
pp4 <- cleanPlot(pp4)
pp4

################################################################################################################
################################################################################################################
psdDataGpMean <- groupedData(psd ~ stimDuration | trialInSub, data = psdDataMeanTrial)
plot(psdDataGpMean)

fm1.lis <- nlsList( psd ~ SSlogis(stimDuration, Asym, xmid, scal), data = psdDataGpMean )
fm1.nlme <- nlme( fm1.lis )
plot( fm1.nlme, fitted(.) ~ stimDuration|subject )
plot(augPred(fm1.nlme), col.line = 'black')
plot( fm1.nlme, resid(.) ~ stimDuration, abline = 0 )
plot( fm1.nlme, resid(.) ~ fitted(.), abline = 0 )

fm1a.nlme <- nlme(
  
  )
################################################################################################################
################################################################################################################
psdDataGp <- groupedData(psd ~ stimDuration | trial3, data = psdData)
plot(psdDataGp)

fm1.lis <- nlsList( psd ~ SSlogis(stimDuration, Asym, xmid, scal), data = psdDataGp )
fm1.nlme <- nlme( fm1.lis )
plot( fm1.nlme, fitted(.) ~ stimDuration|subject )
plot(augPred(fm1.nlme), col.line = 'black')
plot( fm1.nlme, resid(.) ~ stimDuration, abline = 0 )
plot( fm1.nlme, resid(.) ~ fitted(.), abline = 0 )


fm1.lme <- lme(
  psd~stimDurationFac*oddball
  , data=psdDataGp
  , random = ~1|subject/oddball  # ~(stimDuration-1)|subject/trial2
  , control = list(opt="optim")
)

mmf<-model.matrix(formula(fm1.lme), getData(fm1.lme))
mmr<-model.matrix(fm1.lme$modelStruct$reStruct, getData(fm1.lme))

plot( fm1.lme, fitted(.) ~ stimDuration|subject )
plot( fm1.lme, fitted(.) ~ stimDuration|subject*oddball )
plot(augPred(fm1.lme), col.line = 'black')
plot(augPred(fm1.lme, primary="stimDuration"), col.line = 'black')
plot(augPred(fm1.lme) | subject)
plot( fm1.lme, resid(.) ~ stimDuration|oddball, abline = 0 )
plot( fm1.lme, resid(.) ~ stimDuration|subject, abline = 0 )
plot( fm1.lme, resid(.) ~ stimDuration|subject*oddball, abline = 0 )
plot( fm1.lme, resid(.) ~ stimDuration, abline = 0 )
plot( fm1.lme, resid(.) ~ fitted(.), abline = 0 )
plot( fm1.lme, resid(.) ~ fitted(.)|oddball, abline = 0 )
plot( fm1.lme, resid(.) ~ fitted(.)|subject, abline = 0 )
plot( fm1.lme, resid(.) ~ fitted(.)|stimDuration, abline = 0 )
plot( fm1.lme, resid(.) ~ fitted(.)|stimDuration*oddball, abline = 0 )
plot( fm1.lme, resid(.) ~ fitted(.)|subject*oddball, abline = 0 )
plot( fm1.lme, resid(.) ~ fitted(.)|stimDuration*subject, abline = 0 )
plot( fm1.lme, resid(.) ~ fitted(.)|stimDuration*subject*oddball, abline = 0 )
plot(ACF(fm1.lme, maxLag = 10, resType="n"), alpha = 0.01)
plot(Variogram( fm1.lme, form = ~ stimDuration ))
plot(Variogram( fm1.lme, form = ~ stimDuration, resType="n", robust=T ))
################################################################################################################
################################################################################################################
