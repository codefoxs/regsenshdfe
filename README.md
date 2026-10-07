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
fixed effects and gives an estimated coefficient on `x` of 0.5621. The `text` blocks are copied directly from the [original Stata output](test/readme_output.txt),
preserving command echoes, headers, numeric formatting, missing values and repeated rows. Complete examples are
provided in [test/examples.do](test/examples.do).

## 1. DMP coefficient bounds

Compute coefficient bounds under specified limits on omitted-variable selection.

```stata
regsenshdfe bounds y x w1 w2, absorb(firm year) rxbar(0 .1 .2 .3) table
```

`rxbar` measures omitted-variable selection on `x` relative to the comparison
controls `w1 w2`. Larger values allow stronger omitted-variable influence.
This example retains the defaults `rybar=+inf` and `cbar=1`.

<!-- stata-output:dmp_bounds -->
```text
. regsenshdfe bounds y x w1 w2, absorb(firm year) rxbar(0 .1 .2 .3) table

Regression Sensitivity Analysis, Bounds

Analysis         : DMP (2022)                  Number of obs      =         600
                                               Beta(short)        =       0.807
Treatment        : x                           Beta(medium)       =       0.562
Outcome          : y                           R2(short)          =       0.207
                                               R2(medium)         =       0.289
                                               Var(Y)             =       5.044
                                               Var(X)             =       1.605
                                               Var(X_Residual)    =       0.955

Hypothesis       : Beta > 0                    Breakdown Point    =          32%
Other Params     : rybar = +inf, cbar = 1

--------------------------------------------------------------------------------
 rxbar                             Beta
--------------------------------------------------------------------------------
 0.000                            [ 0.5621,  0.5621 ]
 0.100                            [ 0.4007,  0.7234 ]
 0.200                            [ 0.2308,  0.8933 ]
 0.300                            [ 0.0411,  1.0830 ]
--------------------------------------------------------------------------------
```
<!-- /stata-output:dmp_bounds -->

The identified interval widens as `rxbar` increases. At `rxbar=0.3`, the lower
endpoint is 0.0411, so all coefficients in the interval remain positive. The
positive-sign breakdown point is approximately 0.3198, displayed by the upstream
command as 32%. This percentage denotes relative selection strength and has no
probability interpretation. The reported intervals are identification regions.

## 2. DMP breakdown points and frontiers

Compute sign-robustness thresholds under alternative correlation restrictions.

```stata
regsenshdfe breakdown y x w1 w2, absorb(firm year) cbar(0(.2)1) plot
```

`cbar` restricts the correlation between the omitted variable and the comparison
controls. The default hypothesis preserves the baseline sign: positive here.

<!-- stata-output:dmp_breakdown -->
```text
. regsenshdfe breakdown y x w1 w2, absorb(firm year) cbar(0(.2)1) plot

Regression Sensitivity Analysis, Breakdown Frontier

Analysis         : DMP (2022)                  Number of obs      =         600
                                               Beta(short)        =       0.807
Treatment        : x                           Beta(medium)       =       0.562
Outcome          : y                           R2(short)          =       0.207
                                               R2(medium)         =       0.289
                                               Var(Y)             =       5.044
                                               Var(X)             =       1.605
Hypothesis       : Beta > 0                    Var(X_Residual)    =       0.955

--------------------------------------------------------------------------------
 cbar                               rxbar(Breakdown)
--------------------------------------------------------------------------------
 0.000                              33.7 %
 0.200                              32.2 %
 0.400                              32.0 %
 0.600                              32.0 %
 0.800                              32.0 %
 1.000                              32.0 %
--------------------------------------------------------------------------------
```
<!-- /stata-output:dmp_breakdown -->

The breakdown point is approximately 0.337 at `cbar=0` and decreases to about
0.320 as the correlation restriction is relaxed. All reported thresholds are
below 1. Under this comparison group and these parameter settings, the positive
sign is not robust to omitted-variable selection reaching the reference strength.

The option `beta(.2, lb)` specifies the hypothesis beta > 0.2:

```stata
regsenshdfe breakdown y x w1 w2, absorb(firm year) beta(.2, lb) cbar(1) table
```

