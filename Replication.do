******************************************************************************
* Paper: Arrival of Young Talent: The Send-down Movement and Rural Education *
* 		 in China (Yi Chen, Ziyin Fan, Xiaomin Gu, and Li-An Zhou) 			 *
*   																	     *
* Date: 2021 Jan 12													         *
*																			 *
* Warning: 64bit Stata is required. If everything runs propoerly, this code  * 
* 		   should finish in about 45min. If error reports "op. sys. refuses  *
* 		   to provide memory", please allocate more RAM, or use 64bit ver.	 *
******************************************************************************

******************************************************************************
*																			 *
* 			Do-file #1: Replication, a Minor Extension and Analysis 		 *
* 																			 *
* This do-file carries out the anlysis in Section 3 of my report. I leanred  * 
* a lot from the authors' do-file, but most codes and all annotations 		 *
* have been written by me. This file is written with rich comments			 *
*																			 * 
* Input data:	census_1990_clean.dta  census_2000_clean.dta  (for Table 3)	 * 
* 				census_1990_clean.dta  census_2000_clean.dta				 * 
* 				census_2010_clean.dta	   					 (for Figure 3)	 * 
* 																			 * 
* Output files: myrepTable3.tex (in my report, it is Table 1)				 *
*  				myFigure3.txt 											 	 *
*				myFigure3.pdf/eps (in my report is it Figure 1)				 *
*                                                                              *
******************************************************************************

**********************************************
*Preparation:                                *
*Set paths and install pacakges 			 *
**********************************************

ssc install outreg2, replace
ssc install estout, replace
ssc install outsum, replace
ssc install firstdigit, replace
ssc install unique, replace
ssc install ftools, replace
ssc install reghdfe, replace
ssc install sxpose, replace
net install synth, from("https://web.stanford.edu/~jhain/Synth") replace
net install parallel, from("https://raw.github.com/gvegayon/parallel/stable/") replace
net install synth_runner, from("https://raw.github.com/bquistorff/synth_runner/master/") replace

clear all
set more off, permanent
set matsize 10000

global path_in  "E:\SDY_replication\SourceData"
* Give the path: the folder containing the source data for main analysis. 

global path_work "E:\SDY_replication\WorkData"
* Give the path: working data folder for temporarily storing the data. It should be empty at the beginning.

global path_out   "E:\SDY_replication\Output"
* Give the path: the folder that stores the outputs. It should be empty at the beginning.


********************************************************************************
*                                                                              *
*                    Step 1: Figure 3 Replication			                   *
*                                                                              *
* Figure 3 (in the original paper) is crucial for the identifying assumption of*
* the cohort-DID model. We need to conduct a bo-cohort DID model and check that*
* coefficients for treatment prior to 1956 should be zero.					   *
*                                                                              *
********************************************************************************

************************
* Define Fixed Effects *
************************

global var_abs_older "region1990 prov#year_birth c.primary_base_older#year_birth c.junior_base_older#year_birth"
global var_abs_older82 "region1982 prov#year_birth c.primary_base_older#year_birth c.junior_base_older#year_birth"
global var_abs_older00 "region2000 prov#year_birth c.primary_base_older#year_birth c.junior_base_older#year_birth"

* The var_abs defined here is for the FE's of the by-cohort DID model. In specific, the paper adopts a high dimensional FE model (reghdfe) which needs to clarify what level of FE we want STATA to absorb:

* region1990: this is the county FE (\lambda_c in the paper)
* prov#year_birth: this is space-time cross term, which allowa slope of time trends to be different for each county (\mu_{p,g} in th paper)
* primary_base_older#year_birth：this is a cross term between county's characteristics and time, which allows the FE to be dependent on each county's education level (\Lambda_c*\mu_g)
* junior_base_older#year_birth: same as above, but with a different measure of county's education level: the above uses proportional of people who graduated from primary school, this ones uses that of junior high school (\Lambda_c*\mu_g)

* Some FE that normally should be countrolled but not here: 

