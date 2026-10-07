* README output capture. Run from the repository root.
* Output markers delimit verbatim documentation excerpts.
version 15.0
set more off
set linesize 120
adopath ++ "."
do test/make_panel.do
* Preserve precision when the upstream command replaces working variables.
recast double y x w1 w2

dis "BEGIN_README_dmp_bounds"
regsenshdfe bounds y x w1 w2, absorb(firm year) compare(w1 w2) rxbar(0 0.1 0.2 0.3) table
dis "END_README_dmp_bounds"

dis "BEGIN_README_dmp_breakdown"
regsenshdfe breakdown y x w1 w2, absorb(firm year) compare(w1 w2) cbar(0(0.2)1) plot
dis "END_README_dmp_breakdown"

dis "BEGIN_README_dmp_beta"
regsenshdfe breakdown y x w1 w2, absorb(firm year) compare(w1 w2) beta(0.2, lb) cbar(1) table
dis "END_README_dmp_beta"

dis "BEGIN_README_oster_eq"
regsenshdfe bounds y x w1 w2, absorb(firm year) compare(w1 w2) oster delta(0 0.5 1, eq) r2long(1.3, relative) table
dis "END_README_oster_eq"

dis "BEGIN_README_oster_bound"
regsenshdfe bounds y x w1 w2, absorb(firm year) compare(w1 w2) oster delta(0 0.5 1, bound) r2long(0.95) table
dis "END_README_oster_bound"

dis "BEGIN_README_oster_zero"
regsenshdfe breakdown y x w1 w2, absorb(firm year) compare(w1 w2) oster r2long(1.3, relative) beta(0, eq) table
dis "END_README_oster_zero"

dis "BEGIN_README_oster_sign"
regsenshdfe breakdown y x w1 w2, absorb(firm year) compare(w1 w2) oster r2long(1.3, relative) beta(sign) table
dis "END_README_oster_sign"

dis "BEGIN_README_compare"
regsenshdfe bounds y x w1 w2 w0, absorb(firm year) compare(w1 w2) rxbar(0 0.1 0.2) table
dis "END_README_compare"

dis "BEGIN_README_nocompare"
regsenshdfe bounds y x w1 w2 w0, absorb(firm year) nocompare(w0) rxbar(0 0.1 0.2) table
dis "END_README_nocompare"

dis "BEGIN_README_regress"
regress y x w1 w2 i.firm i.year
dis "END_README_regress"

dis "BEGIN_README_reghdfe"
reghdfe y x w1 w2, absorb(firm year)
dis %12.8f e(r2)
dis %12.8f e(r2_within)
dis "END_README_reghdfe"

dis "BEGIN_README_native_excluded"
regsensitivity bounds y x w1 w2 i.firm i.year, compare(w1 w2) rxbar(0 0.1 0.2 0.3) table
dis "END_README_native_excluded"

dis "BEGIN_README_native_included"
regsensitivity bounds y x w1 w2 i.firm i.year, rxbar(0 0.1 0.2 0.3) table
dis "END_README_native_included"

dis "README_OUTPUT_COMPLETED"
