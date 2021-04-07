library(zoo)
library(fBasics)
library(tseries)
library(fUnitRoots)
library(fpp2)
library(lmtest)
library(ggfortify)
library(ggplot2)
install.packages("dynlm")
library(dynlm)
library(TSA)
source('Backtest.R')
source('eacf.R')

#Basic Explore
MinnTS <- Copy_of_Project_Data_Minn$Price
MinnTS <- ts(MinnTS, start = c(1996,1), frequency = 12)
plot(MinnTS, main = "Minneapolis Housing Prices 2B2B", ylab = "Price in Dollars")
jarque.bera.test(MinnTS)
skewness(MinnTS)
kurtosis(MinnTS)
TMinnTS <- diff(diff(log(MinnTS))) #White Noise
summary(MinnTS)
jarque.bera.test(TMinnTS)
Box.test(MinnTS, type = c('Ljung-Box'))
Box.test(TMinnTS, type = c('Ljung-Box'))

#TS Explore
Acf(MinnTS)
Pacf(MinnTS)
eacf(MinnTS)
#W/ white Noise
Acf(TMinnTS)
Pacf(TMinnTS)
eacf(TMinnTS)

#Looking at a the following distinct possibilities 
#(1,2,3)w/S(2,0,0)
#(3,2,3)w/s(2,0,0)
#(3,2,0)w/S(2,0,0)
#Auto.arima - Matches model 1 w/ BIC and AIC

#Stationarity
adfTest(MinnTS, type = c("nc"))
adfTest(MinnTS, type = c("c"))
adfTest(MinnTS, type = c("ct"))
kpss.test(MinnTS)
kpss.test(MinnTS, null = c("Trend"))

#On Transformed 
adfTest(TMinnTS, type = c("nc"))
adfTest(TMinnTS, type = c("c"))
adfTest(TMinnTS, type = c("ct"))
kpss.test(TMinnTS)
kpss.test(TMinnTS, null = c("Trend"))

#Result is non-stationary after transformed Stationary
model1 = Arima(MinnTS, order = c(1,2,3), seasonal = c(2,0,0))#Best
model2 = Arima(MinnTS, order = c(2,2,3), seasonal = c(2,0,0))
model3 = Arima(MinnTS, order = c(0,2,3), seasonal = c(2,0,0))
model4 = auto.arima(MinnTS)
model4



nTest = 0.80 * length(MinnTS)
backtest(model1, MinnTS, orig = nTest, h=1)
backtest(model2, MinnTS, orig = nTest, h=1)
backtest(model3, MinnTS, orig = nTest, h=1)
backtest(model4, MinnTS, orig = nTest, h=1)

coeftest(model1)
coeftest(model2)
coeftest(model3)
coeftest(model4)

Acf(model1$residuals)
Acf(model2$residuals)
Acf(model3$residuals)
Acf(model4$residuals)

Model5 = arima(log(MinnTS), order = c(3,2,0), fixed = c(0,NA,NA,NA,NA,NA), seasonal = c(2,0,0))
#Final model needs adjusting 
plot(forecast(model1, h = 36), xlim= c(250, 350), main = "Minneapolis Forecast")

#Correlational model
#Vegas vs Minneapolis
library(astsa)
VegaTS <- Vegas
VegaTS <- ts(VegaTS, start = c(1996, 1), frequency = 12)
ts.plot(VegaTS, MinnTS, gpars = list(col = c("gold", "purple")), main = "Minneapolis (purple) vs Vegas (gold)")

TVegaTS <- diff(diff(log(VegaTS)))
ts.plot(TVegaTS, TMinnTS, gpars = list(col = c("gold", "purple")), main = "Minneapolis (purple) vs Vegas (gold)")

cor(MinnTS, VegaTS)
cor(TMinnTS, TVegaTS)

ccf(MinnTS, VegaTS)
lag2.plot(MinnTS, VegaTS, 20)
ccf(TMinnTS, TVegaTS)#ignore
lag2.plot(TMinnTS, TVegaTS, 20)#Ignore

fit1 = dynlm(MinnTS ~ VegaTS)  
summary(fit1)
fit2 = dynlm(TMinnTS ~ lag(TVegaTS, 0))   
summary(fit2)
#Author choice cutting the differential model as it doesn't hold up
#Using models 1 & 2
#Prewhitening

