libname in "C:\Users\ngkha\Desktop\M1\sas";
proc import out=in.q_tobac
datafile="C:\Users\ngkha\Desktop\M1\sas\DTOBRA3A086NBEA.xls"
dbms=xls;
run;
proc import out=in.q_alco
datafile="C:\Users\ngkha\Desktop\M1\sas\DAOPRA3A086NBEA.xls"
dbms=xls;
run;
proc import out=in.q_recrea
datafile="C:\Users\ngkha\Desktop\M1\sas\DREIRA3A086NBEA.xls"
dbms=xls;
run;
proc import out=in.p_tobac
datafile="C:\Users\ngkha\Desktop\M1\sas\CUSR0000SEGA.xls"
dbms=xls;
run;
proc import out=in.p_alco
datafile="C:\Users\ngkha\Desktop\M1\sas\CUSR0000SAF116.xls"
dbms=xls;
run;
proc import out=in.p_recrea
datafile="C:\Users\ngkha\Desktop\M1\sas\DREIRG3A086NBEA.xls"
dbms=xls;
run;
data p_tobac; set in.p_tobac;
if Month(observation_date) > 01  then delete;
if Year(observation_date) < 1986 | Year(observation_date) > 2019 then delete;
rename  CUSR0000SEGA = p_tobac;
LABEL CUSR0000SEGA = "p_tobac";
run;
data p_alco; set in.p_alco;
if Month(observation_date) > 01 then delete;
if Year(observation_date) < 1986 | Year(observation_date) > 2019 then delete;
rename CUSR0000SAF116  = p_alco;
LABEL CUSR0000SAF116 = "p_alco";
run;
data p_recrea; set in.p_recrea;
if Month(observation_date) > 01  then delete;
if Year(observation_date) < 1986 | Year(observation_date) > 2019 then delete;
rename DREIRG3A086NBEA = p_recrea;
LABEL  DREIRG3A086NBEA = "p_recrea";
run;
data q_tobac; set in.q_tobac;
if Year(observation_date) < 1986 | Year(observation_date) > 2019 then delete;
rename  DTOBRA3A086NBEA = q_tobac;
LABEL DTOBRA3A086NBEA = "q_tobac";
run;
data q_alco; set in.q_alco;
if Year(observation_date) < 1986 | Year(observation_date) > 2019 then delete;
rename  DAOPRA3A086NBEA = q_alco;
LABEL  DAOPRA3A086NBEA = "q_alco";
run;
data q_recrea; set in.q_recrea;
if Year(observation_date) < 1986 | Year(observation_date) > 2019 then delete;
rename  DREIRA3A086NBEA = q_recrea;
LABEL DREIRA3A086NBEA = "q_recrea";
run;
data in.aids; merge q_tobac q_alco q_recrea p_tobac p_alco p_recrea ;
format observation_date year4.;
run;
data aids; set in.aids;
x = p_tobac*q_tobac + p_alco*q_alco + p_recrea*q_recrea ;
w_alco = p_alco*q_alco/x;
w_tobac = p_tobac*q_tobac/x;
w_recrea = p_recrea*q_recrea/x;
run;
proc gplot data=aids;
      plot w_alco*observation_date w_tobac*observation_date w_recrea*observation_date/
           overlay cframe=ligr haxis=axis1 vaxis=axis2;
      title 'Budget Shares Plots';
      footnote1 c=blue '  *     alcoholic   '
                c=red  '  .     tobacco  '
                c=black '  *    recreational   ';
      symbol1 c=blue i=join v=star;
      symbol2 c=red  i=join v=dot;
	  symbol2 c=red  i=join v= circle;

      axis1  label=('Time') ;
      axis2  label=(angle=90 'Budget Share');
run;
quit;

/* calculating translog retail price and translog total expenditure*/
data aids; set aids;
l_tobac = log(p_tobac);
l_alco = log(p_alco);
l_recrea = log(p_recrea);
l_x = log(x);
run;
/* calculating budget share */
data aids; set aids;
t = _n_ ;
co1 = cos(1/2*3.14159*t);
si1 = sin(1/2*3.14159*t);
run;
proc model data = aids;
/* imposing homogeneity and symmetry and adding-up restrictions */
restrict a_alco + a_tobac + a_recrea = 1,
		 g_aa + g_at + g_ar = 0 ,
		 g_at + g_tt + g_tr = 0 ,
		 g_ar + g_tr + g_rr = 0 ;
		 
/* calculating translog price index*/
a0 = 0; /* restrict the constant coefficient price index to be zero */
l_p = a0 + a_alco * l_alco + a_tobac * l_tobac + a_recrea * l_recrea +
0.5 * (g_aa*l_alco*l_alco + g_at*l_alco*l_tobac + g_ar*l_alco*l_recrea + 
       g_at*l_tobac*l_alco + g_tt*l_tobac*l_tobac + g_tr*l_tobac*l_recrea +
       g_ar*l_recrea*l_alco + g_tr*l_recrea*l_tobac + g_rr*l_recrea*l_recrea);
/* share equations */
w_alco = a_alco + g_aa* l_alco + g_at* l_tobac + g_ar*l_recrea + b_alco*(l_x - l_p);
w_tobac = a_tobac + g_at* l_alco + g_tt* l_tobac + g_tr*l_recrea + b_tobac*(l_x - l_p) ; 

fit w_alco w_tobac/ sur outest=fin0
 outs = resid2  white godfrey = 4 ;
parms a_alco b_alco g_aa g_at g_ar 
      a_tobac b_tobac    g_tt g_tr 
      a_recrea                g_rr ;


