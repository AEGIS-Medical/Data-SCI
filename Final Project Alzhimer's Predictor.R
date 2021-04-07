##Final Project: 
##Written by Ryan Hossa
##Goal: Suprivised clustering model

#Installation of Packages and calling Libraries *note any library not covered in lab is noted for purpose
install.packages("ggplot2")
install.packages("caret")
install.packages("ElemStatLearn")
install.packages("rpart")
install.packages("dplyr")
install.packages("rpart.plot")
install.packages("Metrics")
install.packages("e1071")
install.packages("cluster")
install.packages("NbClust")
install.packages("factoextra")
install.packages("fpc")#Various methods for clustering and cluster validation
install.packages("vtreat")#library vtreat is a processor/conditioner that prepares real-world data for supervised machine learning or predictive modeling in a statistically sound manner.
install.packages("xgboost")#implements machine learning algorithms under the Gradient Boosting framework
install.packages("randomForest")
install.packages("plyr")#Note THIS IS THE ISSUE I WAS HAVING THIS PACKAGE ISN'T INSTALLABLE ON THIS RSTUDIO Version
install.packages("caretEnsemble")
install.packages("PerformanceAnalytics")#This allows us to use the chart function on showing correlation between variables
install.packages("ggpubr")#For comparing two specific variables in a correlation using ggscatter function
install.packages("pROC")
install.packages("MLmetrics")
install.packages("ROCR")
install.packages("SDMTools")#For SVM Model

library(ggplot2)
library(caret)
library(rpart)
library(rpart.plot)
library(dplyr)
library(plyr)
library(xgboost)
library(fpc)
library(vtreat)
library(Metrics)
library(NbClust)
library(randomForest)
library(caretEnsemble)
library(e1071)
library(cluster)
library(NbClust)
library(factoextra)
library(PerformanceAnalytics)
library(ggpubr)
library(pROC)
library(MLmetrics)
library(ROCR)
library(SDMTools)
library(ElemStatLearn)

#Description of Data via plots and set-up
set.seed(123)
df <- read.csv("oasis_longitudinal.csv")
dim(df)
str(df)
summary(df)
'As Hand is 1 value throughout it can be dropped to avoid noise'
table(df$Hand)
df$Hand <- NULL
'Again we do not need Subject ID nor MRI ID these are just unique identifiers but we are reserving the data in another variable'
subject_id <- df$Subject.ID
MRI_id <- df$MRI.ID

df$Subject.ID <- NULL
df$MRI.ID <- NULL

sort(apply(df, 2, function(x){sum(is.na(x))}), decreasing = TRUE)

table(df$SES)
#Data Descriptions

chart.Correlation(select(df, Age, EDUC, SES, MMSE, eTIV, nWBV, ASF), histogram = TRUE, main = "Correlation between Variables")
ggplot(df, aes(as.factor(CDR),Age))+
  geom_boxplot(col = "purple")+
  ggtitle('Critical Dementia Rating by Age')+
  xlab('CDR')+
  theme(plot.title = element_text(hjust = .5))
ggplot(df, aes(as.factor(CDR), Age, fill = M.F))+
  geom_boxplot()+
  ggtitle('Critical Dementia Rating by Age')
  xlab("CDR")+
  geom_text(stat = "count", aes(label = ..count..), y = 60, col = "blue")+
  theme(plot.title = element_text(hjust = .5))
ggplot(df, aes(Age, fill = M.F))+
  geom_histogram()+
  facet_wrap(~M.F)+
  scale_fill_manual(values = c("pink", "blue"))+
  ggtitle("Distribution of Age by Sex")+
  theme(plot.title = element_text(hjust = .5))
ggplot(df, aes(Group, fill = as.factor(CDR)))+
  geom_bar()+
  ggtitle("Critical Dementia Ratings Breakdown of Participants")+
  theme(plot.title = element_text(hjust = .5))
