%let path= /home/u4699529/EPG1V2/data;

*************************0 step: database loading or import***********************;

*********************csv xlsx or tab file with one sheet ********************;

title 'Import csv tab or xlsx file with only one sheet';
proc import datafile="&path/storm_damage.csv" dbms=csv 
			out=training.storm_damage replace;
			guessingrows=max;
run;


*************************Excel file with multiple sheets**************************;

****************using proc import and specifying excel sheet******************;
/* 
In this database we get many sheets which is related to storm description.
Here we specify the sheet name that we want to import "Storm_summary". 
*/

title 'Import Excel file by specifying sheet';
proc import datafile="&path/storm" dbms=xlsx 
			out=training.storm_summary  replace;
			sheet="Storm_Summary";
run;

proc import datafile="&path/storm" dbms=xlsx 
			out=training.storm_detail  replace;
			sheet="Storm_Detail";
run;


**********using libname engine for importing all sheets*********;
/*
It is useful to use library for excel file with multiple sheets. Using this method, 
Each sheet will be a sas dataset in the library. 
*/
title 'Load Excel file with all sheets and each sheet as one dataset';
options validvarname=V7;
libname training xlsx "&path/storm.xlsx";

/*So, in my library training i get 8 sas datasets which represent each dataset.*/ 


*****************************1st step: Data display********************************;

***** Let's take a look on database content (variables type length format) ******;

title "storm_summary contents";
proc contents data=training.storm_summary;
run;
title "storm_detail contents";
proc contents data=training.storm_detail;
run;
title "storm_damage contents";
proc contents data=training.storm_damage;
run;
title "storm_2017 contents";
proc contents data=training.storm_2017;
run;

/*we can see the number of observations and variables in each dataset. Also this function
provides us the type, length format and label for each variable. This can be helpful
if we have to reformat variables, change their length or drop some variables etc...
For some variable we don't get the number of observations. So we can see this information
with proc sql step or by a proc means step*/
proc sql;
select count(*) as N
from training.storm_summary;
quit;

proc sql;
select count(*) as N
from training.storm_detail;
quit;

/*
The library contains 8 sas datasets that are linked together. in fact storm_summary
resume some main characteristics of storm. While storm_detail provide more details
for each storm name.
Storm_Damage table list the damage caused by storm event  to 
The table basin_codes, type_codes or subbasin_codes provides codification of basin, subbasin
and storm type.
storm_2017 dataset provide additional storm summary for 2017 year.
So we can merge or join these datasets together depending of our goals.

For example in storm_summary We get 3118 observations and 12 variables.
Some variables are character (Basin, HemEW HemNS Name, Type) while the remaining 
are numeric with different length. In this table we have the type of storm represented
by code. So we can retrieve the label of this code in type_codes table.
*/

/*In addition to proc content we can have a brief overview on each table*/
title 'Display only 50 first lines of storm_summary table';
proc print data=training.storm_summary (obs=50) ;
run;

title 'Display only 50 first lines of storm_detail table';
proc print data=training.storm_detail (obs=50) ;
	*var <name> we can specify the variable to be printed;
	*where <conditions> we can also filter or select a certain row based on conidtion;
run;

***************************2nd step: Exploring data*****************************;

/* For each dataset, we will explore the data. Which consists in describe or summary
data (count, min max mean std), plot them or other exploration technique,
in order to understand datsets, to check missing values, outliers or 
other inconsistencies in data
 */ 
/*We focus our exploration on storm_summary as there are many tables. This is just
an overview of data preparation using sas.*/
****************************storm_summary table****************************;

******************************Numeric variables****************************;
title 'Summary of numeric variables';
proc means data=training.Storm_Summary N nmiss min max mean median std maxdec=2 ;
	var MaxWindMPH MinPressure Lat Lon; /*we can omit this
	statement sas will consider only numeric variable*/
	*class Basin we can do the summary group by one variable ; 
run;

/*Proc means is used to summary numeric variables in a dataset. Many statistics 
can be displayed such as number of observations, number of missing values, min and max 
or other statistics of dispersion or central trends. We can therefore try to detect
outliers or others stranges informations.

Here we can notice that there is 23 missing values for MaxWindMPH and 196 forMinPressure.
MaxWindMPH ranges from 6 to 213 with in mean 79. The minimmun latitude is -40 and the
maximum is 53. The mean of latitude is 8.76. While longitude range from -179 to 179
with a mean of 26.2
Also, variable MinPressure have negative values. We will need to check it.
For others numerics variables there are no suspected datas.
*/

