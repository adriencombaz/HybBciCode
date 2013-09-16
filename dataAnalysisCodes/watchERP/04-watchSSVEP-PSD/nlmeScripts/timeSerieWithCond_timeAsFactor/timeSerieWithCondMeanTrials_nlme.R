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

varList <- c( "subject", "stimDuration", "stimDurationFac", "oddball" )
psdDataMeanTrial <- ddply( psdData, varList, summarise, psd = mean(psd) )
psdDataMeanTrial$sqrtPsd <- sqrt(psdDataMeanTrial$psd)


##############################################################################################
##############################################################################################
pp2 <- ggplot( psdDataMeanTrial, aes(stimDuration, sqrtPsd, colour=oddball) )
pp2 <- pp2 + geom_point() + geom_line( aes(stimDuration, sqrtPsd, group=oddball) )
pp2 <- pp2 + facet_wrap( ~subject, scale="free_y" )
pp2 <- cleanPlot(pp2)
pp2

pp3 <- ggplot( psdDataMeanTrial, aes(stimDuration, psd, colour=oddball) )
pp3 <- pp3 + geom_point() + geom_line( aes(stimDuration, psd, group=oddball) )
pp3 <- pp3 + facet_wrap( ~subject, scale="free_y" )
pp3 <- cleanPlot(pp3)
pp3

##############################################################################################
##############################################################################################
psdDataGp <- groupedData(sqrtPsd ~ stimDuration | subject/oddball, data = psdDataMeanTrial)


fm1.lme <- lme(
  psd ~ (stimDuration+I(stimDuration^2))*oddball
  , data = psdDataGp
  , random = ~(stimDuration+I(stimDuration^2))|subject
  #   , random = stimDuration | trialInSub/subject
  #   , weights = varPower(form = ~stimDuration)
  , control = list(opt="optim")
  , method = "REML"
)

nSub<-length(unique(psdDataMeanTrial$subject))
nOdd<-length(unique(psdDataMeanTrial$oddball))
nTime<-length(unique(psdDataMeanTrial$stimDuration))
mmr<-model.matrix(fm1.lme$modelStruct$reStruct, getData(fm1.lme))
mmr<-mmr[1:(nOdd*nTime),]
fixFitted <- model.matrix(formula(fm1.lme), getData(fm1.lme)) %*% fixef(fm1.lme)
ranFitted <- vector(mode="numeric", length=length(fixFitted))
ind <- 1
for (iS in 1:length(unique(psdDataMeanTrial$subject))){
  ranFitted[((iS-1)*nOdd*nTime+1) : (iS*nOdd*nTime)] = mmr %*% as.numeric(ranef(fm1.lme)[iS,])
}
fitted <- fixFitted+ranFitted

compFitted <- data.frame(fixFitted, fitted, fm1.lme$fitted)

resHome <- psdDataMeanTrial$psd-fitted
sub <- resHome - residuals(fm1.lme)

psdDataMeanTrial$fitted <- fitted
psdDataMeanTrial$res <- resHome

pp4 <- ggplot( psdDataMeanTrial, aes(stimDuration, psd, colour=oddball) )
pp4 <- pp4 + geom_point() + geom_line( aes(stimDuration, fitted, group=oddball) )
pp4 <- pp4 + facet_wrap( ~subject )
pp4 <- cleanPlot(pp4)
pp4

pp5 <- ggplot( psdDataMeanTrial, aes(stimDuration, resHome, colour=oddball) )
pp5 <- pp5 + geom_point() #+ geom_line( aes(stimDuration, fitted, group=oddball) )
pp5 <- pp5 + facet_wrap( ~subject )
pp5 <- cleanPlot(pp5)
pp5


##############################################################################################
##############################################################################################
psdDataGp <- groupedData(sqrtPsd ~ stimDuration | subject/oddball, data = psdDataMeanTrial)


fm1.lme <- lme(
  psd ~ (stimDuration+I(stimDuration^2))*oddball
  , data = psdDataGp
  , random = ~(stimDuration+I(stimDuration^2))|subject/oddball
  #   , random = stimDuration | trialInSub/subject
  #   , weights = varPower(form = ~stimDuration)
  , control = list(opt="optim")
  , method = "REML"
)

