setwd("d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciCode/dataAnalysisCodes/watchERP/04-watchSSVEP-PSD/nlmeScripts/")
library(ez)
source("initData.R")

allTimes <- unique(psdData$stimDuration)
nTimes <- length(allTimes)
pVals <- vector(mode="numeric", length=nTimes)

###############################################################################################################
###############################################################################################################

for (iT in 1:nTimes){
  
  subData <- psdData[psdData$stimDuration==allTimes[iT],]
  
#   pp <- ggplot( subData, aes(frequency, psd, colour=oddball))
#   pp <- pp + stat_summary(fun.data = mean_cl_normal, geom = "pointrange", width = 0.2, position = position_dodge(.5))
#   pp <- pp + facet_wrap( ~subject, scale="free_y" ) 
#   pp <- cleanPlot(pp)
#   pp
  
  lm1 <- lme(
    psd ~ frequency*oddball
    , random = ~1|subject/frequency/oddball
    , data = subData
    , method="ML"
    )

  lm2 <- lme(
    psd ~ frequency
    , random = ~1|subject/frequency/oddball
    , data = subData
    , method="ML"
  )
  
  temp <- anova(lm1, lm2)
  pVals[iT] <- temp[2,9]
  

}


