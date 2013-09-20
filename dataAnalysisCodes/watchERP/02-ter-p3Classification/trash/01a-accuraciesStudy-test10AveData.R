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
library(car)
source("d:/KULeuven/PhD/rLibrary/plot_set.R")

for (iS in 1:7)
{
  filename <- sprintf("d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciProcessedData/watchERP/02-ter-p3Classification/LinSvm/subject_S%d/Results.txt", iS)
  accData1 <- read.csv(filename, header = TRUE, sep = ",", strip.white = TRUE)
  accData1$nAverages = as.factor(accData1$nAverages)
  accData1 <- subset( accData1, conditionTrain == conditionTest)
  accData1$condition = accData1$conditionTrain;
  accData1 <- subset(accData1, select = -c(conditionTrain, conditionTest))

  if (iS == 1) { accData <- accData1 }
  else { accData <- rbind(accData, accData1) }
  
}

accData10Rep <- subset(accData, nAverages == 10, select = -nAverages)

str(accData10Rep)
summary(accData10Rep)

fontsize <- 12;
pp <- ggplot( accData10Rep, aes(condition, accuracy, colour=subject) )
pp <- pp + geom_point( position = position_jitter(w = 0.2, h = 0)
                       , size = 3  )
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
pp <- ggplot( accData10Rep, aes(subject, accuracy, colour=condition, shape=condition) )
pp <- pp + geom_point( position = position_jitter(w = 0.2, h = 0)
                       , size = 3  )
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


OddballVsHybrid     = c(1, 1, 1, 1, -4)    # oddball vs. hybrid
Hybrid857Vs10_12_15 = c(1, 1, 1, -3, 0)  # hybrid-8-57Hz vs. hybrid-10-12-15-Hz
Hybrid10Vs12_15     = c(-2, 1, 1, 0, 0)  # hybrid-10Hz vs. hybrid-12-15-Hz
Hybrid12Vs15        = c(0, -1, 1, 0, 0)  # hybrid-12Hz vs. hybrid-15-Hz

contrasts(accData10Rep$condition) <- cbind(
  OddballVsHybrid
  , Hybrid857Vs10_12_15
  , Hybrid10Vs12_15
  , Hybrid12Vs15
)

#------------------------------------------------------------------------------------------------------
# SIMPLE RM ANOVA (using Anova() from the car package)
#------------------------------------------------------------------------------------------------------
condLev = levels(accData10Rep$condition)
subLev  = levels(accData10Rep$subject)
dataMatrix  = matrix(data=NA, nrow=length(subLev), ncol=length(condLev))
condition   = matrix(data=NA, nrow=length(condLev), ncol=1)

for (iC in 1:length(condLev)) {
  temp = subset(accData10Rep, condition == condLev[iC])
  dataMatrix[, iC] <- temp$accuracy
  condition[iC] <- condLev[iC]  
}

iDataMatrix = data.frame( condition=condition )

accModel <- lm(dataMatrix ~ 1)
analysis <- Anova(accModel, idata = iDataMatrix, idesign = ~condition)
summary(analysis)


#------------------------------------------------------------------------------------------------------
# SIMPLE RM ANOVA (using ezANOVA)
#------------------------------------------------------------------------------------------------------
anovaModelType2 <- ezANOVA( data=accData10Rep
                            , dv=.(accuracy)
                            , wid=.(subject)
                            , within=.(condition)
                            , type=2
                            , detailed=TRUE 
)

anovaModelType3 <- ezANOVA( data=accData10Rep
                       , dv=.(accuracy)
                       , wid=.(subject)
                       , within=.(condition)
                       , type=3
                       , detailed=TRUE 
                       )

pairwise.t.test( accData10Rep$accuracy
                 , accData10Rep$condition
                 , paired=TRUE
                 , p.adjust.method="bonferroni"
                 )

#------------------------------------------------------------------------------------------------------
# SLIGHTLY MORE COMPLICATED WAY (cf, chapter 13.4.7.2 Andy Field's book)
#------------------------------------------------------------------------------------------------------
linearModel = lme( accuracy ~ condition
                   , random = ~1|subject/condition
                   , data = accData10Rep
                   , method = "ML"  
                   )
#summary(linearModel)


baseline = lme( accuracy ~ 1
                , random = ~1|subject/condition
                , data = accData10Rep
                , method = "ML"
                )

anova(baseline, linearModel)

#------------------------------------------------------------------------------------------------------
# USING LMER
#------------------------------------------------------------------------------------------------------
lmH1 <- lmer( accuracy ~ condition + ( 1 | subject ), data = accData10Rep, REM=F )


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
