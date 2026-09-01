{smcl}
{title:Title}

{phang}
{bf:regsenshdfe} {hline 2} regsensitivity with (high-dimensional) fixed effects, via reghdfe

{title:Syntax}

{p 8 17 2}
{cmd:regsenshdfe} {it:subcommand}
{it:depvar} {it:indepvar} {it:controls}
{ifin}{cmd:,} {opt absorb(varlist)}
[{opt compare(varlist)} {opt nocompare(varlist)} {it:regsensitivity_options}]

{pstd}
{it:subcommand} is {bf:bounds} or {bf:breakdown} (regsensitivity's own subcommands).
{it:depvar}/{it:indepvar}/{it:controls} must be plain numeric variables -- no
{cmd:i.}/{cmd:c.} factor-variable syntax, since each one is residualized
individually with {helpb reghdfe}.

{title:Description}

{pstd}
{cmd:regsensitivity} (Masten and Poirier 2026, AER) computes its sensitivity
statistics with plain {cmd:regress}, so a fixed effect entered as
{cmd:i.firm} gets literally expanded into dummy columns -- fine for a
few dozen levels (e.g. state), infeasible for firm or firm-year panels.

{pstd}
{cmd:regsenshdfe} is a thin wrapper: it residualizes {it:depvar}, {it:indepvar},
and every variable in {it:controls} (and, separately, any variable named in
{opt compare()}/{opt nocompare()}) against the fixed effects in
{opt absorb()} using {helpb reghdfe}, then calls
{helpb regsensitivity:regsensitivity} {it:subcommand} on the residuals. By the
Frisch-Waugh-Lovell theorem this reproduces the coefficients/R-squared a
single regression with the fixed effects included as covariates would give,
without ever building the dummy matrix.

{pstd}
After calling {cmd:regsenshdfe}, {cmd:{help regsensitivity_plot:regsensitivity plot}}
works exactly as usual (it only reads {cmd:e()}, saved by the underlying
{cmd:regsensitivity} call).

{title:Options}

{phang}
{opt absorb(varlist)} fixed effects to partial out, passed straight through
to {helpb reghdfe}'s own {opt absorb()} (so {cmd:firm year} or
{cmd:firm#year}-style syntax works exactly as it does in reghdfe).

{phang}
{opt compare(varlist)}/{opt nocompare(varlist)} same meaning as in
{helpb regsensitivity_bounds:regsensitivity bounds}; the variables must
already be part of {it:controls}.

{phang}
any other {it:regsensitivity_options} (e.g. {opt dmp}, {opt oster},
{opt rxbar()}, {opt delta()}, {opt beta()}, {opt plot}, {opt table}) are
passed straight through.

{title:Caveat}

{pstd}
This is a local extension, not part of the official {cmd:regsensitivity}
package -- verify against a case you can also compute directly (e.g. a
low-cardinality fixed effect via {cmd:i.}) before trusting it on a design
you can't cross-check.

{title:Example}

{phang}{cmd:. regsenshdfe bounds y x w1 w2, absorb(firm year) compare(w1 w2) plot}{p_end}