nSub<-length(unique(psdDataMeanTrial$subject))
nOdd<-length(unique(psdDataMeanTrial$oddball))
nTime<-length(unique(psdDataMeanTrial$stimDuration))
mmr<-model.matrix(fm1.lme$modelStruct$reStruct, getData(fm1.lme))
mmr<-mmr[1:(nOdd*nTime),]
fixFitted <- model.matrix(formula(fm1.lme), getData(fm1.lme)) %*% fixef(fm1.lme)
ranFitted1 <- vector(mode="numeric", length=length(fixFitted))
ranFitted2 <- vector(mode="numeric", length=length(fixFitted))
ra<-ranef(fm1.lme)
ind <- 1
for ( iS in 1:nSub ){
  ranFitted1[((iS-1)*nOdd*nTime+1) : (iS*nOdd*nTime)] = mmr[,1:3] %*% as.numeric(ra$subject[iS,])
  for (iT in 1:nTime){ 
    for (iO in 1:nOdd){
      ranFitted2[(iS-1)*nOdd*nTime+(iT-1)*nOdd+iO] = 
        mmr[(iT-1)*nOdd+iO,4:6] %*% as.numeric(ra$oddball[(iS-1)*nOdd+iO,])
    }
  }
}
subFitted <- fixFitted+ranFitted1
fitted <- fixFitted+ranFitted1+ranFitted2

compFitted <- data.frame(fixFitted, ranFitted1, subFitted, ranFitted2, fitted, fm1.lme$fitted)

resHome <- psdDataMeanTrial$psd-fitted
sub <- resHome - residuals(fm1.lme)

psdDataMeanTrial$fitted <- fitted
psdDataMeanTrial$res <- resHome

pp4 <- ggplot( psdDataMeanTrial, aes(stimDuration, psd, colour=oddball) )
pp4 <- pp4 + geom_point() + geom_line( aes(stimDuration, fitted, group=oddball) )
pp4 <- pp4 + facet_wrap( ~subject )
pp4 <- cleanPlot(pp4)
pp4

pp5 <- ggplot( psdDataMeanTrial, aes(stimDuration, resHome, colour=oddball) )
pp5 <- pp5 + geom_point() #+ geom_line( aes(stimDuration, fitted, group=oddball) )
pp5 <- pp5 + facet_wrap( ~subject )
pp5 <- cleanPlot(pp5)
pp5




##############################################################################################
##############################################################################################


fm2.lme <- update(fm1.lme, corr = corCAR1())

anova(fm0.lme, fm1.lme)
anova(fm2.lme, fm1.lme)
# fm1.lme <- update(fm0.lme, corr = corAR1(form=~1|stimDurationFac/subject/oddball))

summary(fm1.lme)
# mmf<-model.matrix(formula(fm1.lme), getData(fm1.lme))
# mmr<-model.matrix(fm1.lme$modelStruct$reStruct, getData(fm1.lme))
# coef(fm1.lme)
# res <- resid(fm1.lme, type="n", asList=TRUE)
# fixef(fm1.lme)
plot(ranef(fm1.lme), level=2)
plot(ranef(fm1.lme), level=1)

plot( fm1.lme, fitted(.) ~ stimDuration )
plot( fm1.lme, fitted(.) ~ stimDuration|subject )
plot( fm1.lme, fitted(.) ~ stimDuration|subject*oddball )

plot(augPred(fm0.lme), col.line = 'black')
plot(augPred(fm1.lme), col.line = 'black')
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

plot( fm0.lme, resid(., type = "normalized") ~ fitted(.), abline = 0 )
plot( fm1.lme, resid(., type = "normalized") ~ fitted(.), abline = 0 )
plot( fm1.lme, resid(., type = "normalized") ~ fitted(.)|oddball, abline = 0 )
plot( fm1.lme, resid(., type = "normalized") ~ fitted(.)|subject, abline = 0 )
plot( fm1.lme, resid(., type = "normalized") ~ fitted(.)|stimDuration, abline = 0 )
plot( fm1.lme, resid(., type = "normalized") ~ fitted(.)|stimDuration*oddball, abline = 0 )
plot( fm1.lme, resid(., type = "normalized") ~ fitted(.)|subject*oddball, abline = 0 )
plot( fm1.lme, resid(.) ~ fitted(.)|stimDuration*subject, abline = 0 )
plot( fm1.lme, resid(.) ~ fitted(.)|stimDuration*subject*oddball, abline = 0 )

plot(ACF(fm1.lme, maxLag = 180, resType="p"), alpha = 0.01)
plot(ACF(fm1.lme, maxLag = 100, resType="n"), alpha = 0.01)
plot(ACF(fm1.lme, maxLag = 100, resType="r"), alpha = 0.01)
plot(ACF(fm0.lme, resType="n"), alpha = 0.01)
plot(ACF(fm1.lme, resType="n"), alpha = 0.01)
plot(Variogram( fm1.lme, form = ~ stimDuration ))
plot(Variogram( fm1.lme, form = ~ stimDuration, resType="n", robust=T ))
