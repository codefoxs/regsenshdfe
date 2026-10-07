*===============================================================================
* make_panel.do -- Reproducible example data; no private or downloaded inputs.
* In : none
* Out: simulated data in memory
*===============================================================================
version 15.0
clear
set seed 20261008
set obs 600
gen firm = ceil(_n / 10)
gen year = mod(_n - 1, 10) + 2001
gen industry = mod(firm - 1, 3) + 1
gen w1 = rnormal()
gen w2 = rnormal()
gen w0 = rnormal()
gen x = 0.8*w1 - 0.4*w2 + 0.2*w0 + sin(firm) + cos(year) + rnormal()
gen y = 0.6*x + 0.8*w1 + 0.3*w2 + 0.4*w0 + 2*sin(firm) + cos(year) + 2*rnormal()
label variable y "Simulated outcome"
label variable x "Simulated treatment"
