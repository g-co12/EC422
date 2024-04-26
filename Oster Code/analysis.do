clear all 
set more off
set maxvar 32000
cap log close
version 16

global state_list  colorado connecticut massachusetts minnesota mississippi ohio rhode_island virginia west_virginia wisconsin wyoming

global datapath_clean "../Data/Clean"
global outputfile "../Output"

global colorado_abbrev CO
global connecticut_abbrev CT
global massachusetts_abbrev MA
global minnesota_abbrev MN
global mississippi_abbrev MS
global ohio_abbrev OH
global rhode_island_abbrev RI
global virginia_abbrev VA
global west_virginia_abbrev WV
global wisconsin_abbrev WI
global wyoming_abbrev WY

global ela_title "ELA"
global math_title "Math"

program main 
	
	package_install_check
	
	log using "$outputfile/analysis_log.log", replace


	exhibit_1_sumstats_panela
	exhibit_2_demographics
	exhibit_3_dotplot
	exhibit_4_regressions
	exhibit_5_robustness_fe
	
	appendix_regressions_excludeCT
	appendix_state_histograms
	cap log close
	
end
	
program exhibit_1_sumstats_panela
{
	use "${datapath_clean}/state_score_data", clear
	egen state_gr = group(state)
	preserve
	gen count = 1
	collapse (sum) count, by(state district_id)
	tabstat count, by(state) s(n) save
	tabstatmat counts 
	matrix counts = counts
	restore
	preserve
	duplicates drop state district_id year, force
	gen count = 1
	collapse (sum) count, by(state district_id)
	tabstat count, by(state) s(mean) save
	tabstatmat years 
	matrix years = years
	restore
	preserve 
	
	gen share_blh = share_black + share_hisp
	
	foreach var in pass share_inperson share_virtual share_hybrid share_blh share_lunch  share_ELL {
		replace `var' = `var' * 100
	}
	gen pass21 = pass if year == 2021
	gen pass19 = pass if year == 2019
	collapse (firstnm) share_inperson share_hybrid share_virtual share_blh share_lunch share_ELL EnrollmentTotal, by(state district_id)
	tabstat  share_inperson share_hybrid share_virtual share_blh share_lunch share_ELL [aw = EnrollmentTotal], save s(mean) by(state)
	tabstatmat sum_stats
	matrix sum_stats = sum_stats
	matrix sum_stats = counts, years, sum_stats
	mat li sum_stats
	qui levelsof state, local(states)
	mat rownames sum_stats = "CO" "CT" "MA" "MN" "MS" "OH" "RI" "VA" "WI" "WV" "WY" "Overall"
	mat colnames sum_stats = "Districts" "Avg Years" "\% In-Person" "\% Hybrid" "\% Virtual" "\% Black \& Hispanic" "\% FRPL" "\% ELL"
	esttab matrix(sum_stats, fmt(0 1 1 1 1 1 1 1 1 )) using "$outputfile/tables/summary_stats_panela.tex", compress nomtitle eqlabels(, none) replace
	
}
end

program exhibit_2_demographics
{	
	cap rm "$outputfile/tables/demographics.tex"
	use "${datapath_clean}/state_score_data", clear
	gen temp1 = pass if year<2021
	egen old_pass = mean(temp1), by(state district_id)

	egen temp2=mean(temp1), by(state)
	replace old_pass =old_pass - temp2

	keep if year==2021
	gen share_blh = share_black + share_hisp

	rename case_rate_per100k_zip case_rate
	replace case_rate = case_rate/100
	
	label var old_pass "Prev Pass Rate"
	label var share_black "Share Black"
	label var share_hisp "Share Hispanic"
	label var share_lunch "Share FRPL"
	label var share_ELL "Share ELL"
	label var case_rate "Avg Case Rate"
	label var trump_vote_share "Repub Vote Share"
	
	
	foreach var in old_pass share_black share_hisp share_lunch share_ELL case_rate trump_vote_share {
		reg share_inperson `var' [aw=EnrollmentTotal], r
		est sto m1
		areg share_inperson `var' [aw=EnrollmentTotal], absorb(state) vce(robust)
		est sto m2		
		areg share_inperson `var' i.commute_zone [aw=EnrollmentTotal], absorb(state) vce(robust)
		est sto m3		
		
		esttab m1 m2 m3 using "$outputfile/tables/demographics.tex", append f keep(`var') label collabels(none) b(3) se(3) se noobs nostar nonotes nonum nolines wide nomtitles nodep 
	}
	
}
end

