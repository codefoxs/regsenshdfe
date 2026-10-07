# regsenshdfe

[中文说明](README_CN.md)

`regsenshdfe` implements omitted-variable sensitivity analysis for linear models
with high-dimensional fixed effects. It partials out fixed effects using
`reghdfe`, then calls `regsensitivity` to compute coefficient identified sets and
breakdown points under the DMP and Oster frameworks.

Fixed effects are always included as controls and excluded from the comparison
group used to calibrate selection. The results describe sensitivity of coefficient
magnitudes and signs to omitted-variable assumptions; they do not provide
significance tests or confidence intervals.

## Installation

Requires Stata 15 or later. Install the dependencies:

```stata
ssc install ftools
ssc install reghdfe
ssc install regsensitivity
```

Download this repository, change to its root directory in Stata, and install:

```stata
net install regsenshdfe, from(".") replace
```

After publication to `codefoxs/regsenshdfe` on branch `main`, the intended GitHub
installation command is:

```stata
net install regsenshdfe, from("https://raw.githubusercontent.com/codefoxs/regsenshdfe/main/") replace
```

## Syntax and example data

The estimation syntax is `regsenshdfe bounds depvar indepvar controls, absorb(absvars)`
or `regsenshdfe breakdown depvar indepvar controls, absorb(absvars)`, with optional
`if` and `in` restrictions. `bounds` computes coefficient identified sets at
specified sensitivity parameters; `breakdown` computes thresholds for a specified
hypothesis.

The examples use a simulated panel of 60 firms over 10 years, with 600 observations.
The outcome is `y`, the target regressor is `x`, and `w1 w2` are comparison controls.
Run the data-generation script from the repository root:

```stata
adopath ++ "."
do test/make_panel.do
recast double y x w1 w2
```

The script replaces the data in memory. The baseline model includes firm and year
fixed effects and gives an estimated coefficient on `x` of 0.5621. The tables
report actual output rounded to the displayed precision. Complete examples are
provided in [test/examples.do](test/examples.do).

## 1. DMP coefficient bounds

Compute coefficient bounds under specified limits on omitted-variable selection.

```stata
regsenshdfe bounds y x w1 w2, absorb(firm year) rxbar(0 .1 .2 .3) table
```

`rxbar` measures omitted-variable selection on `x` relative to the comparison
controls `w1 w2`. Larger values allow stronger omitted-variable influence.
This example retains the defaults `rybar=+inf` and `cbar=1`.

| rxbar | Possible coefficient interval |
| --- | --- |
| 0.0 | [0.5621, 0.5621] |
| 0.1 | [0.4007, 0.7234] |
| 0.2 | [0.2308, 0.8933] |
| 0.3 | [0.0411, 1.0830] |

The identified interval widens as `rxbar` increases. At `rxbar=0.3`, the lower
endpoint is 0.0411, so all coefficients in the interval remain positive. The
positive-sign breakdown point is approximately 0.3198, displayed by the upstream
command as 32.0%. This percentage denotes relative selection strength and has no
probability interpretation. The reported intervals are identification regions.

## 2. DMP breakdown points and frontiers

Compute sign-robustness thresholds under alternative correlation restrictions.

```stata
regsenshdfe breakdown y x w1 w2, absorb(firm year) cbar(0(.2)1) plot
```

`cbar` restricts the correlation between the omitted variable and the comparison
controls. The default hypothesis preserves the baseline sign: positive here.

| cbar | Positive-sign breakdown rxbar |
| --- | --- |
| 0.0 | 33.7% |
| 0.2 | 32.2% |
| 0.4 | 32.0% |
| 0.6 | 32.0% |
| 0.8 | 32.0% |
| 1.0 | 32.0% |

The breakdown point is approximately 0.337 at `cbar=0` and decreases to about
0.320 as the correlation restriction is relaxed. All reported thresholds are
below 1. Under this comparison group and these parameter settings, the positive
sign is not robust to omitted-variable selection reaching the reference strength.

The option `beta(.2, lb)` specifies the hypothesis beta > 0.2:

```stata
regsenshdfe breakdown y x w1 w2, absorb(firm year) beta(.2, lb) cbar(1) table
```

The resulting threshold is 21.7%, below the threshold for beta > 0. A stricter
coefficient lower bound permits less omitted-variable selection.

## 3. Oster identified sets under equality restrictions

Fix the proportional-selection parameter delta at specified values and compute
the corresponding coefficient identified sets.

