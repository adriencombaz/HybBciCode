setwd("d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciCode/dataAnalysisCodes/watchERP/02-ter-p3Classification/")
rm(list = ls())
library(ggplot2)
library(reshape2)
library(nlme)
library(ez)
library(lme4)
library(LMERConvenienceFunctions)
library(languageR)
library(Hmisc)

source("d:/KULeuven/PhD/rLibrary/plotFactorMeans_InteractionGraphs.R")

for (iS in 1:8)
{
#   if (iS==8) 
#     {
#     filename <- sprintf("d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciProcessedData/watch-ERP/02-ter-p3Classification/LinSvm/subject_S%d_EpochRejection/Results_forLogisiticRegression.txt", iS)
#     }
#     else
#     {
#     filename <- sprintf("d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciProcessedData/watch-ERP/02-ter-p3Classification/LinSvm/subject_S%d/Results_forLogisiticRegression.txt", iS)
#     }
  filename <- sprintf("d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciProcessedData/watch-ERP/02-ter-p3Classification/LinSvm/subject_S%d/Results_forLogisiticRegression.txt", iS)
  accData1 <- read.csv(filename, header = TRUE, sep = ",", strip.white = TRUE)
#   accData1$nAverages = as.factor(accData1$nAverages )
  accData1$foldTest = as.factor(accData1$foldTest )
  accData1 <- subset( accData1, conditionTrain == conditionTest )
  accData1 <- subset( accData1, foldTrain == 1 )
  accData1$condition = accData1$conditionTrain;
  accData1 <- subset(accData1, select = -c(conditionTrain, conditionTest, foldTrain))

  if (iS == 1) { accData <- accData1 }
  else { accData <- rbind(accData, accData1) }
  
}

# temp <- subset(accData, nAverages == 1)
# temp2 <- subset(accData, nAverages == 5)
# temp3 <- subset(accData, nAverages == 10)
# accData <- rbind(temp, temp2, temp3)
# accData$nAverages <- droplevels(accData)$nAverages

accData$condition = relevel(accData$condition, "hybrid-15Hz")
accData$condition = relevel(accData$condition, "hybrid-12Hz")
accData$condition = relevel(accData$condition, "hybrid-10Hz")
accData$condition = relevel(accData$condition, "hybrid-8-57Hz")
accData$condition = relevel(accData$condition, "oddball")

str(accData)
summary(accData)

fontsize <- 12;
pp <- ggplot( accData, aes(nAverages, correctness, colour=condition, shape=condition) )
# pp <- pp + stat_summary(fun.data = mean_cl_boot, geom = "pointrange", width = 0.2, position = position_dodge(.5))
pp <- pp + stat_summary(fun.data = mean_cl_normal, geom = "pointrange", width = 0.2, position = position_dodge(.5))
# pp <- pp + stat_summary(fun.y = mean, geom = "point", aes(group=condition), width = 0.2)
# pp <- pp + stat_summary(fun.y = mean, geom = "line", aes(group=condition))
pp <- pp + facet_wrap( ~subject )
pp <- pp + theme(
  panel.background =  element_rect(fill='white')
  ,panel.grid.major = element_line(colour = "black", size = 0.5, linetype = "dotted")
  #   ,panel.grid.minor = element_line(colour = "black", size = 0.5, linetype = "dotted")
  #   , panel.grid.major = element_blank() # switch off major gridlines
  , panel.grid.minor = element_blank() # switch off minor gridlines
  , axis.ticks = element_line(colour = 'black')
  , axis.line = element_line(colour = 'black')
  , panel.border = theme_border(c("left","bottom"), size=0.25)
  , axis.title.y = element_text(face="plain", size = fontsize, angle=90, colour = 'black')
  , axis.title.x = element_text(face="plain", size = fontsize, angle=0, colour = 'black')
  , axis.text.x = element_text(face="plain", size = fontsize, colour = 'black')
  , axis.text.y = element_text(face="plain", size = fontsize, colour = 'black')
  , plot.title = element_text(face="plain", size = fontsize, colour = "black")
  , legend.text = element_text(face="plain", size = fontsize)
  , legend.title = element_text(face="plain", size = fontsize)
  , strip.background = element_blank()
)
pp


