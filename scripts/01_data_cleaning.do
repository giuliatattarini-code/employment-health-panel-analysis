/**************************************************************************
Project: Employment Health Panel Analysis
Author: Giulia Tattarini
Software: STATA 19
Description:
Illustrative workflow for longitudinal panel data analysis using SOEP data.
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
* Load data
* ------------------------------------------------------------------------

* Example:
* use "data/soep_sample.dta", clear

* ------------------------------------------------------------------------
* Data cleaning
* ------------------------------------------------------------------------

display "Data cleaning workflow initialized."
