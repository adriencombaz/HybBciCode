setwd("d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciCode/dataAnalysisCodes/watchERP/05-TargetERP-correlation/")

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
corrDataset$subject <- droplevels(corrDataset$subject)
corrDataset$ish1015 <- as.factor(corrDataset$ish10 & corrDataset$ish15)
corrDataset$isodd <- as.factor(corrDataset$isodd)
corrDataset$ish08 <- as.factor(corrDataset$ish08)
corrDataset$ish10 <- as.factor(corrDataset$ish10)
corrDataset$ish12 <- as.factor(corrDataset$ish12)
corrDataset$ish15 <- as.factor(corrDataset$ish15)

pp <- ggplot(corrDataset, aes(channel, correlation, colour=isodd))
pp <- pp + geom_point()
pp <- pp + facet_wrap(~subject)
pp <- cleanPlot(pp)
print(pp)

channels <- c("F3", "Fz", "F4", "C3", "Cz", "C4", "P3", "Pz", "P4", "O1", "Oz", "O2")
temp <- corrDataset[corrDataset$channel %in% channels, ]
temp$channel <- droplevels(temp$channel)
temp$channel <- ordered(temp$channel, levels = channels)
pp2 <- ggplot(temp, aes(channel, correlation, colour=isodd))
pp2 <- pp2 + geom_point(size=3) + labs(colour='oddball condition')
pp2 <- pp2 + facet_wrap(~subject)
pp2 <- cleanPlot(pp2)
print(pp2)

channels <- c("F3", "Fz", "F4", "C3", "Cz", "C4", "P3", "Pz", "P4", "O1", "Oz", "O2")
temp <- corrDataset[corrDataset$channel %in% channels, ]
temp$channel <- droplevels(temp$channel)
temp$channel <- ordered(temp$channel, levels = channels)
pp2 <- ggplot(temp, aes(channel, correlation, colour=ish1015))
pp2 <- pp2 + geom_point(size=3) + labs(colour='oddball condition')
pp2 <- pp2 + facet_wrap(~subject)
pp2 <- cleanPlot(pp2)
print(pp2)


channels <- c("F3", "Fz", "F4", "C3", "Cz", "C4", "P3", "Pz", "P4", "O1", "Oz", "O2")
temp <- corrDataset[corrDataset$channel %in% channels, ]
pp2bis <- ggplot(temp, aes(channel, correlation, shape=isodd, colour=pair))
pp2bis <- pp2bis + geom_point()
pp2bis <- pp2bis + facet_wrap(~subject, scales="free")
pp2bis <- cleanPlot(pp2bis)
print(pp2bis)


# channels <- c("Fz", "Cz", "Pz", "Oz")
# temp <- corrDataset[corrDataset$channel %in% channels, ]
# pp2 <- ggplot(temp, aes(channel, correlation, colour=isodd))
# pp2 <- pp2 + geom_point()
# pp2 <- pp2 + facet_wrap(~subject)
# pp2 <- cleanPlot(pp2)
# print(pp2)

#####################################################################################################################
#####################################################################################################################

temp <- melt( corrDataset
              , id.vars=c("subject", "pair", "channel", "correlation")
                    , measure.vars=c("isodd", "ish08", "ish10", "ish12", "ish15")
                    , variable.name="condition"
                    , value.name="present")

channels <- c("F3", "Fz", "F4", "C3", "Cz", "C4", "P3", "Pz", "P4", "O1", "Oz", "O2")
temp <- temp[temp$channel %in% channels, ]
pp3 <- ggplot(temp, aes(channel, correlation, colour=present))
pp3 <- pp3 + geom_point()
pp3 <- pp3 + facet_grid(condition~subject)
pp3 <- cleanPlot(pp3)
print(pp3)

#####################################################################################################################
#####################################################################################################################
tempOdd <- corrDataset[corrDataset$isodd=="1", ]
tempOdd$cond <- "odd"
tempH08 <- corrDataset[corrDataset$ish08=="1", ]
tempH08$cond <- "H08"
tempH10 <- corrDataset[corrDataset$ish10=="1", ]
tempH10$cond <- "H10"
tempH12 <- corrDataset[corrDataset$ish12=="1", ]
tempH12$cond <- "H12"
tempH15 <- corrDataset[corrDataset$ish15=="1", ]
tempH15$cond <- "H15"
temp2 <- rbind(tempOdd, tempH08, tempH10, tempH12, tempH15)

