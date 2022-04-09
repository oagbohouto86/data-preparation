## ----setup, include=FALSE------------------------------------------------------------
knitr::opts_chunk$set(echo = TRUE)


## ------------------------------------------------------------------------------------
library("tidyverse")
library("MASS")
library("dplyr")
library("readxl")
library("pastecs")
library("summarytools")


## ------------------------------------------------------------------------------------
path="D:/git/preparation/"


## ------------------------------------------------------------------------------------
storm_damage<-read.csv(file=paste(path,"storm_damage.csv",sep=""),header=TRUE)
#storm_damage=read.csv(file="D:/git/preparation/storm_damage.csv",header=TRUE)


## ------------------------------------------------------------------------------------
loadsheet <- function(excel_sheet){
    read_excel("D:/git/preparation/storm.xlsx",sheet=excel_sheet)
}


## ------------------------------------------------------------------------------------
Storm_Summary <- loadsheet(excel_sheet = "Storm_Summary")
Storm_Detail <- loadsheet(excel_sheet = "Storm_Detail")
Storm_Damage <- loadsheet(excel_sheet = "Storm_Damage")
Storm_Range <- loadsheet(excel_sheet = "Storm_Range")
Storm_2017 <- loadsheet(excel_sheet = "Storm_2017")
Storm_Range <- loadsheet(excel_sheet = "Storm_Range")
Basin_Codes <- loadsheet(excel_sheet = "Basin_Codes")
Type_Codes <- loadsheet(excel_sheet = "Type_Codes")


## ------------------------------------------------------------------------------------
str(Storm_Summary)
str(Storm_Detail)
str(Storm_Damage)
str(Storm_2017) 


## ------------------------------------------------------------------------------------
head(Storm_Summary,n=50)
head(Storm_Detail,n=50)


## ------------------------------------------------------------------------------------
summary(Storm_Summary) #basic stats such as min max mean
#by(Storm_Summary, Storm_Summary$Basin, summary)#Summary by a variable.
#stat.desc(Storm_Summary) #to have more statistics about numeric variable


## ------------------------------------------------------------------------------------
#Storm_Summary[c(which(Storm_Summary$MinPressure==-9999 | Storm_Summary$MinPressure==100)),]# fonction de base which 
filter(Storm_Summary,MinPressure==-9999 | MinPressure==100) #fonction plus simple


## ------------------------------------------------------------------------------------
#prop.table(table(Storm_Summary$Basin))*100 #Construite à partir de la fonction de base table
freq(Storm_Summary$Basin,report.nas = FALSE) #Fonction plus fournie de la librairie summary_tool
freq(Storm_Summary$Type,report.nas = FALSE)
freq(Storm_Summary$`Hem NS`,report.nas = FALSE)
freq(Storm_Summary$`Hem EW`,report.nas = FALSE)


## ------------------------------------------------------------------------------------
summary_function<-function(dataset){
  stat.desc(dataset)
}


## ------------------------------------------------------------------------------------
summary_function(Storm_Detail)


## ------------------------------------------------------------------------------------
storm1=Storm_Summary %>% merge( Basin_Codes, by=c('Basin', 'Basin'),all.x=TRUE) %>% merge( Type_Codes, by=c('Type', 'Type'),all.x=TRUE) #left join
#storm1_new=storm1 %>% left_join( Basin_Codes, by=c('Basin'='Basin')) %>% left_join( Type_Codes, by=c('Type'='Type'))


## ------------------------------------------------------------------------------------
storm1_new=bind_rows(storm1,Storm_2017)


## ------------------------------------------------------------------------------------
names(storm1_new)
names(storm1_new)=c("Type","Basin","Season","Name","MaxWindMPH","MinPressure","StartDate", "EndDate", "Hem_NS", "Hem_EW", "Lat","Lon", "BasinName", "Storm_Type", "Location")

storm1_new$MinPressure[storm1_new$MinPressure==-9999 |storm1_new$MinPressure==100 ]<-NA
storm1_new$Basin[storm1_new$Basin=="na"]<-"NA"
summary(storm1_new$MinPressure)
freq(storm1_new$Basin)


## ------------------------------------------------------------------------------------
storm_final=storm1_new %>% mutate(oceancode=substr(Basin,2,2))%>% mutate(ocean=recode(oceancode,"A"="Atlantic","P"="Pacific","I"="Indian",.default = NULL)) %>%mutate(PressureGroup=cut(MinPressure, c(872,920,1012), include.lowest = FALSE,right=TRUE, labels = c(1, 2))) %>% mutate(duration=difftime(EndDate,StartDate,units='weeks'))