```stata
regsenshdfe bounds y x w1 w2, absorb(firm year) oster delta(0 .5 1, eq) r2long(1.3, relative) table
```

`delta(..., eq)` fixes delta at each listed value. `r2long(1.3, relative)` sets the
long-model R-squared to 1.3 times the medium-model R-squared, here
`1.3 × 0.28872647 = 0.37534441`. Section 8 defines the R-squared measure and
provides the explicit-dummy comparison.

| delta | Possible coefficient values |
| --- | --- |
| 0.0 | {0.5621} |
| 0.5 | {0.3747} |
| 1.0 | {0.1015, 1.5556} |

Under this R-squared specification, the identified set contains only 0.3747 at
delta 0.5. At delta 1 it contains two discrete values, 0.1015 and 1.5556. Results
should be reported as the complete set, rather than as a selected root or the
interval between the roots. A dot in the original output denotes the absence of
an additional solution in that column.

## 4. Oster coefficient bounds under inequality restrictions

Bound the absolute value of delta and compute coefficient lower and upper bounds.

```stata
regsenshdfe bounds y x w1 w2, absorb(firm year) oster delta(0 .5 1, bound) r2long(.95) table
```

`bound` allows delta to vary with absolute value up to each supplied limit.
This example sets long-model R-squared to 0.95.

| Maximum absolute delta | Possible coefficient interval |
| --- | --- |
| 0.0 | [0.5621, 0.5621] |
| 0.5 | [-0.6514, 2.8190] |
| 1.0 | [-∞, +∞] |

At an absolute delta limit of 0.5, the coefficient bounds include zero and
negative values, so the positive sign is not robust. At a limit of 1, the bounds
span the real line. The table reports each parameter limit once, omitting
identical rows repeated in the tested upstream display.

This example uses a long-model R-squared of 0.95, unlike section 3. Comparisons
of equality and inequality restrictions require the same R-squared and other
parameter settings.

## 5. Oster explain-away threshold

The option `beta(0, eq)` specifies beta != 0 and computes the proportional-selection
threshold at which that hypothesis fails.

```stata
regsenshdfe breakdown y x w1 w2, absorb(firm year) oster r2long(1.3, relative) beta(0, eq) table
```

| Long-model R-squared | Explain-away delta threshold |
| --- | --- |
| 0.37534441 | 1.10580156 (110.6%) |

Under this R-squared specification, the explain-away threshold is approximately
1.106. It describes the selection required for a zero coefficient and does not
substitute for a separate assessment of sign robustness.

## 6. Oster sign breakdown point

The option `beta(sign)` specifies preservation of the baseline coefficient sign.
The baseline coefficient is positive in this example, so the hypothesis is beta > 0.

```stata
regsenshdfe breakdown y x w1 w2, absorb(firm year) oster r2long(1.3, relative) beta(sign) table
```

| Long-model R-squared | Positive-sign breakdown point |
| --- | --- |
| 0.37534441 | 1.00000000 (100.0%) |

On the same sample and R-squared specification, the explain-away threshold is
1.1058 and the sign threshold is 1.0000. The sign threshold is a robustness
boundary; it need not imply an attained negative coefficient at the boundary
itself. An explain-away threshold above 1 is therefore insufficient to establish
sign robustness for delta near 1.

DMP's rxbar and Oster's delta have different definitions. Their magnitudes do
not provide a cross-method ranking of robustness.

## 7. Comparison-control specification

`compare()` specifies the controls used to calibrate selection, and `nocompare()`
specifies controls excluded from that calibration. Both calls below include `w0`
in the model and use `w1 w2` as the comparison group:

```stata
regsenshdfe bounds y x w1 w2 w0, absorb(firm year) compare(w1 w2) rxbar(0 .1 .2) table
regsenshdfe bounds y x w1 w2 w0, absorb(firm year) nocompare(w0) rxbar(0 .1 .2) table
```

Both commands produce:

| rxbar | Possible coefficient interval |
| --- | --- |
| 0.0 | [0.5172, 0.5172] |
| 0.1 | [0.3496, 0.6848] |
| 0.2 | [0.1729, 0.8615] |

`nocompare(w0)` excludes `w0` from the comparison group while retaining its
control role. Including `w0` changes the baseline coefficient from approximately
0.5621 to 0.5172. Fixed effects are always treated as noncomparison controls by
`regsenshdfe`.

## 8. R-squared definitions and explicit fixed-effect comparison

