setwd("d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciCode/dataAnalysisCodes/watchERP/04-watchSSVEP-PSD/nlmeScripts/timeSerieWithCond_timeAsFactor/")
source("initData.R")

##############################################################################################
##############################################################################################

pp3 <- ggplot( psdData, aes(stimDuration, sqrtPsd, colour=condition) )
pp3 <- pp3 + geom_point() + geom_line( aes(stimDuration, sqrtPsd, group=trialInSub) )
pp3 <- pp3 + facet_wrap( ~subject )
pp3 <- pp3 + xlab("time") + ylab("value")
pp3 <- cleanPlot(pp3)
pp3

##############################################################################################
##############################################################################################

# psdDataGp <- groupedData(psd ~ stimDuration | subject, data = psdData)
# fm1.lis <- lmList(sqrtPsd~stimDuration, data=psdDataGp)
# plot(intervals(fm1.lis))
# 
# psdDataGp <- groupedData(psd ~ I(stimDuration-1) | trial3, data = psdData)
# fm1.lis <- lmList(sqrtPsd~I(stimDuration-1), data=psdDataGp)
# plot(intervals(fm1.lis))


# fm1.lis <- lmList(psd~(stimDuration+I(stimDuration^2))|subject/oddball/trialInSubAndCond, data=psdData)
# plot(intervals(fm1.lis))
# summary(fm1.lis)
# pairs(fm1.lis, id = 0.01, adj = -0.5)
# pairs(fm1.lis)

##############################################################################################
##############################################################################################

psdDataGp <- groupedData(sqrtPsd ~ stimDuration | subject/oddball/trialInSubAndCond, data = psdData)

