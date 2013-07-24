setwd("d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciCode/dataAnalysisCodes/watchERP/02-xxx-p3Classification/")
rm(list = ls())

library(ggplot2)
# library(plyr)
library(car)
# library(reshape2)
# library(lme4)
# library(LMERConvenienceFunctions)
# library(languageR)
# library(Hmisc)

source("createDataFrame.R")
source("d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciCode/dataAnalysisCodes/deps/cleanPlot.R")
source("d:/KULeuven/PhD/rLibrary/plotFactorMeans_InteractionGraphs.R")

aveClass <- 10
nRunsForTrain <- 2
FS <- 256
nFoldSvm <- 5

accData <- createDataFrame(aveClass, nRunsForTrain, FS, nFoldSvm)

str(accData)
summary(accData)

outputPath  <- "d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciResults/watchERP/02-xxx-p3Classification"
dir.create(outputPath, showWarnings=FALSE)
folder      <- sprintf("LinSvm_%dRunsForTrain_%dHz_%.2dcvSvm", nRunsForTrain, FS, nFoldSvm)
if (aveClass != 0){ folder  <- sprintf("%s_%.2dAveClassifier.txt", folder, aveClass) }
outputPath  <- file.path(outputPath, folder)
dir.create(outputPath, showWarnings=FALSE)

#################################################################################################################
#                                                                                                               #
#                                         PLOT PER SUBJECT DATA                                                 #
#                                                                                                               #
#################################################################################################################

#################################################################################################################
#################################################################################################################

dataToPlot <- subset(accData, classifier=="normal")
pp <- ggplot( dataToPlot, aes(nRep, correctness, colour=condition, shape=condition) )
# pp <- pp + stat_summary(fun.y = mean, geom="point",  position = position_jitter(w = 0.2, h = 0), size = 3)
# pp <- pp + stat_summary(fun.y = mean, geom="point", position = position_dodge(.5))
pp <- pp + stat_summary(fun.data = mean_cl_normal, geom = "pointrange", width = 0.2, position = position_dodge(.5))
pp <- pp + facet_wrap( ~subject )
# pp <- pp + geom_smooth( method="lm" , se=F)
pp <- cleanPlot(pp)
#pp + theme(legend.direction = "horizontal", legend.position = "bottom")
# pp <- pp + theme(legend.justification=c(1,0), legend.position=c(1,0))
# pp <- pp + theme(legend.position=c(0.8334,0.1667))
# print(pp)
# pp

ggsave( filename = "CompareConditions.png"
        , plot = pp
        , path = outputPath
        , width = 30
        , height = 20
        , units = "cm"
        , dpi =  600
        )


#################################################################################################################
# INTERACTION GRAPH FOR ALL SUBJECTS
#################################################################################################################
dataToPlot <- subset(accData, classifier=="normal")
factorList <- c("nRep", "frequency")
outcome <- "correctness"
dataframe <- dataToPlot
# source("d:/KULeuven/PhD/rLibrary/plotFactorMeans_InteractionGraphs.R")

png(filename = file.path(outputPath, "interactionGraph.png")
    , width = 30
    , height = 20
    , units = "cm"
    , res =  600
    )
plotFactorMeans_InteractionGraphs(dataframe, factorList, outcome)
dev.off()

#################################################################################################################
# INTERACTION GRAPH PER SUBJECT
#################################################################################################################
# 
# allSub <- levels(dataToPlot$subject)
# for (iS in 1:length(allSub)){
#   dataToPlotSub <- subset(dataToPlot, subject==allSub[iS])
# 
#   png(filename = file.path(outputPath, sprintf("interactionGraph_S%d.png", iS))
#       , width = 30
#       , height = 20
#       , units = "cm"
#       , res =  600
#   )
#   plotFactorMeans_InteractionGraphs(dataToPlotSub, factorList, outcome)
#   dev.off()  
# 
# }

#################################################################################################################
#################################################################################################################
