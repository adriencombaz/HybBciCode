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

fileDir <- "d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciProcessedData/watch-ERP/04-watchSSVEP-PSD"
filename <- "psdDataset_Oz_Ha1"

fullfilename <- file.path( fileDir, paste0(filename, ".csv") )

psdData <- read.csv(fullfilename, header = TRUE)

psdData$frequency <- as.factor(psdData$frequency)
psdData$oddball <- as.factor(psdData$oddball)
psdData$fileNb <- as.factor(psdData$fileNb)
psdData$trial <- as.factor(psdData$trial)
psdData$sqrtPsd <- sqrt(psdData$psd)
psdData$stimDurationFac <- as.factor(psdData$stimDuration)

psdData$trialInSub <- psdData$oddball : psdData$frequency : psdData$trial

# temp1 <- psdData[psdData$frequency=="10",]
# temp2 <- psdData[psdData$frequency=="15",]
# psdData <- rbind(temp1, temp2)

varList <- c( "subject", "frequency","oddball", "stimDuration" )
psdDataAveRun <- ddply( psdData, varList, summarise, psd = mean(psd) )
psdDataAveRun$sqrtPsd <- sqrt(psdDataAveRun$psd)


############################################################################################################
############################################################################################################

pp <- ggplot( psdData, aes(stimDuration, psd, colour=oddball ) )
pp <- pp + stat_summary(fun.data = mean_cl_normal, geom="pointrange", position = position_dodge(0.2))
pp <- pp + facet_grid( subject ~ frequency, scales = "free_y"  )
pp <- cleanPlot(pp)

pp2 <- ggplot( psdDataAveRun, aes(stimDuration, psd, colour=oddball ) )
pp2 <- pp2 + stat_summary(fun.data = mean_cl_normal, geom="pointrange", position = position_dodge(0.2))
pp2 <- pp2 + facet_wrap( ~ frequency )
pp2 <- cleanPlot(pp2)


############################################################################################################
############################################################################################################

lm0 <- lme(
  psd ~ (stimDuration + stimDuration^2)*oddball*frequency
  , random = ~(stimDuration + stimDuration^2) | subject
  , data = psdData
  , control = list(opt="optim")
)
plot( lm0, resid(.) ~ stimDuration|subject*frequency*oddball, abline = 0 )

lm1 <- lme(
  psd ~ (stimDuration + stimDuration^2)*oddball*frequency
  , random = ~(stimDuration + stimDuration^2) | subject/oddball/frequency # not sure about the nesting, but gives better residual plot
  , data = psdData
  , control = list(opt="optim")
  )
plot( lm1, resid(.) ~ stimDuration, abline = 0 )
plot( lm1, resid(.) ~ stimDuration|oddball*frequency, abline = 0 )
plot( lm1, resid(.) ~ stimDuration|subject*frequency*oddball, abline = 0 )


plot( lm1, fitted(.) ~ stimDuration, abline = 0 )
plot( lm0, fitted(.) ~ stimDuration|subject*frequency*oddball, abline = 0 )


# lm2 <- lme(
#   psd ~ (stimDuration + stimDuration^2)*oddball*frequency
#   , random = ~(stimDuration + stimDuration^2) | trial/subject/oddball/frequency # not sure about the nesting, but gives better residual plot
#   , data = psdData
#   , control = list(opt="optim")
# )
# plot( lm2, resid(.) ~ stimDuration, abline = 0 )
# plot( lm2, resid(.) ~ stimDuration|subject*frequency*oddball, abline = 0 )
# plot(ACF(lm2, maxLag = 10), alpha = 0.01)

lm3 <- update(lm0, correlation = corAR1(0, form = ~stimDurationFac))
plot(ACF(lm3, maxLag = 10), alpha = 0.01)
plot( lm3, resid(.) ~ stimDuration, abline = 0 )

############################################################################################################
############################################################################################################

lm0 <- lme(
  sqrtPsd ~ stimDuration*oddball*frequency
  , random = ~stimDuration | subject
  , data = psdData
  , control = list(opt="optim")
)
plot( lm0, resid(.) ~ stimDuration|subject*frequency*oddball, abline = 0 )
plot(ACF(lm0, maxLag = 10), alpha = 0.01)

lm1 <- lme(
  sqrtPsd ~ stimDuration*oddball*frequency
  , random = ~stimDuration | subject/oddball/frequency # not sure about the nesting, but gives better residual plot
  , data = psdData
  , control = list(opt="optim")
)
plot( lm1, resid(.) ~ stimDuration, abline = 0 )
plot( lm1, resid(.) ~ stimDuration|oddball*frequency, abline = 0 )
plot( lm1, resid(.) ~ stimDuration|subject*frequency, abline = 0 )
plot( lm1, resid(.) ~ stimDuration|subject*frequency*oddball, abline = 0 )
plot(ACF(lm1, maxLag = 10), alpha = 0.01)

plot( lm1, fitted(.) ~ stimDuration )
plot( lm1, fitted(.) ~ stimDuration|subject*frequency*oddball )
plot( lm1, fitted(.) ~ stimDuration|frequency*oddball )

