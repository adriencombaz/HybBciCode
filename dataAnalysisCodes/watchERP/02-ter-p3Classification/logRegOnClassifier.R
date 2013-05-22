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


#################################################################################################################

lmH3 <- lmer( correctness ~ frequency * classifier + ( 1 | subject ) + ( 1 | nRep ), data = accData1, family = binomial )
lmH2 <- lmer( correctness ~ frequency + classifier + ( 1 | subject ) + ( 1 | nRep ), data = accData1, family = binomial )
lmH1b <- lmer( correctness ~ classifier + ( 1 | subject ) + ( 1 | nRep ), data = accData1, family = binomial )
lmH1a <- lmer( correctness ~ frequency + ( 1 | subject ) + ( 1 | nRep ), data = accData1, family = binomial )
lmH0 <- lmer( correctness ~ ( 1 | subject ) + ( 1 | nRep ), data = accData1, family = binomial )

anova( lmH0, lmH1a, lmH2, lmH3 )
anova( lmH0, lmH1b, lmH2, lmH3 )


