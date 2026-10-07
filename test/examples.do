*===============================================================================
* examples.do -- All README/help examples on reproducible simulated data.
* In : test/make_panel.do; installed dependencies
* Out: tables and graphs in memory; run from the repository root
*===============================================================================
version 15.0
set more off
adopath ++ "."
do test/make_panel.do
* Match the precision used for direct native-command comparisons.
recast double y x w1 w2

* 1. DMP bounds with all controls as the comparison group.
regsenshdfe bounds y x w1 w2, absorb(firm year) rxbar(0 .1 .2 .3) table
regsenshdfe plot, xline(1)

* 2. Keep w0 in the model without using it to calibrate selection.
regsenshdfe bounds y x w1 w2 w0, absorb(firm year) compare(w1 w2) rxbar(0 .1 .2) table
regsenshdfe bounds y x w1 w2 w0, absorb(firm year) nocompare(w0) rxbar(0 .1 .2) table

* 3. DMP breakdown frontier and an alternative coefficient hypothesis.
regsenshdfe breakdown y x w1 w2, absorb(firm year) cbar(0(.2)1) plot
regsenshdfe breakdown y x w1 w2, absorb(firm year) beta(.2, lb) cbar(1) table

* 4. Oster equality and bounded-delta analyses on the residualized R2 scale.
regsenshdfe bounds y x w1 w2, absorb(firm year) oster delta(0 .5 1, eq) r2long(1.3, relative) table
regsenshdfe bounds y x w1 w2, absorb(firm year) oster delta(0 .5 1, bound) r2long(.95) table
regsenshdfe breakdown y x w1 w2, absorb(firm year) oster r2long(1.3, relative) beta(0, eq) table
regsenshdfe breakdown y x w1 w2, absorb(firm year) oster r2long(1.3, relative) beta(sign) table
regsenshdfe breakdown y x w1 w2, absorb(firm year) oster r2long(.8 .9 1) beta(0, eq) plot
regsenshdfe breakdown y x w1 w2, absorb(firm year) oster r2long(.8 .9 1) beta(sign) table

* 5. Interacted FE and sample restrictions; FE are always conditioned on.
regsenshdfe bounds y x w1 w2 if year >= 2003 in 1/500, absorb(firm year#industry) rxbar(0 .1 .2) table

* 6. Parameter grids: tuples instead of a Cartesian product.
regsenshdfe bounds y x w1 w2, absorb(firm year) rxbar(0 .1 .2) cbar(0 .5 1) noproduct ngrid(3) table
regsenshdfe bounds y x w1 w2, absorb(firm year) rxbar(0 .2) ngrid(3) table

* 7. Saved results remain compatible with upstream plotting.
est store sensitivity_model
matrix bounds = e(idset_table)
matrix summary = e(sumstats)
regsenshdfe plot, xline(1)
