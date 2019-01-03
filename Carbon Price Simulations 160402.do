

** KN **
**Updated Aug 18 to account for newly released EIA data for residential elec prices

* CARBON PRICE SIMULATIONS 160402
capture log close
capture clear matrix
clear
set more off
set mem 1000m
set matsize 4000
capture matrix close

*global pathname="C:\Users\jaldy.HKS\Dropbox\EnergyStar Rebates\Aldy, Houde, Nazar"
global pathname="C:/Users/`c(username)'/Dropbox/Rebates_Project/Aldy, Houde, Nazar/Paper 2/Carbon Price Analysis"
cd "$pathname" 
*log using "Carbon Price Simulations 160402", replace
* CARBON PRICE SIMULATIONS 160402

* EIA CARBON PRICE SUMMARIES
* EIA: AEO2013 CARBON TAX SIDE CASES
foreach x of num 1 15 25 {
	*use "AEO2013 EMM C Price Side Cases.dta"
	use "AEO2018 EPP by Market Module.dta"
	keep if year==2020 /* SEPT 2018 EDIT; WANT RES PRICES FOR 2020 - YEAR 1 TAX */
	drop co2_e
	*ren co2_e emis_ctax`x'
	keep if eia_case==`x'
	drop ind_p
	*ren elec_all_p pelec_ctax`x'
	**Update Aug 2018 : previous version used average elec price, now use residential**
	ren res_p pelec_ctax`x' 
	sort market
	save temp`x', replace
	clear
	}
use temp0.dta
foreach x of num 1 15 25 {
	merge 1:1 market using temp`x'.dta
	drop _merge
	}	
drop co2_p eia_case year
foreach x of num 1 15 25 {
	g pelec_chg_ctax`x' = (pelec_ctax`x'-pelec_ctax0)/pelec_ctax0
	label var pelec_chg_ctax`x' "Percentage change in electricity price under $`x' carbon tax"
	}
sort market
ren pelec_ctax1 pelec_CPP
ren pelec_chg_ctax1 pelec_chg_CPP
label var pelec_chg_ctax1 "Percentage change in electricity price under CPP"
save "EIA Carbon Tax EMM 2020", replace
clear
/*
* EIA: CLEAN POWER PLAN ANALYSIS -- ESTIMATES BASED ON PROPOSED CPP 
foreach x of num 1/2 {
	use "eia_electricity_price"
	keep if eia_case==`x'
	drop year
	ren elec_all_pct elec_all_pct`x'
	sort market
	save temp`x', replace
	}
use temp1.dta
merge 1:1 market using temp2.dta
drop _merge
foreach x of num 1/2 {
	ren elec_all_pct`x' pelec_chg_cpp`x'
	}
drop eia_case
label var pelec_chg_cpp1 "Percentage change in electricity price under CPP EIA Base Case"
label var pelec_chg_cpp2 "Percentage change in electricity price under CPP EIA Policy Ext Case"
sort market
save "EIA CPP Proposal First Year", replace
clear
*/
* ZIP CODE - POWER MARKET CROSSWALK
* SOURCE: PROVIDED BY JOHN CONTI, EIA, MARCH 30, 2016
import excel using power_profiler_zipcode_tool_2012_v6-0, sheet("Zip-Subregion") first
ren PrimaryeGRIDSubregion market
* NOTE THAT THE eGRID FILE HAS DIFFERENT CODES FOR FOUR MARKETS FROM THE EIA EMM CODING SCHEME
* COMPARE MAP IN eGRID EXCEL FILE TO FIGURE 3 OF EIA EMM DOCUMENTATION HERE:
* http://www.eia.gov/forecasts/aeo/nems/documentation/electricity/pdf/m068(2013).pdf
* RECODE eGRID MARKETS FOR THE FOLLOWING:
* SRMV --> SRDA
* SRMW --> SRGW
* SRSO --> SRSE
* SRTV --> SRCE
replace market = "SRDA" if market=="SRMV"
replace market = "SRGW" if market=="SRMW"
replace market = "SRSE" if market=="SRSO"
replace market = "SRCE" if market=="SRTV"
sort market
merge m:1 market using "EIA Carbon Tax EMM 2020"
sum _merge
list market if _merge==2
drop _merge
/*
sort market
merge m:1 market using "EIA CPP Proposal First Year"
sum _merge
list market if _merge==2
drop _merge
label var market "Electricity Market Module"
*/
save "Carbon Price Zip Code Scenarios", replace





