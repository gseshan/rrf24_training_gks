* RRF 2024 - Processing Data Template	
*-------------------------------------------------------------------------------	
* Loading data
*------------------------------------------------------------------------------- 	
	
	global onedrive "C:\Users\WB274813\WBG\RRF24\DataWork\"
	global data 	"${onedrive}\Data"
	global github 	"C:\Users\WB274813\Documents\Github\rrf24_training_gks"
	global outputs 	"${github}/Stata/Outputs"
	
	* Load TZA_CCT_baseline.dta
	use "${data}\Raw\TZA_CCT_baseline.dta", clear

	
*-------------------------------------------------------------------------------	
* Checking for unique ID and fixing duplicates
*------------------------------------------------------------------------------- 		

	*isid hhid
	*ssc install iefieldkit, replace
	
	* Identify duplicates 
	ieduplicates	hhid ///
					using "${outputs}/duplicates.xlsx", ///
					uniquevars(key) ///
					keepvars(vid enid submissionday) ///
					nodaily
					
	*isid hhid
	
*-------------------------------------------------------------------------------	
* Define locals to store variables for each level
*------------------------------------------------------------------------------- 							
	
	* IDs
	*local ids 		???	
	local ids 		vid hhid enid
		
	* Unit: household

	local hh_vars floor - n_elder ///
					food_cons - submissionday
	
	* Unit: Household-memebr
 
	local hh_member gender age read clinic_visit sick days_sick ///
	treat_fin treat_cost ill_impact days_impact
	
	
	
	* define locals with suffix and for reshape
	foreach mem in `hh_mem' {
		
		local mem_vars 		"`mem_vars' `mem'_*"
		local reshape_mem	"`reshape_mem' `mem'_"
	}
		
	
*-------------------------------------------------------------------------------	
* Tidy Data: HH
*-------------------------------------------------------------------------------	

	*preserve 
		
		* Keep HH vars
		keep `ids' `hh_vars'
		
		* Check if data type is string
				
		
		* Fix data types 
		* numeric should be numeric
		* dates should be in the date format
		* Categorical should have value labels 
		
				
		

		*fixing submission date
		gen submissiondate=date(submissionday,"YMD hms")
		format submissiondate %td
			
		encode ar_farm_unit, gen(ar_unit)
		labelbook ar_unit
		
		destring duration, replace
		
		*clean crop other
		replace crop_other = proper(crop_other) 
		*labelbook crop
		replace crop = 40 if regex(crop_other, "Coconut")==1
		replace crop = 41 if regex(crop_other, "Sesame")==1
		label define df_CROP 40 "Coconut" 41 "Sesame", add
		
		
			* Turn numeric variables with negative values into missings
		*ds, has(type ???)
		ds, has(type string)	
		ds, has(type numeric)
		global numVars `r(varlist)'
		
		foreach numVar of global numVars {
			recode `numVar' (-88 = .d)
		}
		
		
		
		
		global ??? ???

		foreach numVar of global numVars {
			
			???
		}	
		
		* Explore variables for outliers
		sum ???
		
		* dropping, ordering, labeling before saving
		drop 	???
				
		order 	???
		
		lab var ???
		
		isid ???
		
		* Save data		
		iesave 	"${data}/Intermediate/???", ///
				idvars(???)  version(???) replace ///
				report(path("${outputs}/???.csv") replace)  
		
	restore
	
*-------------------------------------------------------------------------------	
* Tidy Data: HH-member 
*-------------------------------------------------------------------------------*

	preserve 

		keep ???

		* tidy: reshape tp hh-mem level 
		reshape ???
		
		* clean variable names 
		rename ???
		
		* drop missings 
		drop if mi(???)
		
		* Cleaning using iecodebook
		// recode the non-responses to extended missing
		// add variable/value labels
		// create a template first, then edit the template and change the syntax to 
		// iecodebook apply
		iecodebook template 	using ///
								"${outputs}/hh_mem_codebook.xlsx"
								
		isid ???					
		
		* Save data: Use iesave to save the clean data and create a report 
		iesave 	???  
				
	restore			
	
*-------------------------------------------------------------------------------	
* Tidy Data: Secondary data
*------------------------------------------------------------------------------- 	
	
	* Import secondary data 
	???
	
	* reshape  
	reshape ???
	
	* rename for clarity
	rename ???
	
	* Fix data types
	encode ???
	
	* Label all vars 
	lab var district "District"
	???
	???
	???
	
	* Save
	keeporder ???
	
	save "${data}/Intermediate/???.dta", replace

	
****************************************************************************end!
	
