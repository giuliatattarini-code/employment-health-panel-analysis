/**************************************************************************
Project: Employment Health Panel Analysis
Author: Giulia Tattarini
Software: STATA 19

Description:
Constructs socio-demographic variables, health outcomes,
and core employment indicators from the processed SOEP panel file.

Note:
This script is a simplified and illustrative version of the variable
construction workflow used in related academic research. It is intended for
portfolio purposes and does not provide a full replication package.
**************************************************************************/

clear all
set more off

* ------------------------------------------------------------------------
* Project directories
* ------------------------------------------------------------------------

global input_data  "data/processed"
global output_data "data/processed"

* ------------------------------------------------------------------------
* 1. Load processed person-year panel
* ------------------------------------------------------------------------

use "$input_data/master_panel.dta", clear

* ------------------------------------------------------------------------
* 2. Socio-demographic variables
* ------------------------------------------------------------------------

* Survey year
rename syear year
label variable year "Survey year"

* Age and age squared
generate age = year - gebjahr
label variable age "Age"

generate agesq = age*age
label variable agesq "Age squared"

* Gender
generate women = sex == 2 if sex < .
label define women 0 "Men" 1 "Women"
label values women women
label variable women "Gender: women"

* Education: ISCED classification
rename pgisced11 education
label variable education "Education: ISCED classification"

* Region: current federal state
rename bula federal_state
label variable federal_state "Federal state"

* ------------------------------------------------------------------------
* 3. Health outcomes
* ------------------------------------------------------------------------

* Self-rated health, reversed so that higher values indicate better health
* Original SOEP scale: 1 = very good; 5 = bad

generate self_rated_health = -ple0008 + 6 if ple0008 < .
label define self_rated_health ///
    1 "Very bad" ///
    2 "Bad" ///
    3 "Satisfactory" ///
    4 "Good" ///
    5 "Very good"
label values self_rated_health self_rated_health
label variable self_rated_health "Self-rated health, reversed"

* Life satisfaction, 0-10 scale
rename plh0182 life_satisfaction
label variable life_satisfaction "Life satisfaction"

* Disability indicator used for sample selection / robustness checks
recode ple0041 (0/29 = 0 "No") (30/100 = 1 "Yes") (else = .), ///
    generate(disability_30plus)
replace disability_30plus = 0 if ple0040 == 2
label variable disability_30plus "Legally attested disability of 30% or more"

* ------------------------------------------------------------------------
* 4. Employment status
* ------------------------------------------------------------------------

* Employment status from generated SOEP employment variable
recode pgemplst ///
    (1 = 1 "Full-time") ///
    (2 = 2 "Regular part-time") ///
    (4 = 3 "Marginal part-time") ///
    (5 = 4 "Not working") ///
    (else = .), generate(emp_status_raw)
label variable emp_status_raw "Employment status, raw classification"

* Employment status combining employment information and occupational position
* PGSTIB distinguishes employees, civil servants, manual workers, unemployed,
* and other non-employed respondents.

generate employment_status = .
replace employment_status = 1 if inrange(pgstib, 210, 640) & emp_status_raw == 1
replace employment_status = 2 if inrange(pgstib, 210, 640) & emp_status_raw == 2
replace employment_status = 3 if inrange(pgstib, 210, 640) & emp_status_raw == 3
replace employment_status = 4 if inlist(pgstib, 10, 12) & emp_status_raw == 4

label define employment_status ///
    1 "Full-time" ///
    2 "Regular part-time" ///
    3 "Marginal part-time" ///
    4 "Not employed"
label values employment_status employment_status
label variable employment_status "Employment status"

* ------------------------------------------------------------------------
* 5. Contract type
* ------------------------------------------------------------------------

* Temporary vs permanent contract among employed respondents

generate contract = .
replace contract = 1 if plb0037_h == 2 & employment_status <= 3
replace contract = 0 if plb0037_h == 1 & employment_status <= 3

label define contract 0 "Permanent" 1 "Temporary"
label values contract contract
label variable contract "Contract type"

* Contract type including non-employment as reference category

generate contract_with_unemp = contract
replace contract_with_unemp = 2 if contract == 0
replace contract_with_unemp = 0 if employment_status == 4

label define contract_with_unemp ///
    0 "Not employed" ///
    1 "Temporary" ///
    2 "Permanent"
label values contract_with_unemp contract_with_unemp
label variable contract_with_unemp "Contract type, including non-employment"

* ------------------------------------------------------------------------
* 6. Working-time categories
* ------------------------------------------------------------------------

* Working time is primarily based on contractual weekly hours.
* Long full-time captures high actual working hours above 40 per week.

generate working_time = .
replace working_time = 1 if pgvebzeit <= 15 & employment_status <= 3
replace working_time = 2 if inrange(pgvebzeit, 16, 34) & employment_status <= 3
replace working_time = 3 if inrange(pgvebzeit, 35, 40) & employment_status <= 3
replace working_time = 4 if pgtatzeit > 40 & pgtatzeit < . & employment_status <= 3

