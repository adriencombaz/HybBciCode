setwd("d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciCode/dataAnalysisCodes/watchERP/02-ter-p3Classification/")
rm(list = ls())

library(ggplot2)
library(lme4)
library(LMERConvenienceFunctions)
library(languageR)

# source("createDataFrame.R")
source("createDataFrame_2RunsForTrain.R")
source("cleanPlot.R")

#################################################################################################################

# accData1 <- subset(accData, classifier=="normal")
# accData1 <- subset(accData1, select = -c(classifier, foldTest))
varList <- c("subject", "condition", "roundNb", "correctness", "frequency", "nRep", "nRepWithinSub")
accData1 <- accData[ accData$classifier=="normal", names(accData1) %in% varList ]
accData1$nRepFac <- as.factor(accData1$nRep)

str(accData1)
summary(accData1)

#################################################################################################################

pp <- ggplot( accData1, aes(nRep, correctness, colour=condition, shape=condition) )
# pp <- pp + stat_summary(fun.y = mean, geom="point",  position = position_jitter(w = 0.2, h = 0), size = 3)
# pp <- pp + stat_summary(fun.y = mean, geom="point", position = position_dodge(.5))
pp <- pp + stat_summary(fun.data = mean_cl_normal, geom = "pointrange", width = 0.2, position = position_dodge(.5), size = 1)
pp <- pp + facet_wrap( ~subject ) 
pp <- cleanPlot(pp)
pp <- pp + theme(legend.position=c(0.8334,0.1667))
pp

#################################################################################################################

source("d:/KULeuven/PhD/rLibrary/plotFactorMeans_InteractionGraphs.R")
plotFactorMeans_InteractionGraphs(accData1, c("nRep", "frequency"), "correctness")

#################################################################################################################

# f0Vs857_10_12_15    = c(-4, 1, 1, 1, 1)     # oddball vs. hybrid
# f857Vs10_12_15      = c(0, -3, 1, 1, 1)     # hybrid-8-57Hz vs. hybrid-10-12-15-Hz
# f10Vs12_15          = c(0, 0, -2, 1, 1)     # hybrid-10Hz vs. hybrid-12-15-Hz
# f12Vs15             = c(0, 0, 0, -1, 1)     # hybrid-12Hz vs. hybrid-15-Hz
# contrasts(accData1$frequency) <- cbind(
#   f0Vs857_10_12_15
#   , f857Vs10_12_15
#   , f10Vs12_15
#   , f12Vs15
# )

Rep1VsRep2 = c(-1, 1, 0, 0, 0, 0, 0, 0, 0, 0)
Rep2VsRep3 = c(0, -1, 1, 0, 0, 0, 0, 0, 0, 0)
Rep3VsRep4 = c(0, 0, -1, 1, 0, 0, 0, 0, 0, 0)
Rep4VsRep5 = c(0, 0, 0, -1, 1, 0, 0, 0, 0, 0)
Rep5VsRep6 = c(0, 0, 0, 0, -1, 1, 0, 0, 0, 0)
Rep6VsRep7 = c(0, 0, 0, 0, 0, -1, 1, 0, 0, 0)
Rep7VsRep8 = c(0, 0, 0, 0, 0, 0, -1, 1, 0, 0)
Rep8VsRep9 = c(0, 0, 0, 0, 0, 0, 0, -1, 1, 0)
Rep9VsRep10 = c(0, 0, 0, 0, 0, 0, 0, 0, -1, 1)

contrasts(accData1$nRepFac) <- cbind(
  Rep1VsRep2
  , Rep2VsRep3
  , Rep3VsRep4
  , Rep4VsRep5
  , Rep5VsRep6
  , Rep6VsRep7
  , Rep7VsRep8
  , Rep8VsRep9
  , Rep9VsRep10
)

#################################################################################################################