# datasetPlot <- melt( subset(accData, select = -foldTest), id=c("subject", "correctness") )
# datasetPlot <- melt( subset(accData, select = -c(foldTest, subject) ), id="correctness" )
datasetPlot <- melt( subset(accData, select = c(nAverages, condition, correctness) ), id="correctness" )
datasetPlot$value <- as.factor(datasetPlot$value)
datasetPlot$value <- factor(datasetPlot$value, levels = c(levels(as.factor(accData$nAverages)), levels(as.factor(accData$condition))))

factorBar <- ggplot(datasetPlot, aes(value, correctness))
factorBar <- factorBar + stat_summary(fun.y = mean, geom = "bar", fill = "White", colour = "Black") 
factorBar <- factorBar + stat_summary(fun.data = mean_cl_boot, geom = "pointrange") 
factorBar <- factorBar + facet_wrap(~variable, scales="free_x")
factorBar

interactionBar <- ggplot(accData, aes(nAverages, correctness, colour = condition))
interactionBar <- interactionBar + stat_summary( fun.y = mean, geom = "point", position = position_dodge(.5) )
interactionBar <- interactionBar + stat_summary(fun.y = mean, geom = "line", aes(group= condition), position = position_dodge(.5) )
interactionBar <- interactionBar + stat_summary(fun.data = mean_cl_boot, geom = "errorbar", width = 0.2, position = position_dodge(.5) )
interactionBar <- interactionBar + labs(x = "nAverages", y = "correctness", colour = "condition") 
interactionBar



interactionBar <- ggplot(accData, aes(nAverages, correctness, colour = condition))
interactionBar <- interactionBar + stat_summary( fun.y = mean, geom = "point", position = position_dodge(.5) )
interactionBar <- interactionBar + stat_summary(fun.y = mean, geom = "line", aes(group= condition), position = position_dodge(.5) )
interactionBar <- interactionBar + stat_summary(fun.data = mean_cl_boot, geom = "errorbar", width = 0.2, position = position_dodge(.5) )
interactionBar <- interactionBar + labs(x = "nAverages", y = "correctness", colour = "condition") 
interactionBar

interactionBar2 <- ggplot(accData, aes(condition, correctness, colour = as.factor(nAverages)))
interactionBar2 <- interactionBar2 + stat_summary(fun.y = mean, geom = "point")
interactionBar2 <- interactionBar2 + stat_summary(fun.y = mean, geom = "line", aes(group= as.factor(nAverages)))
interactionBar2 <- interactionBar2 + stat_summary(fun.data = mean_cl_boot, geom = "errorbar", width = 0.2)
interactionBar2 <- interactionBar2 + labs(x = "condition", y = "correctness", colour = "nAverages") 
interactionBar2




conditionBar <- ggplot(accData, aes(nAverages, correctness))
conditionBar <- conditionBar + stat_summary(fun.y = mean, geom = "bar", fill = "White", colour = "Black") 
conditionBar <- conditionBar + stat_summary(fun.data = mean_cl_boot, geom = "pointrange") 
conditionBar <- conditionBar + labs(x = "nAverages", y = "correctness") 
conditionBar


# OddballVsHybrid     = c(1, 1, 1, 1, -4)     # oddball vs. hybrid
# Hybrid857Vs10_12_15 = c(1, 1, 1, -3, 0)     # hybrid-8-57Hz vs. hybrid-10-12-15-Hz
# Hybrid10Vs12_15     = c(-2, 1, 1, 0, 0)     # hybrid-10Hz vs. hybrid-12-15-Hz
# Hybrid12Vs15        = c(0, -1, 1, 0, 0)     # hybrid-12Hz vs. hybrid-15-Hz
# contrasts(accData$condition) <- cbind(
#   OddballVsHybrid
#   , Hybrid857Vs10_12_15
#   , Hybrid10Vs12_15
#   , Hybrid12Vs15
# )

