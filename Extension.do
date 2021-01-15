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
* 							Do-file #2: Extension							 *
*																			 *
* This do-file carries out extension in Sectoin 4. Codes and annotations in  * 
* this file are my orginal work. This file is written with rich comments	 *
* 																			 *
* Input data:	census_2000_clean.dta  										 *
* 																			 * 
* Output files: myExtension.pdf/eps (in my report it is Figure 1)			 *
*																			 *
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
net install sg100.pkg, from ("http://www.stata.com/stb/stb47") replace 
*This is the linest package, which is not required for the replication do-file

clear all
set more off, permanent
set matsize 10000

global path_in  "E:\SDY_replication\SourceData"
* Give the path: the folder containing the source data for main analysis. 

global path_out   "E:\SDY_replication\Output"
* Give the path: the folder that stores the outputs. It should be empty at the beginning.


********************************************************************************
*                                                                              *
*                    Step 1: Extenstion to text file                 *
*                                                                              *
********************************************************************************

*********************
*Control:1946-1955	*
*Treat:  1956-1969	*
*Data: 	Census 2000	*
*********************

use "$path_in\census_2000_clean.dta", clear

forvalues y = 1946/1979 {
	gen I`y' = sdy_density*[year_birth==`y']
	* generate group dummies for by-cohort DID
	
	if ((`y'>=1958) & (`y'<=1961)) {
	constraint def `y' (`y'-1956)*(I1956-I1957)=I1956-I`y'
	* generate the constraints we need later for increaseing partial exposure groups
	}
	else if ((`y'>=1962) & (`y'<=1963)){
	constraint def `y' I1961=I`y'
	* generate the constraints for full exposure groups
	}
	else if ((`y'>=1965) & (`y'<=1969)){
	constraint def `y' (`y'-1963)*(I1963-I1964)=I1963-I`y'
	* generate the constraints for decreasing partial exposure groups
	}
}

qui areg yedu I1946-I1979 male han_ethn i.year_birth#i.prov, absorb (region2000) cluster(region2000)
* This is to run the by-cohort DID with FE on county, time and time-county cross term
* As the original dataset is large (3million), this will take quite some time
est table, stat(r2 N) keep (I1946-I1979) b se style(columns)
* the two lines above take appx 8 min

qui linest, c(1958-1969) modify
* This is to impose our partial exposure constraints
* Stata does not have a standard function to combine high dimension FE (reghdfe) and constraint regression (csnreg). Instead, the best method is to use linest as a second stage regression. For more detail please refer to "http://www.stata.com/stb/stb47"
est table, stat(r2 N) keep (I1946-I1979) b se style(columns)
* this takes appx 3 min

outreg2 using "$path_out\myExtension.txt", replace sideway noparen se nonotes nocons noaster nolabel text keep(I1946-I1979) sortvar(I1946-I1979)
* this takes 35 min. I have not managed to find the root of abnormal time, but it could be because linest pakages' output is different from standard areg (or reghdfe) results.

* If you find it takes too long, just use my file "myExtension2.txt" in the next step, which is the same but a copy of "myExtension.txt" I outputted before. 


********************************************************************************
*                                                                              *
*                    Step 2: Text file to pdf/eps			                   *
*		My extension could be compared with Panel C of Figure 3 in the paper   *
*                                                                              *
********************************************************************************

insheet using "$path_out\myExtension.txt", clear
* or myExtension2.txt
keep if inrange(_n,5,38)
* we import pure data
gen year = substr(v1,2,4)
* basically year=2000

rename (v2 v3)(coef2000 se2000)
destring, force replace
keep year coef* se*
reshape long coef se, i(year) j(data)
drop if coef == .
* Form a table-type, two-way dataset

gen lb = coef - 1.96*se
gen ub = coef + 1.96*se
gen y_overlap = min(max(year-1955,0),max(1970-year,0),6)
* Preparation for the coefficient line together with the CI
* Each dot on the figure will represent an estimation of that year's coefficient

twoway line lb year, lpattern(dash) lcolor(gs8) yaxis(1) ///
|| line ub year, lpattern(dash) lcolor(gs8) ///
|| line coef year, lwidth(thick) lcolor(black) yaxis(1) ///
|| line y_overlap year, lpattern(dash_dot) lwidth(thick) lcolor(gs8) yaxis(2) ///
||, graphregion(fcolor(gs16) lcolor(gs16)) plotregion(lcolor(gs16) margin(zero)) ///
     ylabel(-3(1)6, labsize(small) angle(0) format(%12.0f) axis(1)) ytitle("Coefficients", size(small) axis(1)) ///
     ylabel(0(2)6, labsize(small) angle(0) format(%12.0f) axis(2)) ytick(-6 0(1)6 12,axis(2)) ytitle("Years of Overlap", size(small) axis(2)) ///
	 xlabel(1945(5)1980, labsize(small)) xtick(1945(5)1980) xtitle("Birth Cohort", size(small)) ///
	 legend(order(3 1 4)label(3 "Coefficient") label(1 "95% CI") label(4 "Overlapped Years in""Primary Schools") col(2) size(small) margin(tiny)) ///
	 xline(1955 1970, lpattern(solid) lwidth(thin) lcolor(black)) ///
	 title("Extension Figure - Census 2000", size(small) margin(small)) ///
	 yline(0, lpattern(solid) lwidth(thin) lcolor(black)) fxsize(165) fysize(80)
* some graphical features, e.g., fxsize is the size of x axis, fysize is that of y axis 
	 
graph save c,replace 
graph export "$path_out\myExtension.eps",replace
* or "$path_out\myExtension.pdf"

