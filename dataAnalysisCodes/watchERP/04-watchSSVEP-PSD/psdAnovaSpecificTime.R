setwd("d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciCode/dataAnalysisCodes/watchERP/04-watchSSVEP-PSD/")
rm(list = ls())
library(ggplot2)
library(reshape2)
library(grid)
library(plyr)


source("d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciCode/dataAnalysisCodes/deps/cleanPlot.R")
source("d:/KULeuven/PhD/rLibrary/plotFactorMeans_InteractionGraphs.R")
source("d:/KULeuven/PhD/rLibrary/plotInteractionGraphs_level2.R")

fileDir <- "d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciProcessedData/watchERP/04-watchSSVEP-PSD"
filename <- "psdDataset_Oz_Ha1"

fullfilename <- file.path( fileDir, paste0(filename, ".csv") )

psdData <- read.csv(fullfilename, header = TRUE)

psdData$frequency <- as.factor(psdData$frequency)
psdData$oddball <- as.factor(psdData$oddball)
psdData$fileNb <- as.factor(psdData$fileNb)
psdData$trial <- as.factor(psdData$trial)
psdData$sqrtPsd <- sqrt(psdData$psd)

psdData <- psdData[psdData$stimDuration==5,]
# psdData <- psdData[psdData$frequency==15,]
varList <- c( "subject", "frequency","oddball" )
psdDataAveRun <- ddply( psdData, varList, summarise, psd = mean(psd) )
psdDataAveRun$sqrtPsd <- sqrt(psdDataAveRun$psd)

########################################################################################################################
########################################################################################################################
psdData$trialWithinSub <- as.numeric(psdData$trial)
allSubs   <- levels(psdData$subject)
nSubs   <- length(allSubs)
for (iS in 1:nSubs){
  psdData[psdData$subject==allSubs[iS], ]$trialWithinSub <- iS*100 + as.numeric(psdData[psdData$subject==allSubs[iS], ]$trial)
}
psdData$trialWithinSub <- as.factor(psdData$trialWithinSub)

# test <- lme(psd ~ 1+frequency+oddball+frequency:oddball, random = ~1|trial/subject, data = psdData, method="REML")
# test2 <- lme(psd ~ 1+frequency+oddball+frequency:oddball, random = ~1|trialWithinSub, data = psdData, method="REML")
# test3 <- lme(psd ~ 1+frequency+oddball+frequency:oddball, random = ~1|subject/trial, data = psdData, method="REML")


########################################################################################################################
########################################################################################################################

pp <- ggplot( psdData, aes(oddball, psd, colour=frequency ) )
pp <- pp + stat_summary(fun.data = mean_cl_normal, geom="pointrange", position = position_dodge(0.2))
pp <- pp + stat_summary(fun.data = mean_cl_normal, geom="line", aes(group=frequency), position = position_dodge(0.2))
pp <- pp + facet_wrap( ~ subject, scales = "free_y" )
pp <- cleanPlot(pp)

plotFactorMeans_InteractionGraphs(psdData,  c("oddball", "frequency"), "psd")

########################################################################################################################
########################################################################################################################
library(ez)

mod <- ezANOVA(
                data = psdDataAveRun
                , dv = .(psd)
                , wid = .(subject)
                , within = .(oddball, frequency)
                , type = 2
                , detailed = TRUE
                )
mod

detach("package:ez", unload=TRUE)

########################################################################################################################
########################################################################################################################
library(nlme)

# baseline <- lme(psd ~ 1, random = ~1|subject/frequency/oddball, data = psdDataAveRun, method="ML")
# frequency <- lme(psd ~ 1+frequency, random = ~1|subject/frequency/oddball, data = psdDataAveRun, method="ML")
# frequencyOddball <- lme(psd ~ 1+frequency+oddball, random = ~1|subject/frequency/oddball, data = psdDataAveRun, method="ML")
full <- lme(psd ~ 1+frequency+oddball+frequency:oddball, random = ~1|subject/frequency/oddball, data = psdDataAveRun, method="REML")

# anova(baseline, frequency, frequencyOddball, full)

# baseline2 <- lme(psd ~ 1, random = ~1|subject, data = psdDataAveRun, method="ML")
# frequency2 <- lme(psd ~ 1+frequency, random = ~1|subject, data = psdDataAveRun, method="ML")
# frequencyOddball2 <- lme(psd ~ 1+frequency+oddball, random = ~1|subject, data = psdDataAveRun, method="ML")
full2 <- lme(psd ~ 1+frequency+oddball+frequency:oddball, random = ~1|subject, data = psdDataAveRun, method="REML")

# anova(baseline2, frequency2, frequencyOddball2, full2)


detach("package:nlme", unload=TRUE)
########################################################################################################################
########################################################################################################################
library(lme4)
library(LMERConvenienceFunctions)
library(languageR)

# baseline42 <- lmer(psd ~ 1 + (1|subject), data = psdDataAveRun)
# frequency42 <- lmer(psd ~ 1+frequency + (1|subject), data = psdDataAveRun)
# frequencyOddball42 <- lmer(psd ~ 1+frequency+oddball + (1|subject), data = psdDataAveRun)
full42 <- lmer(psd ~ 1+frequency+oddball+frequency:oddball + (1|subject), data = psdDataAveRun)

# anova(baseline42, frequency42, frequencyOddball42, full42)

# baseline4 <- lmer(psd ~ 1 + (1|subject/frequency/oddball), data = psdDataAveRun)
# frequency4 <- lmer(psd ~ 1+frequency + (1|subject/frequency/oddball), data = psdDataAveRun)
# frequencyOddball4 <- lmer(psd ~ 1+frequency+oddball + (1|subject/frequency/oddball), data = psdDataAveRun)
full4 <- lmer(psd ~ 1+frequency+oddball+frequency:oddball + (1|subject/frequency/oddball), data = psdDataAveRun)

# anova(baseline4, frequency4, frequencyOddball4, full4)

detach("package:languageR", unload=TRUE)
detach("package:LMERConvenienceFunctions", unload=TRUE)
detach("package:lme4", unload=TRUE)
