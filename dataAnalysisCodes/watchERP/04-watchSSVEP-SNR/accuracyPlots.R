setwd("d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciCode/dataAnalysisCodes/watchERP/04-watchSSVEP-SNR/")
rm(list = ls())
library(ggplot2)
library(reshape2)
library(grid)

source("d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciCode/dataAnalysisCodes/deps/cleanPlot.R")
source("createSnrDatasetFnc.R")
# subsetChLabel <- c("ch-O", "ch-PO-O", "ch-P-PO-O", "ch-CP-P-PO-O", "ch-C-CP-P-PO-O", "ch-all")
# harmonicsLabel <- c("fund","fund-ha1")
subsetChLabel <- c("ch-P-PO-O")
harmonicsLabel <- c("fund-ha1")

snrData <- createSnrDatasetFnc(subsetChLabel, harmonicsLabel)
varList <- c( "subject", "run", "roundNb", "time" )
accData <- ddply( snrData, varList, summarize 
                  , targetFrequency = unique(targetFrequency)
                  , oddball = unique(oddball)
                  , correctness = ( unique(targetFrequency) == watchedFrequency[which.max(snr)] ) * 1 
)        

accData$timeFac <- as.factor(accData$time)


pp <- ggplot( accData, aes(time, correctness, colour=oddball ) )
pp <- pp + stat_summary(fun.y = mean, geom="point", position = position_dodge(0.2))
pp <- pp + stat_summary(fun.y = mean, geom="line", aes(group=oddball), position = position_dodge(0.2))
pp <- cleanPlot(pp)
print(pp)

pp1 <- pp + facet_wrap( ~targetFrequency )
print(pp1)

pp2 <- pp + facet_wrap( ~subject )
print(pp2)

pp3 <- pp + facet_grid( targetFrequency~subject )
print(pp3)

#############################################################################################################
#############################################################################################################
library(lme4)
library(LMERConvenienceFunctions)
library(languageR)

lm1 <- glmer( correctness ~ targetFrequency*timeFac*oddball + ( 1 | subject/timeFac ), data = accData, family = binomial )
lm0 <- glmer( correctness ~ targetFrequency*timeFac + ( 1 | subject/timeFac ), data = accData, family = binomial )
anova(lm1,lm0)


