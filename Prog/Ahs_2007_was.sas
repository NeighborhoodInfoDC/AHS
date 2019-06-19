/**************************************************************************
 Program:  Ahs_2007_was.sas
 Library:  AHS
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  03/06/09
 Version:  SAS 9.1
 Environment:  Windows
 
 Description:  Read 2007 AHS Metro file for Washington, DC, region.

 Adapted from program provided by HUD.

 Modifications:
**************************************************************************/

%include "K:\Metro\PTatian\DCData\SAS\Inc\Stdhead.sas";

** Define libraries **;
%DCData_lib( AHS )

libname rawdata xport "D:\DCData\Libraries\AHS\Raw\hud.xpt";

%LET dset = Ahs_2007_was;   * name of AHS dataset;

%let where = ( smsa = '8840' );

* Revised for 2007;

/*
* Name: METROPOLITAN In_ahs2007.sas
  Date: December 10, 2008
  This is the final program designed to convert the SAS transport
  files provided by the Census Bureau into a single SAS dataset with
  a similar structure to pre-1997 data.

  The program was developed by the Housing and Community Development Group, 
  part of ICF International, under contract with HUD.


  For questions about the SAS program, please contact:

    Katherine Nicholson
    Housing and Community Development
    ICF International
    9300 Lee Highway
    Fairfax, VA 22031
    Phone: 703-934-3619
    Fax:   703-934-3156
    Email: knicholson@icfi.com


  Questions to HUD about the AHS should be directed to one of the following:
    Dav Vandenbrouke 
    202-402-5890
    david_a._vandenbroucke@hud.gov

    Carolyn Lynch
    202-402-5910
    carolyn.lynch@hud.gov
   
    Ron Sepanik
    202-402-5887
    ronald_j._sepanik@hud.gov


Questions to Census about the AHS should be directed to either:
    Tamara Cole (email: tamara.a.cole@census.gov) or

    Joe Huesman (email: jhuesman@census.gov).

    They can both be reached by phone at: 301-763-3235.

*/


* First extract the individual files from the SAS transport file;

proc copy in=rawdata out=ahs;

* End of reading from the raw files;


* Define a macro to show the contents of each individual file,
  and set a flag.;


%macro runcim(filen);

proc contents data=ahs.&filen;
  title "&filen file";
run;

proc sort data=ahs.&filen;
  by smsa control;
run;

data ahs.&filen;
  set ahs.&filen;
  where &where;
  &filen.f=1;
run;

%mend;

* Run the macro for each individual file. In 2001 houshld, toppuf and weight were merged
into newhouse dataset;

%runcim(owner);
%runcim(homimp);
%runcim(jtw);
%runcim(mortg);
%runcim(rmov);
%runcim(person);
%runcim(newhouse);




* Set up the individual data to handle multiple observations for the
  same household;

* Multiple observations in the person file.;

data ahs.person;
  set ahs.person;
  if rel=1 or rel=2 then hhead=1;
    else hhead=0;
  movgrp=mvg;
run;


  * Lines above also prepare for other merging.;

proc sort data=ahs.person;
  by smsa control;
run;

proc means noprint data=ahs.person;
  var age;
  by smsa control;
  output out=junk n=numfam;
run;

data junk;
  set junk;
  keep smsa control numfam;
run;

data ahs.person;
  merge ahs.person junk;
  by smsa control;
run;

* Merge on JTW here;

proc sort data=ahs.person;
  by smsa control pline;
run;

data ahs.jtw;
  set ahs.jtw;
  persons=person;
  pline=person;
run;

proc sort data=ahs.jtw;
  by smsa control pline;
run;

data ahs.person;
  merge ahs.person ahs.jtw;
  by smsa control pline;
run;

* Merge in Recent Movers here;

proc sort data=ahs.person;
  by smsa control movgrp;
run;

proc sort data=ahs.rmov;
  by smsa control movgrp;
run;

data ahs.person;
  merge ahs.person ahs.rmov;
  by smsa control movgrp;
run;

proc sort data=ahs.person;
  by smsa control hhead descending pline;
run;

* Multiple observations in the Home Improvement file;

proc sort data=ahs.homimp;
  by smsa control descending ras;
run;

data ahs.homimp;
  set ahs.homimp;
  racost=rad;
  rastemp=ras+0;
run;

proc means noprint data=ahs.homimp;
  var rastemp;
  by smsa control;
  output out=junk1 n=numfam;
run;

data junk1;
  set junk1;
  keep smsa control numfam;
run;

data ahs.homimp;
  merge ahs.homimp junk1;
  by smsa control;
