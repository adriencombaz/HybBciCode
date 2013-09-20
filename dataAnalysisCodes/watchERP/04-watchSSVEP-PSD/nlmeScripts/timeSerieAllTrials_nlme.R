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
# psdData$trialInSubAndCond <- as.factor(psdData$trial)
# psdData$trialInSub        <- psdData$oddball:psdData$trial
# psdData$trial             <- psdData$oddball:psdData$subject:psdData$trial
psdData$sqrtPsd           <- sqrt(psdData$psd)
psdData$log10Psd          <- log10(psdData$psd)
psdData$lnPsd             <- log(psdData$psd)
psdData$stimDuration      <- as.numeric(psdData$stimDuration)
psdData$stimDurationFac   <- as.factor(psdData$stimDuration)
psdData$condition <- psdData$oddball

psdData$oddball <- revalue( psdData$oddball, c("0"="odd0", "1"="odd1" ) )

psdData <- psdData[psdData$frequency=="15",]
psdData$frequency <- droplevels(psdData$frequency)
psdData <- psdData[psdData$oddball=="odd1",]
psdData$oddball <- droplevels(psdData$oddball)
# psdData <- psdData[psdData$stimDuration!=1,]

psdData <- psdData[with(psdData, order(subject, trial, stimDuration)), ]

##############################################################################################
##############################################################################################
pp2 <- ggplot( psdData, aes(stimDuration, psd) )
pp2 <- pp2 + geom_point() + geom_line( aes(stimDuration, psd, group=trial) )
pp2 <- pp2 + facet_wrap( ~subject, scale="free_y" )
pp2 <- cleanPlot(pp2)
pp2

pp3 <- ggplot( psdData, aes(stimDuration, sqrtPsd) )
pp3 <- pp3 + geom_point() + geom_line( aes(stimDuration, sqrtPsd, group=trial) )
pp3 <- pp3 + facet_wrap( ~subject )
pp3 <- pp3 + xlab("time") + ylab("value")
pp3 <- cleanPlot(pp3)
pp3

##############################################################################################
##############################################################################################

# psdDataGp <- groupedData(sqrtPsd ~ stimDuration | subject/oddball, data = psdData)
psdDataGp <- groupedData(sqrtPsd ~ stimDuration | subject/trial, data = psdData)
# psdDataGp <- groupedData(sqrtPsd ~ stimDuration | subject, data = psdData)
# psdDataGp <- groupedData(sqrtPsd ~ stimDuration | trialInSub/subject, data = psdData)
# plot(psdData)
# plot(psdData, displayLevel="subject")

fm0.lme <- lme(
  sqrtPsd ~ stimDuration
  , data = psdDataGp
  , random = ~stimDuration|subject
#   , corr = corCAR1(form=~stimDuration|subject/trial)
  #   , weights = varPower(form = ~stimDuration)
  , control = list(opt="optim")
  , method = "REML"
)

fm1.lme <- lme(
  sqrtPsd ~ stimDuration
  , data = psdDataGp
  , random = ~stimDuration|subject
  , corr = corCAR1(form=~stimDuration|subject/trial)
  #   , weights = varPower(form = ~stimDuration)
  , control = list(opt="optim")
  , method = "REML"
)

fm2.lme <- lme(
  sqrtPsd ~ stimDuration
  , data = psdDataGp
  , random = ~stimDuration|subject
  , corr = corAR1(form=~stimDuration|subject/trial)
  #   , weights = varPower(form = ~stimDuration)
  , control = list(opt="optim")
  , method = "REML"
)

summary(fm0.lme)
summary(fm1.lme)
intervals(fm0.lme)
intervals(fm1.lme)
anova(fm0.lme, fm1.lme)
# mmf<-model.matrix(formula(fm1.lme), getData(fm1.lme))
# mmr<-model.matrix(fm1.lme$modelStruct$reStruct, getData(fm1.lme))
# coef(fm1.lme)
# res <- resid(fm1.lme, type="n", asList=TRUE)
# fixef(fm1.lme)
plot(ranef(fm0.lme))
plot(ranef(fm1.lme))

plot( fm1.lme, fitted(.) ~ stimDuration )
plot( fm1.lme, fitted(.) ~ stimDuration|subject )
plot( fm1.lme, fitted(.) ~ stimDuration|subject*oddball )

plot(augPred(fm0.lme), col.line = 'black')
plot(augPred(fm1.lme) | subject, col.line = 'black')

plot( fm0.lme, resid(.) ~ stimDuration, abline = 0 )
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

plot(ACF(fm0.lme, maxLag = 180, resType="n"), alpha = 0.01)
plot(ACF(fm1.lme, maxLag = 180, resType="n"), alpha = 0.01)
plot(ACF(fm1.lme, maxLag = 1000, resType="n"), alpha = 0.01)
plot(ACF(fm1.lme, maxLag = 1000, resType="r"), alpha = 0.01)
plot(ACF(fm0.lme, resType="n"), alpha = 0.01)
plot(ACF(fm1.lme, resType="n"), alpha = 0.01)
plot(Variogram( fm1.lme, form = ~ stimDuration ))
plot(Variogram( fm1.lme, form = ~ stimDuration, resType="n", robust=T ))


