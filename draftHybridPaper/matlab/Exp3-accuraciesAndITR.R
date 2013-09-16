rm(list = ls())
library(ggplot2)
source("d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciCode/dataAnalysisCodes/watchERP_2stim/04-icon-detection/createSymbolCorrectnessDatasetFnc.R")
source("d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciCode/dataAnalysisCodes/deps/cleanPlot.R")

outputPath = "d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciCode/draftHybridPaper/pix/"

trainRuns     <- c(1,2)
subsetChTag   <- "ch-P-PO-O"
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
accDataset$type <- revalue(accDataset$type, c(p3 = "oddball"))

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


##############################################################################################
##############################################################################################
png(filename = file.path(outputPath, "exp3-ITR.png")
    , width = 900
    , height = 600
    , units = "px"
    #     , res =  600
)
pp5 <- ggplot( ITRDataset, aes(nRepFac, ITR, colour=subject ) )
pp5 <- pp5 + geom_point(position = position_dodge(0.4))
pp5 <- pp5 + geom_line(position = position_dodge(0.4), aes(group=subject), linetype="solid")
pp5 <- pp5 + stat_summary(fun.y=mean, geom="point", colour="black", size=3)
pp5 <- pp5 + stat_summary(fun.y=mean, geom="line", aes(group=type), colour="black", size=1)
pp5 <- pp5 + facet_wrap(~type)
# pp5 <- pp5 + ylim(0, 100)
pp5 <- pp5 + xlab("number of repetitions") + ylab("ITR")
pp5 <- cleanPlot(pp5)
print(pp5)

dev.off()

##############################################################################################
##############################################################################################
png(filename = file.path(outputPath, "exp3-acc.png")
    , width = 900
    , height = 600
    , units = "px"
    #     , res =  600
)

pp6 <- ggplot( ITRDataset, aes(nRepFac, 100*accuracy, colour=subject ) )
pp6 <- pp6 + geom_point(position = position_dodge(0.4))
pp6 <- pp6 + geom_line(position = position_dodge(0.4), aes(group=subject))
pp6 <- pp6 + stat_summary(fun.y=mean, geom="point", colour="black", size=3)
pp6 <- pp6 + stat_summary(fun.y=mean, geom="line", aes(group=type), colour="black", size=1.2)
pp6 <- pp6 + facet_wrap(~type)
# pp6 <- pp6 + ylim(0, 1)
pp6 <- pp6 + xlab("number of repetitions") + ylab("accuracy (%)")
pp6 <- cleanPlot(pp6)
print(pp6)

dev.off()
