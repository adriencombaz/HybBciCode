setwd("d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciCode/dataAnalysisCodes/watchERP/04-watchSSVEP-SNR/")
rm(list = ls())
library(ggplot2)
library(reshape2)
library(grid)

source("http://egret.psychol.cam.ac.uk/statistics/R/extensions/rnc_ggplot2_border_themes_2013_01.r")

fontsize <- 12;

snrDataOz <- read.csv("snrDatasetOz.csv", header = TRUE)

snrDataOz$frequency = as.factor(snrDataOz$frequency)
snrDataOz$oddball = as.factor(snrDataOz$oddball)
snrDataOz$fileNb = as.factor(snrDataOz$fileNb)
snrDataOz$trial = as.factor(snrDataOz$trial)
# snrDataOz$stimDuration = as.factor(snrDataOz$stimDuration)
str(snrDataOz)
summary(snrDataOz)


# graphs

# fontsize <- 12;
# barplot <- ggplot(snrDataOz)
# barplot <- barplot + geom_point( 
#   aes(frequency, snr, shape=subject, colour=oddball)
#   , position = position_jitter(w = 0.2, h = 0)
#   , size = 3  
# ) 
# barplot <- barplot + facet_wrap( ~stimDuration, scale="free_y" )
# barplot <- barplot + theme(
#   panel.background =  element_rect(fill='white')
#   ,panel.grid.major = element_line(colour = "black", size = 0.5, linetype = "dotted")
#   #   ,panel.grid.minor = element_line(colour = "black", size = 0.5, linetype = "dotted")
#   #   , panel.grid.major = element_blank() # switch off major gridlines
#   , panel.grid.minor = element_blank() # switch off minor gridlines
#   , axis.ticks = element_line(colour = 'black')
#   , axis.line = element_line(colour = 'black')
#   , panel.border = theme_border(c("left","bottom"), size=0.25)
#   , axis.title.y = element_text(face="plain", size = fontsize, angle=90, colour = 'black')
#   , axis.title.x = element_text(face="plain", size = fontsize, angle=0, colour = 'black')
#   , axis.text.x = element_text(face="plain", size = fontsize, colour = 'black')
#   , axis.text.y = element_text(face="plain", size = fontsize, colour = 'black')
#   , plot.title = element_text(face="plain", size = fontsize, colour = "black")
#   , legend.text = element_text(face="plain", size = fontsize)
#   , legend.title = element_text(face="plain", size = fontsize)
#   , strip.background = element_blank()
# )
# barplot

pp <- ggplot(snrDataOz,aes(stimDuration, snr, shape=oddball, colour=oddball) )
pp <- pp + geom_point( 
 position = position_jitter(w = 0.2, h = 0)
  , size = 3  
) 
pp <- pp + facet_wrap( ~subject + frequency, ncol = 4 )
pp <- pp + geom_smooth(method="lm", aes(fill=oddball), se = F)
pp <- pp + theme(
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
pp



pp2 <- ggplot(snrDataOz,aes(stimDuration, snr, shape=frequency, colour=frequency) )
pp2 <- pp2 + geom_point( 
  position = position_jitter(w = 0.2, h = 0)
  , size = 3  
) 
pp2 <- pp2 + facet_wrap( ~subject + oddball )
pp2 <- pp2 + geom_smooth(method="lm", aes(fill=frequency), se = F)
pp2 <- pp2 + theme(
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
pp2

