setwd("d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciCode/dataAnalysisCodes/watchERP/05-TargetERP-correlation/")

rm(list = ls())
library(ggplot2)
library(reshape2)
source("d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciCode/dataAnalysisCodes/deps/cleanPlot.R")

#####################################################################################################################
#####################################################################################################################

tableDir <- "d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciCode/draftHybridPaper"
resDir <- "d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciResults/watchERP/05-TargetERP-correlation"
corrFile <- file.path( resDir, "ERPcorrelations.txt")
corrDataset <- read.csv(corrFile, header = TRUE, sep = ",", strip.white = TRUE)

corrDataset <- corrDataset[corrDataset$subject != "S08", ]
corrDataset$subject <- droplevels(corrDataset$subject)
corrDataset$ish1015 <- as.factor(corrDataset$ish10 & corrDataset$ish15)
corrDataset$isodd <- as.factor(corrDataset$isodd)
corrDataset$ish08 <- as.factor(corrDataset$ish08)
corrDataset$ish10 <- as.factor(corrDataset$ish10)
corrDataset$ish12 <- as.factor(corrDataset$ish12)
corrDataset$ish15 <- as.factor(corrDataset$ish15)

corrDataset$pair <- relevel(corrDataset$pair, "corr(h12/h15)")
corrDataset$pair <- relevel(corrDataset$pair, "corr(h10/h15)")
corrDataset$pair <- relevel(corrDataset$pair, "corr(h10/h12)")
corrDataset$pair <- relevel(corrDataset$pair, "corr(h08/h15)")
corrDataset$pair <- relevel(corrDataset$pair, "corr(h08/h12)")
corrDataset$pair <- relevel(corrDataset$pair, "corr(h08/h10)")
corrDataset$pair <- relevel(corrDataset$pair, "corr(odd/h15)")
corrDataset$pair <- relevel(corrDataset$pair, "corr(odd/h12)")
corrDataset$pair <- relevel(corrDataset$pair, "corr(odd/h10)")
corrDataset$pair <- relevel(corrDataset$pair, "corr(odd/h08)")

#####################################################################################################################
#####################################################################################################################

channels <- c("F3", "Fz", "F4", "C3", "Cz", "C4", "P3", "Pz", "P4", "O1", "Oz", "O2")
temp <- corrDataset[corrDataset$channel %in% channels, ]
temp$channel <- droplevels(temp$channel)
temp$channel <- ordered(temp$channel, levels = channels)
pp2 <- ggplot(temp, aes(channel, correlation, colour=isodd))
pp2 <- pp2 + geom_point(size=3) + labs(colour='oddball condition')
pp2 <- pp2 + facet_wrap(~subject)
pp2 <- cleanPlot(pp2)
print(pp2)

#####################################################################################################################
#####################################################################################################################

summary(corrDataset)
library(lme4)
library(LMERConvenienceFunctions)
library(languageR)
library(multcomp)
library(plyr)

lm1 <- lmer( correlation ~ pair + (1|subject/channel), data = corrDataset)
summary(lm1)

mltComp <- glht(lm1, linfct=mcp(pair="Tukey"))
summary(mltComp)
temp <- summary(mltComp)

estimates <- format(temp$test$coefficients, digits=3)
zvals <- format(temp$test$tstat, digits=2)
pvals <- formatC(temp$test$pvalues, format="f", digits=5)
sink(file.path( tableDir, "tukeyTable.tex"))
cat("\\begin{table*}[t]\\scriptsize\n")
cat("\\caption{\n")
cat("Results from the post hoc pairwise comparisons of the linear mixed model built on the correlation data shown in \\autoref{fig:corrERP}.\n")
cat("The first column represents the tested hypothesis; ``odd'' represents the oddball condition while ``h08'', ``h10'', ``h12'' and ``h15'' represent the hybrid condition at \\SIlist[list-units = single]{8.57;10;12;15}{\\Hz}, respectively.\n")
cat("Therefore ``corr(odd,h10)'' represents the correlation between oddball and \\SI{10}{\\Hz}-hybrid ERPs.\n")
cat("The first line of the table tests for significance in the difference between, on the one hand, correlation values between ERPs recorded in the oddball and in the \\SI{10}{\\Hz}-hybrid conditions and, on the other hand, correlation values between ERPs recorded in the oddball and in the \\SI{8.57}{\\Hz}-hybrid conditions.\n")
cat("The second column shows the estimate of the tested difference (reported in the first column), the third and fourth columns represent respectively the test statistic and the associated p-value.\n")
cat("the symbol $^{**}$ denotes statistical significance below 0.01.\n")
cat("}\n")
cat("\\label{table:TukeyTable}\n")
cat("\\centering\n")
cat("\\begin{tabular}{l r r r l}\n")
cat("\\toprule\n")
cat("Null hypothesis & Estimate & z-value & p-value & \\tabularnewline\n")
cat("\\toprule\n")
for (i in 1:length(temp$test$coefficients)){
  cat( gsub("/", ",", row.names(mltComp$linfct)[i]), " == 0" )
  cat(" & $", estimates[i], "$")
  cat(" & $", zvals[i], "$")
  if (as.numeric(pvals[i]) < 0.001){
    cat(" & $< 0.001", "$")
  }else{
    cat(" & $", pvals[i], "$")
  }
  if (as.numeric(pvals[i]) < 0.01){
    cat(" & $^{**}$")
  }else{
    cat(" & ")
  }
  cat("\\tabularnewline\n")
}
cat("\\bottomrule\n")
cat("\\end{tabular}\n")
cat("\\end{table*}\n")
sink()

