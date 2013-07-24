setwd("d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciCode/dataAnalysisCodes/watchERP/04-watchSSVEP-PSD/")
rm(list = ls())
library(ggplot2)
library(reshape2)
library(grid)
library(lme4)
library(LMERConvenienceFunctions)
library(languageR)

source("d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciCode/dataAnalysisCodes/deps/cleanPlot.R")
source("d:/KULeuven/PhD/rLibrary/plotFactorMeans_InteractionGraphs.R")

filename <- "psdDataset_SelChan_1Ha"

####################################################################################################################
####################################################################################################################
# linearReg <- function(filename)
# {
  
  fileDir <- "d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciProcessedData/watch-ERP/04-watchSSVEP-PSD"
  fullfilename <- file.path( fileDir, paste0(filename, ".csv") )
  
#   resDir <- "d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciResults/watchERP/04-watchSSVEP-PSD"
#   resDir <- file.path(resDir, filename)
#   dir.create(resDir, showWarnings=FALSE)
  
  psdData <- read.csv(fullfilename, header = TRUE)
  
  psdData$frequency       <- as.factor(psdData$frequency)
  psdData$oddball         <- as.factor(psdData$oddball)
  psdData$fileNb          <- as.factor(psdData$fileNb)
  psdData$trial           <- as.factor(psdData$trial)
  psdData$stimDurationFac <- as.factor(psdData$stimDuration)
  psdData$psd             <- sqrt(psdData$psd)

  # add coding variable for nRep nested within subject
  psdData$stimDurationWithinSub <- psdData$stimDuration
  allSubs   <- levels(psdData$subject)
  nSubs   <- length(allSubs)
  for (iS in 1:nSubs){
    psdData[psdData$subject==allSubs[iS], ]$stimDurationWithinSub <- iS*1000 + psdData[psdData$subject==allSubs[iS], ]$stimDuration
  }
  psdData$stimDurationWithinSub <- as.factor(psdData$stimDurationWithinSub)


  psdData$trialWithinSub <- numeric( nrow(psdData) )
  psdData$trialPerSub <- numeric( nrow(psdData) )
  allSubs   <- levels(psdData$subject)
  nSubs   <- length(allSubs)
  for (iS in 1:nSubs){
    psdData[psdData$subject==allSubs[iS], ]$trialWithinSub <- iS*10000 + 1:nrow( psdData[psdData$subject==allSubs[iS], ] )
    psdData[psdData$subject==allSubs[iS], ]$trialPerSub <- 1:nrow( psdData[psdData$subject==allSubs[iS], ] )
  }
  psdData$trialWithinSub <- as.factor(psdData$trialWithinSub)
  psdData$trialPerSub <- as.factor(psdData$trialPerSub)

  str(psdData)
  summary(psdData)
  
  lmH <- NULL
  
  #################################################################################################################
  #################################################################################################################

  f857Vs10_12_15      = c(-3, 1, 1, 1)     # hybrid-8-57Hz vs. hybrid-10-12-15-Hz
  f10Vs12_15          = c(0, -2, 1, 1)     # hybrid-10Hz vs. hybrid-12-15-Hz
  f12Vs15             = c(0, 0, -1, 1)     # hybrid-12Hz vs. hybrid-15-Hz
  contrasts(psdData$frequency) <- cbind(
    f857Vs10_12_15
    , f10Vs12_15
    , f12Vs15
  )
  
  Rep1VsRep2    = c(-1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
  Rep2VsRep3    = c(0, -1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
  Rep3VsRep4    = c(0, 0, -1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
  Rep4VsRep5    = c(0, 0, 0, -1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0)
  Rep5VsRep6    = c(0, 0, 0, 0, -1, 1, 0, 0, 0, 0, 0, 0, 0, 0)
  Rep6VsRep7    = c(0, 0, 0, 0, 0, -1, 1, 0, 0, 0, 0, 0, 0, 0)
  Rep7VsRep8    = c(0, 0, 0, 0, 0, 0, -1, 1, 0, 0, 0, 0, 0, 0)
  Rep8VsRep9    = c(0, 0, 0, 0, 0, 0, 0, -1, 1, 0, 0, 0, 0, 0)
  Rep9VsRep10   = c(0, 0, 0, 0, 0, 0, 0, 0, -1, 1, 0, 0, 0, 0)
  Rep10VsRep11  = c(0, 0, 0, 0, 0, 0, 0, 0, 0, -1, 1, 0, 0, 0)
  Rep11VsRep12  = c(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, 1, 0, 0)
  Rep12VsRep13  = c(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, 1, 0)
  Rep13VsRep14  = c(0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, -1, 1)
  
  contrasts(psdData$stimDurationFac) <- cbind(
    Rep1VsRep2
    , Rep2VsRep3
    , Rep3VsRep4
    , Rep4VsRep5
    , Rep5VsRep6
    , Rep6VsRep7
    , Rep7VsRep8
    , Rep8VsRep9
    , Rep9VsRep10
    , Rep10VsRep11
    , Rep11VsRep12
    , Rep12VsRep13
    , Rep13VsRep14
  )
  
####################################################################################################################
#################################################################################################################
lm1 <- lmer( psd ~ stimDuration * oddball * frequency + (stimDuration | subject/frequency/oddball/trial) , data = psdData )
lm2 <- lmer( psd ~ stimDuration * frequency + (stimDuration | subject/frequency/oddball/trial) , data = psdData )


####################################################################################################################
#################################################################################################################
lmH1 <- lmer( psd ~ stimDuration * oddball * frequency + (stimDuration | subject) , data = psdData )
lmH2 <- lmer( psd ~ stimDuration * oddball * frequency + (1 | subject) , data = psdData )
anova(lmH1, lmH2)

lmH3 <- lmer( psd ~ stimDuration * oddball * frequency + (stimDuration | subject/frequency/oddball/trial), data = psdData )
anova(lmH1, lmH3)

lmH4 <- lmer( psd ~ stimDuration * frequency + (stimDuration | subject) , data = psdData )
anova(lmH1, lmH4)

lmH5 <- lmer( psd ~ stimDuration * oddball * frequency + (stimDuration | subject/trial), data = psdData )
anova(lmH5, lmH3)

lmH6 <- lmer( psd ~ stimDuration * frequency + (stimDuration | subject/trial), data = psdData )
anova(lmH5, lmH6)

toto <- lmer( psd ~ stimDuration * frequency + (stimDuration | subject) + (stimDuration | trialPerSub), data = psdData )
tete <- lmer( psd ~ stimDuration * frequency + (stimDuration | subject) + (stimDuration | trialWithinSub), data = psdData )
tata <- lmer( psd ~ stimDuration * frequency + (stimDuration | subject/trialPerSub), data = psdData )

lmH1a <- lmer( psd ~ stimDuration * oddball * frequency + (1 | subject) + (0 + stimDuration | subject) , data = psdData )
lmH4a <- lmer( psd ~ stimDuration * frequency  + (1 | subject) + (0 + stimDuration | subject) , data = psdData )
anova(lmH1a, lmH4a)

lmH2a <- lmer( psd ~ stimDuration + oddball + frequency 
               + stimDuration:oddball + stimDuration:frequency + oddball:frequency
               + (1 | subject) + (0 + stimDuration | subject) , data = psdData )
anova(lmH1a, lmH2a)

lmH3a <- lmer( psd ~ stimDuration + oddball + frequency 
               + stimDuration:frequency + oddball:frequency
               + (1 | subject) + (0 + stimDuration | subject) , data = psdData )
anova(lmH3a, lmH2a)

lmH4a <- lmer( psd ~ stimDuration + oddball + frequency 
               + stimDuration:frequency
               + (1 | subject) + (0 + stimDuration | subject) , data = psdData )
anova(lmH3a, lmH4a)

  ####################################################################################################################
  #################################################################################################################
  lmH$mod004 <- lmer( psd ~ stimDuration * oddball * frequency + (1 | subject) + ( 1 | stimDurationWithinSub ), data = psdData )
  
  lmH$mod003 <- lmer( psd ~ stimDuration + oddball + frequency + (1 | subject) + ( 1 | stimDurationWithinSub ), data = psdData )
  
  lmH$mod002c <- lmer( psd ~ stimDuration + frequency + (1 | subject) + ( 1 | stimDurationWithinSub ), data = psdData )
  lmH$mod002b <- lmer( psd ~ oddball + frequency + (1 | subject) + ( 1 | stimDurationWithinSub ), data = psdData )
  lmH$mod002a <- lmer( psd ~ stimDuration + oddball + (1 | subject) + ( 1 | stimDurationWithinSub ), data = psdData )
  
  lmH$mod001c <- lmer( psd ~ stimDuration + (1 | subject) + ( 1 | stimDurationWithinSub ), data = psdData )
  lmH$mod001b <- lmer( psd ~ frequency + (1 | subject) + ( 1 | stimDurationWithinSub ), data = psdData )
  lmH$mod001a <- lmer( psd ~ oddball + (1 | subject) + ( 1 | stimDurationWithinSub ), data = psdData )
  
  lmH$mod000 <- lmer( psd ~ (1 | subject) + ( 1 | stimDurationWithinSub ), data = psdData )
  
#   anova( lmH$mod003, lmH$mod004 )
# 
# #   pp <- pvals.fnc(lmH$mod004)
# 
#   anova( lmH$mod002a, lmH$mod003 )
#   anova( lmH$mod002b, lmH$mod003 )
#   anova( lmH$mod002c, lmH$mod003 )
#   
#   anova( lmH$mod002a, lmH$mod001a )
#   anova( lmH$mod002a, lmH$mod001c )
#   anova( lmH$mod002b, lmH$mod001a )
#   anova( lmH$mod002b, lmH$mod001b )
#   anova( lmH$mod002c, lmH$mod001b )
#   anova( lmH$mod002c, lmH$mod001c )
#   
#   anova( lmH$mod001a, lmH$mod000 )
#   anova( lmH$mod001b, lmH$mod000 )
#   anova( lmH$mod001c, lmH$mod000 )
  
#   anova( lmH$mod000, lmH$mod001a, lmH$mod002a, lmH$mod003, lmH$mod004 )
#   anova( lmH$mod000, lmH$mod001a, lmH$mod002b, lmH$mod003, lmH$mod004 )
#   anova( lmH$mod000, lmH$mod001b, lmH$mod002b, lmH$mod003, lmH$mod004 )
#   anova( lmH$mod000, lmH$mod001b, lmH$mod002c, lmH$mod003, lmH$mod004 )
#   anova( lmH$mod000, lmH$mod001c, lmH$mod002a, lmH$mod003, lmH$mod004 )
#   anova( lmH$mod000, lmH$mod001c, lmH$mod002c, lmH$mod003, lmH$mod004 )  

  ####################################################################################################################
  #################################################################################################################
  lmH$mod104 <- lmer( psd ~ stimDurationFac * oddball * frequency + (1 | subject) + ( 1 | stimDurationWithinSub ), data = psdData )
  
  lmH$mod103 <- lmer( psd ~ stimDurationFac + oddball + frequency + (1 | subject) + ( 1 | stimDurationWithinSub ), data = psdData )
  
  lmH$mod102c <- lmer( psd ~ stimDurationFac + frequency + (1 | subject) + ( 1 | stimDurationWithinSub ), data = psdData )
  lmH$mod102b <- lmer( psd ~ oddball + frequency + (1 | subject) + ( 1 | stimDurationWithinSub ), data = psdData )
  lmH$mod102a <- lmer( psd ~ stimDurationFac + oddball + (1 | subject) + ( 1 | stimDurationWithinSub ), data = psdData )

  lmH$mod101c <- lmer( psd ~ stimDurationFac + (1 | subject) + ( 1 | stimDurationWithinSub ), data = psdData )
  lmH$mod101b <- lmer( psd ~ frequency + (1 | subject) + ( 1 | stimDurationWithinSub ), data = psdData )
  lmH$mod101a <- lmer( psd ~ oddball + (1 | subject) + ( 1 | stimDurationWithinSub ), data = psdData )
  
  lmH$mod100 <- lmer( psd ~ (1 | subject) + ( 1 | stimDurationWithinSub ), data = psdData )
  
#   anova( lmH$mod103, lmH$mod104 )
#   
# #   pp2 <- pvals.fnc(lmH$mod104)
# 
#   anova( lmH$mod102a, lmH$mod103 )
#   anova( lmH$mod102b, lmH$mod103 )
#   anova( lmH$mod102c, lmH$mod103 )
#   
#   anova( lmH$mod102a, lmH$mod101a )
#   anova( lmH$mod102a, lmH$mod101c )
#   anova( lmH$mod102b, lmH$mod101a )
#   anova( lmH$mod102b, lmH$mod101b )
#   anova( lmH$mod102c, lmH$mod101b )
#   anova( lmH$mod102c, lmH$mod101c )
#   
#   anova( lmH$mod101a, lmH$mod100 )
#   anova( lmH$mod101b, lmH$mod100 )
#   anova( lmH$mod101c, lmH$mod100 )

#   anova( lmH$mod000, lmH$mod001a, lmH$mod002a, lmH$mod003, lmH$mod004 )
#   anova( lmH$mod000, lmH$mod001a, lmH$mod002b, lmH$mod003, lmH$mod004 )
#   anova( lmH$mod000, lmH$mod001b, lmH$mod002b, lmH$mod003, lmH$mod004 )
#   anova( lmH$mod000, lmH$mod001b, lmH$mod002c, lmH$mod003, lmH$mod004 )
#   anova( lmH$mod000, lmH$mod001c, lmH$mod002a, lmH$mod003, lmH$mod004 )
#   anova( lmH$mod000, lmH$mod001c, lmH$mod002c, lmH$mod003, lmH$mod004 )  
  
#   return(lmH)

# }


####################################################################################################################
####################################################################################################################

# filenames <- c( "psdDataset_O1OzO2_1Ha"
#                 , "psdDataset_O1OzO2_2Ha"
#                 , "psdDataset_Oz_1Ha"
#                 , "psdDataset_Oz_2Ha"
#                 , "psdDataset_SelChan_1Ha"
#                 , "psdDataset_SelChan_2Ha"
# )
# filenames <- c("psdDataset_SelChan_1Ha")

# for (iF in 1:length(filenames))
# {
#   lmem <- linearReg(filenames[iF])
#   
#   resDir <- "d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciResults/watchERP/04-watchSSVEP-PSD"
#   resDir <- file.path(resDir, filenames[iF])
#   dir.create(resDir, showWarnings=FALSE)  
#   
#   save(lmem, file=file.path(resDir, "linearModels.RData"))
#   
# #   save(lmem, file="d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciResults/watchERP/04-watchSSVEP-PSD/linearModels.RData")
# }
# 
# 
# for (iF in 1:length(filenames))
# {
#   
#   resDir <- "d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciResults/watchERP/04-watchSSVEP-PSD"
#   resDir <- file.path(resDir, filenames[iF])
#   dir.create(resDir, showWarnings=FALSE)  
#   
#   load( file.path(resDir, "linearModels.RData") )
#   
#   pp <- pvals.fnc(lmem$mod004)
#   print(pp)
#   
#   
#   #   save(lmem, file="d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciResults/watchERP/04-watchSSVEP-PSD/linearModels.RData")
# }

####################################################################################################################
####################################################################################################################