ggplot(df, aes(Group, EDUC))+
  geom_boxplot(col = "green")+
  geom_point(stat = "summary", fun.y = "mean", col = "red", size = 4)+
  ggtitle("Education vs Dementia Grouping")+
  theme(plot.title = element_text(hjust = .5))
ggplot(df, aes(M.F, EDUC))+
  geom_boxplot(col = "cyan")+
  ggtitle("Years of Education by Sex")+
  theme(plot.title = element_text(hjust = .5))
ggplot(df, aes(Group, MMSE))+
  geom_point(col = "black")+
  geom_point(stat = "summary", fun.y = "mean", col = "red", size = 5)+
  geom_point(stat = "summary", fun.y = "median", col = "yellow", size = 5)+
  ggtitle("Mini Mental State Exam by Group")+
  theme(plot.title = element_text(hjust = .5))
ggscatter(df, x = "CDR", y = "ASF", add = "reg.line", conf.int = TRUE, cor.coef = TRUE, cor.method = "pearson", xlab = 'Critical Dementia Rating', ylab = 'Atlas Scaling Factor')
ggscatter(df, x = "MMSE", y = "EDUC", add = "reg.line", conf.int = TRUE, cor.coef = TRUE, cor.method = "pearson", xlab = 'Mini-Mental', ylab = 'Education')
ggscatter(df, x = "Group", y = "ASF", add = "reg.line", conf.int = TRUE, cor.coef = TRUE, cor.method = "pearson", xlab = 'Diagnosis Group', ylab = 'Atlas Scaling')

ggplot(df, aes(EDUC, MMSE, col = M.F))+
  geom_point()+
  geom_smooth(method = "lm", se = FALSE)+
  ggtitle("Education vs Mini-Mental by Sex")+
  theme(plot.title = element_text(hjust = .5))
ggplot(df, aes(as.factor(CDR), ASF, fill = as.factor(CDR)))+
  geom_boxplot(aes(x = CDR+.1, group = as.factor(CDR)), width = .25)+
  ggtitle("Atlas Scaling Factor by Critical Dementia Rating")+
  geom_dotplot(aes(x = CDR-.1, group = as.factor(CDR)), binaxis = "y", binwidth = .01, stackdir = "center")+
  theme(plot.title = element_text(hjust = .5))
anova(aov(EDUC~M.F, data = df))
kruskal.test(df$EDUC, as.factor(df$M.F))

#Data Manipulation Replacing Those Missing Values
df$SES[is.na(df$SES)] <- median(df$SES, na.rm = TRUE)
df$MMSE[is.na(df$MMSE)] <- median(df$MMSE, na.rm = TRUE)
#Creation of a new column of data if needed for diagnosis groupings, don't really have a plan for this but think it might come in handy for predict
#df$Dementia <- 0
#df$Dementia[df$CDR == 0] <- 0
#df$Dementia[df$CDR > 0] <- 1
#df$Dementia <- as.factor(df$Dementia) * Never needed to create another column
#Finally we are going to create dummy variables as in my proposal we are looking at KNN model and the other model is SVM which we will get to later
df$Group<-as.factor(df$Group)
df$M.F<-as.factor(df$M.F)
df$CDR<-as.factor(ifelse(df$CDR==.5, 1, df$CDR))
#then we are going to break down CDR into yes no essentially for demented or non
factor_variables<-df[, sapply(df, is.factor)]
CDR<-factor_variables$CDR
dum_var<-dummyVars(~., factor_variables[,-3])
factor_variables<-as.data.frame(predict(dum_var, factor_variables[,-3]))
factor_variables<-as.data.frame(cbind(factor_variables, CDR))
#Hyper
numeric_variables<-df[, sapply(df, is.numeric)]
correlations<-cor(numeric_variables)
highCorr<-findCorrelation(correlations, cutoff = .80) #Note we aren't going for tried 75 and 80 because it maybe a little hard pressed
numeric_variables<-numeric_variables[,-highCorr]
#Scaling and Centering, our last prerprocess step to ensure everything is running on the same scale on well... numeric values
numeric_variables$Visit<-scale(numeric_variables$Visit)
numeric_variables$Age<-scale(numeric_variables$Age)
numeric_variables$EDUC<-scale(numeric_variables$EDUC)
numeric_variables$MMSE<-scale(numeric_variables$MMSE)
numeric_variables$nWBV<-scale(numeric_variables$nWBV)
numeric_variables$ASF<-scale(numeric_variables$ASF)
#We can now drop group variables and create a training data varaible
train2<-as.data.frame(cbind(numeric_variables, factor_variables))
trainingset<-createDataPartition(y = train2$CDR, p = 0.8, list = FALSE)
training <- train2[trainingset,]
testing <- train2[-trainingset,]
ffControl <- trainControl(method = "repeatedcv", number = 5, repeats = 5)
knnew <- train(CDR ~ ., data = train_transformed, method = "knn",  trControl = fitControl)

