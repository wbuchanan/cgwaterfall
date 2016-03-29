
// Drop program from memory
cap prog drop cgbubble

// Declare the file as defining a program with r-class property
prog def cgbubble, rclass

	// Specify the version which under which Stata should interpret code
	version 13.1
	
	// Define the syntax structure of the program
	syntax [using/] [if] , 	COHortid(string asis) 							 ///   
							Years(numlist min=2 max=2 sort)					 ///   
							QTILEmath(string asis)							 ///    
							SCHname(string asis)							 ///   
							DIPLoma(string asis) 							 ///   
							ENRollyear1(string asis)						 ///   
						   [STRetch scheme(passthru)						 ///   
							SAVing(string asis) 							 ///   
							fmt(string asis)								 ///   
							JITter(passthru) DBug]

	// Check debug option
	if "`dbug'" != "" {
		pause on
		pause "Debugging Started enter q to continue or BREAK to exit"
	}	
	else {
		pause off
	}
	
	// Preserve the current state of the user's session
	preserve

		// Check to see if you need to load a file or if the data is in memory
		if `"`using'"' != "" {

			// Load the file passed by the user
			use `"`using'"', clear
		
			pause "Check to see if data were loaded"
			
		} // End IF Block for loading file

		pause "Will try to confirm presence of all required variables"
		
		// Make sure all of the variables are present
		confirm v `cohortid' `qtilemath' `schname' `diploma' `enrollyear1'
		
		// Parse the year values to make them simpler to reference later
		loc syear `: word 1 of `years''
		loc eyear `: word 2 of `years''

		pause "syear and eyear should be defined as the start and end years of interest"
		
		// Mark records that would be excluded
		marksample touse

		pause "Marked the sample with touse"
		
		// Make sure the quartile values are either missing or 1-4
		assert inrange(`qtilemath', 1, 4) | mi(`qtilemath')

		pause "Just passed quartile assertion tests"
		
		/* Keep records from the date range who aren't missing the math quartile
		and that also satisfy any thing passed to the if condition */
		keep if `touse' & inrange(`cohortid', `syear', `eyear') & !mi(`qtilemath')

		pause "Removed any cases: non-missing qtilemath, outside of year range, and not satisfying if condition"
		
		// Define value labels for the math quartiles
		la def `qtilemath' 	1 `""1{superscript:st}" "Quartile""' ///   
							2 `""2{superscript:nd}" "Quartile""' ///   
							3 `""3{superscript:rd}" "Quartile""' ///   
							4 `""4{superscript:th}" "Quartile""', modify
							
		// Apply the new value labels to the variable
		la val `qtilemath' `qtilemath'					

		pause "Applied value labels to the quartile variable"
		
		/* Set aside namespace for temporary variables. These have the benefit 
		of being automatically garbage collected when the program finishes 
		executing which means you don't use up as much of your system's RAM */
		tempvar enrl num den avg qcode numsch wgt

		/* Create a numeric school variable so the data can be returned to the
		end user as a matrix in the r(bubbledata) */
		qui: encode `schname', gen(`numsch')
		
		pause "Defined a temp variable called numsch containing numeric values of school names"
		
		// Get all of the unique school values
		qui: levelsof `numsch', loc(schs)
		
		pause "All values of tempvar stored in local schs"
		
		// Create a local macro to store the value labels
		loc schlab la def school
		
		pause "Started defining syntax to label the school numeric values

		// Return each of the codes with its label in a macro
		foreach v of loc schs {
		
			// Add the value label definition to the school value label macro
			loc schlab `schlab' `v' "`: label (`numsch') `v''"
			
		} // End Loop to store school value labels
		
		pause "Finished constructing local macro with code to define school value labels from the numeric values"
		
		// Return the local to the user when the program completes execution
		ret loc schlabels = `"`schlab'"'
		
		pause "Returned previously mentioned macro to the end user via r(schlabels)"
		
		/* Total number of students by quartile and school that graduated and 
		enrolled after graduating. */
		collapse (sum) `enrollyear1' `diploma', by(`numsch' `qtilemath') 
		
		pause "Data should contain upto four records per school (1 per quartile) with the total students enrolling the year after graduation and the number getting a diploma"

		// Percent of students enrolling the year after graduation
		qui: g `enrl' = (`enrollyear1' / `diploma') * 100
		
		pause "Check the enrl tempvar...should be % graduates enrolled after year 1"

		// Number of students enrolled year after graduation by math quartile
		qui: egen `num' = sum(`enrollyear1'), by(`qtilemath')
		
		pause "Check tempvar num...should be # graduates within each quartile enrolled after year 1"

		// Number of students who graduated by math quartile
		qui: egen `den' = sum(`diploma'), by(`qtilemath')

		pause "Check tempvar den...should be # graduates within each quartile"

		// Percentage of graduates enrolling the year after graduation by quartile
		qui: g `avg' = (`num' / `den') * 100
		
		pause "Check tempvar avg...should be % graduates within each quartile enrolled after year 1"

		// Check to see if the user wants the values spread out along the x-axis
		if "`stretch'" == "" {

			// Create a variable to identify the test score quartile
			qui: g `qcode' = 	cond(`qtilemath' == 1, 1.2, 				 ///   
								cond(`qtilemath' == 2, 1.4,					 ///   
								cond(`qtilemath' == 3, 1.6, 1.8)))
			
			pause "Check values of tempvar qcode < 2"
			
			// Store modified versions of the variable labels for the graph					
			loc xlab1 1.2 "1{superscript:st} Quartile"
			loc xlab2 1.4 "2{superscript:nd} Quartile"					
			loc xlab3 1.6 "3{superscript:rd} Quartile"					
			loc xlab4 1.8 "4{superscript:th} Quartile"	
			
			pause "Check locals xlab1-xlab4 will print on a single line"
			
			// Create a macro with the syntax for the xlabel option of the graph
			loc xlab xlab(`xlab1' `xlab2' `xlab3' `xlab4', angle(45) labs(small))	
			
			pause "Check local xlab will expand into the full xlabel option for the graph"
			
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

			pause "Check tempvar qcode = qtilemath argument"

			// Create xlabel syntax telling it to use the value labels
			loc xlab xlab(, val)
			
			pause "Check local xlab only includes the optional argument val"
			
			// Create the xscale syntax for scaling the xvariable values
			loc xsca xsca(range(0.5 4.5))
			
			pause "Check xscale ranges from 0.5 through 4.5"
			
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

		pause "Check locals start and end are not equal to one another"
		
		/* Store the notes by sentence.  I use the numbers for notes/titles to 
		indicate how I would like them displayed with regards to line breaks.  
		So, note1a and note1b would be on the same line, and note 2a would be 
		on the following line. */
		loc note1a "Sample: `start' through `end' high school graduates." 
		loc note1b "Postsecondary enrollment outcomes from NSC matched records."
		loc note2a "All other data from ${agency_name} administrative records."
		loc note2b "{superscript:1} Values weighted by HS Graduates"

		// Store optional arguments for the notes parameter
		loc noteopts size(vsmall) pos(7) 
		
		// Store the syntax for the notes optional argument in a local macro
		loc notes note("`note1a' `note1b'" "`note2a' `note2b'", `noteopts')
		
		pause "Check local notes will expand to full note argument for graph"
		
		/* Use the same concept from above to store/organize information for the
		titles and/or subtitles of graphs */
		loc ti1 "College Enrollment Rates Among High School Graduates"
		loc ti2 "By Quartile Of Prior Achievement and School"
		loc tiopts size(medium) span c(black)
		loc title ti("`ti1'" "`ti2'", `tiopts')
		
		pause "Check local title will expand to full title argument for graph"

		// Create a yaxis title local macro
		loc yti yti("Percentage" "of Students", size(medium))

		// Create a yaxis local macro with all of the syntax for yaxis options
		loc yaxis ylab(0(20)100) ymti(0(5)100) ysca(range(0 100)) `yti'

		pause "Check local yaxis will expand to all yaxis optional arguments"

		// Create a macro with all of the x-axis syntax
		loc xaxis `xlab' `xsca' xti(" " "Prior Achievement", size(medsmall))

		pause "Check local xaxis will expand to all xaxis optional arguments"

		// Create legend key value pairs with informative labels
		loc leg1 1 "Overall % of Graduates" "Enrolled in IHL Post-Graduation{superscript:1}"
		loc leg2 2 "% of Graduates by Math Quartile" "Enrolled in IHL Post-Graduation"

		// Store the syntax for the legend option in a local macro called legend
		loc legend legend(label(`leg1') label(`leg2'))

		pause "Check local legend will expand to define the legend values"
		
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
		
		
		// Create the graph
		tw scatter `enrl' `qcode' [aweight = `wgt'], `jitter'		  || 	 ///   
		scatter `avg' `qcode', `title' `xaxis' `yaxis' `notes' `save' 		 ///   
		`legend' `scheme' `xline' name(cgbubbleplot, replace)

		pause "Check graph parameters from previously executed command.  Then export"
		
		// Export the graph if user specified a file format
		`export'

		// Create matrix from the data in memory
		mata : st_matrix("cgbubble", st_data(., 1..8))
		
		pause "Check that matrix cgbubble exists and is accessible from Stata"
		
		// Add Column names to the matrix
		mat colnames cgbubble = quartile school num1 den1 rate1 num2 den2 rate2
		
		pause "Check the values in the matrix cgbubble"
		
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
	
	// Turn pause off if it was already turned on
	pause off

// End of the program	
end