The following checks use the same sample with explicit fixed-effect indicators
and high-dimensional absorption. Membership of the comparison group determines
the R-squared definition used in sensitivity analysis. The complete comparison
is implemented in [test/compare_r2.do](test/compare_r2.do).

### 8.1 Regression coefficients and overall R-squared

```stata
regress y x w1 w2 i.firm i.year
reghdfe y x w1 w2, absorb(firm year)
```

| Regression | Coefficient on x | Overall R-squared | Within R-squared |
| --- | --- | --- | --- |
| `regress` with `i.firm i.year` | 0.56205310 | 0.65915834 | Not returned separately |
| `reghdfe` with `absorb(firm year)` | 0.56205310 | 0.65915834 | 0.28872647 |

The coefficient and overall R-squared agree across estimators. Overall R-squared
is 0.65915834. Within R-squared is 0.28872647 and measures the fraction of variation
explained after partialling out the fixed effects.

### 8.2 Fixed effects excluded from the comparison group

```stata
regsensitivity bounds y x w1 w2 i.firm i.year, compare(w1 w2) rxbar(0 .1 .2 .3) table
regsenshdfe bounds y x w1 w2, absorb(firm year) rxbar(0 .1 .2 .3) table
```

| Command | Baseline coefficient | R2(short) | R2(medium) | DMP breakdown |
| --- | --- | --- | --- | --- |
| Native + `i.firm i.year` + `compare(w1 w2)` | 0.56205311 | 0.20729475 | 0.28872647 | 0.31975099 |
| `regsenshdfe` | 0.56205311 | 0.20729475 | 0.28872647 | 0.31975099 |

Native `regsensitivity` partials out the fixed-effect indicators excluded from
`compare()` before computing the sensitivity results. Both implementations use
residualized R-squared of 0.28872647 and produce the same breakdown point.

The full DMP table and the Oster table under section 3's specification passed an
absolute `1e-7` tolerance check. The maximum absolute difference was zero in this
example; comparisons on other data are assessed using the numerical tolerance.

### 8.3 Fixed effects included in the comparison group

```stata
regsensitivity bounds y x w1 w2 i.firm i.year, rxbar(0 .1 .2 .3) table
```

| Native comparison group | Baseline coefficient | R2(medium) | DMP breakdown |
| --- | --- | --- | --- |
| `w1 w2` only | 0.56205311 | 0.28872647 | 0.31975099 |
| `w1 w2` plus firm/year dummies | 0.56205311 | 0.65915834 | 0.19565717 |

Omitting `compare()` from the native call includes all controls, including the
fixed-effect indicators, in the comparison group. R2(medium) then equals overall
R-squared and the breakdown point changes accordingly. `regsenshdfe` implements
the specification excluding fixed effects from the comparison group; its Oster
`r2long()` parameter must use the corresponding residualized scale.

## Plotting and stored results

Following `bounds`, the plotting subcommand and result matrices are available as:

```stata
regsenshdfe plot, xline(1)
matrix bounds = e(idset_table)
matrix summary = e(sumstats)
```

The table is `e(idset_table)` after `bounds` and `e(breakfront_table)` after
`breakdown`. `e(breakdown)` is supplied only for supported `bounds` specifications;
it is not a universal return value.

See [test/examples.do](test/examples.do) for interacted FE, sample restrictions,
parameter grids and stored estimates. [test/bootstrap.do](test/bootstrap.do)
illustrates a firm-cluster bootstrap. Run `help regsenshdfe` for the full options
and stored-results reference.

## Tests and limitations

Run `do test/run_all.do` from the repository root for the numerical tests,
R-squared comparison and examples. Tests replace the active data. Environment
and detailed checks are recorded in [test/VALIDATION.md](test/VALIDATION.md).

- This is point-identification analysis; it does not automatically provide
  robust/clustered standard errors or confidence intervals. The bootstrap's 20
  replications illustrate the workflow, not a recommended inference procedure.
- No weights, `vce()`, `cluster()`, or factor/time-series operators in the analysis
  variable list. FE interactions are allowed inside `absorb()`.
- FE are always controlled for. Joint sample selection and singleton removal
  follow `reghdfe`. The active data are restored, but `e(sample)` is not supplied.
- Analysis names are limited to 31 characters and must avoid upstream residual
  naming conflicts such as `y` with `yr`. Some parameter combinations remain
  subject to upstream numerical limitations.

This is an independent wrapper, not an official extension by the dependency
authors. Consult `regsensitivity` for DMP/Oster formulas and assumptions. The
wrapper is MIT-licensed; dependencies retain their own licenses.
