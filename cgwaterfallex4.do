/**** A. Attainment along the Education Pipeline ****/
/**** 4. Progression by Students' On-Track Status After Ninth Grade ****/
{
di "Where is the CG_Analysis file located on your computer?"  _n			 ///   
"Enter the file path to it here" _request(_cgdemofp)

// Step 1: Load the college-going analysis file into Stata
use `"`cgdemofp'/CG_Analysis"', clear

di "Enter the starting year for the cohort" _request(_chrt_ninth_begin)
di "Enter the ending year for the cohort" _request(_chrt_ninth_end)

// Step 2: Keep students in ninth grade cohorts you can observe persisting to the second year of college
keep if (chrt_ninth >= `chrt_ninth_begin' & chrt_ninth <= `chrt_ninth_end')
keep if ontrack_sample == 1
// Step 3: Generate on-track indicators that take into account students’ GPAs upon completion of their first year in high school
label define ot 1 "Off-Track to Graduate" ///
2 "On-Track to Graduate, GPA < 3.0" ///
3 "On-Track to Graduate, GPA >= 3.0", replace
gen ontrack_endyr1_gpa = .
replace ontrack_endyr1_gpa = 1 if ontrack_endyr1 == 0
replace ontrack_endyr1_gpa = 2 if ontrack_endyr1 == 1 & cum_gpa_yr1 < 3 & !mi(cum_gpa_yr1)
replace ontrack_endyr1_gpa = 3 if ontrack_endyr1 == 1 & cum_gpa_yr1 >= 3 & !mi(cum_gpa_yr1)
assert !mi(ontrack_endyr1_gpa) if !mi(ontrack_endyr1) & !mi(cum_gpa_yr1)
label values ontrack_endyr1_gpa ot
// Step 4: Create variables for the outcomes "regular diploma recipients", "seamless transitioners" and "second year persisters"
gen grad = (!mi(chrt_grad) & ontime_grad == 1)
gen seamless_transitioners_any = (enrl_1oct_ninth_yr1_any == 1 & ontime_grad == 1)
gen second_year_persisters = (enrl_1oct_ninth_yr1_any == 1 & enrl_1oct_ninth_yr2_any == 1 & ontime_grad == 1)
// Step 5: Create average outcomes by on-track status at the end of ninth grade
collapse (mean) grad seamless_transitioners_any second_year_persisters (count) N=sid, by(ontrack_endyr1_gpa)
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
reshape long time, i(ontrack_endyr1_gpa N)
// 3. Create a single variable that takes on all the outcomes of interest
bysort ontrack_endyr1_gpa: gen outcome = 100 if time == 1
bysort ontrack_endyr1_gpa: replace outcome = grad if time == 2
bysort ontrack_endyr1_gpa: replace outcome = seamless_transitioners_any if time == 3
bysort ontrack_endyr1_gpa: replace outcome = second_year_persisters if time == 4
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
// 3. Determine the location of the label for each on-track outcome
sort ontrack_endyr1_gpa _j
foreach obsnum of numlist 4(4)12 {
local ontrack`obsnum'_label = outcome + 7 in `obsnum'
}
#delimit ;
twoway (connected outcome time if ontrack_endyr1_gpa == 1,
sort lcolor(dkorange) mlabel(outcome) mlabc(black) mlabs(vsmall) mlabp(3)
mcolor(dkorange) msymbol(circle) msize(small))
(connected outcome time if ontrack_endyr1_gpa == 2, sort lcolor(navy*.6)
mlabel(outcome) mlabs(vsmall) mlabp(3) mlabc(black) mcolor(navy*.6)
msymbol(square) msize(small))
(connected outcome time if ontrack_endyr1_gpa == 3, sort lcolor(navy*.9)
mlabel(outcome) mlabs(vsmall) mlabp(3) mlabc(black) mcolor(navy*.9)
msymbol(diamond) msize(small))
(connected outcome time if ontrack_endyr1_gpa == 4, sort lcolor(navy*.3)
mlabel(outcome) mlabs(vsmall) mlabp(3) mlabc(black) mcolor(navy*.3)
msymbol(triangle) msize(small)),
title("Student Progression from 9th Grade through College", size(medium))
ylabel(, nogrid)
subtitle("by Course Credits and GPA after First High School Year", size(medsmall))
xscale(range(.8(.2)4.2)) xlabel(1 2 3 4, valuelabels labsize(vsmall)) xtitle("")
yscale(range(0(20)100)) ylabel(0(20)100, labsize(small) format(%9.0f))
ytitle("Percent of Ninth Graders" " ")
text(`ontrack4_label' 4 "Off-Track to Graduate", color(dkorange) size(2))
text(`ontrack8_label' 4 "On-Track to Graduate," "GPA<3.0", color(navy*.8) size(2))
text(`ontrack12_label' 4 "On-Track to Graduate," "GPA>=3.0", color(navy*1.3) size(2))
legend(off)
graphregion(color(white) fcolor(white) lcolor(white))
plotregion(color(white) fcolor(white) lcolor(white))
note(" " "Sample: `chrt_label' ${agency_name} first-time ninth graders. Students who transferred into or out of ${agency_name} are excluded from the sample." "Postsecondary enrollment outcomes from NSC matched records. All other data are from ${agency_name} administrative records.", size(vsmall));
#delimit cr
// graph export "A4_Progression_by_OnTrack_Ninth.emf", replace
// graph save "A4_Progression_by_OnTrack_Ninth.gph", replace
}
