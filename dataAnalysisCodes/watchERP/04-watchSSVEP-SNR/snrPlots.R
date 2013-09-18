setwd("d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciCode/dataAnalysisCodes/watchERP/04-watchSSVEP-SNR/")
rm(list = ls())
library(ggplot2)
library(reshape2)
library(grid)

source("d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciCode/dataAnalysisCodes/deps/cleanPlot.R")
source("createSnrDatasetFnc.R")
# subsetChLabel <- c("ch-O", "ch-PO-O", "ch-P-PO-O", "ch-CP-P-PO-O", "ch-C-CP-P-PO-O", "ch-all")
# harmonicsLabel <- c("fund","fund-ha1")
subsetChLabel <- c("ch-all")
harmonicsLabel <- c("fund-ha1")

snrData <- createSnrDatasetFnc(subsetChLabel, harmonicsLabel)
snrData <- snrData[snrData$watchedFrequency == snrData$targetFrequency,]

snrData$trialInSub <- snrData$run : snrData$roundNb
str(snrData)

#############################################################################################################
#############################################################################################################

pp <- ggplot( snrData, aes(time, snr, colour=oddball ) )
pp <- pp + stat_summary(fun.data = mean_cl_normal, geom="pointrange", position = position_dodge(0.2))
pp <- pp + stat_summary(fun.y = mean, geom="line", aes(group=oddball), position = position_dodge(0.2))
pp <- pp + facet_wrap( ~targetFrequency )
pp <- cleanPlot(pp)
print(pp)

pp2 <- pp + facet_wrap( ~subject )
print(pp2)

pp3 <- pp + facet_grid( targetFrequency~subject )
print(pp3)

#############################################################################################################
#############################################################################################################
library(lme4)
library(LMERConvenienceFunctions)
library(languageR)


fm1 <- lmer( snr ~ (time+I(time^2))*targetFrequency*oddball
              + ((time+I(time^2))|subject/trialInSub)
              , snrData
              , REML = FALSE
)

fm1b <- lmer( snr ~ (time+I(time^2)) + targetFrequency + oddball
              + (time+I(time^2)) : targetFrequency + (time+I(time^2)) : oddball
             + ((time+I(time^2))|subject/trialInSub)
             , snrData
             , REML = FALSE
)


fm2 <- lmer( snr ~ (time+I(time^2))*targetFrequency
               + ((time+I(time^2))|subject/trialInSub)
               , snrData
               , REML = FALSE
)
fm3 <- lmer( snr ~ (time+I(time^2))*oddball
               + ((time+I(time^2))|subject/trialInSub)
               , snrData
               , REML = FALSE
)
fm4 <- lmer( snr ~ (time+I(time^2))
               + ((time+I(time^2))|subject/trialInSub)
               , snrData
               , REML = FALSE
)

anova(fm1, fm2)
anova(fm1, fm3)
anova(fm2, fm4)
anova(fm3, fm4)


fm <- fm1
snrData$fitted  <- fitted(fm)
snrData$res     <- residuals(fm, type="normalized")

pp4 <- ggplot( snrData, aes(time, snr, colour=oddball) )
pp4 <- pp4 + geom_point(size=1) + geom_line( aes(time, snr, group=trialInSub) , linetype=2, size=0.3)
pp4 <- pp4 + geom_point() + geom_line( aes(time, fitted, group=trialInSub) )
pp4 <- pp4 + facet_grid( subject~targetFrequency, scales="free" )
# pp4 <- pp4 + facet_wrap( ~subject )
pp4 <- cleanPlot(pp4)
pp4

plot( fitted(fm), residuals(fm) )
abline(h=0)

# t<-4
# pp6 <- ggplot(snrData[snrData$time==t,], aes(fitted, res))
pp6 <- ggplot(snrData, aes(fitted, res))
pp6 <- pp6 + geom_point()
pp6 <- cleanPlot(pp6)
pp6

snrData$timeFac <- as.factor(snrData$time)
pp7 <- pp6 + facet_wrap(~timeFac, scales="free")
pp7

mcp.fnc(fm, trim = 2.5, col = "red")
tete <- pacf( resid( fm ) )

pp5 <- ggplot( snrData, aes(time, res) )
pp5 <- pp5 + geom_point()
pp5 <- cleanPlot(pp5)
pp5

