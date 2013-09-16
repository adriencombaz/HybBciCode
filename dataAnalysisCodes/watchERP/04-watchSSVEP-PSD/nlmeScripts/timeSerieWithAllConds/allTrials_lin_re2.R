setwd("d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciCode/dataAnalysisCodes/watchERP/04-watchSSVEP-PSD/nlmeScripts/timeSerieWithAllConds/")
source("initData.R")

psdData$psd <- sqrt(psdData$psd)

##############################################################################################
##############################################################################################

pp3 <- ggplot( psdData, aes(stimDuration, psd, colour=condition) )
pp3 <- pp3 + geom_point() + geom_line( aes(stimDuration, psd, group=trialInSubAndFreq) )
pp3 <- pp3 + facet_grid( subject~frequency )
pp3 <- pp3 + xlab("time") + ylab("value")
pp3 <- cleanPlot(pp3)
pp3

##############################################################################################
##############################################################################################

psdDataGp <- groupedData(psd ~ stimDuration | subject/trialInSub, data = psdData)
# plot(psdData)
# plot(psdData, displayLevel="subject")

fm1a.lme <- lme(
  psd ~ stimDuration*frequency*oddball
  , data = psdDataGp
  , random =  ~stimDuration | subject
  , control = list(opt="optim")
  , method = "REML"
)

fm1b.lme <- update(fm1a.lme, cor = corAR1(form=~stimDuration|subject/trialInSub))
fm1b.lme <- update(fm1a.lme, cor = corCompSymm(form=~stimDuration|subject/trialInSub))
fm1b.lme <- update(fm1a.lme, cor = corSymm(form=~stimDuration|subject/trialInSub))

fm2a.lme <- lme(
  psd ~ stimDuration*oddball
  , data = psdDataGp
  , random =  ~stimDuration | subject
  , control = list(opt="optim")
  , method = "REML"
)

fm2b.lme <- update(fm2a.lme, cor = corAR1(form=~stimDuration|subject/trialInSub))
fm2b.lme <- update(fm2a.lme, cor = corCompSymm(form=~stimDuration|subject/trialInSub))
fm2b.lme <- update(fm2a.lme, cor = corSymm(form=~stimDuration|subject/trialInSub))

anova(fm1a.lme, fm1b.lme)
anova(fm2a.lme, fm2b.lme)
fm1b.lmeML <- update(fm1b.lme, method="ML")
fm2b.lmeML <- update(fm2b.lme, method="ML")
anova(fm1b.lmeML, fm2b.lmeML)

fm1.lme <- fm1a.lme
fm1.lme <- fm1b.lme
fm1.lme <- fm2a.lme
fm1.lme <- fm2b.lme

summary(fm1a.lme)

# mmf<-model.matrix(formula(fm1.lme), getData(fm1.lme))
# mmr<-model.matrix(fm1.lme$modelStruct$reStruct, getData(fm1.lme))
# coef(fm1.lme)
# fixef(fm1.lme)
# ranef(fm1.lme)
# fm1.lme$apVar
# VarCorr(fm1.lme)

plot(ranef(fm1.lme), level=2)
plot(ranef(fm1.lme), level=1)

psdData$fitted  <- fitted(fm1.lme)
psdData$res     <- residuals(fm1.lme, type="normalized")

pp4 <- ggplot( psdData, aes(stimDuration, psd, colour=oddball) )
pp4 <- pp4 + geom_point() + geom_line( aes(stimDuration, psd, group=trialInSubAndFreq) , linetype=2, size=0.3)
pp4 <- pp4 + geom_line( aes(stimDuration, fitted, group=oddball), size=2 )
pp4 <- pp4 + facet_grid( frequency~subject )
pp4 <- cleanPlot(pp4)
pp4

pp4b <- ggplot( psdData, aes(stimDuration, psd, colour=oddball) )
pp4b <- pp4b + geom_point() #+ geom_line( aes(stimDuration, sqrtPsd, group=trialInSubAndCond) , linetype=2, size=0.3)
pp4b <- pp4b + geom_line( aes(stimDuration, fitted, group=oddball) )
pp4b <- pp4b + facet_grid( subject~trialInSubAndCond, scale="free_y" )
pp4b <- cleanPlot(pp4b)
pp4b

pp5 <- ggplot( psdData, aes(stimDuration, res, colour=trialInSubAndCond) )
pp5 <- pp5 + geom_point() + geom_line( aes(stimDuration, res, group=trialInSubAndCond) )
pp5 <- pp5 + facet_wrap( subject~oddball, scale="free_y" )
pp5 <- cleanPlot(pp5)
pp5

pp5b <- ggplot( psdData, aes(stimDuration, res, colour=oddball) )
pp5b <- pp5b + geom_point() + geom_line( aes(stimDuration, res, group=oddball) )
pp5b <- pp5b + facet_grid( subject~trialInSubAndCond, scale="free_y" )
pp5b <- cleanPlot(pp5b)
pp5b

pp6 <- ggplot( psdData, aes(as.numeric(oddball:stimDurationFac), res, colour=oddball) )
pp6 <- pp6 + geom_point() + geom_line( aes(as.numeric(oddball:stimDurationFac), res, group=trialInSubAndCond) )
pp6 <- pp6 + facet_grid( subject~trialInSubAndCond, scale="free_y" )
pp6 <- cleanPlot(pp6)
pp6

# plot( fm1.lme, fitted(.) ~ stimDuration )
# plot( fm1.lme, fitted(.) ~ stimDuration|subject )
# plot( fm1.lme, fitted(.) ~ stimDuration|subject*oddball )
# 
# plot(augPred(fm1.lme), col.line = 'black')
# plot(augPred(fm1.lme) | subject, col.line = 'black')

plot( fm1.lme, resid(., type = "normalized") ~ stimDuration, abline = 0 )
plot( fm1.lme, resid(., type = "normalized") ~ stimDuration|oddball, abline = 0 )
plot( fm1.lme, resid(., type = "normalized") ~ stimDuration|trialInSub, abline = 0 )
plot( fm1.lme, resid(., type = "normalized") ~ stimDuration|subject, abline = 0 )
plot( fm1.lme, resid(., type = "normalized") ~ stimDuration|subject*oddball, abline = 0 )

plot( fm1.lme, resid(., type = "normalized") ~ fitted(.), abline = 0 )
plot( fm1.lme, resid(., type = "normalized") ~ fitted(.)|oddball, abline = 0 )
plot( fm1.lme, resid(., type = "normalized") ~ fitted(.)|subject, abline = 0 )
plot( fm1.lme, resid(., type = "normalized") ~ fitted(.)|stimDuration, abline = 0 )
plot( fm2.lme, resid(., type = "normalized") ~ fitted(.)|stimDuration, abline = 0 )
plot( fm1.lme, resid(., type = "normalized") ~ fitted(.)|stimDuration*oddball, abline = 0 )
plot( fm1.lme, resid(., type = "normalized") ~ fitted(.)|subject*oddball, abline = 0 )
plot( fm1.lme, resid(.) ~ fitted(.)|stimDuration*subject, abline = 0 )
plot( fm1.lme, resid(.) ~ fitted(.)|stimDuration*subject*oddball, abline = 0 )

plot(ACF(fm1.lme, maxLag = 15, resType="n"), alpha = 0.01)
plot(ACF(fm1.lme, resType="n"), alpha = 0.01)
plot(Variogram( fm1.lme, form = ~ stimDuration ))
plot(Variogram( fm1.lme, form = ~ stimDuration, resType="n", robust=T ))
