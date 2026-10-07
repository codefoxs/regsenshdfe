*===============================================================================
* test_edge_cases.do -- FE syntax, storage precision, validation and grid checks.
* In : test/make_panel.do; test/test_regsenshdfe.do defines _rsh_equal
* Out: assertions and progress on screen; run with test/run_all.do
*===============================================================================
version 15.0
do test/make_panel.do

* 1. Heterogeneous slopes: independent explicit-dummy benchmark.
gen trend = year - 2001
* Double precision is needed for a tight comparison with upstream replacement.
recast double y x w1 w2 w0
qui regsensitivity bounds y x w1 w2 i.firm##c.trend i.year, compare(w1 w2) rxbar(0 .1 .2) table
matrix reference = e(idset_table)
qui regsenshdfe bounds y x w1 w2, absorb(firm##c.trend year) rxbar(0 .1 .2) table
matrix actual = e(idset_table)
_rsh_equal reference actual
dis as result "PASS EDGE 1: heterogeneous slopes against explicit interactions"

* 2. String FE, named FE saving and savefe must not alter original data.
tostring firm, gen(firm_string)
datasignature
local before `"`r(datasignature)'"'
qui regsenshdfe bounds y x w1 w2, absorb(firm year) rxbar(0 .1 .2) table
matrix reference = e(idset_table)
foreach fe in "firm_string year" "FE1=firm year" "firm year, savefe" {
    qui regsenshdfe bounds y x w1 w2, absorb(`fe') rxbar(0 .1 .2) table
    matrix actual = e(idset_table)
    _rsh_equal reference actual
    datasignature
    assert `"`r(datasignature)'"' == `"`before'"'
}
dis as result "PASS EDGE 2: string FE, named FE and savefe isolation"

* 3. Integer/float input storage must not round working residuals.
replace y = round(10*y)
recast int y
recast float x w1 w2
sort firm year
char y[origin] "test integer outcome"
local original_type : type y
local original_sort : sortedby
preserve
recast double y x w1 w2
qui regsensitivity bounds y x w1 w2 i.firm i.year, compare(w1 w2) rxbar(0 .1 .2) table
matrix reference = e(idset_table)
restore
datasignature
local before `"`r(datasignature)'"'
qui regsenshdfe bounds y x w1 w2, absorb(firm year) rxbar(0 .1 .2) table
matrix actual = e(idset_table)
_rsh_equal reference actual
datasignature
assert `"`r(datasignature)'"' == `"`before'"'
assert "`: type y'" == "`original_type'"
assert "`: sortedby'" == "`original_sort'"
assert "`: char y[origin]'" == "test integer outcome"
assert "`: variable label y'" == "Simulated outcome"
regsenshdfe plot, xline(1)
datasignature
assert `"`r(datasignature)'"' == `"`before'"'
dis as result "PASS EDGE 3: storage precision, metadata and bounds plot"

* 4. Upstream residual-name collision and invalid group/option inputs.
ren w1 yr
datasignature
local before `"`r(datasignature)'"'
cap regsenshdfe bounds y x yr w2, absorb(firm year) table
assert _rc == 198
datasignature
assert `"`r(datasignature)'"' == `"`before'"'
ren yr w1
foreach spec in "compare(w0)" "compare(x)" "compare(w1) nocompare(w2)" "vce(robust)" {
    cap regsenshdfe bounds y x w1 w2, absorb(firm year) `spec' table
    assert _rc == 198
}
cap regsenshdfe bounds y x, absorb(firm year)
assert _rc != 0
cap regsenshdfe bounds y x w1 w2 [aw=w0], absorb(firm year)
assert _rc != 0
cap regsenshdfe bounds y x w1 w2 i.industry, absorb(firm year)
assert _rc != 0
cap regsenshdfe unknown y x w1 w2, absorb(firm year)
assert _rc == 198
dis as result "PASS EDGE 4: name collisions and invalid specifications"

* 5. Finite rybar with cbar=0 has an analytic independent FE benchmark.
do test/make_panel.do
recast double y x w1 w2
qui regsensitivity bounds y x w1 w2 i.firm i.year, compare(w1 w2) rxbar(0 .1 .2) rybar(100) cbar(0) ngrid(3) table
matrix reference = e(idset_table)
qui regsenshdfe bounds y x w1 w2, absorb(firm year) rxbar(0 .1 .2) rybar(100) cbar(0) ngrid(3) table
matrix actual = e(idset_table)
_rsh_equal reference actual
qui regsensitivity bounds y x w1 w2 i.firm i.year, compare(w1 w2) oster delta(0 .5 1, bound) r2long(.95) maxovb(.5) table
matrix reference = e(idset_table)
qui regsenshdfe bounds y x w1 w2, absorb(firm year) oster delta(0 .5 1, bound) r2long(.95) maxovb(.5) table
matrix actual = e(idset_table)
_rsh_equal reference actual
dis as result "PASS EDGE 5: finite rybar and maxovb forwarding"
dis as result "ALL EDGE CASE TESTS PASSED"
