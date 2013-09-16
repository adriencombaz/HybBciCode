rm(list = ls())
library(ggplot2)
library(reshape2)
library(grid)

source("d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciCode/dataAnalysisCodes/deps/cleanPlot2.R")
source("d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciCode/dataAnalysisCodes/deps/cleanPlot.R")
source("d:/KULeuven/PhD/rLibrary/plotFactorMeans_InteractionGraphs.R")
source("d:/KULeuven/PhD/rLibrary/plotInteractionGraphs_level2.R")

outputPath <- "d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciCode/draftHybridPaper/pix/"

filename <- "psdDataset_Oz_Ha1"
fileDir <- "d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciProcessedData/watch-ERP/04-watchSSVEP-PSD"
fullfilename <- file.path( fileDir, paste0(filename, ".csv") )

psdData <- read.csv(fullfilename, header = TRUE)

psdData$frequency = as.factor(psdData$frequency)
psdData$oddball = as.factor(psdData$oddball)
psdData$fileNb = as.factor(psdData$fileNb)
psdData$trial = as.factor(psdData$trial)
# psdData$psd = sqrt(psdData$psd)
str(psdData)
summary(psdData)


####################################################################################################################

png(filename = file.path(outputPath, "meanPsdPlots.png")
    , width = 900
    , height = 600
    , units = "px"
    #     , res =  600
)

pp <- ggplot( psdData, aes(stimDuration, psd, color=oddball ) )
pp <- pp + stat_summary(fun.data = mean_cl_normal, geom="pointrange", position = position_dodge(0.4))
pp <- pp + xlab("stimulation time (s)") + ylab("power")
# pp <- pp + facet_wrap( frequency~subject, scales="free_y", nrow=4  )
# pp <- pp + facet_grid( frequency~subject, scales="free_y" )
pp <- pp + facet_grid( subject~frequency, scales="free_y" )
pp <- cleanPlot2(pp, 12)
print(pp)
# pp <- pp + theme(strip.text.x = element_text(size = 10) 
#                  , axis.text.y = element_text(face="plain", size = 5, colour = 'black')
# )

dev.off()

# figname = paste0("compareOddball_Q2", ".png")
# ggsave( figname 
#         , plot = pp
#         , width = 30
#         , height = 20
#         , units = "cm"
# )

####################################################################################################################
png(filename = file.path(outputPath, "psdPlotsAllTrials.png")
    , width = 900
    , height = 600
    , units = "px"
    #     , res =  600
)

subData = psdData[ psdData$subject %in% c("S2", "S5") & psdData$frequency=="15", ]
pp <- ggplot( subData, aes(stimDuration, psd) )
pp <- pp + geom_point() + geom_line( aes(stimDuration, psd, group=trial) )
pp <- pp + xlab("stimulation time (s)") + ylab("power")
pp <- pp + facet_grid(  subject~oddball, scales="free_y"  )
pp <- cleanPlot2(pp, 12)
pp <- pp + theme(strip.text.x = element_text(size = 12) )
print(pp)
                                     
dev.off()

