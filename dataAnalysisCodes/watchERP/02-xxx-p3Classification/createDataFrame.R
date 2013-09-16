createDataFrame <- function(aveClass, nRunsForTrain, FS, nFoldSvm)

{
  library(plyr)
  
  filelistname <- "d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciCode/dataAnalysisCodes/watchERP/01-preprocess-plot/watchErpDataset2.csv"
  filelist <- read.csv(filelistname, header = TRUE, sep = ",", strip.white = TRUE)
  allSub <- unique(filelist$subjectTag)
  nSub <- length(allSub)
  
#################################################################################################################
#                                                                                                               #
#                                   LOAD DATA AND CREATE THE DATA FRAME                                         #
#                                                                                                               #
#################################################################################################################

for (iS in 1:nSub)
  {
  #--------------------------------------------------------------------------------------------------------------
  # Load correctness data caclulated with classifiers built on the same type of data as the test data 
  dataDir   <- "d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciProcessedData/watch-ERP/02-xxx-p3Classification"
  folder    <- sprintf("LinSvm_%dRunsForTrain_%dHz_%.2dcvSvm", nRunsForTrain, FS, nFoldSvm)
  subFolder <- sprintf("subject_%s", allSub[iS])
  if (aveClass == 0){ textfile  <- "ResultsClassification.txt" 
  } else{ textfile  <- sprintf("ResultsClassification_%.2dAveClassifier.txt", aveClass) }
  filename  <- file.path(dataDir, folder, subFolder, textfile)
  accData1  <- read.csv(filename, header = TRUE, sep = ",", strip.white = TRUE)
  
  # Factorize what hes to be
  accData1$testingRun     <- as.factor(accData1$testingRun )
  accData1$roundNb        <- as.factor(accData1$roundNb )
  accData1$foldInd        <- as.factor(accData1$foldInd )
  for (iTR in 1:nRunsForTrain){ accData1[[sprintf("trainingRun_%d", iTR)]] <- as.factor(accData1[[sprintf("trainingRun_%d", iTR)]]) }
  # accData1$nAverages = as.factor(accData1$nAverages )
  
  
  #--------------------------------------------------------------------------------------------------------------
  # Load correctness data caclulated with pooled classifiers
  
  folder    <- sprintf("LinSvmPooled_%dRunsForTrain_%dHz_%.2dcvSvm", nRunsForTrain, FS, nFoldSvm)
  subFolder <- sprintf("subject_%s", allSub[iS])
  if (aveClass == 0){ textfile  <- "ResultsClassification.txt" 
  } else{ textfile  <- sprintf("ResultsClassification_%.2dAveClassifier.txt", aveClass) }
  filename  <- file.path(dataDir, folder, subFolder, textfile)
  accData2 <- read.csv(filename, header = TRUE, sep = ",", strip.white = TRUE)
  
  # Factorize what hes to be
  accData2$testingRun     <- as.factor(accData1$testingRun )
  accData2$roundNb        <- as.factor(accData1$roundNb )
  accData2$foldInd        <- as.factor(accData1$foldInd )
  for (iTR in 1:nRunsForTrain){ accData2[[sprintf("trainingRun_%d", iTR)]] <- as.factor(accData2[[sprintf("trainingRun_%d", iTR)]]) }
  
  accData2$nRep <- accData2$nAverages
  accData2 <- accData2[ , !names(accData2) %in% c("nAverages")]
  
  #--------------------------------------------------------------------------------------------------------------
  # Load correctness data caclulated with pooled classifiers trained on all data
  
  folder    <- sprintf("LinSvmPooled_allData_%dRunsForTrain_%dHz_%.2dcvSvm", nRunsForTrain, FS, nFoldSvm)
  subFolder <- sprintf("subject_%s", allSub[iS])
  if (aveClass == 0){ textfile  <- "ResultsClassification.txt" 
  } else{ textfile  <- sprintf("ResultsClassification_%.2dAveClassifier.txt", aveClass) }
  filename  <- file.path(dataDir, folder, subFolder, textfile)
  accData3 <- read.csv(filename, header = TRUE, sep = ",", strip.white = TRUE)
  
  # Factorize what hes to be
  accData3$testingRun     <- as.factor(accData1$testingRun )
  accData3$roundNb        <- as.factor(accData1$roundNb )
  accData3$foldInd        <- as.factor(accData1$foldInd )
  for (iTR in 1:nRunsForTrain){ accData3[[sprintf("trainingRun_%d", iTR)]] <- as.factor(accData3[[sprintf("trainingRun_%d", iTR)]]) }
  
  accData3$nRep <- accData3$nAverages
  accData3 <- accData3[ , !names(accData3) %in% c("nAverages")]

  #--------------------------------------------------------------------------------------------------------------
  # Concatenate the data frames
  accData1$classifier <- "normal"
  accData2$classifier <- "pooled"
  accData3$classifier <- "pooledAll"
  temp <- rbind(accData1, accData2, accData3)
  temp$classifier = as.factor(temp$classifier)
  
  if (iS == 1) { accData <- temp
  } else { accData <- rbind(accData, temp) }
  
}
rm(temp, accData1, accData2, accData3, filename, iS)


#--------------------------------------------------------------------------------------------------------------
# relevel the condition factor
accData$condition = relevel(accData$condition, "hybrid-15Hz")
accData$condition = relevel(accData$condition, "hybrid-12Hz")
accData$condition = relevel(accData$condition, "hybrid-10Hz")
accData$condition = relevel(accData$condition, "hybrid-8-57Hz")
accData$condition = relevel(accData$condition, "oddball")


accData$frequency <- accData$condition
accData$frequency <- revalue(accData$frequency
                             , c("oddball"="0Hz"
                                 , "hybrid-8-57Hz"="8.57Hz"
                                 , "hybrid-10Hz"="10Hz"
                                 , "hybrid-12Hz"="12Hz"
                                 , "hybrid-15Hz"="15Hz"
                                 )
                             )

accData$nRepFac <- as.factor(accData$nRep)
  
#--------------------------------------------------------------------------------------------------------------
#  
accData$trial <- accData$trainingRun_1
if (nRunsForTrain < 1){
  for (iTR in 2:nRunsForTrain){ 
  accData$trial <- accData$trial : accData[[sprintf("trainingRun_%d", iTR)]] 
  }
}
accData$trial <- accData$trial : accData$testingRun : accData$roundNb
accData$trial <- droplevels(accData$trial)
accData$trial <- as.factor(as.numeric(accData$trial))
  
  
#--------------------------------------------------------------------------------------------------------------
# add coding variable for nRep nested within subject
accData$nRepWithinSub <- accData$nRep
allSubs   <- levels(accData$subject)
nSubs   <- length(allSubs)
for (iS in 1:nSubs){
  accData[accData$subject==allSubs[iS], ]$nRepWithinSub <- iS*1000 + accData[accData$subject==allSubs[iS], ]$nRepWithinSub
}
accData$nRepWithinSub <- as.factor(accData$nRepWithinSub)

  return(accData)

}