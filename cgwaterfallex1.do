/**** A. Attainment along the Education Pipeline ****/
/**** 1. Overall Progression ****/
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
// Step 4: Create agency-level average outcomes
// 1. Preserve the data (to work with the data in its existing structure later on)
preserve
// 2. Calculate the mean of each outcome variable by agency
collapse (mean) grad seamless_transitioners_any second_year_persisters (count) N = sid
// 3. Create a string variable called school_name equal to "${agency_name} Average"
gen school_name = "${agency_name} AVERAGE"
// 4. Save this data as a temporary file
tempfile agency_level
save `agency_level'
// 5. Restore the data to the original form
restore
// Step 5: Create school-level maximum and minimum outcomes
// 1. Create a variable school_name that takes on the value of students’ first high school attended
gen school_name = first_hs_name
// 2. Calculate the mean of each outcome variable by first high school attended
collapse (mean) grad seamless_transitioners second_year_persisters (count) N = sid, by(school_name)
// 3. Identify the agency maximum values for each of the three outcome variables
preserve
collapse (max) grad seamless_transitioners_any second_year_persisters (count) N
gen school_name = "${agency_name} MAX HS"
tempfile agency_max
save `agency_max'
restore
// 4. Identify the agency minimum values for each of the three outcome variables
preserve
collapse (min) grad seamless_transitioners_any second_year_persisters (count) N
gen school_name = "${agency_name} MIN HS"
tempfile agency_min
save `agency_min'
restore
// 5. Append the three tempfiles to the school-level file loaded into Stata
append using `agency_level'
append using `agency_max'
append using `agency_min'
// Step 6: Format the outcome variables so they read as percentages in the graph
foreach var of varlist grad seamless_transitioners_any second_year_persisters {
replace `var' = (`var' * 100)
format `var' %9.1f
}
// Step 7: Reformat the data file so that one variable contains all the outcomes of interest
// 1. Create 4 observations for each school: ninth grade, hs graduation, seamless college transition and second-year persistence
foreach i of numlist 1/4 {
gen time`i' = `i'
}
// 2. Reshape the data file from wide to long
reshape long time , i(school_name N)
// 3. Create a single variable that takes on all the outcomes of interest
bysort school_name: gen outcome = 100 if time == 1
bysort school_name: replace outcome = grad if time == 2
bysort school_name: replace outcome = seamless_transitioners_any if time == 3
bysort school_name: replace outcome = second_year_persisters if time == 4
format outcome %9.1f
// Step 8: Prepare to graph the results
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
// Step 9: Graph the results
#delimit ;
twoway (connected outcome time if school_name == "${agency_name} AVERAGE",
sort lcolor(dkorange) mlabel(outcome) mlabc(black) mlabs(vsmall) mlabp(12)
mcolor(dknavy) msymbol(circle) msize(small))
(connected outcome time if school_name == "${agency_name} MAX HS", sort lcolor(black)
lpattern(dash) mlabel(outcome) mlabs(vsmall) mlabp(12) mlabc(black)
mcolor(black) msize(small))
(connected outcome time if school_name == "${agency_name} MIN HS", sort lcolor(blue)
lpattern(dash) mlabel(outcome) mlabs(vsmall) mlabp(12) mlabc(black)
mcolor(black) msize(small)),
title("Student Progression from 9th Grade Through College")
subtitle("${agency_name} Average", size(medsmall))
xscale(range(.8(.2)4.2))
xtitle("") xlabel(1 2 3 4 , valuelabels labsize(vsmall))
ytitle("Percent of Ninth Graders")
yscale(range(0(20)100))
ylabel(0(20)100, nogrid)
legend(col(1) position(2) size(vsmall)
label(1 "${agency_name} Average")
label(2 "${agency_name} Max HS")
label(3 "${agency_name} Min HS")
ring(0) region(lpattern(none) lcolor(none) fcolor(none)))
graphregion(color(white) fcolor(white) lcolor(white))
plotregion(color(white) fcolor(white) lcolor(white))
note(" " "Sample: `chrt_label' ${agency_name} first-time ninth graders. Postsecondary enrollment outcomes from NSC matched records." "All other data from ${agency_name} administrative records.", size(vsmall));
#delimit cr
// graph export "A1_Overall_Progression.emf", replace
// graph save "A1_Overall_Progression.gph", replace
}