* prov: this is the province level FE; however province is a larger geographic term than county, so it is neglected after countrolling region1990
* year_birth: in principle we can control for time only (county-invariant) FE. After trying myself, the coefficients for time only FE is 0 (or near 0). This could be because the time FE has been covered by multiple cross-terms controlled above which invovles time.


*****************************************
*Panel B: Census 1990					*
*****************************************

use "$path_in\census_1990_clean.dta", clear
keep if rural==1
drop rural 

forvalues y = 1946/1969 {
	gen I`y' = sdy_density*[year_birth==`y']
	* generate group dummies for by-cohort DID
}

reghdfe yedu I1946-I1969 male han_ethn, absorb($var_abs_older) cluster(region1990)
* This paper adopts high-dimensional FE model, which efficiently absorbs mutiple level of FE and thie cross terms. It takes some time to run the regression

outreg2 using "$path_out\myFigure3.txt", replace sideway noparen se nonotes nocons noaster nolabel text keep(I1946-I1969) sortvar(I1946-I1969)
* The above two lines should take appx 5min

drop I1946-I1969


****************************************
*Panel A: Census 1982	               *
****************************************

use "$path_in\census_1982_clean.dta", clear
keep if rural==1
drop rural 

forvalues y = 1946/1962 {
	gen I`y' = sdy_density*[year_birth==`y']
}

reghdfe yedu I1946-I1962 male han_ethn, absorb($var_abs_older82) cluster(region1982)
outreg2 using "$path_out\myFigure3.txt", append sideway noparen se nonotes nocons noaster nolabel text keep(I1946-I1962) sortvar(I1946-I1962)
* The above two lines should take appx 4min

drop I1946-I1962


*****************************************
*Panel C: Census 2000                   *
*****************************************

use "$path_in\census_2000_clean.dta", clear
keep if rural==1
drop rural 

forvalues y = 1946/1979 {
	gen I`y' = sdy_density*[year_birth==`y']
}

reghdfe yedu I1946-I1979 male han_ethn, absorb($var_abs_older00) cluster(region2000)

outreg2 using "$path_out\myFigure3.txt", append sideway noparen se nonotes nocons noaster nolabel text keep(I1946-I1979) sortvar(I1946-I1979)
* The above two lines should take appx 6min

drop I1946-I1979


******************************************
* Merge Panel D and Draw whole Figure 3  *
******************************************

insheet using "$path_out\myFigure3.txt", clear
keep if inrange(_n,5,38)
* we import pure data
gen year = substr(v1,2,4)
* basically year = 1990, 2000, 1982

rename (v2 v3 v4 v5 v6 v7)(coef1990 se1990 coef1982 se1982 coef2000 se2000)
destring, force replace
keep year coef* se*
reshape long coef se, i(year) j(data)
drop if coef == .
* Form a table-type, two-way dataset

gen lb = coef - 1.96*se
gen ub = coef + 1.96*se
gen y_overlap = min(max(year-1955,0),max(1970-year,0),6)
sort data year
* Preparation for the coefficient line together with the CI
* Each dot on the figure will represent an estimation of that year's coefficient

twoway line lb year if data==1982, sort lpattern(dash) lcolor(gs8) yaxis(1) ///
|| line ub year if data==1982, sort lpattern(dash) lcolor(gs8) ///
|| line coef year if data==1982, lwidth(thick) lcolor(black)  yaxis(1) ///
|| line y_overlap year if data==1982, sort lpattern(dash_dot) lwidth(thick) lcolor(gs8) yaxis(2) ///
||, graphregion(fcolor(gs16) lcolor(gs16)) plotregion(lcolor(gs16) margin(zero)) ///
     ylabel(-4(2)8, labsize(small) angle(0) format(%12.0f) axis(1)) ytitle("Coefficients", size(small) axis(1)) ///
     ylabel(0(2)6, labsize(small) angle(0) format(%12.0f) axis(2)) ytick(-6 0(1)6 12,axis(2)) ytitle("Years of Overlap", size(small) axis(2)) ///
	 xlabel(1945(5)1980, labsize(small)) xtick(1945(5)1980) xtitle("Birth Cohort", size(small)) ///
	 xline(1955 1970, lpattern(solid) lwidth(thin) lcolor(black)) ///
	 title("Panel A - Census 1982", size(small) margin(small)) ///
	 yline(0, lpattern(solid) lwidth(thin) lcolor(black)) legend(off) fxsize(70) fysize(60)
