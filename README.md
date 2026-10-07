# regsenshdfe

[中文说明](README_CN.md)

A significant regression coefficient can still be sensitive to omitted variables.
`regsenshdfe` asks: **how strong would omitted-variable selection have to be to
change the size or sign of the coefficient?**

It combines the DMP and Oster analyses in `regsensitivity` with fixed-effect
absorption by `reghdfe`. Each section below gives a question, a runnable command,
actual results and an interpretation. These are sensitivity analyses, not
significance tests: their thresholds are neither p-values nor probabilities.

## Installation and example data

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

All results below use one simulated panel: 60 firms, 10 years, 600 observations.
The outcome is `y`, the treatment is `x`, and the comparison controls are `w1 w2`.
From the repository root, run:

```stata
adopath ++ "."
do test/make_panel.do
recast double y x w1 w2
```

This replaces the data in memory. The baseline model includes `y x w1 w2` and
firm/year fixed effects; the coefficient on `x` is about **0.5621**. Tables below
are formatted from actual output and rounded for display. The complete examples
are in [test/examples.do](test/examples.do).

## 1. DMP bounds: which coefficient values remain possible?

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

**Interpretation:** The interval widens as stronger omitted-variable selection is
allowed. At `rxbar=0.3`, its lower endpoint is still positive. The reported
positive-sign breakdown point is about **0.3198 (32.0%)**. That percentage is a
relative selection strength, not a probability that the result is wrong. These
intervals are not confidence intervals.

## 2. DMP breakdown: when does the conclusion cease to hold?

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

**Interpretation:** With zero allowed correlation, the threshold is about 0.337.
Relaxing that restriction lowers it to about 0.320. Under the listed assumptions,
this example cannot preserve the positive sign up to the `rxbar=1` benchmark.
That assessment depends on the comparison controls and parameter choices.

To ask whether the coefficient remains above 0.2 rather than merely above zero:

```stata
regsenshdfe breakdown y x w1 w2, absorb(firm year) beta(.2, lb) cbar(1) table
```

**Result:** The threshold is **21.7%**. Preserving a coefficient above 0.2 is a
stronger requirement than preserving its positive sign, so it breaks down sooner.

## 3. Oster equality: what if delta is fixed at a particular value?

```stata
regsenshdfe bounds y x w1 w2, absorb(firm year) oster delta(0 .5 1, eq) r2long(1.3, relative) table
```

`delta(..., eq)` fixes delta at each listed value. `r2long(1.3, relative)` sets the
long-model R-squared to 1.3 times the medium-model R-squared, here
`1.3 × 0.28872647 = 0.37534441`. The explicit-dummy comparison below explains
which R-squared is used.

| delta | Possible coefficient values |
| --- | --- |
| 0.0 | {0.5621} |
| 0.5 | {0.3747} |
| 1.0 | {0.1015, 1.5556} |

**Interpretation:** At delta 0.5, the coefficient is 0.3747 under the chosen
R-squared assumption. At delta 1, there are two feasible solutions; reporting
only the smaller one would omit part of the result. Two discrete values do not
mean the whole interval `[0.1015, 1.5556]` is feasible. Dots in the original output
mean that there is no additional solution in that column, not a zero coefficient.

## 4. Oster bounded delta: what if only its maximum magnitude is known?

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

**Interpretation:** At a limit of 0.5, zero and negative values are already
possible, so the positive sign is not guaranteed. At a limit of 1, there are no
finite bounds. This table shows each distinct limit once; the tested upstream
version prints some identical rows more than once.

The R-squared assumption differs from the previous section. Differences between
the two tables therefore cannot be attributed solely to `eq` versus `bound`.
Hold R-squared and the other parameters fixed when comparing those choices.

## 5. Oster explain-away threshold: how much selection can make beta zero?

```stata
regsenshdfe breakdown y x w1 w2, absorb(firm year) oster r2long(1.3, relative) beta(0, eq) table
```

| Long-model R-squared | Explain-away delta threshold |
| --- | --- |
| 0.37534441 | 1.10580156 (110.6%) |

**Interpretation:** Under this R-squared assumption, delta needs to reach about
1.106 to make the coefficient equal zero. This answers the explain-away question;
it does not establish that the sign survives every weaker degree of selection.

