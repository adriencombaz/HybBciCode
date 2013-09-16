setwd("d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciCode/dataAnalysisCodes/watchERP/04-watchSSVEP-PSD/")
rm(list = ls())
library(ggplot2)
library(reshape2)
library(grid)
library(plyr)
library(nlme)
library(lattice)

####################################################################################################
####################################################################################################

# subjects  <- c("S1", "S2", "S3", "S4", "S5", "S6", "S7", "S8")
# trials    <- c("tr01", "tr02", "tr03", "tr04", "tr05", "tr06", "tr07", "tr08", "tr09", "tr10", "tr11", "tr12")
nS <- 8#ength(subjects)
nT <- 12#length(trials)
time      <- 1:14

intercept <- 100
subIntercept_std <- 15
subjectMeans <- rnorm(nS, mean=0, sd=subIntercept_std)

meanTrialIntercept_std <- 10 # subject-average deviation from the mean
stdTrialIntercept_std <- 2   # 
trialIntercept_std <- rnorm(nS, mean=meanTrialIntercept_std, sd=stdTrialIntercept_std)
trialDeviations <- matrix(data=NA, nrow=nS, ncol=nT)
for (iS in 1:nS){
  trialDeviations[iS,] <- rnorm(nT, mean=0, sd=trialIntercept_std[iS])
}


####################################################################################################
####################################################################################################

value   <- vector(mode="numeric", length=nS*nT)
subject <- vector(mode="character", length=nS*nT)
trial   <- vector(mode="character", length=nS*nT)
for (iS in 1:nS){
  for (iTr in 1:nT){
    
    value[(iS-1)*nT+iTr]    <- intercept + subjectMeans[iS] + trialDeviations[iS, iTr]
    subject[(iS-1)*nT+iTr]  <- iS
    trial[(iS-1)*nT+iTr]    <- iTr
    
  }
}

art <- data.frame(subject, trial, value)
art$subject <- as.factor(art$subject)
art$trial <- as.factor(art$trial)
art$trInSub <- art$subject : art$trial

####################################################################################################
####################################################################################################
pp <- ggplot( art, aes(subject, value ) )
pp <- pp + stat_summary(fun.y=mean, geom="point", colour="red", size=5)
pp <- pp + geom_point() 
pp

varList <- c( "subject", "value" )
artSubjectMean <- ddply( art, varList, summarise, value = mean(value) )



####################################################################################################
####################################################################################################
artGp <- groupedData(value ~ 1 | subject/trial, data = art)

fm1.lme<-lme(value~1, data=art, random=~1|subject)
plot(fm1.lme)
plot( fm1.lme, resid(.) ~ fitted(.)|subject, abline = 0 )
plot(ACF(fm1.lme, maxLag = 10, resType="n"), alpha = 0.01)
plot(Variogram( fm1.lme))
plot(Variogram( fm1.lme, resType="n", robust=T ))