label define working_time ///
    1 "Marginal part-time" ///
    2 "Standard part-time" ///
    3 "Standard full-time" ///
    4 "Long full-time"
label values working_time working_time
label variable working_time "Working-time category"

* Working time including non-employment

generate working_time_with_unemp = working_time
replace working_time_with_unemp = 0 if employment_status == 4

label define working_time_with_unemp ///
    0 "Not employed" ///
    1 "Marginal part-time" ///
    2 "Standard part-time" ///
    3 "Standard full-time" ///
    4 "Long full-time"
label values working_time_with_unemp working_time_with_unemp
label variable working_time_with_unemp "Working-time category, including non-employment"

* Binary indicator for marginal part-time employment

generate marginal_part_time = .
replace marginal_part_time = 1 if working_time == 1
replace marginal_part_time = 0 if working_time > 1 & working_time < .

label define marginal_part_time 0 "No marginal part-time" 1 "Marginal part-time"
label values marginal_part_time marginal_part_time
label variable marginal_part_time "Marginal part-time employment"

* Marginal part-time indicator including non-employment

generate marginal_with_unemp = .
replace marginal_with_unemp = 0 if working_time_with_unemp == 0
replace marginal_with_unemp = 1 if working_time_with_unemp == 1
replace marginal_with_unemp = 2 if working_time_with_unemp > 1 & working_time_with_unemp < .

label define marginal_with_unemp ///
    0 "Not employed" ///
    1 "Marginal part-time" ///
    2 "Standard PT/FT/long FT"
label values marginal_with_unemp marginal_with_unemp
label variable marginal_with_unemp "Marginal part-time, including non-employment"

* ------------------------------------------------------------------------
* 7. Wage indicators
* ------------------------------------------------------------------------

* Gross hourly wage among employed respondents.
* Implausibly low and high values are set to missing.

generate hourly_wage = pglabgro / (4.33 * pgtatzeit) ///
    if pglabgro >= 1 & pgtatzeit >= 1 & employment_status <= 3

replace hourly_wage = . if hourly_wage < 1
replace hourly_wage = . if hourly_wage > 200
label variable hourly_wage "Gross hourly wage"

* Median wage by year and federal state
bysort year federal_state: egen median_wage = median(hourly_wage) ///
    if employment_status <= 3
label variable median_wage "Median hourly wage by year and federal state"

* Low-wage threshold: two thirds of the median hourly wage
generate low_wage_threshold = (2/3) * median_wage
label variable low_wage_threshold "Low-wage threshold: two thirds of median wage"

* Binary low-wage indicator

generate low_wage = .
replace low_wage = 1 if hourly_wage < low_wage_threshold & hourly_wage < .
replace low_wage = 0 if hourly_wage >= low_wage_threshold & hourly_wage < .

label define low_wage 0 "No low-wage work" 1 "Low-wage work"
label values low_wage low_wage
label variable low_wage "Low-wage work"

* Low-wage indicator including non-employment

generate low_wage_with_unemp = .
replace low_wage_with_unemp = 0 if employment_status == 4
replace low_wage_with_unemp = 1 if low_wage == 1
replace low_wage_with_unemp = 2 if low_wage == 0

label define low_wage_with_unemp ///
    0 "Not employed" ///
    1 "Low-wage work" ///
    2 "No low-wage work"
label values low_wage_with_unemp low_wage_with_unemp
label variable low_wage_with_unemp "Low-wage work, including non-employment"

* Relative wage: gross hourly wage divided by year-state median wage

generate relative_wage = hourly_wage / median_wage
label variable relative_wage "Hourly wage relative to year-state median"

* Relative wage including non-employment, where non-employed respondents are set to 0

generate relative_wage_with_unemp = relative_wage
replace relative_wage_with_unemp = 0 if employment_status == 4
label variable relative_wage_with_unemp "Relative wage, including non-employment"

* ------------------------------------------------------------------------
* 9. Occupational class
* ------------------------------------------------------------------------

* Harmonised EGP class variable using ISCO-88 and ISCO-08 based SOEP variables.

generate class_raw = pgegp88
replace class_raw = pgegp08 if missing(class_raw)

generate egp5 = .
replace egp5 = 4 if class_raw == 1
replace egp5 = 3 if class_raw == 2
replace egp5 = 2 if inlist(class_raw, 3, 4)
replace egp5 = 1 if inlist(class_raw, 7, 8, 9)
replace egp5 = 0 if employment_status == 4

label define egp5 ///
    4 "Higher service" ///
    3 "Lower service" ///
    2 "Routine non-manual" ///
    1 "Working class" ///
    0 "Not employed"
label values egp5 egp5
label variable egp5 "EGP class, 5 categories"

* ------------------------------------------------------------------------
* 10. Save analytical indicators dataset
* ------------------------------------------------------------------------

save "$output_data/indicators_panel.dta", replace

display "Indicator dataset created successfully."

