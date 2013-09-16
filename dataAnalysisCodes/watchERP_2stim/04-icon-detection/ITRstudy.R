setwd("d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciCode/dataAnalysisCodes/watchERP_2stim/04-icon-detection/")

rm(list = ls())
library(ggplot2)
source("createSymbolCorrectnessDatasetFnc.R")
source("d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciCode/dataAnalysisCodes/deps/cleanPlot.R")

figDir = "d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciResults/watchERP_2stim/04-icon-detection/"

trainRuns     <- c(1,2)
subsetChTag   <- "ch-CP-P-PO-O"
harmonicsTag  <- "fund-ha1"
FS            <- 128
nFoldSvm      <- 10

accDataset <- createSymbolCorrectnessDatasetFnc(trainRuns, subsetChTag, harmonicsTag, FS, nFoldSvm)
accDataset$stimDuration <- accDataset$nRep*6*0.25
accDataset$nChoices <- 0
accDataset[accDataset$type=="p3", ]$nChoices <- 6
accDataset[accDataset$type=="ssvep", ]$nChoices <- 2
accDataset[accDataset$type=="symbol", ]$nChoices <- 12
accDataset$nSymbols <- 1

varList <- c( "type", "subject", "nRepFac" )
ITRDataset <- ddply( accDataset, varList, summarize 
                    , nChoices = unique(nChoices)
                    , nRep = unique(nRep)
                    , stimDuration = unique(stimDuration) 
                    , accuracy = mean(correctness)
                    , ITR = ( 
                      log2(unique(nChoices)) + mean(correctness)*log2( max( mean(correctness), 0.000000001 ) )
                      + (1-mean(correctness))*log2( max( (1-mean(correctness)), 0.000000001) / (unique(nChoices)-1) ) 
                      ) * 60 / mean(stimDuration)
                     )

# allTypes <- unique(accDataset$type)
# allSub <- unique(accDataset$subject)
# allReps <- unique(accDataset$nRepFac)
# nTypes <- length(allTypes)
# nSub <- length(allSub)
# nReps <- length(allReps)
# ind <- 1
# ITR <- vector(mode="numeric", length=nTypes*nSub*nReps)
# for (iT in 1:nTypes){
#   for (iS in 1:nSub){
#     for (iR in 1:nReps){
#       temp <- accDataset[accDataset$type==allTypes[iT] & accDataset$subject==allSub[iS] & accDataset$nRepFac==allReps[iR], ]
#       temp$type <- droplevels(temp$type)
#       temp$subject <- droplevels(temp$subject)
#       temp$nRepFac <- droplevels(temp$nRepFac)
#       p <- mean(temp$correctness)
#       nc <- unique(temp$nChoices)
#       if (p==0 || p==1){ ITR[ind] <- log2(nc) *60 / mean(temp$stimDuration)
#       }else{ ITR[ind] <- (log2(nc) + p*log2(p) + (1-p)*log2((1-p)/(nc-1))) *60 / mean(temp$stimDuration) }
#       ind <- ind+1
#     }
#   }
# }
  
pp <- ggplot( ITRDataset, aes(nRepFac, ITR, colour=type ) )
pp <- pp + geom_point(shape = 20, size = 3)
pp <- pp + geom_line(aes(group=type))
pp <- pp + facet_wrap(~subject)
# pp <- pp + ylim(0, 100)
pp <- cleanPlot(pp)
print(pp)

pp2 <- ggplot( ITRDataset, aes(nRepFac, 100*accuracy, colour=type ) )
pp2 <- pp2 + geom_point(position = position_dodge(0.2), shape = 20, size = 3)
pp2 <- pp2 + geom_line(position = position_dodge(0.2), aes(group=type))
pp2 <- pp2 + facet_wrap(~subject)
# pp2 <- pp2 + ylim(0, 100)
pp2 <- cleanPlot(pp2)
print(pp2)

pp3 <- ggplot( ITRDataset, aes(stimDuration, ITR, colour=subject ) )
pp3 <- pp3 + geom_point(position = position_dodge(0.4), shape = 20, size = 3)
pp3 <- pp3 + geom_line(position = position_dodge(0.4), aes(group=subject))
pp3 <- pp3 + facet_wrap(~type)
# pp3 <- pp3 + ylim(0, 100)
pp3 <- cleanPlot(pp3)
print(pp3)

pp4 <- ggplot( ITRDataset, aes(stimDuration, accuracy, colour=subject ) )
pp4 <- pp4 + geom_point(position = position_dodge(0.4), shape = 20, size = 3)
pp4 <- pp4 + geom_line(position = position_dodge(0.4), aes(group=subject))
pp4 <- pp4 + facet_wrap(~type)
pp4 <- pp4 + ylim(0, 1)
pp4 <- cleanPlot(pp4)
print(pp4)

##############################################################################################"
##############################################################################################"
pp5 <- ggplot( ITRDataset, aes(as.factor(stimDuration), ITR, colour=subject ) )
pp5 <- pp5 + geom_point(position = position_dodge(0.4))
pp5 <- pp5 + geom_line(position = position_dodge(0.4), aes(group=subject), linetype="solid")
pp5 <- pp5 + stat_summary(fun.y=mean, geom="point", colour="black", size=3)
pp5 <- pp5 + stat_summary(fun.y=mean, geom="line", aes(group=type), colour="black", size=1)
pp5 <- pp5 + facet_wrap(~type)
# pp5 <- pp5 + ylim(0, 100)
pp5 <- cleanPlot(pp5)
print(pp5)

pp6 <- ggplot( ITRDataset, aes(nRepFac, 100*accuracy, colour=subject ) )
pp6 <- pp6 + geom_point(position = position_dodge(0.4))
pp6 <- pp6 + geom_line(position = position_dodge(0.4), aes(group=subject))
pp6 <- pp6 + stat_summary(fun.y=mean, geom="point", colour="black", size=3)
pp6 <- pp6 + stat_summary(fun.y=mean, geom="line", aes(group=type), colour="black", size=1.2)
pp6 <- pp6 + facet_wrap(~type)
# pp6 <- pp6 + ylim(0, 1)
pp6 <- cleanPlot(pp6)
print(pp6)
