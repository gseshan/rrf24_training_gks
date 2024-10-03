* RRF 2024 - Analyzing Data Template	
*-------------------------------------------------------------------------------	
* Load data
*------------------------------------------------------------------------------- 
	
	*load analysis data 
	global onedrive "C:\Users\WB274813\WBG\RRF24\DataWork"
	global data 	"${onedrive}/Data"
	global github 	"C:\Users\WB274813\Documents\Github\rrf24_training_gks"
	global outputs 	"${github}/Stata/Outputs"
	
	use "${data}/FInal/TZA_CCT_analysis.dta", clear
*-------------------------------------------------------------------------------	
* Summary stats
*------------------------------------------------------------------------------- 

	* defining globals with variables used for summary
	global sumvars 	hh_size n_child_5 n_elder read sick female_head ///
					livestock_now area_acre_w drought_flood crop_damage
	
	* Summary table - overall and by districts
	eststo all: 	estpost sum $sumvars
	eststo dist_1: 	estpost sum $sumvars if district == 1
	eststo dist_2: 	estpost sum $sumvars if district == 2
	eststo dist_3: 	estpost sum $sumvars if district == 3
	
	
	* Exporting table in csv

		esttab 	all dist_1 dist_2 dist_3 ///
			using "${outputs}/summary.csv", replace ///
			label ///
			main(mean %6.2f) aux(sd) ///
			refcat(hh_size "HH characteristics" drought_flood "Shocks" , nolabel) ///
			mtitle("Full Sample" " Kibaha" "Bagamoyos" "Chamwino") ///
			nonotes addn(Mean with standard deviations in parentheses.)
			
	* Also export in tex for latex
		esttab 	all dist_1 dist_2 dist_3 ///
			using "${outputs}/summary.tex", replace ///
			label ///
			main(mean %6.2f) aux(sd) ///
			refcat(hh_size "HH characteristics" drought_flood "Shocks" , nolabel) ///
			mtitle("Full Sample" " Kibaha" "Bagamoyos" "Chamwino") ///
			nonotes addn(Mean with standard deviations in parentheses.)
			
			
*-------------------------------------------------------------------------------	
* Balance tables
*------------------------------------------------------------------------------- 	
	
	* Balance (if they purchased cows or not)
		

	iebaltab 	$sumvars, ///
				grpvar(treatment) ///
				rowvarlabels	///
				format(%12.3f)	///
				savecsv("${outputs}/balance") ///
				savetex("${outputs}/balance") ///
				nonote addnote(" Significance: ***=.01, **=.05, *=.1") replace 	
				
*-------------------------------------------------------------------------------	
* Regressions
*------------------------------------------------------------------------------- 				
				
	* Model 1: Regress of food consumption value on treatment
	regress food_cons_usd_w treatment
	eststo model1		// store regression results

	estadd local clustering "No"
	

	
	* Model 2: Add controls 
	regress food_cons_usd_w treatment crop_damage drought_flood hh_size
	eststo model2
	
	estadd local clustering "No"
	
	
	* Model 3: Add clustering by village
		regress food_cons_usd_w treatment crop_damage drought_flood hh_size, vce(cluster vid)
	eststo model3
	
	estadd local clustering "Yes"
	
	
	esttab 	model1 model2 model3 
	
	* Export results in tex
			
			esttab 	model1 model2 model3 ///
			using "$outputs/regressions.csv" , ///
			label ///
			b(%9.3f) se(%9.3f) ///
			nomtitles ///
			mgroup("Annual food consumption(USD)", pattern(1 0 0 ) span) ///
			scalars("clustering Clustering") ///
			replace
	
	*			using "$outputs/regressions.tex" , ///
*-------------------------------------------------------------------------------			
* Graphs 
*-------------------------------------------------------------------------------	

	* Bar graph by treatment for all districts 
	gr bar 	area_acre_w, over(treatment)
	
		gr bar 	area_acre, ///
			over(treatment) ///
			by(	district, row(1) note("") ///
				 legend(pos(6)) ///
				 title("Area cultivated by treatment assignemnt across districts")) ///
			asy /// 
			legend(rows(1) order(0 "Assignment:" 1 "Control" 2 "Treatment") ) ///
			subtitle(,pos(6) bcolor(none)) ///
			blabel(total, format(%9.1f)) ///
			bar(1, color(green)) bar(2, color(yellow)) ///
			ytitle("Average area cultivated (Acre)") name(g1, replace)
			
			
			gr export "$outputs/fig1.png", replace		
			
	* Distribution of non food consumption by female headed hhs with means

	forvalue f = 0/1 {
		
		sum nonfood_cons_usd if female_head == `f'
		local mean_`f' = r(mean)
	}
	
			
	twoway	(kdensity nonfood_cons_usd if female_head == 1, color(purple)) ///
			(kdensity nonfood_cons_usd if female_head == 0, color(gs12)) ///
			, ///
			xline(`mean_1', lcolor(purple) 	lpattern(dash)) ///
			xline(`mean_0', lcolor(gs12) 		lpattern(dash)) ///
			leg(order(0 "Household Head:" 1 "Female" 2 "Male" ) row(1) pos(6)) ///
			xtitle("Non-food consumption value (USD)") ///
			ytitle("Density") ///
			title("Distribution of non-food consumption") ///
			note("Dashed line represents the average non-food consumption")
			
			
	gr export "$outputs/fig2.png", replace				
			
*-------------------------------------------------------------------------------			
* Graphs: Secondary data
*-------------------------------------------------------------------------------			
			

	use "${data}/Final/TZA_amenity_analysis.dta", clear
	
	* createa  variable to highlight the districts in sample
	encode district, gen(district_code)
	*Kibaha - 6, Chamwino - 3, Bagamayo - 1
	gen in_sample = inlist(district_code, 1, 3, 6)
	
	* Separate indicators by sample
	separate n_school	, by(in_sample)
	separate n_medical	, by(in_sample)
	
	* Graph bar for number of schools by districts
				
				* Graph bar for number of schools by districts
	gr hbar 	n_school0 n_school1, ///
				nofill ///
				over(district, sort(n_school)) ///
				legend(order(0 "Districts:" 1 "Not in Sample" 2 "In Sample") row(1)  pos(6)) ///
				ytitle("Number of Schools") ///
				name(g1, replace)
				
				
	* Graph bar for number of medical facilities by districts				
				gr hbar 	n_medical0 n_medical1 , ///
				nofill ///
				over(district, sort( n_medical )) ///
				legend(order(0 "Districts:" 1 "Not in Sample" 2 "In Sample") row(1)  pos(6)) ///
				ytitle("Number of Medical Facilities") ///
				name(g2, replace)

			*ssc install grc1leg2
				grc1leg2 g1 g2, ///
				row(1) legend(g1) ///
				ycommon xcommon ///
				title("Access to Amenities: By Districts", size())
				
				
gr export "$outputs/fig3.png", replace			

****************************************************************************end!
	
