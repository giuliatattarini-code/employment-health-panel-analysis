/**************************************************************************
Project: Employment Health Panel Analysis
Author: Giulia Tattarini
Software: STATA 19

Description:
Runs fixed-effects panel models for health outcomes using employment indicators. T

Note:
This is a simplified, portfolio-oriented version of the original analysis
workflow. It is intended to show complex, reproducible modelling and output
production logic, not to reproduce the full paper.
**************************************************************************/

clear all
set more off

* ------------------------------------------------------------------------
* 0. Directories and input data
* ------------------------------------------------------------------------

global input_data "data/processed"
global log_path   "logs"
global tables     "outputs/tables"
global graphs     "outputs/graphs"

use "$input_data/analysis_sample.dta", clear

* ------------------------------------------------------------------------
* 1. Panel setup
* ------------------------------------------------------------------------

xtset pid year
xtdescribe

* ------------------------------------------------------------------------
* 2. Global macros
* ------------------------------------------------------------------------

* Outcomes
global outcomes self_rated_health life_satisfaction

* Controls
global controls c.age c.agesq i.year

* PE indicators
global pe_cat contract_with_unemp working_time_with_unemp
global pe_cont relative_wage_with_unemp
global pe_all contract_with_unemp working_time_with_unemp relative_wage_with_unemp

* Outcome-specific table names
local table_self_rated_health  "FE_self_rated_health"
local table_life_satisfaction  "FE_life_satisfaction"

* Indicator labels for table titles
local label_contract_with_unemp     "Contract"
local label_working_time_with_unemp "Working time"
local label_relative_wage_with_unemp "Relative wage"

estimates clear

* ------------------------------------------------------------------------
* 3. M1: fixed-effects models with single PE indicators
* ------------------------------------------------------------------------

log using "$log_path/M1_single_indicators.log", replace

foreach y of global outcomes {

    local table "`table_`y''"
    local replace_or_append replace

    foreach x of global pe_all {

        local xlab "`label_`x''"

        display "=================================================="
        display "Outcome: `y' | M1 single indicator: `x'"
        display "=================================================="

        if "`x'" == "relative_wage_with_unemp" {
            xtreg `y' c.`x' $controls if sample_joint_m1 == 1, fe vce(cluster pid)
            margins, dydx(`x') post
        }
        else {
            xtreg `y' i.`x' $controls if sample_joint_m1 == 1, fe vce(cluster pid)
            margins, dydx(`x') post
        }

        estimates store AME_`y'_`x'

        outreg2 using "$tables/`table'_M1.doc", word `replace_or_append' ///
            ctitle("`xlab'") dec(3) se ///
            alpha(0.001, 0.01, 0.05) symbol(***, **, *) ///
            label

        local replace_or_append append
    }
}

log close

* ------------------------------------------------------------------------
* 4. M2: fixed-effects models with gender interactions
* ------------------------------------------------------------------------

log using "$log_path/M2_gender_interactions.log", replace

foreach y of global outcomes {

    local table "`table_`y''"
    local replace_or_append replace

    foreach x of global pe_all {

        local xlab "`label_`x''"

        display "=================================================="
        display "Outcome: `y' | M2 gender interaction: `x'"
        display "=================================================="

        if "`x'" == "relative_wage_with_unemp" {
            xtreg `y' c.`x'##i.women $controls if sample_joint_m1 == 1, ///
                fe vce(cluster pid)
            margins women, dydx(`x') post noestimcheck
        }
        else {
            xtreg `y' i.`x'##i.women $controls if sample_joint_m1 == 1, ///
                fe vce(cluster pid)
            margins women, dydx(`x') post noestimcheck
        }

        estimates store AME_`y'_`x'_gender

        outreg2 using "$tables/`table'_M2.doc", word `replace_or_append' ///
            ctitle("`xlab' x gender") dec(3) se ///
            alpha(0.001, 0.01, 0.05) symbol(***, **, *) ///
            label

        local replace_or_append append
    }
}

log close

* ------------------------------------------------------------------------
* 5. Formal contrasts for gender-interaction models
* ------------------------------------------------------------------------

putdocx clear
putdocx begin

putdocx paragraph, style(Title)
putdocx text ("M2: Gender interactions and contrasts")

foreach y of global outcomes {

    putdocx paragraph, style(Heading1)
    putdocx text ("Outcome: `y'")

    foreach x of global pe_all {

        local xlab "`label_`x''"

        putdocx paragraph, style(Heading2)
        putdocx text ("Indicator: `xlab'")

        if "`x'" == "relative_wage_with_unemp" {
            xtreg `y' c.`x'##i.women $controls if sample_joint_m1 == 1, ///
                fe vce(cluster pid)
            margins women, dydx(`x') post noestimcheck
        }
        else {
            xtreg `y' i.`x'##i.women $controls if sample_joint_m1 == 1, ///
                fe vce(cluster pid)
            margins `x', over(women) contrast noestimcheck
        }

        matrix M = r(table)'
        putdocx table tbl_`y'_`x' = matrix(M), rownames colnames nformat(%9.3f)
        putdocx paragraph
    }
}

putdocx save "$tables/M2_gender_contrasts.docx", replace

* ------------------------------------------------------------------------
* 6. Example coefficient plots from stored AMEs
* ------------------------------------------------------------------------

* The full paper contains extensive graphing code. This portfolio version keeps
* one compact example to show how stored margins can be turned into publication-
* style coefficient plots.

coefplot ///
    (AME_self_rated_health_contract_with_unemp_gender, ///
        keep(1.contract_with_unemp:0.women 2.contract_with_unemp:0.women) ///
        rename(1.contract_with_unemp:0.women = "Temporary" ///
               2.contract_with_unemp:0.women = "Permanent") ///
        label("Men") ///
        recast(scatter) ///
        msymbol(O) mcolor(black) mfcolor(black) ///
        ciopts(recast(rcap) lcolor(black)) ///
        offset(-0.15)) ///
    (AME_self_rated_health_contract_with_unemp_gender, ///
        keep(1.contract_with_unemp:1.women 2.contract_with_unemp:1.women) ///
        rename(1.contract_with_unemp:1.women = "Temporary" ///
               2.contract_with_unemp:1.women = "Permanent") ///
        label("Women") ///
        recast(scatter) ///
        msymbol(D) mcolor(black) mfcolor(white) ///
        ciopts(recast(rcap) lcolor(black)) ///
        offset(0.15)), ///
    horizontal noeqlabels ///
    xline(0, lpattern(dash) lcolor(gs10)) ///
    ylabel(, noticks) ///
    xtitle("Average marginal effect") ytitle("") ///
    title("Contract type and self-rated health") ///
    legend(order(2 "Men" 4 "Women") row(1) position(6) ring(1)) ///
    graphregion(color(white)) ///
    plotregion(color(white)) ///
    name(fig_contract_health, replace)

graph save "$graphs/fig_contract_health.gph", replace
graph export "$graphs/fig_contract_health.png", as(png) replace

* ------------------------------------------------------------------------
* 7. Save stored estimates
* ------------------------------------------------------------------------

estimates save "$tables/fixed_effects_estimates.ster", replace

display "Fixed-effects models, tables, contrasts, and figure exports completed successfully."

