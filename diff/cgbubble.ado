// Drop program from memory
cap prog drop cgbubble

// Declare the file as defining a program with r-class property
prog def cgbubble, rclass

// Specify the version which under which Stata should interpret code
version 13.1

// Define the syntax structure of the program
syntax [using/] [if] , COHortid(string asis)  ///   
Years(numlist min=2 max=2 sort) ///   
QTILEmath(string asis) ///    
SCHname(string asis) ///   
DIPLoma(string asis)  ///   
ENRollyear1(string asis) ///   
[STRetch scheme(passthru) ///   
SAVing(string asis)  ///   
fmt(string asis) ///   
JITter(passthru)]

// Step 1: 
// Preserve the current state of the user's session
preserve

// Check to see if you need to load a file or if the data is in memory
if `"`using'"' != "" {

// Load the file passed by the user
use `"`using'"', clear

} // End IF Block for loading file

// Make sure all of the variables are present
confirm v `cohortid' `qtilemath' `schname' `diploma' `enrollyear1'

// Step 2: 
// Parse the year values to make them simpler to reference later
loc syear `: word 1 of `years''
loc eyear `: word 2 of `years''

// Mark records that would be excluded
marksample touse

// Make sure the quartile values are either missing or 1-4
assert inrange(`qtilemath', 1, 4) | mi(`qtilemath')

/* Keep records from the date range who aren't missing the math quartile
and that also satisfy any thing passed to the if condition */
keep if `touse' & inrange(`cohortid', `syear', `eyear') & !mi(`qtilemath')

// Define value labels for the math quartiles
la def `qtilemath' 1 `""1{superscript:st}" "Quartile""' ///   
2 `""2{superscript:nd}" "Quartile""' ///   
3 `""3{superscript:rd}" "Quartile""' ///   
4 `""4{superscript:th}" "Quartile""', modify

// Apply the new value labels to the variable
la val `qtilemath' `qtilemath'

/* Set aside namespace for temporary variables. These have the benefit 
of being automatically garbage collected when the program finishes 
executing which means you don't use up as much of your system's RAM */
tempvar enrl num den avg qcode numsch wgt

/* Create a numeric school variable so the data can be returned to the
end user as a matrix in the r(bubbledata) */
qui: encode `schname', gen(`numsch')

// Get all of the unique school values
qui: levelsof `numsch', loc(schs)

// Create a local macro to store the value labels
loc schlab la def school

// Return each of the codes with its label in a macro
foreach v of loc schs {

// Add the value label definition to the school value label macro
loc schlab `schlab' `v' "`: label (`numsch') `v''"

} // End Loop to store school value labels

// Return the local to the user when the program completes execution
ret loc schlabels = `"`schlab'"'