channels <- c("F3", "Fz", "F4", "C3", "Cz", "C4", "P3", "Pz", "P4", "O1", "Oz", "O2")
temp2 <- temp2[temp2$channel %in% channels, ]

pp4 <- ggplot(temp2, aes(channel, correlation, colour=cond))
pp4 <- pp4 + stat_summary(fun.data = mean_cl_normal, geom="pointrange", position = position_dodge(0.4))
pp4 <- pp4 + facet_wrap(~subject)
pp4 <- cleanPlot(pp4)
print(pp4)

#####################################################################################################################
#####################################################################################################################
summary(corrDataset)
library(lme4)
library(LMERConvenienceFunctions)
library(languageR)

lm0 <- lmer( correlation ~ 1 + (1|subject/channel), data = corrDataset)
lm1 <- lmer( correlation ~ pair + (1|subject/channel), data = corrDataset)
lm1b <- lmer( correlation ~ pair + (1|subject) + (1|channel), data = corrDataset)
lm2 <- lmer( correlation ~ pair + (1|subject) + (1|subject:channel), data = corrDataset)
lm3 <- lmer( correlation ~ pair + (1|subject), data = corrDataset)
lm4 <- lmer( correlation ~ pair + (1|subject:channel), data = corrDataset)

summary(lm1)
anova(lm0, lm1)
anova(lm1, lm2, lm3)
anova(lm1, lm2, lm4)

lm1 <- lmer( correlation ~ isodd + ish08 + ish10 + ish12 + ish15 + (1|subject/channel), data = corrDataset)
lm1 <- lmer( correlation ~ 1 + (1|subject/channel), data = corrDataset)
lm2 <- lmer( correlation ~ 1 + (1|subject) + (1|subject:channel), data = corrDataset)
lm1 <- lmer( correlation ~ isodd + (1|subject/channel), data = corrDataset)
lm2 <- lmer( correlation ~ ish10 + (1|subject/channel), data = corrDataset)


fm <- lm1

dotplot(ranef(fm, postVar=TRUE))
qqmath(ranef(fm, postVar=TRUE))      
re1 <- ranef(fm, postVar=TRUE)
re2 <- ranef(fm, postVar=FALSE)
dotplot(re1[1])
qqmath(re1[1])      
dotplot(re1[2])
qqmath(re1[2])      
dotplot(re2[1])
qqmath(re2[1])      
dotplot(re2[2])
qqmath(re2[2])      

plot( fitted(fm), residuals(fm) )
abline(h=0)

mcp.fnc(fm, trim = 2.5, col = "red")
pacf( resid( fm ) )

# mcmc <- pvals.fnc( fm, nsim=50000, withMCMC=TRUE )
mcmc <- pvals.fnc( fm, nsim=50000, withMCMC=TRUE, ndigits=6 )
mcmc$fixed
mcmc$random

library(xtable)
test <- xtable(mcmc$fixed[,1:5])
print(test, include.rownames=FALSE)
print(test)

#####################################################################################################################
#####################################################################################################################
detach("package:LMERConvenienceFunctions", unload=TRUE)
detach("package:lme4", unload=TRUE)
library(nlme)

lm1 <- lme(
  correlation ~ 1
  , data = corrDataset
  , random =  ~1|subject/channel
  , control = list(opt="optim")
  , method = "ML"
)
lm2 <- lme(
  correlation ~ isodd
  , data = corrDataset
  , random =  ~1|subject/channel
  , control = list(opt="optim")
  , method = "ML"
)
anova(lm2)
anova(lm1, lm2)

lm3 <- lme(
  correlation ~ ish10
  , data = corrDataset
  , random =  ~1|subject/channel
  , control = list(opt="optim")
  , method = "ML"
)
anova(lm1, lm3)

plot(ranef(lm1), level=2)
plot(ranef(lm1), level=1)
plot( lm1, resid(., type = "normalized") ~ fitted(.), abline = 0 )
plot( lm1, resid(., type = "normalized") ~ as.numeric(channel), abline = 0 )

plot(ranef(lm2), level=2)
plot(ranef(lm2), level=1)
plot( lm2, resid(., type = "normalized") ~ fitted(.), abline = 0 )
plot( lm2, resid(., type = "normalized") ~ as.numeric(channel), abline = 0 )

detach("package:nlme", unload=TRUE)