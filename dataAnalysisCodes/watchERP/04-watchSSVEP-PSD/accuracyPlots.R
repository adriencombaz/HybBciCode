setwd("d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciCode/dataAnalysisCodes/watchERP/04-watchSSVEP-PSD/")
rm(list = ls())
library(ggplot2)
library(reshape2)
library(grid)

source("d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciCode/dataAnalysisCodes/deps/cleanPlot.R")

# subsetChLabel <- c("ch-O", "ch-PO-O", "ch-P-PO-O", "ch-CP-P-PO-O", "ch-C-CP-P-PO-O", "ch-all")
# harmonicsLabel <- c("fund","fund-ha1")
subsetChLabel <- c("ch-P-PO-O")
harmonicsLabel <- c("fund-ha1")

