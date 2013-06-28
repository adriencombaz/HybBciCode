setwd("d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciCode/dataAnalysisCodes/watchERP_2stim/02--classify-erps-one-classifier-per-stimFreq/")
# rm(list = ls())
library(plyr)

########################################################################################################################################
########################################################################################################################################

tablename <- "d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciCode/dataAnalysisCodes/watchERP_2stim/01-preprocess-plot/watchErpDataset.csv"
filelist <- read.csv(tablename, header = TRUE, sep = ",", strip.white = TRUE)
sub <- unique(filelist$subjectTag)
nSub <- length(sub)

########################################################################################################################################

run = unique( filelist$run )
if ( !identical(run, 1:max(run)) ){ stop("wrong run numbering") }
# listRunsForTrain <- list( 1, 2, 3, c(1, 2), c(2, 3), c(3, 4) )
listRunsForTrain <- list( c(1, 2) )
listTestRun <- lapply( listRunsForTrain, function(x, param) y <- param[param>max(x)], 1:8 )

########################################################################################################################################
resDir <- "d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciProcessedData/watchERP_2stim/02--classify-erps-one-classifier-per-stimFreq"
for (iCond in 1:length(listRunsForTrain)){

  nRunsForTrain <- length( listRunsForTrain[[iCond]] )
  
  condition <- "train"
  for (iTr in 1:nRunsForTrain){condition <- sprintf("%s%d", condition, listRunsForTrain[[iCond]][iTr])}
  condition <- sprintf("%s_test", condition)
  for (iTs in 1:length( listTestRun[[iCond]] )){condition <- sprintf("%s%d", condition, listTestRun[[iCond]][iTs])}  
  
  for (iS in 1:5){
    
    # Load data
    p3file <- file.path( resDir
                         , sprintf("linSvm_%dRunsForTrain", nRunsForTrain)
                         , sprintf("subject_%s", sub[iS])
                         , "Results_forLogisiticRegression.txt")
    p3Dataset_iS <- read.csv(p3file, header = TRUE, sep = ",", strip.white = TRUE)
    
    # Factorise
    p3Dataset_iS$foldInd <- as.factor(p3Dataset_iS$foldInd)
    p3Dataset_iS$testingRun <- as.factor(p3Dataset_iS$testingRun)
    p3Dataset_iS$roundNb <- as.factor(p3Dataset_iS$roundNb)
    p3Dataset_iS$targetFrequency <- as.factor(p3Dataset_iS$targetFrequency)
    for (iTr in 1:nRunsForTrain){
      p3Dataset_iS[ , sprintf("trainingRun_%d", iTr)] <- as.factor(p3Dataset_iS[ , sprintf("trainingRun_%d", iTr)])
    }
    
    # select training run(s)
    for (iTr in 1:nRunsForTrain){
      factorname <- sprintf("trainingRun_%d", iTr)
      factorvalue <- listRunsForTrain[[iCond]][iTr]
      p3Dataset_iS <- p3Dataset_iS[ p3Dataset_iS[ , factorname] == factorvalue,  ]
    }
    
    # select test runs
    p3Dataset_iS <- p3Dataset_iS[ p3Dataset_iS$testingRun %in% listTestRun[[iCond]], ]
    
    # add condition field
    p3Dataset_iS$condition <- condition

    # some cleaning
    p3Dataset_iS$run <- droplevels( p3Dataset_iS$testingRun )
    p3Dataset_iS$nRep <- p3Dataset_iS$nAverages    
    p3Dataset_iS <- p3Dataset_iS[c("condition", "subject", "run", "roundNb", "nRep", "targetFrequency", "correctness")]
        
    # concatenate subjects' data
    if (iCond == 1 && iS == 1) { p3Dataset <- p3Dataset_iS }
    else { p3Dataset <- rbind(p3Dataset, p3Dataset_iS) }   
    
  }
  
#   p3Dataset <- p3Dataset[with(p3Dataset, order(condition, subject, run, roundNb, nRep)), ]

}
p3Dataset$condition <- as.factor(p3Dataset$condition)
row.names(p3Dataset)<-NULL

rm(list=c("filelist", "p3Dataset_iS", "condition", "factorname", "factorvalue", "iCond", "iS", "iTr", "iTs"
          ,"listRunsForTrain", "listTestRun", "nRunsForTrain", "nSub", "p3file", "resDir", "run", "sub", 'tablename'))
