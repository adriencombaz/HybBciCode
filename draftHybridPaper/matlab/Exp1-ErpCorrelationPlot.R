rm(list = ls())
library(ggplot2)
library(reshape2)
source("d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciCode/dataAnalysisCodes/deps/cleanPlot.R")

#####################################################################################################################
#####################################################################################################################

resDir <- "d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciResults/watchERP/05-TargetERP-correlation/"
corrFile <- file.path( resDir, "ERPcorrelations.txt")
corrDataset <- read.csv(corrFile, header = TRUE, sep = ",", strip.white = TRUE)

corrDataset <- corrDataset[corrDataset$subject != "S08", ]
corrDataset$subject <- revalue(corrDataset$subject, c("S09"="S08", "S10"="S09"))
corrDataset$subject <- droplevels(corrDataset$subject)
corrDataset$isodd <- as.factor(corrDataset$isodd)

channels <- c("F3", "Fz", "F4", "C3", "Cz", "C4", "P3", "Pz", "P4", "O1", "Oz", "O2")
temp <- corrDataset[corrDataset$channel %in% channels, ]
temp$channel <- droplevels(temp$channel)
temp$channel <- ordered(temp$channel, levels = channels)

outputPath <- "d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciCode/draftHybridPaper/pix/"

#####################################################################################################################
#####################################################################################################################

png(filename = file.path(outputPath, "correlationPoints.png")
    , width = 900
    , height = 600
    , units = "px"
#     , res =  600
)

pp2 <- ggplot(temp, aes(channel, correlation, colour=isodd))
pp2 <- pp2 + geom_point(size=3) + labs(colour='oddball condition')
pp2 <- pp2 + facet_wrap(~subject)
pp2 <- cleanPlot(pp2)
print(pp2)

dev.off()

#####################################################################################################################

# pp2 <- ggplot(temp, aes(channel, correlation, colour=isodd))
# pp2 <- pp2 + geom_point(size=3) + labs(colour='oddball condition')
# pp2 <- pp2 + facet_wrap(~subject)
# pp2 <- cleanPlot(pp2)
# # print(pp2)
# ggsave( paste0("correlationPoints2", ".png") 
#         , plot = pp2
#         , path = outputPath
#         , width = 30
#         , height = 20
#         , units = "cm"
#         )
# dev.off()
# 
# #####################################################################################################################
# 
# png(filename = file.path(outputPath, "correlationPoints3.png")
#     , width = 30
#     , height = 20
#     , units = "cm"
#     , res =  600
# )
# 
# pp2 <- ggplot(temp, aes(channel, correlation, colour=isodd))
# pp2 <- pp2 + geom_point(size=3) + labs(colour='oddball condition')
# pp2 <- pp2 + facet_wrap(~subject)
# pp2 <- cleanPlot(pp2)
# print(pp2)
# 
# dev.off()