graph save a,replace 
* some graphical features, e.g., fxsize is the size of x axis, fysize is that of y axis 

twoway line lb year if data==1990, lpattern(dash) lcolor(gs8) yaxis(1) ///
|| line ub year if data==1990, lpattern(dash) lcolor(gs8) ///
|| line coef year if data==1990, lwidth(thick) lcolor(black) yaxis(1) ///
|| line y_overlap year if data==1990, lpattern(dash_dot) lwidth(thick) lcolor(gs8) yaxis(2) ///
||, graphregion(fcolor(gs16) lcolor(gs16)) plotregion(lcolor(gs16) margin(zero)) ///
     ylabel(-4(2)8, labsize(small) angle(0) format(%12.0f) axis(1)) ytitle("Coefficients", size(small) axis(1)) ///
     ylabel(0(2)6, labsize(small) angle(0) format(%12.0f) axis(2)) ytick(-6 0(1)6 12,axis(2)) ytitle("Years of Overlap", size(small) axis(2)) ///
	 xlabel(1945(5)1980, labsize(small)) xtick(1945(5)1980) xtitle("Birth Cohort", size(small)) ///
	 xline(1955 1970, lpattern(solid) lwidth(thin) lcolor(black)) ///
	 title("Panel B - Census 1990", size(small) margin(small)) ///
	 yline(0, lpattern(solid) lwidth(thin) lcolor(black)) legend(off) fxsize(70) fysize(60)
graph save b,replace 

twoway line lb year if data==2000, lpattern(dash) lcolor(gs8) yaxis(1) ///
|| line ub year if data==2000, lpattern(dash) lcolor(gs8) ///
|| line coef year if data==2000, lwidth(thick) lcolor(black) yaxis(1) ///
|| line y_overlap year if data==2000, lpattern(dash_dot) lwidth(thick) lcolor(gs8) yaxis(2) ///
||, graphregion(fcolor(gs16) lcolor(gs16)) plotregion(lcolor(gs16) margin(zero)) ///
     ylabel(-3(1)6, labsize(small) angle(0) format(%12.0f) axis(1)) ytitle("Coefficients", size(small) axis(1)) ///
     ylabel(0(2)6, labsize(small) angle(0) format(%12.0f) axis(2)) ytick(-6 0(1)6 12,axis(2)) ytitle("Years of Overlap", size(small) axis(2)) ///
	 xlabel(1945(5)1980, labsize(small)) xtick(1945(5)1980) xtitle("Birth Cohort", size(small)) ///
	 legend(order(3 1 4)label(3 "Coefficient") label(1 "95% CI") label(4 "Overlapped Years in""Primary Schools") col(2) size(small) margin(tiny)) ///
	 xline(1955 1970, lpattern(solid) lwidth(thin) lcolor(black)) ///
	 title("Panel C - Census 2000", size(small) margin(small)) ///
	 yline(0, lpattern(solid) lwidth(thin) lcolor(black)) fxsize(65) fysize(80)
graph save c,replace 


