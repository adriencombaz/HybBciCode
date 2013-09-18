setwd("d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciCode/dataAnalysisCodes/watchERP/04-watchSSVEP-PSD/lme4Scripts/")
# detach("package:nlme", unload=TRUE)
source("initDataWithHa.R")
library(lme4)
library(LMERConvenienceFunctions)
library(languageR)


# psdData <- psdData[psdData$stimDuration != 1, ]
# psdData$stimDuration <- psdData$stimDuration-1

##############################################################################################
##############################################################################################
pp2 <- ggplot( psdData, aes(stimDuration, psd, colour=oddball) )
pp2 <- pp2 + geom_point() + geom_line( aes(stimDuration, psd, group=trialInSubAndFreq) )
pp2 <- pp2 + facet_grid( subject~frequency*harmonic, scales="free" )
pp2 <- cleanPlot(pp2)
pp2

pp2b <- ggplot( psdData, aes(stimDuration, psd, colour=oddball) )
pp2b <- pp2b + stat_summary(fun.data=mean_cl_normal, geom="pointrange", aes(stimDuration, psd, group=oddball))
# pp2b <- pp2b + geom_point() + geom_line( aes(stimDuration, psd, group=trialInSubAndFreq) )
pp2b <- pp2b + facet_grid( subject~frequency*harmonic, scales="free" )
pp2b <- cleanPlot(pp2b)
pp2b

##############################################V################################################
##############################################################################################

# fm1 <- lmer( psd ~ (stimDuration+I(stimDuration^2))*frequency*oddball
#              + (stimDuration+I(stimDuration^2)|subject/trialInSub)
#              , psdData
#              , REML = TRUE
# )
# 
# fm1 <- lmer( psd ~ (stimDuration+I(stimDuration^2))*frequency*oddball
#              + (stimDuration+I(stimDuration^2)|subject/trialInSub)
#              , psdData
#              , REML = FALSE
# )
# 
# fm0 <- lmer( psd ~ (stimDuration+I(stimDuration^2))*frequency
#              + (stimDuration+I(stimDuration^2)|subject/trialInSub)
#              , psdData
#              , REML = FALSE
# )
# 
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

mcmc <- pvals.fnc( fm1a, nsim=5000, withMCMC=TRUE )
mcmc$fixed
mcmc$random

###########################################################################################################################
###########################################################################################################################
fm1a <- lmer( psd ~ (stimDuration+I(stimDuration^2))*frequency*oddball
              + ((stimDuration+I(stimDuration^2))|subject/trialInSub)
              , psdData
              , REML = FALSE
)
fm1a1 <- lmer( psd ~ (stimDuration+I(stimDuration^2))*frequency
              + ((stimDuration+I(stimDuration^2))|subject/trialInSub)
              , psdData
              , REML = FALSE
)
fm1a2 <- lmer( psd ~ (stimDuration+I(stimDuration^2))*oddball
              + ((stimDuration+I(stimDuration^2))|subject/trialInSub)
              , psdData
              , REML = FALSE
)
fm1a3 <- lmer( psd ~ (stimDuration+I(stimDuration^2))
               + ((stimDuration+I(stimDuration^2))|subject/trialInSub)
               , psdData
               , REML = FALSE
)

anova(fm1a, fm1a1)
anova(fm1a, fm1a2)
anova(fm1a3, fm1a1)
anova(fm1a3, fm1a2)

mcmc <- pvals.fnc( fm1a1, nsim=5000, withMCMC=TRUE )
mcmc$fixed
mcmc$random

###########################################################################################################################
###########################################################################################################################
fm1a <- lmer( psd ~ (stimDuration+I(stimDuration^2))*frequency*oddball
              + ((stimDuration+I(stimDuration^2))|subject/trialInSub)
              , psdData
              , REML = TRUE
)

fm1a2 <- lmer( psd ~ (stimDuration+I(stimDuration^2))*frequency*oddball
               + (1|subject/trialInSub)
               + ((0+stimDuration)|subject/trialInSub)
               + ((0+I(stimDuration^2))|subject/trialInSub)
               , psdData
               , REML = TRUE
)
anova(fm1a, fm1a2)

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
