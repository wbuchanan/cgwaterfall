
// Define tutorial program
prog def cgbubbleprog, rclass

	// Set version number
	version 13
	
	// Define syntax structure
	syntax anything(name=step id="Step Number")
	
	pause on
	
	// Change the EOL Delimiter
	#d ;
	
	/* Read the source code for the COLLEGE ENROLLMENT RATES BY 8TH GRADE 
	ACHIEVEMENT QUARTILES - BUBBLES plot . */
	// infix str cgbubble 1-2045 using `"`c(sysdir_personal)'c/cgbubble1.txt"', clear ;
	infix str cgbubble 1-167 using `"cgbubble1.txt"', clear ;
	
	// Compress the data
	compress ;

	// Wait for user to see the data loaded before moving forward
	di as res "Once you see data loaded into Stata enter q into the console "
	"and hit enter." _request(_pausetest) ;
	
	// See if anyone tries something different
	while "`pausetest'" != "q" { ;
	
		// Print message
		di as res "This was only a test.  If I were actually using the " in 
		smcl {help pause} as res " command, q would advance past the pause and "
		"BREAK would send a SIGHUP/SIGKILL to the running process." _request(_pausetest);	
		
	} ; // End IF Block for non q pressers
	
	qui: ds
	loc var `r(varlist)'
	
	// Read all lines into local macros
	forv i = 1/55 {
	
		// Store each line in its own named macro
		loc line`i' `"`= `var'[`i']'"'
		
	} // End Loop over observations
	
	// Check the step
	if "`step'" == "1" { ;
	
		// Display message on the screen
		di as res "If you want to make your do files more flexible, you will "
		"need to find places where you can easily substitute a parameterized "
		"value into the code, as well as a reasonably meaningful name to "
		"reference the argument." ;
		
		// Set sleep for 10 seconds
		sleep 10000;
		
		// Display question
		di in yellow "Here's an easy one to start...Can anything be "
		"parameterized in " in green "`line4'" in yellow "? (Y/N)" _request(_q1);
		
		// Check answer
		while !inlist(lower("`q1'"), "y", "n") == 1 { ;
		
			// Print alert
			di as err "There are only two answer choices. Please try again." ;
			
		} ;
		
		// For a no answer
		if lower("`q1'") == "n" { ;
		
			// Print a different message
			di as err "Are you sure?  Have you ever run into issues with file "
			"naming conventions where you work, or know others who have?" _n(10);
			
			di as res "Why not allow the user to tell your program what file "
			"it should use as an option and assume they have the data loaded "
			"if they don't specify a file?" _n(10) ;
			
			di in green "Assuming a specific file is available in memory will "
			"almost always be risky, but giving the end-user a chance to tell "
			"your program where the data are located can help." _n(10);
			
		} ; // End IF Block for Nothing changed to question 1
		
		// Otherwise
		else { ;
		
			// Create a new variable and replace the file name with a parameter
			noi: g cgbubble2 = subinstr(cgbubble1, "CG_Analysis", `"`"`using'"'"', .) in 4 ;
			
		} ; // End ELSE Block for good answer

		// Compare the two values 
		li in 4 ;
		
		//Print text to console
		di in green "Which do you think would be more flexible?  Why/Why not?";
		
	} ; // End Step 1
	

	#d cr
	
// End program
end

	
