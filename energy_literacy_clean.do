/* 
Author: Ken Norris

Date: July 2018

Last Update: July 2018

Description: This code cleans Energy Literacy survey data of 1000 individuals 
collected in order to judge salience of energy efficiency programs, with 
attention paid to rebate programs like EnergyStar appliances. 

The following describes the flow of the .do file that cleans the data for 
analysis
	1. Variable generated to map fips codes to State
	2. .....
	
 Zip -> County crosswalk here: 
 
 https://anthonylouisdagostino.com/2018/03/28/a-better-zip5-county-crosswalk/
 
*******************************************************************************/


clear all
global dropbox `"C:/Users/`c(username)'/Dropbox/Rebates_Project"'
cd $dropbox

**Start with many tempfiles bringing in some raw data to compile summary stats**


*In order to get census region create this crosswalk and save as tempfile*
tempfile censusregion
input str24 state byte census_region
"California"     4
"Colorado"       4
"Connecticut"    1
"Delaware"       3
"Florida"        3
"Georgia"        3
"Hawaii"         4
"Illinois"       2
"Indiana"        2
"Kentucky"       3
"Louisiana"      3
"Maryland"       3
"Massachusetts"  1
"Minnesota"      2
"New Hampshire"  1
"New Jersey"     1
"New York"       1
"Nevada"         4
"North Carolina" 3
"Ohio"           2
"Oklahoma"       3
"Oregon"         4
"Pennsylvania"   1
"Tennessee"      3
"Utah"           4
"Vermont"        1
"Virginia"       3
"Washington"     4
"Wyoming"        4
end
label values census_region census_region
label def census_region 1 "Northeast", modify
label def census_region 2 "Midwest", modify
label def census_region 3 "South", modify
label def census_region 4 "West", modify

save "`censusregion'"


insheet using "$dropbox\Energy Literacy Survey\2017 Data\SalesTaxHoliday.csv", clear
tempfile taxholiday
save "`taxholiday'"

tempfile canchoose
insheet using "$dropbox\Energy Literacy Survey\2017 Data\CanChooseEnergyProvider.csv", clear
save "`canchoose'"

**To generate a spreadsheet of counties and if have multiple utilities( =1)*
insheet using "$dropbox\Energy Literacy Survey\2017 Data\Service_Territory_2015.csv", clear

statastates, abbreviation(state)
drop state_fips _merge state

gen state = proper(state_name)
drop state_name

egen county_st = group(county state), label

duplicates tag county_st, gen(tag)

gen multi_utility = 0 
replace multi_utility = 1 if tag != 0 
drop tag
drop if state == "PR"


*Going to generate from this a tempfile that can be used to see how many unique utilities
*exist in the data. Merge to survey to get an idea of how pervasive multi utility issue is

keep if multi_utility == 0

tempfile utilbycounty
save "`utilbycounty'"



*Begin majority of cleaning literacy survey here*

insheet using "$dropbox\Energy Literacy Survey\EnergyLiteracySurvey.csv", names clear
drop in 2

* Other than responseid, survey questions all have q in var name
rename responseid qresponseid 
keep *q*
*Don't need this q
drop q56

*Many identifiers in the .csv file were ambiguously named, including state
rename qresponseid id
rename q1 hh_income
rename q2 age
rename q47 hh_age
rename q48 educ
rename q49 num_adult
rename q50 num_kid
rename q4 city
rename q60 state
rename q3 zip_code
rename q42 salestax 
rename q5 own_rent
rename q8 elec_provider
rename q9 provider_choice
rename q10 switch_provider
rename q11 pay_ckwh
rename q12 consume_kwh
rename q13 know_es
rename q14 own_es

*recode ID by number*
egen ID = group(id)
drop id
rename ID id
order id

*Below command generates both state_abbrev and fips codes
statastates, name(state)
*5 respondents did not get to State question
drop if state == ""
drop if id==.
drop _merge

replace state = proper(state)


/*Cant figure this loop out right now, want it to be same as below*
local stfiles censusregion taxholiday canchoose
foreach f in `stfiles'{
	merge m:1 state using "`f'"
	drop_merge
}
*/

*Pull in census region for each state*
merge m:1 state using "`censusregion'"
drop _merge

merge m:1 state using "`taxholiday'"
drop _merge 

merge m:1 state using "`canchoose'"
drop _merge


*Check duplicates on id*
duplicates list id


