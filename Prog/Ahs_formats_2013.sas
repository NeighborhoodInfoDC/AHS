/**************************************************************************
 Program:  Ahs_formats_2013.sas
 Library:  AHS
 Project:  Urban-Greater DC
 Author:   P. Tatian
 Created:  06/19/19
 Version:  SAS 9.4
 Environment:  Local Windows session (desktop)
 GitHub issue:  1
 
 Description:  Create AHS formats for 2013. 

 Adapted from "AHS 2013 Value Labels Package"
 downloaded from
 https://www.census.gov/programs-surveys/ahs/data/2013/ahs-2013-
 public-use-file--puf-/2013-ahs-metropolitan-puf-microdata.html
 
 Format input file (2013ValLabels_edit.csv) has been edited from 
 original format file (2013ValLabels.csv) to add missing value labels. 

 Modifications:
**************************************************************************/

%include "L:\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( AHS )

*Step 1:  Import the Formats CSV file into SAS;
data temp;
      infile "&_dcdata_r_path\AHS\Raw\2013-met\2013ValLabels_edit.csv" 
          delimiter = ',' MISSOVER DSD FIRSTOBS=2;

     informat TABLE $32. ; 
     informat NAME $32. ;
     informat FMTNAME $32. ;
     informat VALUE $16. ;
     informat LABEL $43. ;
     informat TYPE $1. ;
     informat FLAT $3. ;
     informat METRO $3. ;
     
     format TABLE $32. ;
     format NAME $32. ;   
     format FMTNAME $32. ;         
     format VALUE $16. ;
     format LABEL $43. ;
     format TYPE $1. ;
     format FLAT $3. ;
     format METRO $3. ;
     
     
     input TABLE $ NAME $ FMTNAME $ VALUE $ LABEL $ TYPE $ FLAT $ METRO $;
run;

*Step 2:  Reshape the new SAS dataset into the type SAS dataset that Proc Format can
     utilize;
data temp1;
     set temp;
     if value not in ('-6','-7','-8','-9'); *these values are not used in SAS version of the PUFs;
     rename value=START;
     end=value;
     drop table;
run;

/*This code eliminates duplicate formating rows caused by variables that are found on
     multiple AHS tables or share a common format name */
proc sort data=temp1 out=temp2 nodupkey ;
     by FMTNAME START END LABEL TYPE;
run;

*Step 3:  Build the Format Catalog;
proc format LIBRARY=AHS
     cntlin = temp2;
run;

proc catalog catalog=AHS.formats;
  contents;
quit;