// Step 3: 
/* Total number of students by quartile and school that graduated and 
enrolled after graduating. */
collapse (sum) `enrollyear1' `diploma', by(`numsch' `qtilemath') 

// Percent of students enrolling the year after graduation
qui: g `enrl' = (`enrollyear1' / `diploma') * 100

// Number of students enrolled year after graduation by math quartile
qui: egen `num' = sum(`enrollyear1'), by(`qtilemath')

// Number of students who graduated by math quartile
qui: egen `den' = sum(`diploma'), by(`qtilemath')

// Percentage of graduates enrolling the year after graduation by quartile
qui: g `avg' = (`num' / `den') * 100

// Step 4: 
// Check to see if the user wants the values spread out along the x-axis
if "`stretch'" == "" {

// Create a variable to identify the test score quartile
qui: g `qcode' = cond(`qtilemath' == 1, 1.2,  ///   
cond(`qtilemath' == 2, 1.4, ///   
cond(`qtilemath' == 3, 1.6, 1.8)))

// Store modified versions of the variable labels for the graph
loc xlab1 1.2 "1{superscript:st} Quartile"
loc xlab2 1.4 "2{superscript:nd} Quartile"
loc xlab3 1.6 "3{superscript:rd} Quartile"
loc xlab4 1.8 "4{superscript:th} Quartile"

// Create a macro with the syntax for the xlabel option of the graph
loc xlab xlab(`xlab1' `xlab2' `xlab3' `xlab4', angle(45) labs(small))
loc stem la def quartile 
loc labs 1 `"`xlab1'"' 2 `"`xlab2'"' 3 `"`xlab3'"' 4 `"`xlab4'"'
// Return the xlabel values for `qtilemath' in macros
ret loc qtilelab = `"`stem' `labs', modify"'

// Create a macro with the syntax for the xscale option of the graph
loc xsca xsca(range(1 6))

// Create a macro with the xline syntax for the xline option
loc xline xline(2, lp(dot))

// Scale the value of the diploma value to avoid the points being too large
qui: g `wgt' = `diploma' ^ .45

} // End IF Block for condensed graph

// If user wants more separation between points
else {

// Clone the quartile value into the variable used for the x-axis
qui: clonevar `qcode' = `qtilemath'

// Create xlabel syntax telling it to use the value labels
loc xlab xlab(, val)

// Create the xscale syntax for scaling the xvariable values
loc xsca xsca(range(0.5 4.5))

// Create a null xline local
loc xline ""

// Get value labels
loc xlab1 `: label (`qtilemath') 1'
loc xlab2 `: label (`qtilemath') 2'
loc xlab3 `: label (`qtilemath') 3'
loc xlab4 `: label (`qtilemath') 4'

loc stem la def quartile 
loc labs 1 `"`xlab1'"' 2 `"`xlab2'"' 3 `"`xlab3'"' 4 `"`xlab4'"'

// Return the xlabel values for `qtilemath' in macros
ret loc qtilelab = `"`stem' `labs', modify"'

// Scale the value of the diploma value to avoid the points being too large
qui: g `wgt' = `diploma' ^ .75

} // End ELSE Block for stretched view

// Step 5: 
// Are the start and end years the same value?
if `syear' == `eyear' {

// If so modify the starting value to show the start of the year
loc start "`= `syear' - 1'"

// Leave the end in place
loc end "`eyear'"

} // End IF Block for same valued start and end years

// If they are different
else {

// Create a string showing the start - end year pairs for the start
loc start "`= `syear' - 1' - `syear'" 

// Create a string showing the start - end year pairs for the end
loc end "`= `eyear' - 1' - `eyear'"

} // End ELSE Block for two values for years

/* Store the notes by sentence.  I use the numbers for notes/titles to 
indicate how I would like them displayed with regards to line breaks.  
So, note1a and note1b would be on the same line, and note 2a would be 
on the following line: */ 
loc note1a "Sample: `start' through `end' high school graduates." 
loc note1b "Postsecondary enrollment outcomes from NSC matched records."
loc note2a "All other data from ${agency_name} administrative records."
loc note2b "{superscript:1} Values weighted by HS Graduates"

// Store optional arguments for the notes parameter
loc noteopts size(vsmall) pos(7) 

// Store the syntax for the notes optional argument in a local macro
loc notes note("`note1a' `note1b'" "`note2a' `note2b'", `noteopts')

/* Use the same concept from above to store/organize information for the
titles and/or subtitles of graphs */
loc ti1 "College Enrollment Rates Among High School Graduates"
loc ti2 "By Quartile Of Prior Achievement and School"
loc tiopts size(medium) span c(black)
loc title ti("`ti1'" "`ti2'", `tiopts')

// Create a yaxis title local macro
loc yti yti("Percentage" "of Students", size(medium))

// Create a yaxis local macro with all of the syntax for yaxis options
loc yaxis ylab(0(20)100) ymti(0(5)100) ysca(range(0 100)) `yti'

// Create a macro with all of the x-axis syntax
loc xaxis `xlab' `xsca' xti(" " "Prior Achievement", size(medsmall))

// Create legend key value pairs with informative labels
loc leg1 1 "Overall % of Graduates" "Enrolled in IHL Post-Graduation{superscript:1}"
loc leg2 2 "% of Graduates by Math Quartile" "Enrolled in IHL Post-Graduation"

// Store the syntax for the legend option in a local macro called legend
loc legend legend(label(`leg1') label(`leg2'))

// Check for option to save the graph
if "`saving'" == "" {

// If not present create empty macro
loc save ""

} // End IF Block for graph save option

// If specified
else {

// Save the graph with the user specified name
loc save saving(`"`saving'"', replace)

} // End ELSE block for graph saving option

// Check option to export to external format
if "`fmt'" == "" {

// If nothing specified create a macro with nothing in it
loc export ""

} // End IF Block for graph export

// If user specified a file format
else {

// Create a filename macro
loc filenm collegeEnrollmentByMathAchievementQuartiles

// Store syntax to export the graph in a macro
loc export gr export `"`filenm'"', as(`fmt') replace

} // End ELSE Block for graph export

// Step 6: 
// Create the graph
tw scatter `enrl' `qcode' [aweight = `wgt'], `jitter'  ||  ///   
scatter `avg' `qcode', `title' `xaxis' `yaxis' `notes' `save'  ///   
`legend' `scheme' `xline' name(cgbubbleplot, replace)

// Export the graph if user specified a file format
`export'

// Create matrix from the data in memory
mata : st_matrix("cgbubble", st_data(., 1..8))

// Add Column names to the matrix
mat colnames cgbubble = quartile school num1 den1 rate1 num2 den2 rate2

// Return the dataset to the user
ret mat bubbledata = cgbubble

// Create variable labels too
ret loc qvarlab = `"la var quartile "Prior Math Achievement Quartile""'
ret loc schvarlab = `"la var school "Name of Last School""'
ret loc num1 = `"la var num1 "Within Schools Enrolled in IHL by Achievement Quartile""'
ret loc num2 = `"la var num2 "Between Schools Enrolled in IHL by Achievement Quartile""'
ret loc den1 = `"la var den1 "Within Schools Graduates by Achievement Quartile""'
ret loc den2 = `"la var den2 "Between Schools Graduates by Achievement Quartile""'

// Restore the original data that was in memory
restore

// End of the program
end


