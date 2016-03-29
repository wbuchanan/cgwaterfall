********************************************************************************
* Description of the Program -												   *
* This program is a convenience wrapper for creating several of the 'Waterfall'*
* style graphs in the SDP College Going Toolkit.  It provides a single 		   *
* interface with which you can create disaggregated versions of the existing   *
* graphs, handle all of the data manipulation from the analysis data set,	   *
* return the data after aggregation, generate unique graphs for schools, etc.. *
*																			   *
* Data Requirements -														   *
*	Student ID					-- to sid() 		[values] = [str, int, real]*
*	Cohort ID 					-- to cohortid() 	[values] = [0, 1]		   *
*	School Name 				-- to schname() 	[values] = [str] 		   *
*	Ontime Grad					-- to ontime()		[values] = [0, 1]		   *
*	Yr 1 Enrollment 			-- to fenr() 		[values] = [0, 1]		   *
*	Yr 2 Enrollment 			-- to senr() 		[values] = [0, 1]		   *
*	Race/Ethnicity 				-- to race()		[values] = [1, 7]		   *
* 	Student Sex/Gender 			-- to sex() 		[values] = [0, 1]		   *
* 	Lunch Status 				-- to frl()			[values] = [0, 2]		   *
* 	Year Span 					-- to yearspan() 	[values] = [[int] [int]]   *
* 	Graph Style Type 			-- to bysep() 		[values] = [str]		   *
* 	Statistics 					-- to stats() 		[values] = [see help egen] *
* 	Export Format 				-- to fmt() 		[values] = [see graphs]    *
* 	Graph Garbage Collection 	-- gph 				[values] = [gph | ] 	   *
* 	Graph Scheme/Style File 	-- to scheme() 		[values] = [scheme-name]   *
* 	File name stub 				-- to savename() 	[values] = [str] 		   *
*	Agency Name 				-- to agency() 		[values] = [str] 		   *
* 	Minimum Cell Size 			-- to cellsize() 	[values] = [int] 		   *
* 	On Track Sample Indicator 	-- to ontsample() 	[values] = [0, 1] 		   *
*	Student's GPA 				-- to gpa() 		[values] = [variable name] *
*	On Track Cohort Year 		-- to ontyear() 	[values] = [varname]	   *
*																			   *
* System Requirements -														   *
*	You must have pdflatex installed in order to use the LaTeX option.  	   *
*																			   *
* Program Output -															   *
*	Generates 'Waterfall' charts based on the SDP College Going Toolkit.	   *
*	The program allows you to generate a single overall graph across subunits  *
*	A single graph with each of the subunits represented in subplots		   *
*	And individual graphs for each subunit (e.g., school).					   *
*	Each of these graphs can also be disaggregated by passing variable names   *
*			to the sex, race, and/or frl parameters.  						   *
*																			   *
* Lines - 1066																   *
*																			   *
********************************************************************************

// Drop the program from memory if it exists
cap prog drop cgwaterfall

