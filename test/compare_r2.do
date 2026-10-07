*===============================================================================
* compare_r2.do -- Explicit FE checks for the README R-squared comparison.
* In : test/make_panel.do and installed dependencies
* Out: coefficients, R-squared, and sensitivity comparisons on screen
*===============================================================================
version 15.0
set more off
adopath ++ "."
do test/make_panel.do
* Upstream replaces analysis variables in place. Preserve residual precision.
recast double y x w1 w2

qui regress y x w1 w2 i.firm i.year
scalar b_dummy = _b[x]
scalar r2_dummy = e(r2)
scalar n_dummy = e(N)
qui reghdfe y x w1 w2, absorb(firm year) tolerance(1e-12)
scalar b_hdfe = _b[x]
scalar r2_hdfe = e(r2)
scalar r2_within = e(r2_within)
assert e(N) == n_dummy
assert reldif(b_dummy,b_hdfe) < 1e-8
assert reldif(r2_dummy,r2_hdfe) < 1e-8
matrix regression_check = (b_dummy,r2_dummy,. \ b_hdfe,r2_hdfe,r2_within)
matrix rownames regression_check = regress_dummies reghdfe_absorb
matrix colnames regression_check = beta overall_R2 within_R2
matrix list regression_check, format(%12.8f)

* Explicit comparison controls are essential: FE stay outside the benchmark.
qui regsensitivity bounds y x w1 w2 i.firm i.year, compare(w1 w2) rxbar(0 0.1 0.2 0.3) table
matrix native_stats = e(sumstats)
matrix native_bounds = e(idset_table)
scalar native_bd = e(breakdown)
qui regsenshdfe bounds y x w1 w2, absorb(firm year) compare(w1 w2) rxbar(0 0.1 0.2 0.3) table
matrix hdfe_stats = e(sumstats)
matrix hdfe_bounds = e(idset_table)
scalar hdfe_bd = e(breakdown)
assert e(N) == n_dummy
matrix stats_difference = native_stats - hdfe_stats
matrix bounds_difference = native_bounds - hdfe_bounds
mata: st_numscalar("stats_max_abs",max(abs(st_matrix("stats_difference"))))
mata: st_numscalar("bounds_max_abs",max(abs(st_matrix("bounds_difference"))))
assert stats_max_abs < 1e-7 & bounds_max_abs < 1e-7
assert reldif(native_bd,hdfe_bd) < 1e-7
assert reldif(hdfe_stats[4,1],r2_within) < 1e-8
matrix sensitivity_check = (native_stats[2,1],native_stats[3,1],native_stats[4,1],native_bd \ hdfe_stats[2,1],hdfe_stats[3,1],hdfe_stats[4,1],hdfe_bd)
matrix rownames sensitivity_check = native_FE_excluded hdfe_wrapper
matrix colnames sensitivity_check = beta R2_short R2_medium DMP_breakdown
matrix list sensitivity_check, format(%12.8f)
dis "STATS_MAX_ABS_DIFF=" %12.5e stats_max_abs
dis "BOUNDS_MAX_ABS_DIFF=" %12.5e bounds_max_abs

* Omitting compare() in the native command puts the FE into the benchmark.
qui regsensitivity bounds y x w1 w2 i.firm i.year, rxbar(0 0.1 0.2 0.3) table
matrix all_controls = e(sumstats)
scalar all_bd = e(breakdown)
assert reldif(all_controls[4,1],r2_dummy) < 1e-8
matrix calibration_check = (hdfe_stats[2,1],hdfe_stats[4,1],hdfe_bd \ all_controls[2,1],all_controls[4,1],all_bd)
matrix rownames calibration_check = FE_excluded FE_included
matrix colnames calibration_check = beta R2_medium DMP_breakdown
matrix list calibration_check, format(%12.8f)

* Oster also matches when FE are excluded and R2long uses the same scale.
qui regsensitivity bounds y x w1 w2 i.firm i.year, compare(w1 w2) oster delta(0 0.5 1, eq) r2long(1.3, relative) table
matrix native_oster = e(idset_table)
qui regsenshdfe bounds y x w1 w2, absorb(firm year) compare(w1 w2) oster delta(0 0.5 1, eq) r2long(1.3, relative) table
matrix hdfe_oster = e(idset_table)
assert rowsof(native_oster) == rowsof(hdfe_oster)
assert colsof(native_oster) == colsof(hdfe_oster)
forvalues i = 1/`=rowsof(native_oster)' {
    forvalues j = 1/`=colsof(native_oster)' {
        if missing(native_oster[`i',`j']) | missing(hdfe_oster[`i',`j']) {
            assert native_oster[`i',`j'] == hdfe_oster[`i',`j']
        }
    }
}
matrix oster_difference = native_oster - hdfe_oster
mata: st_numscalar("oster_max_abs",max(abs(st_matrix("oster_difference"))))
assert oster_max_abs < 1e-7
matrix list native_oster, format(%12.8f)
matrix list hdfe_oster, format(%12.8f)
dis "OSTER_MAX_ABS_DIFF=" %12.5e oster_max_abs
dis "R2LONG_RELATIVE=" %12.8f (1.3*r2_within)
dis "R2_COMPARISON_PASSED"
