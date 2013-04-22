setwd("d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciCode/dataAnalysisCodes/watchERP/02-ter-p3Classification/")
rm(list = ls())
library(ggplot2)
library(reshape2)
library(nlme)
library(ez)
library(reshape2)
library(lme4)
library(LMERConvenienceFunctions)
library(languageR)
library(Hmisc)

source("d:/KULeuven/PhD/rLibrary/plot_set.R")

for (iS in 1:8)
{
  filename <- sprintf("d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciProcessedData/watch-ERP/02-ter-p3Classification/LinSvm/subject_S%d/Results_forLogisiticRegression.txt", iS)
  accData1 <- read.csv(filename, header = TRUE, sep = ",", strip.white = TRUE)
  accData1$nAverages = as.factor(accData1$nAverages )
  accData1$foldTest = as.factor(accData1$foldTest )
  accData1 <- subset( accData1, conditionTrain == conditionTest )
#   accData1 <- subset( accData1, foldTrain == 1 )
  accData1$condition = accData1$conditionTrain;
#   accData1 <- subset(accData1, select = -c(conditionTrain, conditionTest, foldTrain))

  if (iS == 1) { accData <- accData1 }
  else { accData <- rbind(accData, accData1) }
  
}

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


OddballVsHybrid     = c(1, 1, 1, 1, -4)     # oddball vs. hybrid
Hybrid857Vs10_12_15 = c(1, 1, 1, -3, 0)     # hybrid-8-57Hz vs. hybrid-10-12-15-Hz
Hybrid10Vs12_15     = c(-2, 1, 1, 0, 0)     # hybrid-10Hz vs. hybrid-12-15-Hz
Hybrid12Vs15        = c(0, -1, 1, 0, 0)     # hybrid-12Hz vs. hybrid-15-Hz
contrasts(accData$condition) <- cbind(
  OddballVsHybrid
  , Hybrid857Vs10_12_15
  , Hybrid10Vs12_15
  , Hybrid12Vs15
)

SingleTrialVsAverage  = c(-9, 1, 1, 1, 1, 1, 1, 1, 1, 1)
TwoVsMore             = c(0, -8, 1, 1, 1, 1, 1, 1, 1, 1)
ThreeVsMore           = c(0, 0, -7, 1, 1, 1, 1, 1, 1, 1)
FourVsMore            = c(0, 0, 0, -6, 1, 1, 1, 1, 1, 1)
FiveVsMore            = c(0, 0, 0, 0, -5, 1, 1, 1, 1, 1)
SixVsMore             = c(0, 0, 0, 0, 0, -4, 1, 1, 1, 1)
SevenVsMore           = c(0, 0, 0, 0, 0, 0, -3, 1, 1, 1)
EightVsMore           = c(0, 0, 0, 0, 0, 0, 0, -2, 1, 1)
NineVsTen             = c(0, 0, 0, 0, 0, 0, 0, 0, -1, 1)
contrasts(accData$nAverages) <- cbind(
  SingleTrialVsAverage
  , TwoVsMore
  , ThreeVsMore
  , FourVsMore
  , FiveVsMore
  , SixVsMore
  , SevenVsMore
  , EightVsMore
  , NineVsTen
)


#------------------------------------------------------------------------------------------------------
# USING LMER
#------------------------------------------------------------------------------------------------------
# accData10Rep$accTrans <-sqrt(accData10Rep$accuracy)
# accData10Rep$accTrans <-log2(accData10Rep$accuracy)
# accData10Rep$accTrans <-exp(accData10Rep$accuracy)

lmH1 <- lmer( correctness ~ nAverages*condition + ( 1 | subject ), data = accData, family = binomial )
lmH2 <- lmer( correctness ~ nAverages + condition + ( 1 | subject ), data = accData, family = binomial )
lmH3a <- lmer( correctness ~ nAverages + ( 1 | subject ), data = accData, family = binomial )
lmH3b <- lmer( correctness ~ condition + ( 1 | subject ), data = accData, family = binomial )


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
anova( lmH0, lmH3a, lmH2, lmH1 )
anova( lmH0, lmH3b, lmH2, lmH1 )

# Compare factor levels
mcmc = pvals.fnc( lmH1, nsim=5000, withMCMC=TRUE )
mcmc$fixed
mcmc$random
