{smcl}
{* *! version 0.4.0 08oct2026}{...}
{vieweralsosee "regsensitivity" "help regsensitivity"}{...}
{vieweralsosee "reghdfe" "help reghdfe"}{...}
{viewerjumpto "Syntax" "regsenshdfe##syntax"}{...}
{viewerjumpto "Options" "regsenshdfe##options"}{...}
{viewerjumpto "R-squared and interpretation" "regsenshdfe##interpretation"}{...}
{viewerjumpto "Stored results" "regsenshdfe##results"}{...}
{viewerjumpto "Examples and tests" "regsenshdfe##examples"}{...}
{title:Title}

{phang}
{bf:regsenshdfe} {hline 2} Regression sensitivity analysis with high-dimensional fixed effects

{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:regsenshdfe bounds} {it:depvar indepvar controls} {ifin}{cmd:,}
{opt absorb(absvars)} [{it:options}]

{p 8 17 2}
{cmd:regsenshdfe breakdown} {it:depvar indepvar controls} {ifin}{cmd:,}
{opt absorb(absvars)} [{it:options}]

{p 8 17 2}
{cmd:regsenshdfe plot} [{cmd:,} {it:plot_options}]

{pstd}
Requires Stata 15 or later, {helpb ftools}, {helpb reghdfe}, and
{helpb regsensitivity}. Install the dependencies with {cmd:ssc install}.
Analysis variables must be plain numeric variables, without factor-variable or
time-series operators. Generate transformations or interactions beforehand.
At least one comparison control is required. Weights are not supported.

{title:Description}

{pstd}
{cmd:regsenshdfe} is an independent wrapper. It determines a joint complete-case
sample using {cmd:reghdfe}, including recursive singleton removal, then projects
the outcome, treatment, and each control on the specified fixed effects in that
sample. The original {cmd:regsensitivity} routines calculate DMP or Oster bounds
and breakdown frontiers from the working residuals. No sensitivity formula is
reimplemented. Fixed effects are always conditioned on, never used as comparison
controls.

{pstd}
Working residuals use double precision. The original data, variable storage
types, labels, observation order and variable order are restored on success or
failure. This includes errors during fixed-effect estimation and plotting.
Saved fixed-effect variables requested inside {opt absorb()} are temporary;
they are not returned to the caller's data.

{marker options}{...}
{title:Options}

