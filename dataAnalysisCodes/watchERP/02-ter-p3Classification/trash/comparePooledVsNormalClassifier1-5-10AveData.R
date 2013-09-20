setwd("d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciCode/dataAnalysisCodes/watchERP/02-ter-p3Classification/")
rm(list = ls())
library(ggplot2)
library(reshape2)
library(ez)
library(gridExtra) # for grid.arrange function
library(plyr)

source("cleanPlot.R")

for (iS in 1:8)
{
  filename <- sprintf("d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciProcessedData/watchERP/02-ter-p3Classification/LinSvm/subject_S%d/Results.txt", iS)
  accData1 <- read.csv(filename, header = TRUE, sep = ",", strip.white = TRUE)
  accData1$nAverages = as.factor(accData1$nAverages)
  accData1 <- subset( accData1, conditionTrain == conditionTest)
  accData1$condition = accData1$conditionTrain;
  accData1 <- subset(accData1, select = -c(conditionTrain, conditionTest))
  accData1 <- subset(accData1, condition != "oddball")
  str(accData1)
  summary(accData1)

  filename <- sprintf("d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciProcessedData/watchERP/02-ter-p3Classification/LinSvmPooled/subject_S%d/Results.txt", iS)
  accData2 <- read.csv(filename, header = TRUE, sep = ",", strip.white = TRUE)
  accData2$nAverages = as.factor(accData2$nAverages)
  accData2$condition = accData2$conditionTest;
  accData2 <- subset(accData2, select = -conditionTest)
  accData2 <- subset(accData2, condition != "oddball")
#   str(accData2)
#   summary(accData2)

  temp1 <- accData1;
  temp2 <- accData2;
  temp1$classifier <- "normal"
  temp2$classifier <- "pooled"
  temp <- rbind(temp1, temp2)
  temp$classifier = as.factor(temp$classifier)
  
  if (iS == 1) { accData <- temp }
  else { accData <- rbind(accData, temp) }
  
}
accData$condition <- droplevels(accData)$condition

accData$condition = relevel(accData$condition, "hybrid-15Hz")
accData$condition = relevel(accData$condition, "hybrid-12Hz")
accData$condition = relevel(accData$condition, "hybrid-10Hz")
accData$condition = relevel(accData$condition, "hybrid-8-57Hz")

# temp <- subset(accData, nAverages == 1)
# temp2 <- subset(accData, nAverages == 5)
# temp3 <- subset(accData, nAverages == 10)
# accData <- rbind(temp, temp2, temp3)
# 
# accData$nAverages <- droplevels(accData)$nAverages

accData$frequency <- accData$condition
accData$frequency <- revalue(accData$frequency
        , c("hybrid-8-57Hz"="8.57"
            , "hybrid-10Hz"="10"
            , "hybrid-12Hz"="12"
            , "hybrid-15Hz"="15"
            )
        )
# accData$frequency <- as.numeric(accData$frequency)


str(accData)
summary(accData)




# source("d:/KULeuven/PhD/rLibrary/plotFactorMeans_InteractionGraphs.R")
# factorList <- c("nAverages", "frequency", "classifier")
# outcome <- "accuracy"
# dataframe <- accData
# plotFactorMeans_InteractionGraphs(dataframe, factorList, outcome)
# 
# 
# 






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



#------------------------------------------------------------------------------------------------------
# SIMPLE RM ANOVA (using anova() from car)
#-----------------------------------------------------------------------------------------------------
condLev = levels(accData$condition)
nAveLev = levels(accData$nAverages)
classLev= levels(accData$classifier)
subLev  = levels(accData$subject)
dataMatrix  = matrix(data=NA, nrow=length(subLev), ncol=length(condLev)*length(nAveLev)*length(classLev))
condition   = matrix(data=NA, nrow=length(condLev)*length(nAveLev)*length(classLev), ncol=1)
nAverages   = matrix(data=NA, nrow=length(condLev)*length(nAveLev)*length(classLev), ncol=1)
classifier  = matrix(data=NA, nrow=length(condLev)*length(nAveLev)*length(classLev), ncol=1)

