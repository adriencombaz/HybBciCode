setwd("d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciCode/dataAnalysisCodes/watchERP/02-ter-p3Classification/")
rm(list = ls())

library(ggplot2)
library(lme4)
library(LMERConvenienceFunctions)
library(languageR)

source("createDataFrame.R")
source("cleanPlot.R")

#################################################################################################################

accData1 <- subset(accData, classifier=="normal")
accData1 <- subset(accData1, select = -c(classifier, foldTest))

str(accData1)
summary(accData1)

#################################################################################################################

pp <- ggplot( accData1, aes(nRep, correctness, colour=condition, shape=condition) )
pp <- pp + stat_summary(fun.y = mean, geom="point",  position = position_jitter(w = 0.2, h = 0), size = 3)
# pp <- pp + stat_summary(fun.y = mean, geom="point", position = position_dodge(.5))
# pp <- pp + stat_summary(fun.data = mean_cl_normal, geom = "pointrange", width = 0.2, position = position_dodge(.5), size = 1)
pp <- pp + facet_wrap( ~subject ) 
pp <- cleanPlot(pp)
pp <- pp + theme(legend.position=c(0.8334,0.1667))
pp

#################################################################################################################

f0Vs857_10_12_15    = c(-4, 1, 1, 1, 1)     # oddball vs. hybrid
f857Vs10_12_15      = c(0, -3, 1, 1, 1)     # hybrid-8-57Hz vs. hybrid-10-12-15-Hz
f10Vs12_15          = c(0, 0, -2, 1, 1)     # hybrid-10Hz vs. hybrid-12-15-Hz
f12Vs15             = c(0, 0, 0, -1, 1)     # hybrid-12Hz vs. hybrid-15-Hz
contrasts(accData1$frequency) <- cbind(
  f0Vs857_10_12_15
  , f857Vs10_12_15
  , f10Vs12_15
  , f12Vs15
)


#################################################################################################################

# lmH4 <- lmer( correctness ~ nRep*frequency + ( correctness | subject ), data = accData1, family = binomial )
# lmH3 <- lmer( correctness ~ nRep*frequency + ( 1 | subject ), data = accData1, family = binomial )
# lmH2 <- lmer( correctness ~ nRep + frequency + ( 1 | subject ), data = accData1, family = binomial )
# lmH1a <- lmer( correctness ~ nRep + ( 1 | subject ), data = accData1, family = binomial )
# lmH1b <- lmer( correctness ~ frequency + ( 1 | subject ), data = accData1, family = binomial )
# lmH0 <- lmer( correctness ~ ( 1 | subject ), data = accData1, family = binomial )
# 
# anova( lmH0, lmH1a, lmH2, lmH3 ) #, lmH4 )
# anova( lmH0, lmH1b, lmH2, lmH3 ) #, lmH4 )

#################################################################################################################

accData1$nRepFac <- as.factor(accData1$nRep)
lmH3 <- lmer( correctness ~ frequency * nRepFac + ( 1 | subject/nRepFac ), data = accData1, family = binomial )
lmH2 <- lmer( correctness ~ frequency + nRepFac + ( 1 | subject/nRepFac ), data = accData1, family = binomial )
lmH1a <- lmer( correctness ~ frequency + ( 1 | subject/nRepFac ), data = accData1, family = binomial )
lmH1b <- lmer( correctness ~ nRepFac + ( 1 | subject/nRepFac ), data = accData1, family = binomial )
lmH0 <- lmer( correctness ~ ( 1 | subject/nRepFac ), data = accData1, family = binomial )

anova( lmH0, lmH1a, lmH2, lmH3 ) #, lmH4 )
anova( lmH0, lmH1b, lmH2, lmH3 ) #, lmH4 )


#################################################################################################################

allSubs   <- levels(accData1$subject)
allFreqs  <- levels(accData1$frequency)
allNreps  <- unique(accData1$nRep)
nSubs   <- length(allSubs)
nFreqs  <- length(allFreqs)
nReps   <- length(allNreps)
ID     <- rep(NA, length(accData1$subject))
count <- 1
for (iS in 1:nSubs){
  for (iF in 1:nFreqs){
    for (iR in 1:nReps){
        
        temp <- subset(accData1, subject == allSubs[iS])
        temp <- subset(temp, frequency == allFreqs[iF])
        temp <- subset(temp, nRep == allNreps[iR])
        
        for (iT in 1:length(temp$subject)){
          ID[count] <- 1000*iS + allNreps[iR]
          count <- count+1          
        }
        
    }
  }
}

accData1$ID <- ID

lmH13 <- lmer( correctness ~ frequency * nRep + ( 1 | subject ) + ( 1 | ID ), data = accData1, family = binomial )
lmH12 <- lmer( correctness ~ frequency + nRep + ( 1 | subject ) + ( 1 | ID ), data = accData1, family = binomial )
lmH11a <- lmer( correctness ~ frequency + ( 1 | subject ) + ( 1 | ID ), data = accData1, family = binomial )
lmH11b <- lmer( correctness ~ nRep + ( 1 | subject ) + ( 1 | ID ), data = accData1, family = binomial )
lmH10 <- lmer( correctness ~ ( 1 | subject ) + ( 1 | ID ), data = accData1, family = binomial )

anova( lmH10, lmH11a, lmH12, lmH13 ) #, lmH4 )
anova( lmH10, lmH11b, lmH12, lmH13 ) #, lmH4 )

