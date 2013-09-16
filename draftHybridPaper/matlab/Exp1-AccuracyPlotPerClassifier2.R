setwd("d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciCode/dataAnalysisCodes/watchERP/02-xxx-p3Classification/")
rm(list = ls())

library(ggplot2)
library(plyr)
library(car)
# library(reshape2)
# library(lme4)
# library(LMERConvenienceFunctions)
# library(languageR)
# library(Hmisc)

source("createDataFrame.R")
source("d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciCode/dataAnalysisCodes/deps/cleanPlot.R")
source("d:/KULeuven/PhD/rLibrary/plotFactorMeans_InteractionGraphs.R")
outputPath <- "d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciCode/draftHybridPaper/pix/"

aveClass <- 0
nRunsForTrain <- 2
FS <- 128
nFoldSvm <- 10

accData <- createDataFrame(aveClass, nRunsForTrain, FS, nFoldSvm)

accData <- accData[accData$subject != "S08",]
accData$subject <- revalue(accData$subject, c("S09"="S08", "S10"="S09"))
accData$subject <- droplevels(accData$subject)
# levels(accData$subject)
accData <- accData[accData$classifier != "pooled",]
accData$classifier <- droplevels(accData$classifier)
accData <- accData[accData$condition != "oddball", ]
accData$condition <- droplevels(accData$condition)
accData$frequency <- droplevels(accData$frequency)
accData$classifier <- revalue( accData$classifier
                               , c("normal"="specific"
                                   , "pooledAll"="general"))
str(accData)
summary(accData)

#################################################################################################################
#                                                                                                               #
#                                         PLOT PER SUBJECT DATA                                                 #
#                                                                                                               #
#################################################################################################################
# varList <- c("subject", "nRepFac", "classifier")
# accData2 <- ddply( accData, varList, summarize 
#                    , meanCorr = mean(correctness)
#                    , nRep = unique(nRep)
#                    )
# 
# varList <- c("nRepFac", "classifier")
# temp <- ddply( accData, varList, summarize 
#                , meanCorr = mean(correctness)
#                , nRep = unique(nRep)
#                )
# 
# temp$subject <- "grand mean"
# accData2 <- rbind(accData2, temp)
# 
# str(accData2)
# summary(accData2)
# 
# 
# #################################################################################################################
# #################################################################################################################
# 
# png(filename = file.path(outputPath, "P3AccuracyPerClassifierPerSubject.png")
#     , width = 900
#     , height = 600
#     , units = "px"
# )
# 
# pp <- ggplot( accData2, aes(nRepFac, meanCorr, colour=classifier) )
# pp <- pp + geom_point(width = 0.2, position = position_dodge(.3))
# pp <- pp + geom_line(aes(group=classifier), width = 0.2, position = position_dodge(.3))
# pp <- pp + facet_wrap( ~subject ) + xlab("number of repetitions") + ylab("accuracy")
# pp <- cleanPlot(pp)
# pp <- pp + theme(legend.position=c(5/8,1/6))
# print(pp)
#                                
# dev.off()
# 
# # ggsave( filename = "P3Accuracy.png"
# #         , plot = pp
# #         , path = outputPath
# #         , width = 30
# #         , height = 20
# #         , units = "cm"
# #         , dpi =  600
# #         )

#################################################################################################################
#                                                                                                               #
#                                         PLOT PER CONDITION DATA                                                 #
#                                                                                                               #
#################################################################################################################
png(filename = file.path(outputPath, "P3AccuracyPerClassifierPerFreq.png")
, width = 900
, height = 600
, units = "px"
)

pp <- ggplot( accData, aes(nRepFac, correctness, colour=classifier) )
pp <- pp + stat_summary(fun.y = mean, geom = "line", aes(group=classifier), width = 0.2)
pp <- pp + facet_wrap(~condition)
pp <- cleanPlot(pp)
print(pp)

# pp2 <- pp + facet_grid(condition~subject)
# print(pp2)

dev.off()
                               

