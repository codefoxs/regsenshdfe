*===============================================================================
* test_regsenshdfe.do -- Numerical equivalence and data-safety regression tests.
* In : test/make_panel.do; installed reghdfe, ftools, regsensitivity
* Out: assertions and progress on screen; run from the repository root
*===============================================================================
version 15.0
set more off
adopath ++ "."
cap program drop regsenshdfe
cap program drop _regsenshdfe_work
scalar rsh_max_reldif = 0
scalar rsh_cells = 0
cap program drop _rsh_equal
program define _rsh_equal
    args a b
    assert rowsof(`a') == rowsof(`b') & colsof(`a') == colsof(`b')
    forvalues i = 1/`=rowsof(`a')' {
        forvalues j = 1/`=colsof(`a')' {
            scalar rsh_cells = rsh_cells + 1
            if missing(`a'[`i',`j']) | missing(`b'[`i',`j']) {
                assert `a'[`i',`j'] == `b'[`i',`j']
            }
            else {
                scalar rsh_max_reldif = max(rsh_max_reldif, reldif(`a'[`i',`j'], `b'[`i',`j']))
                assert reldif(`a'[`i',`j'], `b'[`i',`j']) < 1e-7
            }
        }
    }
end

do test/make_panel.do
* Match upstream's working precision for an independent dummy-FE oracle.
recast double y x w1 w2 w0
datasignature
local original `"`r(datasignature)'"'
unab original_vars : _all

* 1. Bounds and breakdown, DMP and Oster: compare complete result tables.
local cases = 0
foreach subcmd in bounds breakdown {
    foreach method in dmp oster {
        local opts cbar(0 .5 1)
        local tab breakfront_table
        if "`method'" == "oster" local opts r2long(.95)
        if "`subcmd'" == "bounds" {
            local tab idset_table
            local opts rxbar(0 .1 .2) cbar(1)
            if "`method'" == "oster" local opts delta(0 .5 1, eq) r2long(.95)
        }
        qui regsensitivity `subcmd' y x w1 w2 w0 i.firm i.year, compare(w1 w2) `method' `opts' table
        matrix reference = e(`tab')
        matrix refstats = e(sumstats)
        qui regsenshdfe `subcmd' y x w1 w2 w0, absorb(firm year) compare(w1 w2) `method' `opts' table
        matrix actual = e(`tab')
        matrix actstats = e(sumstats)
        _rsh_equal reference actual
        _rsh_equal refstats actstats
        assert e(N) == 600 & e(N_hdfe) == 600 & e(N_singletons) == 0
        assert "`e(cmd)'" == "regsensitivity" & "`e(cmd2)'" == "regsenshdfe"
        qui regsenshdfe `subcmd' y x w1 w2 w0, absorb(firm year) nocompare(w0) `method' `opts' table
        matrix actual = e(`tab')
        _rsh_equal reference actual
        local ++cases
    }
}
dis as result "PASS 1: four method/subcommand pairs and compare/nocompare parity"

* 2. Default calibration, FE interactions and factor prefixes.
qui regsensitivity bounds y x w1 w2 i.firm i.year#i.industry, compare(w1 w2) rxbar(0 .1 .2) table
matrix reference = e(idset_table)
qui regsenshdfe bounds y x w1 w2, absorb(i.firm year#industry) rxbar(0 .1 .2) table
matrix actual = e(idset_table)
_rsh_equal reference actual
datasignature
assert `"`r(datasignature)'"' == `"`original'"'
unab current_vars : _all
assert "`current_vars'" == "`original_vars'"
assert "`: variable label y'" == "Simulated outcome"
dis as result "PASS 2: FE interactions, default calibration and data preservation"

* 3. An independent regression verifies coefficient and within R-squared.
qui reghdfe y x w1 w2, absorb(firm year) tolerance(1e-12)
scalar refbeta = _b[x]
scalar refr2 = e(r2_within)
qui regsenshdfe bounds y x w1 w2, absorb(firm year) rxbar(0 .1) table
matrix stats = e(sumstats)
assert reldif(refbeta, stats[2,1]) < 1e-8
assert reldif(refr2, stats[4,1]) < 1e-8
dis as result "PASS 3: HDFE slope and within R-squared"

* 4. Missing controls/FE, if/in, and a singleton: use the same oracle sample.
replace w1 = . in 1
replace year = . in 11
replace firm = 999 in 22
qui reghdfe y x w1 w2 if year >= 2002 in 2/580, absorb(firm year) tolerance(1e-12)
gen selected = e(sample)
scalar refN = e(N)
scalar refsingle = e(num_singletons)
qui regsensitivity bounds y x w1 w2 i.firm i.year if selected, compare(w1 w2) rxbar(0 .1 .2) table
matrix reference = e(idset_table)
qui regsenshdfe bounds y x w1 w2 if year >= 2002 in 2/580, absorb(firm year) rxbar(0 .1 .2) table
matrix actual = e(idset_table)
_rsh_equal reference actual
assert e(N) == refN & e(N_singletons) == refsingle
assert refsingle == 1
dis as result "PASS 4: common sample, missingness and if/in"

* 5. Failing FE estimation must not lose data; upstream option errors too.
datasignature
local before `"`r(datasignature)'"'
foreach spec in "absorb(nonexistent)" "absorb(firm year) cbar(not_number)" "absorb(firm year) compare(y)" "absorb(firm year) nocompare(w1 w2)" "absorb(firm year) cluster(firm)" {
    cap regsenshdfe bounds y x w1 w2, `spec' table
    local rc = _rc
    assert `rc' != 0
    datasignature
    assert `"`r(datasignature)'"' == `"`before'"'
}
dis as result "PASS 5: errors restore data and unsupported options are rejected"

* 6. No usable observations and 32-character names fail safely.
cap regsenshdfe bounds y x w1 w2 if 0, absorb(firm year) table
assert _rc != 0
ren y abcdefghijklmnopqrstuvwxyz123456
cap regsenshdfe bounds abcdefghijklmnopqrstuvwxyz123456 x w1 w2, absorb(firm year) table
assert _rc == 198
ren abcdefghijklmnopqrstuvwxyz123456 y
datasignature
assert `"`r(datasignature)'"' == `"`before'"'
dis as result "PASS 6: empty samples and upstream name-length restriction"

* 7. Plot after data restoration and after estimates store/restore.
qui regsenshdfe bounds y x w1 w2, absorb(firm year) rxbar(0 .1 .2) table
est store rsh_saved
qui regress y x w1 w2
est restore rsh_saved
regsensitivity plot, xline(1)
qui regsenshdfe breakdown y x w1 w2, absorb(firm year) cbar(0 .5 1) plot

cap graph drop _all
dis as result "PASS 7: saved estimates and plotting"

* 8. Safe postestimation plotting, including an upstream plot error.
regsenshdfe plot
cap regsenshdfe plot, thisoptiondoesnotexist
assert _rc != 0
datasignature
assert `"`r(datasignature)'"' == `"`before'"'
dis as result "PASS 8: plot isolation and plot error recovery"
dis as result "ALL REGSENSHDFE TESTS PASSED"
