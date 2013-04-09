setwd("d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciCode/dataAnalysisCodes/watchERP/02-p3Classification/")
rm(list = ls())
library(ggplot2)
library(reshape2)
library(ez)

accData <- read.csv("bldaResults/Results_blda_sub1to5_cond1to6_ave1to10.txt", header = TRUE)
accData$nAverages = as.factor(accData$nAverages)
str(accData)
summary(accData)


gpBoxplot <- ggplot(accData)
gpBoxplot + 
  geom_boxplot(aes(x=nAverages, y=accuracy, fill=condition), position = position_dodge(width = .5), width=.5)


# setting up the contrast for the stimulation condition, knowing that the factor levels are ordered in this wau:
# hybrid-10Hz, hybrid-12Hz, hybrid-15Hz, hybrid-8-57Hz, oddball
contrasts(accData$condition) <- cbind(
  c(1, 1, 1, 1, -4)    # oddball vs. hybrid
  , c(1, 1, 1, -3, 0)  # hybrid-8-57Hz vs. hybrid-10-12-15-Hz
  , c(-2, 1, 1, 0, 0)  # hybrid-10Hz vs. hybrid-12-15-Hz
  , c(0, -1, 1, 0, 0)  # hybrid-12Hz vs. hybrid-15-Hz
  )
# anovaModel <- ezANOVA(data=accData, dv=.(accuracy),wid=.(subject), within=.(condition,nAverages), type=2, detailed=TRUE)
# 
# 
# lmH1 <- lmer( accuracy ~ nAverages + condition + nAverages*condition + ( 1 | subject ), data = accData, REM=F )
# 
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

lmH2 <- lmer( accuracy ~ nAverages + condition + ( 1 | subject ), data = accData, REM=F )
mcmc = pvals.fnc( lmH2, nsim=5000, withMCMC=TRUE )
mcmc$fixed
mcmc$random
anova(lmH1, lmH2)

lmH3 <- lmer( accuracy ~ nAverages +  ( 1 | subject ), data = accData, REM=F )
mcmc = pvals.fnc( lmH3, nsim=5000, withMCMC=TRUE )
mcmc$fixed
mcmc$random
anova(lmH2, lmH3)