fm1.lme <- lme(
  sqrtPsd ~ stimDuration*oddball
  , data = psdDataGp
  , random = ~stimDuration|subject/oddball
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
  
plot(ranef(fm1.lme), level=2)
plot(ranef(fm1.lme), level=1)

psdData$fitted  <- fitted(fm1.lme)
psdData$res     <- residuals(fm1.lme, type="normalized")

pp4 <- ggplot( psdData, aes(stimDuration, sqrtPsd, colour=oddball) )
pp4 <- pp4 + geom_point(size=1) + geom_line( aes(stimDuration, sqrtPsd, group=trialInSub) , linetype=2, size=0.3)
pp4 <- pp4 + geom_point() + geom_line( aes(stimDuration, fitted, group=oddball), size=2 )
pp4 <- pp4 + facet_wrap( ~subject )
pp4 <- cleanPlot(pp4)
pp4

pp5 <- ggplot( psdData, aes(stimDuration, res, colour=oddball) )
pp5 <- pp5 + geom_point() + geom_line( aes(stimDuration, res, group=trialInSub) )
pp5 <- pp5 + facet_wrap( ~subject )
pp5 <- cleanPlot(pp5)
pp5

pp6 <- ggplot( psdData, aes(as.numeric(trialInSubAndCond:stimDurationFac), res, colour=trialInSubAndCond) )
pp6 <- pp6 + geom_point() + geom_line( aes(as.numeric(trialInSubAndCond:stimDurationFac), res, group=trialInSub) )
pp6 <- pp6 + facet_grid( subject~oddball )
pp6 <- cleanPlot(pp6)
pp6

plot( fm1.lme, fitted(.) ~ stimDuration )
plot( fm1.lme, fitted(.) ~ stimDuration|subject )
plot( fm1.lme, fitted(.) ~ stimDuration|subject*oddball )

# plot(augPred(fm1.lme), col.line = 'black')
# plot(augPred(fm1.lme) | subject, col.line = 'black')

plot( fm1.lme, resid(., type = "normalized") ~ stimDuration, abline = 0 )
plot( fm1.lme, resid(., type = "normalized") ~ stimDuration|oddball, abline = 0 )
plot( fm1.lme, resid(., type = "normalized") ~ stimDuration|subject, abline = 0 )
plot( fm1.lme, resid(., type = "normalized") ~ stimDuration|subject*oddball, abline = 0 )

plot( fm1.lme, resid(., type = "normalized") ~ fitted(.), abline = 0 )
plot( fm1.lme, resid(., type = "normalized") ~ fitted(.)|oddball, abline = 0 )
plot( fm1.lme, resid(., type = "normalized") ~ fitted(.)|subject, abline = 0 )
plot( fm1.lme, resid(., type = "normalized") ~ fitted(.)|stimDuration, abline = 0 )
plot( fm1.lme, resid(., type = "normalized") ~ fitted(.)|stimDuration*oddball, abline = 0 )
plot( fm1.lme, resid(., type = "normalized") ~ fitted(.)|subject*oddball, abline = 0 )

plot(ACF(fm1.lme, maxLag = 100, resType="n"), alpha = 0.01)
plot(ACF(fm1.lme, resType="n"), alpha = 0.01)

plot(Variogram( fm1.lme, form = ~ stimDuration ))
plot(Variogram( fm0.lme, form = ~ stimDuration, resType="n", robust=T ))

##############################################################################################
##############################################################################################

fm3.lme <- update(fm1.lme, corr = corARMA(form=~stimDuration|subject/oddball/trialInSubAndCond, p=1)) 
fm3.lme <- update(fm1.lme, corr = corARMA(form=~stimDuration|subject/oddball/trialInSubAndCond, p=2)) 
fm3.lme <- update(fm1.lme, corr = corARMA(form=~stimDuration|subject/oddball/trialInSubAndCond, q=1)) 
fm3.lme <- update(fm1.lme, corr = corARMA(form=~stimDuration|subject/oddball/trialInSubAndCond, q=2)) 
fm3.lme <- update(fm1.lme, corr = corARMA(form=~stimDuration|subject/oddball/trialInSubAndCond, q=3)) 
fm3.lme <- update(fm1.lme, corr = corARMA(form=~stimDuration|subject/oddball/trialInSubAndCond, q=4)) 
fm3.lme <- update(fm1.lme, corr = corARMA(form=~stimDuration|subject/oddball/trialInSubAndCond, q=5)) 
fm3.lme <- update(fm1.lme, corr = corARMA(form=~stimDuration|subject/oddball/trialInSubAndCond, q=6)) 
fm3.lme <- update(fm1.lme, corr = corARMA(form=~stimDuration|subject/oddball/trialInSubAndCond, p=1, q=1)) 
fm3.lme <- update(fm1.lme, corr = corCAR1(form=~stimDuration|subject/oddball/trialInSubAndCond)) 
fm3.lme <- update(fm1.lme, corr = corCAR1(value=0.4, form=~stimDuration|subject/oddball/trialInSubAndCond)) 
fm3.lme <- update(fm1.lme, corr = corCAR1(value=0.6, form=~stimDuration|subject/oddball/trialInSubAndCond)) 
fm3.lme <- update(fm1.lme, corr = corCAR1(value=0.8, form=~stimDuration|subject/oddball/trialInSubAndCond)) 
fm3.lme <- update(fm1.lme, corr = corExp(form = ~ stimDuration|subject/oddball/trialInSubAndCond)) 
fm4.lme <- update(fm1.lme, corr = corExp(form = ~ stimDuration|subject/oddball/trialInSubAndCond, nugget=T)) 
fm3.lme <- update(fm1.lme, corr = corRatio(form = ~ stimDuration|subject/oddball/trialInSubAndCond)) 
fm3.lme <- update(fm1.lme, corr = corLin(form = ~ stimDuration|subject/oddball/trialInSubAndCond)) 
fm3.lme <- update(fm1.lme, corr = corSpher(form = ~ stimDuration|subject/oddball/trialInSubAndCond)) 
fm3.lme <- update(fm1.lme, corr = corGaus(form = ~ stimDuration|subject/oddball/trialInSubAndCond)) 

summary(fm3.lme)

psdData$fitted  <- fitted(fm3.lme)
psdData$res     <- residuals(fm3.lme, type="normalized")

pp5 <- ggplot( psdData, aes(stimDuration, res, colour=oddball) )
pp5 <- pp5 + geom_point() + geom_line( aes(stimDuration, res, group=trialInSub) )
pp5 <- pp5 + facet_wrap( ~subject )
pp5 <- cleanPlot(pp5)
pp5

pp6 <- ggplot( psdData, aes(as.numeric(trialInSubAndCond:stimDurationFac), res, colour=trialInSubAndCond) )
pp6 <- pp6 + geom_point() + geom_line( aes(as.numeric(trialInSubAndCond:stimDurationFac), res, group=trialInSub) )
pp6 <- pp6 + facet_grid( subject~oddball )
pp6 <- cleanPlot(pp6)
pp6

plot( fm3.lme, resid(., type = "normalized") ~ stimDuration, abline = 0 )
plot( fm3.lme, resid(., type = "normalized") ~ fitted(.), abline = 0 )

plot( fm3.lme, resid(., type = "normalized") ~ stimDuration|subject, abline = 0 )
plot( fm3.lme, resid(., type = "normalized") ~ fitted(.)|subject, abline = 0 )

plot(ACF(fm3.lme, maxLag = 10, resType="n"), alpha = 0.05)
plot(ACF(fm3.lme, maxLag = 200, resType="n"), alpha = 0.05)

plot(Variogram( fm3.lme, form = ~ stimDuration ))
plot(Variogram( fm3.lme, form = ~ stimDuration, resType="n", robust=T ))


##############################################################################################
##############################################################################################

fm2.lme <- update(fm1.lme, weights = varPower(form=~stimDuration))
plot(ACF(fm2.lme, maxLag = 180, resType="p"), alpha = 0.01)
plot(augPred(fm2.lme), col.line = 'black')
plot( fm2.lme, resid(., type="n") ~ stimDuration|subject, abline = 0 )
plot( fm2.lme, resid(., type="n") ~ stimDuration, abline = 0 )

psdData$fitted2  <- fitted(fm2.lme)
psdData$res2     <- residuals(fm2.lme, type="normalized")

pp7 <- ggplot( psdData, aes(stimDuration, res2, colour=oddball) )
pp7 <- pp7 + geom_point() + geom_line( aes(stimDuration, res2, group=trialInSub) )
pp7 <- pp7 + facet_wrap( ~subject )
pp7 <- cleanPlot(pp7)
pp7

pp8 <- ggplot( psdData, aes(as.numeric(trialInSubAndCond:stimDurationFac), res2, colour=trialInSubAndCond) )
pp8 <- pp8 + geom_point() + geom_line( aes(as.numeric(trialInSubAndCond:stimDurationFac), res2, group=trialInSub) )
pp8 <- pp8 + facet_grid( subject~oddball )
pp8 <- cleanPlot(pp8)
pp8

###################################################################################################################
###################################################################################################################

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