####################################################################################################################
# subData = psdData[ psdData$subject=="S2" & psdData$frequency=="15" & psdData$oddball=="0", ]
# 
# pp <- ggplot( subData, aes(stimDuration, psd ) )
# pp <- pp + stat_summary(fun.data = mean_cl_normal, geom="pointrange", size=2)
# pp <- pp + xlab("stimulation time (s)") + ylab("psd") + ggtitle("Average SSVEP response over 12 measures")
# # pp <- pp + facet_grid( subject ~ frequency, scales = "free_y"  )
# pp <- cleanPlot2(pp, 30)
# # pp <- pp + theme( axis.title.x = element_blank(), axis.title.y = element_blank() )
# # pp
# 
# figname = paste0("psdS2_Q", ".png")
# ggsave( figname 
#         , plot = pp
#         , width = 30
#         , height = 20
#         , units = "cm"
# )
# 
# ####################################################################################################################
# subData1 = psdData[ psdData$subject=="S2" & psdData$oddball=="0", ]
# subData2 = psdData[ psdData$subject=="S6" & psdData$oddball=="0", ]
# subData = rbind(subData1, subData2)
# 
# pp <- ggplot( subData, aes(stimDuration, psd, color=frequency ) )
# pp <- pp + stat_summary(fun.data = mean_cl_normal, geom="pointrange", size=1.5, position = position_dodge(0.4))
# # pp <- pp + xlab("stimulation time (s)") + ylab(expression(sqrt("psd")))
# pp <- pp + xlab("stimulation time (s)") + ylab("psd")
# pp <- pp + facet_wrap(  ~ subject  )
# pp <- cleanPlot2(pp, 30)
# pp <- pp + theme(strip.text.x = element_text(size = 30) )
# # pp <- pp + theme( axis.title.x = element_blank(), axis.title.y = element_blank() )
# # pp
# 
# figname = paste0("psdS2_perFreq_Q", ".png")
# ggsave( figname 
#         , plot = pp
#         , width = 60
#         , height = 20
#         , units = "cm"
# )
# 
# ####################################################################################################################
# 
# pp <- ggplot( psdData, aes(stimDuration, psd, color=oddball ) )
# pp <- pp + stat_summary(fun.data = mean_cl_normal, geom="pointrange", position = position_dodge(0.2))
# pp <- pp + xlab("stimulation time (s)") + ylab("psd")
# # pp <- pp + facet_wrap( subject~frequency, scales="free_y", ncol=4  )
# pp <- pp + facet_grid( subject~frequency, scales="free_y" )
# pp <- cleanPlot2(pp, 10)
# pp <- pp + theme(strip.text.x = element_text(size = 10) 
#                  , axis.text.y = element_text(face="plain", size = 5, colour = 'black')
#                  )
# 
# figname = paste0("compareOddball_Q2", ".png")
# ggsave( figname 
#         , plot = pp
#         , width = 30
#         , height = 20
#         , units = "cm"
# )
# 
# ####################################################################################################################
# 
# pp <- ggplot( psdData, aes(stimDuration, psd, color=oddball ) )
# pp <- pp + stat_summary(fun.data = mean_cl_normal, geom="pointrange", position = position_dodge(0.2))
# pp <- pp + xlab("stimulation time (s)") + ylab("psd")
# # pp <- pp + facet_wrap( subject~frequency, scales="free_y", ncol=4  )
# # pp <- pp + facet_grid( subject~frequency, scales="free" )
# pp <- pp + facet_grid( frequency~subject, scales="free" )
# pp <- cleanPlot2(pp, 10)
# pp
# 
# ####################################################################################################################
# psdData$trialInSubAndFreq <- psdData$oddball : psdData$trial
# tempData <- psdData[psdData$subject %in% c("S1", "S2", "S3", "S4"), ]
# pp <- ggplot( tempData, aes(stimDuration, psd, color=oddball ) )
# pp <- pp + geom_point() + geom_line( aes(stimDuration, psd, group=trialInSubAndFreq) )
# pp <- pp + xlab("stimulation time (s)") + ylab("psd")
# pp <- pp + facet_grid( subject~frequency, scales="free_y" )
# # pp <- pp + facet_grid( frequency~subject, scales="free_y" )
# pp <- cleanPlot2(pp, 12)
# # pp <- pp + theme(strip.text.x = element_text(size = 10) 
# #                  , axis.text.y = element_text(face="plain", size = 5, colour = 'black')
# # )
# 
# pp2 <- pp + facet_wrap( frequency~subject, scales="free_y", nrow=4  )
# 
# 
# figname = paste0("compareOddball_Q2ALlTrial1", ".png")
# ggsave( figname 
#         , plot = pp
#         , width = 30
#         , height = 20
#         , units = "cm"
# )
# 
# psdData$trialInSubAndFreq <- psdData$oddball : psdData$trial
# tempData <- psdData[psdData$subject %in% c("S5", "S6", "S7", "S8"), ]
# pp <- ggplot( tempData, aes(stimDuration, psd, color=oddball ) )
# pp <- pp + geom_point() + geom_line( aes(stimDuration, psd, group=trialInSubAndFreq) )
# pp <- pp + xlab("stimulation time (s)") + ylab("psd")
# pp <- pp + facet_grid( subject~frequency, scales="free_y" )
# # pp <- pp + facet_grid( frequency~subject, scales="free_y" )
# pp <- cleanPlot2(pp, 12)
# # pp <- pp + theme(strip.text.x = element_text(size = 10) 
# #                  , axis.text.y = element_text(face="plain", size = 5, colour = 'black')
# # )
# 
# pp2 <- pp + facet_wrap( frequency~subject, scales="free_y", nrow=4  )
# 
# 
# figname = paste0("compareOddball_Q2ALlTrial2", ".png")
# ggsave( figname 
#         , plot = pp
#         , width = 30
#         , height = 20
#         , units = "cm"
# )
# ####################################################################################################################
# 
# pp <- ggplot( psdData, aes(stimDuration, psd, color=frequency ) )
# pp <- pp + stat_summary(fun.data = mean_cl_normal, geom="pointrange", position = position_dodge(0.2))
# pp <- pp + xlab("stimulation time (s)") + ylab("psd")
# # pp <- pp + facet_wrap( subject~frequency, scales="free_y", ncol=4  )
# pp <- pp + facet_grid( subject~oddball, scales="free_y" )
# pp <- cleanPlot2(pp, 10)
# pp <- pp + theme(strip.text.x = element_text(size = 10) 
#                  , axis.text.y = element_text(face="plain", size = 5, colour = 'black')
# )
# 
# figname = paste0("compareFreq_Q2", ".png")
# ggsave( figname 
#         , plot = pp
#         , width = 30
#         , height = 20
#         , units = "cm"
# )
# 
# 
# ####################################################################################################################
# 
# factorList <- c("stimDuration", "frequency", "oddball")
# outcome <- "psd"
# dataframe <- psdData
# source("d:/KULeuven/PhD/rLibrary/plotFactorMeans_InteractionGraphs.R")
# resDir <- "d:/KULeuven/PhD/Correspondance/meeting-Anna-Ivanova/"
# 
# png(filename = file.path(resDir, "interactionGraph.png")
#     , width = 30
#     , height = 20
#     , units = "cm"
#     , res = 300
# )
# plotFactorMeans_InteractionGraphs(dataframe, factorList, outcome)
# dev.off()
# 
# ####################################################################################################################
# 
# source("d:/KULeuven/PhD/rLibrary/plotInteractionGraphs_level2.R")
# dataframe <- psdData
# outcome <- "psd"
# xFactor <- "stimDuration"
# factorList <- c("oddball", "frequency")
# 
# png(filename = file.path(resDir, "interactionGraph_level2.png")
#     , width = 30
#     , height = 20
#     , units = "cm"
#     , res = 300
# )
# plotInteractionGraphs_level2(dataframe, xFactor, outcome, factorList)
# dev.off()
