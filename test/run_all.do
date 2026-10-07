*===============================================================================
* run_all.do -- Run assertions and all documented examples from the repo root.
* In : test do-files and installed dependencies
* Out: screen output and in-memory graphs only
*===============================================================================
version 15.0
set more off
do test/test_regsenshdfe.do
do test/test_edge_cases.do
dis as result "COMPARED_CELLS=" rsh_cells " MAX_RELDIF=" %12.5e rsh_max_reldif
do test/examples.do
do test/bootstrap.do
dis as result "ALL TESTS AND EXAMPLES COMPLETED"
