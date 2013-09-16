createSnrDatasetFnc <- function(runs, subsetChTag, harmonicsTag){
  
  ########################################################################################################################################
  ########################################################################################################################################
  
  tablename <- "d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciCode/dataAnalysisCodes/watchERP_2stim/01-preprocess-plot/watchErpDataset.csv"
  filelist <- read.csv(tablename, header = TRUE, sep = ",", strip.white = TRUE)
  sub <- unique(filelist$subjectTag)
  nSub <- length(sub)
  
  resDir <- "d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciProcessedData/watchERP_2stim/03-classify-ssveps"
  
  ########################################################################################################################################
  ########################################################################################################################################
  for (iS in 1:nSub){    
 
    # Load data
    p3file <- file.path( resDir, sprintf("%s_%s", subsetChTag, harmonicsTag), sprintf("snrs_subject%s.txt", sub[iS]) )
    snrDataiS <- read.csv(p3file, header = TRUE, sep = ",", strip.white = TRUE)
    
    # Factorise
    snrDataiS$run               <- as.factor(snrDataiS$run)
    snrDataiS$roundNb           <- as.factor(snrDataiS$roundNb)
    snrDataiS$targetFrequency   <- as.factor(snrDataiS$targetFrequency)
    snrDataiS$watchedFrequency  <- as.factor(snrDataiS$watchedFrequency)
    snrDataiS$winnerFreq        <- as.factor(snrDataiS$winnerFreq)
    
    # Consider only the chosen runs
    snrDataiS <- snrDataiS[ snrDataiS$run %in% runs, ]
    snrDataiS$run <- droplevels(snrDataiS$run)
    
    # concatenate subjects' data
    if (iS == 1) { snrData <- snrDataiS } else{ snrData <- rbind(snrData, snrDataiS) }
  }  

  # bit of rearranging before returning the data frame
  snrData$nRepFac <- as.factor(snrData$nRep)
  snrData$trial   <- snrData$run : snrData$roundNb
  varList <- c( "subject", "trial", "nRep", "targetFrequency", "watchedFrequency", "snr", "nCompSP", "run","roundNb", "nRepFac" )
  snrData <- snrData[ , (names(snrData) %in% varList)]
  snrData <- snrData[ , varList]
  snrData <- snrData[with(snrData, order(subject, trial, nRep, targetFrequency, watchedFrequency)), ]
  
  snrData$isTarget <- (snrData$watchedFrequency == snrData$targetFrequency)*1
  snrData$isTarget <- as.factor(snrData$isTarget)  
  return(snrData)
  
}