for (iC in 1:length(condLev)) {
  temp = subset(accData, condition == condLev[iC])
  
  for(iA in 1:length(nAveLev)) {
    temp2 = subset(temp, nAverages==nAveLev[iA])

    for (iCl in 1:length(classLev)) {
      
      temp3 = subset(temp2, classifier==classLev[iCl])
      ii <- (iC-1)*length(nAveLev)*length(classLev)+(iA-1)*length(classLev)+iCl
      dataMatrix[, ii] <- temp3$accuracy
      condition[ii] <- condLev[iC]
      nAverages[ii] <- nAveLev[iA]
      classifier[ii] <- classLev[iCl]
    }
  }
}

iDataMatrix = data.frame( condition=condition, nAverages=nAverages, classifier=classifier )

accModel <- lm(dataMatrix ~ 1)
analysis <- Anova(accModel, idata = iDataMatrix, idesign = ~classifier*condition*nAverages, multivariate=FALSE)
summary(analysis)

#------------------------------------------------------------------------------------------------------
# SIMPLE RM ANOVA (using ezANOVA)
#------------------------------------------------------------------------------------------------------
anovaModelType2 <- ezANOVA( data=accData
                            , dv=.(accuracy)
                            , wid=.(subject)
                            , within=.(condition, nAverages, classifier)
                            , type=2
                            , detailed=TRUE 
)

anovaModelType3 <- ezANOVA( data=accData
                            , dv=.(accuracy)
                            , wid=.(subject)
                            , within=.(condition, nAverages, classifier)
                            , type=3
                            , detailed=TRUE 
                            , return_aov=TRUE
)

pairwise.t.test( accData$accuracy
                 , accData$condition
                 , paired=TRUE
                 , p.adjust.method="bonferroni"
)

pairwise.t.test( accData$accuracy
                 , accData$nAverages
                 , paired=TRUE
                 , p.adjust.method="bonferroni"
)

pairwise.t.test( accData$accuracy
                 , accData$classifier
                 , paired=TRUE
                 , p.adjust.method="bonferroni"
)





factorList <- c("nAverages", "condition", "classifier")
outcome <- "accuracy"
# originalLevels <- c( levels(as.factor(accData$nAverages)), levels(as.factor(accData$condition)), levels(as.factor(accData$classifier)) )
originalLevels <- levels( as.factor( accData[[factorList[1]]] ) )
for (ii in 2:length(factorList)){
  originalLevels <- c( originalLevels, levels( as.factor( accData[[factorList[ii]]] ) ) ) 
}

datasetPlot <- melt( subset(accData, select = c(factorList, outcome) ), id=outcome )
datasetPlot$value <- as.factor(datasetPlot$value)
datasetPlot$value <- factor(datasetPlot$value, levels = originalLevels)

factorBar <- ggplot(datasetPlot, aes(value, accuracy))
factorBar <- factorBar + stat_summary(fun.y = mean, geom = "bar", fill = "White", colour = "Black") 
factorBar <- factorBar + stat_summary(fun.data = mean_cl_boot, geom = "pointrange") 
factorBar <- factorBar + facet_wrap(~variable, scales="free_x")
factorBar

# pdf("test.pdf", width = 16, height = 10)
fontsize = 9
grid.newpage()
pushViewport(viewport(layout = grid.layout(3, 3)))

