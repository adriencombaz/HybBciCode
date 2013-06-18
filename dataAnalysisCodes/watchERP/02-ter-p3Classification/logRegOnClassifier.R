setwd("d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciCode/dataAnalysisCodes/watchERP/02-ter-p3Classification/")
rm(list = ls())

library(ggplot2)
library(lme4)
library(LMERConvenienceFunctions)
library(languageR)

source("createDataFrame.R")
source("cleanPlot.R")

#################################################################################################################

accData1 <- subset(accData, frequency!=0)
accData1 <- subset(accData1, select = -c(foldTest))
accData1$frequency <- droplevels(accData1)$frequency
accData1$condition <- droplevels(accData1)$condition
accData1$nRepFac <- as.factor(accData1$nRep)

str(accData1)
summary(accData1)

#################################################################################################################


pp <- ggplot( accData1, aes(nRep, correctness, colour=classifier, shape=condition) )
pp <- pp + stat_summary(fun.y = mean, geom="point",  position = position_jitter(w = 0.2, h = 0), size = 3)
# pp <- pp + stat_summary(fun.y = mean, geom="point", position = position_dodge(.5))
# pp <- pp + stat_summary(fun.data = mean_cl_normal, geom = "pointrange", width = 0.2, position = position_dodge(.5), size = 1)
pp <- pp + facet_wrap( ~subject ) 
pp <- cleanPlot(pp)
pp <- pp + theme(legend.position=c(0.8334,0.1667))
pp

#################################################################################################################
factorList <- c("classifier", "nRep", "frequency")
outcome <- "correctness"
source("d:/KULeuven/PhD/rLibrary/plotFactorMeans_InteractionGraphs.R")

dataframe <- accData1
plotFactorMeans_InteractionGraphs(dataframe, factorList, outcome)

#################################################################################################################

f857Vs10_12_15      = c(-3, 1, 1, 1)     # hybrid-8-57Hz vs. hybrid-10-12-15-Hz
f10Vs12_15          = c(0, -2, 1, 1)     # hybrid-10Hz vs. hybrid-12-15-Hz
f12Vs15             = c(0, 0, -1, 1)     # hybrid-12Hz vs. hybrid-15-Hz
contrasts(accData1$frequency) <- cbind(
  f857Vs10_12_15
  , f10Vs12_15
  , f12Vs15
)

#################################################################################################################
tempData <- subset(accData1, nRep != 10)
tempData$nRep <- droplevels(tempData)$nRep
lmHTest <- lmer( correctness ~ nRep * classifier * frequency + (1 | subject) + ( 1 | nRepWithinSub ), data = tempData, family = binomial )

#################################################################################################################
lmH004 <- lmer( correctness ~ nRep * classifier * frequency + (1 | subject) + ( 1 | nRepWithinSub ), data = accData1, family = binomial )

lmH003 <- lmer( correctness ~ nRep + classifier + frequency + (1 | subject) + ( 1 | nRepWithinSub ), data = accData1, family = binomial )

lmH002c <- lmer( correctness ~ nRep + frequency + (1 | subject) + ( 1 | nRepWithinSub ), data = accData1, family = binomial )
lmH002b <- lmer( correctness ~ classifier + frequency + (1 | subject) + ( 1 | nRepWithinSub ), data = accData1, family = binomial )
lmH002a <- lmer( correctness ~ nRep + classifier + (1 | subject) + ( 1 | nRepWithinSub ), data = accData1, family = binomial )

lmH001c <- lmer( correctness ~ nRep + (1 | subject) + ( 1 | nRepWithinSub ), data = accData1, family = binomial )
lmH001b <- lmer( correctness ~ frequency + (1 | subject) + ( 1 | nRepWithinSub ), data = accData1, family = binomial )
lmH001a <- lmer( correctness ~ classifier + (1 | subject) + ( 1 | nRepWithinSub ), data = accData1, family = binomial )

lmH000 <- lmer( correctness ~ (1 | subject) + ( 1 | nRepWithinSub ), data = accData1, family = binomial )

anova( lmH000, lmH001a, lmH002a, lmH003, lmH004 )
anova( lmH000, lmH001a, lmH002b, lmH003, lmH004 )
anova( lmH000, lmH001b, lmH002b, lmH003, lmH004 )
anova( lmH000, lmH001b, lmH002c, lmH003, lmH004 )
anova( lmH000, lmH001c, lmH002a, lmH003, lmH004 )
anova( lmH000, lmH001c, lmH002c, lmH003, lmH004 )

#################################################################################################################

lmH104 <- lmer( correctness ~ nRepFac * classifier * frequency + (1 | subject) + ( 1 | nRepWithinSub ), data = accData1, family = binomial )

lmH103 <- lmer( correctness ~ nRepFac + classifier + frequency + (1 | subject) + ( 1 | nRepWithinSub ), data = accData1, family = binomial )

lmH102c <- lmer( correctness ~ nRepFac + frequency + (1 | subject) + ( 1 | nRepWithinSub ), data = accData1, family = binomial )
lmH102b <- lmer( correctness ~ classifier + frequency + (1 | subject) + ( 1 | nRepWithinSub ), data = accData1, family = binomial )
lmH102a <- lmer( correctness ~ nRepFac + classifier + (1 | subject) + ( 1 | nRepWithinSub ), data = accData1, family = binomial )

lmH101c <- lmer( correctness ~ nRepFac + (1 | subject) + ( 1 | nRepWithinSub ), data = accData1, family = binomial )
lmH101b <- lmer( correctness ~ frequency + (1 | subject) + ( 1 | nRepWithinSub ), data = accData1, family = binomial )
lmH101a <- lmer( correctness ~ classifier + (1 | subject) + ( 1 | nRepWithinSub ), data = accData1, family = binomial )

lmH100 <- lmer( correctness ~ (1 | subject) + ( 1 | nRepWithinSub ), data = accData1, family = binomial )

anova( lmH100, lmH101a, lmH102a, lmH103, lmH104 )
anova( lmH100, lmH101a, lmH102b, lmH103, lmH104 )
anova( lmH100, lmH101b, lmH102b, lmH103, lmH104 )
anova( lmH100, lmH101b, lmH102c, lmH103, lmH104 )
anova( lmH100, lmH101c, lmH102a, lmH103, lmH104 )
anova( lmH100, lmH101c, lmH102c, lmH103, lmH104 )

