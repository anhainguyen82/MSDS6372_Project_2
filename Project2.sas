proc import datafile="/home/anhainguyen820/sasuser.v94/wine_train.csv"
          dbms=dlm out=wine replace;
     delimiter=',';
     getnames=yes;
run;

proc import datafile="/home/anhainguyen820/sasuser.v94/wine_test.csv"
          dbms=dlm out=test replace;
     delimiter=',';
     getnames=yes;
run;

/*EDA of original data, split into two parts for easy viewing*/
proc sgscatter data=wine;
matrix "fixed.acidity"N
	   "volatile.acidity"N
	   "citric.acid"N
	   "residual.sugar"N
 	   chlorides / diagonal=(histogram);
run;

proc sgscatter data=wine;
matrix "free.sulfur.dioxide"N
	   "total.sulfur.dioxide"N
	   density
	   pH
	   sulphates
	   alcohol / diagonal=(histogram);
run;

/*log transformed non-normal variables, fixed.acidity not used because it contains 0's*/
data wine; set wine;
"log.residual.sugar"N = log("residual.sugar"N);
"log.chlorides"N = log(chlorides);
"log.free.sulfur.dioxide"N = log("free.sulfur.dioxide"N);
"log.total.sulfur.dioxide"N = log("total.sulfur.dioxide"N);
"log.sulphates"N = log(sulphates);
"log.alcohol"N = log(alcohol);
run;

data test; set test;
"log.residual.sugar"N = log("residual.sugar"N);
"log.chlorides"N = log(chlorides);
"log.free.sulfur.dioxide"N = log("free.sulfur.dioxide"N);
"log.total.sulfur.dioxide"N = log("total.sulfur.dioxide"N);
"log.sulphates"N = log(sulphates);
"log.alcohol"N = log(alcohol);
run;

/*EDA of log transformed variables*/
proc sgscatter data=wine;
matrix "log.residual.sugar"N
	   "log.chlorides"N
	   "log.free.sulfur.dioxide"N
	   "log.total.sulfur.dioxide"N
	   "log.sulphates"N
	   "log.alcohol"N
	   / diagonal=(histogram);
run;

/*Univariate model with residuals to check assumptions*/
proc glm data=wine plots=diagnostics;
class Outcome;
model "log.residual.sugar"N
	   "log.chlorides"N
	   "log.free.sulfur.dioxide"N
	   "log.total.sulfur.dioxide"N
	   "log.sulphates"N
	   "log.alcohol"N
	   "fixed.acidity"N
	   "volatile.acidity"N
	   "citric.acid"N
	   density
	   pH
	   = Outcome;
Output Out=Errs R=Eact Eant;
Run;
quit;

/*test for homogeneity*/
proc discrim data=wine pool=test;
class Outcome;
var "log.residual.sugar"N
	   "log.chlorides"N
	   "log.free.sulfur.dioxide"N
	   "log.total.sulfur.dioxide"N
	   "log.sulphates"N
	   "log.alcohol"N
	   "fixed.acidity"N
	   "volatile.acidity"N
	   "citric.acid"N
	   density
	   pH;
run;

/*PCA*/
proc princomp plots=all data=wine out=pca;
var "log.residual.sugar"N 
	   "log.chlorides"N
	   "log.free.sulfur.dioxide"N
	   "log.total.sulfur.dioxide"N
	   "log.sulphates"N
	   "log.alcohol"N
	   "fixed.acidity"N
	   "volatile.acidity"N
	   "citric.acid"N
	   density
	   pH;
id Outcome;
run;

proc sgplot data=pca;
scatter x=PRIN1 y=PRIN2 / group=Outcome;
ellipse x=PRIN1 y=PRIN2 / group=Outcome;
run;

/*MANOVA of all variables*/
proc glm data=wine;
class Outcome;
model "log.residual.sugar"N
	   "log.chlorides"N
	   "log.free.sulfur.dioxide"N
	   "log.total.sulfur.dioxide"N
	   "log.sulphates"N
	   "log.alcohol"N
	   "fixed.acidity"N
	   "volatile.acidity"N
	   "citric.acid"N
	   density
	   pH
	   = Outcome;
Manova H=_All_ / PrintE PrintH Canonical;
run;

/*LDA*/
proc discrim data=wine pool=test testdata=test;
class Outcome;
var "log.residual.sugar"N
	   "log.chlorides"N
	   "log.free.sulfur.dioxide"N
	   "log.total.sulfur.dioxide"N
	   "log.sulphates"N
	   "log.alcohol"N
	   "fixed.acidity"N
	   "volatile.acidity"N
	   "citric.acid"N
	   density
	   pH;
run;

/*Logistic regression*/
proc logistic data=wine plots=roc;
class Outcome / param=ref;
model Outcome(event='fine') = "log.residual.sugar"N
	   						  "log.chlorides"N
	  						  "log.free.sulfur.dioxide"N
	  						  "log.total.sulfur.dioxide"N
	   						  "log.sulphates"N
	   						  "log.alcohol"N
	   						  "fixed.acidity"N
	  						  "volatile.acidity"N
	  						  "citric.acid"N
	  						  density
	 						  pH/ selection=forward scale=none lackfit ctable;
run;

/*Simple Logistic regression*/
proc logistic data=wine plots=roc;
class Outcome / param=ref;
model Outcome(event='fine') = "fixed.acidity"N
	                          "volatile.acidity"N
	   						  "citric.acid"N
	 						  "residual.sugar"N
 						      "free.sulfur.dioxide"N
	 						  "total.sulfur.dioxide"N
	 						  density
	 						  pH
	 						  sulphates
	 						  alcohol
	 						  chlorides/ scale=none lackfit ctable;
run;

proc univariate data = wine;
histogram;
run;

