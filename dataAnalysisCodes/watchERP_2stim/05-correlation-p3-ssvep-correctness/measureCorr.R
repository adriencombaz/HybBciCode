setwd("d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciCode/dataAnalysisCodes/watchERP_2stim/05-correlation-p3-ssvep-correctness/")
rm(list = ls())

nSubjects <- 6;
corrCoef <- matrix( data = NA, nrow = 1, ncol = nSubjects)
# iSub <- 1
for (iSub in 1:6)
{  
  #################################################################################################################
  #                                 LOAD SSVEP DATA
  #################################################################################################################
  subsetCh <- c( "C3", "Cz", "C4", "CP5", "CP1", "CP2", "CP6", "P7", "P3", "Pz", "P4", "P8", "PO3", "PO4", "O1", "Oz", "O2" )
  harmonics <- c(0, 1)
  runs <- c(3,4,5,6,7,8)
  
  filename  <- sprintf("d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciProcessedData/watchERP_2stim/03-classify-ssveps/snrs_subjectS%d.txt", iSub)
  snrDataiS   <- read.csv(filename, header = TRUE, sep = ",", strip.white = TRUE)  
  
  snrDataiS$run               <- as.factor(snrDataiS$run)
  snrDataiS$roundNb           <- as.factor(snrDataiS$roundNb)
  snrDataiS$nRep              <- as.factor(snrDataiS$nRep)    
  snrDataiS$targetFrequency   <- as.factor(snrDataiS$targetFrequency)
  snrDataiS$watchedFrequency  <- as.factor(snrDataiS$watchedFrequency)
  snrDataiS$harmonic          <- as.factor(snrDataiS$harmonic)
  
  snrDataiS <- snrDataiS[ snrDataiS$channel %in% subsetCh & snrDataiS$harmonic %in% harmonics & snrDataiS$run %in% runs, ]
  snrDataiS$channel <- droplevels( snrDataiS$channel )
  snrDataiS$harmonic <- droplevels( snrDataiS$harmonic )
  snrDataiS$run <- droplevels( snrDataiS$run )
  
  varList <- c( "subject", "run","roundNb", "nRep", "targetFrequency", "watchedFrequency", "snr" )
  snrDataiS <- snrDataiS[ , (names(snrDataiS) %in% varList)]
  
  varList <- c( "subject", "run","roundNb", "nRep", "targetFrequency", "watchedFrequency" )
  snrDataiS <- ddply(snrDataiS, varList, summarize, snr = mean(snr))
  
  varList <- c( "subject", "run","roundNb", "nRep" )
  ssvepDataset <- ddply( snrDataiS, varList, summarize, 
                      correctness_ssvep = ( unique(targetFrequency) == watchedFrequency[which.max(snr)] ) * 1 )
  
  #################################################################################################################
  #                                 LOAD P3 DATA
  #################################################################################################################
  source("d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciCode/dataAnalysisCodes/watchERP_2stim/02-classify-erps/createP3CorrectnessDataset.R")
  p3Dataset <- p3Dataset[ p3Dataset$condition=="train12_test345678" , ]
  p3Dataset <- p3Dataset[ p3Dataset$subject==as.character(unique(ssvepDataset$subject)) , ]
  p3Dataset$nRep <- as.factor(p3Dataset$nRep)    
  p3Dataset$run <- droplevels( p3Dataset$run )
  p3Dataset$subject <- droplevels( p3Dataset$subject )
  p3Dataset$correctness_p3 <- p3Dataset$correctness  
  
  varList   <- c("subject", "run", "roundNb", "nRep", "correctness_p3")
  p3Dataset <- p3Dataset[ , (names(p3Dataset) %in% varList)]

  #################################################################################################################
  #                                 COMBINE THE DATASET
  #################################################################################################################
  p3Dataset     <- p3Dataset[with(p3Dataset, order(run, roundNb, nRep)), ]
  ssvepDataset  <- ssvepDataset[with(ssvepDataset, order(run, roundNb, nRep)), ]
  
  varList   <- c("subject", "run", "roundNb", "nRep")
  temp1 <- p3Dataset[ , (names(p3Dataset) %in% varList)]
  temp2 <- ssvepDataset[ , (names(ssvepDataset) %in% varList)]
  row.names(temp1)<-NULL
  row.names(temp2)<-NULL
  if (!identical(temp1, temp2)){stop('smth wrong here')}

  datasetCorr <- p3Dataset;
  datasetCorr$correctness_ssvep <- ssvepDataset$correctness_ssvep
  
  #################################################################################################################
  #                                 CORRELATION COEEFICIENT
  #################################################################################################################
  #   datasetCorr$correctness_ssvep <- 2*datasetCorr$correctness_ssvep - 1
  #   datasetCorr$correctness_p3 <- 2*datasetCorr$correctness_p3 - 1
  
  corrCoef[iSub] <- cor(datasetCorr$correctness_p3, datasetCorr$correctness_ssvep)


  #################################################################################################################
  #                                 CONFUSION MATRIX
  #################################################################################################################
  print( table(datasetCorr$correctness_p3, datasetCorr$correctness_ssvep) )
}