train1<-as.data.frame(cbind(numeric_variables, factor_variables))
train1<-train1[,c(-8,-9,-10)]
#Modelling, since we are building a KNN let's see how many clusters are important
#I would use the nbclust but seem to be erroring out note sure how fix soo let's examine it graphically
fviz_nbclust(train1, kmeans, method = "wss")
#Support Vector Model
#SVM
set.seed(17)
svm2 <- train(MMSE~., data = train1, method = "svmRadial", metric = "Accuracy", trControl = fitControl, tuneLength = 15)
svm  <- train(CDR~., data = train1, method = "svmRadial", metric = "Accuracy", trControl = fitControl, tuneLength = 15)
varImp(svm)
plot(svm)
max(svm$results$Accuracy)
fitControl <- trainControl(method = "repeatedcv", number = 5, repeats = 10)#K = 5, KNN models suffers much more at 6
knn1 <- train(CDR ~ ., data = train1, method = "knn",  trControl = fitControl)
max(knn1$results$Accuracy)

plot(knn1)
varImp(knn1)
svmmodel.predict<-predict(svm,subset(train1,select= CDR),decision.values=TRUE)
svmmodel.probs<-attr(svmmodel.predict,"decision.values")
svmmodel.class<-predict(svm,train1,type="raw")
svmmodel.labels<-train1$CDR
#analyzing result
svmmodel.confusion<-confusion.matrix(svmmodel.labels,svmmodel.class)
svmmodel.accuracy<-prop.correct(svmmodel.confusion)
svmmodel.accuracy
svmmodel.prediction<-prediction(svmmodel.probs,svmmodel.labels)
svmmodel.performance<-performance(svmmodel.prediction,"tpr","fpr")
svmmodel.auc<-performance()
#roc analysis for test data !!!!!! SEE OTHER R FILE THIS IS WHERE I RAN INTO PROBLEMS AND WANTED TO SEPERATE AND SIMPLIFY MY DATA TRANFORMATIONS
svmmodel.prediction<-prediction()
svmmodel.performance<-performance(svmmodel.prediction,"tpr","fpr")
svmmodel.auc<-performance(svmmodel.prediction,"auc")@y.values[[1]]

#Validation of Model Section
models<-list("K-Nearest" = knn1, "Support Vector Model" = svm)
modelCor(resamples(models))
mod_accuracy<-c(0.7872099, 0.8236723)
Model<-c("K-Nearest", "Support Vector Model")
data.frame(Model, mod_accuracy)%>%
  ggplot(aes(reorder(Model, mod_accuracy), mod_accuracy*100))+
  geom_point(col = "black", size = 6)+
  geom_point(col = "red", size = 3)+
  ggtitle("Accuracy by Model")+
  ylab("Accuracy %")+
  xlab("Model")+
  theme(plot.title = element_text(hjust = .5))