// Define the program
prog def cgwaterfall, rclass

	// Set the version underwhich the program should be interpreted
	version 13.1

	// Define the syntax structure of the command
	syntax [using/] [if], SCHName(string asis) BYSep(string asis)			 ///   
						YEARspan(numlist max = 2 min = 2 integer sort)		 ///   
						ONTime(string asis) Fenr(string asis) 				 ///   
						Senr(string asis) GRADvar(string asis) 				 ///  
						COHortid(string asis) SId(string asis)				 ///   
						[ STats(string asis) SEx(string asis) 				 ///   
						RAce(string asis) FRl(string asis) 					 ///   
						FMt(string asis) gph SCHEme(passthru) 				 ///
						SAVEname(string asis) AGency(string asis) 			 ///   
						CELLsize(string asis) ONTSample(string asis)		 ///  
						gpa(string asis) ONTYear(string asis) recastbg 		 ///   
						texify ]  	

	// Preserve any data currently in memory
	preserve
		pause on
	// Check for using dataset
	if `"`using'"' != "" { 
	
		// Load the dataset
		qui: use `"`using'"', clear
		
		// Make sure variables are actually in the dataset
		confirm v `schname' `ontime' `fenr' `senr' `gradvar' `cohortid'	`sex' ///   
		`race' `frl' `gpa' `ontsample' `ontyear'
			
	} // End IF Block to check for file passed to using argument
	
	// If null statistics parameter 
	if mi("`stats'") {
		loc stats min mean max
	}
	
	// If no value is passed to cell size 
	if "`cellsize'" == "" {
		loc dropcell = 1
		loc cellsize = 20
		loc capfmt c(red) s(medium) pos(5) 
		loc caption caption("May include PII." "Not for Public Release", `capfmt')
		
	} // End IF Block for cell size check
	
	// Recast cellsize to numeric
	else {
		loc dropcell = 0
		loc cellsize = `cellsize'
		loc caption ""
	} // End ELSE Block
	
	// Store formatting for xaxis 
	loc xaxis xlab(, val labsize(vsmall)) xscale(range(.8(.1)4.1)) xti(" ")
	
	// Undocumented option to plot an area plot behind the connected scatterplot
	if "`recastbg'" != "" {
	
		// Set syntax for area plot as a base layer
		loc bgshade rarea loutcome uoutcome outtype, sort ||

		// With the additional legend element need to adjust the rendering
		loc legrows rows(2)
		
	} // End IF Block for background area plot
	
	// Store graph command shells
	if "`bysep'" == "sep" {
		loc grcmd `bgshade' connected loutcome uoutcome schmoutcome outtype
	}
	else {
		loc grcmd `bgshade' connected loutcome uoutcome moutcome outtype
	}	
	
	// Set aggregation type macro for later
	if "`ontsample'`gpa'`ontyear'" != "" {
		loc aggtype ontrack
	}
	else {
		loc aggtype overall
	}
	
	// Store available statistics
	loc available min mean max median 
						
	// Parse the year span for identifying the cohort
	loc yrs1 : word 1 of `yearspan'
	loc yrs2 : word 2 of `yearspan'
	
	// Create year label for graph notes
	if `yrs1' == `yrs2' { 
		loc yearlab "`= `yrs1' - 1' through `yrs2'"
	}
	else if `yrs1' != `yrs2' {
		loc yearlab "`yrs1' through `yrs2'"
	}
	
	// Check agency argument
	if "`agency'" == "" {
		loc agency ""
	}
	
	// Store the variance estimators in a local macro to parse correctly
	loc varstat mad mdev semean sd
	
	// Check for variance based argument
	if  `"`: list stats & varstat'"' != ""  {
		
		// Put the variance estimator into the local macro stat1 (for the lower bound)
		loc stat1 `: list stats & varstat'

		// Put the central tendency measure in stat2
		loc stat2 `: list stats - stat1'
		
		// Put the variance estimator into stat3 as well (for the upper bound)
		loc stat3 `stat1'
		
		// Generate variable labels for the upper/lower bounds in the graphs
		legkey `aggtype', statname(`stat3')
		
		// Store variable labels for the bounds in new macros
		loc stat1lab `"`r(varlab1)'"'
		loc stat3lab `"`r(varlab3)'"'

		// Generate variable label for the central tendency measure
		legkey `aggtype', statname(`stat2')
		
		// Store central tendency variable label in new macro
		loc stat2lab `"`r(varlab2)'"'
		

	} // End IF Block for variance arguments
		
	// If percentiles are requested 
	else if regexm(`"`stats'"', `"([a-zA-Z])"') != 1 {
	
		// Sort the percentile values from smallest to largest
		loc stats `: list sort stats'
		
		// Parse the individual statistics
		loc stat1 `: word 1 of `stats''
		loc stat2 `: word 2 of `stats''
		loc stat3 `: word 3 of `stats''
			
		// Build the label for this type of stat
		// Store it in separate local macro
		legkey `aggtype', statname(`stat1')	
		loc stat1lab `"`r(varlab)'{superscript:1}"'
		legkey `aggtype', statname(`stat3')	
		loc stat3lab `"`r(varlab)'{superscript:1}"'
		legkey `aggtype', statname(`stat2')	
		loc stat2lab `"`r(varlab)'{superscript:2}"'
		
		// Set foot note macros to use in the notes for the graph
		loc footnotes "1. Between Schools Estimate; 2. Within School Estimate"
		
	} // End ELSEIF Block for percentile stats
	
	// For all other cases
	else if `: word count `: list stats & available'' == 3 {
	
		// Build variable labels for use in the graphs and store in local macros
		forv st = 1/3 {
			
			// Parse the individual statistics
			loc stat`st' `: word `st' of `stats''
			
			// Build the label for this type of stat
			legkey `aggtype', statname(`stat`st'')
			
			// Store it in separate local macro
			loc stat`st'lab `"`r(varlab`st')'"'
			
		} // End Loop to build variable labels for summary stats
		
	} // End ELSEIF Block for percentile stats
	
	// Otherwise issue error
	else {
		
		// Print error message
		di as err "You can get the min, mean, and max by ommiting stats." _n ///  
		"You can also use one of semean, sd, mad, or mdev along with a "	 ///   
		"measure of central tendency" _n "Or specify three statistics to "	 ///   
		"use to create the uppwer/lower bounds and central tendency to graph"
		
		// Return error code
		err 198
		
	} // End IF Block for incorrectly specified stat arguments 
		
	// Build up the notes for the graphs
	loc note1a "Sample: `yearlab' `agency' first-time ninth graders." 
	loc note1b "Students who transferred into or out of `agency' are excluded"
	loc note1c "from the sample." 
	loc note1 "`note1a' `note1b' `note1c'"
	loc note2a "Postsecondary enrollment outcomes from NSC matched records."
	loc note2b "All other data are from `agency' administrative records."
	loc note2 "`note2a' `note2b'" 
	loc notefmt size(vsmall) c(black) pos(7) 
	loc grnotes note("`note1'" "`note2'" "`footnotes'", `notefmt')

	// Store all disaggregation options
	loc disagg `sex' `race' `frl'
	
	// Set local for by prefix when disaggregated results requested
	if "`sex'`race'`frl'" == "" {
		loc disby ""
	}
	else {
		loc disby bys `disagg' :
	}

	// Make sure disaggregation variables are properly labeled
	foreach dvar of loc disagg {
	
		// Check for a variable label to use
		if "`: var label `dvar''" == "" {
		
			// Get a variable label from the user
			di as res "Please enter a variable label for `dvar'" 			 ///   
			_request(_thevarlabel)
			
			// Store the syntax to label the variable
			loc `dvar'label la var `dvar' "`thevarlabel'"
			
			// And label it
			``dvar'label'
			
		} // End IF Block for null variable labels
		
		// Check for value labels
		if "`: val label `dvar''" == "" {
		
			// Create a shell to store the syntax to label the values
			loc `dvar'vallabel la def `dvar' 
		
			// If no value labels exist get the list of unique values
			qui: levelsof `dvar', loc(dvarval)
			
			// Iterate over them
			foreach dvallab of loc dvarval {
			
				// Request the label from the user
				di as res "Please enter a label for the value `dvallab' "	 /// 
				"of `dvar'" _request(_dval)
				
				// Store the value label
				loc `dvar'vallabel ``dvar'vallabel' `dvallab' `"`dval'"'
				
				// Store the value label in a characteristics as well
				qui: char `dvar'[v`dvallab'] "la def `dvar' `dvallab' `dval', modify"
				
			} // End Loop over unique values for labeling
			
			// Add modify statement to syntax
			loc `dvar'vallabel ``dvar'vallabel' , modify
			
			// Apply the value labels to the data
			``dvar'vallabel'
			
		} // End IF Block for unlabeled disaggregation variables
		
		// If the variable is already labeled
		else {
		
			// Create a shell to store the syntax to label the values before graphing
			loc `dvar'vallabel la def `dvar' 
		
			// Get the value label name
			loc dlabnm `: val label `dvar''
			// Get the list of unique values
			qui: levelsof `dvar', loc(dvarval)
			
			// Iterate over them
			foreach dvallab of loc dvarval {
			
				// Add characteristics to variable
				qui: char `dvar'[v`dvallab'] ///   
				`"la def `dvar' `dvallab' "`: label `dlabnm' `dvallab''", modify"'
				
				// Store version in local macro as well
				loc `dvar'vallabel ``dvar'vallabel' `dvallab' "`: label `dlabnm' `dvallab''"
			
			} // End Loop over labels
			
			// Add modify to local
			loc `dvar'vallabel ``dvar'vallabel' , modify
			
		} // End ELSE Block for value labeled variables
		
	} // End Loop over disaggregation variables		

	// Create shell for subtitle macro
	loc dislab by 
	
	// Loop over the variables
	if `: word count `disagg'' == 1 {
		loc dislab `dislab' `: var label `disagg''
	}
	else if `: word count `disagg'' == 2 {
		loc lab1 `: var label `: word 1 of `disagg'''
		loc lab2 `: var label `: word 2 of `disagg'''
		loc dislab `dislab' `lab1' and `lab2'
	}
	else if `: word count `disagg'' == 3 {
		loc lab1 `: var label `: word 1 of `disagg'''
		loc lab2 `: var label `: word 2 of `disagg'''
		loc lab3 `: var label `: word 3 of `disagg'''
		loc dislab `dislab' `lab1', `lab2', and `lab3'
	}

	// Store Graph title
	loc grti1 "Student Progression from 9{superscript:th}"
	loc grti2 "Grade Through College"
	loc grtitle ti(`"`grti1' `grti2'"', size(medlarge) span c(black))
	
	// Store Y-Axis Title
	loc ylabtitle yti(`"% of 9{superscript:th} Grade Students"')
	
	// Mark the sample used for the graphs
	marksample touse
	
	// Keep observations within cohort range and satisfying IF condition(s)
	qui: keep if `touse' & inrange(`cohortid', `yrs1', `yrs2') 
	
	// Check for ontrack variables
	if "`gpa'`ontsample'`ontyear'" != "" {
	
		// Keep observations within cohort range and satisfying IF condition(s)
		qui: keep if `ontsample' == 1
		
		// Create ontrack indicator variable
		qui: g ontrack = cond(`ontyear' == 0, 1, 							 ///   
						 cond(`ontyear' == 1 & `gpa' < 3, 2,				 ///
						 cond(`ontyear' == 1 & `gpa' >= 3, 3, .)))
						 
		// Define value labels
		la def ontrack 	1 `""Off-Track to" "Graduate""'						 ///   
						2 `""On-Track to" "Graduate," "GPA < 3.0""'			 ///   
						3 `""On-Track to" "Graduate," "GPA >= 3.0""', modify

		// Apply value labels
		la val ontrack ontrack
		
		// Put ontrack variable in macro with same name so it can be used later
		loc ontrack ontrack
		
		// Create local macro to store marker label position arguments
		loc labm1 mlab(moutcome) mlabg(*1.25) sort mlabs(medsmall)
		loc labm2 mlab(moutcome) mlabg(*1.25) sort mlabs(medsmall) 
		loc labm3 mlab(moutcome) mlabg(*1.25) sort mlabs(medsmall)

		// Store all of the point label syntax in a single macro
		loc pointlab `labm1' `labm2' `labm3'
				
		// Store Graph title
		loc grti1 `"Student Progression from 9{superscript:th}"'
		loc grti2 `"Grade On-Track for HS Graduation Status"'
		loc grtitle ti("`grti1'" "`grti2'", size(medlarge) span c(black))
		loc grcmd connected moutcome outtype
	
		// Add assertion block
		cap assert !mi(ontrack) if !mi(`ontyear') & !mi(`gpa')
		
		// If Assertion is false alter user
		if _rc != 0 {
		
			// Print message to screen
			di as err "WARNING: There is a problem with your ontrack " 		 ///   
			"indicator variable!" _n "Do you wish to continue anyway? (Y/n)" ///   
			_request(_ontcont)
			
			// If no response
			if regexm("`ontcont'", "^([nN])") == 1  {
				di as res "Stopping program"
			}
			
			// For any other response
			else { 
				continue
			}
			
		} // End IF Block for assertion block failure

	} // End IF Block for restricted sample for ontrack status
	
	// For non-ontrack status graphs
	else {
		
		// Store aesthetic parameters for college-going graphs in local macro
		loc sortsym sort msym(O O O) 
		loc thelab mlab(loutcome uoutcome moutcome) 
		loc linepat lp(dash dash solid)
		loc labelsize mlabs(medsmall medsmall medsmall)
		loc pointlab `sortsym' `thelab' `linepat' `labelsize'
		
	} // End ELSE Block to build syntax for point formatting
	
	// Create placeholder variable for 100 % starting
	qui: g outcome1 = 100.00
	
	// Create a graduation status variable
	qui: g outcome2 = cond(!mi(`gradvar') & `ontime' == 1, 1, 0)
	
	// Create seamless transition variable
	qui: g outcome3 = cond(`fenr' == 1 & `ontime' == 1, 1, 0)
	
	// Create persistence variable
	qui: g outcome4 = cond(`fenr' == 1 & `senr' == 1 & `ontime' == 1, 1, 0)
	
	// Estimate the aggregate values that will get further processed
	`disby' genagg `stat1' `stat2' `stat3', schname(`schname') sid(`sid') 	 ///   
	aggtype(`aggtype')

	// Store macros containing boundard stats
	loc bounds `stat1' `stat3'
	
	/* Rescale outcome measures to be on a percentage scale and correct the 
	variables storing the upper/lower bounds based on the type of variance 
	estimator passed to the stats parameter. */	
	forv status = 2/4 {

		/* Rescale the aggregated values */ 
		qui: replace moutcome`status' = 100 * moutcome`status'
		qui: replace schmoutcome`status' = 100 * schmoutcome`status'
		qui: replace loutcome`status' = 100 * loutcome`status'
		qui: replace uoutcome`status' = 100 * uoutcome`status'
		
		/* If standard errors were requested, make the upper and lower bounds
		a 95% Confidence interval based on the within school measure of 
		central tendency */
		if "`: list bounds & varstat'" == "semean" {
			
			// Create lower bound
			qui: replace loutcome`status' = schmoutcome`status' - 		 ///   
											(loutcome`status' * 1.96)
			
			// Create upper bound
			qui: replace uoutcome`status' = schmoutcome`status' + 		 ///   
											(uoutcome`status' * 1.96)	
				
		} // End IF Block for variance parameters
		
		/* If standard deviations, mean absolute deviation, or median absolute 
		deviation were passed as variance estimates, replace the upper bounds 
		based on the within school measure of central tendency ± variance */
		else if "`: list bounds & varstat'" != "" {
				
			// Create lower bound
			qui: replace loutcome`status' = schmoutcome`status' -  loutcome`status'
			
			// Create upper bound
			qui: replace uoutcome`status' = schmoutcome`status' +  uoutcome`status'	
				
		} // End IF Block for variance parameters
		
	} // End Loop to create aggregated values
	
	// Optimize the data storage formatting
	qui: compress
	
	// Get the list of all variable names holding floating point values
	qui: ds, has(type float double)

	// Set the display format for all of the variables
	format %9.1f `r(varlist)'
		
	// Create a tempvar to identify an individual record from a school
	tempvar schtag xout esttlabels
	
	// Tag a single observation per school
	qui: egen `schtag' = tag(`schname' `disagg' `ontrack')
	
	// Keep only the data required for the graph
	qui: keep if `schtag' == 1
	
	// Keep the variables required for the graph
	qui: keep `sid' `schname' `disagg' `ontrack' *outcome* *ellsize*

	// Restructure the data so it can be visualized
	qui: reshape long schmoutcome moutcome loutcome uoutcome outcome 		 ///   
	cellsize schcellsize, i(`schname' `disagg' `ontrack') j(outtype)
	
	// Reapply value labels
	foreach dvar of loc disagg {
		``dvar'vallabel'
		la val `dvar' `dvar'
	}
	
	// Replace starting point values for outcomes
	foreach v of var moutcome* loutcome* uoutcome* schmoutcome* {
		qui: replace `v' = 100 if outtype == 1
	}
	
	// Define value labels
	la def outtype 	1 `""9{superscript:th}" "Graders""' 					 ///   
					2 `""On-time" "Grads""'									 ///   
					3 `""Seamless" "Transitioners""' 						 ///   
					4 `""2{superscript:nd} Yr" "Persisters""', modify

	// Apply the value labels
	la val outtype outtype
	
	// Create indicator for cases with cell sizes below threshold
	qui: bys `schname' `disagg' `ontrack' (outtype): replace cellsize = 	 ///   
	cellsize[_n + 1] if outtype == 1 & mi(cellsize)
	qui: bys `schname' `disagg' `ontrack' (outtype): replace schcellsize = 	 ///   
	schcellsize[_n + 1] if outtype == 1 & mi(schcellsize)
	qui: g smcell = cond(cellsize <= `cellsize', 1, 0)
	qui: g smschcell = cond(schcellsize <= `cellsize', 1, 0)

	qui: encode `schname', gen(schnm)
	qui: levelsof schnm, loc(schs)
	
	// Create a local macro to store the value labels
	loc schlab la def schnm
	
	// Return each of the codes with its label in a macro
	foreach v of loc schs {
		
		// Add the value label definition to the school value label macro
		loc schlab `schlab' `v' "`: label (schnm) `v''"
		
	} // End Loop to store school value labels
	
	// Return the local to the user when the program completes execution
	ret loc schnm = `"`schlab'"'
	
	// Apply variable labels to variables
	la var loutcome "`stat1lab'"
	la var moutcome "`stat2lab'"
	la var uoutcome "`stat3lab'"
	la var schmoutcome "`stat2lab'"
	loc safe1 outtype `disagg' `ontrack' schcellsize
	loc safe2 loutcome schmoutcome moutcome uoutcome
	loc safevars `safe1' `safe2'
	
	foreach v in `disagg' `ontrack' {
	
		// Create column headers for LaTeX table
		loc grouplabs `"`grouplabs' ""`: var l `v''"""'
		
	}
	
	ret loc `schname'varlab = `"la var `schname' "School Name""'
	ret loc outtypevarlab = `"la var outtype "Student Outcome Groups""'
	ret loc schcellsize = `"la var schcellsize "Within School Cell Size""'
	ret loc loutcome = `"la var loutcome "`stat1lab'""'
	ret loc moutcome = `"la var moutcome "`stat2lab'""'
	ret loc uoutcome = `"la var uoutcome "`stat3lab'""'
	ret loc schmoutcome = `"la var schmoutcome "`stat2lab'""'
	
	//qui: clonevar `esttlabels' = outtype
	//la val `esttlabels' esttablab
	
	//qui: decode `esttlabels', gen(`xout')
	qui: g shrtschname = subinstr(`schname', " High School", "", .)
	qui: replace shrtschname = subinstr(shrtschname, " School", "", .)
	qui: replace shrtschname = subinstr(shrtschname, " HS", "", .)
	qui: replace shrtschname = subinstr(shrtschname, " High", "", .)
	qui: replace shrtschname = subinstr(shrtschname, " ", "", .)
	
	// qui: egen matrownms = concat(shrtschname `xout'), p(" ")
	// qui: replace matrownms = subinstr(matrownms, "_", " ", .)
	qui: g matrownms = shrtschname 
	
	// Check for ontrack status or other outcomes
	if "`ontrack'" == "" {
		// Define value labels for exporting table
		loc group1 `""Outcome Type: 1 $=$ 9\textsuperscript{th} Graders""' 
		loc group2 `""2 $=$ On-Time Graduates""' 		   
		loc group3 `""3 $=$ Seamless Transitioners""' 
		loc group4 `""4 $=$ 2\textsuperscript{nd} Year Persisters""'
		loc xtracoll `"`group1' `group2' `group3' `group4'"'
	}
	else {
	   
		// Define value labels for exporting table
		loc group1 `"Outcome Groups: 1 $=$ 9\textsuperscript{th} Graders"' 
		loc group2 `"2 $=$ On-Time Graduates"' 		   
		loc group3 `"3 $=$ Seamless Transitioners"' 
		loc group4 `"4 $=$ 2\textsuperscript{nd} Year Persisters"'
		loc group5 `"On-Track Groups: 1 $=$ Off-Track to Graduate"' 
		loc group6 `"2 $=$ On-Track GPA $<$ 3.0"' 
		loc group7 `"3 $=$ On-Track GPA $>=$ 3.0"' 
		loc xtracoll `"\noindent `group1' `group2' `group3' `group4' \\ `group5' `group6' `group7'"'
	}
	// Store a copy of the dataset in mata to return all of the data after graphing
	mkmat `safevars', mat(waterfall) rown(matrownms)
	mat colnames waterfall = `: subinstr loc safevars "_" "\_", all'
	
	// Check for LaTeX report option
	if "`texify'" != "" {
	
		// Open a connection to the file that will be consumed by the template
		qui: file open texreport using `"`c(pwd)'/stataout.tex"', w replace        
	
		file write texreport `"\documentclass[12pt,oneside,final,letterpaper]{article}"' _n
		file write texreport `"\usepackage{pdflscape}\usepackage{tabulary}"' _n
		file write texreport `"\usepackage{graphicx}\usepackage{longtable}"' _n
		file write texreport `"\usepackage[hidelinks]{hyperref}"' _n
		file write texreport `"\DeclareGraphicsExtensions{.pdf, .png}"' _n
		file write texreport `"\graphicspath{{"`c(pwd)'"}}"' _n
		file write texreport `"\title{Stata Output Example: \\ `c(current_date)'}"' _n
		file write texreport `"\author{`c(username)'}"' _n
		file write texreport `"\begin{document}"' _n
		file write texreport `"\begin{titlepage} \maketitle \end{titlepage}"' _n
		file write texreport `"\newpage\clearpage \tableofcontents \newpage\clearpage"' _n
		file write texreport `"\listoffigures \newpage\clearpage"' _n
		file write texreport `"\listoftables \newpage\clearpage"' _n
				 
		qui: estout m(waterfall, fmt(a2)) using								 ///   
		`"`c(pwd)'/waterfalltable.tex"', label style(tex) replace  			 ///    
		coll("Outcome Type" `ontrack' "\# Students" "Lower Bound" 			 ///   
		"Within Schools" "Between Schools" "Upper Bound") 
		
		// Add table to report
		file write texreport `"\section{Table of Results}"' _n
		file write texreport `"\begin{landscape}\begin{longtable}{l`= "c" * `= colsof(waterfall)''}"' _n
		file write texreport `"\input{`c(pwd)'/waterfalltable}"' _n
		file write texreport `"\end{longtable}"' _n
		file write texreport `"`xtracoll'"' _n
		file write texreport `"\end{landscape}"' _n
		
		//tempfile fixesttab
		//qui: filefilter `"`c(pwd)'/waterfalltable.tex"' `"`fixesttab'.tex"', ///   
		//from("l*{1}{c}") to(`"l`= "c" * `= colsof(waterfall) - 1''"') replace 
		//qui: filefilter `"`fixesttab'.tex"' `"`c(pwd)'/waterfalltable.tex"', ///   
		//from("l*{1}{c}") to(`"l`= "c" * `= colsof(waterfall)''"') replace 
		
	}

	ret mat waterfall = waterfall
	
	// Remove tempvars
	//qui: drop `xout' matrownms `esttlabels'

	// If a small cell size limit was not provided originally
	if `dropcell' == 1 {
	
		// Prompt user one last time to indicate if small cells should be kept
		di as err "Cell Size not provided.  Graphs may include PII. "		 ///   
		"Would you like to omit cells with < 20 Students? (Y/n)"			 ///   
		_request(_makedrop) 
		
		// Test user's response to the prompt
		if regexm("`makedrop'", "^([yY])") == 1 {
			
			// Print message back to user
			di as res "Dropping small cell sizes"
			
			// Drop small cell size records
			qui: drop if smschcell == 1 | smcell == 1
			 
		} // End IF Block to drop cells
		
		// If they wanted to keep the cases
		else {
		
			// Print message to screen
			di as res "A notification will be added to your graphs to "		 ///   
			"remind you in the future that they may not be appropriate "	 ///   
			"for public release."
			
		} // End ELSE Block for non drop
	
	} // End IF Block for no cell-size supplied
	
	// If user provided a cell size value
	else {
	
		// Drop the cases meeting that criterion
		qui: drop if smschcell == 1 | smcell == 1
		
	} // End ELSE Block for small cell size exemptions
	
	// Check disaggregation variables
	if "`sex'" != ""  {
		la var `sex' "Gender"
	}
	
	// Check race variable
	if "`race'" != "" {
		la var `race' "Ethnoracial Identification"
	}
	
	// Check frl variable
	if "`frl'" != ""  {
		la var `frl' "Free/Reduced Price Lunch Status"
	}
	
	// Create macro to store outtype value labels
	loc outtype la def outtype 
	
	// Loop over values for outtype variable
	forv i = 1/4 {
	
		// Add the outtype vaalue labels
		loc outtype `outtype' `i' `"`: label (outtype) `i''"'
		
	} // End Loop over x-axis values
	
	// Return the full value label list
	ret loc outtype = `"`outtype', modify"'

	// Check bysep parameter
	if !inlist("`bysep'", "by", "sep", "overall") {
	
		// Print error message to screen
		di as err "The bysep parameter can only take two values: " _n		 ///   
		as res "by - " as text "Create single graph with all schools" _n	 ///   
		as res "sep - " as text "Create individual graphs for schools" _n	 ///   
		as res "overall - " as text "Create graph at the district level" _n	 
		
		// Return error code
		err 198
		
	} // End IF Block for bysep validation
	
	// By graph across schools overall
	else if "`bysep'" == "by" & "`disagg'" == ""  & 						 ///   
		"`ontsample'`ontyear'`gpa'" == "" {  
	
		// Build the graph for the entire agency with school-level subplots
		tw `grcmd', `pointlab' `xaxis' `scheme' `ylabtitle' by(`schname', 	 ///   
		`grtitle' `grnotes' subti(`"Schools Overall"', size(medium) span 	 ///   
		c(black)) legend(`legrows' span) `caption') 
		
		// Call to garbage collection subroutine
		chksavecln, grsave(`savename') fmt(`fmt') `gph'  id(all)		 ///   
		`texify' grti("`agency' Schools Overall")
		
	} // End ELSE IF Block for bysep option syntax construction
	
	// Disaggregated by graph within school
	else if "`bysep'" == "by" & "`disagg'" != ""  & 						 ///   
		"`ontsample'`ontyear'`gpa'" == "" {  

		// Loop over the school names
		foreach group of var `disagg' {
		
			// Get unique values of disaggregation variable
			qui: levelsof `group', loc(gr)
			
			// Loop over the individual groups
			foreach v of loc gr {
			
				// Return the value label for the variable
				ret loc grlab`v' = "`: label (`group') `v''"
				loc grlab`v' "`: label (`group') `v''"
				
				// Build the graph for individual schools
				tw `grcmd' if `group' == `v', `pointlab' `xaxis' `ylabtitle' ///   
				by(`schname', `grtitle' `grnotes' legend(`legrows' span)	 ///   
				subti("by `grlab`v'' Students", size(medium) span c(black))  ///   
				`caption') `scheme' name("`group'`v'", replace) 
					
				// Call to garbage collection subroutine
				chksavecln, grsave(`savename') fmt(`fmt') `gph' 		 ///   
				`texify' grti("`grlab`v'' Students") 						 ///   
				id(`: subinstr loc grlab`v' " " "", all')

			} // End Loop over individual groups
			
		} // End Loop over Schools
						
	} // End ELSE IF Block for bysep option syntax construction
	
	// Separate graphs for each school overall
	else if "`bysep'" == "sep" & "`disagg'" == ""  & 						 ///   
		"`ontsample'`ontyear'`gpa'" == "" { 
	
		// Get unique values of school names
		qui: levelsof `schname', loc(schools)
		
		// Loop over the school names
		foreach sch of loc schools {
		
			// School name w/o embedded spaces
			loc schgrnm : subinstr loc sch " " "", all
		
			// Build the graph for individual schools
			tw `grcmd' if `schname' == `"`sch'"', `xaxis' `pointlab' 		 ///   
			`scheme' `ylabtitle' `grtitle' `grnotes' 						 ///   
			name("`schgrnm'", replace) subti(`"`sch' Overall Average"', 	 ///   
			size(medium) span c(black))	legend(`legrows' span) `caption'
			 	
			// Call to garbage collection subroutine
			chksavecln, grsave(`savename') fmt(`fmt') `gph'  `texify'	 ///   
			id(`: subinstr loc sch " " "", all') grti("`agency' Overall Average")
			
		} // End Loop over Schools
	
	} // End ELSE Block for bysep option
	
	// Disaggregated by graph for schools 
	else if "`bysep'" == "sep" & "`disagg'" != ""  & 						 ///   
		"`ontsample'`ontyear'`gpa'" == "" { 
	
		// Get unique values of school names
		qui: levelsof `schname', loc(schools)
		
		// Loop over the school names
		foreach sch of loc schools {
		
			// School name w/o embedded spaces
			loc schgrnm : subinstr loc sch " " "", all

			// Build the graph for individual schools
			tw `grcmd' if `schname' == `"`sch'"', `xaxis' `pointlab' 		 ///   
			`scheme' `ylabtitle' by(`disagg', `grtitle' `grnotes'			 ///   
			subti(`"`sch' Average `dislab'"', size(medium) span c(black))	 ///   
			legend(`legrows' span) `caption') name("`schgrnm'", replace)
			
			// Call to garbage collection subroutine
			chksavecln, grsave(`savename') fmt(`fmt') `gph' `texify'	 ///   
			id(`: subinstr loc sch " " "", all'Disagg)						 ///   
			grti("`sch' Average `dislab'")
				
		} // End Loop over Schools

	} // End ELSE IF Block for bysep option syntax construction
	
	// Overall graph for the agency level 
	else if "`bysep'" == "overall" & "`disagg'" == "" & 					 ///   
		"`ontsample'`ontyear'`gpa'" == "" { 
	
		// Build the graph for the agency overall 
		tw `grcmd', `ylabtitle' `xaxis' `pointlab' `scheme' `grtitle' 		 ///   
		`grnotes' subti(`"`agency' Overall `dislab'"', c(black) span 		 ///   
		size(medium)) legend(`legrows' span) `caption'
		
		// Call to garbage collection subroutine
		chksavecln, grsave(`savename') fmt(`fmt') `gph' `texify'		 ///   
		grti("`agency' Overall") id(agencyOverall)
			
	} // End ELSE IF Block for bysep option syntax construction
	
	// Overall graph for the agency level 
	else if "`bysep'" == "overall" & "`disagg'" != ""  & 					 ///   
		"`ontsample'`ontyear'`gpa'" == "" { 
	
		// Build the graph for the agency overall 
		tw `grcmd', `ylabtitle' `xaxis' `pointlab' `scheme' by(`disagg', 	 ///   
		`grtitle' `grnotes' subti(`"`agency' Overall `dislab'"',			 ///   
		c(black) span size(medium)) legend(`legrows' span) `caption')    
	
		// Call to garbage collection subroutine
		chksavecln, grsave(`savename') fmt(`fmt') `gph' id(allDisagg)	 ///   
		`texify' grti("`agency' Overall `dislab'")
				
	} // End ELSE IF Block for bysep option syntax construction
	
	// Overall graph for the agency level 
	else if "`bysep'" == "overall" & "`disagg'" == "" & 					 ///   
		"`ontsample'`ontyear'`gpa'" != "" { 
	
		// Build the graph for ontrack students for the agency overall 
		tw `grcmd' if ontrack == 1, `labm1' || `grcmd' if ontrack == 2, 	 ///   
		`labm2' || `grcmd' if ontrack == 3, `labm3' `ylabtitle' `grtitle' 	 ///   
		`xaxis' `grnotes' subti(`"`agency' Overall"', c(black) span 		 ///   
		size(medium)) `scheme' legend(label(1 `: label (ontrack) 1') 		 ///   
		label(2 `: label (ontrack) 2') label(3 `: label (ontrack) 3') span	 ///   
		`legrows') `caption'

		// Call to garbage collection subroutine
		chksavecln, grsave(`savename') fmt(`fmt') `gph' `texify'	 	 ///   
		grti("`agency' On-Track Overall") id(overallOnTrack)
				
		// Return value labels for ontrack status
		ret loc ontrack1 "`: label (ontrack) 1'"
		ret loc ontrack2 "`: label (ontrack) 2'"
		ret loc ontrack3 "`: label (ontrack) 3'"
		
	} // End ELSE IF Block for bysep option syntax construction
	
	// Overall graph for the agency level 
	else if "`bysep'" == "overall" & "`disagg'" != ""  & 					 ///   
		"`ontsample'`ontyear'`gpa'" != "" { 

		// Build the graph for ontrack students for the agency overall 
		tw `grcmd' if ontrack == 1, `labm1' || `grcmd' if ontrack == 2, 	 ///   
		`labm2' || `grcmd' if ontrack == 3, `labm3'	`ylabtitle' `scheme' 	 ///   
		`xaxis'  by(`disagg', `grtitle' `grnotes' `caption'					 ///   
		subti(`"`agency' Overall `dislab'"', c(black) span size(medium)))	 ///   
		legend(label(1 `: label (ontrack) 1') `legrows' span				 ///   
		label(2 `: label (ontrack) 2') label(3 `: label (ontrack) 3'))
		
		// Call to garbage collection subroutine
		chksavecln, grsave(`savename') fmt(`fmt') `gph' `texify'	 	 ///   
		grti("`agency' On-Track Overall `dislab'") id(ontrackDisagg)
		
		// Return value labels for ontrack status
		ret loc ontrack1 "`: label (ontrack) 1'"
		ret loc ontrack2 "`: label (ontrack) 2'"
		ret loc ontrack3 "`: label (ontrack) 3'"
		
	} // End ELSE IF Block for bysep option syntax construction
	

	// Issue error message for disaggregated on time stuff
	else if "`ontsample'`ontyear'`gpa'" != "" & "`bysep'" != "overall" {	
	
		// Print message on screeen
		di as res "Please use 'overall' for the bysep argument to create " 	 ///   
		"disaggregated graphs for on-track to graduate graphs."
		
		// Issue error code
		err 198
		
	} // End ELSEIF Block for disaggregated on-track call
	
	// Bring original data back into active memory
	restore

	if "`texify'" != "" {
		file write texreport `"\end{document}"' _n
		file close texreport 
		mkscript, savename(`c(pwd)'/`savename'.tex) scriptnm(mkreport)
		`r(mklatex)'
	}
	
	
// End of Program
end

{
prog def mkscript, rclass

	syntax, savename(string asis) scriptnm(string asis)
	
	if regexm("`c(os)'", "[xX]") == 1 {
		qui: file open script using `"`scriptnm'.sh"', w replace
		file write script "#!/bin/bash" _n
		file write script `"cd "`c(pwd)'""' _n
		file write script `"pdflatex stataout.tex"' _n
		file write script `"pdflatex stataout.tex"' _n
		file write script `"pdflatex stataout.tex"' _n
		file close script
		ret loc mklatex = "! chmod +x `scriptnm'.sh && open -a Terminal.app ./`scriptnm'.sh"
	}
	else {
		qui: file open script using `"`scriptnm'.bat"', w replace
		file write script ":: Batch file to create PDF" _n
		file write script `"chdir /d "`c(pwd)'""' _n
		file write script `"pdflatex stataout.tex"' _n
		file write script `"pdflatex stataout.tex"' _n
		file write script `"pdflatex stataout.tex"' _n
		file close script	
		ret loc mklatex = "! `scriptnm'.bat"
	}
	

end
}


{
// Define subroutine for garbage collection/export
prog def chksavecln

	// Define syntax
	syntax, [grsave(string asis) fmt(string asis) gph id(string asis)		 ///   
			texify grti(string asis) ]
	
	// Prepend underscore to id parameter
	loc id "_`id'"
	
	// Check graph save options
	if "`grsave'" != "" {
	
		// Check for garbage collection option
		if "`fmt'" == "" {
			loc fmt pdf
		}
		
		// Export graph to external format
		qui: gr export `"`grsave'`id'.`fmt'"', as(`fmt') replace
		
		// Check LaTeX option
		if "`texify'" != "" {
		
			// Write an entry to the LaTeX source code
			file write texreport `"\begin{landscape}\begin{figure}[h!]"' _n
			file write texreport `"\includegraphics[scale=.975]{`grsave'`id'.`fmt'}"' _n
			file write texreport `"\caption{`grti' \label{fig: `id'}}"' _n
			file write texreport `"\end{figure}\end{landscape}"' _n
			
		} // End LaTeX Option	
		
		// Check for garbage collection option
		if "`gph'" != "" {
			qui: erase `"`grsave'`id'.gph"'
		}
		
	} // End IF Block for graph export info
	
// End Sub-routine
end
}

{
// Define subroutine to generate variable labels/legend keys
prog def legkey, rclass

	// Define syntax structure
	syntax anything(name=ontrgr) [, statname(string asis) ]
	
	// Check ontrack graph argument
	if "`ontrgr'" == "ontrack" {
		loc grtype "On-Track Status" 
	}
	else {
		loc grtype Persistence
	}
	
	// Define generic Labels for the available metrics
	loc mean `"Average `grtype'"'
	loc min `"Minimum `grtype'"'
	loc max `"Maximum `grtype'"'
	loc mad "Median Absolute Deviation"
	loc mdev "Mean Absolute Deviation"
	loc sd "Standard Deviation"
	
	// Set default return values
	loc laval1 `min'
	loc laval2 `mean'
	loc laval3 `max'

	// Check for percentile values
	if regexm("`statname'", "^([0-9][0-9])$") == 1 {

		if `statname' == 50 {
			loc laval `"Schools Average `grtype'"'
		}
		else {
			// Store the label value in a new macro
			loc laval `"`statname'{superscript:th} %ile `grtype'"'
		}
		
		// Return the value labels
		ret loc varlab `"`laval'"'
		
	} // End IF Block for percentile value
	
	// Check for variance stats
	else if inlist("`statname'", "mad", "mdev", "sd", "semean") {
	
		loc laval1 "``statname'' Below"
		loc laval3 "``statname'' Above"
		
	} // End ELSEIF Block for mad/mdev

	// If central tendency measure
	else {
	
		// Other wise use existing labels above 
		loc laval2 "``statname''"

	} // End ELSE Block 
	
	// Return the local macro
	ret loc varlab1 = `"`laval1'"'
	ret loc varlab2 = `"`laval2'"'
	ret loc varlab3 = `"`laval3'"'

// End of subroutine
end
}

{
// Define subroutine to generate aggregate values
prog def genagg, byable(onecall) 

	// Syntax structure
	syntax anything(name=stats), aggtype(string asis) schname(string asis)   ///   
								 sid(string asis) 
	
	// Construct by prefix syntax for overall results when disaggregated
	if _by() & `"`_byvars'"' != "" & "`aggtype'" == "overall" {
	
		// Store the data in a by prefix local macro
		local by "bys `_byvars' `_byrc0':"
		local bysch "bys `schname' `_byvars' `_byrc0':"

	} // End IF Block for overall disaggregated results
	
	// Construct by prefix syntax for overall results without disaggregation
	else if `"`_byvars'"' == "" & "`aggtype'" == "overall" {
	
		// Store the data in a by prefix local macro
		local by ""
		
		// This is used to estimate the within school aggregations
		local bysch "bys `schname':"

	} // End IF Block for overall disaggregated results
	
	// For disaggregated ontrack for HS graduation outcomes
	else if _by() & `"`_byvars'"' != "" & "`aggtype'" == "ontrack" {
	
		// Store the by prefix syntax for the ontrack for graduation case
		local by "bys ontrack `_byvars' `_byrc0':"
		local bysch "bys `schname' ontrack `_byvars' `_byrc0':"
		local ontrack ontrack
		
	} // End ELSEIF Block for Ontrack status when disaggregated
	
	// For ontrack for HS graduation outcomes w/o disaggregated results
	else if `"`_byvars'"' == "" & "`aggtype'" == "ontrack" {
	
		// Store the by prefix syntax for the ontrack for graduation case
		local by "bys ontrack:"
		local bysch "bys `schname' ontrack:"
		local ontrack ontrack
		
	} // End ELSEIF Block for Ontrack status when disaggregated
	
	// Create macro expressions for the aggregation statistics
	if regexm("`stats'", "[a-zA-Z]") != 1 {
	
		/* Parse the percentile value and store the egen function in a macro 
		so the variable can be passed to it later */
		loc agg2 pctile ,p(`: word 1 of `stats'')
		loc agg3 pctile ,p(`: word 2 of `stats'')
		loc agg4 pctile ,p(`: word 3 of `stats'')

	} // End IF Block for percentile aggregations
	
	// For non-percentile aggregations
	else {
		
		// Aggregations that aren't percentiles will create the function wrapper
		loc agg2 `: word 1 of `stats''  
		loc agg3 `: word 2 of `stats''  
		loc agg4 `: word 3 of `stats''  
		
	} // End ELSE Block for all other aggregations
	
	// Loop over status variables to create aggregates
	forv status = 2/4 {
		
		// Check for percentiles
		if regexm("`agg2'", "^(pctile)") == 1 {
		
			// Pass the variable names to the macros created above for use below
			loc fun1 mean(outcome`status')
			loc fun2 `: word 1 of `agg2''(moutcome`status')`: word 2 of `agg2''
			loc fun3 `: word 1 of `agg3''(moutcome`status')`: word 2 of `agg3''
			loc fun4 `: word 1 of `agg4''(moutcome`status')`: word 2 of `agg4''

			// Creates the overall central tendency within schools
			qui: `bysch' egen double moutcome`status' = `fun1'

			// Creates the overall central tendency within schools
			qui: `by' egen double schmoutcome`status' = `fun3'

			// Estimates lower bound based on the school level aggregates
			qui: `by' egen double loutcome`status' = `fun2'
			
			// Estimates the upper bound based on the school level aggregates
			qui: `by' egen double uoutcome`status' = `fun4'
							   
		} // End IF Block for percentiles
		
		// Not percentile aggregations
		else {
		
			// Pass the variable names to the macros created above for use below
			loc fun1 mean(outcome`status')
			loc fun2 `: word 1 of `agg2''(schmoutcome`status')`: word 2 of `agg2''
			loc fun3 `: word 1 of `agg3''(outcome`status')`: word 2 of `agg3''
			loc fun4 `: word 1 of `agg4''(schmoutcome`status')`: word 2 of `agg4''

			// Creates the overall central tendency across the agency
			qui: `by' egen double moutcome`status' = `fun1'

			// Creates the overall central tendency within schools
			qui: `bysch' egen double schmoutcome`status' = `fun3'

			// Estimates lower bound based on the school level aggregates
			qui: `by' egen double loutcome`status' = `fun2'
			
			// Estimates the upper bound based on the school level aggregates
			qui: `by' egen double uoutcome`status' = `fun4'
							   
		} // End Else Block for non percentile calculations
			
		// Estimates the district/agency level sample size
		qui: `by' egen double cellsize`status' = count(`sid')

		// Estimates the within school sample size
		qui: `bysch' egen double schcellsize`status' = count(`sid')

	} // End Loop over outcome variables
	
// End of data formatting subroutine
end
}		
