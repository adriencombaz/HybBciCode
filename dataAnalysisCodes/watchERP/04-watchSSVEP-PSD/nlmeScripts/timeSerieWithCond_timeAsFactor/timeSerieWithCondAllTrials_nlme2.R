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

fm1.lme <- lme(
  psd ~ (stimDuration+I(stimDuration^2))*oddball
  , data = psdData
  , random =  ~(stimDuration+I(stimDuration^2))|subject/trialInSubAndCond
  #   , weights = varPower(form = ~stimDuration)
  , control = list(opt="optim")
  , method = "REML"
)

##############################################################################################
##############################################################################################

# psdDataGp <- groupedData(sqrtPsd ~ stimDuration | subject/oddball, data = psdData)
# psdDataGp <- groupedData(sqrtPsd ~ stimDuration | trial/subject/oddball, data = psdData)
# psdDataGp <- groupedData(sqrtPsd ~ stimDuration | subject, data = psdData)
psdDataGp <- groupedData(sqrtPsd ~ stimDuration | subject/trialInSub, data = psdData)
# plot(psdData)
# plot(psdData, displayLevel="subject")

fm1.lme <- lme(
  sqrtPsd ~ poly(stimDuration)*oddball
  , data = psdDataGp
  , random = ~poly(stimDuration) | subject/oddball/trialInSubAndCond
  #   , weights = varPower(form = ~stimDuration)
  , control = list(opt="optim")
  , method = "REML"
)

fm1.lme <- lme(
  sqrtPsd ~ stimDuration*oddball
  , data = psdDataGp
  , random =  ~stimDuration | subject/trialInSub
  , control = list(opt="optim")
  , method = "REML"
)

fm2.lme <- lme(
  sqrtPsd ~ stimDuration*oddball
  , data = psdDataGp
  , random = ~stimDuration | trial
  , control = list(opt="optim")
  , method = "REML"
)

fm2.lme <- update(fm0.lme, corr = corAR1())

summary(fm1.lme)

# mmf<-model.matrix(formula(fm1.lme), getData(fm1.lme))
# mmr<-model.matrix(fm1.lme$modelStruct$reStruct, getData(fm1.lme))
# coef(fm1.lme)
# fixef(fm1.lme)
# ranef(fm1.lme)
# fm1.lme$apVar

plot(ranef(fm1.lme), level=2)
plot(ranef(fm1.lme), level=1)

psdData$fitted  <- fitted(fm1.lme)
psdData$res     <- residuals(fm1.lme, type="normalized")

pp4 <- ggplot( psdData, aes(stimDuration, sqrtPsd, colour=trialInSubAndCond) )
pp4 <- pp4 + geom_point() #+ geom_line( aes(stimDuration, sqrtPsd, group=trialInSubAndCond) , linetype=2, size=0.3)
pp4 <- pp4 + geom_line( aes(stimDuration, fitted, group=trialInSubAndCond) )
pp4 <- pp4 + facet_wrap( subject~oddball, scale="free_y" )
pp4 <- cleanPlot(pp4)
pp4

pp5 <- ggplot( psdData, aes(stimDuration, res, colour=trialInSubAndCond) )
pp5 <- pp5 + geom_point() + geom_line( aes(stimDuration, res, group=trialInSubAndCond) )
pp5 <- pp5 + facet_wrap( subject~oddball, scale="free_y" )
pp5 <- cleanPlot(pp5)
pp5

pp6 <- ggplot( psdData, aes(as.numeric(oddball:stimDurationFac), res, colour=oddball) )
pp6 <- pp6 + geom_point() + geom_line( aes(as.numeric(oddball:stimDurationFac), res, group=trialInSubAndCond) )
pp6 <- pp6 + facet_wrap( subject~trialInSubAndCond )
pp6 <- cleanPlot(pp6)
pp6

# plot( fm1.lme, fitted(.) ~ stimDuration )
# plot( fm1.lme, fitted(.) ~ stimDuration|subject )
# plot( fm1.lme, fitted(.) ~ stimDuration|subject*oddball )
# 
# plot(augPred(fm1.lme), col.line = 'black')
# plot(augPred(fm1.lme) | subject, col.line = 'black')

plot( fm0.lme, resid(.) ~ stimDuration, abline = 0 )
plot( fm0.lme, resid(., type = "pearson") ~ stimDuration, abline = 0 )
plot( fm0.lme, resid(., type = "normalized") ~ stimDuration, abline = 0 )
plot( fm1.lme, resid(.) ~ stimDuration, abline = 0 )
plot( fm1.lme, resid(., type = "pearson") ~ stimDuration, abline = 0 )
plot( fm1.lme, resid(., type = "normalized") ~ stimDuration, abline = 0 )
plot( fm1.lme, resid(.) ~ stimDuration|oddball, abline = 0 )
plot( fm1.lme, resid(.) ~ stimDuration|subject, abline = 0 )
plot( fm1.lme, resid(.) ~ stimDuration|subject*oddball, abline = 0 )
plot( fm1.lme, resid(., type = "normalized") ~ stimDuration|subject*oddball, abline = 0 )