program exhibit_3_dotplot 
{
	use "${datapath_clean}/state_score_data", clear
	
	egen state_gr = group(state)
	labmask state_gr, values(state)
	egen district_unique = group(district_id state_gr)
	
	egen inperson_grp = cut(share_inperson), at(0,0.25,0.5,0.75,1.1)
	replace inperson_grp=inperson_grp/0.25
	
	xtile group_Black = share_black [aw=EnrollmentTotal], nq(3)  
	xtile group_Hispanic = share_hisp [aw=EnrollmentTotal], nq(3)
	xtile group_FRPL = share_lunch [aw=EnrollmentTotal], nq(3)
	xtile group_ELL = share_ELL [aw=EnrollmentTotal], nq(3)
	
	egen panel_var = group(district_unique subject) 
	xtset panel_var year
	
	gen pass_change = pass - L1.pass if year<2021
	replace pass_change = pass - L2.pass if year == 2021 
	
	replace pass_change = pass_change*100
	
	mean pass_change if subject=="math", over(year) 
	mean pass_change if subject=="ela", over(year) 
	mean pass_change if subject=="math" & year==2021, over(state_gr) 
	mean pass_change if subject=="ela" & year==2021, over(state_gr) 
	
	foreach subject in math ela {
	
	foreach i of numlist 17/19 21 {
          quietly mean pass_change [aw=EnrollmentTotal] if subject=="`subject'" & year==20`i'
          estimate store `subject'`i'_m1		  
		  quietly mean pass_change [aw=EnrollmentTotal] if subject=="`subject'" & year==20`i', over(state_gr)
          estimate store `subject'`i'_m2
		  quietly mean pass_change [aw=EnrollmentTotal] if subject=="`subject'" & year==20`i', over(inperson_grp)
          estimate store `subject'`i'_m3
		  quietly mean pass_change [aw=EnrollmentTotal] if subject=="`subject'" & year==20`i', over(group_Black)
          estimate store `subject'`i'_m4
		  quietly mean pass_change [aw=EnrollmentTotal] if subject=="`subject'" & year==20`i', over(group_Hispanic)
          estimate store `subject'`i'_m5
		  quietly mean pass_change [aw=EnrollmentTotal] if subject=="`subject'" & year==20`i', over(group_FRPL)
          estimate store `subject'`i'_m6
		  quietly mean pass_change [aw=EnrollmentTotal] if subject=="`subject'" & year==20`i', over(group_ELL)
          estimate store `subject'`i'_m7
       }
	   
	}
	
	coefplot (math2*, label(Spring 2021) msymbol(O)) (math1*, label(Spring 2016-2019) msymbol(Oh)), bylabel(Math) || (ela2*, label(Spring 2021) msymbol(O)) (ela1*, label(Spring 2016-2019) msymbol(Oh)), bylabel(ELA) ||, nooffsets noci legend(off) grid(none) scheme(s1mono) order(. pass_change . *@1.s* *@2.s* *@3.s* *@4.s* *@5.s* *@6.s* *@7.s* *@8.s* *@9.s* *@10.s* *@11.s* . *0.inperson* *1.inperson* *2.inperson* *3.inperson* . *_Black . *_Hispanic . *_FRPL . *_ELL .) groups(*_change = "{bf:Overall}" *inperson*="{bf:% In-Person}" *_gr = "{bf:States}" *_Black = "{bf:Black}" *_Hispanic = "{bf:Hispanic}" *_FRPL = "{bf:FRPL}" *_ELL = "{bf:ELL}", angle(horizontal)) coeflabels(pass_change = " " *0.inperson*="0-25" *1.inperson*="25-50" *2.inperson*="50-75" *3.inperson*="75-100" *@1.group*= "Low" *@2.group*= "Middle" *@3.group* = "High" *@1.s*="CO" *@2.s*="CT" *@3.s*="MA" *@4.s*="MN" *@5.s*="MS" *@6.s*="OH" *@7.s*="RI" *@8.s*="VA" *@9.s*="WI" *@10.s*="WV" *@11.s*="WY" ) ylabel(,labsize(small)) ysize(10) xsize(7) xline(0) xtitle("						Average Change in Pass Rates (percentage points)", size(small))


graph export "$outputfile/figures/pass_rate_comparisons.pdf", replace

}
end

