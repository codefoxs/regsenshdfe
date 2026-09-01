*! regsenshdfe v0.1  2026-09-01
*! Extends regsensitivity (Masten & Poirier 2026 AER) to (high-dimensional)
*! fixed effects by partialling them out via reghdfe before handing the
*! residualized variables to regsensitivity. Not an official package.
*!
*! Idea: regsensitivity's own DMP/Oster calculations are built on plain
*! `regress`, so factor-variable fixed effects (i.firm i.year ...) get
*! literally expanded into dummy columns -- fine for a few dozen levels
*! (e.g. state), infeasible for firm/firm-year panels. reghdfe's demeaning
*! algorithm scales to that, and by the Frisch-Waugh-Lovell theorem,
*! residualizing y, x, and every control against the same fixed effects
*! and then running the sensitivity analysis on the residuals reproduces
*! the same coefficients/R^2 that a single regression with the fixed
*! effects included as covariates would give.

program define regsenshdfe, eclass
    version 14.0

    gettoken subcmd 0 : 0, parse(" ,")
    local subcmd = lower("`subcmd'")
    if !inlist("`subcmd'", "bounds", "breakdown") {
        di as error "regsenshdfe: first word must be {bf:bounds} or {bf:breakdown} (regsensitivity's own subcommands)"
        exit 198
    }

    syntax varlist(min=2 numeric) [if] [in], ABSorb(string) ///
        [COMpare(varlist numeric) NOCOMpare(varlist numeric) *]

    if "`compare'" != "" & "`nocompare'" != "" {
        di as error "regsenshdfe: specify compare() or nocompare(), not both"
        exit 198
    }

    cap which reghdfe
    if _rc {
        di as error "regsenshdfe requires {bf:reghdfe}. Install with: ssc install reghdfe"
        exit 601
    }
    cap which regsensitivity
    if _rc {
        di as error "regsenshdfe requires {bf:regsensitivity}. Install with: ssc install regsensitivity"
        exit 601
    }

    marksample touse
    markout `touse' `absorb'

    tokenize `varlist'
    local depvar   `1'
    local indepvar `2'
    macro shift 2
    local controls `*'

    if "`controls'" == "" {
        di as error "regsenshdfe: need at least one control variable"
        exit 198
    }

    local allvars `depvar' `indepvar' `controls'
    local n : word count `allvars'

    * --- compare()/nocompare() must be a subset of the controls just listed ---
    foreach cv of local compare {
        local pos : list posof "`cv'" in allvars
        if `pos' == 0 {
            di as error "regsenshdfe: compare() variable `cv' is not in the depvar/indepvar/controls list"
            exit 198
        }
    }
    foreach cv of local nocompare {
        local pos : list posof "`cv'" in allvars
        if `pos' == 0 {
            di as error "regsenshdfe: nocompare() variable `cv' is not in the depvar/indepvar/controls list"
            exit 198
        }
    }

    * --- partial each variable out of the fixed effects with reghdfe ---
    di as text "{hline 79}"
    di as text "regsenshdfe: absorbing `absorb' via reghdfe (`n' variables), then calling"
    di as text "             regsensitivity `subcmd' on the residuals"
    di as text "{hline 79}"

    forvalues i = 1/`n' {
        local v`i' : word `i' of `allvars'
        tempvar r`i'
        quietly reghdfe `v`i'' if `touse', absorb(`absorb') residuals(`r`i'')
        local rname`i' `r`i''
    }

    local r_depvar   `rname1'
    local r_indepvar `rname2'
    local r_controls
    forvalues i = 3/`n' {
        local r_controls `r_controls' `rname`i''
    }

    local compare_opt
    if "`compare'" != "" {
        local r_compare
        foreach cv of local compare {
            local pos : list posof "`cv'" in allvars
            local r_compare `r_compare' `rname`pos''
        }
        local compare_opt compare(`r_compare')
    }
    if "`nocompare'" != "" {
        local r_nocompare
        foreach cv of local nocompare {
            local pos : list posof "`cv'" in allvars
            local r_nocompare `r_nocompare' `rname`pos''
        }
        local compare_opt nocompare(`r_nocompare')
    }

    * --- hand off to the real command on the residualized variables ---
    regsensitivity `subcmd' `r_depvar' `r_indepvar' `r_controls' if `touse', `compare_opt' `options'

end