diff2x = diff(VegaTS, 2)
Acf(diff2x, na.action = na.omit)
Pacf(diff2x, na.action = na.omit)
eacf(diff2x)

#As models 1,2,3 have NA values we've omitted them for our best model in additon
prewhiten(VegaTS, MinnTS, x.model = model4, main = "Auto from Minn model 4")
prewhiten(VegaTS, MinnTS, x.model = model1, main = "Model 1 prewhittened")
prewhiten(VegaTS, MinnTS, x.model = Arima(MinnTS, order = c(1,2,0), seasonal = c(2,0,0)), main = "unique model prewhittened")

#Not Prewhittened 
corModel1 = Arima(MinnTS, xreg = VegaTS, order = c(1,2,3), seasonal = c(2,0,0))
corModel2 = Arima(MinnTS, xreg = VegaTS, order = c(1,2,2), seasonal = c(2,0,0))
#Prewhittened best two
corModel3 = Arima(MinnTS, xreg = lag(VegaTS, 7), order = c(3,2,0), seasonal = c(2,0,0))
corModel4 = Arima(MinnTS, xreg = lag(VegaTS, 7), order = c(1,2,2), seasonal = c(2,0,0))

#Nothing is found forecast would not be helpful for double difference
#Let's look at our raw data models
#Non-Whitened first
#corModel1 first
backtest(corModel1, MinnTS, nTest, h=1)
coeftest(corModel1)
Acf(corModel1$residuals)

#corModel2
backtest(corModel2, MinnTS, nTest, h=1)
coeftest(corModel2)
Acf(corModel2$residuals)

fit1 = dynlm(MinnTS ~ lag(VegaTS, 0) + lag(VegaTS, 7), + lag(VegaTS, 6) + lag(VegaTS, -1) + lag(VegaTS, -2))
summary(fit1)

#corModel Special
WMModel1 = Arima(subset(MinnTS, end = 285), xreg = subset(VegaTS, start = 7), order = c(3,2,0), seasonal = c(2,0,0))
backtest(WMModel1, MinnTS, nTest, h =1)
coeftest(WMModel1)
Acf(WMModel1$residuals)
#CorModel Special2 
WMModel2 = Arima(subset(MinnTS, end = 285), xreg = subset(VegaTS, start = 7), order = c(1,2,2), seasonal = c(2,0,0))
backtest(WMModel2, MinnTS, nTest, h =1)
coeftest(WMModel2)
Acf(WMModel2$residuals)
#corModel3
backtest(corModel3, MinnTS, nTest, h = 1)
coeftest(corModel3)
Acf(corModel3$residuals)
#corModel4
backtest(corModel4, TMinnTS, nTest, h = 1)
coeftest(corModel4)
Acf(corModel4$residuals)

cormodel3NOAR1 = Arima(MinnTS, xreg = lag(VegaTS, 7), order = c(3,2,0), fixed = c(0,NA,NA,NA,NA,NA), seasonal = c(2,0,0))
backtest(cormodel3NOAR1, MinnTS, nTest, h =1)
coeftest(cormodel3NOAR1)
Acf(cormodel3NOAR1$residuals)

#Examing Volitility via Garch
library(fGarch)
#Technically we have gone through the differencing looking at the residuals
hist(diff((MinnTS)))
Acf(model1$residuals^2)
res = model1$residuals
archfit = garch(res, order = c(0,1))


coeftest(archfit)
autoplot(archfit$residuals, main="ARCH(1) Residuals")  # As good as it gets
Acf(archfit$residuals^2, main="ACF of ARCH(0, 1) residuals", ylim=c(-.05, .25), lag.max=25)

res2 = WMModel1$residuals
archfit2 = garch(res, order = c(0,1))
coeftest(archfit2)
autoplot(archfit2$residuals, main="ARCH(0,1) Co-Int. Residuals")  # As good as it gets


#Let's look at it all together
library(vars)
combined <- Project_Data_Minn_Combined
s = VARselect(combined[, 2:4], lag.max=10, type="const")
s
s$selection

VarModel = VAR(combined[,2:4], p=5, type = "const")
VarModel

serial.test(VarModel, lags.pt=10, type="PT.asymptotic")
coeftest(VarModel)
plot(forecast(VarModel, h = 10))

VarModel2 = VAR(combined[,2:4], p=10, type = "const")
VarModel2
serial.test(VarModel2, lags.pt=10, type="PT.asymptotic")
coeftest(VarModel2)
