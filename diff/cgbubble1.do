// Step 1: Load the college-going analysis file into Stata
use "analysis/CG_Analysis", clear
// Step 2: Keep students in high school graduation cohorts you can observe enrolling in college the fall after graduation AND have non-missing eighth grade test scores
local chrt_grad_begin = 2008
local chrt_grad_end = 2009
keep if (chrt_grad >= `chrt_grad_begin' & chrt_grad <= `chrt_grad_end')
keep if qrt_8_math != .
// Step 3: Create agency- and school-level average outcomes for each quartile
// 1. Calculate the mean of each outcome variable by high school
collapse (sum) enrl_1oct_grad_yr1_any hs_diploma, by(last_hs_name qrt_8_math)
gen pct_enrl = enrl_1oct_grad_yr1_any / hs_diploma * 100
// 2. Calculate the mean of each outcome variable for the agency as a whole
egen num = sum(enrl_1oct_grad_yr1_any), by(qrt_8_math)
egen denom = sum(hs_diploma), by(qrt_8_math)
gen agency_avg = num / denom * 100
drop num denom
// Step 4: Create a variable to identify the test score quartile
gen agency_quartile_code = .
forvalues qrt = 1(1)4 {
local qrt_plot = `qrt' * 2
replace agency_quartile_code = 1.`qrt_plot' if qrt_8_math == `qrt'
}
// Step 5: Prepare to graph the results
// Generate a cohort label to be used in the footnote for the graph
local temp_begin = `chrt_grad_begin'-1
local temp_end = `chrt_grad_end'-1
if `chrt_grad_begin'==`chrt_grad_end' {
local chrt_label "`temp_begin'-`chrt_grad_begin'"
}
else {
local chrt_label "`temp_begin'-`chrt_grad_begin' through `temp_end'-`chrt_grad_end'"
}
// Step 6: Graph the results
#delimit ;
graph twoway scatter pct_enrl agency_quartile_code [aweight = hs_diploma],
msymbol(Oh) msize(vsmall) mcolor(dknavy) ||
scatter agency_avg agency_quartile_code,
mcolor(cranberry) msymbol(D) msize(small)
title("College Enrollment Rates Among High School"
"Graduates Within Quartile Of Prior Achievement,"
"By High School", size(med))
xscale(range(1 6)) yscale(range(0 105)) ylabel(0 20 40 60 80 100)
xlabel(1.2 "Q1" 1.4 "Q2" 1.6 "Q3" 1.8 "Q4", labsize(small))
xtitle(" " "Quartile of Prior Achievement") ytitle("Percent" " ")
ylabel(,nogrid) legend(off)
graphregion(color(white) fcolor(white) lcolor(white))
plotregion(color(white) fcolor(white) lcolor(white))
xline(2)
note("Sample: `chrt_label' high school graduates. Postsecondary enrollment outcomes from NSC matched records."
"All other data from ${agency_name} administrative records.", size(vsmall));
#delimit cr
graph export "D7_Col_Enrl_by_Eighth_Qrt_Bubbles.emf", replace
graph save "D7_Col_Enrl_by_Eighth_Qrt_Bubbles.gph", replace