fm2.lme <- update(fm1.lme, weights = varFixed(~stimDuration|trialInSub))
plot(ACF(fm2.lme, maxLag = 180, resType="p"), alpha = 0.01)
plot(augPred(fm2.lme), col.line = 'black')
plot( fm2.lme, resid(.) ~ stimDuration|subject, abline = 0 )
plot( fm2.lme, resid(.) ~ stimDuration, abline = 0 )


fm3.lme <- update(fm1.lme, corr = corARMA(form=~stimDuration, p=1)) 
fm3.lme <- update(fm1.lme, corr = corARMA(form=~stimDuration, p=2)) 
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
plot(ACF(fm3.lme, maxLag = 10, resType="n"), alpha = 0.05)
plot(augPred(fm3.lme), col.line = 'black')
plot( fm3.lme, resid(.) ~ stimDuration|subject, abline = 0 )
plot( fm3.lme, resid(.) ~ stimDuration, abline = 0 )
plot( fm3.lme, resid(.) ~ fitted(.)|subject, abline = 0 )
plot( fm3.lme, resid(.) ~ fitted(.), abline = 0 )
plot(Variogram( fm3.lme, form = ~ stimDuration ))
plot(Variogram( fm3.lme, form = ~ stimDuration, resType="n", robust=T ))


fm0.gls <- gls(
  sqrtPsd ~ stimDuration*oddball
  , data = psdDataGp
  , corr = corCAR1(form=~stimDuration|subject/oddball/trialInSubAndCond)
  #   , weights = varPower(form = ~stimDuration)
  #   , control = list(opt="optim")
  #   , method = "REML"
)

summary(fm0.gls)
intervals(fm0.gls)
mmf<-model.matrix(formula(fm0.gls), getData(fm0.gls))

plot( fm0.gls, fitted(.) ~ stimDuration )
plot( fm0.gls, fitted(.) ~ stimDuration|subject )
plot( fm0.gls, fitted(.) ~ stimDuration|subject*oddball )

plot( fm0.gls, resid(.) ~ stimDuration, abline = 0 )
plot( fm0.gls, resid(., type = "pearson") ~ stimDuration, abline = 0 )
plot( fm0.gls, resid(., type = "normalized") ~ stimDuration, abline = 0 )

plot( fm0.gls, resid(.) ~ stimDuration|oddball, abline = 0 )
plot( fm0.gls, resid(., type = "pearson") ~ stimDuration|oddball, abline = 0 )
plot( fm0.gls, resid(., type = "normalized") ~ stimDuration|oddball, abline = 0 )

plot( fm0.gls, resid(.) ~ stimDuration|subject, abline = 0 )
plot( fm0.gls, resid(., type = "pearson") ~ stimDuration|subject, abline = 0 )
plot( fm0.gls, resid(., type = "normalized") ~ stimDuration|subject, abline = 0 )

plot( fm0.gls, resid(.) ~ stimDuration|subject*oddball, abline = 0 )
plot( fm0.gls, resid(., type = "pearson") ~ stimDuration|subject*oddball, abline = 0 )
plot( fm0.gls, resid(., type = "normalized") ~ stimDuration|subject*oddball, abline = 0 )

plot( fm0.gls, resid(.) ~ fitted(.), abline = 0 )
plot( fm0.gls, resid(., type = "pearson") ~ fitted(.), abline = 0 )
plot( fm0.gls, resid(., type = "normalized") ~ fitted(.), abline = 0 )

plot( fm0.gls, resid(.) ~ fitted(.)|oddball, abline = 0 )
plot( fm0.gls, resid(., type = "pearson") ~ fitted(.)|oddball, abline = 0 )
plot( fm0.gls, resid(., type = "normalized") ~ fitted(.)|oddball, abline = 0 )

plot( fm1.lme, resid(., type = "normalized") ~ fitted(.)|subject, abline = 0 )
plot( fm1.lme, resid(., type = "normalized") ~ fitted(.)|stimDuration, abline = 0 )
plot( fm1.lme, resid(., type = "normalized") ~ fitted(.)|stimDuration*oddball, abline = 0 )
plot( fm1.lme, resid(., type = "normalized") ~ fitted(.)|subject*oddball, abline = 0 )
plot( fm1.lme, resid(.) ~ fitted(.)|stimDuration*subject, abline = 0 )
plot( fm1.lme, resid(.) ~ fitted(.)|stimDuration*subject*oddball, abline = 0 )

plot(ACF(fm0.gls, resType="p"), alpha = 0.01)
plot(ACF(fm0.gls, resType="n"), alpha = 0.01)
plot(ACF(fm0.gls, resType="n", form = ~1|subject/oddball/trialPerSubAndCond), alpha = 0.01)
plot(ACF(fm0.gls, maxLag = 2500, resType="n"), alpha = 0.01)
plot(ACF(fm1.lme, maxLag = 100, resType="r"), alpha = 0.01)