# lmH003 <- lmer( correctness ~ frequency * nRepFac + ( 1 | subject/nRepFac ), data = accData1, family = binomial )
# lmH002 <- lmer( correctness ~ frequency + nRepFac + ( 1 | subject/nRepFac ), data = accData1, family = binomial )
# lmH001a <- lmer( correctness ~ frequency + ( 1 | subject/nRepFac ), data = accData1, family = binomial )
# lmH001b <- lmer( correctness ~ nRepFac + ( 1 | subject/nRepFac ), data = accData1, family = binomial )
# lmH000 <- lmer( correctness ~ ( 1 | subject/nRepFac ), data = accData1, family = binomial )
# 
# anova( lmH000, lmH001a, lmH002, lmH003 ) #, lmH4 )
# anova( lmH000, lmH001b, lmH002, lmH003 ) #, lmH4 )

######################
## IS EQUIVALENT TO ## 
######################

lmH013 <- lmer( correctness ~ frequency * nRepFac + (1 | subject) + ( 1 | nRepWithinSub ), data = accData1, family = binomial )
# lmH013a <- lmer( correctness ~ frequency + nRepFac + frequency:nRepFac + (1 | subject) + ( 1 | nRepWithinSub ), data = accData1, family = binomial )
lmH012 <- lmer( correctness ~ frequency + nRepFac + (1 | subject) + ( 1 | nRepWithinSub ), data = accData1, family = binomial )
lmH011a <- lmer( correctness ~ frequency + (1 | subject) + ( 1 | nRepWithinSub ), data = accData1, family = binomial )
lmH011b <- lmer( correctness ~ nRepFac + (1 | subject) + ( 1 | nRepWithinSub ), data = accData1, family = binomial )
lmH010 <- lmer( correctness ~ (1 | subject) + ( 1 | nRepWithinSub ), data = accData1, family = binomial )

anova( lmH010, lmH011a, lmH012, lmH013 ) #, lmH4 )
anova( lmH010, lmH011b, lmH012, lmH013 ) #, lmH4 )

#################################################################################################################

# lmH103 <- lmer( correctness ~ frequency * nRep + ( 1 | subject/nRepFac ), data = accData1, family = binomial )
# lmH102 <- lmer( correctness ~ frequency + nRep + ( 1 | subject/nRepFac ), data = accData1, family = binomial )
# lmH101a <- lmer( correctness ~ frequency + ( 1 | subject/nRepFac ), data = accData1, family = binomial )
# lmH101b <- lmer( correctness ~ nRep + ( 1 | subject/nRepFac ), data = accData1, family = binomial )
# lmH100 <- lmer( correctness ~ ( 1 | subject/nRepFac ), data = accData1, family = binomial )
# 
# anova( lmH100, lmH101a, lmH102, lmH103 ) #, lmH4 )
# anova( lmH100, lmH101b, lmH102, lmH103 ) #, lmH4 )

######################
## IS EQUIVALENT TO ## 
######################

lmH113 <- lmer( correctness ~ frequency * nRep + (1 | subject) + ( 1 | nRepWithinSub ), data = accData1, family = binomial )
lmH112 <- lmer( correctness ~ frequency + nRep + (1 | subject) + ( 1 | nRepWithinSub ), data = accData1, family = binomial )
lmH111a <- lmer( correctness ~ frequency + (1 | subject) + ( 1 | nRepWithinSub ), data = accData1, family = binomial )
lmH111b <- lmer( correctness ~ nRep + (1 | subject) + ( 1 | nRepWithinSub ), data = accData1, family = binomial )
lmH110 <- lmer( correctness ~ (1 | subject) + ( 1 | nRepWithinSub ), data = accData1, family = binomial )

anova( lmH110, lmH111a, lmH112, lmH113 ) #, lmH4 )
anova( lmH110, lmH111b, lmH112, lmH113 ) #, lmH4 )


#################################################################################################################
# accData1$ssvepOn <- 1
# accData1$ssvepOn[accData1$frequency=="0"] <- 0
# accData1$ssvepOn <- as.factor(accData1$ssvepOn)
# 
# pp <- ggplot( accData1, aes(nRep, correctness, colour=ssvepOn, shape=ssvepOn) )
# pp <- pp + stat_summary(fun.data = mean_cl_normal, geom = "pointrange", width = 0.2, position = position_dodge(.5), size = 1)
# pp <- pp + facet_wrap( ~subject ) 
# pp <- cleanPlot(pp)
# pp <- pp + theme(legend.position=c(0.8334,0.1667))
# pp