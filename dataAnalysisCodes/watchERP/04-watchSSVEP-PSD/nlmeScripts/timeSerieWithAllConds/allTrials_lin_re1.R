setwd("d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciCode/dataAnalysisCodes/watchERP/04-watchSSVEP-PSD/nlmeScripts/timeSerieWithAllConds/")
source("initData.R")

psdData$psd <- sqrt(psdData$psd)

##############################################################################################
##############################################################################################
pp2 <- ggplot( psdData, aes(stimDuration, psd, colour=oddball) )
pp2 <- pp2 + geom_point() + geom_line( aes(stimDuration, psd, group=trialInSub) )
# pp2 <- pp2 + facet_wrap( frequency~subject, scales="free",nrow = 4 )
# pp2 <- pp2 + facet_grid( frequency~subject)
pp2 <- pp2 + facet_grid( subject~frequency, scales="free" )
pp2 <- cleanPlot(pp2)
pp2

##############################################################################################
##############################################################################################

psdDataGp <- groupedData(psd ~ stimDuration | subject/trialInSub, data = psdData)

fm1.lme <- lme(
  psd ~ stimDuration*oddball*frequency
  , data = psdDataGp
  , random = ~stimDuration|subject/trialInSub
  , control = list(opt="optim")
  , method = "REML"
)

summary(fm1.lme)

# mmf<-model.matrix(formula(fm1.lme), getData(fm1.lme))
# mmr<-model.matrix(fm1.lme$modelStruct$reStruct, getData(fm1.lme))
# coef(fm1.lme)
# fixef(fm1.lme)
# ranef(fm1.lme)
# fm1.lme$apVar
# plot(ranef(fm1.lme), level=2)
# plot(ranef(fm1.lme), level=1)

psdData$fitted  <- fitted(fm1.lme)
psdData$res     <- residuals(fm1.lme, type="normalized")

pp4 <- ggplot( psdData, aes(stimDuration, psd, colour=oddball) )
pp4 <- pp4 + geom_point(size=1) + geom_line( aes(stimDuration, psd, group=trialInSub) , linetype=2, size=0.3)
pp4 <- pp4 + geom_point() + geom_line( aes(stimDuration, fitted, group=trialInSub), size=1 )
pp4 <- pp4 + facet_wrap( frequency~subject, scales="free",nrow = 4 )
pp4 <- cleanPlot(pp4)
pp4

pp5 <- ggplot( psdData, aes(stimDuration, res, colour=oddball) )
pp5 <- pp5 + geom_point() + geom_line( aes(stimDuration, res, group=trialInSub) )
pp5 <- pp5 + facet_wrap( frequency~subject, scales="free",nrow = 4 )
pp5 <- cleanPlot(pp5)
pp5

pp6 <- ggplot( psdData, aes(as.numeric(trialInSubAndCond:stimDurationFac), res, colour=trialInSubAndCond) )
pp6 <- pp6 + geom_point()# + geom_line( aes(as.numeric(trialInSubAndCond:stimDurationFac), res, group=trialInSub) )
pp6 <- pp6 + facet_grid( frequency~subject, scales="free",nrow = 4 )
pp6 <- cleanPlot(pp6)
pp6

plot( fm1.lme, resid(., type = "normalized") ~ stimDuration, abline = 0 )
plot( fm1.lme, resid(., type = "normalized") ~ fitted(.), abline = 0 )

plot(ACF(fm1.lme, maxLag = 100, resType="n"), alpha = 0.01)
plot(ACF(fm1.lme, maxLag = 160, resType="n"), alpha = 0.01)
plot(ACF(fm1.lme, resType="n"), alpha = 0.01)


fm1.lmeML <- lme(
  psd ~ stimDuration*oddball*frequency
  , data = psdDataGp
  , random = ~stimDuration|subject/trialInSub
  , control = list(opt="optim")
  , method = "ML"
)
fm2.lmeML <- lme(
  psd ~ stimDuration*frequency
  , data = psdDataGp
  , random = ~stimDuration|subject/trialInSub
  , control = list(opt="optim")
  , method = "ML"
)
anova(fm1.lmeML, fm2.lmeML)

###################################################################################################################
###################################################################################################################

fm3.lmeML <- lme(
  psd ~ stimDuration + stimDuration:oddball +stimDuration:frequency + stimDuration:oddball:frequency
  , data = psdDataGp
  #   , random = ~(stimDuration+I(stimDuration^2))|subject/oddball
  , random = ~stimDuration|subject/trialInSub
  , control = list(opt="optim")
  , method = "ML"
)

psdData$fitted2  <- fitted(fm3.lmeML)
psdData$res2     <- residuals(fm3.lmeML, type="normalized")

pp7 <- ggplot( psdData, aes(stimDuration, res2, colour=oddball) )
pp7 <- pp7 + geom_point() + geom_line( aes(stimDuration, res2, group=trialInSub) )
pp7 <- pp7 + facet_wrap( ~subject, scale="free_y" )
pp7 <- cleanPlot(pp7)
pp7

pp8 <- ggplot( psdData, aes(as.numeric(trialInSubAndCond:stimDurationFac), res2, colour=trialInSubAndCond) )
pp8 <- pp8 + geom_point() #+ geom_line( aes(as.numeric(trialInSubAndCond:stimDurationFac), res2, group=trialInSub) )
pp8 <- pp8 + facet_grid( subject~oddball, scale="free_y" )
pp8 <- cleanPlot(pp8)
pp8

plot( fm3.lmeML, resid(., type = "normalized") ~ stimDuration, abline = 0 )
plot( fm3.lmeML, resid(., type = "normalized") ~ fitted(.), abline = 0 )
plot( fm3.lmeML, resid(., type = "normalized") ~ stimDuration|subject, abline = 0 )
plot( fm3.lmeML, resid(., type = "normalized") ~ fitted(.)|subject, abline = 0 )

plot(ACF(fm3.lmeML, maxLag = 10, resType="n"), alpha = 0.05)
plot(ACF(fm3.lmeML, maxLag = 160, resType="n"), alpha = 0.05)

plot(Variogram( fm3.lmeML, form = ~ stimDuration ))
plot(Variogram( fm3.lmeML, form = ~ stimDuration, resType="n", robust=T ))

###################################################################################################################
###################################################################################################################
###################################################################################################################
