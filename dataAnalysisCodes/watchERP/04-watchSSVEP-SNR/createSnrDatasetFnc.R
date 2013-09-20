createSnrDatasetFnc <- function(subsetChTag, harmonicsTag){
  
  ########################################################################################################################################
  ########################################################################################################################################
  library(plyr)
  tablename <- "d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciCode/dataAnalysisCodes/watchERP/04-watchSSVEP-SNR/watchFftDataset.csv"
  filelist <- read.csv(tablename, header = TRUE, sep = ",", strip.white = TRUE)
  sub <- unique(filelist$subjectTag)
  nSub <- length(sub)
  
  resDir <- "d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciProcessedData/watchERP/04-watchSSVEP-SNR"
  
  ########################################################################################################################################
  ########################################################################################################################################
#   for (iS in 1:nSub){
  for (iS in 1:nSub){
      
    filename <- file.path( resDir, sprintf("%s_%s", subsetChTag, harmonicsTag), sprintf("snrs_subject%s.txt", sub[iS]) )
    snrDataiS <- read.csv(filename, header = TRUE, sep = ",", strip.white = TRUE)
  
    # Factorise
    snrDataiS$run               <- as.factor(snrDataiS$run)
    snrDataiS$roundNb           <- as.factor(snrDataiS$roundNb)
    snrDataiS$watchedFrequency  <- as.factor(snrDataiS$watchedFrequency)
    snrDataiS$targetFrequency   <- as.factor(snrDataiS$targetFrequency)
    snrDataiS$oddball           <- as.factor(snrDataiS$oddball)
    
#     varList <- c( "subject", "run", "roundNb", "time" )
#     accDataiS <- ddply( snrDataiS, varList, summarize 
#                       , targetFrequency = unique(targetFrequency)
#                       , oddball = unique(oddball)
#                       , correctness = ( unique(targetFrequency) == watchedFrequency[which.max(snr)] ) * 1 
#     )        
# 
#     # concatenate subjects' data
#     if (iS == 1) { accData <- accDataiS } else{ accData <- rbind(accData, accDataiS) }  
  # concatenate subjects' data
  if (iS == 1) { snrData <- snrDataiS } else{ snrData <- rbind(snrData, snrDataiS) }  
    
  }
    
  return(snrData)
  
}