<!-- stata-output:dmp_beta -->
```text
. regsenshdfe breakdown y x w1 w2, absorb(firm year) beta(.2, lb) cbar(1) table

Regression Sensitivity Analysis, Breakdown Frontier

Analysis         : DMP (2022)                  Number of obs      =         600
                                               Beta(short)        =       0.807
Treatment        : x                           Beta(medium)       =       0.562
Outcome          : y                           R2(short)          =       0.207
                                               R2(medium)         =       0.289
                                               Var(Y)             =       5.044
                                               Var(X)             =       1.605
Hypothesis       : Beta > .2                   Var(X_Residual)    =       0.955

--------------------------------------------------------------------------------
 cbar                               rxbar(Breakdown)
--------------------------------------------------------------------------------
 1.000                              21.7 %
--------------------------------------------------------------------------------
```
<!-- /stata-output:dmp_beta -->

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

<!-- stata-output:oster_eq -->
```text
. regsenshdfe bounds y x w1 w2, absorb(firm year) oster delta(0 .5 1, eq) r2long(1.3, relative) table
ndeltapoints = 3, ngrid = 200

Regression Sensitivity Analysis, Bounds

Analysis         : Oster (2019)                Number of obs      =         600
                                               Beta(short)        =       0.807
Treatment        : x                           Beta(medium)       =       0.562
Outcome          : y                           R2(short)          =       0.207
                                               R2(medium)         =       0.289
                                               Var(Y)             =       5.044
                                               Var(X)             =       1.605
                                               Var(X_Residual)    =       0.955

Hypothesis       : Beta != 0                   Breakdown Point    =         111%
Other Params     : R-squared(long) = .375

--------------------------------------------------------------------------------
 delta                             Beta
--------------------------------------------------------------------------------
 0.000                            { 0.5621,       .,       . }
 0.500                            { 0.3747,       .,       . }
 1.000                            { 0.1015,  1.5556,       . }
--------------------------------------------------------------------------------
```
<!-- /stata-output:oster_eq -->

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

<!-- stata-output:oster_bound -->
```text
. regsenshdfe bounds y x w1 w2, absorb(firm year) oster delta(0 .5 1, bound) r2long(.95) table

Regression Sensitivity Analysis, Bounds

Analysis         : Oster (2019)                Number of obs      =         600
                                               Beta(short)        =       0.807
Treatment        : x                           Beta(medium)       =       0.562
Outcome          : y                           R2(short)          =       0.207
                                               R2(medium)         =       0.289
                                               Var(Y)             =       5.044
                                               Var(X)             =       1.605
                                               Var(X_Residual)    =       0.955

Hypothesis       : Beta > 0                    Breakdown Point    =        22.5%
Other Params     : R-squared(long) = .95

--------------------------------------------------------------------------------
 Delta                             Beta
--------------------------------------------------------------------------------
 0.000                            [ 0.5621,  0.5621 ]
 0.000                            [ 0.5621,  0.5621 ]
 0.000                            [ 0.5621,  0.5621 ]
 0.000                            [ 0.5621,  0.5621 ]
 0.500                            [-0.6514,  2.8190 ]
 0.500                            [-0.6514,  2.8190 ]
 0.500                            [-0.6514,  2.8190 ]
 1.000                            [   -inf,    +inf ]
 1.000                            [   -inf,    +inf ]
 1.000                            [   -inf,    +inf ]
 1.000                            [   -inf,    +inf ]
--------------------------------------------------------------------------------
```
<!-- /stata-output:oster_bound -->

At an absolute delta limit of 0.5, the coefficient bounds include zero and
negative values, so the positive sign is not robust. At a limit of 1, the bounds
span the real line. Repeated identical rows from the upstream display are retained verbatim.

This example uses a long-model R-squared of 0.95, unlike section 3. Comparisons
of equality and inequality restrictions require the same R-squared and other
parameter settings.

## 5. Oster explain-away threshold

The option `beta(0, eq)` specifies beta != 0 and computes the proportional-selection
threshold at which that hypothesis fails.

```stata
regsenshdfe breakdown y x w1 w2, absorb(firm year) oster r2long(1.3, relative) beta(0, eq) table
```

