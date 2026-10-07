# regsenshdfe

[中文说明](README_CN.md)

Regression sensitivity analysis with high-dimensional fixed effects. `regsenshdfe`
partials out fixed effects with `reghdfe`, then delegates DMP and Oster sensitivity
calculations to `regsensitivity`. It is an independent wrapper, not an official
extension by the authors of either dependency.

## Install

Requires Stata 15 or later, `ftools`, `reghdfe`, and `regsensitivity`.

```stata
ssc install ftools
ssc install reghdfe
ssc install regsensitivity
```

From a downloaded or cloned repository, change to its root and install locally:

```stata
net install regsenshdfe, from(".") replace
help regsenshdfe
```

The intended GitHub installation command, once this repository has been published
at `codefoxs/regsenshdfe` on branch `main`, is:

```stata
net install regsenshdfe, from("https://raw.githubusercontent.com/codefoxs/regsenshdfe/main/") replace
```

The package installs the ado and English help file. Clone/download the repository
to obtain the `test/` examples; no private data are needed.

## Syntax

```stata
regsenshdfe bounds    depvar indepvar controls [if] [in], absorb(absvars) [options]
regsenshdfe breakdown depvar indepvar controls [if] [in], absorb(absvars) [options]
regsenshdfe plot [, plot_options]
```

The first variable is the outcome and the second is the treatment of interest.
At least one comparison control is required. Analysis variables must be plain
numeric variables; generate transformations, interactions, or indicators first.
The `absorb()` specification is parsed by `reghdfe`, so `firm year`, `i.firm`,
`firm year#industry`, and heterogeneous slopes such as `firm##c.trend` are allowed.

| Option | Meaning |
| --- | --- |
| `absorb(absvars)` | Required fixed effects, always conditioned on and excluded from the comparison group. |
| `compare(varlist)` | Use this subset of the listed controls as the comparison group. Other controls remain in the model. Default: all controls. |
| `nocompare(varlist)` | Exclude this subset from the comparison group. Mutually exclusive with `compare()`. |
| `dmp` / `oster` | Select the underlying method; DMP is the default. |
| `rxbar()`, `rybar()`, `cbar()` | DMP sensitivity parameters; `rxbar()` specifies bounds grids. Breakdown solves for `rxbar`. |
| `delta()`, `r2long()` | Oster sensitivity parameters; `delta()` specifies bounds grids. Breakdown solves for delta. |
| `beta()` | Breakdown hypothesis: `sign` by default; `beta(.2, lb)` means beta > .2; Oster `beta(0, eq)` means beta != 0. |
| `maxovb()` | Upstream Oster bounds restriction on the maximum absolute omitted-variable bias. |
| `ngrid(#)`, `noproduct` | Upstream grid controls; `noproduct` pairs parameter values instead of taking their Cartesian product (bounds). |
| `table`, `plot`, `noplot` | Upstream display controls. Use `table` for explicit table-only examples; `plot` requests a graph. `noplot` retains upstream semantics and is not a universal suppression switch. |

Parameter specifications, including `delta(1, eq)` and `r2long(1.3, relative)`,
retain their upstream meaning. Consult `help regsensitivity_bounds` and
`help regsensitivity_breakdown` for method-specific combinations. Unknown options
are rejected: this command does not accept weights, `vce()`, `cluster()`, or
arbitrary `reghdfe` solver options. The projection tolerance is `1e-12`.

## Which R-squared is used?

**The analysis uses residualized R-squared, not the overall R-squared that includes
fixed effects.** Fixed effects are treated as always-included nuisance controls,
not as controls that calibrate selection on unobservables.

With all listed controls in the comparison group, `R2(medium)` equals the within
R-squared of the corresponding `reghdfe` regression. If some listed controls are
excluded by `compare()` or `nocompare()`, those controls are also partialled out;
the resulting R-squared is conditional on both them and the fixed effects.

On the same estimation sample, the wrapper targets the same calculation as:

```stata
regsensitivity bounds y x w1 w2 i.firm i.year, compare(w1 w2) rxbar(0 .1 .2) table
```

The explicit dummy expansion is only a feasible benchmark when the number of
fixed effects is small. The Frisch-Waugh-Lovell theorem gives coefficient
invariance; it does **not** equate residualized R-squared to overall R-squared.

For Oster, `r2long(1.3, relative)` means 1.3 times this **residualized** medium-model
R-squared. A manually specified `r2long()` must use the same scale. Do not import
the overall R-squared from a regression table into this calculation. Treating
fixed effects themselves as comparison controls is a different sensitivity
specification and is not implemented here.

## Examples

Run from the repository root. All commands below are exercised in
[`test/examples.do`](test/examples.do).

```stata
adopath ++ "."
do test/make_panel.do

* DMP bounds and a safe postestimation plot
regsenshdfe bounds y x w1 w2, absorb(firm year) rxbar(0 .1 .2 .3) table
regsenshdfe plot, xline(1)

* Include w0, but benchmark selection against w1 and w2 only
regsenshdfe bounds y x w1 w2 w0, absorb(firm year) compare(w1 w2) rxbar(0 .1 .2) table
regsenshdfe bounds y x w1 w2 w0, absorb(firm year) nocompare(w0) rxbar(0 .1 .2) table

* DMP breakdown frontier
regsenshdfe breakdown y x w1 w2, absorb(firm year) cbar(0(.2)1) plot

* Oster: delta fixed at each supplied value; conditional R2 calibration
regsenshdfe bounds y x w1 w2, absorb(firm year) oster delta(0 .5 1, eq) r2long(1.3, relative) table

* Oster: explain-away and sign-change hypotheses are distinct
regsenshdfe breakdown y x w1 w2, absorb(firm year) oster r2long(.8 .9 1) beta(0, eq) plot
regsenshdfe breakdown y x w1 w2, absorb(firm year) oster r2long(.8 .9 1) beta(sign) table

* Firm and industry-by-year FE, with sample restrictions
regsenshdfe bounds y x w1 w2 if year >= 2003 in 1/500, absorb(firm year#industry) rxbar(0 .1 .2) table
```

