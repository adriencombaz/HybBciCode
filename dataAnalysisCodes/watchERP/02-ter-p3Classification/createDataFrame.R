library(plyr)

setwd("d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciCode/dataAnalysisCodes/watchERP/02-ter-p3Classification/")
rm(list = ls())
#################################################################################################################
#                                                                                                               #
#                                   LOAD DATA AND CREATE THE DATA FRAME                                         #
#                                                                                                               #
#################################################################################################################

for (iS in 1:8)
{
  #--------------------------------------------------------------------------------------------------------------
  # Load correctness data caclulated with classifiers built on the same type of data as the test data 
  
  filename <- sprintf("d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciProcessedData/watch-ERP/02-ter-p3Classification/LinSvm/subject_S%d/Results_forLogisiticRegression.txt", iS)
  accData1 <- read.csv(filename, header = TRUE, sep = ",", strip.white = TRUE)

  # Factorize what hes to be
  accData1$foldTest = as.factor(accData1$foldTest )
  # accData1$nAverages = as.factor(accData1$nAverages )
  
  # Consire only results calculated with a classifier build on  
  # data recorded in the same condition as they were tested
  accData1 <- subset( accData1, conditionTrain == conditionTest)
  accData1$condition = accData1$conditionTrain;
  
  # Consider only results from classifier built on first run and tested on the 2 next ones
  if (iS == 8){
    temp1 <- subset( accData1, foldTrain == 1 )
    temp1 <- subset(temp1, condition != "hybrid-12Hz")
    temp2 <- subset(accData1, condition == "hybrid-12Hz")
    temp2a <- subset( temp2, foldTrain == 2 )
    temp2a <- subset( temp2a, foldTest == 3 )
    temp2b <- subset( temp2, foldTrain == 3 )
    temp2b <- subset( temp2b, foldTest == 2 )
    accData1 <- rbind(temp1, temp2a, temp2b)
    rm(temp1, temp2, temp2a, temp2b) 
  }
  else{
    accData1 <- subset( accData1, foldTrain == 1 )
  }
  accData1$foldTrain <- droplevels(accData1)$foldTrain    

  # Remove unnecessary columns
  accData1 <- subset(accData1, select = -c(conditionTrain, conditionTest, foldTrain))
  
  #--------------------------------------------------------------------------------------------------------------
  # Load correctness data caclulated with pooled classifiers
  
  filename <- sprintf("d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciProcessedData/watch-ERP/02-ter-p3Classification/LinSvmPooled/subject_S%d/Results_forLogisiticRegression.txt", iS)
  accData2 <- read.csv(filename, header = TRUE, sep = ",", strip.white = TRUE)
  
  # Factorize what hes to be
  accData2$foldTest = as.factor(accData2$foldTest)
  # accData2$nAverages = as.factor(accData1$nAverages )
  
  # Consider only results from classifier built on first run and tested on the 2 next ones
  if (iS == 8){
    temp1 <- subset( accData2, foldTrain == 1 )
    temp1 <- subset(temp1, conditionTest != "hybrid-12Hz")
    temp2 <- subset(accData2, conditionTest == "hybrid-12Hz")
    temp2a <- subset( temp2, foldTrain == 2 )
    temp2a <- subset( temp2a, foldTest == 3 )
    temp2b <- subset( temp2, foldTrain == 3 )
    temp2b <- subset( temp2b, foldTest == 2 )
    accData2 <- rbind(temp1, temp2a, temp2b)
    rm(temp1, temp2, temp2a, temp2b) 
  }
  else{
    accData2 <- subset( accData2, foldTrain == 1 )
  }
  accData2$foldTrain <- droplevels(accData2)$foldTrain
  accData2$condition = accData2$conditionTest;
  
  # Remove unnecessary columns
  accData2 <- subset(accData2, select = -c(conditionTest, foldTrain))
  
  
  #--------------------------------------------------------------------------------------------------------------
  # Concatenate the data frames
  accData1$classifier <- "normal"
  accData2$classifier <- "pooled"
  temp <- rbind(accData1, accData2)
  temp$classifier = as.factor(temp$classifier)
  
  if (iS == 1) { accData <- temp }
  else { accData <- rbind(accData, temp) }
  
}
rm(temp, accData1, accData2, filename, iS)


#--------------------------------------------------------------------------------------------------------------
# consider only a limited number of averages
# temp <- subset(accData, nRep == 1)
# temp2 <- subset(accData, nRep == 5)
# temp3 <- subset(accData, nRep == 10)
# accData <- rbind(temp, temp2, temp3)
# accData$nRep <- droplevels(accData)$nRep
# rm(temp, temp2, temp3)

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

accData$nRep <- accData$nAverages
accData <- subset(accData, select = -c(nAverages))
