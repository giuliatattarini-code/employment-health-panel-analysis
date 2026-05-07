/**************************************************************************
Project: Employment Health Panel Analysis
Author: Giulia Tattarini
Software: STATA 19
Description:
Illustrative workflow for fixed-effects panel data models using
longitudinal SOEP data.
**************************************************************************/

clear all
set more off

* ------------------------------------------------------------------------
* Project directories
* ------------------------------------------------------------------------

global root "."
global scripts "$root/scripts"
global output "$root/output"

* ------------------------------------------------------------------------
* Load analytical dataset
* ------------------------------------------------------------------------

* Example:
* use "data/analysis_sample.dta", clear

* ------------------------------------------------------------------------
* Panel settings
* ------------------------------------------------------------------------

* Example:
* xtset pid year

* ------------------------------------------------------------------------
* Fixed-effects models
* ------------------------------------------------------------------------

* Example:
* xtreg health i.employment_status age age2 i.year, fe vce(cluster pid)

display "Panel model workflow initialized."
