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

psdData$frequency <- as.factor(psdData$frequency)
psdData$oddball <- as.factor(psdData$oddball)
psdData$fileNb <- as.factor(psdData$fileNb)
psdData$trial <- as.factor(psdData$trial)
psdData$sqrtPsd <- sqrt(psdData$psd)
psdData$stimDurationFac <- as.factor(psdData$stimDuration)

psdData <- psdData[psdData$frequency=="15",]
psdData <- psdData[psdData$oddball=="0",]
psdData$frequency <- droplevels(psdData$frequency)
psdData$oddball <- droplevels(psdData$oddball)


varList <- c( "subject", "stimDuration", "stimDurationFac" )
psdDataMeanTrial <- ddply( psdData, varList, summarise, psd = mean(psd) )
psdDataMeanTrial$sqrtPsd <- sqrt(psdDataMeanTrial$psd)

# varList <- c( "subject", "stimDuration", "trial", "sqrtPsd" )
# psdData <- psdData[ , names(psdData) %in% varList]

psdDataSingleTrial <- psdData[psdData$trial=="tr06",]
psdDataSingleTrial$trial <- droplevels(psdDataSingleTrial$trial)

##############################################################################################
##############################################################################################

# psdData <- groupedData(sqrtPsd ~ stimDuration | subject, data = psdDataSingleTrial)
# psdData <- groupedData(sqrtPsd ~ stimDuration | subject, data = psdDataMeanTrial)
psdData <- groupedData(sqrtPsd ~ stimDurationFac | subject, data = psdDataMeanTrial)
# psdData <- groupedData(sqrtPsd ~ stimDuration | subject, data = psdData)
plot(psdData)

fm1.lme <- lme(sqrtPsd~stimDurationFac, data=psdData, random = ~stimDurationFac|subject, , control = list(opt="optim"))
# fm1.lme <- lme(sqrtPsd~stimDuration, data=psdData, random = ~stimDuration|subject, , control = list(opt="optim"))
# fm1.lme <- lme(sqrtPsd~stimDuration, data=psdData, random = ~stimDuration|trial/subject, , control = list(opt="optim"))

# model.matrix(sqrtPsd ~ stimDuration, psdDataMeanTrial)


# res <- resid(fm1.lme, type="n", asList=TRUE)

plot( fm1.lme, fitted(.) ~ stimDuration|subject )
plot(augPred(fm1.lme), col.line = 'black')
plot( fm1.lme, resid(.) ~ stimDuration|trial*subject, abline = 0 )
plot( fm1.lme, resid(.) ~ stimDuration|subject, abline = 0 )
plot( fm1.lme, resid(.) ~ stimDuration, abline = 0 )
plot( fm1.lme, resid(.) ~ fitted(.), abline = 0 )
plot( fm1.lme, resid(.) ~ fitted(.)|subject, abline = 0 )
plot( fm1.lme, resid(.) ~ fitted(.)|stimDuration, abline = 0 )
plot( fm1.lme, resid(.) ~ fitted(.)|stimDuration*subject, abline = 0 )
plot(ACF(fm1.lme, maxLag = 10, resType="n"), alpha = 0.05)

plot(Variogram( fm1.lme, form = ~ stimDuration ))
plot(Variogram( fm1.lme, form = ~ stimDuration, resType="n", robust=T ))



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





fm2.lme <- update(fm1.lme, weights = varPower(form=~stimDuration|subject))
fm2b.lme <- update(fm1.lme, weights = varPower(form=~stimDuration))
fm2.lme <- update(fm1.lme, weights = varIdent(form=~stimDuration|subject))
fm2b.lme <- update(fm1.lme, weights = varIdent(form=~stimDuration))
fm2.lme <- update(fm1.lme, weights = varFixed(value=~stimDuration))
fm2.lme <- update(fm1.lme, weights = varExp(form=~stimDuration|subject))
fm2.lme <- update(fm1.lme, weights = varConstPower(form=~stimDuration))
# fm2.lme <- update(fm1.lme, weights = varComb(form=~stimDuration|subject))
plot(ACF(fm2.lme, maxLag = 10, resType="n"), alpha = 0.05)
plot(augPred(fm2.lme), col.line = 'black')
plot( fm2.lme, resid(.) ~ stimDuration|subject, abline = 0 )
plot( fm2.lme, resid(.) ~ stimDuration, abline = 0 )
plot( fm2.lme, resid(.) ~ fitted(.), abline = 0 )
plot(Variogram( fm2.lme, form = ~ stimDuration ))
plot(Variogram( fm2.lme, form = ~ stimDuration, resType="n", robust=T ))


