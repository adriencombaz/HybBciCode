setwd("d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciCode/dataAnalysisCodes/watchERP_2stim/04-icon-detection/")

rm(list = ls())

library(ggplot2)
source("d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciCode/dataAnalysisCodes/deps/cleanPlot.R")

#################################################################################################################
#################################################################################################################

loadData <- function(file)
{
  fileDir = "d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciProcessedData/watchERP_2stim/04-icon-detection"
  fileext = ".txt"
  filename = file.path( fileDir, paste0(file, fileext) )
  figDir = "d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciResults/watchERP_2stim/04-icon-detection/"  
  figname = paste0(file, ".png")
  
  accData <- read.csv(filename, header = TRUE, sep = ",", strip.white = TRUE)
  str(accData)
  summary(accData)
  
  
  temp <- subset( accData, select = -c(correctness_ssvep, correctness))
  temp$correctnessType <- "p3"
  temp$correctness <- temp$correctness_p3
  temp <- subset( temp, select = -correctness_p3 )
  
  temp2 <- subset( accData, select = -c(correctness_p3, correctness))
  temp2$correctnessType <- "ssvep"
  temp2$correctness <- temp2$correctness_ssvep
  temp2 <- subset( temp2, select = -correctness_ssvep )
  
  temp3 <- subset( accData, select = -c(correctness_ssvep, correctness_p3))
  temp3$correctnessType <- "symbol"
  
  accData <- rbind(temp, temp2, temp3)
  return(accData)
}

#################################################################################################################
#################################################################################################################

file = c("train1_test2345678", "train12_test345678", "train2_test345678", "train23_test45678", "train3_test45678","train34_test5678")

for (iF in 1:length(file))
{
  temp <- loadData(file[iF])
  
  temp$condition <- file[iF]
  if (iF == 1) { accData <- temp }
  else { accData <- rbind(accData, temp) }
  
}

figDir = "d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciResults/watchERP_2stim/04-icon-detection/"  

#################################################################################################################
#################################################################################################################

pp <- ggplot( accData, aes(nRep, correctness, colour=condition ) )
pp <- pp + stat_summary(fun.y = mean, geom="point", position = position_dodge(0.4), shape = 20, size = 3)
pp <- pp + stat_summary(fun.y = mean, geom="line", position = position_dodge(0.4))
pp <- pp + facet_grid( subject ~ correctnessType  )
pp <- pp + ylim(0, 1)
pp <- cleanPlot(pp)

ggsave( "allData.png" 
        , plot = pp
        , path = figDir
        , width = 30
        , height = 20
        , units = "cm"
)

#################################################################################################################
#################################################################################################################


pp <- ggplot( subset(accData, targetFrequency==15), aes(nRep, correctness, colour=condition ) )
pp <- pp + stat_summary(fun.y = mean, geom="point", position = position_dodge(0.4), shape = 20, size = 3)
pp <- pp + stat_summary(fun.y = mean, geom="line", position = position_dodge(0.4))
pp <- pp + facet_grid( subject ~ correctnessType  )
pp <- pp + ylim(0, 1)
pp <- cleanPlot(pp)

ggsave( "allData_15Hz.png" 
        , plot = pp
        , path = figDir
        , width = 30
        , height = 20
        , units = "cm"
)


pp <- ggplot( subset(accData, targetFrequency==12), aes(nRep, correctness, colour=condition ) )
pp <- pp + stat_summary(fun.y = mean, geom="point", position = position_dodge(0.4), shape = 20, size = 3)
pp <- pp + stat_summary(fun.y = mean, geom="line", position = position_dodge(0.4))
pp <- pp + facet_grid( subject ~ correctnessType  )
pp <- pp + ylim(0, 1)
pp <- cleanPlot(pp)

ggsave( "allData_12Hz.png" 
        , plot = pp
        , path = figDir
        , width = 30
        , height = 20
        , units = "cm"
)

#################################################################################################################
#################################################################################################################
accData$targetFrequency <- as.factor(accData$targetFrequency)
pp <- ggplot( subset(accData, correctnessType=="symbol"), aes(nRep, correctness, colour=targetFrequency ) )
pp <- pp + stat_summary(fun.y = mean, geom="point", position = position_dodge(0.4), shape = 20, size = 3)
pp <- pp + stat_summary(fun.y = mean, geom="line", position = position_dodge(0.4))
pp <- pp + facet_grid( subject ~ condition  )
pp <- pp + ylim(0, 1)
pp <- cleanPlot(pp)

ggsave( "allData_symbol.png" 
        , plot = pp
        , path = figDir
        , width = 30
        , height = 20
        , units = "cm"
)

pp <- ggplot( subset(accData, correctnessType=="ssvep"), aes(nRep, correctness, colour=targetFrequency ) )
pp <- pp + stat_summary(fun.y = mean, geom="point", position = position_dodge(0.4), shape = 20, size = 3)
pp <- pp + stat_summary(fun.y = mean, geom="line", position = position_dodge(0.4))
pp <- pp + facet_grid( subject ~ condition  )
pp <- pp + ylim(0, 1)
pp <- cleanPlot(pp)

ggsave( "allData_ssvep.png" 
        , plot = pp
        , path = figDir
        , width = 30
        , height = 20
        , units = "cm"
)

pp <- ggplot( subset(accData, correctnessType=="p3"), aes(nRep, correctness, colour=targetFrequency ) )
pp <- pp + stat_summary(fun.y = mean, geom="point", position = position_dodge(0.4), shape = 20, size = 3)
pp <- pp + stat_summary(fun.y = mean, geom="line", position = position_dodge(0.4))
pp <- pp + facet_grid( subject ~ condition  )
pp <- pp + ylim(0, 1)
pp <- cleanPlot(pp)

ggsave( "allData_p3.png" 
        , plot = pp
        , path = figDir
        , width = 30
        , height = 20
        , units = "cm"
)
