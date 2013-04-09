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
library(car)

source("d:/KULeuven/PhD/rLibrary/plot_set.R")

for (iS in 1:7)
{
  filename <- sprintf("d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciProcessedData/watch-ERP/02-ter-p3Classification/LinSvm/subject_S%d/Results.txt", iS)
  accData1 <- read.csv(filename, header = TRUE, sep = ",", strip.white = TRUE)
  accData1$nAverages = as.factor(accData1$nAverages)
  accData1 <- subset( accData1, conditionTrain == conditionTest)
  accData1$condition = accData1$conditionTrain;
  accData1 <- subset(accData1, select = -c(conditionTrain, conditionTest))

  if (iS == 1) { accData <- accData1 }
  else { accData <- rbind(accData, accData1) }
  
}

temp <- subset(accData, nAverages == 1)
temp2 <- subset(accData, nAverages == 5)
temp3 <- subset(accData, nAverages == 10)
accData10Rep <- rbind(temp, temp2, temp3)

accData10Rep$nAverages <- droplevels(accData10Rep)$nAverages

# accData10Rep$accuracy <- exp( accData10Rep$accuracy/100 )

str(accData10Rep)
summary(accData10Rep)

fontsize <- 12;
pp <- ggplot( accData10Rep, aes(nAverages, accuracy, colour=condition, shape=condition) )
pp <- pp + geom_point( position = position_jitter(w = 0.2, h = 0)
                       , size = 3  )
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

fontsize <- 12;
pp <- ggplot( accData10Rep, aes(condition, accuracy, colour=nAverages, shape=nAverages) )
pp <- pp + geom_point( position = position_jitter(w = 0.2, h = 0)
                       , size = 3  )
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


fontsize <- 12;
pp <- ggplot( accData10Rep, aes(condition, accuracy, colour=subject) )
pp <- pp + geom_point( position = position_jitter(w = 0.2, h = 0)
                       , size = 3  )
pp <- pp + facet_wrap( ~nAverages )
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

# OddballVsHybrid     = c(1, 1, 1, 1, -4)     # oddball vs. hybrid
# Hybrid857Vs10_12_15 = c(1, 1, 1, -3, 0)     # hybrid-8-57Hz vs. hybrid-10-12-15-Hz
# Hybrid10Vs12_15     = c(-2, 1, 1, 0, 0)     # hybrid-10Hz vs. hybrid-12-15-Hz
# Hybrid12Vs15        = c(0, -1, 1, 0, 0)     # hybrid-12Hz vs. hybrid-15-Hz
# contrasts(accData10Rep$condition) <- cbind(
#   OddballVsHybrid
#   , Hybrid857Vs10_12_15
#   , Hybrid10Vs12_15
#   , Hybrid12Vs15
# )
# 
# SingleTrialVsAverage = c(-2, 1, 1)
# SmallVsLargeAverage = c(0, -1, 1)
# contrasts(accData10Rep$nAverages) <- cbind(
#   SingleTrialVsAverage
#   , SmallVsLargeAverage
# )

#------------------------------------------------------------------------------------------------------
# SIMPLE RM ANOVA (using anova() from car)
#------------------------------------------------------------------------------------------------------
# dataMatrix2 <- acast(accData10Rep, subject~condition+nAverages, value.var="accuracy")
# condition <- acast(accData10Rep, subject~condition+nAverages, value.var="condition")
# nAverages <- acast(accData10Rep, subject~condition+nAverages, value.var="nAverages")


condLev = levels(accData10Rep$condition)
nAveLev = levels(accData10Rep$nAverages)
subLev  = levels(accData10Rep$subject)
dataMatrix  = matrix(data=NA, nrow=length(subLev), ncol=length(condLev)*length(nAveLev))
condition   = matrix(data=NA, nrow=length(condLev)*length(nAveLev), ncol=1)
nAverages   = matrix(data=NA, nrow=length(condLev)*length(nAveLev), ncol=1)

for (iC in 1:length(condLev)) {

  temp = subset(accData10Rep, condition == condLev[iC])
  for(iA in 1:length(nAveLev)) {
    
    temp2 = subset(temp, nAverages==nAveLev[iA])
    dataMatrix[, (iC-1)*length(nAveLev)+iA] <- temp2$accuracy
    condition[(iC-1)*length(nAveLev)+iA] <- condLev[iC]
    nAverages[(iC-1)*length(nAveLev)+iA] <- nAveLev[iA]
  }
  
}

iDataMatrix = data.frame( condition=condition, nAverages=nAverages )

accModel <- lm(dataMatrix ~ 1)
analysis <- Anova(accModel, idata = iDataMatrix, idesign = ~condition * nAverages, multivariate=FALSE)
summary(analysis)

#------------------------------------------------------------------------------------------------------
# SIMPLE RM ANOVA (using ezANOVA)
#------------------------------------------------------------------------------------------------------

