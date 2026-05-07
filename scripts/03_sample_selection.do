/**************************************************************************
Project: Employment Health Panel Analysis
Author: Giulia Tattarini
Software: STATA 19

Description:
Applies sample restrictions and creates analytical samples for longitudinal
fixed-effects models using the indicator dataset.

Note:
This script is a simplified, portfolio-oriented version of the sample
selection workflow used in related academic research. It is intended to
illustrate transparent sample construction and missing-data handling.
**************************************************************************/

clear all
set more off

* ------------------------------------------------------------------------
* 0. Directories and input data
* ------------------------------------------------------------------------

global input_data  "data/processed"
global output_data "data/processed"

use "$input_data/indicators_panel.dta", clear

count

* ------------------------------------------------------------------------
* 1. Keep variables used in the analytical workflow
* ------------------------------------------------------------------------

keep ///
    pid hid year ///
    age agesq women education federal_state ///
    self_rated_health life_satisfaction disability_30plus ///
    employment_status contract contract_with_unemp ///
    working_time working_time_with_unemp marginal_with_unemp ///
    low_wage low_wage_with_unemp ///
    relative_wage relative_wage_with_unemp ///
    egp5

order ///
    pid hid year ///
    age agesq women education federal_state ///
    self_rated_health life_satisfaction disability_30plus ///
    employment_status contract contract_with_unemp ///
    working_time working_time_with_unemp marginal_with_unemp ///
    low_wage low_wage_with_unemp ///
    relative_wage relative_wage_with_unemp ///
    egp5

* ------------------------------------------------------------------------
* 2. Define the eligible population
* ------------------------------------------------------------------------

* Study period: self-rated health is consistently available from 1994 onwards.
keep if year >= 1994

* Working-age population.
keep if inrange(age, 20, 65)

* Keep respondents who are either employed or not employed.
keep if employment_status < .

* Among employed respondents, keep only those with valid contract information.
drop if inrange(employment_status, 1, 3) & missing(contract)

* ------------------------------------------------------------------------
* 3. Exclude respondents with disability at baseline
* ------------------------------------------------------------------------

sort pid year
by pid: generate first_observation = (_n == 1)
by pid: egen baseline_disability = max(disability_30plus == 1 & first_observation)

drop if baseline_disability == 1

drop first_observation baseline_disability

* ------------------------------------------------------------------------
* 4. Check missing values on model variables
* ------------------------------------------------------------------------

* Uncomment if the mdesc package is installed.
* mdesc self_rated_health life_satisfaction age employment_status ///
*     contract_with_unemp working_time_with_unemp ///
*     relative_wage_with_unemp egp5

* Analytical samples for models including non-employment.
generate sample_joint_m1 = !missing( ///
    self_rated_health, life_satisfaction, age, ///
    employment_status, contract_with_unemp, ///
    working_time_with_unemp, relative_wage_with_unemp)

generate sample_health_m1 = !missing( ///
    self_rated_health, age, employment_status, ///
    contract_with_unemp, working_time_with_unemp, ///
    relative_wage_with_unemp)

generate sample_lifesat_m1 = !missing( ///
    life_satisfaction, age, employment_status, ///
    contract_with_unemp, working_time_with_unemp, ///
    relative_wage_with_unemp)

label variable sample_joint_m1   "Joint analytical sample: health and life satisfaction"
label variable sample_health_m1  "Analytical sample: self-rated health"
label variable sample_lifesat_m1 "Analytical sample: life satisfaction"

* ------------------------------------------------------------------------
* 5. Require at least two observations per respondent
* ------------------------------------------------------------------------

foreach sample in sample_joint_m1 sample_health_m1 sample_lifesat_m1 {
    bysort pid: egen waves_`sample' = total(`sample')
    replace `sample' = 0 if waves_`sample' < 2
    label variable waves_`sample' "Number of valid waves for `sample'"
}

* ------------------------------------------------------------------------
* 6. Basic quality checks
* ------------------------------------------------------------------------

duplicates report pid year

tab sample_joint_m1
tab sample_health_m1
tab sample_lifesat_m1

* ------------------------------------------------------------------------
* 7. Save selected analytical dataset
* ------------------------------------------------------------------------

save "$output_data/analysis_sample.dta", replace