factorList <- levels( datasetPlot$variable )
for (ii in 1:length(factorList)) {
  
  xFactor <- factorList[ii]
  colFactor <- factorList[-ii]
  for (jj in 1:length(colFactor)) {
    
    intPlot <- ggplot( accData, aes_string( x = xFactor, y = "accuracy", colour = colFactor[jj] ) )
    intPlot <- intPlot + stat_summary( fun.y = mean, geom = "point" )
    intPlot <- intPlot + stat_summary(fun.y = mean, geom = "line", aes_string(group= colFactor[jj]) )
    intPlot <- intPlot + stat_summary(fun.data = mean_cl_boot, geom = "errorbar", width = 0.2 )
    intPlot <- intPlot + labs(x = xFactor, y = "accuracy", colour = colFactor[jj]) + theme(axis.text.x=element_text(angle=90, hjust=0))
    intPlot <- intPlot + theme(
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
    print(intPlot, vp = viewport(layout.pos.row = which( factorList == colFactor[jj] ), layout.pos.col = ii) )
  }  
}



interactionBar <- ggplot(accData, aes(nAverages, accuracy, colour = condition))
interactionBar <- interactionBar + stat_summary( fun.y = mean, geom = "point", position = position_dodge(.5) )
interactionBar <- interactionBar + stat_summary(fun.y = mean, geom = "line", aes(group= condition), position = position_dodge(.5) )
interactionBar <- interactionBar + stat_summary(fun.data = mean_cl_boot, geom = "errorbar", width = 0.2, position = position_dodge(.5) )
interactionBar <- interactionBar + labs(x = "nAverages", y = "correctness", colour = "condition") 
interactionBar



nAveragesBar <- ggplot(accData, aes(nAverages, accuracy))
nAveragesBar <- nAveragesBar + stat_summary(fun.y = mean, geom = "bar", fill = "White", colour = "Black") 
nAveragesBar <- nAveragesBar + stat_summary(fun.data = mean_cl_boot, geom = "pointrange") 
nAveragesBar <- nAveragesBar + labs(x = "nAverages", y = "accuracy") 
nAveragesBar

conditionBar <- ggplot(accData, aes(condition, accuracy))
conditionBar <- conditionBar + stat_summary(fun.y = mean, geom = "bar", fill = "White", colour = "Black") 
conditionBar <- conditionBar + stat_summary(fun.data = mean_cl_boot, geom = "pointrange") 
conditionBar <- conditionBar + labs(x = "nAverages", y = "accuracy") 
conditionBar

classifierBar <- ggplot(accData, aes(classifier, accuracy))
classifierBar <- classifierBar + stat_summary(fun.y = mean, geom = "bar", fill = "White", colour = "Black") 
classifierBar <- classifierBar + stat_summary(fun.data = mean_cl_boot, geom = "pointrange") 
classifierBar <- classifierBar + labs(x = "classifier", y = "accuracy") 
classifierBar

interactionBar <- ggplot(accData, aes(classifier, accuracy, colour = nAverages))
interactionBar <- interactionBar + stat_summary(fun.y = mean, geom = "point")
interactionBar <- interactionBar + stat_summary(fun.y = mean, geom = "line", aes(group= nAverages))
interactionBar <- interactionBar + stat_summary(fun.data = mean_cl_boot, geom = "errorbar", width = 0.2)
interactionBar <- interactionBar + labs(x = "classifier", y = "accuracy", colour = "nAverages") 
interactionBar

interactionBar2 <- ggplot(accData, aes(nAverages, accuracy, colour = classifier))
interactionBar2 <- interactionBar2 + stat_summary(fun.y = mean, geom = "point")
interactionBar2 <- interactionBar2 + stat_summary(fun.y = mean, geom = "line", aes(group= classifier))
interactionBar2 <- interactionBar2 + stat_summary(fun.data = mean_cl_boot, geom = "errorbar", width = 0.2)
interactionBar2 <- interactionBar2 + labs(x = "nAverages", y = "accuracy", colour = "classifier") 
interactionBar2

interactionBar2 <- ggplot(accData, aes(condition, accuracy, colour = classifier))
interactionBar2 <- interactionBar2 + stat_summary(fun.y = mean, geom = "point")
interactionBar2 <- interactionBar2 + stat_summary(fun.y = mean, geom = "line", aes(group= classifier))
interactionBar2 <- interactionBar2 + stat_summary(fun.data = mean_cl_boot, geom = "errorbar", width = 0.2)
interactionBar2 <- interactionBar2 + labs(x = "condition", y = "accuracy", colour = "classifier") 
interactionBar2


#------------------------------------------------------------------------------------------------------
# SLIGHTLY MORE COMPLICATED WAY (cf, chapter 13.7.5 Andy Field's book)
#------------------------------------------------------------------------------------------------------
baseline = lme( accuracy ~ 1
                , random = ~1|subject/classifier/condition/nAverages
                , data = accData
                , method = "ML"
)

classModel2 = update(baseline, .~. + classifier)
nAveModel2 = update(classModel2, .~. + nAverages)
condModel2 = update(nAveModel2, .~. + condition)
intClassNaveModel2  = update(condModel2, .~. + classifier:nAverages)
intClassCondModel2  = update(condModel2, .~. + classifier:condition)
finalModel2         = update(condModel2, .~. + condition:nAverages)

# summary(baseline)
summary(nAveModel2)
# summary(condModel2)
# summary(accModel2)

anova(baseline, classModel2, nAveModel2, condModel2, intClassNaveModel2, intClassCondModel2, finalModel2)