<!-- stata-output:oster_zero -->
```text
. regsenshdfe breakdown y x w1 w2, absorb(firm year) oster r2long(1.3, relative) beta(0, eq) table

Regression Sensitivity Analysis, Breakdown Frontier

Analysis         : Oster (2019)                Number of obs      =         600
                                               Beta(short)        =       0.807
Treatment        : x                           Beta(medium)       =       0.562
Outcome          : y                           R2(short)          =       0.207
                                               R2(medium)         =       0.289
                                               Var(Y)             =       5.044
                                               Var(X)             =       1.605
Hypothesis       : Beta != 0                   Var(X_Residual)    =       0.955
Other Params     : R-squared(long) = .375
--------------------------------------------------------------------------------
 Beta(Hypothesis)                   Delta(Breakdown)
--------------------------------------------------------------------------------
 0.000                              110.6%
--------------------------------------------------------------------------------
```
<!-- /stata-output:oster_zero -->

Under this R-squared specification, the explain-away threshold is approximately
1.106. It describes the selection required for a zero coefficient and does not
substitute for a separate assessment of sign robustness.

## 6. Oster sign breakdown point

The option `beta(sign)` specifies preservation of the baseline coefficient sign.
The baseline coefficient is positive in this example, so the hypothesis is beta > 0.

```stata
regsenshdfe breakdown y x w1 w2, absorb(firm year) oster r2long(1.3, relative) beta(sign) table
```

<!-- stata-output:oster_sign -->
```text
. regsenshdfe breakdown y x w1 w2, absorb(firm year) oster r2long(1.3, relative) beta(sign) table

Regression Sensitivity Analysis, Breakdown Frontier

Analysis         : Oster (2019)                Number of obs      =         600
                                               Beta(short)        =       0.807
Treatment        : x                           Beta(medium)       =       0.562
Outcome          : y                           R2(short)          =       0.207
                                               R2(medium)         =       0.289
                                               Var(Y)             =       5.044
                                               Var(X)             =       1.605
Hypothesis       : Beta > 0                    Var(X_Residual)    =       0.955
Other Params     : R-squared(long) = .375
--------------------------------------------------------------------------------
 Beta(Hypothesis)                   Delta(Breakdown)
--------------------------------------------------------------------------------
 0.000                              100.0%
--------------------------------------------------------------------------------
```
<!-- /stata-output:oster_sign -->

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

<!-- stata-output:compare -->
```text
. regsenshdfe bounds y x w1 w2 w0, absorb(firm year) compare(w1 w2) rxbar(0 .1 .2) table

Regression Sensitivity Analysis, Bounds

Analysis         : DMP (2022)                  Number of obs      =         600
                                               Beta(short)        =       0.790
Treatment        : x                           Beta(medium)       =       0.517
Outcome          : y                           R2(short)          =       0.197
                                               R2(medium)         =       0.285
                                               Var(Y)             =       4.957
                                               Var(X)             =       1.566
                                               Var(X_Residual)    =       0.914

Hypothesis       : Beta > 0                    Breakdown Point    =        28.8%
Other Params     : rybar = +inf, cbar = 1

--------------------------------------------------------------------------------
 rxbar                             Beta
--------------------------------------------------------------------------------
 0.000                            [ 0.5172,  0.5172 ]
 0.100                            [ 0.3496,  0.6848 ]
 0.200                            [ 0.1729,  0.8615 ]
--------------------------------------------------------------------------------
```
<!-- /stata-output:compare -->

<!-- stata-output:nocompare -->
```text
. regsenshdfe bounds y x w1 w2 w0, absorb(firm year) nocompare(w0) rxbar(0 .1 .2) table

Regression Sensitivity Analysis, Bounds

Analysis         : DMP (2022)                  Number of obs      =         600
                                               Beta(short)        =       0.790
Treatment        : x                           Beta(medium)       =       0.517
Outcome          : y                           R2(short)          =       0.197
                                               R2(medium)         =       0.285
                                               Var(Y)             =       4.957
                                               Var(X)             =       1.566
                                               Var(X_Residual)    =       0.914

Hypothesis       : Beta > 0                    Breakdown Point    =        28.8%
Other Params     : rybar = +inf, cbar = 1

--------------------------------------------------------------------------------
 rxbar                             Beta
--------------------------------------------------------------------------------
 0.000                            [ 0.5172,  0.5172 ]
 0.100                            [ 0.3496,  0.6848 ]
 0.200                            [ 0.1729,  0.8615 ]
--------------------------------------------------------------------------------
```
<!-- /stata-output:nocompare -->

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

