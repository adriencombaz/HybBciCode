setwd("d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciCode/dataAnalysisCodes/watchERP_2stim/02-classify-erps/")
rm(list = ls())

library(ggplot2)
source("createP3CorrectnessDataset.R")
source("d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciCode/dataAnalysisCodes/deps/cleanPlot.R")

# figDir = "d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciResults/watchERP_2stim/02-classify-erps/"

aveClass <- 10
nRunsForTrain <- 2
FS <- 128
nFoldSvm <- 10
source("createP3CorrectnessDataset.R")
createP3CorrectnessDataset(aveClass, nRunsForTrain, FS, nFoldSvm)

figDir  <- "d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciResults/watchERP_2stim/02-classify-erps"
dir.create(figDir, showWarnings=FALSE)
folder      <- sprintf("LinSvm_%dRunsForTrain_%dHz_%.2dcvSvm", nRunsForTrain, FS, nFoldSvm)
if (aveClass != 0){ folder  <- sprintf("%s_%.2dAveClassifier.txt", folder, aveClass) }
figDir  <- file.path(figDir, folder)
dir.create(figDir, showWarnings=FALSE)

#################################################################################################################
#################################################################################################################
#                                   GRAND AVERAGE ACCURACIES
#################################################################################################################
#################################################################################################################

figfilename <- file.path(figDir, "p3accuracy_grandAverage.png")
png( filename = figfilename
     , width=1920, height=1200, units="px"
)

pp <- ggplot( p3Dataset, aes(nRep, correctness, colour=condition ) )
pp <- pp + stat_summary(fun.y = mean, geom="point", position = position_dodge(0.4), shape = 20, size = 3)
pp <- pp + stat_summary(fun.y = mean, geom="line", position = position_dodge(0.4))
pp <- pp + ylim(0, 1)
pp <- cleanPlot(pp)
print(pp)
dev.off()

# ggsave( "p3accuracy_grandAverage.png" 
#         , plot = pp
#         , path = figDir
#         , width = 30
#         , height = 20
#         , units = "cm"
# )

#################################################################################################################
#################################################################################################################
#                                       ACCURACIES PER SUBJECT
#################################################################################################################
#################################################################################################################
figfilename <- file.path(figDir, "p3accuracy.png")
png( filename = figfilename
     , width=1920, height=1200, units="px"
)
pp <- ggplot( p3Dataset, aes(nRep, correctness, colour=condition ) )
pp <- pp + stat_summary(fun.y = mean, geom="point", position = position_dodge(0.4), shape = 20, size = 3)
pp <- pp + stat_summary(fun.y = mean, geom="line", position = position_dodge(0.4))
pp <- pp + facet_wrap( ~subject )
pp <- pp + ylim(0, 1)
pp <- cleanPlot(pp)
print(pp)
dev.off()
# ggsave( "p3accuracy.png" 
#         , plot = pp
#         , path = figDir
#         , width = 30
#         , height = 20
#         , units = "cm"
# )

#################################################################################################################
#################################################################################################################
#                   ACCURACIES PER SUBJECT / TARGET FREQ FOR EACH TRAIN/TEST SET
#################################################################################################################
#################################################################################################################
conds <- levels(p3Dataset$condition)
nConds <- length(conds)
for (iC in 1:nConds){
  
  figfilename <- file.path(figDir, sprintf("p3accuracy_perFreq_%s.png", conds[iC]))
  png( filename = figfilename
       , width=1920, height=1200, units="px"
  )  
  
  subDataset <- p3Dataset[ p3Dataset[ , "condition"] == conds[iC],  ]
  pp <- ggplot( subDataset, aes(nRep, correctness, colour=targetFrequency ) )
  pp <- pp + stat_summary(fun.y = mean, geom="point", position = position_dodge(0.4), shape = 20, size = 3)
  pp <- pp + stat_summary(fun.y = mean, geom="line", position = position_dodge(0.4))
  pp <- pp + facet_wrap( ~subject )
  pp <- pp + ylim(0, 1)
  pp <- cleanPlot(pp)
  print(pp)
  dev.off()  
#   ggsave( sprintf("p3accuracy_perFreq_%s.png", conds[iC])
#           , plot = pp
#           , path = figDir
#           , width = 30
#           , height = 20
#           , units = "cm"
#   )  
  
}

#################################################################################################################
#################################################################################################################
#                                 DETAILS PER RUN / ROUND
#################################################################################################################
#################################################################################################################

cond <- "train12_test345678"
figDirCond <- file.path( figDir, cond )
dir.create(figDirCond, showWarnings=FALSE)

subDataset <- p3Dataset[ p3Dataset[ , "condition"] == cond,  ]
subjects <- levels(subDataset$subject)
nSub <- length(subjects)

for (iS in 1:nSub){ 
  
  figfilename <- file.path(figDirCond, sprintf("detail_corr_perRound_%s.png", subjects[iS] ))
  png( filename = figfilename
       , width=1920, height=1200, units="px"
  )
  
  subDataset_iS <- subDataset[ subDataset[ , "subject"] == subjects[iS],  ]
  pp <- ggplot( subDataset_iS, aes(nRep, correctness, colour=targetFrequency ) )
  pp <- pp + geom_point(size = 3)
  pp <- pp + geom_line()
  pp <- pp +facet_grid( run ~ roundNb )
  pp <- pp + ylim(0, 1)
  pp <- cleanPlot(pp)
  print(pp)
  dev.off()
  
}

#################################################################################################################
#################################################################################################################
#                                 DETAILS PER RUN
#################################################################################################################
#################################################################################################################
cond <- "train12_test345678"
figDirCond <- file.path( figDir, cond )
dir.create(figDirCond, showWarnings=FALSE)

subDataset <- p3Dataset[ p3Dataset[ , "condition"] == cond,  ]
subjects <- levels(subDataset$subject)
nSub <- length(subjects)

figfilename <- file.path(figDirCond, sprintf("detail_corr_perRun.png") )
png( filename = figfilename
     , width=1920, height=1200, units="px"
)

pp <- ggplot( subDataset, aes(nRep, correctness, colour=targetFrequency) )
pp <- pp + stat_summary(fun.y = mean, geom="point", position = position_dodge(0.2), size = 3)
pp <- pp + stat_summary(fun.y = mean, geom="line", position = position_dodge(0.2))
pp <- pp +facet_grid( subject ~ run )
pp <- pp + ylim(0, 1)
pp <- cleanPlot(pp)
print(pp)
dev.off()


