setwd("d:/KULeuven/PhD/Work/Hybrid-BCI/HybBciCode/dataAnalysisCodes/watchERP/02-xxx-p3Classification/")
rm(list = ls())

library(ggplot2)
library(bild)
library(car)
library(plyr)

summary(locust)
str(locust)

dataToPlot <- ddply( locust, c("feed", "time"), summarise, logitP = logit(mean(move)) )
dataToPlot <- dataToPlot[with(dataToPlot, order(feed, time)), ]


pp <- ggplot( dataToPlot, aes(time, logitP, colour=feed) )
pp <- pp + geom_line(aes(group=feed))
print(pp)


locust2 <- bild(
  move ~ (time + I(time^2)) * feed
  , data = locust
  , start = NULL
  , aggregate = feed
  , dependence = "MC2"
  )
summary(locust2)

plot(locust2, which = 5, ylab = "probability of locomotion")
plot(locust2, which = 1)
plot(locust2, which = 2)
plot(locust2, which = 3)
plot(locust2, which = 4)




locust2r <- bild(
  move ~ (time + I(time^2)) * feed
  , data = locust
  , start = NULL
  , aggregate = feed
  , dependence = "MC2R"
)

# Integ <- bildIntegrate(li = -2.5, ls = 2.5, lig = -2.5, lsg = 2.5)
# locust2r <- bild(
#   move ~ (time + I(time^2)) * feed
#   , data = locust
#   , start = NULL
#   , aggregate = feed
#   , dependence = "MC2R"
#   , integrate = Integ
# )
summary(locust2r)

plot(locust2r, which = 5, ylab = "probability of locomotion", add.unadjusted = TRUE)
plot(locust2r, which = 1)
plot(locust2r, which = 2)
plot(locust2r, which = 3)
plot(locust2r, which = 4)


plot(
  locust2r
  , which = 6
  , ident = TRUE
  , subSET = feed == "0"
  , ylab = "probability of locomotion"
  , main = "Unfeed group"
  )
plot(
  locust2r
  , which = 6
  , subSET = (sex == "0")
  , main = "sex==0"
  , ident = TRUE
  )
plot(
  locust2r
  , which = 6
  , subSET = (feed == "0" & sex == "0")
  , main = "Unfeed & Female"
  , ident = TRUE
  )

plot( locust2r, which = 6, ident = TRUE )


locust$fitted <- locust2r@Fitted
locust$res <- locust2r@residuals
locust$fitPlusRes <- locust$fitted + locust$res