run;



* Define a macro to handle the change in format to be
  similar to the old style where there is a single household
  record as opposed to individual records;

%macro lagvar(newvar,origvar,arvar);
  &newvar.1=&origvar;
  &newvar.2=lag1(&origvar);
  &newvar.3=lag2(&origvar);
  &newvar.4=lag3(&origvar);
  &newvar.5=lag4(&origvar);
  &newvar.6=lag5(&origvar);
  &newvar.7=lag6(&origvar);
  &newvar.8=lag7(&origvar);
  &newvar.9=lag8(&origvar);
  &newvar.10=lag9(&origvar);
  &newvar.11=lag10(&origvar);
  &newvar.12=lag11(&origvar);
  &newvar.13=lag12(&origvar);
  &newvar.14=lag13(&origvar);
  &newvar.15=lag14(&origvar);
  &newvar.16=lag15(&origvar);
  array &arvar {*} &newvar.1 &newvar.2-&newvar.16;
  do x=1 to 16;
    if x>numfam then &arvar(x)=.;
  end;
  drop x &origvar;
%mend;

* Now set up code to do transformation to single record from
  multiple record.;

* Transform person file;

data ahs.person;
  set ahs.person;
  by smsa control hhead descending pline;

  %lagvar(age,age,tempa);
  %lagvar(grad,grad,tempb);
  %lagvar(move,move,tempc);
  movyr=move;
  %lagvar(movyr,movyr,tempd);
  %lagvar(movm,movm,tempdz);
  %lagvar(mvg,mvg,tempnd);

  %lagvar(par,par,tempe);
  %lagvar(pline,pline,tempf);
  %lagvar(rel,rel,tempg);
  %lagvar(rntdue,rntdue,temph);
  %lagvar(sal,sal,tempi);
  %lagvar(spos,spos,tempj);
  
  %lagvar(food,food,tempm);
  %lagvar(here,here,tempn);
  %lagvar(mar,mar,tempt);

  %lagvar(race,race,tempv);
  %lagvar(sex,sex,tempw);
  %lagvar(span,span,tempx);
  %lagvar(ten,ten,tempy);
  lodstat=lodsta;
  %lagvar(lodsta,lodstat,tempz);
  %lagvar(lodrnt,lodrnt,tempaa);
  %lagvar(famnum,famnum,tempfa);
  %lagvar(famrel,famrel,tempfb);
  %lagvar(famtyp,famtyp,tempfc);
  %lagvar(citshp,citshp,tempna);
  %lagvar(inusyr,inusyr,tempnb);
  %lagvar(natvty,natvty,tempnc);


  %lagvar(pqothnr,pqothnr,tempng);
  %lagvar(pqretir,pqretir,tempnh);
  %lagvar(pqsal,pqsal,tempni);
  %lagvar(pqsalnr,pqsalnr,tempnj);
  %lagvar(pqself,pqself,tempnk);
  %lagvar(pqselfnr,pqselfnr,tempnl);
  %lagvar(pqss,pqss,tempnm);
  %lagvar(pqssi,pqssi,tempnn);
  %lagvar(pqwelf,pqwelf,tempno);
  %lagvar(pqwkcmp,pqwkcmp,tempnp);
  %lagvar(pvother,pvother,tempnq);

  %lagvar(pqalim,pqalim,temppl);
  %lagvar(pqdiv,pqdiv,temppm);
  %lagvar(pqint,pqint,temppn);
  %lagvar(pqother,pqother,temppo);
  %lagvar(pqrent,pqrent,temppp);

  * Do transform for JTW portion;

  %lagvar(ampm,ampm,tempae);
  %lagvar(distj,distj,tempaf);
  %lagvar(hjob,hjob,tempag);
  %lagvar(pass,pass,tempai);
  %lagvar(timej,timej,tempaj);
  %lagvar(tran,tran,tempak);
  %lagvar(vehcl,vehcl,tempal);
  %lagvar(whdy,whdy,tempam);
  %lagvar(whhrb,whhrb,tempan);
  %lagvar(whhrw,whhrw,tempao);
  %lagvar(whome,whome,tempap);
  %lagvar(person,persons,tempaq);
  %lagvar(wtime,wtime,tempar);
  %lagvar(winus,winus,tempas);

  %lagvar(wlineq,wlineq,tempjt);
  * Line above moved from person;

  * Start of special code to transform movers;

  %lagvar(movgrp,movgrp,tempat);
  %lagvar(xcond,xcond,tempau);
  %lagvar(xcoop,xcoop,tempav);
  %lagvar(xcost,xcost,tempaw);
  %lagvar(xhead,xhead,tempax);
  %lagvar(xinus,xinus,tempay);
  %lagvar(xper,xper,tempaz);
  %lagvar(xrel,xrel,tempba);
  %lagvar(xten,xten,tempbb);
  %lagvar(xunit,xunit,tempbc);


  %lagvar(jdistj,jdistj,tempnr);
  %lagvar(jpass,jpass,tempns);
  %lagvar(jtimej,jtimej,tempnt);
  %lagvar(jtran,jtran,tempnu);
  %lagvar(jvehcl,jvehcl,tempnv);
  %lagvar(jwhdy,jwhdy,tempnw);
  %lagvar(jwhhrb,jwhhrb,tempnx);
  %lagvar(jwhhrw,jwhhrw,tempny);
  %lagvar(jwtime,jwtime,tempnz);

  %lagvar(rmov,rmov,tempoa);

  %lagvar(jovgrp,jovgrp,tempob);
  %lagvar(jxhead,jxhead,tempoc);
  %lagvar(jxper,jxper,tempod);
  %lagvar(jxten,jxten,tempoe);
  %lagvar(jxunit,jxunit,tempof);

  %lagvar(jage,jage,tempog);
  %lagvar(jatvty,jatvty,tempoh);
  %lagvar(jgrad,jgrad,tempoi);
  %lagvar(jhere,jhere,tempoj);
  %lagvar(jitshp,jitshp,tempok);
  %lagvar(jmar,jmar,tempol);
  %lagvar(jmove,jmove,tempom);
  %lagvar(jmovm,jmovm,tempon);
  %lagvar(jmvg,jmvg,tempoo);
  %lagvar(jnusyr,jnusyr,tempop);
  %lagvar(jpar,jpar,tempoq);

  %lagvar(jpqothnr,jpqothnr,tempot);
  %lagvar(jpqretir,jpqretir,tempou);
  %lagvar(jpqsal,jpqsal,tempov);
  %lagvar(jpqsalnr,jpqsalnr,tempox);
  %lagvar(jpqself,jpqself,tempoy);
  %lagvar(jpqslfnr,jpqslfnr,tempoz);
  %lagvar(jpqss,jpqss,temppa);
  %lagvar(jpqssi,jpqssi,temppb);
  %lagvar(jpqwelf,jpqwelf,temppc);
  %lagvar(jpqwkcmp,jpqwkcmp,temppd);

  %lagvar(jrace,jrace,temppf);
  %lagvar(jrel,jrel,temppg);
  %lagvar(jsal,jsal,tempph);
  %lagvar(jsex,jsex,temppi);
  %lagvar(jspan,jspan,temppj);
  %lagvar(jspos,jspos,temppk);


  if last.control=1 then output;
  drop hhead;