*Use this command for all those categorical vars 
*The block below can be used to factorize the qual variables to then tab

local catvars know_es own_es own_rent provider_choice switch_provider ///
	q39 q40 q41 q17 q18 q19 q20 q54 q21 q44 q23 q45 q24_1 ///
	q24_2 q24_3 q24_4 q24_5 q24_6 q25_1 q25_2 q25_3 q26_1 ///
	q26_2 q26_3 q26_4 q26_5 q26_6 q7 q6 q15

foreach var in `catvars'{
	egen `var'factor = group(`var'), label
}

drop `catvars'


*barely anything obs in these*
drop q7_4_text q10_3_text q15_8_text q54_5_text q54_5_texttopics

*these just make no sense imo*
drop q16 q53 q43

*Below can be used to clean up numeric entry survey Q's
*removes all the don't knows from numeric responses and replaces with . *
local remove_nonsense pay_ckwh consume_kwh salestax

foreach n in `remove_nonsense'{
	replace `n' = subinstr(`n', ",", "",.)
	replace `n' = subinstr(`n', "%", "", .)
	replace `n' = subinstr(`n', "percent", "", .)
	destring `n', generate(new_`n') force
}

preserve

insheet using "$dropbox\Energy Literacy Survey\2017 Data\zip_code_database.csv", clear
keep zip county
replace county = subinstr(county, "County", "", .)
tostring zip, replace
rename zip zip_code

tempfile zipc
save "`zipc'"

restore

*Bringing in fips codes and county names for survey respondents*

merge m:1 zip_code using "$dropbox\Energy Literacy Survey\2017 Data\mapping_zip_county_nov99.dta"
rename zcta5 fips_county
drop _merge


merge m:1 zip_code using "`zipc'"

drop if _merge==2
drop _merge

*Cleaned up version of elec_provider
gen utility = proper(itrim(trim(elec_provider)))

*Clean up abbreviations of utilities
replace utility = subinstr(utility, "Pse&G", "Public Service Enterprise Group", .)
replace utility = subinstr(utility, "Pseg", "Public Service Enterprise Group", .)
replace utility = subinstr(utility, "Gmp", "Green Mountain Power", .)
replace utility = subinstr(utility, "Jcp&L", "Jersey Central Power and Light", .)
replace utility = subinstr(utility, "Jcp", "Jersey Central Power and Light", .)
replace utility = subinstr(utility, "Com Ed", "Comed", .)
replace utility = subinstr(utility, "Delmarva Power", "Delmarva", .)
replace utility = subinstr(utility, "Bge", "Baltimore Gas & Electric Co", .)
replace utility = subinstr(utility, "Cleco", "Cleco Power Llc", .)
replace utility = subinstr(utility, "Nes", "Nashville Electric Service", .)
replace utility = subinstr(utility, "Pge", "Portland General Electric", .)
replace utility = subinstr(utility, "Pse", "Puget Sound Energy", .)
replace utility = subinstr(utility, "Ku", "Kentucky Utilities Co", .)
replace utility = subinstr(utility, "Og&E", "Oklahoma General Electric", .)
replace utility = subinstr(utility, "Helco", "Hawaiian Electric", .)
replace utility = subinstr(utility, "Heco", "Hawaiian Electric", .)
replace utility = subinstr(utility, "Oge", "Oklahoma General Electric", .)
*Nstar became part of conglomeration known as Eversource*
replace utility = subinstr(utility, "Nstar", "Eversource", .)
replace utility = subinstr(utility, "Dont Know", "Don't Know", .)

gen utilityimpute = 1 if lower(utility) == "don't know"

egen county_st = group(county state), label


*This is frigged. Merged in those counties where only one utility exists.
*only 100/1000 actually match and very few of Don't know.
*Not helpful. Going to need to develop something to match utilities here

*Leave this for now
*merge m:1 county_st using "`utilbycounty'"


rename fips_county county_utility
destring county_utility, replace


*Merge in DSIRE Rebates. Doesn't uniquely identify due to year, NEED TO FIX THIS*

merge m:1 county_utility using "$dropbox\Energy Literacy Survey\DSIRE_rebates_collapse.dta"


***maybe use this step to bring in elec price. Need to figure out for sure what county_utility is***

*merge m:1 county_utility using "$dropbox\Energy Literacy Survey\2017 Data\county_elec_price_2007_2012"

save "$dropbox/Energy Literacy Survey/literacysurvey_cleaned.dta", replace
