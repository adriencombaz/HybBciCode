createSymbolCorrectnessDataset <- function(aveClass, nRunsForTrain, FS, nFoldSvm)
{
  # library(plyr)
library("reshape2")

########################################################################################################################################
########################################################################################################################################

tablename <- "d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciCode/dataAnalysisCodes/watchERP_2stim/01-preprocess-plot/watchErpDataset.csv"
filelist <- read.csv(tablename, header = TRUE, sep = ",", strip.white = TRUE)
sub <- unique(filelist$subjectTag)
nSub <- length(sub)

run = unique( filelist$run )
if ( !identical(run, 1:max(run)) ){ stop("wrong run numbering") }
runsForTrain <- c(1, 2)
testRun <- run[run>max(runsForTrain)]
nRunsForTrain <- length(runsForTrain)

subsetCh <- c( "C3", "Cz", "C4", "CP5", "CP1", "CP2", "CP6", "P7", "P3", "Pz", "P4", "P8", "PO3", "PO4", "O1", "Oz", "O2" )
harmonics <- c(0, 1)

########################################################################################################################################
# P3 DATA
########################################################################################################################################


for (iS in 1:nSub){
  
  #--------------------------------------------------------------------------------------------------------------
  # Load correctness data caclulated with classifiers built on the same type of data as the test data 
  p3Folder <- file.path( "d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciProcessedData/watchERP_2stim/02-classify-erps"
                       , sprintf("LinSvm_%dRunsForTrain_%dHz_%.2dcvSvm", nRunsForTrain, FS, nFoldSvm)
                       , sprintf("subject_%s", sub[iS]) )
  if (aveClass == 0){ textfile  <- "Results_forLogisiticRegression.txt" 
  } else{ textfile  <- sprintf("Results_forLogisiticRegression_%.2dAveClassifier.txt", aveClass) }
  p3file  <- file.path(p3Folder, textfile)
  p3Dataset_iS <- read.csv(p3file, header = TRUE, sep = ",", strip.white = TRUE)
  
  # Factorise
  p3Dataset_iS$foldInd          <- as.factor(p3Dataset_iS$foldInd)
  p3Dataset_iS$testingRun       <- as.factor(p3Dataset_iS$testingRun)
  p3Dataset_iS$roundNb          <- as.factor(p3Dataset_iS$roundNb)
  p3Dataset_iS$targetFrequency  <- as.factor(p3Dataset_iS$targetFrequency)
  p3Dataset_iS$nAverages        <- as.factor(p3Dataset_iS$nAverages)
  for (iTr in 1:nRunsForTrain){
    p3Dataset_iS[ , sprintf("trainingRun_%d", iTr)] <- as.factor(p3Dataset_iS[ , sprintf("trainingRun_%d", iTr)])
  }
  
  # select training run(s)
  for (iTr in 1:nRunsForTrain){
    factorname <- sprintf("trainingRun_%d", iTr)
    factorvalue <- runsForTrain[iTr]
    p3Dataset_iS <- p3Dataset_iS[ p3Dataset_iS[ , factorname] == factorvalue,  ]
  }
  
  # select test runs
  p3Dataset_iS <- p3Dataset_iS[ p3Dataset_iS$testingRun %in% testRun, ]
  
  
  # some cleaning
  p3Dataset_iS$run <- droplevels( p3Dataset_iS$testingRun )
  p3Dataset_iS$nRep <- p3Dataset_iS$nAverages    
  p3Dataset_iS <- p3Dataset_iS[c("subject", "run", "roundNb", "nRep", "targetFrequency", "correctness")]
  
  # concatenate subjects' data
  if (iS == 1) { p3Dataset <- p3Dataset_iS }
  else { p3Dataset <- rbind(p3Dataset, p3Dataset_iS) }   
}

########################################################################################################################################
# SSVEP DATA
########################################################################################################################################

for (iS in 1:nSub){
  
  # Load data
  filename  <- sprintf("d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciProcessedData/watchERP_2stim/03-classify-ssveps/snrs_subjectS%d.txt", iS)
  snrDataiS   <- read.csv(filename, header = TRUE, sep = ",", strip.white = TRUE)  
  
  # Factorise
  snrDataiS$run               <- as.factor(snrDataiS$run)
  snrDataiS$roundNb           <- as.factor(snrDataiS$roundNb)
  snrDataiS$nRep              <- as.factor(snrDataiS$nRep)
  snrDataiS$targetFrequency   <- as.factor(snrDataiS$targetFrequency)
  snrDataiS$watchedFrequency  <- as.factor(snrDataiS$watchedFrequency)
  snrDataiS$harmonic          <- as.factor(snrDataiS$harmonic)
  
  # select runs, channels and harmonics
  snrDataiS <- snrDataiS[ snrDataiS$run %in% testRun & snrDataiS$harmonic %in% harmonics, ]
  if (!identical(subsetCh, "all")){ snrDataiS <- snrDataiS[ snrDataiS$channel %in% subsetCh, ] }
  snrDataiS$channel <- droplevels( snrDataiS$channel )
  snrDataiS$harmonic <- droplevels( snrDataiS$harmonic )
  snrDataiS$run <- droplevels( snrDataiS$run )
  
  # select the factors to consider
  varList <- c( "subject", "run","roundNb", "nRep", "targetFrequency", "watchedFrequency", "snr" )
  snrDataiS <- snrDataiS[ , (names(snrDataiS) %in% varList)]
  
  # average snrs over channels and harmonics
  varList <- c( "subject", "run","roundNb", "nRep", "targetFrequency", "watchedFrequency" )
  snrDataiS <- ddply(snrDataiS, varList, summarize, snr = mean(snr))
  
  # generate correctness dataset from snr values
  varList <- c( "subject", "run","roundNb", "nRep" )
  accDataiS <- ddply( snrDataiS, varList, summarize, 
                      targetFrequency = unique(targetFrequency), 
                      correctness = ( unique(targetFrequency) == watchedFrequency[which.max(snr)] ) * 1 )
  
 
  if (iS == 1) { ssvepDataset <- accDataiS }
  else { ssvepDataset <- rbind(ssvepDataset, accDataiS) }
  
}

########################################################################################################################################
# DATASET COMBINING P3, SSVEP AND SYMBOL CORRECTNESS
########################################################################################################################################

p3Dataset$type    <- as.factor("p3")
ssvepDataset$type <- as.factor("ssvep")
temp <- rbind(p3Dataset, ssvepDataset)

temp <- dcast(temp, subject + run + roundNb + nRep + targetFrequency ~ type, value.var="correctness")
temp$symbol <- (temp$p3 & temp$ssvep)*1

accDataset <- melt( temp
               , id.vars=c("subject", "run", "roundNb", "nRep", "targetFrequency")
               , measure.vars=c("p3", "ssvep", "symbol")
               , variable.name="type"
               , value.name="correctness")

# check <- test2[ test2$type=="ssvep", ]
# check$type <- droplevels( check$type )
# check <- check[ , c("subject", "run", "roundNb", "nRep", "targetFrequency", "type", "correctness")]
# check2 <- ssvepDataset[ , c("subject", "run", "roundNb", "nRep", "targetFrequency", "type", "correctness")]
# check <- check[with(check, order(subject, run, roundNb, nRep)), ]
# check2 <- check2[with(check2, order(subject, run, roundNb, nRep)), ]
# rownames(check) <- NULL
# rownames(check2) <- NULL
# identical(check, check2)

}