twoway || connected coef year if data==1982, lwidth(medthick) msymbol(triangle) color(black) ///
|| line coef year if data==1990, lwidth(medthick) color(gs6) ///
|| connected coef year if data==2000, lwidth(medthick) msymbol(square) color(gs12) ///
||, graphregion(fcolor(gs16) lcolor(gs16)) plotregion(lcolor(gs16) margin(zero)) ///
     ylabel(-2(1)5, labsize(small) angle(0) format(%12.0f)) ytitle("Coefficients", size(small)) ///
	 xlabel(1945(5)1980, labsize(small)) xtick(1945(5)1980) xtitle("Birth Cohort", size(small)) ///
	 legend(label(1 "Census 1982") label(2 "Census 1990") label(3 "Census 2000") col(2) size(small)) ///
	 xline(1955 1970, lpattern(solid) lwidth(thin) lcolor(black)) ///
	 title("Panel D - Three Censuses in One Graph", size(small) margin(small)) ///
	 yline(0, lpattern(solid) lwidth(thin) lcolor(black)) fxsize(70) fysize(80)
graph save d,replace 
* This is a merging for graph 4, which two-ways only the coefficient lines not the CI's

graph combine a.gph b.gph c.gph d.gph, graphregion(fcolor(gs16) lcolor(gs16))
graph export "$path_out\myFigure3.pdf",replace
*or "$path_out\myExtension.eps"

erase a.gph
erase b.gph
erase c.gph
erase d.gph
erase "$path_out\myFigure3.pdf"
*or "$path_out\myExtension.eps"

* Now please open "$path_out\myFigure3.pdf" for the whole Figure3. It is appended in my report as Figure 1


********************************************************************************
*                                                                              *
*               Step 2: Table 3 Replication (Table 1 in my report)             *
*                                                                              *
* Table 3 perfomrs a cohort-DID. With the parellel assumption checked by work  *
* above, we know estimate the average treatment effect on the whole treatment  *
* group. 																	   *
*                                                                              *
* Control:  1946-1955														   *
* Treat	 :  1956-1969														   *
*                                                                              *
********************************************************************************

use "$path_in\census_1990_clean.dta", clear
gen treat = inrange(year_birth,1956,1969) if inrange(year_birth,1946,1969)

************************
* Define Fixed Effects *
************************

global var_abs "region1990 prov#year_birth c.primary_base#year_birth c.junior_base#year_birth"
* the difference between primary_base and primary_base_older is the _older includes data from 1945-1955.

* The var_abs defined here is for the FE's of the cohort DID model. In specific, the paper adopts a high dimensional FE model (reghdfe) which needs to clarify what level of FE we want STATA to absorb:

* region1990: this is the county FE (\lambda_c in the paper)
* prov#year_birth: this is space-time cross term, which allowa slope of time trends to be different for each county (\mu_{p,g} in th paper)
* primary_base#year_birth：this is a cross term between county's characteristics and time, which allows the FE to be dependent on each county's education level (\Lambda_c*\mu_g)
* junior_base#year_birth: same as above, but with a different measure of county's education level: the above uses proportional of people who graduated from primary school, this ones uses that of junior high school (\Lambda_c*\mu_g)

* Some FE that normally should be countrolled but not here: 

* prov: this is the province level FE; however province is a larger geographic term than county, so it is neglected after countrolling region1990
* year_birth: in principle we can control for time only (county-invariant) FE. After trying myself, the coefficients for time only FE is 0 (or near 0). This could be because the time FE has been covered by multiple cross-terms controlled above which invovles time.


*****************************************************************************
*Table 3: The Effect of SDYs on the Educational Attainment of Rural Children*
*Columns (1)--(7)                                                           *
*****************************************************************************