fm3.lme <- update(fm2.lme, corr = corARMA(form=~stimDuration, p=1)) 
fm3.lme <- update(fm2.lme, corr = corARMA(form=~stimDuration, p=2)) 
fm3.lme <- update(fm2.lme, corr = corARMA(form=~stimDuration, q=1)) 
fm3.lme <- update(fm2.lme, corr = corARMA(form=~stimDuration, q=2)) 
fm3.lme <- update(fm2.lme, corr = corARMA(form=~stimDuration, q=3)) 
fm3.lme <- update(fm2.lme, corr = corARMA(form=~stimDuration, q=4)) 
fm3.lme <- update(fm2.lme, corr = corARMA(form=~stimDuration, q=5)) 
fm3.lme <- update(fm2.lme, corr = corARMA(form=~stimDuration, q=6)) 
fm3.lme <- update(fm2.lme, corr = corARMA(form=~stimDuration, p=1, q=1)) 
fm3.lme <- update(fm2.lme, corr = corCAR1(form=~stimDuration)) 
fm3.lme <- update(fm2.lme, corr = corCAR1(value=0.4, form=~stimDuration)) 
fm3.lme <- update(fm2.lme, corr = corCAR1(value=0.6, form=~stimDuration)) 
fm3.lme <- update(fm2.lme, corr = corCAR1(value=0.8, form=~stimDuration)) 
fm3.lme <- update(fm2.lme, corr = corExp(form = ~ stimDuration)) 
fm4.lme <- update(fm2.lme, corr = corExp(form = ~ stimDuration, nugget=T)) 
fm3.lme <- update(fm2.lme, corr = corRatio(form = ~ stimDuration)) 
fm3.lme <- update(fm2.lme, corr = corLin(form = ~ stimDuration)) 
fm3.lme <- update(fm2.lme, corr = corSpher(form = ~ stimDuration)) 
fm3.lme <- update(fm2.lme, corr = corGaus(form = ~ stimDuration)) 
plot(ACF(fm3.lme, maxLag = 10, resType="n"), alpha = 0.05)
plot(augPred(fm3.lme), col.line = 'black')
plot( fm3.lme, resid(.) ~ stimDuration|subject, abline = 0 )
plot( fm3.lme, resid(.) ~ stimDuration, abline = 0 )
plot( fm3.lme, resid(.) ~ fitted(.)|subject, abline = 0 )
plot( fm3.lme, resid(.) ~ fitted(.), abline = 0 )
plot(Variogram( fm3.lme, form = ~ stimDuration ))
plot(Variogram( fm3.lme, form = ~ stimDuration, resType="n", robust=T ))

##############################################################################################
##############################################################################################

psdDataFac <- psdData
psdDataFac$timeFac <- as.factor(psdDataFac$stimDuration)
psdDataFac <- groupedData(sqrtPsd ~ stimDuration | subject/timeFac, data = psdDataFac)
fmFac1.lme <- lme(sqrtPsd~timeFac, data=psdDataFac, random = ~1|subject/timeFac)

plot( fmFac1.lme, fitted(.) ~ stimDuration|subject )
plot(augPred(fmFac1.lme), col.line = 'black')
plot(augPred(fmFac1.lme), primary="timeFac", col.line = 'black')
plot( fmFac1.lme, resid(.), abline = 0 )
plot( fmFac1.lme, resid(.) ~ stimDuration|subject, abline = 0 )
plot( fmFac1.lme, resid(.) ~ stimDuration, abline = 0 )
plot( fm1.lme, resid(.) ~ fitted(.), abline = 0 )
plot( fm1.lme, resid(.) ~ fitted(.)|subject, abline = 0 )
plot( fm1.lme, resid(.) ~ fitted(.)|stimDuration, abline = 0 )
plot( fmFac1.lme, resid(.) ~ fitted(.)|subject, abline = 0 )
plot(ACF(fmFac1.lme, maxLag = 10, resType="n"), alpha = 0.05)

plot(Variogram( fm1.lme, form = ~ stimDuration ))
plot(Variogram( fmFac1.lme, form = ~ stimDuration, resType="n", robust=T ))
