*! regsenshdfe v0.3  2026-09-04
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
*!
*! v0.3: absorb() is parsed down to its underlying variable names before
*! markout, so interactions (year#dind2), factor prefixes (i.firm) and
*! FE-saving names (FE1=firm) -- all legal in reghdfe's absorb(), none of
*! them a legal varlist -- no longer break sample marking.
*!
*! v0.2: each variable is residualized IN PLACE under its own original
*! name (original values stashed to a tempvar, restored on exit) instead
*! of a throwaway tempvar, so regsensitivity's own output shows the real
*! variable names (Treatment/Outcome/table headers) instead of __000001-
*! style placeholders. The dataset is left exactly as it was found,
*! whether or not the regsensitivity call succeeds.

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

    * --- strip absorb() down to plain variable names for markout ---
    * absorb() is reghdfe's own syntax: interactions (year#dind2), factor
    * prefixes (i.firm), FE-saving names (FE1=firm) and trailing options
    * (, savefe) are all legal there, and none of them parse as the plain
    * varlist markout wants. Anything left that isn't a numeric variable is
    * skipped here and left for reghdfe to complain about properly.
    local absspec `absorb'
    local cpos = strpos("`absspec'", ",")
    if `cpos' local absspec = substr("`absspec'", 1, `cpos' - 1)
    local absspec : subinstr local absspec "##" " ", all
    local absspec : subinstr local absspec "#" " ", all

    local absvars
    foreach tok of local absspec {
        local epos = strpos("`tok'", "=")
        if `epos' local tok = substr("`tok'", `epos' + 1, .)
        local dpos = strrpos("`tok'", ".")
        if `dpos' local tok = substr("`tok'", `dpos' + 1, .)
        capture confirm numeric variable `tok'
        if !_rc local absvars `absvars' `tok'
    }
    markout `touse' `absvars'

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

    * --- compare()/nocompare() must be a subset of the controls just listed ---
    local dupcheck : list dups allvars
    if "`dupcheck'" != "" {
        di as error "regsenshdfe: `dupcheck' appears more than once in depvar/indepvar/controls"
        exit 198
    }
    foreach cv of local compare {
        local ok : list cv in allvars
        if !`ok' {
            di as error "regsenshdfe: compare() variable `cv' is not in the depvar/indepvar/controls list"
            exit 198
        }
    }
    foreach cv of local nocompare {
        local ok : list cv in allvars
        if !`ok' {
            di as error "regsenshdfe: nocompare() variable `cv' is not in the depvar/indepvar/controls list"
            exit 198
        }
    }

    di as text "{hline 79}"
    di as text "regsenshdfe: absorbing `absorb' via reghdfe, then calling regsensitivity `subcmd'"
    di as text "{hline 79}"

    * --- residualize each variable IN PLACE, keeping its original name ---
    * stash the raw values under a tempvar, then let reghdfe write the
    * residual back under the original variable name -- regsensitivity's
    * own display then shows real variable names, not placeholders.
    foreach v of local allvars {
        tempvar orig_`v'
        rename `v' `orig_`v''
        quietly reghdfe `orig_`v'' if `touse', absorb(`absorb') residuals(`v')
    }

    local compare_opt
    if "`compare'"   != "" local compare_opt compare(`compare')
    if "`nocompare'" != "" local compare_opt nocompare(`nocompare')

    capture noisily regsensitivity `subcmd' `depvar' `indepvar' `controls' if `touse', `compare_opt' `options'
    local rc = _rc

    * --- restore the dataset to exactly how it was found, success or not ---
    foreach v of local allvars {
        drop `v'
        rename `orig_`v'' `v'
    }

    if `rc' {
        exit `rc'
    }

end