plot( fm0.lme, resid(., type = "normalized") ~ fitted(.), abline = 0 )
plot( fm1.lme, resid(., type = "normalized") ~ fitted(.), abline = 0 )
plot( fm2.lme, resid(., type = "normalized") ~ fitted(.), abline = 0 )
plot( fm1.lme, resid(., type = "normalized") ~ fitted(.)|oddball, abline = 0 )
plot( fm1.lme, resid(., type = "normalized") ~ fitted(.)|subject, abline = 0 )
plot( fm1.lme, resid(., type = "normalized") ~ fitted(.)|stimDuration, abline = 0 )
plot( fm2.lme, resid(., type = "normalized") ~ fitted(.)|stimDuration, abline = 0 )
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
plot(ACF(fm2.lme, resType="n"), alpha = 0.01)
plot(Variogram( fm1.lme, form = ~ stimDuration ))
plot(Variogram( fm1.lme, form = ~ stimDuration, resType="n", robust=T ))


fm2.lme <- update(fm1.lme, weights = varFixed(~stimDuration|trialInSub))
plot(ACF(fm2.lme, maxLag = 180, resType="p"), alpha = 0.01)
plot(augPred(fm2.lme), col.line = 'black')
plot( fm2.lme, resid(.) ~ stimDuration|subject, abline = 0 )
plot( fm2.lme, resid(.) ~ stimDuration, abline = 0 )


fm3a.lme <- update(fm1.lme, corr = corARMA(p=1)) 
fm3.lme <- update(fm1.lme, corr = corARMA(form=~stimDuration, p=1)) 
fm3.lme <- update(fm1.lme, corr = corARMA(form=~stimDuration, p=2)) 
fm3.lme <- update(fm1.lme, corr = corARMA(form=~stimDuration, p=3)) 
fm3.lme <- update(fm1.lme, corr = corARMA(form=~stimDuration, q=1)) 
fm3.lme <- update(fm1.lme, corr = corARMA(form=~stimDuration, q=2)) 
fm3.lme <- update(fm1.lme, corr = corARMA(form=~stimDuration, q=3)) 
fm3.lme <- update(fm1.lme, corr = corARMA(form=~stimDuration, q=4)) 
fm3.lme <- update(fm1.lme, corr = corARMA(form=~stimDuration, q=5)) 
fm3.lme <- update(fm1.lme, corr = corARMA(form=~stimDuration, q=6)) 
fm3.lme <- update(fm1.lme, corr = corARMA(form=~stimDuration, p=1, q=1)) 
fm3.lme <- update(fm1.lme, corr = corCAR1(form=~stimDuration)) 
fm3.lme <- update(fm1.lme, corr = corCAR1(value=0.4, form=~stimDuration)) 
fm3.lme <- update(fm1.lme, corr = corCAR1(value=0.6, form=~stimDuration)) 
fm3.lme <- update(fm1.lme, corr = corCAR1(value=0.8, form=~stimDuration)) 
fm3.lme <- update(fm1.lme, corr = corExp(form = ~ stimDuration)) 
fm4.lme <- update(fm1.lme, corr = corExp(form = ~ stimDuration, nugget=T)) 
fm3.lme <- update(fm1.lme, corr = corRatio(form = ~ stimDuration)) 
fm3.lme <- update(fm1.lme, corr = corLin(form = ~ stimDuration)) 
fm3.lme <- update(fm1.lme, corr = corSpher(form = ~ stimDuration)) 
fm3.lme <- update(fm1.lme, corr = corGaus(form = ~ stimDuration)) 
plot(ACF(fm1.lme, maxLag = 10, resType="n"), alpha = 0.05)
plot(ACF(fm3.lme, maxLag = 10, resType="n"), alpha = 0.05)
plot(augPred(fm3.lme), col.line = 'black')
plot( fm3.lme, resid(.) ~ stimDuration|subject, abline = 0 )
plot( fm3.lme, resid(.) ~ stimDuration, abline = 0 )
plot( fm3.lme, resid(.) ~ fitted(.)|subject, abline = 0 )
plot( fm3.lme, resid(.) ~ fitted(.), abline = 0 )
plot(Variogram( fm3.lme, form = ~ stimDuration ))
plot(Variogram( fm3.lme, form = ~ stimDuration, resType="n", robust=T ))
