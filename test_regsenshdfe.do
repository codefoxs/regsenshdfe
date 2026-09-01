*===============================================================================
* test_regsenshdfe.do  --  Validate regsenshdfe against plain regsensitivity
*
* In  : bfg2020.dta (ships with regsensitivity, ssc install regsensitivity, all)
*       simulated two-way FE panel (generated in Test B below)
* Out : screen only
*
* Test A: single (moderate) fixed effect, state -- regsenshdfe's reghdfe
*         partialling vs regsensitivity's own i.statea dummy expansion.
*         Same fixed effect, two different computation paths -- if the
*         Frisch-Waugh-Lovell argument behind regsenshdfe is right, the
*         identified-set bounds and breakdown points should match to
*         numerical precision.
* Test B: two-way fixed effect, firm x year -- the actual motivating case
*         (this is what you can't do with plain i.firm i.year once firm
*         count gets large). Small simulated panel here so the i.-expansion
*         comparison is still feasible, just to prove the two paths agree
*         before trusting regsenshdfe on a panel too big to cross-check.
*===============================================================================

adopath + "D:/Code/VibeCoding/regsenshdfe"
cd "D:/Code/VibeCoding"
clear
capture cls


*-------------------------------------------------------------------------------
* Test A. bfg2020, single fixed effect (state, ~50 levels)
*-------------------------------------------------------------------------------

sysuse bfg2020, clear

local y  avgrep2000to2016
local x  tye_tfe890_500kNI_100_l6
local w1 log_area_2010 lat lon temp_mean rain_mean elev_mean d_coa d_riv d_lak ave_gyi

di as text _n "{hline 79}"
di as text "Test A1: regsensitivity with i.statea expanded as a dummy control"
di as text "{hline 79}"
regsensitivity bounds `y' `x' `w1' i.statea, compare(`w1') noplot
di as result "breakdown (A1, i.statea) = " e(breakdown)

di as text _n "{hline 79}"
di as text "Test A2: regsenshdfe, state partialled out via reghdfe"
di as text "{hline 79}"
regsenshdfe bounds `y' `x' `w1', absorb(statea) compare(`w1')
di as result "breakdown (A2, reghdfe absorb) = " e(breakdown)


*-------------------------------------------------------------------------------
* Test B. Simulated small panel, two-way fixed effect (firm x year)
*-------------------------------------------------------------------------------

clear
set seed 20260901
set obs 30
gen firm = _n
gen firm_fe = rnormal(0, 3)
tempfile firms
save `firms'

clear
set obs 8
gen year = 2000 + _n
gen year_fe = rnormal(0, 2)
tempfile years
save `years'

clear
set obs 240
gen firm = ceil(_n / 8)
gen t    = mod(_n - 1, 8) + 1
gen year = 1999 + t
merge m:1 firm using `firms', nogen
merge m:1 year using `years', nogen

gen double w1 = rnormal()
gen double w2 = rnormal()
gen double omitted = 0.6 * w1 + rnormal()          // correlated with w1, plays the role of the unobserved variable
gen double x  = 0.5 * w1 - 0.3 * w2 + 0.7 * omitted + firm_fe + year_fe + rnormal()
gen double y  = 1.2 * x + 0.8 * w1 + 0.4 * w2 + 1.5 * omitted + firm_fe + year_fe + rnormal()

di as text _n "{hline 79}"
di as text "Test B1: regsensitivity with i.firm i.year expanded as dummy controls"
di as text "{hline 79}"
regsensitivity bounds y x w1 w2 i.firm i.year, compare(w1 w2) noplot
di as result "breakdown (B1, i.firm i.year) = " e(breakdown)

di as text _n "{hline 79}"
di as text "Test B2: regsenshdfe, firm and year both partialled out via reghdfe"
di as text "{hline 79}"
regsenshdfe bounds y x w1 w2, absorb(firm year) compare(w1 w2)
di as result "breakdown (B2, reghdfe absorb) = " e(breakdown)

di as text _n "{hline 79}"
di as text "Test B3: regsenshdfe breakdown subcommand + oster analysis, sanity check"
di as text "{hline 79}"
regsenshdfe breakdown y x w1 w2, absorb(firm year) compare(w1 w2) oster r2long(1)
