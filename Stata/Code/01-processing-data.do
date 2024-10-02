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
	*display "`ids'"
	
	* Unit: household

	local hh_vars floor - n_elder ///
					food_cons - submissionday
	
	* Unit: Household-memebr
 
	local hh_mem gender age read clinic_visit sick days_sick ///
		treat_fin treat_cost ill_impact days_impact
	
	
	
	* define locals with suffix and for reshape
	foreach mem in `hh_mem' {
		
		local mem_vars 		"`mem_vars' `mem'_*"
		local reshape_mem	"`reshape_mem' `mem'_"
		
	}
		
	display "`mem_vars'"
	display "`reshape_mem'"
	
*-------------------------------------------------------------------------------	
* Tidy Data: HH
*-------------------------------------------------------------------------------	
	preserve 
		
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
		
		*encoding area farm unit
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
		
		ds, has(type numeric)
		global numVars `r(varlist)'
		
		foreach numVar of global numVars {
			recode `numVar' (-88 = .d) //.d is DK
		}
		

		* Explore variables for outliers
		sum food_cons nonfood_cons ar_farm, det
		
		* dropping, ordering, labeling before saving
		drop 	ar_farm_unit submissionday crop_other
				
		order 	ar_unit, after(ar_farm)
		
		lab var submissiondate "Date of interview"
		
		isid hhid, sort 
		
		* Save data		
		iesave 	"${data}/Intermediate/TZA_CCT_HH.dta", ///
				idvars(hhid)  version(15) replace ///
				report(path("${outputs}/TZA_CCT_HH_report.csv") replace) 
		
	restore
	
*-------------------------------------------------------------------------------	
* Tidy Data: HH-member 
*-------------------------------------------------------------------------------*

	preserve 

		keep `mem_vars' `ids'
		display "`reshape_mem'"
		
		* tidy: reshape tp hh-mem level 
		reshape long `reshape_mem', i(`ids') j(member) 
		
		* clean variable names 
		rename *_ *
		
		* drop missings 
		drop if mi(gender)
		
		* Cleaning using iecodebook
		// recode the non-responses to extended missing
		// add variable/value labels
		// create a template first, then edit the template and change the syntax to 
		// iecodebook apply
		/*
		iecodebook template 	using ///
								"${outputs}/hh_mem_codebook.xlsx" , replace
		*/
		iecodebook apply 	using "${outputs}/hh_mem_codebook.xlsx" , replace
		isid hhid member						
		
		* Save data: Use iesave to save the clean data and create a report 
		iesave 	"${data}/Intermediate/TZA_CCT_HH_mem.dta", ///
				idvars(hhid member)  version(15) replace ///
				report(path("${outputs}/TZA_CCT_HH_mem_report.csv") replace)    
				
	restore			
	
*-------------------------------------------------------------------------------	
* Tidy Data: Secondary data
*------------------------------------------------------------------------------- 	
	
	* Import secondary data 
	import delimited "${data}/Raw/TZA_amenity.csv", clear
	
	* reshape  
	reshape wide n , i(adm2_en) j(amenity) str
	
	* rename for clarity
	rename n* n_*
	
	* Fix data types
	encode adm2_en , gen(district) 
	
	* Label all vars 
	lab var district "District"
	lab var n_school "No. of schools"
	lab var n_clinic "No. of clinics"
	lab var n_hospital "No. of hospitals"
	
	* Save
	*ssc install keeporder
	keeporder district n_*
	
	save "${data}/Intermediate/TZA_amenity_tidy.dta", replace

	
****************************************************************************end!
	