`beta(0, eq)` asks how much selection can make beta equal zero; `beta(sign)` asks
when its sign can fail. These are not interchangeable, even when their numerical
answers happen to coincide. In Oster bounds, `delta(..., eq)` fixes delta at each
value; `delta(..., bound)` bounds its absolute magnitude. DMP does not implement
the `beta(..., eq)` hypothesis in the tested upstream version.

For parameter tuples, the tested DMP example is:

```stata
regsenshdfe bounds y x w1 w2, absorb(firm year) rxbar(0 .1 .2) cbar(0 .5 1) noproduct ngrid(3) table
```

Use compatible grid lengths. Upstream 1.2.0 can fail on some `noproduct` grids
with its default dense-grid construction; the explicit `ngrid(3)` example is
covered by the runnable suite.

## Saved results and plotting

The numerical results and upstream plot metadata remain in `e()`:

| Result | Meaning |
| --- | --- |
| `e(N)` | Observations used in sensitivity analysis. |
| `e(sumstats)` | Short/medium coefficients, conditional R-squared, and variances. |
| `e(idset_table)`, `e(idset)` | Bounds table and plotting grid, after `bounds`. |
| `e(breakdown)` | Scalar breakdown point when provided by upstream `bounds`; not guaranteed for every specification. |
| `e(breakfront_table)`, `e(breakfront)` | Breakdown table and plotting grid, after `breakdown`. |
| `e(N_hdfe)`, `e(N_singletons)` | Joint HDFE sample size and number of removed singleton observations. |
| `e(absorb)`, `e(cmdline_hdfe)` | Absorption specification and original wrapper command line. |
| `e(cmd2)`, `e(version_hdfe)` | `regsenshdfe` and the wrapper version. |

`e(cmd)` deliberately remains `regsensitivity`; upstream `e(cmdline)` describes
the residualized call. `estimates store` / `estimates restore` can save and restore
results for plotting. The wrapper does not supply an `e(sample)` indicator or a
regression coefficient/VCE matrix. To identify the sample, run the corresponding
`reghdfe` model on the same original data with the same `if`/`in` restriction.

Prefer `regsenshdfe plot`. It delegates to the upstream graph routines while
protecting the active data. The tested upstream breakdown plot creates variables
literally named `x` and `y`; calling `regsensitivity plot` directly on a dataset
containing those names can fail. Graph options retain upstream limitations;
for a graph name use `name(mygraph)`, not `name(mygraph, replace)`.

## Tests and implementation boundaries

```stata
* From the repository root; this replaces the active data with simulated data
 do test/run_all.do
```

| File | Coverage |
| --- | --- |
| [`test/make_panel.do`](test/make_panel.do) | Reproducible 60-firm, 10-year simulated panel. |
| [`test/test_regsenshdfe.do`](test/test_regsenshdfe.do) | Full-table comparisons against explicit FE; all four method/subcommand pairs; sample selection; data restoration; plots and errors. |
| [`test/test_edge_cases.do`](test/test_edge_cases.do) | Heterogeneous slopes, string/saved FE, storage precision, name restrictions, finite rybar and maxovb. |
| [`test/examples.do`](test/examples.do) | Runnable examples corresponding to README and help, including hypotheses, grids and stored results. |
| [`test/bootstrap.do`](test/bootstrap.do) | Illustrative firm-cluster bootstrap with a separate FE identifier for each sampled cluster draw. |
| [`test/run_all.do`](test/run_all.do) | Runs assertions and all examples. |

Validation on Stata 19.5 with regsensitivity 1.2.0, reghdfe 6.12.4 and ftools
2.49.1 passed 13 test groups and 191 matrix-cell comparisons at a relative
tolerance of `1e-7`. See [the validation record](test/VALIDATION.md) for execution
evidence, installation checks and remaining boundaries.

The wrapper establishes one joint complete-case sample with `reghdfe`, including
its recursive singleton removal, then projects every analysis variable on the
same fixed effects and sample. Working residuals use double precision; the
original dataset, variable types, labels and order are restored after success or
failure. Fixed-effect estimates requested through FE-saving syntax are temporary
and are not exported to the caller's dataset.

The sensitivity routines analyze point identification. They do not produce
cluster-robust standard errors or confidence intervals. The 20-replication
bootstrap is only a workflow example, not a validated general inference method
or an adequate publication replication count. Breakdown functionals can be
nonregular; choose an inference method appropriate to the research design.

The tested upstream implementation appends `r` to variable names, so analysis
names are limited to 31 characters and combinations such as `y` and `yr` are
rejected. Finite `rybar()` with positive `cbar()` can require costly numerical
optimization. Upstream statistical algorithms and their numerical limitations
are inherited rather than reimplemented.

## Provenance and license

The starting wrapper was version 0.3 from the author's local repository. The 0.4.0
release hardens data restoration, common-sample handling, option validation and
plotting, and adds distributable documentation and reproducible examples.
Exploratory scripts relying on private data are not part of the current package.

The method labels follow the installed `regsensitivity` documentation: DMP
(Diegert, Masten and Poirier) and Oster, with the extensions implemented upstream.
For formulas, assumptions and bibliographic details, use the original package's
help and references. The wrapper does not bundle dependency source code.

MIT license for this wrapper; dependencies retain their own licenses.