run;
quit;
proc model data = aids;
/* imposing homogeneity and symmetry and adding-up restrictions */
restrict a_alco + a_tobac + a_recrea = 1,
		 g_aa + g_at + g_ar = 0 ,
		 g_at + g_tt + g_tr = 0 ,
		 g_ar + g_tr + g_rr = 0 ;
		 
/* calculating translog price index*/
a0 = 0; /* restrict the constant coefficient price index to be zero */
l_p = a0 + a_alco * l_alco + a_tobac * l_tobac + a_recrea * l_recrea +
0.5 * (g_aa*l_alco*l_alco + g_at*l_alco*l_tobac + g_ar*l_alco*l_recrea + 
       g_at*l_tobac*l_alco + g_tt*l_tobac*l_tobac + g_tr*l_tobac*l_recrea +
       g_ar*l_recrea*l_alco + g_tr*l_recrea*l_tobac + g_rr*l_recrea*l_recrea);
/* share equations */
w_alco = a_alco + g_aa* l_alco + g_at* l_tobac + g_ar*l_recrea + b_alco*(l_x - l_p);
w_tobac = a_tobac + g_at* l_alco + g_tt* l_tobac + g_tr*l_recrea + b_tobac*(l_x - l_p) ; 

fit w_alco w_tobac/ sur outest=fin0
 outs = resid2  HCCME = 3 ;
parms a_alco b_alco g_aa g_at g_ar 
      a_tobac b_tobac    g_tt g_tr 
      a_recrea                g_rr ;


run;
quit;

data fin0;
  set fin0;
  drop _name_ _type_ _status_ _nused_;
run;
/* Elasticities */
proc means data=aids noprint;
   var w_alco w_tobac w_recrea p_alco p_tobac p_recrea x ;
   output out=means mean= w_alco w_tobac w_recrea am tm rm x ;
run;
proc iml;
  use fin0;
  read all var {g_aa g_at g_ar g_tt g_tr g_rr} ;
  read all var {b_alco b_tobac a_alco a_tobac a_recrea} ;

  close fin0;

  use means;

  /* read in the mean shares */
  read all var {w_alco w_tobac w_recrea} ;
  /* read in the mean price and expenditure */
  read all var {am tm rm x } ;

  l_alco = log(am);
  l_tobac = log(tm);
  l_recrea = log(rm);
  l_x = log(x);

  close means;

  /* To calculate the elasticity matrix with own price elasticity
     as diagonal elements and cross price elasticities as off diagonal elements,
  you can express the parameters in matrix form and use matrix manipulation
  in the calculation*/

  /* Budget share vector */
  w = w_alco//w_tobac//w_recrea;

  /* gamma(i,j) matrix */
  gij = (g_aa||g_at||g_ar)//
        (g_at||g_tt||g_tr)//
        (g_ar||g_tr||g_rr);
  

  /* parameter based on sum-to-one constraint */
  b_recrea = 0 - b_alco - b_tobac ;

  a = a_alco//a_tobac//a_recrea;  /* alpha(i) vector */
  b = b_alco//b_tobac//b_recrea;  /* beta(i) vector  */


  /* calculating translog price index*/
  a0 = 0; 
  l_p = a0 + a_alco*l_alco + a_tobac*l_tobac + a_recrea*l_recrea +
  0.5 *(g_aa*l_alco*l_alco + g_at*l_alco*l_tobac + g_ar*l_alco*l_recrea + 
       g_at*l_tobac*l_alco + g_tt*l_tobac*l_tobac + g_tr*l_tobac*l_recrea +
       g_ar*l_recrea*l_alco + g_tr*l_recrea*l_tobac + g_rr*l_recrea*l_recrea);


  /* Calculate each element of the elasticity matrix */
  nk = ncol(gij);

  mi = -1#I(nk);

  ff2 = j(nk,nk,0);   /* Initialize Marshallian elasticity matrix */
  fic2 = j(nk,nk,0);  /* Initialize Hicksian elasticity matrix */
  fi2 = j(nk,1,0);    /* Income elasticity vector */


  /* prepare for plotting the elasticity matrices*/

  /* initialize index vectors for the X- and Y-axis */
  x = j(nk*nk,1,0);
  y = j(nk*nk,1,0);

  /* initialize vector to store elasticity matrices */
  Helast = j(nk*nk,1,0);
  Melast = j(nk*nk,1,0);

  i=1;
  do i=1 to nk;
     fi2[i,1] = 1 + b[i,]/w[i,];
     j=1;
     do j=1 to nk;
        ff2[i,j] = mi[i,j] + (gij[i,j] - b[i,]#(w[j,]-b[j,]#(l_x-l_p)))/w[i,];
        fic2[i,j] = ff2[i,j] + w[j,]#fi2[i,];
        x[(i-1)*nk+j,1] = i ;
  y[(i-1)*nk+j,1] = j ;
  Melast[(i-1)*nk+j,1] = ff2[i,j] ;
  Helast[(i-1)*nk+j,1] = fic2[i,j] ;
     end;
  end;

  print 'Results for Full Non-Linear AIDS Model';
   mattrib ff2 colname=({alcohol tobacco recreational}) rowname =({alcohol tobacco recreational}) label='Marshallian Elasticity Matrix' ;

 print 'Marshallian Elasticities'; print ff2;
  mattrib fi2 rowname =({alcohol tobacco recreational}) label='Income Elasticity' ;
 print 'Expenditure Elasticities'; print fi2;
  mattrib fic2 colname=({alcohol tobacco recreational}) rowname =({alcohol tobacco recreational}) label='Hicksian Elasticity Matrix' ;
 print 'Compensated Elasticities'; print fic2;

 /*create data set for plotting*/
  create plotdata var{x y Melast Helast} ;
  append;
  close plotdata;
run;
quit;



