/*

Author: Ken Norris
Date: Aug 2018
Update : Sept 2018

Purpose: Update Residential price forecasts in EIA data for major electricity
Will then map to zip codes, etc.

*/

global dropbox "C:/Users/`c(username)'/Dropbox/Rebates_Project/Aldy, Houde, Nazar/Paper 2/Carbon Price Analysis"
set more off

cd "$dropbox"


global markets = "FRCC MROE MROW NEWE NYCW NYLI NYUP RFCE RFCM RFCW SRDA SRGW SRSE SRCE SRVC SPNO SPSO AZNM CAMX NWPP RMPA USA" 

* First run of the loop saves the first dataset of residential prices. Going to then append to the other prices/emissions
* we want for ERCT and then run the whole thing on the other markets and append it all together


*Set up an initial file using a base of one of the agencies before extending to them all
import delimited using "$dropbox/EIA Regional Data/Electric_Power_Projections_by_Electricity_Market_Module_Region_ERCT.csv", rowrange(438:441) varnames(5) clear
drop fullname apikey units v41 growth20172050
rename v1 case

egen eia_case = group(case)
recode eia_case (1 = 15) (2 = 25) (3 = 0) (4 = 1)

local strtoreal v5 v6
foreach x of varlist `strtoreal'{
	destring `x', replace
}

reshape long v, i(case) j(year)
rename v res_p
	

replace year = year + 2011
gen market = "ERCT"

save "AEO2018 EPP by Market Module", replace

foreach range1 in 448:451 458:461 592:595 {
	*Set up an initial file using a base of one of the agencies before extending to them all
	import delimited using "$dropbox/EIA Regional Data/Electric_Power_Projections_by_Electricity_Market_Module_Region_ERCT.csv", rowrange(`range1') varnames(5) clear
	drop fullname apikey units v41 growth20172050
	rename v1 case

	egen eia_case = group(case)
	recode eia_case (1 = 15) (2 = 25) (3 = 0) (4 = 1)

	local strtoreal v5 v6
	foreach x of varlist `strtoreal'{
		destring `x', replace
	}

	reshape long v, i(case) j(year)
	if "`range1'" == "458:461" rename v average_p  
	if "`range1'" == "448:451" rename v ind_p 
	if "`range1'" == "592:595" rename v co2_e 

	replace year = year + 2011
	gen market = "ERCT"
	
	merge 1:1 eia_case year market using "AEO2018 EPP by Market Module", nogen
	

	save "AEO2018 EPP by Market Module", replace
}



* Need to run a loop and append to ERCT data for residential prices and 
* then merge the other data we iterate over
foreach m of global markets{
	import delimited using "$dropbox/EIA Regional Data/Electric_Power_Projections_by_Electricity_Market_Module_Region_`m'.csv", rowrange(438:441) varnames(5) clear
	drop fullname apikey units growth20172050 v35
	rename v1 case
		
	egen eia_case = group(case)
	recode eia_case (1 = 15) (2 = 25) (3 = 0) (4 = 1)

	local strtoreal v5 v6
	foreach x of varlist `strtoreal'{
		destring `x', replace
	}

	reshape long v, i(case) j(year)
	rename v res_p
		 

	replace year = year + 2011
	gen market = "`m'"
		
	append using "AEO2018 EPP by Market Module"
			
	save "AEO2018 EPP by Market Module", replace
}

foreach range2 in 448:451 458:461 592:595{
	foreach m of global markets{
		import delimited using "$dropbox/EIA Regional Data/Electric_Power_Projections_by_Electricity_Market_Module_Region_`m'.csv", rowrange(`range2') varnames(5) clear
		drop fullname apikey units growth20172050 v35
		rename v1 case
		
		egen eia_case = group(case)
		recode eia_case (1 = 15) (2 = 25) (3 = 0) (4 = 1)

		local strtoreal v5 v6
		foreach x of varlist `strtoreal'{
			destring `x', replace
		}

		reshape long v, i(case) j(year)
		if "`range2'" == "458:461" rename v average_p  
		if "`range2'" == "448:451" rename v ind_p 
		if "`range2'" == "592:595" rename v co2_e 

		replace year = year + 2011
		gen market = "`m'"
		
		merge 1:1 eia_case year market using "AEO2018 EPP by Market Module", nogen
		
		
		save "AEO2018 EPP by Market Module", replace
	}

}

use "AEO2018 EPP by Market Module", clear

label var average_p "All sectors average electricity prices, 2017 cents/kWh"
label var res_p "Residential electricity prices, 2017 cents/kWh"
label var ind_p "Industrial electricity prices, 2017 cents/kWh"
label var co2_e "Electricity sector carbon dioxide emissions, MMTCO2"

save "AEO2018 EPP by Market Module", replace

*************    < ARCHIVED SEPT 2018 >    ************



* NO LONGER WANT TO MERGE WITH 2013 AEO DATA AS OF SEPT 2018 / COMMENTING THIS OUT *

/*


merge 1:1 market eia_case year using "AEO2013 EMM C Price Side Cases 160826", keep (master match) nogen

*Update residential elec price where there is an updated measure 
**(year > 2015, carbon price != 10)
replace elec_res_p = residential_p_2018
drop residential_p_2018 

label var elec_res_p "Residential electricity prices, 2017 cents/kwh"

save "AEO2013 EMM C Price Side Cases 160826 updated", replace

*/

