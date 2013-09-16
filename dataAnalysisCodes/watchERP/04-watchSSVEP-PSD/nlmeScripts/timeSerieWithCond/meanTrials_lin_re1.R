setwd("d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciCode/dataAnalysisCodes/watchERP/04-watchSSVEP-PSD/nlmeScripts/timeSerieWithCond/")
source("initData.R")

varList <- c( "subject", "oddball", "stimDuration", "stimDurationFac" )
psdDataMeanTrial <- ddply( psdData, varList, summarise, psd = mean(psd) )
psdDataMeanTrial$sqrtPsd <- sqrt(psdDataMeanTrial$psd)


##############################################################################################
##############################################################################################
pp2 <- ggplot( psdDataMeanTrial, aes(stimDuration, sqrtPsd, colour=oddball) )
pp2 <- pp2 + geom_point() + geom_line( aes(stimDuration, sqrtPsd, group=oddball) )
pp2 <- pp2 + facet_wrap( ~subject, scale="free_y" )
pp2 <- cleanPlot(pp2)
pp2

##############################################################################################
##############################################################################################
psdDataGp <- groupedData(sqrtPsd ~ stimDuration | subject/oddball, data = psdDataMeanTrial)


fm1.lme <- lme(
  sqrtPsd ~ stimDuration*oddball
  , data = psdDataGp
  , random = ~stimDuration|subject
  , control = list(opt="optim")
  , method = "REML"
)

# nSub<-length(unique(psdDataMeanTrial$subject))
# nOdd<-length(unique(psdDataMeanTrial$oddball))
# nTime<-length(unique(psdDataMeanTrial$stimDuration))
# mmr<-model.matrix(fm1.lme$modelStruct$reStruct, getData(fm1.lme))
# mmr<-mmr[1:(nOdd*nTime),]
# fixFitted <- model.matrix(formula(fm1.lme), getData(fm1.lme)) %*% fixef(fm1.lme)
# ranFitted <- vector(mode="numeric", length=length(fixFitted))
# ind <- 1
# for (iS in 1:length(unique(psdDataMeanTrial$subject))){
#   ranFitted[((iS-1)*nOdd*nTime+1) : (iS*nOdd*nTime)] = mmr %*% as.numeric(ranef(fm1.lme)[iS,])
# }
# fitted <- fixFitted+ranFitted
# 
# compFitted <- data.frame(fixFitted, fitted, fm1.lme$fitted)
# 
# resHome <- psdDataMeanTrial$psd-fitted
# sub <- resHome - residuals(fm1.lme)

# mmf<-model.matrix(formula(fm1.lme), getData(fm1.lme))
# mmr<-model.matrix(fm1.lme$modelStruct$reStruct, getData(fm1.lme))
# coef(fm1.lme)
# fixef(fm1.lme)
# ranef(fm1.lme)
# fm1.lme$apVar

plot(ranef(fm1.lme))

psdDataMeanTrial$fitted  <- fitted(fm1.lme)
psdDataMeanTrial$res     <- residuals(fm1.lme, type="normalized")

pp4 <- ggplot( psdDataMeanTrial, aes(stimDuration, sqrtPsd, colour=oddball) )
pp4 <- pp4 + geom_point() + geom_line( aes(stimDuration, fitted, group=oddball) )
pp4 <- pp4 + facet_wrap( ~subject )
pp4 <- cleanPlot(pp4)
pp4

pp5 <- ggplot( psdDataMeanTrial, aes(stimDuration, res, colour=oddball) )
pp5 <- pp5 + geom_point() #+ geom_line( aes(stimDuration, fitted, group=oddball) )
pp5 <- pp5 + facet_wrap( ~subject )
pp5 <- cleanPlot(pp5)
pp5

plot( fm1.lme, resid(., type = "normalized") ~ stimDuration, abline = 0 )
plot( fm1.lme, resid(., type = "normalized") ~ stimDuration|oddball, abline = 0 )
plot( fm1.lme, resid(., type = "normalized") ~ stimDuration|subject, abline = 0 )
plot( fm1.lme, resid(., type = "normalized") ~ stimDuration|subject*oddball, abline = 0 )

plot( fm1.lme, resid(., type = "normalized") ~ fitted(.), abline = 0 )
plot( fm1.lme, resid(., type = "normalized") ~ fitted(.)|oddball, abline = 0 )
plot( fm1.lme, resid(., type = "normalized") ~ fitted(.)|subject, abline = 0 )
plot( fm1.lme, resid(., type = "normalized") ~ fitted(.)|stimDuration, abline = 0 )
plot( fm2.lme, resid(., type = "normalized") ~ fitted(.)|stimDuration, abline = 0 )
plot( fm1.lme, resid(., type = "normalized") ~ fitted(.)|stimDuration*oddball, abline = 0 )
plot( fm1.lme, resid(., type = "normalized") ~ fitted(.)|subject*oddball, abline = 0 )

plot(ACF(fm1.lme, maxLag = 30, resType="n"), alpha = 0.01)
plot(ACF(fm1.lme, resType="n"), alpha = 0.01)

plot(Variogram( fm1.lme, form = ~ stimDuration ))
plot(Variogram( fm1.lme, form = ~ stimDuration, resType="n", robust=T ))