{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt absorb(absvars)}}Required FE specification, parsed by reghdfe{p_end}
{synopt:{opt compare(varlist)}}Subset of listed controls used for calibration; default all controls{p_end}
{synopt:{opt nocompare(varlist)}}Listed controls excluded from calibration{p_end}
{synopt:{opt dmp}}DMP sensitivity analysis; default{p_end}
{synopt:{opt oster}}Oster analysis and extensions implemented by regsensitivity{p_end}
{synopt:{opt rx:bar(spec)}}DMP bounds grid for treatment selection strength{p_end}
{synopt:{opt ry:bar(spec)}}DMP outcome selection strength{p_end}
{synopt:{opt c:bar(spec)}}DMP correlation restriction{p_end}
{synopt:{opt delta(spec)}}Oster bounds grid for proportional selection{p_end}
{synopt:{opt r2long(spec)}}Oster long-model R-squared on the residualized scale{p_end}
{synopt:{opt beta(spec)}}Breakdown hypothesis; default sign{p_end}
{synopt:{opt maxovb(spec)}}Upstream Oster bounds restriction on absolute omitted-variable bias{p_end}
{synopt:{opt ngrid(#)}}Upstream plotting-grid size{p_end}
{synopt:{opt noproduct}}Pair parameter values instead of their Cartesian product; bounds only{p_end}
{synopt:{opt table}}Request a table{p_end}
{synopt:{opt plot}}Request a graph{p_end}
{synopt:{opt noplot}}Retain upstream noplot semantics; see below{p_end}
{synoptline}

{phang}
{opt absorb()} accepts, for example, {cmd:firm year}, {cmd:i.firm},
{cmd:firm year#industry}, or heterogeneous slopes such as {cmd:firm##c.trend}.
Projection tolerance is fixed at {cmd:1e-12}. Arbitrary reghdfe options are not
forwarded. In particular, {cmd:cluster()} and {cmd:vce()} are not accepted.

{phang}
{opt compare()} and {opt nocompare()} are mutually exclusive. They must refer to
controls already listed after the treatment, not to the outcome or treatment.
Noncomparison controls remain in the model and are further partialled out by
regsensitivity. At least one control must remain in the comparison group.

{phang}
Sensitivity parameter specifications retain upstream syntax, including
{cmd:delta(1, eq)}, {cmd:delta(1, bound)}, and {cmd:r2long(1.3, relative)}.
For the complete method-specific meanings and permitted combinations, see
{help regsensitivity_bounds} and {help regsensitivity_breakdown}.
Breakdown solves for rxbar (DMP) or delta (Oster); do not use the corresponding
bounds-grid option to specify a breakdown frontier.

{phang}
{cmd:beta(sign)} asks whether beta retains the medium-model coefficient's sign.
{cmd:beta(.2, lb)} asks whether beta is greater than .2.
For Oster, {cmd:beta(0, eq)} asks whether beta differs from zero; its breakdown
point is the explain-away threshold. This differs from the sign-change question.
In Oster bounds, {cmd:delta(..., eq)} fixes delta at each value, whereas
{cmd:delta(..., bound)} bounds its absolute magnitude. The tested upstream
version does not implement {cmd:beta(..., eq)} for DMP.

{phang}
Use {cmd:table} for explicit table-only output. {cmd:noplot} preserves upstream
behavior and is not a universal switch suppressing all default plots. With
{cmd:noproduct}, use compatible parameter and dense-grid lengths. A tested
example uses {cmd:rxbar(0 .1 .2) cbar(0 .5 1) noproduct ngrid(3)}; upstream 1.2.0
can fail on some default dense-grid combinations.

{marker interpretation}{...}
{title:R-squared and interpretation}

{pstd}
{bf:The reported R-squared is residualized, not the overall R-squared including FE.}
When all listed controls are comparison controls, R2(medium) equals the within
R-squared from the corresponding reghdfe model. When additional controls are
excluded from the comparison group, R-squared is conditional on both those
controls and the FE.

{pstd}
On the same effective sample, the target is equivalent to explicit FE indicators
in regsensitivity with those indicators excluded from {opt compare()}.
The Frisch-Waugh-Lovell theorem establishes coefficient invariance; it does not
make within and overall R-squared equal. For Oster,
{cmd:r2long(1.3, relative)} is 1.3 times the residualized medium-model R-squared.
A manually supplied R-squared must use that same scale. Treating fixed effects
as comparison controls is a different specification, not supported here.

{pstd}
The statistics concern point identification, not standard errors. No robust or
clustered VCE or confidence intervals are computed. The repository's small
cluster-bootstrap example illustrates resampling only; it is not a validated
general inference procedure for potentially nonregular breakdown functionals.

{marker results}{...}
{title:Stored results}

{pstd}
Upstream numerical results and plotting metadata remain in {cmd:e()}.
Availability depends on the selected subcommand and method.

{synoptset 27}{...}
{synopt:{cmd:e(N)}}Sensitivity-analysis sample size{p_end}
{synopt:{cmd:e(sumstats)}}Short/medium coefficients, residualized R-squared and variances{p_end}
{synopt:{cmd:e(idset_table)}}Bounds table after bounds{p_end}
{synopt:{cmd:e(idset)}}Bounds plotting grid after bounds{p_end}
{synopt:{cmd:e(breakdown)}}Scalar breakdown point when provided by bounds{p_end}
{synopt:{cmd:e(breakfront_table)}}Breakdown table after breakdown{p_end}
{synopt:{cmd:e(breakfront)}}Breakdown plotting grid after breakdown{p_end}
{synopt:{cmd:e(N_hdfe)}}Joint HDFE sample size{p_end}
{synopt:{cmd:e(N_singletons)}}Removed singleton observations{p_end}
{synopt:{cmd:e(absorb)}}Original absorb specification{p_end}
{synopt:{cmd:e(cmdline_hdfe)}}Original wrapper call{p_end}
{synopt:{cmd:e(cmd2)}}regsenshdfe{p_end}
{synopt:{cmd:e(version_hdfe)}}Wrapper version{p_end}

{pstd}
{cmd:e(cmd)} remains {cmd:regsensitivity} for upstream compatibility;
{cmd:e(cmdline)} describes its residualized call. Results can be saved and
restored using {helpb estimates store} and {helpb estimates restore}.
No {cmd:e(sample)} indicator or regression coefficient/VCE matrix is supplied.
To recover the sample, run the corresponding reghdfe model on the same original
data with the same if/in restriction.

{title:Plotting and limitations}

{pstd}
Prefer {cmd:regsenshdfe plot}. It invokes {cmd:regsensitivity plot} in isolated
working data and restores the active data even when plotting fails. Upstream
1.2.0 breakdown plots create variables literally named x and y, which can
conflict with user data when upstream plotting is called directly.
Plot options retain upstream syntax; use {cmd:name(mygraph)}, not
{cmd:name(mygraph, replace)}.

{pstd}
Upstream residual construction appends r to analysis names. Names longer than
31 characters and conflicting combinations such as y and yr are rejected.
Finite rybar with positive cbar can require costly numerical optimization.
Statistical and numerical limitations of the dependency remain applicable.

{marker examples}{...}
{title:Examples and tests}

{pstd}
Download or clone the repository for test scripts; net install installs the ado
and help only. From the repository root, the following setup creates simulated
data and replaces the current data in memory:

{phang2}{cmd:. adopath ++ "."}{p_end}
{phang2}{cmd:. do test/make_panel.do}{p_end}

{pstd}DMP bounds and postestimation graph:{p_end}
{phang2}{cmd:. regsenshdfe bounds y x w1 w2, absorb(firm year) rxbar(0 .1 .2 .3) table}{p_end}
{phang2}{cmd:. regsenshdfe plot, xline(1)}{p_end}

{pstd}Keep w0 but calibrate against w1 and w2 only:{p_end}
{phang2}{cmd:. regsenshdfe bounds y x w1 w2 w0, absorb(firm year) compare(w1 w2) rxbar(0 .1 .2) table}{p_end}
{phang2}{cmd:. regsenshdfe bounds y x w1 w2 w0, absorb(firm year) nocompare(w0) rxbar(0 .1 .2) table}{p_end}

{pstd}DMP breakdown frontier:{p_end}
{phang2}{cmd:. regsenshdfe breakdown y x w1 w2, absorb(firm year) cbar(0(.2)1) plot}{p_end}

{pstd}Oster bounds and distinct breakdown hypotheses:{p_end}
{phang2}{cmd:. regsenshdfe bounds y x w1 w2, absorb(firm year) oster delta(0 .5 1, eq) r2long(1.3, relative) table}{p_end}
{phang2}{cmd:. regsenshdfe breakdown y x w1 w2, absorb(firm year) oster r2long(.8 .9 1) beta(0, eq) plot}{p_end}
{phang2}{cmd:. regsenshdfe breakdown y x w1 w2, absorb(firm year) oster r2long(.8 .9 1) beta(sign) table}{p_end}

{pstd}Interacted FE and sample restrictions:{p_end}
{phang2}{cmd:. regsenshdfe bounds y x w1 w2 if year >= 2003 in 1/500, absorb(firm year#industry) rxbar(0 .1 .2) table}{p_end}

{pstd}Parameter tuples:{p_end}
{phang2}{cmd:. regsenshdfe bounds y x w1 w2, absorb(firm year) rxbar(0 .1 .2) cbar(0 .5 1) noproduct ngrid(3) table}{p_end}

{pstd}
These examples are in {cmd:test/examples.do}. Assertion-based numerical and data
safety checks are in {cmd:test/test_regsenshdfe.do}. Additional edge cases are in
{cmd:test/test_edge_cases.do}. The firm-cluster bootstrap is in
{cmd:test/bootstrap.do}, with only 20 illustrative replications.
Run {cmd:do test/run_all.do} from the repository root to execute the full suite.
The English README and linked README_CN.md provide matching documentation.

{title:Provenance}

{pstd}
Version 0.4.0 develops the original local 0.3 wrapper. DMP and Oster method labels
follow the upstream documentation. For formulas, assumptions and bibliographic
details, consult {help regsensitivity}. This package does not bundle dependency
source code. MIT license for the wrapper; dependencies retain their own licenses.
