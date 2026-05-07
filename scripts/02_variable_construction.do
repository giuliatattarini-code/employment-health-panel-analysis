/**************************************************************************
Project: Employment Health Panel Analysis
Author: Giulia Tattarini
Software: STATA 19
Description:
Illustrative workflow for constructing employment and health indicators
from longitudinal SOEP data.
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
* Load cleaned data
* ------------------------------------------------------------------------

* Example:
* use "data/clean_panel_data.dta", clear

* ------------------------------------------------------------------------
* Variable construction
* ------------------------------------------------------------------------

* Example indicators:
* - employment status
* - contract type
* - working-time category
* - relative wage
* - self-rated health
* - life satisfaction

display "Variable construction workflow initialized."
