setwd("d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciCode/dataAnalysisCodes/watchERP/04-watchSSVEP-PSD/")
rm(list = ls())
library(ggplot2)
library(reshape2)
library(grid)
library(plyr)
library(nlme)
library(lattice)

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

varList <- c( "subject", "frequency","oddball", "stimDuration" )
psdDataAveRun <- ddply( psdData, varList, summarise, psd = mean(psd) )
psdDataAveRun$sqrtPsd <- sqrt(psdDataAveRun$psd)

varList <- c( "subject", "frequency","oddball", "stimDuration", "trial", "sqrtPsd" )
psdData <- psdData[ , names(psdData) %in% varList]

############################################################################################################
############################################################################################################
psdGpDataAveTrial <- groupedData(sqrtPsd ~ stimDuration | subject/frequency/oddball, data = psdDataAveRun)
plot( psdGpDataAveTrial )

aveTr.lm1 <- lme(
  sqrtPsd ~ stimDuration*oddball*frequency
  , random = ~stimDuration | subject
  , data = psdGpDataAveTrial
  , control = list(opt="optim")
)

############################################################################################################
############################################################################################################

psdGpDataNst <- groupedData(sqrtPsd ~ stimDuration | subject/frequency/oddball, data = psdData)
plot( psdGpDataNst, layout=c(8,8) )
plot(
  groupedData(sqrtPsd ~ stimDuration | frequency/subject/oddball, data = psdData)
  , displayLevel=2
  , layout=c(8,4)
)

psdGpDataNoNst <- groupedData(sqrtPsd ~ stimDuration | subject, data = psdData)

psdGpDataMeanTr <- groupedData(sqrtPsd ~ stimDuration | subject, data = psdData)
psdGpDataMeanTr2 <- groupedData(sqrtPsd ~ stimDuration | subject/frequency/oddball, data = psdData)
# plot( psdGpDataMeanTr, inner = ~oddball/frequency )

# modList <- lmList(sqrtPsd~stimDuration, data=psdGpData)
# coef(modList)



allTr.nst.list <- lmList(
  sqrtPsd ~ stimDuration | subject/oddball/frequency
  , data = psdGpDataNst
)

allTr.noNst.list <- lmList(
  sqrtPsd ~ stimDuration*oddball*frequency | subject
  , data = psdGpDataNoNst
)




allTr.nst.lm1 <- lme(
  sqrtPsd ~ stimDuration*oddball*frequency
  , random = ~stimDuration | subject/oddball/frequency
  , data = psdGpDataNst
  , control = list(opt="optim")
)

allTr.noNst.lm1 <- lme(
  sqrtPsd ~ stimDuration*oddball*frequency
  , random = ~stimDuration | subject
  , data = psdGpDataNoNst
  , control = list(opt="optim")
)

allTr.trInSub.lm1 <- lme(
  sqrtPsd ~ stimDuration*oddball*frequency
  , random = ~stimDuration | trial/subject
  , data = psdGpDataNoNst
  , control = list(opt="optim")
)


meanTr.lm1 <- lme(
  sqrtPsd ~ stimDuration*oddball*frequency
  , random = ~stimDuration | subject
  , data = psdGpDataMeanTr
  , control = list(opt="optim")
)

meanTr2.lm1 <- lme(
  sqrtPsd ~ stimDuration*oddball*frequency
  , random = ~stimDuration | subject/frequency/oddball
  , data = psdGpDataMeanTr2
  , control = list(opt="optim")
)

lm1<-allTr.trInSub.lm1
plot( lm1, fitted(.) ~ stimDuration|subject*frequency*oddball )
plot(augPred(lm1), layout=c(8,8), col.line = 'black')
plot( lm1, resid(.) ~ stimDuration|subject*frequency*oddball, abline = 0 )
plot( lm1, resid(.) ~ stimDuration|subject*frequency*oddball*trial, abline = 0 )
plot(ACF(lm1, maxLag = 10), alpha = 0.01)

lm1AR <- update(lm1, correlation=corAR1())
lm1ARtest <- update(lm1, correlation=corAR1())

allTr.nst.lm1AR1 = update(allTr.nst.lm1, correlation = corAR1())
allTr.noNst.lm1AR1 = update(allTr.noNst.lm1, correlation = corAR1())
meanTr.lm1AR1 = update(meanTr.lm1, correlation = corAR1())


allTr.nst.lm1AR1 = update(allTr.nst.lm1,  corCAR1(form = ~stimDuration))

plot( allTr.nst.lm1, fitted(.) ~ stimDuration|subject*frequency*oddball )
plot(augPred(allTr.nst.lm1), layout=c(8,8), col.line = 'black')
plot( allTr.nst.lm1, resid(.) ~ stimDuration|subject*frequency*oddball, abline = 0 )
plot(ACF(allTr.nst.lm1, maxLag = 10), alpha = 0.01)

plot( allTr.nst.lm1AR1, fitted(.) ~ stimDuration|subject*frequency*oddball )
plot(augPred(allTr.nst.lm1AR1), layout=c(8,8), col.line = 'black')
plot( allTr.nst.lm1AR1, resid(.) ~ stimDuration|subject*frequency*oddball, abline = 0 )
plot(ACF(allTr.nst.lm1AR1, maxLag = 10), alpha = 0.01)