<!-- stata-output:regress -->
```text
. regress y x w1 w2 i.firm i.year

      Source |       SS           df       MS      Number of obs   =       600
-------------+----------------------------------   F(71, 528)      =     14.38
       Model |  4155.58944        71  58.5294287   Prob > F        =    0.0000
    Residual |  2148.79784       528  4.06969288   R-squared       =    0.6592
-------------+----------------------------------   Adj R-squared   =    0.6133
       Total |  6304.38728       599  10.5248536   Root MSE        =    2.0173

------------------------------------------------------------------------------
           y | Coefficient  Std. err.      t    P>|t|     [95% conf. interval]
-------------+----------------------------------------------------------------
           x |   .5620531   .0843629     6.66   0.000      .396325    .7277812
          w1 |   .7579636   .1167349     6.49   0.000     .5286418    .9872854
          w2 |    .237039   .0961581     2.47   0.014     .0481397    .4259384
             |
        firm |
          2  |  -1.177765    .907488    -1.30   0.195    -2.960496    .6049651
          3  |  -1.874688   .9075639    -2.07   0.039    -3.657568    -.091809
          4  |  -3.506707   .9121671    -3.84   0.000    -5.298629   -1.714785
          5  |  -4.512236   .9156747    -4.93   0.000    -6.311049   -2.713423
          6  |  -3.468641   .9106474    -3.81   0.000    -5.257577   -1.679704
          7  |  -1.653196   .9028742    -1.83   0.068    -3.426863    .1204705
          8  |  -1.513019   .9074759    -1.67   0.096    -3.295725    .2696878
          9  |  -1.884869   .9053791    -2.08   0.038    -3.663456   -.1062816
         10  |  -3.083981   .9092646    -3.39   0.001    -4.870201   -1.297761
         11  |   -5.37309   .9322505    -5.76   0.000    -7.204465   -3.541715
         12  |  -4.354312   .9150133    -4.76   0.000    -6.151826   -2.556799
         13  |  -1.015512   .9050396    -1.12   0.262    -2.793432    .7624087
         14  |   -.728662   .9027039    -0.81   0.420    -2.501994     1.04467
         15  |   -1.69811   .9029619    -1.88   0.061    -3.471949     .075729
         16  |  -3.835486   .9051348    -4.24   0.000    -5.613593   -2.057379
         17  |  -5.098544     .90995    -5.60   0.000     -6.88611   -3.310977
         18  |  -2.955083   .9172694    -3.22   0.001    -4.757029   -1.153138
         19  |  -1.870405   .9079581    -2.06   0.040    -3.654059   -.0867516
         20  |  -.8628285   .9024963    -0.96   0.339    -2.635753    .9100957
         21  |  -1.322503    .902774    -1.46   0.144    -3.095972    .4509672
         22  |  -3.020155   .9077282    -3.33   0.001    -4.803358   -1.236953
         23  |  -2.989838   .9206263    -3.25   0.001    -4.798378   -1.181298
         24  |  -4.578688   .9180199    -4.99   0.000    -6.382108   -2.775268
         25  |  -3.253378   .9050354    -3.59   0.000    -5.031291   -1.475466
         26  |  -.9070758   .9037248    -1.00   0.316    -2.682413    .8682618
         27  |  -.8527717   .9042086    -0.94   0.346     -2.62906    .9235164
         28  |  -1.547529   .9062369    -1.71   0.088    -3.327802    .2327431
         29  |  -3.595764   .9141561    -3.93   0.000    -5.391594   -1.799935
         30  |  -4.674752   .9170786    -5.10   0.000    -6.476322   -2.873181
         31  |  -2.952558   .9074769    -3.25   0.001    -4.735267    -1.16985
         32  |  -2.204524   .9053977    -2.43   0.015    -3.983148   -.4259001
         33  |   .0281449   .9052263     0.03   0.975    -1.750142    1.806432
         34  |  -2.918565   .9031346    -3.23   0.001    -4.692743   -1.144387
         35  |  -2.549844   .9209286    -2.77   0.006    -4.358978     -.74071
         36  |   -4.67691   .9223588    -5.07   0.000    -6.488854   -2.864967
         37  |  -3.980459   .9145401    -4.35   0.000    -5.777043   -2.183876
         38  |  -2.114559   .9097571    -2.32   0.020    -3.901747    -.327371
         39  |  -1.453312   .9077228    -1.60   0.110    -3.236504    .3298791
         40  |  -.8516614   .9027567    -0.94   0.346    -2.625097    .9217745
         41  |  -2.695841   .9074045    -2.97   0.003    -4.478407   -.9132747
         42  |  -5.346466   .9172675    -5.83   0.000    -7.148408   -3.544524
         43  |  -3.550187   .9197644    -3.86   0.000    -5.357034    -1.74334
         44  |  -2.693687    .908588    -2.96   0.003    -4.478578   -.9087957
         45  |  -2.087973   .9049075    -2.31   0.021    -3.865634   -.3103116
         46  |  -1.046489   .9187893    -1.14   0.255     -2.85142    .7584425
         47  |  -3.352509   .9038392    -3.71   0.000    -5.128072   -1.576947
         48  |  -4.056608   .9208171    -4.41   0.000    -5.865523   -2.247693
         49  |  -5.991617   .9228357    -6.49   0.000    -7.804498   -4.178737
         50  |  -3.921669    .904953    -4.33   0.000    -5.699419   -2.143918
         51  |  -1.103624   .9046813    -1.22   0.223    -2.880841    .6735925
         52  |   .3754291    .903662     0.42   0.678    -1.399785    2.150643
         53  |  -1.377921   .9035339    -1.53   0.128    -3.152884    .3970414
         54  |  -4.349469   .9127981    -4.76   0.000     -6.14263   -2.556307
         55  |  -4.385698     .91917    -4.77   0.000    -6.191377   -2.580018
         56  |  -3.905872   .9129005    -4.28   0.000    -5.699235    -2.11251
         57  |  -2.984005   .9079597    -3.29   0.001    -4.767662   -1.200348
         58  |  -.7221535   .9026944    -0.80   0.424    -2.495467     1.05116
         59  |  -.5116381   .9041725    -0.57   0.572    -2.287855    1.264579
         60  |  -3.250205    .911138    -3.57   0.000    -5.040105   -1.460304
             |
        year |
       2002  |   .4841218   .3700528     1.31   0.191    -.2428348    1.211078
       2003  |   2.213766    .382817     5.78   0.000     1.461734    2.965797
       2004  |   2.384452   .4084861     5.84   0.000     1.581994    3.186909
       2005  |    2.21306   .4028003     5.49   0.000     1.421772    3.004348
       2006  |   .9207526   .3769441     2.44   0.015     .1802583    1.661247
       2007  |   .4607009   .3694268     1.25   0.213     -.265026    1.186428
       2008  |  -.1307847   .3691857    -0.35   0.723    -.8560378    .5944684
       2009  |   .7578902   .3731755     2.03   0.043     .0247992    1.490981
       2010  |   1.763894   .3960667     4.45   0.000     .9858343    2.541954
             |
       _cons |   1.452188   .6846917     2.12   0.034     .1071341    2.797243
------------------------------------------------------------------------------
```
<!-- /stata-output:regress -->

