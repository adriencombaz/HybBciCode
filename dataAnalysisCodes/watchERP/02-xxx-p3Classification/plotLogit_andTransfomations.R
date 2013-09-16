setwd("d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciCode/dataAnalysisCodes/watchERP/02-xxx-p3Classification/")
rm(list = ls())

library(ggplot2)
library(car)       #for logit function

source("createDataFrame.R")
source("d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciCode/dataAnalysisCodes/deps/cleanPlot.R")

# aveClass <- 10
# nRunsForTrain <- 2
# FS <- 256
# nFoldSvm <- 5
aveClass <- 0
nRunsForTrain <- 2
FS <- 128
nFoldSvm <- 10

accData <- createDataFrame(aveClass, nRunsForTrain, FS, nFoldSvm)

str(accData)
summary(accData)

#################################################################################################################
# logit of correctness per subject and grand average
#################################################################################################################
varList <- c("subject", "condition", "nRep", "correctness")
dataToPlot <- accData[ accData$classifier=="normal", (names(accData) %in% varList)]
dataToPlot$nRep = as.factor( dataToPlot$nRep )
varList <- c("subject", "condition", "nRep")
dataToPlot <- ddply( dataToPlot, varList, summarise, logitP = logit(mean(correctness)) )
# dataToPlot <- ddply( dataToPlot, varList, summarise, logitP = log( -log(1-(mean(correctness))) ) )
dataToPlot$nRep = as.numeric( dataToPlot$nRep )
dataToPlot$nRepSq = sqrt(dataToPlot$nRep/10)
dataToPlot$logitPTrans = (dataToPlot$logitP)^10

pp <- ggplot( dataToPlot, aes(nRep, logitP, colour=condition, shape=condition) )
pp <- pp + stat_summary(fun.data = mean_cl_normal, geom = "pointrange", width = 0.2, position = position_dodge(.2))
pp <- cleanPlot(pp)
print(pp)

pp2 <- ggplot( dataToPlot, aes(nRep, logitP, colour=condition, shape=condition) )
pp2 <- pp2 + geom_point( width = 0.2, position = position_dodge(.2) )
pp2 <- pp2 + geom_line( aes(group=condition), position = position_dodge(.2) )
pp2 <- cleanPlot(pp2)
pp2 <- pp2 + facet_wrap( ~subject )
print(pp2)

