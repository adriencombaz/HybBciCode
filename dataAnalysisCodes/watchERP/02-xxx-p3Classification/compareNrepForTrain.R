library(plyr)

setwd("d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciCode/dataAnalysisCodes/watchERP/02-ter-p3Classification/")
rm(list = ls())

Fs <- 128
nCv <- 10
#################################################################################################################
#                                                                                                               #
#                                   LOAD DATA AND CREATE THE DATA FRAME                                         #
#                                                                                                               #
#################################################################################################################

# for (iS in 1:8)
for (iS in 1:9)
  {
  #--------------------------------------------------------------------------------------------------------------
  # Load correctness data caclulated with classifiers built on the same type of data as the test data 
  filename <- sprintf("d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciProcessedData/watch-ERP/02-xxx-p3Classification/LinSvm_2RunsForTrain_%dHz_%dcvSvm/subject_S%d/Results_CompareNrepForTrain.txt", Fs, nCv, iS)
  accData1 <- read.csv(filename, header = TRUE, sep = ",", strip.white = TRUE)
  
  # Factorize what hes to be
  accData1$trainingRun_1  <- as.factor(accData1$trainingRun_1 )
  accData1$trainingRun_2  <- as.factor(accData1$trainingRun_2 )
  accData1$testingRun     <- as.factor(accData1$testingRun )
  accData1$roundNb        <- as.factor(accData1$roundNb )
  accData1$foldInd        <- as.factor(accData1$foldInd )
  accData1$nAveragesTest <- as.factor(accData1$nAveragesTest )
  accData1$nAveragesTrain <- as.factor(accData1$nAveragesTrain )
  
  
  #--------------------------------------------------------------------------------------------------------------
  # Load correctness data caclulated with pooled classifiers
  
#   filename <- sprintf("d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciProcessedData/watch-ERP/02-ter-p3Classification/LinSvmPooled/subject_S%d/Results_forLogisiticRegression.txt", iS)
#   accData2 <- read.csv(filename, header = TRUE, sep = ",", strip.white = TRUE)
#   
#   # Factorize what hes to be
#   accData2$foldTest = as.factor(accData2$foldTest)
#   # accData2$nAverages = as.factor(accData1$nAverages )
#   
#   # Consider only results from classifier built on first run and tested on the 2 next ones
#   if (iS == 8){
#     temp1 <- subset( accData2, foldTrain == 1 )
#     temp1 <- subset(temp1, conditionTest != "hybrid-12Hz")
#     temp2 <- subset(accData2, conditionTest == "hybrid-12Hz")
#     temp2a <- subset( temp2, foldTrain == 2 )
#     temp2a <- subset( temp2a, foldTest == 3 )
#     temp2b <- subset( temp2, foldTrain == 3 )
#     temp2b <- subset( temp2b, foldTest == 2 )
#     accData2 <- rbind(temp1, temp2a, temp2b)
#     rm(temp1, temp2, temp2a, temp2b) 
#   }
#   else{
#     accData2 <- subset( accData2, foldTrain == 1 )
#   }
#   accData2$foldTrain <- droplevels(accData2)$foldTrain
#   accData2$condition = accData2$conditionTest;
#   
#   # Remove unnecessary columns
#   accData2 <- subset(accData2, select = -c(conditionTest, foldTrain))
#   
#   
#   #--------------------------------------------------------------------------------------------------------------
#   # Concatenate the data frames
  accData1$classifier <- "normal"
#   accData2$classifier <- "pooled"
#   temp <- rbind(accData1, accData2)
#   temp$classifier = as.factor(temp$classifier)
#   
#   if (iS == 1) { accData <- temp }
#   else { accData <- rbind(accData, temp) }
#   
# }
# rm(temp, accData1, accData2, filename, iS)


  if (iS == 1) { accData <- accData1 }
  else { accData <- rbind(accData, accData1) }  
}
#--------------------------------------------------------------------------------------------------------------
# relevel the condition factor
accData$condition = relevel(accData$condition, "hybrid-15Hz")
accData$condition = relevel(accData$condition, "hybrid-12Hz")
accData$condition = relevel(accData$condition, "hybrid-10Hz")
accData$condition = relevel(accData$condition, "hybrid-8-57Hz")
accData$condition = relevel(accData$condition, "oddball")


accData$frequency <- accData$condition
accData$frequency <- revalue(accData$frequency
                             , c("oddball"="0"
                                 , "hybrid-8-57Hz"="8.57"
                                 , "hybrid-10Hz"="10"
                                 , "hybrid-12Hz"="12"
                                 , "hybrid-15Hz"="15"
                             )
)

# accData$nRep <- accData$nAverages
# accData <- subset(accData, select = -c(nAverages))

#--------------------------------------------------------------------------------------------------------------
# add coding variable for nRep nested within subject
# accData$nRepWithinSub <- accData$nRep
# allSubs   <- levels(accData$subject)
# nSubs   <- length(allSubs)
# for (iS in 1:nSubs){
#   accData[accData$subject==allSubs[iS], ]$nRepWithinSub <- iS*1000 + accData[accData$subject==allSubs[iS], ]$nRepWithinSub
# }
# accData$nRepWithinSub <- as.factor(accData$nRepWithinSub)


#################################################################################################################
#                                                                                                               #
#                                   PLOT THE DATA                                                               #
#                                                                                                               #
#################################################################################################################
library(ggplot2)
source("d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciCode/dataAnalysisCodes/deps/cleanPlot.R")
source("d:/KULeuven/PhD/rLibrary/plotFactorMeans_InteractionGraphs.R")
source("d:/KULeuven/PhD/rLibrary/plotInteractionGraphs_level2.R")

plotFactorMeans_InteractionGraphs(accData, c("nAveragesTrain", "nAveragesTest", "frequency"), "correctness")
plotInteractionGraphs_level2(accData, "nAveragesTest", "correctness", c("nAveragesTrain", "frequency"))

pp <- ggplot( accData, aes(nAveragesTest, correctness, colour=nAveragesTrain) )
# pp <- pp + stat_summary(fun.y = mean, geom="point",  position = position_jitter(w = 0.2, h = 0), size = 3)
# pp <- pp + stat_summary(fun.y = mean, geom="point", position = position_dodge(.5))
pp <- pp + stat_summary(fun.data = mean_cl_normal, geom = "pointrange", width = 0.2, position = position_dodge(.5), size = 0.5)
pp <- pp + stat_summary( fun.data = mean_cl_normal , geom = "line" , aes_string(group="nAveragesTrain") , width = 0.2 , position = position_dodge(.5) )
# pp <- pp + facet_grid( subject ~ condition ) 
pp <- pp + facet_wrap( ~subject ) 
pp <- cleanPlot(pp)
# pp <- pp + theme(legend.position=c(0.8334,0.1667))
pp





