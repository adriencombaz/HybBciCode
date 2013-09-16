createP3CorrectnessDataset <- function(Fs, nFoldSvm)
{
library(plyr)

########################################################################################################################################
########################################################################################################################################

tablename <- "d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciCode/dataAnalysisCodes/watchERP_2stim/01-preprocess-plot/watchErpDataset.csv"
filelist <- read.csv(tablename, header = TRUE, sep = ",", strip.white = TRUE)
sub <- unique(filelist$subjectTag)
nSub <- length(sub)

########################################################################################################################################
resDir <- "d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciProcessedData/watchERP_2stim/02-xxx-classify-erps"
for (iS in 1:nSub){
  
  # Load data
  p3file <- file.path( resDir
                       , sprintf("linSvm_%dHz_%.2dcvSVM", Fs, nFoldSvm)
                       , sprintf("subject_%s", sub[iS])
                       , "ResultsClassification.txt")
  p3Dataset_iS <- read.csv(p3file, header = TRUE, sep = ",", strip.white = TRUE)
  
  # Factorise
  p3Dataset_iS$runsForTrain     <- as.factor(p3Dataset_iS$trainingRuns)
  p3Dataset_iS$testingRun       <- as.factor(p3Dataset_iS$testingRun)
  p3Dataset_iS$roundNb          <- as.factor(p3Dataset_iS$roundNb)
  p3Dataset_iS$nRep             <- as.factor(p3Dataset_iS$nAverages)
  p3Dataset_iS$targetFrequency  <- as.factor(p3Dataset_iS$targetFrequency)
  p3Dataset_iS$trial            <- p3Dataset_iS$testingRun : p3Dataset_iS$roundNb
  
  varList <- c("runsForTrain", "subject", "trial", "nRep", "correctness", "targetFrequency", "testingRun", "roundNb")
  p3Dataset_iS <- p3Dataset_iS[, varList]
  
  # concatenate subjects' data
  if (iS == 1) { p3Dataset <- p3Dataset_iS }
  else { p3Dataset <- rbind(p3Dataset, p3Dataset_iS) }   
  
}

p3Dataset <- p3Dataset[with(p3Dataset, order(runsForTrain, subject, trial, nRep)), ]

row.names(p3Dataset)<-NULL

return(p3Dataset)

}