## 6. Oster sign threshold: when is a positive effect no longer robust?

```stata
regsenshdfe breakdown y x w1 w2, absorb(firm year) oster r2long(1.3, relative) beta(sign) table
```

| Long-model R-squared | Positive-sign breakdown point |
| --- | --- |
| 0.37534441 | 1.00000000 (100.0%) |

**Interpretation:** On the same data and R-squared assumption, the explain-away
threshold is 1.1058 but the sign threshold is 1.0000. They answer different
questions. The latter is a boundary for sign robustness, not a claim that a
negative coefficient must already be feasible exactly at the boundary. An
explain-away delta above 1 alone does not establish sign robustness near 1.

DMP's rxbar and Oster's delta also have different definitions. Their numerical
sizes cannot be compared directly to decide which method shows greater robustness.

## 7. Choosing the comparison controls

Some variables need to be controlled for without serving as a benchmark for
omitted-variable selection. Keep `w0` in the model but compare against `w1 w2`:

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

**Interpretation:** `nocompare(w0)` does not remove `w0` from the model. It removes
it only from the comparison group. Adding `w0` to the model changes the baseline
coefficient from about 0.5621 to 0.5172. Fixed effects are always excluded from
the comparison group in `regsenshdfe`.

## 8. R-squared check: does native regsensitivity with i.firm i.year agree?

**Yes, when fixed effects are excluded from the comparison group in both calls.
Including fixed effects in that group changes both R-squared and the sensitivity
results.** These are actual numerical checks, reproduced by
[test/compare_r2.do](test/compare_r2.do).

### 8.1 Ordinary regression: explicit dummies and absorb() agree

```stata
regress y x w1 w2 i.firm i.year
reghdfe y x w1 w2, absorb(firm year)
```

| Regression | Coefficient on x | Overall R-squared | Within R-squared |
| --- | --- | --- | --- |
| `regress` with `i.firm i.year` | 0.56205310 | 0.65915834 | Not returned separately |
| `reghdfe` with `absorb(firm year)` | 0.56205310 | 0.65915834 | 0.28872647 |

**Interpretation:** Absorption has not lost the explanatory power of the fixed
effects. Overall R-squared is still 0.6592. Within R-squared measures how much
of the remaining variation is explained after removing the fixed effects.

### 8.2 Sensitivity analysis: excluding FE from comparison gives the same result

```stata
regsensitivity bounds y x w1 w2 i.firm i.year, compare(w1 w2) rxbar(0 .1 .2 .3) table
regsenshdfe bounds y x w1 w2, absorb(firm year) rxbar(0 .1 .2 .3) table
```

| Command | Baseline coefficient | R2(short) | R2(medium) | DMP breakdown |
| --- | --- | --- | --- | --- |
| Native + `i.firm i.year` + `compare(w1 w2)` | 0.56205311 | 0.20729475 | 0.28872647 | 0.31975099 |
| `regsenshdfe` | 0.56205311 | 0.20729475 | 0.28872647 | 0.31975099 |

**Interpretation:** Native `regsensitivity` also partials out the dummy variables
when they are excluded from `compare()`. Both paths therefore use 0.2887 rather
than the overall R-squared of 0.6592.

The full DMP bounds table and the full Oster table under section 3's specification
also passed an absolute `1e-7` tolerance check. The largest table difference in
this example was zero; this is not a promise of bit-for-bit equality on all data.

### 8.3 Omitting compare() in the native command includes FE in the benchmark

```stata
regsensitivity bounds y x w1 w2 i.firm i.year, rxbar(0 .1 .2 .3) table
```

| Native comparison group | Baseline coefficient | R2(medium) | DMP breakdown |
| --- | --- | --- | --- |
| `w1 w2` only | 0.56205311 | 0.28872647 | 0.31975099 |
| `w1 w2` plus firm/year dummies | 0.56205311 | 0.65915834 | 0.19565717 |

**Interpretation:** The second row does use overall R-squared, but it also changes
the benchmark for omitted-variable selection. It is a different sensitivity
specification, not a correction of the first row's R-squared. `regsenshdfe`
implements the first row; Oster's `r2long()` must use that same residualized scale.

## Plots, saved results and further examples

After estimation, plot or extract the results:

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

## Validation and limits

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