program exhibit_4_regressions
{
	set matsize 800
	use "${datapath_clean}/state_score_data", clear
	
	
	egen state_gr = group(state)
	egen district_unique = group(district_id state_gr)

	gen treat_year=year==2021
	gen virtual_2021=share_virtual*treat_year
	gen hybrid_2021=share_hybrid*treat_year
	gen inperson_2021=share_inperson*treat_year


	foreach var in black hisp lunch {
		if "`var'"=="black" {
			local label "Black" 
		}
		else if "`var'"=="hisp" {
			local label "Hispanic" 
		}
		else {
			local label "FRPL" 
		}
		
		gen c_`var'_yr_ip = share_`var'*inperson_2021
		gen c_`var'_yr_hybrid = share_`var'*hybrid_2021

		gen c_`var'_ip = share_`var' * share_inperson
		gen c_`var'_hybrid = share_`var'*share_hybrid
		
		label var c_`var'_yr_ip "\% `label' * \% In-Person * 2021"
		label var c_`var'_yr_hybrid "\% `label' * \% Hybrid * 2021"
		label var c_`var'_ip "\% `label' * \% In-Person"
		label var c_`var'_hybrid "\% `label' * \% Hybrid"
		
}

	gen share_blh = share_black + share_hisp
	replace share_inperson=1 if year<2021
	replace share_hybrid=0 if year<2021
	replace share_virtual=0 if year<2021

	label var inperson_2021 "\% In-Person * 2021"
	label var hybrid_2021 "\% Hybrid * 2021"
	
	label var share_inperson "\% In-Person"
	label var share_hybrid "\% Hybrid"
	
	


	
* Panel A

	foreach subject in math ela {
		quietly xi: areg pass share_inperson share_hybrid i.year share_white share_black share_hisp missing_lunch share_lunch_updated missing_ELL share_ELL_updated unemployment participation participate_denom i.year*i.state_gr [aw = EnrollmentTotal] if subject=="`subject'", absorb(district_unique) cluster(district_unique)
		esttab ., keep(share_inperson share_hybrid)
		est sto m1_`subject'
		quietly xi: areg pass share_inperson share_hybrid i.year share_white share_black share_hisp missing_lunch share_lunch_updated  missing_ELL share_ELL_updated unemployment participation participate_denom i.year*i.commute_zone i.year*i.state_gr [aw = EnrollmentTotal] if subject=="`subject'", absorb(district_unique) cluster(district_unique)
		esttab ., keep(share_inperson share_hybrid)
		est sto m2_`subject'
		quietly xi: areg pass share_inperson share_hybrid i.year share_white share_black share_hisp missing_lunch share_lunch_updated  missing_ELL share_ELL_updated unemployment participation participate_denom i.year*i.countyfips i.year*i.state_gr [aw = EnrollmentTotal] if subject=="`subject'", absorb(district_unique) cluster(district_unique)
		esttab ., keep(share_inperson share_hybrid)	
		est sto m3_`subject'
		
	}
		esttab m1_math m2_math m3_math m1_ela m2_ela m3_ela using "$outputfile/tables/main_regressions_panelA.tex", keep(share_inperson share_hybrid) collabels("", lhs(Pass)) label s(N, label("Observations")) se nostar nonotes replace
		
*Panel B: Interactions


	
		foreach subject in math ela {
		quietly xi: areg pass inperson_2021 hybrid_2021 c_black* i.year*share_black share_white share_black share_hisp missing_lunch share_lunch_updated missing_ELL share_ELL_updated unemployment  participation participate_denom i.year*i.commute_zone i.year*i.state_gr  [aw = EnrollmentTotal] if subject=="`subject'", absorb(district_unique) cluster(district_unique)	
		esttab ., keep(inperson_2021 hybrid_2021 c_black_yr_ip c_black_yr_hybrid) star(* .1 ** .05 *** .01)
		est sto m1_`subject'
		quietly xi: areg pass inperson_2021 hybrid_2021 c_hisp* i.year*share_hisp share_white share_black share_hisp missing_lunch share_lunch_updated missing_ELL share_ELL_updated unemployment  participation participate_denom i.year*i.commute_zone i.year*i.state_gr  [aw = EnrollmentTotal] if subject=="`subject'", absorb(district_unique) cluster(district_unique)
		esttab ., keep(inperson_2021 hybrid_2021 c_hisp_yr_ip c_hisp_yr_hybrid) star(* .1 ** .05 *** .01)
		est sto m2_`subject'
		quietly xi: areg pass inperson_2021 hybrid_2021 c_lunch* i.year*share_lunch share_white share_black share_hisp missing_lunch share_lunch_updated missing_ELL share_ELL_updated unemployment participation participate_denom i.year*i.commute_zone i.year*i.state_gr  [aw = EnrollmentTotal] if subject=="`subject'", absorb(district_unique) cluster(district_unique)
		esttab ., keep(inperson_2021 hybrid_2021 c_lunch*) star(* .1 ** .05 *** .01)
		est sto m3_`subject'
		}
	
	esttab m1_math m2_math m3_math m1_ela m2_ela m3_ela using "$outputfile/tables/main_regressions_panelB.tex", keep(inperson_2021 hybrid_2021 c_black_yr_ip c_black_yr_hybrid c_hisp_yr_ip c_hisp_yr_hybrid c_lunch_yr_ip c_lunch_yr_hybrid) collabels("", lhs(Pass)) label s(N, label("Observations")) se nostar nonotes replace



	
}

end


program exhibit_5_robustness_fe
{
* BY Grade

	set matsize 800
	use "${datapath_clean}/state_score_data", clear

	egen state_gr = group(state)
	egen district_unique = group(district_id state_gr)
	
	replace share_inperson=1 if year<2021
	replace share_hybrid=0 if year<2021
	

	quietly xi: areg pass share_inperson share_hybrid i.year share_white share_black share_hisp missing_lunch share_lunch_updated missing_ELL share_ELL_updated unemployment participation participate_denom i.year*i.commute_zone i.year*i.state_gr [aw = EnrollmentTotal] if subject=="math" & pass3~=., absorb(district_unique)  cluster(district_unique)
	esttab ., keep(share_inperson share_hybrid) b(3) se(3) se nostar
	esttab r(coefs)
	mat C=r(coefs)[1,1...],r(coefs)[2,1...]
	
	quietly xi: areg pass share_inperson share_hybrid i.year share_white share_black share_hisp missing_lunch share_lunch_updated missing_ELL share_ELL_updated unemployment participation participate_denom i.year*i.commute_zone i.year*i.state_gr [aw = EnrollmentTotal] if subject=="ela" & pass3~=., absorb(district_unique)  cluster(district_unique)
	esttab ., keep(share_inperson share_hybrid) b(3) se(3) se nostar	
	esttab r(coefs)
	mat C=C,r(coefs)[1,1...],r(coefs)[2,1...]
	
	forvalues i=3/8 {
		quietly xi: areg pass`i' share_inperson share_hybrid i.year share_white share_black share_hisp missing_lunch share_lunch_updated missing_ELL share_ELL_updated unemployment participation participate_denom  i.year*i.commute_zone i.year*i.state_gr [aw = EnrollmentTotal] if subject=="math" & pass3~=., absorb(district_unique)  cluster(district_unique)
		esttab ., keep(share_inperson share_hybrid)  b(3) se(3) se nostar 
		esttab r(coefs)
		mat C`i'=r(coefs)[1,1...],r(coefs)[2,1...]
		quietly xi: areg pass`i' share_inperson share_hybrid i.year share_white share_black share_hisp missing_lunch share_lunch_updated missing_ELL share_ELL_updated unemployment participation participate_denom i.year*i.commute_zone i.year*i.state_gr [aw = EnrollmentTotal] if subject=="ela" & pass3~=., absorb(district_unique)  cluster(district_unique)
		esttab ., keep(share_inperson share_hybrid)  b(3) se(3) se nostar
		esttab r(coefs)
		mat C`i'=C`i',r(coefs)[1,1...],r(coefs)[2,1...]

	}
	mat A=C\C3\C4\C5\C6\C7\C8
	mat rownames A = "All" "Grade 3" "Grade 4" "Grade 5" "Grade 6" "Grade 7" "Grade 8"
	esttab matrix(A, fmt(3 3 3 3 3 3 3 3)) using "$outputfile/tables/robust_fe_grades.tex", compress nomtitle collabels(,none) eqlabels(, none) replace

* Continuous Measures


	set matsize 800
	use "${datapath_clean}/state_score_data", clear

	egen state_gr = group(state)
	egen district_unique = group(district_id state_gr)

	replace share_inperson=1 if year<2021
	replace share_hybrid=0 if year<2021
	
	gen total_share = share_inperson + share_hybrid
	
	
	foreach sub in math ela {
		quietly xi: areg pass share_inperson share_hybrid i.year share_white share_black share_hisp missing_lunch share_lunch_updated missing_ELL share_ELL_updated unemployment participation participate_denom i.year*i.commute_zone i.year*i.state_gr [aw = EnrollmentTotal] if subject=="`sub'" & cts_pass_advanced ~=., absorb(district_unique)  cluster(district_unique)
		esttab ., keep(share_inperson share_hybrid) b(3) se(3) se nostar
		esttab r(coefs)
		mat C_`sub'=r(coefs)[1,1...],r(coefs)[2,1...]
	}
	
	foreach var in below advanced {
	foreach sub in math ela {
		quietly xi: areg cts_pass_`var' share_inperson share_hybrid i.year share_white share_black share_hisp missing_lunch share_lunch_updated missing_ELL share_ELL_updated unemployment participation participate_denom i.year*i.commute_zone i.year*i.state_gr [aw = EnrollmentTotal] if subject=="`sub'", absorb(district_unique)  cluster(district_unique)
		esttab ., keep(share_inperson share_hybrid)  b(3) se(3) se nostar 
		esttab r(coefs)
		mat C_`var'_`sub'=r(coefs)[1,1...],r(coefs)[2,1...]
	}
	}	
	mat Cont=(C_math,C_ela)\(C_below_math, C_below_ela)\(C_advanced_math, C_advanced_ela)
	mat rownames Cont = "All" "Below Pass" "Advanced Pass"
	esttab matrix(Cont, fmt(3 3 3 3 3 3 3 3)) using "$outputfile/tables/robust_fe_continuous.tex", compress nomtitle collabels(,none) eqlabels(, none) replace

}

