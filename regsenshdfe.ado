*! regsenshdfe 0.4.0  08oct2026
*! HDFE partialling-out wrapper for regsensitivity; independent extension.
program define regsenshdfe, eclass
    version 15.0
    local call `"regsenshdfe `0'"'
    gettoken subcmd 0 : 0, parse(" ,")
    local subcmd = lower("`subcmd'")
    if "`subcmd'" == "plot" {
        if "`e(cmd2)'" != "regsenshdfe" {
            dis as error "run regsenshdfe bounds or breakdown before regsenshdfe plot"
            exit 301
        }
        preserve
        qui clear
        * The upstream bounds plot saves the active dataset before clearing it.
        tempvar placeholder
        qui set obs 1
        qui gen `placeholder' = 0
        cap noisily regsensitivity plot `0'
        local rc = _rc
        restore
        exit `rc'
    }
    if !inlist("`subcmd'", "bounds", "breakdown") {
        dis as error "first word must be bounds, breakdown, or plot"
        exit 198
    }

    syntax varlist(min=3 numeric) [if] [in], ABSorb(string) ///
        [COMpare(varlist numeric) NOCOMpare(varlist numeric) ///
         DMP OSTER RXbar(string) RYbar(string) Cbar(string) ///
         DELta(string) R2long(string) BETA(string) MAXOVB(string) ///
         NGRID(integer -1) NOPROduct PLOT TABLE NOPLOT]

    if "`compare'" != "" & "`nocompare'" != "" {
        dis as error "specify compare() or nocompare(), not both"
        exit 198
    }
    gettoken depvar controls : varlist
    gettoken indepvar controls : controls
    local duplicates : list dups varlist
    if "`duplicates'" != "" {
        dis as error "outcome, treatment, and controls must be distinct variables"
        exit 198
    }
    foreach group in compare nocompare {
        local invalid : list `group' - controls
        if "`invalid'" != "" {
            dis as error "`group'() must contain only variables listed in controls: `invalid'"
            exit 198
        }
    }
    local comparison `controls'
    if "`compare'" != "" local comparison `compare'
    if "`nocompare'" != "" local comparison : list controls - nocompare
    if "`comparison'" == "" {
        dis as error "at least one comparison control is required"
        exit 198
    }
    * Upstream appends r to variable names when constructing residuals.
    foreach v of local varlist {
        if strlen("`v'") > 31 {
            dis as error "regsensitivity requires analysis variable names of at most 31 characters: `v'"
            exit 198
        }
    }
    foreach dependency in reghdfe regsensitivity {
        cap which `dependency'
        if _rc {
            dis as error "`dependency' is required; see help regsenshdfe for installation"
            exit 601
        }
    }

    local options `dmp' `oster' `noproduct' `plot' `table' `noplot'
    foreach opt in compare nocompare rxbar rybar cbar delta r2long beta maxovb {
        if "``opt''" != "" local options `options' `opt'(``opt'')
    }
    if `ngrid' != -1 local options `options' ngrid(`ngrid')

    * Enclose every destructive operation, including errors from reghdfe.
    preserve
    cap noisily _regsenshdfe_work `subcmd' `varlist' `if' `in', absorb(`absorb') `options'
    local rc = _rc
    restore
    if `rc' {
        ereturn clear
        exit `rc'
    }
    * Leave e(cmd) and upstream plot metadata intact.
    ereturn local cmd2 "regsenshdfe"
    ereturn local cmdline_hdfe `"`call'"'
    ereturn local absorb `"`absorb'"'
    ereturn local version_hdfe "0.4.0"
end

program define _regsenshdfe_work, eclass
    version 15.0
    gettoken subcmd 0 : 0
    syntax varlist(min=3 numeric) [if] [in], ABSorb(string) [PLOT *]
    marksample touse
    * Let reghdfe parse FE syntax and determine joint missingness/singletons.
    unab before : _all
    qui reghdfe `varlist' if `touse', absorb(`absorb') tolerance(1e-12)
    * FE-saving options may create named variables on each projection.
    unab after : _all
    local generated : list after - before
    if "`generated'" != "" drop `generated'
    qui replace `touse' = e(sample)
    local n_singletons = e(num_singletons)
    qui count if `touse'
    local n_hdfe = r(N)

    * Project all variables before replacing any FE or slope input. Double
    * residuals avoid rounding to the original float/integer storage types.
    local residuals
    foreach v of local varlist {
        tempvar residual
        unab before : _all
        qui reghdfe `v' if `touse', absorb(`absorb') residuals(`residual') tolerance(1e-12)
        unab after : _all
        local generated : list after - before
        local generated : list generated - residual
        if "`generated'" != "" drop `generated'
        local residuals `residuals' `residual'
    }
    qui keep if `touse'
    keep `residuals'
    local i = 0
    foreach v of local varlist {
        local ++i
        local residual : word `i' of `residuals'
        ren `residual' `v'
    }
    * Upstream creates <name>r temporarily. Detect overlapping names rather
    * than allowing an opaque "variable already defined" error downstream.
    foreach v of local varlist {
        local residual_name `v'r
        local collision : list residual_name in varlist
        if `collision' {
            dis as error "rename `residual_name': it conflicts with regsensitivity's residual naming"
            exit 198
        }
    }
    local plotopt `plot'
    if "`subcmd'" == "breakdown" local plotopt
    regsensitivity `subcmd' `varlist', `options' `plotopt'
    if "`subcmd'" == "breakdown" & "`plot'" != "" {
        * Upstream breakdown plots create variables literally named x and y.
        * Plot in empty working data to avoid collisions with analysis names.
        qui clear
        regsensitivity plot
    }
    ereturn scalar N_hdfe = `n_hdfe'
    ereturn scalar N_singletons = `n_singletons'
end