run;


* Transform home improvement file;

data ahs.homimp;
  set ahs.homimp;
  by smsa control descending ras;

  %lagvar(racost,racost,tempaa);
  %lagvar(rah,rah,tempab);
  %lagvar(ras,ras,tempac);

  %lagvar(jras,jras,tempng);


  if last.control=1 then output;
run;

* Merge all files together;

data ahs.&dset;
  merge ahs.owner ahs.homimp ahs.mortg
        ahs.person ahs.newhouse;
  by smsa control;
  drop ownerf homimpf jtwf mortgf rmovf personf newhousef  
	rastemp numfam;

run;

proc datasets ddname=ahs;
  delete owner homimp jtw mortg person rmov newhouse ;
run;


%MACRO SKIP;

* Code to switch to upper case is thanks to Dav Vandenbroucke;

FILENAME OutFile1 "&dirname.\ReName.txt" LRECL=32767;

/* write content listing to a dataset */
PROC CONTENTS DATA=ahs.&dset. OUT=Content NOPRINT;
RUN;

/* write format statements to text file */

DATA _NULL_ ;  
     FILE OutFile1;
     SET Content;
     UName = UPCASE(Name);
     IF UName ^= Name THEN
          PUT 'RENAME ' Name $ '=' UName +(-1) '; ' ;
RUN;

/* Assign the formats to the AHS dataset */

PROC DATASETS DDNAME=ahs ;
     MODIFY &dset ;
     %INCLUDE OutFile1; /* inserts rename statements created in previous step */
RUN;

* End of code to change variable names;

%MEND SKIP;


%file_info( data=ahs.&dset, freqvars=smsa, printobs=0 )

/*
PROC CONTENTS DATA=ahs.ahs2007M;
	title "Contents of AHS 2007 Metropolitan File";
run;
*/


run;