anovaModelType2 <- ezANOVA( data=accData10Rep
                            , dv=.(accuracy)
                            , wid=.(subject)
                            , within=.(condition, nAverages)
                            , type=2
                            , detailed=TRUE 
)

anovaModelType3 <- ezANOVA( data=accData10Rep
                       , dv=.(accuracy)
                       , wid=.(subject)
                       , within=.(condition, nAverages)
                       , type=3
                       , detailed=TRUE 
                       , return_aov=TRUE
                       )

pairwise.t.test( accData10Rep$accuracy
                 , accData10Rep$condition
                 , paired=TRUE
                 , p.adjust.method="bonferroni"
)

pairwise.t.test( accData10Rep$accuracy
                 , accData10Rep$nAverages
                 , paired=TRUE
                 , p.adjust.method="bonferroni"
)


nAveragesBar <- ggplot(accData10Rep, aes(nAverages, accuracy))
nAveragesBar <- nAveragesBar + stat_summary(fun.y = mean, geom = "bar", fill = "White", colour = "Black") 
nAveragesBar <- nAveragesBar + stat_summary(fun.data = mean_cl_boot, geom = "pointrange") 
nAveragesBar <- nAveragesBar + labs(x = "nAverages", y = "accuracy") 
nAveragesBar


conditionBar <- ggplot(accData10Rep, aes(condition, accuracy))
conditionBar <- conditionBar + stat_summary(fun.y = mean, geom = "bar", fill = "White", colour = "Black") 
conditionBar <- conditionBar + stat_summary(fun.data = mean_cl_boot, geom = "pointrange") 
conditionBar <- conditionBar + labs(x = "condition", y = "accuracy") 
conditionBar

interactionBar <- ggplot(accData10Rep, aes(condition, accuracy, colour = nAverages))
interactionBar <- interactionBar + stat_summary(fun.y = mean, geom = "point")
interactionBar <- interactionBar + stat_summary(fun.y = mean, geom = "line", aes(group= nAverages))
interactionBar <- interactionBar + stat_summary(fun.data = mean_cl_boot, geom = "errorbar", width = 0.2)
interactionBar <- interactionBar + labs(x = "condition", y = "accuracy", colour = "nAverages") 
interactionBar

interactionBar2 <- ggplot(accData10Rep, aes(nAverages, accuracy, colour = condition))
interactionBar2 <- interactionBar2 + stat_summary(fun.y = mean, geom = "point")
interactionBar2 <- interactionBar2 + stat_summary(fun.y = mean, geom = "line", aes(group= condition))
interactionBar2 <- interactionBar2 + stat_summary(fun.data = mean_cl_boot, geom = "errorbar", width = 0.2)
interactionBar2 <- interactionBar2 + labs(x = "nAverages", y = "accuracy", colour = "condition") 
interactionBar2


#------------------------------------------------------------------------------------------------------
# SLIGHTLY MORE COMPLICATED WAY (cf, chapter 13.7.5 Andy Field's book)
#------------------------------------------------------------------------------------------------------
baseline = lme( accuracy ~ 1
                , random = ~1|subject/condition/nAverages
                , data = accData10Rep
                , method = "ML"
                )

# condModel = update(baseline, .~. + condition)
# nAveModel = update(condModel, .~. + nAverages)
# accModel  = update(condModel, .~. + condition:nAverages)
# 
# summary(baseline)
# summary(condModel)
# summary(nAveModel)
# summary(accModel)
# 
# anova(baseline, condModel, nAveModel, accModel)


nAveModel2 = update(baseline, .~. + nAverages)
condModel2 = update(nAveModel2, .~. + condition)
accModel2  = update(condModel2, .~. + condition:nAverages)

# summary(baseline)
summary(nAveModel2)
# summary(condModel2)
# summary(accModel2)

anova(baseline, condModel2, nAveModel2, accModel2)

#------------------------------------------------------------------------------------------------------
# USING LMER
#------------------------------------------------------------------------------------------------------
lmH1 <- lmer( accuracy ~ nAverages*condition + ( 1 | subject ), data = accData10Rep, REM=F )


# independence
tete <- pacf( resid( lmH1 ) )
plot( fitted(lmH1), residuals(lmH1) )
abline(h=0)

# normality
toto <- mcp.fnc( lmH1 )
qqnorm( residuals(lmH1), main = " " )
qqline( residuals(lmH1) )

shapiro.test( residuals( lmH1 ) )

# Compare with null model
lmH0 <- lmer( accuracy ~ ( 1 | subject ), data = accData10Rep )
anova( lmH1, lmH0 )

# Compare factor levels
mcmc = pvals.fnc( lmH1, nsim=5000, withMCMC=TRUE )
mcmc$fixed
mcmc$random
