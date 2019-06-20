/**************************************************************************
 Program:  Ahs_2007_met.sas
 Library:  AHS
 Project:  Urban-Greater DC
 Author:   P. Tatian
 Created:  06/19/19
 Version:  SAS 9.4
 Environment:  Local Windows session (desktop)
 GitHub issue:  1
 
 Description:  Create 2007 AHS metro area data sets.

 Modifications:
**************************************************************************/

%include "L:\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( AHS )

** Library reference for HUD-provided data sets **;
libname ahs2007 "L:\Libraries\AHS\Raw\2007-met";

** Create format assignments **;

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
     
     length sfmtname $ 40;
     
     if type = 'C' then sfmtname = '$' || left( fmtname );
     else sfmtname = left( fmtname );
     
run;

proc sort data=temp nodupkey;
     by table name fmtname type;
run;

proc sql noprint;

  select distinct cat( trim(name), ' ', trim(sfmtname), '.' ) into :fmt_stmt_hu separated by ' ' from temp
  where table in ( "NEWHOUSE", "MORTG", "OWNER" );

  select distinct cat( trim(name), ' ', trim(sfmtname), '.' ) into :fmt_stmt_per separated by ' ' from temp
  where table in ( "PERSON", "JTW" );

  select distinct cat( trim(name), ' ', trim(sfmtname), '.' ) into :fmt_stmt_rmov separated by ' ' from temp
  where table in ( "RMOV" );

  select distinct cat( trim(name), ' ', trim(sfmtname), '.' ) into :fmt_stmt_himp separated by ' ' from temp
  where table in ( "HOMIMP" );

quit;

%put _user_;

run;

** Housing unit data **;

proc sort data=ahs2007.newhouse out=newhouse;
  by smsa control;
run;

proc sort data=ahs2007.mortg out=mortg;
  by smsa control;
run;

proc sort data=ahs2007.owner out=owner;
  by smsa control;
run;

data Ahs_2007_met_hu;

  merge newhouse mortg owner;
  by smsa control;
  
run;

proc datasets library=work memtype=(data) nolist;
  modify Ahs_2007_met_hu;
    format &fmt_stmt_hu;
quit;

%Finalize_data_set( 
  /** Finalize data set parameters **/
  data=Ahs_2007_met_hu,
  out=Ahs_2007_met_hu,
  outlib=AHS,
  label="American Housing Survey, 2007, metropolitan area, housing units",
  sortby=smsa control,
  /** Metadata parameters **/
  revisions=%str(New file.),
  /** File info parameters **/
  printobs=0,
  freqvars=smsa
)

** Person data **;

proc sort data=ahs2007.person out=person;
  by smsa control person;
run;

proc sort data=ahs2007.jtw out=jtw;
  by smsa control person;
run;

data Ahs_2007_met_per;

  merge person jtw;
  by smsa control person;
  
run;

proc datasets library=work memtype=(data) nolist;
  modify Ahs_2007_met_per;
    format smsa $smsa. &fmt_stmt_per;
quit;

%Finalize_data_set( 
  /** Finalize data set parameters **/
  data=Ahs_2007_met_per,
  out=Ahs_2007_met_per,
  outlib=AHS,
  label="American Housing Survey, 2007, metropolitan area, persons",
  sortby=smsa control person,
  /** Metadata parameters **/
  revisions=%str(New file.),
  /** File info parameters **/
  printobs=0,
  freqvars=smsa
)

** Movers **;

data Ahs_2007_met_rmov;

  set Ahs2007.rmov;
  
run;

proc datasets library=work memtype=(data) nolist;
  modify Ahs_2007_met_rmov;
    format smsa $smsa. &fmt_stmt_rmov;
quit;

%Finalize_data_set( 
  /** Finalize data set parameters **/
  data=Ahs_2007_met_rmov,
  out=Ahs_2007_met_rmov,
  outlib=AHS,
  label="American Housing Survey, 2007, metropolitan area, recent movers",
  sortby=smsa control rmov,
  /** Metadata parameters **/
  revisions=%str(New file.),
  /** File info parameters **/
  printobs=0,
  freqvars=smsa
)

** Home improvements **;

data Ahs_2007_met_himp;

  set Ahs2007.homimp;
  
run;

proc datasets library=work memtype=(data) nolist;
  modify Ahs_2007_met_himp;
    format smsa $smsa. &fmt_stmt_himp;
quit;

%Finalize_data_set( 
  /** Finalize data set parameters **/
  data=Ahs_2007_met_himp,
  out=Ahs_2007_met_himp,
  outlib=AHS,
  label="American Housing Survey, 2007, metropolitan area, home improvements",
  sortby=smsa control,
  /** Metadata parameters **/
  revisions=%str(New file.),
  /** File info parameters **/
  printobs=0,
  freqvars=smsa
)

