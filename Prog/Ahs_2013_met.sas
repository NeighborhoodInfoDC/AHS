/**************************************************************************
 Program:  Ahs_2013_met.sas
 Library:  AHS
 Project:  Urban-Greater DC
 Author:   P. Tatian
 Created:  06/19/19
 Version:  SAS 9.4
 Environment:  Local Windows session (desktop)
 GitHub issue:  1
 
 Description:  Create 2013 AHS metro area data sets.

 Modifications:
**************************************************************************/

%include "L:\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( AHS )

%let revisions = New file.;

** Library reference for HUD-provided data sets **;
libname ahs2013 "L:\Libraries\AHS\Raw\2013-met";

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
  where table in ( "NEWHOUSE", "MORTG", "OWNER", "RATIOV", "TOPICAL", "REPWGT" );

  select distinct cat( trim(name), ' ', trim(sfmtname), '.' ) into :fmt_stmt_per separated by ' ' from temp
  where table in ( "PERSON", "JTW" );

  select distinct cat( trim(name), ' ', trim(sfmtname), '.' ) into :fmt_stmt_rmov separated by ' ' from temp
  where table in ( "RMOV" );

  select distinct cat( trim(name), ' ', trim(sfmtname), '.' ) into :fmt_stmt_omov separated by ' ' from temp
  where table in ( "OMOV" );

  select distinct cat( trim(name), ' ', trim(sfmtname), '.' ) into :fmt_stmt_himp separated by ' ' from temp
  where table in ( "HOMIMP" );

quit;

run;

** Control_to_smsa format **;

%Data_to_format(
  FmtLib=work,
  FmtName=$control_to_smsa,
  Data=ahs2013.newhouse (drop=type),
  Value=control,
  Label=smsa,
  OtherLabel="",
  Print=N,
  Contents=N
  )

** Housing unit data **;

proc sort data=ahs2013.newhouse out=newhouse;
  by control;
run;

proc sort data=ahs2013.mortg out=mortg;
  by control;
run;

proc sort data=ahs2013.owner out=owner;
  by control;
run;

proc sort data=ahs2013.owner out=ratiov;
  by control;
run;

proc sort data=ahs2013.owner out=topical;
  by control;
run;

proc sort data=ahs2013.owner out=repwgt;
  by control;
run;

data Ahs_2013_met_hu;

  merge newhouse mortg owner ratiov topical repwgt;
  by control;
  
run;

proc datasets library=work memtype=(data) nolist;
  modify Ahs_2013_met_hu;
    format &fmt_stmt_hu;
quit;

%Finalize_data_set( 
  /** Finalize data set parameters **/
  data=Ahs_2013_met_hu,
  out=Ahs_2013_met_hu,
  outlib=AHS,
  label="American Housing Survey, 2013, metropolitan area, housing units",
  sortby=smsa control,
  /** Metadata parameters **/
  revisions=%str(&revisions),
  /** File info parameters **/
  printobs=0,
  freqvars=smsa
)

** Person data **;

data Ahs_2013_met_per;

  set ahs2013.person;
  
  length SMSA $ 4;
  
  smsa = put( control, $control_to_smsa. );
  
  label smsa = "1980 design PMSA code";
  
run;

proc datasets library=work memtype=(data) nolist;
  modify Ahs_2013_met_per;
    format smsa $smsa. &fmt_stmt_per;
quit;

%Finalize_data_set( 
  /** Finalize data set parameters **/
  data=Ahs_2013_met_per,
  out=Ahs_2013_met_per,
  outlib=AHS,
  label="American Housing Survey, 2013, metropolitan area, persons",
  sortby=smsa control person,
  /** Metadata parameters **/
  revisions=%str(&revisions),
  /** File info parameters **/
  printobs=0,
  freqvars=smsa
)

** Movers **;

data Ahs_2013_met_rmov;

  set Ahs2013.rmov;
  
  length SMSA $ 4;
  
  smsa = put( control, $control_to_smsa. );
  
  label smsa = "1980 design PMSA code";
  
run;

proc datasets library=work memtype=(data) nolist;
  modify Ahs_2013_met_rmov;
    format smsa $smsa. &fmt_stmt_rmov;
quit;

%Finalize_data_set( 
  /** Finalize data set parameters **/
  data=Ahs_2013_met_rmov,
  out=Ahs_2013_met_rmov,
  outlib=AHS,
  label="American Housing Survey, 2013, metropolitan area, recent movers",
  sortby=smsa control mvg,
  /** Metadata parameters **/
  revisions=%str(&revisions),
  /** File info parameters **/
  printobs=5,
  freqvars=smsa
)

** Out movers **;

data Ahs_2013_met_omov;

  set Ahs2013.omov;
  
  length SMSA $ 4;
  
  smsa = put( control, $control_to_smsa. );
  
  label smsa = "1980 design PMSA code";
  
run;

proc datasets library=work memtype=(data) nolist;
  modify Ahs_2013_met_omov;
    format smsa $smsa. &fmt_stmt_omov;
quit;

%Finalize_data_set( 
  /** Finalize data set parameters **/
  data=Ahs_2013_met_omov,
  out=Ahs_2013_met_omov,
  outlib=AHS,
  label="American Housing Survey, 2013, metropolitan area, out movers",
  sortby=smsa control dbugroup,
  /** Metadata parameters **/
  revisions=%str(&revisions),
  /** File info parameters **/
  printobs=5,
  freqvars=smsa
)

** Home improvements **;

data Ahs_2013_met_himp;

  set Ahs2013.homimp;
  
  length SMSA $ 4;
  
  smsa = put( control, $control_to_smsa. );
  
  label smsa = "1980 design PMSA code";
  
run;

proc datasets library=work memtype=(data) nolist;
  modify Ahs_2013_met_himp;
    format smsa $smsa. &fmt_stmt_himp;
quit;

%Finalize_data_set( 
  /** Finalize data set parameters **/
  data=Ahs_2013_met_himp,
  out=Ahs_2013_met_himp,
  outlib=AHS,
  label="American Housing Survey, 2013, metropolitan area, home improvements",
  sortby=smsa control,
  /** Metadata parameters **/
  revisions=%str(&revisions),
  /** File info parameters **/
  printobs=10,
  freqvars=smsa
)

