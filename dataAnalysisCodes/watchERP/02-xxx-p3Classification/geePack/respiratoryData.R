setwd("d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciCode/dataAnalysisCodes/watchERP/02-xxx-p3Classification/")
rm(list = ls())

library(ggplot2)
library(geepack)

data(respiratory)
str(respiratory)


m.ex <- geeglm(outcome ~ baseline + center + sex + treat + age + I(age^2),
               data = respiratory, id = interaction(center, id),
               family = binomial, corstr = "exchangeable")

m.ex2 <- geeglm(outcome ~ baseline + center + sex + treat + age + I(age^2),
               data = respiratory, id = interaction(center, id),
               family = binomial, corstr = "exchangeable")
