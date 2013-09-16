setwd("d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciCode/dataAnalysisCodes/watchERP/04-watchSSVEP-PSD/nlmeScripts/timeSerieWithCond/")
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

psdDataGp <- groupedData(sqrtPsd ~ stimDuration | subject/trialInSub, data = psdData)
# plot(psdData)
# plot(psdData, displayLevel="subject")

fm1.lme <- lme(
  sqrtPsd ~ stimDuration*oddball
  , data = psdDataGp
  , random =  ~stimDuration | subject
  #   , random =  ~stimDuration | subject/oddball
#   , random = list(subject=pdDiag(~stimDuration))
#   , random = list(subject=pdDiag(~stimDuration), stimDurationFac=~1)
#   , random = list( subject=pdBlocked(list(pdCompSymm(~trialInSub))) )
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

#############################################################################################################

fm3.lme <- update(fm1.lme, corr = corCompSymm(form=~1|subject/oddball)) 
fm3.lme <- update(fm1.lme, corr = corCompSymm(form=~stimDuration|subject/oddball)) 
fm3.lme <- update(fm1.lme, corr = corARMA(form=~1|subject/oddball, p=1)) # INTERESTING!!
fm3.lme <- update(fm1.lme, corr = corARMA(form=~stimDuration|subject/oddball/trial, p=1)) 
fm3.lme <- update(fm1.lme, corr = corCAR1(form=~1|subject/oddball))  # INTERESTING!!
fm3.lme <- update(fm1.lme, corr = corCAR1(form=~stimDuration|subject/oddball/trial))


fm3.lme <- update(fm1.lme, corr = corCompSymm(form=~1|subject/trialInSub)) 
fm3.lme <- update(fm1.lme, corr = corCompSymm(form=~stimDuration|subject/trialInSub)) 
fm3.lme <- update(fm1.lme, corr = corARMA(form=~1|subject/trialInSub, p=1)) 
fm3.lme <- update(fm1.lme, corr = corARMA(form=~stimDuration|subject/trialInSub, p=1)) 
fm3.lme <- update(fm1.lme, corr = corCAR1(form=~1|subject/trialInSub)) 
fm3.lme <- update(fm1.lme, corr = corCAR1(form=~stimDuration|subject/trialInSub)) 


cs1 <- corCAR1(form=~1|subject/trialInSub)
cs1a <- Initialize(cs1, data=psdData)
m1<-corMatrix(cs1a)
cs1 <- corCAR1(form=~stimDuration|subject/trialInSub)
cs1a <- Initialize(cs1, data=psdData)
m2<-corMatrix(cs1a)
identical(m1, m2)

fm3.lme <- update(fm1.lme, corr = corARMA(form=~stimDuration|subject/trialInSub, p=1)) 
fm3.lme <- update(fm1.lme, corr = corARMA(form=~stimDuration|subject/trialInSub, p=2)) 
fm3.lme <- update(fm1.lme, corr = corARMA(form=~stimDuration|subject/trialInSub, q=1)) 
fm3.lme <- update(fm1.lme, corr = corARMA(form=~stimDuration|subject/trialInSub, q=2)) 
fm3.lme <- update(fm1.lme, corr = corARMA(form=~stimDuration|subject/trialInSub, q=3)) 
fm3.lme <- update(fm1.lme, corr = corARMA(form=~stimDuration|subject/trialInSub, q=4)) 
fm3.lme <- update(fm1.lme, corr = corARMA(form=~stimDuration|subject/trialInSub, q=5)) 
fm3.lme <- update(fm1.lme, corr = corARMA(form=~stimDuration|subject/trialInSub, q=6)) 
fm3.lme <- update(fm1.lme, corr = corARMA(form=~stimDuration|subject/trialInSub, p=1, q=1)) 
fm3.lme <- update(fm1.lme, corr = corCAR1(form=~stimDuration|subject/trialInSub)) 
fm3.lme <- update(fm1.lme, corr = corCAR1(value=0.4, form=~stimDuration|subject/trialInSub)) 
fm3.lme <- update(fm1.lme, corr = corCAR1(value=0.6, form=~stimDuration|subject/trialInSub)) 
fm3.lme <- update(fm1.lme, corr = corCAR1(value=0.8, form=~stimDuration|subject/trialInSub)) 
fm3.lme <- update(fm1.lme, corr = corExp(form = ~ stimDuration|subject/trialInSub)) 
fm4.lme <- update(fm1.lme, corr = corExp(form = ~ stimDuration|subject/trialInSub, nugget=T)) 
fm3.lme <- update(fm1.lme, corr = corRatio(form = ~ stimDuration|subject/trialInSub)) 
fm3.lme <- update(fm1.lme, corr = corLin(form = ~ stimDuration|subject/trialInSub)) 
fm3.lme <- update(fm1.lme, corr = corSpher(form = ~ stimDuration|subject/trialInSub)) 
fm3.lme <- update(fm1.lme, corr = corGaus(form = ~ stimDuration|subject/trialInSub)) 

summary(fm3.lme)
fm3.lme$apVar

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



fmH1.lme <- lme(
  sqrtPsd ~ stimDuration*oddball
  , data = psdDataGp
  , random =  ~stimDuration | subject
  , control = list(opt="optim")
  , corr = corCAR1(form=~stimDuration|subject/trialInSub)
  , method = "ML"
)

fmH0.lme <- lme(
  sqrtPsd ~ stimDuration
  , data = psdDataGp
  , random =  ~stimDuration | subject
  , control = list(opt="optim")
  , corr = corCAR1(form=~stimDuration|subject/trialInSub)
  , method = "ML"
)

anova(fmH1.lme, fmH0.lme)