end

program define appendix_regressions_excludeCT

	use "${datapath_clean}/state_score_data", clear
	
	drop if state=="CT"
	
	egen state_gr = group(state)
	egen district_unique = group(district_id state_gr)

	gen treat_year=year==2021
	gen virtual_2021=share_virtual*treat_year
	gen hybrid_2021=share_hybrid*treat_year
	gen inperson_2021=share_inperson*treat_year


	foreach var in black hisp lunch {
		if "`var'"=="black" {
			local label "Black" 
		}
		else if "`var'"=="hisp" {
			local label "Hispanic" 
		}
		else {
			local label "FRPL" 
		}		
		
}

	gen share_blh = share_black + share_hisp
	replace share_inperson=1 if year<2021
	replace share_hybrid=0 if year<2021
	replace share_virtual=0 if year<2021

	label var inperson_2021 "\% In-Person * 2021"
	label var hybrid_2021 "\% Hybrid * 2021"
	
	label var share_inperson "\% In-Person"
	label var share_hybrid "\% Hybrid"
	
	


	
* Panel A

	foreach subject in math ela {
		quietly xi: areg pass share_inperson share_hybrid i.year share_white share_black share_hisp missing_lunch share_lunch_updated missing_ELL share_ELL_updated unemployment participation participate_denom i.year*i.state_gr [aw = EnrollmentTotal] if subject=="`subject'", absorb(district_unique) cluster(district_unique)
		esttab ., keep(share_inperson share_hybrid)
		est sto m1_`subject'
		quietly xi: areg pass share_inperson share_hybrid i.year share_white share_black share_hisp missing_lunch share_lunch_updated  missing_ELL share_ELL_updated unemployment participation participate_denom i.year*i.commute_zone i.year*i.state_gr [aw = EnrollmentTotal] if subject=="`subject'", absorb(district_unique) cluster(district_unique)
		esttab ., keep(share_inperson share_hybrid)
		est sto m2_`subject'
		quietly xi: areg pass share_inperson share_hybrid i.year share_white share_black share_hisp missing_lunch share_lunch_updated  missing_ELL share_ELL_updated unemployment participation participate_denom i.year*i.countyfips i.year*i.state_gr [aw = EnrollmentTotal] if subject=="`subject'", absorb(district_unique) cluster(district_unique)
		esttab ., keep(share_inperson share_hybrid)	
		est sto m3_`subject'
		
	}
		esttab m1_math m2_math m3_math m1_ela m2_ela m3_ela using "$outputfile/tables/regressions_noCT.tex", keep(share_inperson share_hybrid) collabels("", lhs(Pass)) label s(N, label("Observations")) se nostar nonotes replace

end

program define appendix_state_histograms
	use "${datapath_clean}/state_score_data", clear
	graph box share_virtual [aw = EnrollmentTotal] if subject=="math" & year==2021, over(state) scheme(s1mono) ytitle("Percent Virtual")
	graph export "$outputfile/figures/box_virtual.pdf", replace
	graph box share_hybrid [aw = EnrollmentTotal] if subject=="math" & year==2021, over(state) scheme(s1mono) ytitle("Percent Hybrid")
	graph export "$outputfile/figures/box_hybrid.pdf", replace
	graph box share_inperson [aw = EnrollmentTotal] if subject=="math" & year==2021, over(state) scheme(s1mono) ytitle("Percent In-Person")
	graph export "$outputfile/figures/box_inperson.pdf", replace
end

program define package_install_check

	capture : which labmask
	if (_rc) {
		display as error in smcl `"Please install package {it:labutil} from SSC in order to run this do-file;"' _newline ///
					`"You can do so by clicking this link: {stata "ssc install labutil":auto-install labutil}"'
		exit 199
	}

	capture : which tabstatmat
	if (_rc) {
		display as error in smcl `"Please install package {it:tabstatmat} from SSC in order to run this do-file;"' _newline ///
			`"you can do so by clicking this link: {stata "ssc install tabstatmat":auto-install tabstatmat}"'
		exit 199
	}
	
	capture : which estout
	if (_rc) {
		display as error in smcl `"Please install package {it:estout} from SSC in order to run this do-file;"' _newline ///
			`"you can do so by clicking this link: {stata "ssc install estout":auto-install estout}"'
		exit 199
	}
	
	capture : which coefplot
	if (_rc) {
		display as error in smcl `"Please install package {it:coefplot} from SSC in order to run this do-file;"' _newline ///
			`"you can do so by clicking this link: {stata "ssc install coefplot":auto-install coefplot}"'
		exit 199
	}

end


main
