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

aveClass <- 0
nRunsForTrain <- 2
FS <- 128
nFoldSvm <- 10


accData <- createDataFrame(aveClass, nRunsForTrain, FS, nFoldSvm)

accData <- accData[accData$subject != "S08",]
accData$subject <- revalue(accData$subject, c("S09"="S08", "S10"="S09"))
accData$subject <- droplevels(accData$subject)
levels(accData$subject)
str(accData)
summary(accData)
accData <- accData[accData$classifier == "normal", ]

#################################################################################################################
#                                                                                                               #
#                                         PLOT PER SUBJECT DATA                                                 #
#                                                                                                               #
#################################################################################################################
varList <- c("subject", "condition", "nRepFac")
accData2 <- ddply( accData, varList, summarize 
                   , meanCorr = mean(correctness)
                   , nRep = unique(nRep)
                   , frequency = unique(frequency)
                   )

varList <- c("condition", "nRepFac")
temp <- ddply( accData, varList, summarize 
               , meanCorr = mean(correctness)
               , nRep = unique(nRep)
               , frequency = unique(frequency)
               )

temp$subject <- "grand mean"
accData2 <- rbind(accData2, temp)

str(accData2)
summary(accData2)

outputPath <- "d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciCode/draftHybridPaper/pix/"

#################################################################################################################
#################################################################################################################

png(filename = file.path(outputPath, "P3Accuracy.png")
    , width = 900
    , height = 600
    , units = "px"
)

pp <- ggplot( accData2, aes(nRepFac, meanCorr, colour=condition) )
pp <- pp + geom_point(width = 0.2, position = position_dodge(.3))
pp <- pp + geom_line(aes(group=condition), width = 0.2, position = position_dodge(.3))
pp <- pp + facet_wrap( ~subject ) + xlab("number of repetitions") + ylab("accuracy")
pp <- cleanPlot(pp)
pp <- pp + theme(legend.position=c(5/8,1/6))
print(pp)

dev.off()

# ggsave( filename = "P3Accuracy.png"
#         , plot = pp
#         , path = outputPath
#         , width = 30
#         , height = 20
#         , units = "cm"
#         , dpi =  600
#         )