##############################################################################################
##############################################################################################
fm2.lme <- update(fm1.lme, weights = varPower(form=~stimDuration)) 
fm2.lme <- update(fm2.lme, corr = corARMA(form=~stimDuration|subject/oddball, p=1)) 

psdDataMeanTrial$fitted1  <- fitted(fm2.lme)
psdDataMeanTrial$res1     <- residuals(fm2.lme, type="normalized")

pp7 <- ggplot( psdDataMeanTrial, aes(stimDuration, res1, colour=oddball) )
pp7 <- pp7 + geom_point() #+ geom_line( aes(stimDuration, fitted, group=oddball) )
pp7 <- pp7 + facet_wrap( ~subject )
pp7 <- cleanPlot(pp7)
pp7

plot( fm2.lme, resid(., type = "normalized") ~ stimDuration, abline = 0 )
plot( fm2.lme, resid(., type = "normalized") ~ fitted(.), abline = 0 )

plot( fm2.lme, resid(., type = "normalized") ~ stimDuration|subject, abline = 0 )
plot( fm2.lme, resid(., type = "normalized") ~ fitted(.)|subject, abline = 0 )

plot(ACF(fm2.lme, maxLag = 10, resType="n"), alpha = 0.05)
plot(ACF(fm2.lme, maxLag = 200, resType="n"), alpha = 0.05)

plot(Variogram( fm2.lme, form = ~ stimDuration ))
plot(Variogram( fm2.lme, form = ~ stimDuration, resType="n", robust=T ))

##############################################################################################
##############################################################################################

fm3.lme <- update(fm1.lme, corr = corARMA(form=~stimDuration|subject/oddball, p=1)) 
fm3.lme <- update(fm1.lme, corr = corARMA(form=~stimDuration|subject/oddball, p=2)) 
fm3.lme <- update(fm1.lme, corr = corARMA(form=~stimDuration|subject/oddball, q=1)) 
fm3.lme <- update(fm1.lme, corr = corARMA(form=~stimDuration|subject/oddball, q=2)) 
fm3.lme <- update(fm1.lme, corr = corARMA(form=~stimDuration|subject/oddball, q=3)) 
fm3.lme <- update(fm1.lme, corr = corARMA(form=~stimDuration|subject/oddball, q=4)) 
fm3.lme <- update(fm1.lme, corr = corARMA(form=~stimDuration|subject/oddball, q=5)) 
fm3.lme <- update(fm1.lme, corr = corARMA(form=~stimDuration|subject/oddball, q=6)) 
fm3.lme <- update(fm1.lme, corr = corARMA(form=~stimDuration|subject/oddball, p=1, q=1)) 
fm3.lme <- update(fm1.lme, corr = corCAR1(form=~stimDuration|subject/oddball)) 
fm3.lme <- update(fm1.lme, corr = corCAR1(value=0.4, form=~stimDuration|subject/oddball)) 
fm3.lme <- update(fm1.lme, corr = corCAR1(value=0.6, form=~stimDuration|subject/oddball)) 
fm3.lme <- update(fm1.lme, corr = corCAR1(value=0.8, form=~stimDuration|subject/oddball)) 
fm3.lme <- update(fm1.lme, corr = corExp(form = ~ stimDuration|subject/oddball)) 
fm4.lme <- update(fm1.lme, corr = corExp(form = ~ stimDuration|subject/oddball, nugget=T)) 
fm3.lme <- update(fm1.lme, corr = corRatio(form = ~ stimDuration|subject/oddball)) 
fm3.lme <- update(fm1.lme, corr = corLin(form = ~ stimDuration|subject/oddball)) 
fm3.lme <- update(fm1.lme, corr = corSpher(form = ~ stimDuration|subject/oddball)) 
fm3.lme <- update(fm1.lme, corr = corGaus(form = ~ stimDuration|subject/oddball)) 

summary(fm3.lme)

psdDataMeanTrial$fitted2  <- fitted(fm3.lme)
psdDataMeanTrial$res2     <- residuals(fm3.lme, type="normalized")

pp7 <- ggplot( psdDataMeanTrial, aes(stimDuration, res2, colour=oddball) )
pp7 <- pp7 + geom_point() #+ geom_line( aes(stimDuration, fitted, group=oddball) )
pp7 <- pp7 + facet_wrap( ~subject )
pp7 <- cleanPlot(pp7)
pp7

plot( fm3.lme, resid(., type = "normalized") ~ stimDuration, abline = 0 )
plot( fm3.lme, resid(., type = "normalized") ~ fitted(.), abline = 0 )

plot( fm3.lme, resid(., type = "normalized") ~ stimDuration|subject, abline = 0 )
plot( fm3.lme, resid(., type = "normalized") ~ fitted(.)|subject, abline = 0 )

plot(ACF(fm3.lme, maxLag = 10, resType="n"), alpha = 0.05)
plot(ACF(fm3.lme, maxLag = 200, resType="n"), alpha = 0.05)

plot(Variogram( fm3.lme, form = ~ stimDuration ))
plot(Variogram( fm3.lme, form = ~ stimDuration, resType="n", robust=T ))