plot( lm1, resid(.) ~ fitted(.)|subject*frequency*oddball, abline = 0 )


plot( lm1, stimDuration~fitted(.), abline = c(0,1) )

plot( lm0, stimDuration~fitted(.), adj=0.3  ) 


lm2 <- lme(
  sqrtPsd ~ stimDuration*oddball*frequency
  , random = ~stimDuration | trialInSub/subject # not sure about the nesting, but gives better residual plot
  , data = psdData
  , control = list(opt="optim")
)


# lm2 <- lme(
#   sqrtPsd ~ stimDuration*oddball*frequency
#   , random = ~stimDuration | trial/subject/oddball/frequency
#   , data = psdData
#   , control = list(opt="optim")
)
plot( lm2, resid(.) ~ stimDuration, abline = 0 )
plot( lm2, resid(.) ~ stimDuration|subject*frequency*oddball, abline = 0 )
plot(ACF(lm2, maxLag = 10), alpha = 0.01)
plot( lm2, fitted(.) ~ stimDuration|subject )
plot( lm2, fitted(.) ~ stimDuration|subject*oddball )
plot( lm2, fitted(.) ~ stimDuration|subject*oddball*frequency )
# plot(augPred(fm1.lme), col.line = 'black')
# plot(augPred(fm1.lme, primary="stimDuration"), col.line = 'black')
# plot(augPred(fm1.lme) | subject)
plot( lm2, resid(.) ~ stimDuration, abline = 0 )
plot( lm2, resid(.) ~ stimDuration|subject, abline = 0 )
plot( lm2, resid(.) ~ stimDuration|oddball, abline = 0 )
plot( lm2, resid(.) ~ stimDuration|frequency, abline = 0 )
plot( lm2, resid(.) ~ stimDuration|subject*oddball*frequency, abline = 0 )
plot( lm2, resid(.) ~ fitted(.), abline = 0 )
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

lm3 <- update(lm1, correlation = corAR1( ))
plot(ACF(lm3, maxLag = 10), alpha = 0.05)
plot( lm3, resid(.) ~ stimDuration, abline = 0 )

############################################################################################################
############################################################################################################
baseline <- lme(psd ~ 1, random = ~1|subject/frequency/oddball, data = psdDataAveRun, method="ML")

timeRI <- lme( 
  psd ~ stimDuration * oddball * frequency
  , random = ~1|subject/oddball/frequency
  , data = psdDataAveRun
  , method = "REML"
)
test <- update(timeRI, random = ~stimDuration|subject/oddball/frequency)
timeRS <- lme( 
  psd ~ stimDuration * oddball * frequency
  , random = ~stimDuration|subject/oddball/frequency
  , data = psdDataAveRun
  , method = "ML"
  , control = list(opt="optim")
)

ARmodel <- lme( 
  psd ~ stimDuration * oddball * frequency
  , random = ~1+stimDuration|subject/oddball/frequency
  , data = psdDataAveRun
  , method = "REML"
  , correlation = corAR1(0, form = ~stimDuration|subject/oddball/frequency)
  , control = list(opt="optim")
  )


anova(timeRI, timeRS, ARmodel)

ARmodelML <- lme( 
  psd ~ stimDuration * oddball * frequency
  , random = ~1+stimDuration|subject/oddball/frequency
  , data = psdDataAveRun
  , method = "ML"
  , correlation = corAR1(0, form = ~stimDuration|subject/oddball/frequency)
  , control = list(opt="optim")
)


ARmodelPolML <- lme( 
  psd ~ stimDuration * oddball * frequency * I(stimDuration^2)
  , random = ~1+stimDuration|subject/oddball/frequency
  , data = psdDataAveRun
  , method = "ML"
  , correlation = corAR1(0, form = ~stimDuration|subject/oddball/frequency)
  , control = list(opt="optim")
)

ARmodelPolML2 <- lme( 
  psd ~ stimDuration * oddball * frequency * I(stimDuration^2)
  , random = ~1+stimDuration|subject/oddball/frequency
  , data = psdDataAveRun
  , method = "ML"
  , correlation = corAR1(0, form = ~stimDuration|subject/oddball/frequency)
  , control = list(opt="optim")
)

ARmodelPolMLNoOdd <- lme( 
  psd ~ stimDuration * frequency * I(stimDuration^2)
  , random = ~1+stimDuration|subject/oddball/frequency
  , data = psdDataAveRun
  , method = "ML"
  , correlation = corAR1(0, form = ~stimDuration|subject/oddball/frequency)
  , control = list(opt="optim")
)

ARmodelPolMLNoFreq <- lme( 
  psd ~ stimDuration * oddball * I(stimDuration^2)
  , random = ~1+stimDuration|subject/oddball/frequency
  , data = psdDataAveRun
  , method = "ML"
  , correlation = corAR1(0, form = ~stimDuration|subject/oddball/frequency)
  , control = list(opt="optim")
)