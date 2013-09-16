# source("http://egret.psychol.cam.ac.uk/statistics/R/extensions/rnc_ggplot2_border_themes_2013_01.r")
source("d:/KULeuven/PhD/rLibrary/rnc_ggplot2_border_themes_2013_01.r")
cleanPlot2 <- function(pp, fontsize)
{
  pp <- pp + theme(
    panel.background =  element_rect(fill='white')
    ,panel.grid.major = element_line(colour = "black", size = 0.5, linetype = "dotted")
    , panel.grid.minor = element_blank() # switch off minor gridlines
    , axis.ticks = element_line(colour = 'black')
    , axis.line = element_line(colour = 'black')
    , panel.border = theme_border(c("left","bottom"), size=0.25)
    , axis.title.y = element_text(face="bold", size = fontsize, angle=90, colour = 'black')
    , axis.title.x = element_text(face="bold", size = fontsize, angle=0, colour = 'black')
    , axis.text.x = element_text(face="plain", size = fontsize, colour = 'black')
    , axis.text.y = element_text(face="plain", size = fontsize, colour = 'black')
    , plot.title = element_text(face="plain", size = fontsize, colour = "black")
    , legend.text = element_text(face="plain", size = fontsize)
    , legend.title = element_text(face="bold", size = fontsize)
    , strip.background = element_blank()
  )
  
  
  
  
  
}