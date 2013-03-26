setwd("d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciCode/dataAnalysisCodes/watchERP/02-ter-p3Classification/")
rm(list = ls())
library(ggplot2)
library(reshape2)
library(ez)

source("d:/KULeuven/PhD/rLibrary/plot_set.R")

for (iS in 1:3)
{
  filename <- sprintf("d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciProcessedData/watch-ERP/02-ter-p3Classification/LinSvm/subject_S%d/Results.txt", iS)
  accData1 <- read.csv(filename, header = TRUE, sep = ",", strip.white = TRUE)
  accData1$nAverages = as.factor(accData1$nAverages)
  accData1 <- subset( accData1, conditionTrain == conditionTest)
  accData1$condition = accData1$conditionTrain;
  accData1 <- subset(accData1, select = -c(conditionTrain, conditionTest))
  accData1 <- subset(accData1, condition != "oddball")
  str(accData1)
  summary(accData1)

  filename <- sprintf("d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciProcessedData/watch-ERP/02-ter-p3Classification/LinSvmPooled/subject_S%d/Results.txt", iS)
  accData2 <- read.csv(filename, header = TRUE, sep = ",", strip.white = TRUE)
  accData2$nAverages = as.factor(accData2$nAverages)
  accData2$condition = accData2$conditionTest;
  accData2 <- subset(accData2, select = -conditionTest)
  accData2 <- subset(accData2, condition != "oddball")
  str(accData2)
  summary(accData2)

  temp1 <- accData1;
  temp2 <- accData2;
  temp1$classifier <- "normal"
  temp2$classifier <- "pooled"
  temp <- rbind(temp1, temp2)
  temp$classifier = as.factor(temp$classifier)
  
  if (iS == 1) { accData <- temp }
  else { accData <- rbind(accData, temp) }
  
}

# graph
fontsize <- 12;
barplot <- ggplot(accData)
barplot <- barplot + geom_point( 
  aes(nAverages, accuracy, shape=condition, colour=classifier)
  , position = position_jitter(w = 0.2, h = 0)
  , size = 3  
  ) 
barplot <- barplot + facet_wrap( ~subject )
barplot <- barplot + theme(
  panel.background =  element_rect(fill='white')
  ,panel.grid.major = element_line(colour = "black", size = 0.5, linetype = "dotted")
#   ,panel.grid.minor = element_line(colour = "black", size = 0.5, linetype = "dotted")
#   , panel.grid.major = element_blank() # switch off major gridlines
  , panel.grid.minor = element_blank() # switch off minor gridlines
  , axis.ticks = element_line(colour = 'black')
  , axis.line = element_line(colour = 'black')
  , panel.border = theme_border(c("left","bottom"), size=0.25)
  , axis.title.y = element_text(face="plain", size = fontsize, angle=90, colour = 'black')
  , axis.title.x = element_text(face="plain", size = fontsize, angle=0, colour = 'black')
  , axis.text.x = element_text(face="plain", size = fontsize, colour = 'black')
  , axis.text.y = element_text(face="plain", size = fontsize, colour = 'black')
  , plot.title = element_text(face="plain", size = fontsize, colour = "black")
  , legend.text = element_text(face="plain", size = fontsize)
  , legend.title = element_text(face="plain", size = fontsize)
  , strip.background = element_blank()
  )
barplot
