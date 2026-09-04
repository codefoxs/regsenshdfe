*===============================================================================
* oster_within.do  --  Oster (2019) bounds on the within scale, both FE as nuisance
*
* In  : main.dta
* Out : screen only
*
* The choice this file makes, and why it has to be stated rather than assumed:
* psacalc supports two readings of a fixed effect. After xtreg, fe it treats
* individual effects as nuisance parameters and works off the differenced
* R-squared; after areg it treats them as control variables and works off the
* R-squared including the indicators. Both are documented, neither is "the"
* correct one.
*
* Here both stkcd and year#dind2 are treated as nuisance: y, x and every
* control are residualized on them with reghdfe first, and Oster's formula is
* applied to the residuals. Three reasons, none of them a rule handed down by
* the paper:
*   - Oster on Olken and Barron's trip fixed effects: "there is no sense in
*     which such fixed effects are a proxy for some unobserved omitted
*     control." They are not the kind of control delta benchmarks against.
*   - The controls whose selection delta compares to should be the nine
*     economic controls, not 923 firm dummies plus 115 industry-year cells.
*   - On the total scale R2(medium) is 0.816, so Oster's Pi = 1.3 rule gives
*     R_max = 1.06 and has to be capped at 1 -- which is exactly the AET
*     assumption Oster's paper argues against ("their assumption that
*     including the unobservables would produce an R-squared of 1 may
*     understate the robustness of results").
*
* The flip side is stated in the output rather than hidden: on the within
* scale R2(medium) is only 0.028, so Pi = 1.3 gives R_max = 0.036, and a
* small R_max mechanically inflates delta. That is why section 3 reports
* delta across a range of R_max instead of a single number, and reports the
* R_max at which delta falls to 1.
*===============================================================================

adopath + "D:/Code/VibeCoding/regsenshdfe"
cd "D:/Code/VibeCoding/regsenshdfe"
clear
capture cls

global controls = "Lev Size Age Kint RDint OCF OI CEOHold Dual"


*-------------------------------------------------------------------------------
* 1. Residualize on both fixed effects, then the short and medium regressions
*-------------------------------------------------------------------------------

use "main.dta", clear

batch Markup Score $controls, f(qui reghdfe @, a(stkcd year#dind2) resid(r_@))

local rc
foreach v in $controls {
    local rc `rc' r_`v'
}

qui regress r_Markup r_Score
scalar b_short  = _b[r_Score]
scalar r2_short = e(r2)

qui regress r_Markup r_Score `rc'
scalar b_med  = _b[r_Score]
scalar r2_med = e(r2)

di as text _n "{hline 79}"
di as text "1. Inputs, both fixed effects partialled out"
di as text "{hline 79}"
di as result "beta(short)  = " %12.8f b_short "    R2(short)  = " %8.6f r2_short
di as result "beta(medium) = " %12.8f b_med   "    R2(medium) = " %8.6f r2_med
di as result "Oster's Pi = 1.3 rule:  R_max = " %8.6f 1.3 * r2_med


*-------------------------------------------------------------------------------
* 2. Headline numbers at Oster's own bounding values
*-------------------------------------------------------------------------------

di as text _n "{hline 79}"
di as text "2. delta at beta = 0, and beta at delta = 1, with R_max = 1.3 x R2(medium)"
di as text "{hline 79}"

psacalc delta r_Score, beta(0) rmax(`=1.3 * r2_med')
psacalc beta  r_Score, delta(1) rmax(`=1.3 * r2_med')


*-------------------------------------------------------------------------------
* 3. Sensitivity to R_max -- the number the conclusion actually hinges on
*-------------------------------------------------------------------------------

local grid 0.0363 0.05 0.075 0.10 0.15 0.20 0.30 0.50 0.75 1.00

local nr : word count `grid'
matrix T = J(`nr', 4, .)
matrix colnames T = R_max R_max_over_R2med delta_at_beta0 beta_at_delta1

local i = 1
foreach m of local grid {
    qui psacalc delta r_Score, beta(0) rmax(`m')
    matrix T[`i', 3] = r(delta)
    qui psacalc beta r_Score, delta(1) rmax(`m')
    matrix T[`i', 4] = r(beta)
    matrix T[`i', 1] = `m'
    matrix T[`i', 2] = `m' / r2_med
    local ++i
}

di as text _n "{hline 79}"
di as text "3. Oster bounds across R_max"
di as text "{hline 79}"
di as text "   R_max   R_max/R2(med)   delta(beta=0)   beta(delta=1)"
forvalues r = 1/`nr' {
    di as result "  " %6.4f T[`r',1] "      " %8.2f T[`r',2] "      " %10.4f T[`r',3] "      " %12.8f T[`r',4]
}


*-------------------------------------------------------------------------------
* 4. The R_max at which delta falls to 1  [screen only]
*-------------------------------------------------------------------------------

local lo = r2_med
local hi = 1
forvalues it = 1/60 {
    local mid = (`lo' + `hi') / 2
    qui psacalc delta r_Score, beta(0) rmax(`mid')
    if r(delta) > 1 local lo = `mid'
    else            local hi = `mid'
}

di as text _n "{hline 79}"
di as text "4. Where equal selection becomes enough"
di as text "{hline 79}"
di as result "delta = 1 requires R_max = " %8.6f `mid' "  (= " %6.2f `mid' / r2_med " x R2(medium))"
di as text   "i.e. the unobservables would have to raise the within R-squared from"
di as result "     " %6.4f r2_med " to " %6.4f `mid' " before equal selection drives beta to zero."
