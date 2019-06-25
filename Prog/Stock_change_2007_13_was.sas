/**************************************************************************
 Program:  Stock_change_2007_13_was.sas
 Library:  AHS
 Project:  Urban-Greater DC
 Author:   P. Tatian
 Created:  06/25/19
 Version:  SAS 9.4
 Environment:  Local Windows session (desktop)
 GitHub issue:  3
 
 Description:  Analyze housing stock changes, 2007 to 2013,
 Washington region.

 Modifications:
**************************************************************************/

%include "L:\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( AHS )

data Stock_change_2007_13_was;

  merge
    Ahs.Ahs_2007_met_hu 
      (keep=smsa control istatus huhis reuad samedu samehh samehh2 metro
       rename=(istatus=istatus07 huhis=huhis07 reuad=reuad07 samedu=samedu07 samehh=samehh07 samehh2=samehh207 metro=metro07)
       where=(smsa='8840')
       in=_in2007)
    Ahs.Ahs_2013_met_hu 
      (keep=smsa controlm istatus huhis newc reuad samedu samehh samehh2 metro
       rename=(controlm=control istatus=istatus13 huhis=huhis13 reuad=reuad13 samedu=samedu13 samehh=samehh13 samehh2=samehh213 metro=metro13)
       where=(smsa='8840')
       in=_in2013);
  by smsa control;
  
  in2007 = _in2007;
  in2013 = _in2013;
  
  if _in2007 and _in2013 then do;
  
    if samedu13 = '1' then Stock_chg = 1;
    else if huhis13 in ( '2', '3', '5' ) then Stock_chg = 2;
    else if samedu13 = '2' then Stock_chg = 3;
    
  end;
  else if _in2013 then do;
  
    if reuad13 in ( '3', '4', '9' ) then Stock_chg = 4;
    else Stock_chg = 5;
    
  end;
  else do;
  
    if huhis07 = 'B' then Stock_chg = 6;
    
  end;
       
run;

proc freq data=Stock_change_2007_13_was;
  tables in2007 * in2013 / list missing;
  tables Stock_chg / missing; 
  tables istatus: huhis: newc reuad: samedu: samehh: metro: / missing;
  format metro: $metro.;
run;
