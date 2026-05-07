/**************************************************************************
Project: Employment Health Panel Analysis
Author: Giulia Tattarini
Software: STATA 19

Description:
Builds an illustrative person-year panel dataset by merging selected SOEP
files and applying initial sample restrictions.

Note:
Raw SOEP data are not included in this repository due to data protection
restrictions. This script is intended as a simplified workflow example.
**************************************************************************/

clear all
set more off

* ------------------------------------------------------------------------
* Project directories
* ------------------------------------------------------------------------

global raw_data    "data/raw"
global output_data "data/processed"

* ------------------------------------------------------------------------
* 1. Load person-year data
* ------------------------------------------------------------------------

use "$raw_data/ppathl.dta", clear

count
describe

* ------------------------------------------------------------------------
* 2. Merge individual-level generated variables
* ------------------------------------------------------------------------

merge 1:1 pid syear using "$raw_data/pgen.dta", ///
    keepusing( ///
        pgisced11 /// education: ISCED classification
        pgstib    /// occupational position
        pgemplst  /// employment status
        pglfs     /// labour force status
        pgegp88   /// Erikson-Goldthorpe class category based on ISCO-88
        pgegp08   /// Erikson-Goldthorpe class category based on ISCO-08
        pgisco88  /// occupation: ISCO-88
        pgisco08  /// occupation: ISCO-08
        pgtatzeit /// actual weekly working time
        pgvebzeit /// contractual/agreed weekly working time
        pgnace    /// industry sector
        pgnace2   /// industry sector, revised classification
        pglabgro  /// gross labour income
        pglabnet  /// net labour income
        pgimpgro  /// imputation flag: gross labour income
        pgimpnet  /// imputation flag: net labour income
    ) ///
    keep(master match) gen(merge_pgen)

tab merge_pgen

* ------------------------------------------------------------------------
* 3. Merge individual questionnaire data
* ------------------------------------------------------------------------

merge 1:1 pid syear using "$raw_data/pl.dta", ///
    keepusing( ///
        plb0037_h /// contract type
        ple0008   /// self-rated health
        ple0009   /// health-related limitations in daily life
        ple0040   /// legally recognised disability / reduced employment capacity
        ple0041   /// degree of legally recognised disability / reduced employment capacity
        plh0182   /// life satisfaction ) ///
    keep(master match) nogen

* ------------------------------------------------------------------------
* 4. Merge regional information
* ------------------------------------------------------------------------

merge m:1 hid syear using "$raw_data/regionl.dta", ///
    keepusing(bula) /// federal state
    keep(master match) nogen


* ------------------------------------------------------------------------
* 5. Initial sample restrictions
* ------------------------------------------------------------------------

* Keep respondents with completed interviews
keep if inrange(netto, 10, 19)

* Keep private households only
keep if pop == 1 | pop == 2

* Keep valid information on gender
keep if sex > 0

* ------------------------------------------------------------------------
* 6. Recode SOEP missing values
* ------------------------------------------------------------------------

mvdecode _all, mv(-8/-1 = .)

* ------------------------------------------------------------------------
* 7. Save processed dataset
* ------------------------------------------------------------------------

save "$output_data/master_panel.dta", replace

display "Master panel dataset created successfully."
