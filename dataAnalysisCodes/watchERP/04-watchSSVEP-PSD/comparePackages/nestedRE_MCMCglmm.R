setwd("d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciCode/dataAnalysisCodes/watchERP/04-watchSSVEP-PSD/comparePackages/")
# detach("package:nlme", unload=TRUE)
source("initData.R")
library(MCMCglmm)


# psdData <- psdData[psdData$stimDuration != 1, ]
# psdData$stimDuration <- psdData$stimDuration-1

##############################################################################################
##############################################################################################
# pp2 <- ggplot( psdData, aes(stimDuration, psd, colour=oddball) )
# pp2 <- pp2 + geom_point() + geom_line( aes(stimDuration, psd, group=trialInSubAndFreq) )
# pp2 <- pp2 + facet_grid( subject~frequency, scales="free" )
# pp2 <- cleanPlot(pp2)
# pp2
# 
# pp3 <- ggplot( psdData, aes(stimDuration, psd, colour=subject) )
# pp3 <- pp3 + geom_point() + geom_line(aes(stimDuration, psd, group=trial))# aes(stimDuration, psd, group=trialInSubAndFreqAndCond) )
# pp3 <- pp3 + facet_grid( oddball~frequency, scales="free" )
# pp3 <- cleanPlot(pp3)
# pp3

##############################################V################################################
##############################################################################################

fm1a <- MCMCglmm( psd ~ (stimDuration+I(stimDuration^2))*frequency*oddball
              , random = ((stimDuration+I(stimDuration^2))~subject/trialInSub)
              , data = psdData
)
fm1b <- MCMCglmm( psd ~ ((stimDuration+I(stimDuration^2))+frequency+oddball)^2
              , random = ((stimDuration+I(stimDuration^2))~subject/trialInSub)
              , data = psdData
)
fm1c <- MCMCglmm( psd ~ ((stimDuration+I(stimDuration^2))*frequency)+oddball
              , random = ((stimDuration+I(stimDuration^2))~subject/trialInSub)
              , data = psdData
)
fm1d <- MCMCglmm( psd ~ (stimDuration+I(stimDuration^2))*frequency
              , random = ((stimDuration+I(stimDuration^2))~subject/trialInSub)
              , data = psdData
)

anova(fm1z, fm1a, fm1b, fm1c, fm1d)
anova(fm1a, fm1d)

###########################################################################################################################

fm1d <- MCMCglmm( psd ~ (stimDuration+I(stimDuration^2))*frequency*oddball
                  , random = (stimDuration~subject/trialInSub)
                  , data = psdData
)

fm1d2 <- MCMCglmm( psd ~ (stimDuration+I(stimDuration^2))*frequency*oddball
                  , random = us(1+stimDuration+I(stimDuration^2))  ~ subject/trialInSub
                  , data = psdData
)

###########################################################################################################################
###########################################################################################################################

fm <- fm1z1
psdData$fitted  <- fitted(fm)
psdData$res     <- residuals(fm, type="normalized")

dotplot(ranef(fm, postVar=TRUE))
qqmath(ranef(fm, postVar=TRUE))      

pp4 <- ggplot( psdData, aes(stimDuration, psd, colour=oddball) )
pp4 <- pp4 + geom_point(size=1) + geom_line( aes(stimDuration, psd, group=trialInSubAndFreq) , linetype=2, size=0.3)
pp4 <- pp4 + geom_point() + geom_line( aes(stimDuration, fitted, group=trialInSubAndFreq) )
pp4 <- pp4 + facet_grid( subject~frequency, scales="free" )
# pp4 <- pp4 + facet_wrap( ~subject )
pp4 <- cleanPlot(pp4)
pp4

plot( fitted(fm), residuals(fm) )
abline(h=0)

pp6 <- ggplot(psdData, aes(fitted, res))
pp6 <- pp6 + geom_point()
pp6 <- cleanPlot(pp6)
pp6

pp7 <- pp6 + facet_wrap(~stimDurationFac, scales="free")
pp7

mcp.fnc(fm, trim = 2.5, col = "red")
tete <- pacf( resid( fm ) )

pp5 <- ggplot( psdData, aes(stimDuration, res) )
pp5 <- pp5 + geom_point()
pp5 <- cleanPlot(pp5)
pp5
