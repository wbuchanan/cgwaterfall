// Drop the program from memory if it exists
cap prog drop cgwaterfalldemo

// Define the program
prog def cgwaterfalldemo

	// Set the version underwhich the program should be interpreted
	version 13.1
	
	syntax , id(string asis)
	
	// Check for a valid demo ID
	if !inlist("`id'", "1", "2", "3", "4", "all") {
	
		// Print error message
		di as err "Must select either an ID number representing the order "	 ///   
		"of the Waterfall charts in the Analysis pdf or the word all to "	 ///   
		"demo all graphs"
		
		// Issue error code and exit
		err 198
		
	} // End IF Block for invalid demo id
	
	else if "`id'" == "all" {
		di as res "Starting demo 1"
		do cgwaterfallex1.do
		
		di as res "Starting demo 2 in ..."
		sleep 1000
		di as res "5..." _skip(5)
		sleep 1000
		di as res "4..." _skip(5)
		sleep 1000
		di as res "3..." _skip(5)
		sleep 1000
		di as res "2..." _skip(5)
		sleep 1000
		di as res "1..." _skip(5)
		do cgwaterfallex2.do
		di as res "Starting demo 3 in ..."
		sleep 1000
		di as res "5..." _skip(5)
		sleep 1000
		di as res "4..." _skip(5)
		sleep 1000
		di as res "3..." _skip(5)
		sleep 1000
		di as res "2..." _skip(5)
		sleep 1000
		di as res "1..." _skip(5)
		do cgwaterfallex3.do
		di as res "Starting demo 4 in ..."
		sleep 1000
		di as res "5..." _skip(5)
		sleep 1000
		di as res "4..." _skip(5)
		sleep 1000
		di as res "3..." _skip(5)
		sleep 1000
		di as res "2..." _skip(5)
		sleep 1000
		di as res "1..." _skip(5)
		do cgwaterfallex4.do
	}
	
	else {
		foreach v in `id' {
		if "`v'" != "all" do cgwaterfallex`v'.do
		else continue
		}
	}
	
end	
	
	