# SingleTrialVsAverage  = c(-9, 1, 1, 1, 1, 1, 1, 1, 1, 1)
# TwoVsMore             = c(0, -8, 1, 1, 1, 1, 1, 1, 1, 1)
# ThreeVsMore           = c(0, 0, -7, 1, 1, 1, 1, 1, 1, 1)
# FourVsMore            = c(0, 0, 0, -6, 1, 1, 1, 1, 1, 1)
# FiveVsMore            = c(0, 0, 0, 0, -5, 1, 1, 1, 1, 1)
# SixVsMore             = c(0, 0, 0, 0, 0, -4, 1, 1, 1, 1)
# SevenVsMore           = c(0, 0, 0, 0, 0, 0, -3, 1, 1, 1)
# EightVsMore           = c(0, 0, 0, 0, 0, 0, 0, -2, 1, 1)
# NineVsTen             = c(0, 0, 0, 0, 0, 0, 0, 0, -1, 1)
# contrasts(accData$nAverages) <- cbind(
#   SingleTrialVsAverage
#   , TwoVsMore
#   , ThreeVsMore
#   , FourVsMore
#   , FiveVsMore
#   , SixVsMore
#   , SevenVsMore
#   , EightVsMore
#   , NineVsTen
# )

OddballVsHybrid     = c(-4, 1, 1, 1, 1)     # oddball vs. hybrid
Hybrid857Vs10_12_15 = c(0, -3, 1, 1, 1)     # hybrid-8-57Hz vs. hybrid-10-12-15-Hz
Hybrid10Vs12_15     = c(0, 0, -2, 1, 1)     # hybrid-10Hz vs. hybrid-12-15-Hz
Hybrid12Vs15        = c(0, 0, 0, -1, 1)     # hybrid-12Hz vs. hybrid-15-Hz
contrasts(accData$condition) <- cbind(
  OddballVsHybrid
  , Hybrid857Vs10_12_15
  , Hybrid10Vs12_15
  , Hybrid12Vs15
)

# SingleTrialVsAverage = c(-2, 1, 1)
# SmallVsLargeAverage = c(0, -1, 1)
# contrasts(accData$nAverages) <- cbind(
#   SingleTrialVsAverage
#   , SmallVsLargeAverage
# )

#------------------------------------------------------------------------------------------------------
# USING LMER
#------------------------------------------------------------------------------------------------------
# accData10Rep$accTrans <-sqrt(accData10Rep$accuracy)
# accData10Rep$accTrans <-log2(accData10Rep$accuracy)
# accData10Rep$accTrans <-exp(accData10Rep$accuracy)

lmH3 <- lmer( correctness ~ nAverages*condition + ( 1 | subject ), data = accData, family = binomial )
lmH2 <- lmer( correctness ~ nAverages + condition + ( 1 | subject ), data = accData, family = binomial )
lmH1a <- lmer( correctness ~ nAverages + ( 1 | subject ), data = accData, family = binomial )
lmH1b <- lmer( correctness ~ condition + ( 1 | subject ), data = accData, family = binomial )


# # independence
# tete <- pacf( resid( lmH1 ) )
# plot( fitted(lmH1), residuals(lmH1) )
# abline(h=0)
# 
# # normality
# toto <- mcp.fnc( lmH1 )
# qqnorm( residuals(lmH1), main = " " )
# qqline( residuals(lmH1) )
# 
# shapiro.test( residuals( lmH1 ) )
# 
# Compare with null model
lmH0 <- lmer( correctness ~ ( 1 | subject ), data = accData, family = binomial )
anova( lmH0, lmH1a, lmH2, lmH3 )
anova( lmH0, lmH1b, lmH2, lmH3 )

plotlogistic.fit.fnc(lmH2, accData)