proc univariate data= training.storm_summary;
	var MinPressure ;
run;

proc print data=training.storm_summary;
	where MinPressure < 0 and MinPressure is not missing or MinPressure =100;
run;

/* Two observations with negative MinPressure.We will replace them by missing values.
There is one outlier in this variable (-100). We will replace it by missing value.
Number of mising values of this variable is about 9% of all data. We can 
decide to ignore them. But you can replace them by the mean of this variable or
the mean of basin group of this observation.*/


*********************Discrete or Qualitative variables********************;

title 'Distribution of discrete and qualitative variables';
proc freq data=training.storm_summary;
	tables Season Basin Type 'Hem NS'n 'Hem EW'n;
run;
/*Season can be consider as a discrete variable. 
We can notice that for the basin there is one basin name 'na' which have 
16 observations. We can guess that this modality is equal to 'NA' basin as there is
no basin code na in basin_codes tables. We will need to recode it in NA.
 */
proc freq data=training.storm_summary order=freq;
	tables Basin / nocum plots=freqplot (orient=horizontal);
run;


***************storm_detail - storm_damage - storm_range - storm2017************;
/*We won't explore all tables. But below, there is codes to perform it*/

******************************Numeric variables***********************************;
/*Instead of doing this proc step for each dataset we can use the macro which set
the name of dataset and used in proc means statement as we don't need to specify 
the name of numeric variable*/

%let dataset=Storm_Detail;
*%let dataset=Storm_Damage;
*%let dataset=Storm_Range;
*%let dataset=Storm_2017;

proc means data=training.&dataset N nmiss min max mean median std ;
run;


*********************Discrete or Qualitative variables********************;
proc freq data=training.Storm_Detail;
	tables Season Basin Sub_basin Hem_NS Hem_EW Region;
run;

proc freq data=training.Storm_Range;
	tables Season Basin;
run;

proc freq data=training.Storm_2017;
	tables Season Basin;
run;

/* Note that this dataset is very clean. We can be faced of some datasets which need
more exploring, more inconstencies between datas and therefore lead to more 
cleaning works*/ 

**************************3rd step: Data preparation***************************;

/*Data merging
Now lets merge storm1 with basin_codes and type_codes to get BasinName and
Storm_Type.
*/
title 'Merge storm_summary with basin_codes and type_codes';
proc sql;
create table training.storm1 as
	select * 
	from training.storm_summary as sf left join training.Basin_Codes as bc 
		on sf.Basin=bc.Basin left join training.Type_Codes as tc on sf.Type=tc.Type; 
quit;

/* we wil now concatenate this dataset with storm for season 2017*/
title 'Concatenate others storms  with 2017 storms';
data training.storm1_new;
	set training.storm1 training.storm_2017;
run;

/*In the previous step we note that we must change the name of variable Hem NS and Hem EW to 
avoid space, replace -9999 values in MinPressure by missing values, recode na values
by NA in basin variables. */

title 'Recode variables';
data training.storm (rename=('Hem NS'n=Hem_NS 'Hem EW'n=Hem_EW));
	set training.storm1_new;
	
	if MinPressure=-9999 then MinPressure=.;
	else if MinPressure=100 then MinPressure=.;
	else MinPressure=MinPressure;
	
	if Basin='na' then Basin='NA';
	else Basin=Basin;
run;

proc means data=training.storm N nmiss min max mean median std maxdec=2 ;
	var MinPressure;
run;	

proc freq data=training.storm;
	tables Season Basin Type Hem_NS Hem_EW;
run;

/*
Then we will create other news variables:
- PressureGroup (MinPressure<=920 then PressureGroup=1)
- oceancode equal to the second letter of basin name
- duration of storm in days
- recode oceancode
*/
title 'Adding new variables: Pressure Group, Ocean code, Ocean, duration';
data training.storm_final ;
	set training.storm;
	if MinPressure=. then PressureGroup=.;
	ELSE if MinPressure<=920 then PressureGroup=1;
	ELSE if MinPressure>920 then PressureGroup=0;
	ELSE PressureGroup=9;
	
	oceancode=substr(basin,2,1);
	
	if oceancode="A" then Ocean="Atlanic";
	else if oceancode="P" then Ocean="Pacific";
	else if oceancode="I" then Ocean="Indian";
	
	duration=EndDate-StartDate;
run;



/*So we obtain the final dataset which will be use for table, figure plot and differents 
analyses*/

*************************Step 4: Data analysis and report************************;
















title;
footnote;
