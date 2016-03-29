
{
di "Where is the CG_Analysis file located on your computer?"  _n			 ///   
"Enter the file path to it here" _request(_cgdemofp)

// Step 1: Load the college-going analysis file into Stata
use `"`cgdemofp'/CG_Analysis"', clear

di "Enter the starting year for the cohort" _request(_chrt_ninth_begin)
di "Enter the ending year for the cohort" _request(_chrt_ninth_end)

// Step 2: Keep students in ninth grade cohorts you can observe persisting to the second year of college
keep if (chrt_ninth >= `chrt_ninth_begin' & chrt_ninth <= `chrt_ninth_end')
// Step 3: Create variables for the outcomes "regular diploma recipients", "seamless transitioners" and "second year persisters"
gen grad = (!mi(chrt_grad) & ontime_grad == 1)
gen seamless_transitioners_any = (enrl_1oct_ninth_yr1_any == 1 & ontime_grad == 1)
gen second_year_persisters = (enrl_1oct_ninth_yr1_any == 1 & enrl_1oct_ninth_yr2_any == 1 & ontime_grad == 1)
// Step 4: Create average outcomes by race/ethnicity
collapse (mean) grad seamless_transitioners_any second_year_persisters (count) N=sid, by(race_ethnicity)
// Step 5: Format the outcome variables so they read as percentages in the graph
foreach var of varlist grad seamless_transitioners_any second_year_persisters {
replace `var' = (`var' * 100)
format `var' %9.1f
}
// Step 6: Reformat the data file so that one variable contains all the outcomes of interest
// 1. Create 4 observations for each school: ninth grade, hs graduation, seamless college transition and second-year persistence
foreach i of numlist 1/4 {
gen time`i' = `i'
}
// 2. Keep only African-American, Asian-American, Hispanic, and White students
keep if race_ethnicity == 1 | race_ethnicity == 2 | race_ethnicity == 3 | race_ethnicity == 5
sort race_ethnicity
gen sortorder = _n
// 3. Reshape the data file from wide to long
reshape long time , i(sortorder)
// 4. Create a single variable that takes on all the outcomes of interest
bysort race_ethnicity: gen outcome = 100 if time == 1
bysort race_ethnicity: replace outcome = grad if time == 2
bysort race_ethnicity: replace outcome = seamless_transitioners_any if time == 3
bysort race_ethnicity: replace outcome = second_year_persisters if time == 4
format outcome %9.1f
// Step 7: Prepare to graph the results
// 1. Label the outcome
label define outcome 1 "Ninth Graders" 2 "On-time Graduates" ///
3 "Seamless College Transitioners" 4 "Second Year Persisters"
label values time outcome
// 2. Generate a cohort label to be used in the footnote for the graph
local temp_begin = `chrt_ninth_begin'-1
local temp_end = `chrt_ninth_end'-1
if `chrt_ninth_begin'==`chrt_ninth_end' {
local chrt_label "`temp_begin'-`chrt_ninth_begin'"
}
else {
local chrt_label "`temp_begin'-`chrt_ninth_begin' through `temp_end'-`chrt_ninth_end'"
}
// Step 8: Graph the results
#delimit;
twoway (connected outcome time if race_ethnicity==1,
sort lcolor(dknavy) mlabel(outcome) mlabc(black)mlabs(vsmall) mlabp(12)
mcolor(dknavy) msymbol(circle) msize(small))
(connected outcome time if race_ethnicity==2 , sort lcolor(lavender) lpattern(dash)
mlabel(outcome) mlabs(vsmall) mlabp(12) mlabc(black) mcolor(lavender) msize(small))
(connected outcome time if race_ethnicity==3 , sort lcolor(dkgreen) lpattern(dash)
mlabel(outcome) mlabs(vsmall) mlabp(12) mlabc(black) mcolor(dkgreen) msize(small))
(connected outcome time if race_ethnicity==5 , sort lcolor(orange) mlabel(outcome) mlabc(black)
mlabs(vsmall) mlabp(12) mcolor(orange) msymbol(circle) msize(small)),
title("Student Progression from Ninth Grade through College", size(medium))
subtitle("By Student Race/Ethnicity", size(medsmall))
xscale(range(.8(.2)4.2))
xlabel(1 2 3 4 , valuelabels labsize(vsmall))
ytitle("Percent of Ninth Graders")
yscale(range(0(20)100))
ylabel(0(20)100, nogrid)
xtitle("", color(white))
legend(order(2 4 1 3) col(1) position(2) size(vsmall)
label(1 "African American Students")
label(2 "Asian American Students")
label(3 "Hispanic Students")
label(4 "White Students")
ring(0) region(lpattern(none) lcolor(none) fcolor(none)))
graphregion(color(white) fcolor(white) lcolor(white))
plotregion(color(white) fcolor(white) lcolor(white))
note(" " "Sample: `chrt_label' ${agency_name} first-time ninth graders." "Postsecondary enrollment outcomes from NSC matched records. All other data from ${agency_name} administrative records." , size(vsmall));
#delimit cr
// graph export "A2_Progression_by_RaceEthnicity.emf", replace
// graph save "A2_Progression_by_RaceEthnicity.gph", replace
}
