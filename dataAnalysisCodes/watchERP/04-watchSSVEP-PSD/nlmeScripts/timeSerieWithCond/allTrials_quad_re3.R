setwd("d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciCode/dataAnalysisCodes/watchERP/04-watchSSVEP-PSD/nlmeScripts/timeSerieWithCond/")
source("initData.R")

##############################################################################################
##############################################################################################
pp2 <- ggplot( psdData, aes(stimDuration, psd, colour=oddball) )
pp2 <- pp2 + geom_point() + geom_line( aes(stimDuration, psd, group=trialInSub) )
pp2 <- pp2 + facet_wrap( ~subject, scale="free_y" )
pp2 <- cleanPlot(pp2)
pp2

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

psdDataGp <- groupedData(psd ~ stimDuration | subject/oddball/trialInSubAndCond, data = psdData)

fm1.lme <- lme(
#   psd ~ (stimDuration+I(stimDuration^2))*oddball
  psd ~ (stimDuration+I(stimDuration^2)) + (stimDuration+I(stimDuration^2)):oddball
  , data = psdDataGp
#   , random = ~(stimDuration+I(stimDuration^2))|subject/stimDurationFac
  , random = ~1|subject/stimDurationFac
#   , random = list(subject=~stimDuration/oddball, stimDurationFac=~1)
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

pp4 <- ggplot( psdData, aes(stimDuration, psd, colour=oddball) )
pp4 <- pp4 + geom_point(size=1) + geom_line( aes(stimDuration, psd, group=trialInSub) , linetype=2, size=0.3)
pp4 <- pp4 + geom_point() + geom_line( aes(stimDuration, fitted, group=oddball), size=2 )
pp4 <- pp4 + facet_wrap( ~subject, scale="free_y" )
# pp4 <- pp4 + facet_wrap( ~subject )
pp4 <- cleanPlot(pp4)
pp4

pp4b <- ggplot( psdData, aes(stimDuration, psd, colour=oddball) )
pp4b <- pp4b + geom_point(size=1)
pp4b <- pp4b + geom_point() + geom_line( aes(stimDuration, fitted, group=trialInSub) )
pp4b <- pp4b + facet_wrap( ~subject, scale="free_y" )
# pp4b <- pp4b + facet_wrap( ~subject )
pp4b <- cleanPlot(pp4b)
pp4b

pp5 <- ggplot( psdData, aes(stimDuration, res, colour=oddball) )
pp5 <- pp5 + geom_point() + geom_line( aes(stimDuration, res, group=trialInSub) )
pp5 <- pp5 + facet_wrap( ~subject, scale="free_y"  )
pp5 <- cleanPlot(pp5)
pp5

pp6 <- ggplot( psdData, aes(as.numeric(trialInSubAndCond:stimDurationFac), res, colour=trialInSubAndCond) )
pp6 <- pp6 + geom_point() #+ geom_line( aes(as.numeric(trialInSubAndCond:stimDurationFac), res, group=trialInSub) )
pp6 <- pp6 + facet_grid( subject~oddball, scale="free_y" )
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

plot(ACF(fm1.lme, maxLag = 18, resType="n"), alpha = 0.01)
plot(ACF(fm1.lme, resType="n"), alpha = 0.01)

plot(Variogram( fm1.lme, form = ~ stimDuration ))
plot(Variogram( fm0.lme, form = ~ stimDuration, resType="n", robust=T ))

###############################################################################################################
###############################################################################################################

# fm3.lme <- update(fm1.lme, corr = corCAR1(form=~(stimDuration+I(stimDuration^2))|subject/oddball/trialInSubAndCond)) 
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

fm3.lme <- update(fm1.lme, weights = varPower(form=~stimDuration)) 


summary(fm3.lme)
fm3.lme$apVar

psdData$fitted2  <- fitted(fm3.lme)
psdData$res2     <- residuals(fm3.lme, type="normalized")

pp7 <- ggplot( psdData, aes(stimDuration, res2, colour=oddball) )
pp7 <- pp7 + geom_point() + geom_line( aes(stimDuration, res2, group=trialInSub) )
pp7 <- pp7 + facet_wrap( ~subject, scale="free_y" )
pp7 <- cleanPlot(pp7)
pp7

pp8 <- ggplot( psdData, aes(as.numeric(trialInSubAndCond:stimDurationFac), res2, colour=trialInSubAndCond) )
pp8 <- pp8 + geom_point() + geom_line( aes(as.numeric(trialInSubAndCond:stimDurationFac), res2, group=trialInSub) )
pp8 <- pp8 + facet_grid( subject~oddball, scale="free_y" )
pp8 <- cleanPlot(pp8)
pp8

plot( fm3.lme, resid(., type = "normalized") ~ stimDuration, abline = 0 )
plot( fm3.lme, resid(., type = "normalized") ~ fitted(.), abline = 0 )
plot( fm3.lme, resid(., type = "normalized") ~ stimDuration|subject, abline = 0 )
plot( fm3.lme, resid(., type = "normalized") ~ fitted(.)|subject, abline = 0 )

plot(ACF(fm3.lme, maxLag = 10, resType="n"), alpha = 0.05)
plot(ACF(fm3.lme, maxLag = 200, resType="n"), alpha = 0.01)

plot(Variogram( fm3.lme, form = ~ stimDuration ))
plot(Variogram( fm3.lme, form = ~ stimDuration, resType="n", robust=T ))


###################################################################################################################
###################################################################################################################


###################################################################################################################
###################################################################################################################
###################################################################################################################