<!-- stata-output:reghdfe -->
```text
. reghdfe y x w1 w2, absorb(firm year)
(MWFE estimator converged in 2 iterations)

HDFE Linear regression                            Number of obs   =        600
Absorbing 2 HDFE groups                           F(   3,    528) =      71.44
                                                  Prob > F        =     0.0000
                                                  R-squared       =     0.6592
                                                  Adj R-squared   =     0.6133
                                                  Within R-sq.    =     0.2887
                                                  Root MSE        =     2.0173

------------------------------------------------------------------------------
           y | Coefficient  Std. err.      t    P>|t|     [95% conf. interval]
-------------+----------------------------------------------------------------
           x |   .5620531   .0843629     6.66   0.000      .396325    .7277812
          w1 |   .7579636   .1167349     6.49   0.000     .5286418    .9872854
          w2 |    .237039   .0961581     2.47   0.014     .0481397    .4259384
       _cons |   -.071727   .0826603    -0.87   0.386    -.2341105    .0906566
------------------------------------------------------------------------------

Absorbed degrees of freedom:
-----------------------------------------------------+
 Absorbed FE | Categories  - Redundant  = Num. Coefs |
-------------+---------------------------------------|
        firm |        60           0          60     |
        year |        10           1           9     |
-----------------------------------------------------+

. dis %12.8f e(r2)
  0.65915834

. dis %12.8f e(r2_within)
  0.28872647
```
<!-- /stata-output:reghdfe -->

