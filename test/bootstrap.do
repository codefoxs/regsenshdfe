*===============================================================================
* bootstrap.do -- Illustrative firm-cluster bootstrap of a DMP breakdown point.
* In : test/make_panel.do; installed dependencies
* Out: bootstrap table on screen, no persisted data
* This small replication count is for demonstration, not publication inference.
*===============================================================================
version 15.0
set more off
adopath ++ "."
do test/make_panel.do

cap program drop _rsh_boot
program define _rsh_boot, rclass
    * Repeated draws of one firm need distinct FE identifiers.
    qui regsenshdfe bounds y x w1 w2, absorb(bootfirm year) rxbar(0 .1 .2) table
    return scalar breakdown = e(breakdown)
end
bootstrap breakdown=r(breakdown), reps(20) seed(20261008) cluster(firm) idcluster(bootfirm) nodots: _rsh_boot