foreach var in yedu primary_graduate junior_graduate {
* Three dependent varaibles, different measure of education outcome
	forvalues i = 1/2 {
	* rural/urban sample

		if (`i'==1) reghdfe `var' c.sdy_density#c.treat male han_ethn local_1985 if rural==1, absorb($var_abs) cluster(region1990)
		if (`i'==2) reghdfe `var' c.sdy_density#c.treat male han_ethn local_1985 if rural==0, absorb($var_abs) cluster(region1990)
		* c. for continuous, # for cross term
		* cluster(clustervars) estimates consistent standard errors (robust se) even when the observations are correlated within groups.
		
		* I controlled 1 more individual attribute: local_1985 

		summ `var' if e(sample)&treat==0
		* e(sample) shows whether this observation is included in the regression
		local mean = r(mean)
		* this is to add the last roll: mean of control group
		
		if (("`var'"=="yedu")&(`i'==1)) outreg2 using "$path_out\myrepTable3.tex", replace se nocons nonotes nolabel tex addstat(Mean,`mean') keep(c.sdy_density#c.treat male han_ethn local_1985 ) sortvar(c.sdy_density#c.treat male han_ethn local_1985 ) title("The Effect of SDYs on the Educational Attainment of Rural Children") ctitle("rural") addnote("Notes: Robust standard errors are clustered at county level; *\(p<0.05\), ** \(p<0.01\), *** \(p<0.001\)") 
		
		if (("`var'"!="yedu")&(`i'==1)) outreg2 using "$path_out\myrepTable3.tex", append  se nonotes nocons nolabel tex addstat(Mean,`mean') keep(c.sdy_density#c.treat male han_ethn local_1985 ) sortvar(c.sdy_density#c.treat male han_ethn local_1985 ) ctitle("rural")
		
		if (`i'!=1) outreg2 using "$path_out\myrepTable3.tex", append  se nonotes nocons nolabel tex addstat(Mean,`mean') keep(c.sdy_density#c.treat male han_ethn local_1985 ) sortvar(c.sdy_density#c.treat male han_ethn local_1985 ) ctitle("urban")
		* thie is in the sequnce of the table		
	}
}

******************************************************************************
* 							!Notice!                                  	     *
* I controlled one more individual attribute: local_1985. This is for a minor*
* extension to make our comparison with the original table more maningful.   *
*                                                                            *
* Meanwhile, as I mentioned during the presentation, the original result only*
* controls for gender and ehnicity, indeed due to inconsistent record of     *
* other personal attributes across censuses. We just include 1 more to see if*
* controlling more personal attribute will change the main results			 *
*                                                                            *
* local_1985: whether the individual is a local resident of county in 1985   *
*                                                                            *
* Conclusion in short: the main coefficients are not impacted too much		 *
******************************************************************************

keep if rural==1
drop rural
gen treat_placebo = inrange(year_birth,1951,1955) if inrange(year_birth,1946,1955)
* this is for column (7), in which we assumed a 'placebo' treatment from 1951-1955

reghdfe yedu c.sdy_density#c.treat_placebo male han_ethn local_1985, absorb($var_abs) cluster(region1990)

outreg2 using "$path_out\myrepTable3.tex", append se nonotes nocons nolabel tex keep(c.sdy_density#c.treat c.sdy_density#c.treat_placebo male han_ethn local_1985 ) sortvar(c.sdy_density#c.treat c.sdy_density#c.treat_placebo male han_ethn local_1985 ) ctitle("(1946-1950) versus (1951-1955)")

drop treat_placebo


*****************************************************************************
*Table 3: The Effect of SDYs on the Educational Attainment of Rural Children*
*Columns (8)                                                                *
*****************************************************************************

global var_abs2000  "region2000 prov#year_birth c.primary_base#year_birth c.junior_base#year_birth"
* Similar to our explanation above, this is the multi-dimensional FE to be absorbed by the reghdfe

use "$path_in\census_2000_clean.dta", clear
gen treat_placebo = inrange(year_birth,1975,1979) if inrange(year_birth,1970,1979)
* this is for column (7), in which we assumed a 'placebo' treatment from 1975-1979

reghdfe yedu c.sdy_density#c.treat_placebo male han_ethn, absorb($var_abs2000) cluster(region2000)

outreg2 using "$path_out\myrepTable3.tex", append se nonotes nocons nolabel tex keep(c.sdy_density#c.treat c.sdy_density#c.treat_placebo male han_ethn) sortvar(c.sdy_density#c.treat c.sdy_density#c.treat_placebo male han_ethn) ctitle("(1970-1974) versus (1975-1979)")

drop treat_placebo

* Now please open "$path_out\myrepTable3.tex" for the whole table3. It is appended in my report as Table 1