The coefficient and overall R-squared agree across estimators. Overall R-squared
is 0.65915834. Within R-squared is 0.28872647 and measures the fraction of variation
explained after partialling out the fixed effects.

### 8.2 Fixed effects excluded from the comparison group

```stata
regsensitivity bounds y x w1 w2 i.firm i.year, compare(w1 w2) rxbar(0 .1 .2 .3) table
regsenshdfe bounds y x w1 w2, absorb(firm year) rxbar(0 .1 .2 .3) table
```

<!-- stata-output:native_excluded -->
```text
. regsensitivity bounds y x w1 w2 i.firm i.year, compare(w1 w2) rxbar(0 .1 .2 .3) table

Regression Sensitivity Analysis, Bounds

Analysis         : DMP (2022)                  Number of obs      =         600
                                               Beta(short)        =       0.807
Treatment        : x                           Beta(medium)       =       0.562
Outcome          : y                           R2(short)          =       0.207
                                               R2(medium)         =       0.289
                                               Var(Y)             =       5.044
                                               Var(X)             =       1.605
                                               Var(X_Residual)    =       0.955

Hypothesis       : Beta > 0                    Breakdown Point    =          32%
Other Params     : rybar = +inf, cbar = 1

--------------------------------------------------------------------------------
 rxbar                             Beta
--------------------------------------------------------------------------------
 0.000                            [ 0.5621,  0.5621 ]
 0.100                            [ 0.4007,  0.7234 ]
 0.200                            [ 0.2308,  0.8933 ]
 0.300                            [ 0.0411,  1.0830 ]
--------------------------------------------------------------------------------
```
<!-- /stata-output:native_excluded -->

<!-- stata-output:dmp_bounds -->
```text
. regsenshdfe bounds y x w1 w2, absorb(firm year) rxbar(0 .1 .2 .3) table

Regression Sensitivity Analysis, Bounds

Analysis         : DMP (2022)                  Number of obs      =         600
                                               Beta(short)        =       0.807
Treatment        : x                           Beta(medium)       =       0.562
Outcome          : y                           R2(short)          =       0.207
                                               R2(medium)         =       0.289
                                               Var(Y)             =       5.044
                                               Var(X)             =       1.605
                                               Var(X_Residual)    =       0.955

Hypothesis       : Beta > 0                    Breakdown Point    =          32%
Other Params     : rybar = +inf, cbar = 1

--------------------------------------------------------------------------------
 rxbar                             Beta
--------------------------------------------------------------------------------
 0.000                            [ 0.5621,  0.5621 ]
 0.100                            [ 0.4007,  0.7234 ]
 0.200                            [ 0.2308,  0.8933 ]
 0.300                            [ 0.0411,  1.0830 ]
--------------------------------------------------------------------------------
```
<!-- /stata-output:dmp_bounds -->

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

<!-- stata-output:native_included -->
```text
. regsensitivity bounds y x w1 w2 i.firm i.year, rxbar(0 .1 .2 .3) table

Regression Sensitivity Analysis, Bounds

Analysis         : DMP (2022)                  Number of obs      =         600
                                               Beta(short)        =       1.296
Treatment        : x                           Beta(medium)       =       0.562
Outcome          : y                           R2(short)          =       0.449
                                               R2(medium)         =       0.659
                                               Var(Y)             =      10.525
                                               Var(X)             =       2.814
                                               Var(X_Residual)    =       0.955

Hypothesis       : Beta > 0                    Breakdown Point    =        19.6%
Other Params     : rybar = +inf, cbar = 1

--------------------------------------------------------------------------------
 rxbar                             Beta
--------------------------------------------------------------------------------
 0.000                            [ 0.5621,  0.5621 ]
 0.100                            [ 0.2874,  0.8367 ]
 0.200                            [-0.0141,  1.1382 ]
 0.300                            [-0.3850,  1.5091 ]
--------------------------------------------------------------------------------
```
<!-- /stata-output:native_included -->

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

## Reproducing the output

Run `do test/readme_output.do` from the repository root to reproduce the displayed
Stata output. The script sets `linesize 120`; the README does not reformat the
output. The recorded source is [test/readme_output.txt](test/readme_output.txt).

After updating that file, run `python test/sync_readme_output.py` to synchronize
the output blocks in both READMEs. Use `python test/sync_readme_output.py --check`
for character-for-character verification. Explanations remain outside the raw
output blocks.

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
