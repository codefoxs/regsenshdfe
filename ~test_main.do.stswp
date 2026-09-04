*===============================================================================
* test_main.do  --  Omitted-variable sensitivity for the Markup ~ Score baseline
*
* In  : main.dta
* Out : screen only, plus
*         output/test_main_bounds.png   identified-set plot (DMP, full FE)
*
* Baseline being probed:
*   reghdfe Markup Score $controls, a(stkcd year#dind2) vce(cluster stkcd)
*
* stkcd has 923 levels and year#dind2 has 116, so plain regsensitivity has to
* build ~1,040 dummy columns to run this. It does manage it on this sample
* (6,822 obs), which is what makes the sample useful: sections 4 and 5 can
* compare the two computation paths on the real specification rather than on
* the simulated panel in test_regsenshdfe.do.
*
* Section 4 cross-checks the year#dind2-only specification, section 5 the full
* one. Both compare e(idset_table) element by element, not just the printed
* digits -- agreement to ~1e-11 is floating-point accumulation, not a
* difference in method.
*
* Note on clustering: regsensitivity has no vce() option. Its statistics come
* out of the OLS variance decomposition, so the vce(cluster stkcd) in the
* baseline has no counterpart here. That is a property of the method -- the
* sensitivity analysis is about the point identification of beta, not about
* its standard error -- not something regsenshdfe drops on the way through.
*===============================================================================

adopath + "D:/Code/VibeCoding/regsenshdfe"
cd "D:/Code/VibeCoding/regsenshdfe"
clear
capture cls

global output   = "D:/Code/VibeCoding/regsenshdfe/output"
global controls = "Lev Size Age Kint RDint OCF OI CEOHold Dual"

capture mkdir "$output"


*-------------------------------------------------------------------------------
* 1. Baseline reference regression  [screen only]
*-------------------------------------------------------------------------------

use "main.dta", clear

reghdfe Markup Score $controls, a(stkcd year#dind2) vce(cluster stkcd)

di as result "baseline beta(Score) = " %14.10f _b[Score] ", N = " e(N)


*-------------------------------------------------------------------------------
* 2. DMP identified set over rxbar, full fixed effects
*-------------------------------------------------------------------------------

use "main.dta", clear

regsenshdfe bounds Markup Score $controls, ///
        absorb(stkcd year#dind2) compare($controls) noplot

di as result "breakdown point (DMP, rybar=+inf, cbar=1) = " %14.10f e(breakdown)

regsensitivity plot, xline(1)
graph export "$output/test_main_bounds.png", replace width(1600)


*-------------------------------------------------------------------------------
* 3. Breakdown frontier over cbar, and the Oster framework for contrast
*-------------------------------------------------------------------------------

use "main.dta", clear

regsenshdfe breakdown Markup Score $controls, ///
        absorb(stkcd year#dind2) compare($controls) cbar(0(.2)1)

use "main.dta", clear

regsenshdfe breakdown Markup Score $controls, ///
        absorb(stkcd year#dind2) compare($controls) oster r2long(1)


*-------------------------------------------------------------------------------
* 4. Cross-check, year#dind2 only: native i.-expansion vs reghdfe partialling
*-------------------------------------------------------------------------------

use "main.dta", clear

qui regsensitivity bounds Markup Score $controls i.year#i.dind2, ///
        compare($controls) noplot
matrix N = e(idset_table)
scalar bd_n = e(breakdown)

use "main.dta", clear

qui regsenshdfe bounds Markup Score $controls, ///
        absorb(year#dind2) compare($controls) noplot
matrix H = e(idset_table)
scalar bd_h = e(breakdown)

matrix D = N - H
mata: st_numscalar("maxabs", max(abs(st_matrix("D"))))

di as text _n "{hline 79}"
di as text "4. Cross-check, absorb(year#dind2)"
di as text "{hline 79}"
di as result "breakdown   native = " %14.10f bd_n "   hdfe = " %14.10f bd_h
di as result "            |diff| = " %14.10e abs(bd_n - bd_h)
di as result "idset_table " rowsof(N) " x " colsof(N) ", max|diff| = " %14.10e maxabs


*-------------------------------------------------------------------------------
* 5. Cross-check, full fixed effects: the ~1,040-dummy expansion vs reghdfe
*-------------------------------------------------------------------------------

timer clear

use "main.dta", clear

timer on 1
qui regsensitivity bounds Markup Score $controls i.stkcd i.year#i.dind2, ///
        compare($controls) noplot
timer off 1
matrix N = e(idset_table)
scalar bd_n = e(breakdown)

use "main.dta", clear

timer on 2
qui regsenshdfe bounds Markup Score $controls, ///
        absorb(stkcd year#dind2) compare($controls) noplot
timer off 2
matrix H = e(idset_table)
scalar bd_h = e(breakdown)

matrix D = N - H
mata: st_numscalar("maxabs", max(abs(st_matrix("D"))))

di as text _n "{hline 79}"
di as text "5. Cross-check, absorb(stkcd year#dind2)"
di as text "{hline 79}"
di as result "breakdown   native = " %14.10f bd_n "   hdfe = " %14.10f bd_h
di as result "            |diff| = " %14.10e abs(bd_n - bd_h)
di as result "idset_table " rowsof(N) " x " colsof(N) ", max|diff| = " %14.10e maxabs
di as text _n "timings (1 = native expansion, 2 = regsenshdfe):"
timer list
