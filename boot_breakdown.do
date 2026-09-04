*===============================================================================
* boot_breakdown.do  --  Firm-clustered bootstrap of the DMP breakdown point
*
* In  : main.dta
* Out : boot_breakdown.dta   one row per replicate
*       screen summary
*
* regsensitivity has no vce() option and reports no confidence intervals: its
* bounds and breakdown point are deterministic functions of the sample second
* moments of (Y, X, W), so heteroskedasticity- or cluster-robust variance
* assumptions cannot enter them. That does not make the breakdown point free
* of sampling error -- it is still an estimate. This file resamples firms with
* replacement and recomputes the whole thing on each draw, which is the only
* way to get firm-clustered uncertainty into a number this package produces.
*
* bsample's idcluster(bootid) matters: a firm drawn twice must enter as two
* separate fixed effects, otherwise the resampled panel's within-firm variation
* is not what the bootstrap is supposed to be mimicking. absorb() therefore
* uses bootid, not stkcd.
*
* Reported at the end: the percentile interval, and the share of replicates
* whose breakdown point exceeds 1 -- rxbar = 1 is the "unobservable as strong
* as the observables" reference line, so that share is the closest thing here
* to "how confident can I be that the sign survives that benchmark".
*===============================================================================

adopath + "D:/Code/VibeCoding/regsenshdfe"
cd "D:/Code/VibeCoding/regsenshdfe"
clear
capture cls

global controls = "Lev Size Age Kint RDint OCF OI CEOHold Dual"

local B = 500
set seed 20260904


*-------------------------------------------------------------------------------
* 1. Point estimate on the original sample
*-------------------------------------------------------------------------------

use "main.dta", clear

qui regsenshdfe bounds Markup Score $controls, ///
        absorb(stkcd year#dind2) compare($controls) noplot
scalar bd_hat = e(breakdown)

qui reghdfe Markup Score $controls, a(stkcd year#dind2) vce(cluster stkcd)
scalar b_hat = _b[Score]

di as result "point estimates: beta = " %12.8f b_hat ", breakdown = " %12.8f bd_hat


*-------------------------------------------------------------------------------
* 2. Firm-clustered bootstrap
*-------------------------------------------------------------------------------

capture postclose bootres
postfile bootres int rep double(beta breakdown) using "boot_breakdown.dta", replace

forvalues r = 1/`B' {

    quietly {
        use "main.dta", clear
        bsample, cluster(stkcd) idcluster(bootid)

        capture reghdfe Markup Score $controls, a(bootid year#dind2)
        local b = cond(_rc, ., _b[Score])

        capture regsenshdfe bounds Markup Score $controls, ///
                absorb(bootid year#dind2) compare($controls) noplot
        local d = cond(_rc, ., e(breakdown))

        post bootres (`r') (`b') (`d')
    }

    if mod(`r', 50) == 0 di as text "  ... replicate `r' of `B'"
}

postclose bootres


*-------------------------------------------------------------------------------
* 3. Summary  [screen only]
*-------------------------------------------------------------------------------

use "boot_breakdown.dta", clear

count if missing(breakdown)
local nfail = r(N)

sum breakdown, detail
local p025 = r(p1)
_pctile breakdown, p(2.5 50 97.5)
local lo  = r(r1)
local med = r(r2)
local hi  = r(r3)
sum breakdown
local sd = r(sd)

count if breakdown > 1 & !missing(breakdown)
local n_above = r(N)
count if !missing(breakdown)
local n_ok = r(N)

sum beta
local beta_sd = r(sd)
count if beta > 0 & !missing(beta)
local n_wrongsign = r(N)

di as text _n "{hline 79}"
di as text "Firm-clustered bootstrap, `B' replicates (`nfail' failed)"
di as text "{hline 79}"
di as result "breakdown  point est.   = " %8.4f bd_hat
di as result "           boot median  = " %8.4f `med'
di as result "           boot SD      = " %8.4f `sd'
di as result "           95% pctile   = [" %8.4f `lo' ", " %8.4f `hi' "]"
di as result "           share > 1    = " %6.2f 100 * `n_above' / `n_ok' "%"
di as text   ""
di as result "beta       point est.   = " %10.6f b_hat
di as result "           boot SD      = " %10.6f `beta_sd'
di as result "           share > 0    = " %6.2f 100 * `n_wrongsign' / `n_ok' "%"
