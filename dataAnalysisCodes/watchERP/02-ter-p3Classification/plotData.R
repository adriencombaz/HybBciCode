setwd("d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciCode/dataAnalysisCodes/watchERP/02-ter-p3Classification/")
rm(list = ls())

library(ggplot2)
# library(reshape2)
# library(lme4)
# library(LMERConvenienceFunctions)
# library(languageR)
# library(Hmisc)

source("createDataFrame.R")
source("cleanPlot.R")

str(accData)
summary(accData)

outputPath <- "d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciResults/watchERP/02-ter-p3Classification"


#--------------------------------------------------------------------------------------------------------------
# consider only a limited number of repetitions
# temp <- subset(accData, nRep == 1)
# temp2 <- subset(accData, nRep == 5)
# temp3 <- subset(accData, nRep == 10)
# accData <- rbind(temp, temp2, temp3)
# accData$nRep <- droplevels(accData)$nRep
# rm(temp, temp2, temp3)


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
pp <- pp + theme(legend.position=c(0.8334,0.1667))
# pp

# ggsave( filename = "CompareConditions.png"
#         , plot = pp
#         , path = outputPath
#         , width = 30
#         , height = 20
#         , units = "cm"
#         , dpi =  600
#         )


#################################################################################################################
#################################################################################################################

# temp <- subset(accData, classifier=="normal")
# ind <- 1
# for (iS in levels(temp$subject)){
#   for (iC in levels(temp$condition)){
#       for (iR in levels(as.factor(temp$nRep))){
#         subsetTemp <- subset(temp, subject==iS)
#         subsetTemp <- subset(subsetTemp, condition==iC)
#         subsetTemp <- subset(subsetTemp, nRep==iR)
#         dataToPlotTemp <- data.frame(
#           subject = iS
#           , condition = iC
#           , nRep = iR
#           , accuracy = mean(subsetTemp$correctness)
#           )
# 
#         if (ind == 1){
#           dataToPlot <- dataToPlotTemp
#         }
#         else{
#           dataToPlot <- rbind(dataToPlot, dataToPlotTemp)
#         }
#         ind <- ind+1
#       }
#     }
# }
# dataToPlot$accTrans <- exp(dataToPlot$accuracy)
# pp <- ggplot( dataToPlot, aes(nRep, accuracy, colour=condition, shape=condition) )
# # pp <- pp + geom_point(position = position_jitter(w = 0.2, h = 0), size = 3)
# pp <- pp + geom_point(position = position_dodge(.5), size = 3)
# pp <- pp + facet_wrap( ~subject ) 
# pp <- cleanPlot(pp)
# #pp + theme(legend.direction = "horizontal", legend.position = "bottom")
# # pp <- pp + theme(legend.justification=c(1,0), legend.position=c(1,0))
# pp <- pp + theme(legend.position=c(0.8334,0.1667))
# # pp
# 
# ggsave( filename = "CompareConditions2.png"
#         , plot = pp
#         , path = outputPath
#         , width = 30
#         , height = 20
#         , units = "cm"
#         , dpi =  600
# )
# # dev.off()

#################################################################################################################
#################################################################################################################

factorList <- c("nRep", "frequency")
outcome <- "correctness"
dataframe <- dataToPlot
source("d:/KULeuven/PhD/rLibrary/plotFactorMeans_InteractionGraphs.R")

png(filename = file.path(outputPath, "interactionGraph.png")
    , width = 30
    , height = 20
    , units = "cm"
    , res =  600
    )
plotFactorMeans_InteractionGraphs(dataframe, factorList, outcome)
dev.off()

#################################################################################################################
#################################################################################################################

allSub <- levels(dataToPlot$subject)
for (iS in 1:length(allSub)){
  dataToPlotSub <- subset(dataToPlot, subject==allSub[iS])

  png(filename = file.path(outputPath, sprintf("interactionGraph_S%d.png", iS))
      , width = 30
      , height = 20
      , units = "cm"
      , res =  600
  )
  plotFactorMeans_InteractionGraphs(dataToPlotSub, factorList, outcome)
  dev.off()  

}

#################################################################################################################
#################################################################################################################
