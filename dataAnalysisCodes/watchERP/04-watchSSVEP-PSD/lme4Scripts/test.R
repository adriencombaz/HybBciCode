setwd("d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciCode/dataAnalysisCodes/watchERP/04-watchSSVEP-PSD/lme4Scripts/")
# detach("package:nlme", unload=TRUE)
source("initData.R")


# psdData <- psdData[psdData$stimDuration != 1, ]
# psdData$stimDuration <- psdData$stimDuration-1

##############################################################################################
##############################################################################################
pp2 <- ggplot( psdData, aes(stimDuration, psd, colour=oddball) )
pp2 <- pp2 + geom_point() + geom_line( aes(stimDuration, psd, group=trialInSubAndFreq) )
pp2 <- pp2 + facet_grid( subject~frequency, scales="free" )
pp2 <- cleanPlot(pp2)
pp2

pp3 <- ggplot( psdData, aes(stimDuration, psd, colour=subject) )
pp3 <- pp3 + geom_point() + geom_line(aes(stimDuration, psd, group=trial))# aes(stimDuration, psd, group=trialInSubAndFreqAndCond) )
pp3 <- pp3 + facet_grid( oddball~frequency, scales="free" )
pp3 <- cleanPlot(pp3)
pp3

##############################################################################################
##############################################################################################

fm1 <- lmer( psd ~ (stimDuration+I(stimDuration^2))*frequency*oddball
             + (stimDuration+I(stimDuration^2)|subject/frequency)
             , psdData
             , REML = TRUE
)
fm2 <- lmer( psd ~ (stimDuration+I(stimDuration^2))*frequency*oddball
             + (stimDuration+I(stimDuration^2)|subject/frequency)
             + (1|(subject:trialInSub)/stimDurationFac)
             , psdData
             , REML = TRUE
)

fm1 <- lmer( psd ~ (stimDuration+I(stimDuration^2))*frequency*oddball
             + (stimDuration+I(stimDuration^2)|subject/trialInSub)
             , psdData
             , REML = TRUE
)

# fm2 <- lmer( psd ~ (stimDuration+I(stimDuration^2))*frequency*oddball
#              + ((stimDuration+I(stimDuration^2))|subject/frequency/trialInSubAndFreq)
#              , psdData
#              , REML = TRUE
# )
# 
# fm3a <- lmer( psd ~ (stimDuration+I(stimDuration^2))*frequency*oddball
#               + ((stimDuration+I(stimDuration^2))|subject/frequency/trialInSubAndFreq)
#               , psdData
#               , REML = FALSE
# )
# fm3b <- lmer( psd ~ (stimDuration+I(stimDuration^2))*oddball
#               + ((stimDuration+I(stimDuration^2))|subject/frequency/trialInSubAndFreq)
#               , psdData
#               , REML = FALSE
# )

fm1a <- lmer( psd ~ (stimDuration+I(stimDuration^2))*frequency*oddball
              + ((stimDuration+I(stimDuration^2))|subject/trialInSub)
              , psdData
              , REML = FALSE
)
fm1b <- lmer( psd ~ ((stimDuration+I(stimDuration^2))+frequency+oddball)^2
              + ((stimDuration+I(stimDuration^2))|subject/trialInSub)
              , psdData
              , REML = FALSE
)
fm1c <- lmer( psd ~ ((stimDuration+I(stimDuration^2))*frequency)+oddball
              + ((stimDuration+I(stimDuration^2))|subject/trialInSub)
              , psdData
              , REML = FALSE
)
fm1d <- lmer( psd ~ (stimDuration+I(stimDuration^2))*frequency
              + ((stimDuration+I(stimDuration^2))|subject/trialInSub)
              , psdData
              , REML = FALSE
)

anova(fm1a, fm1b, fm1c, fm1d)
anova(fm1a, fm1d)
###########################################################################################################################
###########################################################################################################################
###########################################################################################################################

fm <- fm2
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

mcp.fnc(fm, trim = 2.5, col = "red")
tete <- pacf( resid( fm ) )

pp5 <- ggplot( psdData, aes(stimDuration, res) )
pp5 <- pp5 + geom_point()
pp5 <- cleanPlot(pp5)
pp5
