

clear all
global dropbox `"C:/Users/`c(username)'/Dropbox/Rebates_Project"'
cd $dropbox


insheet using "$dropbox\Energy Literacy Survey\2017 Data\StateRebatesData.csv", names clear

drop fundingsource


*First get those that are statewide, merge these to county wide!
tempfile noutilrebates
keep if utility == ""
drop if state == "Utah"
save "`noutilrebates'"


*Then do the same with those that are unique obs before merge with duplicates*
tempfile uniqueutil
insheet using "$dropbox\Energy Literacy Survey\2017 Data\StateRebatesData.csv", names clear
gen utilitycaps = proper(lower(utility))
drop utility
rename utilitycaps utility

bysort utility: keep if _n==1
*picks up empty statewide first obs, delete this
drop in 1
save "`uniqueutil'"


insheet using "$dropbox\Energy Literacy Survey\2017 Data\StateRebatesData.csv", names clear

*Creating new var for multiple rebates for certain utility to merge 
bysort utility: drop if _n==1
keep if utility !=""

gen utilitycaps = proper(lower(utility))
drop utility
rename utilitycaps utility

local manyrebates waterheater refrigeratorfreezer washer dryer ac dishwasher
foreach m in `manyrebates' {
	rename `m' `m'_additional
}


merge m:1 utility using "`uniqueutil'"
drop _merge

*For now dropping these, pull them back in later (3 obs)
duplicates drop utility, force                                                                                                                                                   

tempfile rebates1
save "`rebates1'" 
*No counties in rebate data above, must match on utility*


*noutil relies on county; if county=Statewide then apply to all obs of state 

import delimited "$dropbox\Energy Literacy Survey\2017 Data\SalesTaxHoliday.csv", clear
tempfile taxholiday
save "`taxholiday'"

use "$dropbox\Energy Literacy Survey\literacysurvey_cleaned.dta", clear

*Merge tax holiday*

merge m:1 state using "`taxholiday'"
drop _merge

*Merge rebates data THIS IS A MESS, still need to merge other rebates up top**
merge m:1 utility using "`rebates1'"


*merge m:1 utility using "`rebates2'"

gen checkutil = proper(lower(administrator))



/*
*Below uses Levenshtein distance, or edit distance to compare admin with
*utility response given by survey answers. Need to alter this to return match 
*from x values in foreach loop
preserve

tempfile checking
keep checkutil
duplicates drop checkutil, force
save "`checking'"


restore 


*Need to figure out how using that tempfile, I can compare and generate a string that matches utility

foreach x of `checking' {
	strdist `x' utility, gen(blah) maxdist(15)
}
*/


save "$dropbox\Energy Literacy Survey\literacysurvey_rebates_cleaned.dta", replace
*Merge price of electricity READY TO GO ONCE I KNOW WHAT COUNTY NUMBER IS*






