createSymbolCorrectnessDatasetFnc <- function(trainRuns, subsetChTag, harmonicsTag, FS, nFoldSvm)
{
library(plyr)
library("reshape2")

########################################################################################################################################
########################################################################################################################################

tablename <- "d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciCode/dataAnalysisCodes/watchERP_2stim/01-preprocess-plot/watchErpDataset.csv"
filelist <- read.csv(tablename, header = TRUE, sep = ",", strip.white = TRUE)
sub <- unique(filelist$subjectTag)
nSub <- length(sub)

run = unique( filelist$run )
if ( !identical(run, 1:max(run)) ){ stop("wrong run numbering") }
runsForTrain <- trainRuns
testRun <- run[run>max(runsForTrain)]
nRunsForTrain <- length(runsForTrain)

trainTag <- "train"
for (iR in 1:nRunsForTrain){ trainTag <- sprintf("%s%d", trainTag, trainRuns[iR])}
########################################################################################################################################
# P3 DATA
########################################################################################################################################

resDirP3 <- "d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciProcessedData/watchERP_2stim/02-xxx-classify-erps"
for (iS in 1:nSub){
  
  # Load data
  p3file <- file.path( resDirP3
                       , sprintf("linSvm_%dHz_%.2dcvSVM", FS, nFoldSvm)
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
  
  # 
  p3Dataset_iS <- p3Dataset_iS[p3Dataset_iS$runsForTrain == trainTag, ]
  p3Dataset_iS$runsForTrain <- droplevels(p3Dataset_iS$runsForTrain)
  p3Dataset_iS$testingRun   <- droplevels(p3Dataset_iS$testingRun)
  p3Dataset_iS$trial        <- droplevels(p3Dataset_iS$trial)

  # 
  varList <- c("subject", "trial", "nRep", "correctness", "targetFrequency", "testingRun", "roundNb")
  p3Dataset_iS <- p3Dataset_iS[ , (names(p3Dataset_iS) %in% varList)]
  p3Dataset_iS <- p3Dataset_iS[, varList]
  
  # concatenate subjects' data
  if (iS == 1) { p3Dataset <- p3Dataset_iS }
  else { p3Dataset <- rbind(p3Dataset, p3Dataset_iS) }   
  
}

p3Dataset <- p3Dataset[with(p3Dataset, order(subject, trial, nRep)), ]

row.names(p3Dataset)<-NULL

########################################################################################################################################
# SSVEP DATA
########################################################################################################################################

resDirSsvep <- "d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciProcessedData/watchERP_2stim/03-classify-ssveps"
for (iS in 1:nSub){
  
  # Load data
  filename <- file.path( resDirSsvep, sprintf("%s_%s", subsetChTag, harmonicsTag), sprintf("snrs_subject%s.txt", sub[iS]) )
  snrDataiS   <- read.csv(filename, header = TRUE, sep = ",", strip.white = TRUE)  
  
  # Factorise
  snrDataiS$testingRun        <- as.factor(snrDataiS$run)
  snrDataiS$roundNb           <- as.factor(snrDataiS$roundNb)
  snrDataiS$nRep              <- as.factor(snrDataiS$nRep)
  snrDataiS$targetFrequency   <- as.factor(snrDataiS$targetFrequency)
  snrDataiS$watchedFrequency  <- as.factor(snrDataiS$watchedFrequency)
  snrDataiS$trial             <- snrDataiS$testingRun : snrDataiS$roundNb
  
  # Consider only the chosen runs
  snrDataiS <- snrDataiS[ snrDataiS$run %in% testRun, ]
  snrDataiS$testingRun  <- droplevels(snrDataiS$testingRun)
  snrDataiS$trial       <- droplevels(snrDataiS$trial)
  
  # generate correctness dataset from snr values
  varList <- c( "subject", "trial", "nRep" )
  accDataiS <- ddply( snrDataiS, varList, summarize 
                      , testingRun = unique(testingRun)
                      , roundNb = unique(roundNb)
                      , targetFrequency = unique(targetFrequency) 
                      , correctness = ( unique(targetFrequency) == watchedFrequency[which.max(snr)] ) * 1 )
  
  # select the factors to consider
  varList <- c("subject", "trial", "nRep", "correctness", "targetFrequency", "testingRun", "roundNb")
  accDataiS <- accDataiS[ , (names(accDataiS) %in% varList)]
  accDataiS <- accDataiS[, varList]
  
  
  if (iS == 1) { ssvepDataset <- accDataiS }
  else { ssvepDataset <- rbind(ssvepDataset, accDataiS) }
  
}
ssvepDataset <- ssvepDataset[with(ssvepDataset, order(subject, trial, nRep)), ]

########################################################################################################################################
# DATASET COMBINING P3, SSVEP AND SYMBOL CORRECTNESS
########################################################################################################################################

p3Dataset$type    <- as.factor("p3")
ssvepDataset$type <- as.factor("ssvep")
temp <- rbind(p3Dataset, ssvepDataset)

temp <- dcast(temp, subject + trial + nRep + targetFrequency + testingRun + roundNb ~ type, value.var="correctness")
temp$symbol <- (temp$p3 & temp$ssvep)*1

accDataset <- melt( temp
               , id.vars=c("subject", "trial", "nRep", "targetFrequency", "testingRun", "roundNb")
               , measure.vars=c("p3", "ssvep", "symbol")
               , variable.name="type"
               , value.name="correctness")

accDataset$nRep <- as.numeric(accDataset$nRep)
accDataset$nRepFac <- as.factor(accDataset$nRep)
return(accDataset)

}