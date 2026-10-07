------------------------------------------------------------------------------------------------------------------------

. cd "D:/Code/Github/regsenshdfe"
D:\Code\Github\regsenshdfe

. cap noisily do "test/readme_output.do"

. * README output capture. run from the repository root.
. * Output markers delimit verbatim documentation excerpts.
. version 15.0

. set more off

. set linesize 120

. adopath ++ "."
  [1]              "."
  [2]  (BASE)      "D:\Program\StataNow/ado\base/"
  [3]  (SITE)      "D:\Program\StataNow/ado\site/"
  [4]  (PERSONAL)  "D:\Program\StataNow\ado\personal/"
  [5]  (PLUS)      "D:\Program\StataNow\ado\plus/"
  [6]  (OLDPLACE)  "D:\Program\StataNow\ado\personal/"
  [7]              "D:\Program\StataNow\ado\personal\r_regressions"
  [8]              "D:\Program\StataNow\ado\personal\Bacondecomp"
  [9]              "D:\Program\StataNow\ado\personal\xthreg2"
  [10]             "D:\Program\StataNow\ado\personal\chatgpt"

. do test/make_panel.do

. *===============================================================================
. * make_panel.do -- Reproducible example data; no private or downloaded inputs.
. * In : none
. * Out: simulated data in memory
. *===============================================================================
. version 15.0

. clear

. set seed 20261008

. set obs 600
Number of observations (_N) was 0, now 600.

. gen firm = ceil(_n / 10)

. gen year = mod(_n - 1, 10) + 2001

. gen industry = mod(firm - 1, 3) + 1

. gen w1 = rnormal()

. gen w2 = rnormal()

. gen w0 = rnormal()

. gen x = 0.8*w1 - 0.4*w2 + 0.2*w0 + sin(firm) + cos(year) + rnormal()

. gen y = 0.6*x + 0.8*w1 + 0.3*w2 + 0.4*w0 + 2*sin(firm) + cos(year) + 2*rnormal()

. label variable y "Simulated outcome"

. label variable x "Simulated treatment"

. 
end of do-file

. * Preserve precision when the upstream command replaces working variables.
. recast double y x w1 w2

. 
. dis "BEGIN_README_dmp_bounds"
BEGIN_README_dmp_bounds

. regsenshdfe bounds y x w1 w2, absorb(firm year) compare(w1 w2) rxbar(0 0.1 0.2 0.3) table

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

. dis "END_README_dmp_bounds"
END_README_dmp_bounds

. 
. dis "BEGIN_README_dmp_breakdown"
BEGIN_README_dmp_breakdown

. regsenshdfe breakdown y x w1 w2, absorb(firm year) compare(w1 w2) cbar(0(0.2)1) plot

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

. dis "END_README_dmp_breakdown"
END_README_dmp_breakdown

. 
. dis "BEGIN_README_dmp_beta"
BEGIN_README_dmp_beta

. regsenshdfe breakdown y x w1 w2, absorb(firm year) compare(w1 w2) beta(0.2, lb) cbar(1) table

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

. dis "END_README_dmp_beta"
END_README_dmp_beta

. 
. dis "BEGIN_README_oster_eq"
BEGIN_README_oster_eq

. regsenshdfe bounds y x w1 w2, absorb(firm year) compare(w1 w2) oster delta(0 0.5 1, eq) r2long(1.3, relative) table
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

. dis "END_README_oster_eq"
END_README_oster_eq

. 
. dis "BEGIN_README_oster_bound"
BEGIN_README_oster_bound

. regsenshdfe bounds y x w1 w2, absorb(firm year) compare(w1 w2) oster delta(0 0.5 1, bound) r2long(0.95) table

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

. dis "END_README_oster_bound"
END_README_oster_bound

. 
. dis "BEGIN_README_oster_zero"
BEGIN_README_oster_zero

. regsenshdfe breakdown y x w1 w2, absorb(firm year) compare(w1 w2) oster r2long(1.3, relative) beta(0, eq) table

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

. dis "END_README_oster_zero"
END_README_oster_zero

. 
. dis "BEGIN_README_oster_sign"
BEGIN_README_oster_sign

. regsenshdfe breakdown y x w1 w2, absorb(firm year) compare(w1 w2) oster r2long(1.3, relative) beta(sign) table

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

. dis "END_README_oster_sign"
END_README_oster_sign

. 
. dis "BEGIN_README_compare"
BEGIN_README_compare

. regsenshdfe bounds y x w1 w2 w0, absorb(firm year) compare(w1 w2) rxbar(0 0.1 0.2) table

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

. dis "END_README_compare"
END_README_compare

. 
. dis "BEGIN_README_nocompare"
BEGIN_README_nocompare

. regsenshdfe bounds y x w1 w2 w0, absorb(firm year) nocompare(w0) rxbar(0 0.1 0.2) table

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

. dis "END_README_nocompare"
END_README_nocompare

. 
. dis "BEGIN_README_regress"
BEGIN_README_regress

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

. dis "END_README_regress"
END_README_regress

. 
. dis "BEGIN_README_reghdfe"
BEGIN_README_reghdfe

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

. dis "END_README_reghdfe"
END_README_reghdfe

. 
. dis "BEGIN_README_native_excluded"
BEGIN_README_native_excluded

. regsensitivity bounds y x w1 w2 i.firm i.year, compare(w1 w2) rxbar(0 0.1 0.2 0.3) table

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

. dis "END_README_native_excluded"
END_README_native_excluded

. 
. dis "BEGIN_README_native_included"
BEGIN_README_native_included

. regsensitivity bounds y x w1 w2 i.firm i.year, rxbar(0 0.1 0.2 0.3) table

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

. dis "END_README_native_included"
END_README_native_included

. 
. dis "README_OUTPUT_COMPLETED"
README_OUTPUT_COMPLETED

. 
end of do-file

. dis "CAPTURE_RC=" _rc
CAPTURE_RC=0