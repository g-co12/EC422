clear all 
set more off
set maxvar 32000
set excelxlsxlargefile on

global state_clean_list colorado connecticut massachusetts minnesota mississippi ohio rhode_island virginia west_virginia wisconsin wyoming 

global datapath_raw_statescore "../Data/Raw/statescoredata"
global datapath_raw_other "../Data/Raw"
global datapath_clean "../Data/Clean"
global learning_model "../Data/Raw/schooling_mode_data.dta"

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


program main 

    foreach state in $state_clean_list { 
      		clean_`state'
      	}

    grade_level
  	cleanup_cts
	make_weights

	clean_nces
	clean_case_data
    clean_commuting_zones
	clean_trump_vote
	clean_unemployment
	
    create_final_dataset

end 

program clean_colorado
	foreach fy in 2016 2017 2018 2019 2021 {
		tempfile `fy'
		if `fy' != 2016 {
			if `fy' == 2021 {
				local start A28
				local sheet "CMAS ELA and Math"
				local keeplist districtcode districtname content grade numberoftotalrecords numberofvalidscores numberofnoscores participationrate meanscalescore standarddeviation numberdidnotyetmeetexpectat percentdidnotyetmeetexpecta numberpartiallymetexpectation percentpartiallymetexpectatio numberapproachedexpectations percentapproachedexpectations numbermetexpectations percentmetexpectations numberexceededexpectations percentexceededexpectations numbermetorexceededexpectati percentmetorexceededexpectat
				local renamelist district_id district_name subject grade n_tested n_scored n_noscore participation mean sd n_below cts_pass_below n_partially cts_pass_partially n_approaching cts_pass_approaching n_at cts_pass_proficient n_above cts_pass_advanced n_pass pass
			}
			else if `fy' == 2019 {
				local start A12
				local sheet "CMAS ELA and Math"
				local keeplist districtcode districtname subject grade numberoftotalrecords numberofvalidscores numberofnoscores participationrate meanscalescore standarddeviation numberdidnotyetmeetexpectat percentdidnotyetmeetexpecta numberpartiallymetexpectation percentpartiallymetexpectatio numberapproachedexpectations percentapproachedexpectations numbermetexpectations percentmetexpectations numberexceededexpectations percentexceededexpectations numbermetorexceededexpectati percentmetorexceededexpectat
				local renamelist district_id district_name subject grade n_tested n_scored n_noscore participation mean sd n_below cts_pass_below n_partially cts_pass_partially n_approaching cts_pass_approaching n_at cts_pass_proficient n_above cts_pass_advanced n_pass pass
			}
			else if `fy' == 2018 {
				local start A7
				local sheet "District and School Detail_1"
				local keeplist districtcode districtname content testgrade oftotalrecords ofvalidscores ofnoscores participationrate meanscalescore didnotyetmeetexpectations n partiallymetexpectations p approachedexpectations r metexpectations t exceededexpectations v metorexceededexpectations x
				local renamelist district_id district_name subject grade n_tested n_scored n_noscore participation mean n_below cts_pass_below n_partially cts_pass_partially n_approaching cts_pass_approaching n_at cts_pass_proficient n_above cts_pass_advanced n_pass pass
			}
			else if `fy' == 2017 {
				local start A5
				local sheet "District and School Detail_1"
				local keeplist districtcode districtname content test numberoftotalrecords numberofvalidscores numberofnoscores participationrate meanscalescore numberdidnotyetmeetexpect didnotyetmeetexpectation numberpartiallymetexpectati partiallymetexpectations numberapproachedexpectations approachedexpectations numbermetexpectations metexpectations numberexceededexpectations exceededexpectations numbermetorexceededexpecta metorexceededexpectations
				local renamelist district_id district_name subject grade n_tested n_scored n_noscore participation mean n_below cts_pass_below n_partially cts_pass_partially n_approaching cts_pass_approaching n_at cts_pass_proficient n_above cts_pass_advanced n_pass pass

			}
			import excel using "${datapath_raw_statescore}/colorado/`fy'/ela.xlsx", clear case(lower) sheet(`sheet') cellrange(`start') firstrow
			keep if level == "DISTRICT"
			keep `keeplist'
			rename (`keeplist')	(`renamelist')		
		}
		else {
			clear
			foreach sheet in ELA MATH {
				tempfile `sheet'
				import excel using "${datapath_raw_statescore}/colorado/`fy'/ela.xlsx", clear case(lower) sheet(`sheet') cellrange(A5) firstrow
				keep if level == "DISTRICT"
				drop level schoolcode schoolname 
				save ``sheet'', replace
			}
			clear
			foreach sheet in ELA MATH {
				append using ``sheet''
			}
			keep districtcode districtname content test numberoftotalrecords numberofvalidscores numberofnoscores participationrate meanscalescore numberdidnotyetmeetexpectat didnotyetmeetexpectations numberpartiallymetexpectation partiallymetexpectations numberapproachedexpectations approachedexpectations numbermetexpectations metexpectations numberexceededexpectations exceededexpectations numbermetorexceededexpectati metorexceededexpectations
			rename (districtcode districtname content test) (district_id district_name subject grade)
			rename (numberoftotalrecords numberofvalidscores numberofnoscores participationrate meanscalescore numberdidnotyetmeetexpectat didnotyetmeetexpectations numberpartiallymetexpectation partiallymetexpectations numberapproachedexpectations approachedexpectations numbermetexpectations metexpectations numberexceededexpectations exceededexpectations numbermetorexceededexpectati metorexceededexpectations) /// 
			(n_tested n_scored n_noscore participation mean n_below cts_pass_below n_partially cts_pass_partially n_approaching cts_pass_approaching n_at cts_pass_proficient n_above cts_pass_advanced n_pass pass)
		}
		
		gen year = `fy'
		save ``fy'', replace
	}
	clear
	foreach fy in 2016 2017 2018 2019 2021 {
		append using ``fy''
	}
	gen state = "CO"
	
	
	destring pass cts* , replace force
	
	keep if strpos(grade, "ELA") > 0 | strpos(grade, "English") > 0 | strpos(grade, "Math") > 0 | inlist(grade, "03", "04", "05", "06", "07", "08")
	drop if strpos(subject, "Spanish") > 0
	replace subject = "ela" if inlist(subject, "ELA", "English Language Arts")
	replace subject = "math" if inlist(subject, "Math", "Mathematics")
	replace grade = lower(grade)
	destring grade, replace i(math mathematics english language arts grade)
	destring district_id, replace
	tostring district_id, replace
	destring participation, i(* -) replace
	destring n_scored, i("<" "*" "," "x" "-") replace
	save "${datapath_clean}/colorado_scores", replace
end

program clean_connecticut
	foreach fy in 2016 2017 2018 2019 2021 {
		di `fy'
		
			tempfile `sheet'_`fy'
			if `fy' == 2021 {
				local start A6
				import excel using "${datapath_raw_statescore}/connecticut/`fy'/smarterbalanced.xlsx", clear case(lower) sheet(District) cellrange(`start') firstrow
				rename (lm learningmodellm reportingdistrictcode reportingdistrictname subgroupcategory subgroup totalnumberofstudents pcnt_part_ela21_inpersontest ///
				  pcnt_part_ela21_remotetest pcnt_part_math21_inpersontest pcnt_part_math21_remotetest n_ela21_inpersontest_scored pcnt_ela21_inpersontest_pl34 /// 
				  mean_ela21_inpersontest_ss n_math21_inpersontest_scored pcnt_math21_inpersontest_pl34 mean_math21_inpersontest_ss n_ela21_remotetest_scored /// 
				  pcnt_ela21_remotetest_pl34 mean_ela21_remotetest_ss n_math21_remotetest_scored pcnt_math21_remotetest_pl34 mean_math21_remotetest_ss) ///
				  (lm_num learningmodel district_id district_name subgroup_category subgroup n_students participation_ela_inperson participation_ela_remote ///
				  participation_math_inperson participation_math_remote n_scored_ela_inperson pass_ela_inperson mean_ela_inperson n_scored_math_inperson pass_math_inperson ///
				  mean_math_inperson n_scored_ela_remote pass_ela_remote mean_ela_remote n_scored_math_remote pass_math_remote mean_math_remote)
				  destring participation_*, replace force
				  reshape long participation_ n_scored_ pass_ mean_, i(district_id subgroup grade lm_num) j(test_mode) string 
				  rename (participation_ n_scored_ pass_ mean_) (participation n_scored pass mean)
				  gen test = substr(test_mode, 1, strpos(test_mode, "_")-1)
				  gen mode = substr(test_mode, strpos(test_mode, "_")+1, .)
				  drop test_mode
				  gen in_person_test = mode == "inperson"
				  gen remote_test = mode == "remote"
				  destring mean pass, replace force
				  rename mean mean_score
				  destring n_scored, i("<" "*" "," "x") replace	
				  replace pass = pass * 100 if pass < 1
				  replace participation = participation * 100 
	
					collapse (mean) pass participation mean_score [aw = n_scored], by(grade district_name district_id subgroup test)
				
			}
			else {
				import delimited "${datapath_raw_statescore}/connecticut/`fy'/smarterbalanced.csv", clear case(lower) varnames(5)
				rename (count v10-v18 averagevss) (n_below below n_approaching approaching n_at at n_above above n_pass pass mean_score)
				rename (below approaching at above) (cts_pass_below cts_pass_approaching cts_pass_proficient cts_pass_advanced)
				rename (district districtcode grade subject totalnumberofstudents totalnumbertested smarterbalancedparticipationrate totalnumberwithscoredtests) ///
				  (district_name district_id grade test n_students n_tested participation n_scored) 
				destring pass cts* mean_score, replace force
				destring n_scored, i("<" "*" "," "x") replace	
				replace pass = pass * 100 if pass < 1
				foreach level in below approaching proficient advanced {
					replace cts_pass_`level' = cts_pass_`level' if cts_pass_`level' < 1
				}
			}
			gen test_type = "smarterbalanced"
			gen year = `fy'
			destring grade participation, replace force
			save ``sheet'_`fy'', replace
		
	}
	clear 
	foreach fy in 2016 2017 2018 2019 2021 {
		
			append using ``sheet'_`fy''
		
	}
	gen state = "CT"
	replace test = lower(test)
	drop if subgroup != "ALL" & year == 2021
	rename test subject
	replace district_id = subinstr(district_id, "=", "", .)
	replace district_id = subinstr(district_id, char(34), "", .)
	destring district_id, replace
	tostring district_id, replace
	save "${datapath_clean}/connecticut_scores", replace
end

program clean_massachusetts
	foreach year in 2017 2018 2019 2021 {
		tempfile `year'
		import excel "${datapath_raw_statescore}/massachusetts/`year'/MA_`year'_NextGenMCAS_Grades3-8.xlsx", clear case(lower) sheet("Next Generation MCAS Achievemen") cellrange(A2) firstrow
		keep a b c e n o g i k m
		if `year' != 2021 {
			drop o
		}
		rename (a b c e n) (district_name district_id subject pass n_scored)
		rename (g i k m) (cts_pass_advanced cts_pass_proficient cts_pass_approaching cts_pass_below)
		destring district_id n_scored cts*, i(",") replace
		replace subject = lower(subject)
		keep if inlist(subject, "ela", "math")
		cap rename o participation
		cap destring participation, replace
		gen year = `year'
		isid district_id subject 
		save ``year'', replace
	}
	clear
	foreach year in 2017 2018 2019 2021 {
		append using ``year''
	}
	gen state = "MA"
	tostring district_id, replace
	save "${datapath_clean}/massachusetts_scores", replace
end

program clean_minnesota
	foreach year in 2016 2017 2018 2019 2021 {
		foreach subject in ela math {
			if !inlist(`year', 2019, 2021) local sheet "Public School Districts"
			else local sheet "District"
			tempfile `subject'_`year'
			if `year' != 2021 import excel "${datapath_raw_statescore}/minnesota/`year'/`subject'.xlsx", clear case(lower) sheet(`sheet') firstrow
			else import excel "${datapath_raw_statescore}/minnesota/`year'/`subject'.xlsx", clear case(lower) sheet(`sheet') cellrange(A2) firstrow
			cap rename groupcategory reportcategory 
			cap rename totaltested counttested
			keep if reportcategory == "All Categories"
			replace subject = "`subject'"
			gen prefix = ""
			tostring districttype districtnumber, replace
			gen dist_num = districtnumber
			gen length = strlen(districtnumber)
			replace districtnumber = "0" + districtnumber if length == 3
			replace districtnumber = "0" + "0" + districtnumber if length == 2
			replace districtnumber = "0" + "0" + "0" + districtnumber if length == 1
			replace districtnumber = prefix + districttype + districtnumber + "000000"
			destring percentlevel* count* grade, replace i("N/A")
			gen pass = percentlevelm + percentlevele
			rename (percentleveld percentlevelp percentlevelm percentlevele) (cts_pass_below cts_pass_approaching cts_pass_proficient cts_pass_advanced)
			if inlist(`year', 2019, 2021) {
				replace pass = pass * 100
				foreach var in cts_pass_below cts_pass_approaching cts_pass_proficient cts_pass_advanced {
					replace `var' = `var' * 100
				}
			}
			gen n_scored = countleveld + countlevelp + countlevelm + countlevele
			cap gen countnotattempted = 0
			cap replace countnotattempted = countnotattempted + countextenuatingcircumstances + bbs
			replace countnotattempted = countnotattempted + countabsent + countinvalid + countmedicalexempt + countnotcomplete + countrefused
			gen n_refused = countnotattempted 
			gen participation = (n_scored / (n_scored + n_refused) ) * 100 
			rename (districtnumber districtname counttested) (district_id district_name n_tested)
			keep grade subject district_name district_id pass n_tested n_scored districttype dist_num participation cts*
			isid grade subject district_name district_id
			replace district_name = lower(district_name)
			gen year = `year'
			save ``subject'_`year'', replace
		}
	}
	clear
	foreach year in 2016 2017 2018 2019 2021 {
		foreach subject in ela math {
			append using ``subject'_`year''
		}
	} 
	gen state = "MN"
	tostring district_id, replace
	save "${datapath_clean}/minnesota_scores", replace
	clear
	import excel "${datapath_raw_statescore}/minnesota/mn_participation.xlsx", clear case(lower) firstrow
	keep if studentgroup == "All Students"

	destring grade, replace force
	keep if inrange(grade, 3, 8)
	destring numerator denominator, replace i(C T S R)
	gen participation = (numerator / denominator) * 100
	gen prefix = ""
	tostring districttype districtnumber, replace
	gen dist_num = districtnumber
	gen length = strlen(districtnumber)
	replace districtnumber = "0" + districtnumber if length == 3
	replace districtnumber = "0" + "0" + districtnumber if length == 2
	replace districtnumber = "0" + "0" + "0" + districtnumber if length == 1
	replace districtnumber = prefix + districttype + districtnumber + "000000"
	replace subject = "ela" if subject == "R"
	replace subject = "math" if subject == "M"
	rename districtnumber district_id
	rename fiscalyear year
	keep subject grade district_id participation year districtname
	rename participation participation_new
	merge 1:1 grade subject district_id year using "${datapath_clean}/minnesota_scores", assert(1 2 3) keep(2 3) nogen
	replace participation = participation_new if !mi(participation_new)
	drop participation_new
	destring district_id, replace
	tostring district_id, replace  format(%14.0g)
	save "${datapath_clean}/minnesota_scores", replace 
end

program clean_mississippi
	tempfile test_data_Mississippi
	tempfile test_data_intermed
	tempfile xtemp
	
	foreach subject in ELA Math {
		tempfile test_data_`subject'
		global Math_cap MATH
		global ELA_cap ELA

		foreach year in 2016 2017 2018 2019 2021 {
			tempfile data_`year'
			clear 
			save `xtemp', emptyok replace
			clear
			foreach num in 3 4 5 6  7 8  {
				clear
				if `year'<2019 {
					import excel using "${datapath_raw_statescore}/mississippi/MS_MAAP_`year'.xlsx", sheet("G`num'`subject'_Sch") firstrow
				}
				if `year'>=2019 {
					import excel using "${datapath_raw_statescore}/mississippi/MS_MAAP_`year'.xlsx", sheet("G`num' $`subject'_cap") firstrow
				}
				quietly destring, replace ignore(*)
				rename Grade`num' Location
				drop if Location==""
				gen pass = Level3PCT+Level4PCT+Level5PCT
				rename Level1PCT cts_pass_below
				rename Level2PCT cts_pass_approaching
				rename Level3PCT cts_pass_passing
				rename Level4PCT cts_pass_proficient
				rename Level5PCT cts_pass_advanced
				gen grade = `num'
				foreach var of varlist cts* {
					replace `var'=`var'*100
				}
				keep pass Location TestTakers cts_* grade
				append using `xtemp'
	 			save `xtemp', replace
			}
			gen year = `year'
			gen subject = "`subject'"
			save `data_`year'', replace
		}		

		use `data_2016', clear
		foreach year in 2017 2018 2019 2021 {
			append using `data_`year''
		}
		save `test_data_`subject''
	}
	use `test_data_ELA', clear
	append using `test_data_Math'
	sort Location subject year
	save `test_data_Mississippi', replace
	clear
	import excel using "${datapath_raw_statescore}/mississippi/MS_MAAP_2021.xlsx", sheet("Participation ELA") firstrow
	rename DistrictSchool Location
	destring ParticipationRate, replace force
	rename ParticipationRate participation
	keep Location participation Sort
	gen year =2021
	gen subject = "ELA"
	save `xtemp', replace
	clear
	import excel using "${datapath_raw_statescore}/mississippi/MS_MAAP_2021.xlsx", sheet("Participation MATH") firstrow
	rename DistrictSchool Location
	destring ParticipationRate, replace force 
	rename ParticipationRate participation 
	
	keep Location participation Location
	gen year =2021
	gen subject = "Math"
	append using `xtemp'
	drop if Location==""
	collapse (mean) participation, by( Location subject year)
		
	sort Location subject year

	merge 1:m Location subject year	using `test_data_Mississippi'
	replace participation = 1 if  year<2021

	sort Location
	gen DistrictName=lower(Location)
	drop _m
	drop if DistrictName=="leflore legacy academy"
	drop if DistrictName=="reimagine prep"
	replace DistrictName=subinword(DistrictName, "co", "county", .)
	replace DistrictName="baldwyn public school district" if DistrictName=="baldwyn school district"
	replace DistrictName="bay st. louis-waveland school district" if DistrictName=="bay st louis waveland school district"
	replace DistrictName="covington county school district" if DistrictName=="covington county schools"
	replace DistrictName="east jasper school district" if DistrictName=="east jasper consolidated sch district"
	replace DistrictName="east jasper school district" if DistrictName=="east jasper consolidated school district"
	replace DistrictName="east tallahatchie school district" if DistrictName=="east tallahatchie consolidated sch district"
	replace DistrictName="east tallahatchie school district" if DistrictName=="east tallahatchie consolidated school district"
	replace DistrictName="east tallahatchie school district" if DistrictName=="east tallahatchie consol sch district"
	replace DistrictName="forrest county ahs" if DistrictName=="forrest county ag high school"
	replace DistrictName="coahoma ahs" if DistrictName=="coahoma ag high school"
	replace DistrictName="greenville public school district" if DistrictName=="greenville public schools"
	replace DistrictName="greenwood leflore consolidated school district" if DistrictName=="greenwood-leflore consolidated sd"
	replace DistrictName="gulfport separate school district" if DistrictName=="gulfport school district"
	replace DistrictName="hattiesburg public school district" if DistrictName=="hattiesburg public schooldistrict"
	replace DistrictName="holmes county consolidated school district" if DistrictName=="holmes consolidate school district"
	replace DistrictName="houston school district" if DistrictName=="houston  school district"
	replace DistrictName="humphreys county school district (achievement school district)" if DistrictName=="humphreys county school district"
	replace DistrictName="midtown public charter" if DistrictName=="midtown public charter school"
	replace DistrictName="ms school of the arts" if DistrictName=="mississippi school for the arts"
	replace DistrictName="moss point school district" if DistrictName=="moss point separate school district"
	replace DistrictName="north panola school district" if DistrictName=="north panola schools"
	replace DistrictName="okolona municipal separate school district" if DistrictName=="okolona separate school district"
	replace DistrictName="pontotoc city school district" if DistrictName=="pontotoc city schools"
	replace DistrictName="pascagoula-gautier school district" if DistrictName=="pascagoula gautier school district"
	replace DistrictName="poplarville school district" if DistrictName=="poplarville separate school district"
	replace DistrictName="republic - joel smilow collegiate" if DistrictName=="joel e. smilow collegiate"
	replace DistrictName="republic - smilow prep" if DistrictName=="smilow prep"
	replace DistrictName="starkville-oktibbeha consolidated school district" if DistrictName=="starkville- oktibbeha consolidated school district"
	replace DistrictName="sunflower county consolidated school district" if DistrictName=="sunflower county consolidate school district"
	replace DistrictName="sunflower county consolidated school district" if DistrictName=="sunflower county consolidate sch district"
	replace DistrictName="tishomingo county school district" if DistrictName=="tishomingo county sp mun sch district"
	replace DistrictName="vicksburg-warren school district" if DistrictName=="vicksburg warren school district"
	replace DistrictName="west jasper school district" if DistrictName=="west jasper consolidated schools"
	replace DistrictName=subinword(DistrictName, "co", "county", .)


	sort DistrictName

	save `test_data_intermed', replace

	clear
	import excel using "${datapath_raw_statescore}/mississippi/Mississippi IDs.xlsx", sheet("MS Districts") firstrow

	replace DistrictName = lower(DistrictName)

	sort DistrictName

	merge 1:m DistrictName using `test_data_intermed'

	keep if _m==3
	gen district_id = StateAssignedDistrictID
	gen state="MS"
	rename DistrictName district_name
	
	keep district_name district_id state year subject participation pass district_id cts_* grade
	tostring district_id, replace 
	replace pass = pass*100
	replace participation = participation*100
	sort district_id
	replace subject = "math" if subject=="Math"
	replace subject = "ela" if subject=="ELA"
	save "${datapath_clean}/mississippi_scores", replace
	
end

program clean_ohio
    clear
	tempfile xtemp
	tempfile ytemp
	save `xtemp', emptyok replace
	save `ytemp', emptyok replace
	
    foreach year in 15 16 17 18 20 {
        local i = `year' + 1
        import excel "${datapath_raw_statescore}\ohio\OH_`year'-`i'_Achievement_District.xlsx", clear firstrow sheet(Performance_Indicators)
        if `year' == 15 | `year' == 16 {
             rename (Reading3rdGrade20`year'`i'ato Math3rdGrade20`year'`i'atora) (pass3ela pass3math)
            foreach grade in 4 5 6 7 8 {
                rename (Reading`grade'thGrade20`year'`i'ato Math`grade'thGrade20`year'`i'atora) (pass`grade'ela pass`grade'math)
            }
        }
        else if `year' == 17 {
            rename (rdGradeReading201718ato thGradeReading201718ato AC AL AR AX ) (pass3ela pass4ela pass5ela pass6ela pass7ela pass8ela)
            rename (rdGradeMath201718atora thGradeMath201718atora AF AO AU BA) (pass3math pass4math pass5math pass6math pass7math pass8math)
        }
        else if `year' == 18 {
            rename (rdGradeReading201819ato thGradeReading201819ato Y AH AN AT) (pass3ela pass4ela pass5ela pass6ela pass7ela pass8ela)
            rename (rdGradeMath201819atora thGradeMath201819atora AB AK AQ AW) (pass3math pass4math pass5math pass6math pass7math pass8math)
        }
        else if `year' == 20 {
            rename (rdGradeEnglishLanguageArts thGradeEnglishLanguageArts Y AH AN AT) (pass3ela pass4ela pass5ela pass6ela pass7ela pass8ela)
            rename (rdGradeMath20202021Percent thGradeMath20202021Percent AB AK AQ AW) (pass3math pass4math pass5math pass6math pass7math pass8math)
        }

        destring pass*, replace i("N C")
        egen passela=rowmean(pass*ela)
        egen passmath=rowmean(pass*math)
       
        gen year = 2000 + `i'
        destring DistrictIRN, replace force
        rename DistrictIRN district_id
        rename DistrictName district_name
        drop if district_id==.
        keep pass* district_id district_name year
        reshape long pass pass3 pass4 pass5 pass6 pass7 pass8, i(district_id district_name year) j(subject) string
        append using `xtemp'
        save `xtemp', replace
    }
    drop if district_name==""
    sort district_id year
    save `xtemp', replace 
    foreach year in 15 16 17 18 20 {
        local i=`year'+1
        import excel "${datapath_raw_statescore}\ohio\OH_`year'-`i'_Achievement_District.xlsx", clear firstrow sheet(Performance_Index)
        destring DistrictIRN PercentofStudentsNotTested, replace force
        rename DistrictIRN district_id
        rename DistrictName district_name
        drop if district_id==.
        gen year = 2000+`i'
        gen participation = 1-PercentofStudentsNotTested/100
        keep year participation district_id district_name 
        drop if district_name==""
        sort district_id year
        append using `ytemp'
        save `ytemp', replace
    }
    sort district_id year
    merge 1:m district_id year using `xtemp', nogen keep(3)
    gen state="OH" 
    tostring district_id, replace
    replace participation = participation * 100
    gen cts_pass_below = . 
    gen cts_pass_advanced=.
    save "${datapath_clean}/ohio_scores", replace
end

program clean_rhode_island
clear

tempfile xtemp
save `xtemp', emptyok replace

	foreach subject in English_Language_Arts_Literacy Mathematics {
	foreach year in 2017 2018 2020	{
		local i=(`year'+1)-2000
		import excel "${datapath_raw_statescore}\rhode_island\RICAS_-_`subject'_`year'-`i'_district_QuickReport.xlsx", clear case(lower) sheet(By_District_AndGrade) firstrow
		gen year = `i'
		gen subject = "`subject'"
		destring districtcode percentmeetingorexceedingexp percentpartiallymeetingexpect percentmeetingexpectations percentexceedingexpectations averagescalescore percenttested, force replace
		rename districtcode district_id
		keep district_id year grade subject districtname percentmeetingorexceedingexp percenttested percentmeetingorexceedingexp percentpartiallymeetingexpect percentmeetingexpectations percentexceedingexpectations averagescalescore percenttested

		append using `xtemp'
		save `xtemp', replace

	}
	}


	destring grade, replace
	rename districtname district_name
	rename percentmeetingorexceedingexp pass
	rename percenttested participation
	rename (percentpartiallymeetingexpect percentmeetingexpectations percentexceedingexpectations ) (cts_pass_below cts_pass_proficient cts_pass_advanced)
	drop if mi(district_id)
	tostring district_id, replace
	replace district_id = "0" + district_id if strlen(district_id) == 1
	gen state="RI"
	replace year = year + 2000
	replace subject="math" if subject=="Mathematics"
	replace subject="ela" if subject=="English_Language_Arts_Literacy"
	save "${datapath_clean}/rhode_island_scores", replace
end

program clean_virginia 
	foreach fy in 2016 2017 2018 2019 2021 {
		tempfile `fy'
		di `fy'
		if `fy' == 2021 {
			local sheet A3
		}
		else if `fy' == 2019 {
			local sheet A1
		} 
		else {
			local sheet A2
		}
		if `fy' != 2019 {
			import excel using "${datapath_raw_statescore}/virginia/`fy'/division.xlsx", clear case(lower) firstrow cellrange(`sheet')

		}
		else {
			import excel using "${datapath_raw_statescore}/virginia/`fy'/division.xlsx", clear case(lower) firstrow cellrange(`sheet') sheet("Division by Test")

		}
		if inlist(`fy', 2018, 2019, 2021) {
			local rate_vars i l
		}
		else if `fy' == 2017 {
			local rate_vars f i
			gen grade = substr(test, 4, 4) if strpos(test, "Grade") > 0 
			gen divnum = .
		}
		else {
			local rate_vars h k
			rename divisionname divname
			gen grade = substr(test, 4, 4) if strpos(test, "Gr") > 0 
		}
		keep divnum divname subject grade test `rate_vars'
		rename (divnum divname `rate_vars') (district_id district_name pass adv_pass)
		gen year = `fy'
		save ``fy'', replace
	}
	clear 
	foreach fy in 2016 2017 2018 2019 2021 {
		append using ``fy''
	}
	gen state = "VA"
	drop if inlist(grade, "Content Specific", "End of Course")
	replace grade = lower(grade)
	destring grade, replace i(e n h i m a s c w r g d)
	replace grade = -1 * grade if grade < 0 
	keep if inlist(subject, "English: Reading", "Mathematics")
	replace subject = "ela" if subject == "English: Reading"
	replace subject = "math" if subject == "Mathematics"
	destring pass adv_pass, replace force
	rename adv_pass cts_pass_advanced
	tostring district_id, replace
	replace district_name = lower(district_name)
	replace district_name = strtrim(district_name)
	save "${datapath_clean}/virginia_scores", replace
	tempfile xwalk
	keep if year == 2021
	drop if mi(district_name) | mi(district_id)
	drop if district_id == "."
	duplicates drop district_name district_id, force 
	rename district_id district_id_new
	keep district_name district_id_new
	save `xwalk', replace
	merge 1:m district_name using "${datapath_clean}/virginia_scores", keep(2 3) 
	replace district_name = district_name + " city" if _merge == 2
	drop district_id_new
	drop _merge
	merge m:1 district_name using `xwalk', assert(3) keep(3) nogen
	replace district_id = district_id_new if mi(district_id) | district_id == "."
	drop district_id_new
	assert !mi(district_id)
	drop if mi(grade)
	save "${datapath_clean}/virginia_scores", replace
	
	import excel using "${datapath_raw_statescore}/virginia/VA_participation.xlsx", clear case(lower) firstrow sheet("Sheet1")
	keep if inlist(participationtype, "English Participation", "Math Participation")
	gen subject = "ela" if participationtype == "English Participation"
	replace subject = "math" if participationtype == "Math Participation"
	assert !mi(subject)
	rename divnum district_id
	rename accountabilityyear year
	gen participation = 100 * (numstudentstested/numstudents)
	keep district_id participation subject year
	tostring district_id, replace
	merge 1:m subject district_id year using "${datapath_clean}/virginia_scores", assert(1 3) keep(3) nogen 
	save "${datapath_clean}/virginia_scores", replace
end
 
program clean_west_virginia 
	tempfile xtemp
	foreach year in 16 17 18 19 21 {
		tempfile `year'
		import excel "${datapath_raw_statescore}/west virginia/WV_AssessmentResults_SY15-to-SY21.xlsx", clear case(lower) sheet("SY`year' School & District")
		rename (A B C E) (district_id district_name school population) 
		rename (K P U Z AE AJ) (pass3math pass4math pass5math pass6math pass7math pass8math)
		rename (AY BD BI BN BS BX) (pass3ela pass4ela pass5ela pass6ela pass7ela pass8ela)
		rename (AP AQ AR AS AT) (cts_pass_belowmath cts_pass_approachingmath cts_pass_proficientmath cts_pass_advancedmath passmath)
		rename (CD CE CF CG CH) (cts_pass_belowela cts_pass_approachingela cts_pass_proficientela cts_pass_advancedela passela)
	

		replace population = lower(population)
		keep if population == "total population"
		keep if school == "999"
		keep district_id district_name pass* cts*
		destring pass*, replace i(*)
		destring cts*, replace i(*)
		reshape long pass pass3 pass4 pass5 pass6 pass7 pass8 cts_pass_below cts_pass_approaching cts_pass_proficient cts_pass_advanced, i(district_id) j(subject) string

		gen year = 2000 + `year'
		destring district_id, replace
		tostring district_id, replace
	
		save ``year'', replace
	}
	clear
	foreach year in 16 17 18 19 21 {
		append using ``year''
	}
	gen state = "WV"
	save "${datapath_clean}/west_virginia_scores", replace

		tempfile 2019 2018 2017 2016
		import excel "${datapath_raw_statescore}/west virginia/WV_AssessmentResults_SY15-to-SY21.xlsx", clear case(lower) sheet("# Students Tested") 
		rename (A C E) (district_id school population)
		replace population = lower(population)
		keep if population == "total population"
		keep if school == "999"
		drop population school
		destring district_id, replace
		tostring district_id, replace
		
		foreach year in 2019 2018 2017 2016 {
			preserve
			if `year'==2019 {
			
			rename (P Q) (n_scoredmath n_scoredela)
			}
			if `year'==2018 {
				rename (M N) (n_scoredmath n_scoredela)
			}
			if `year'==2017 {
				rename (K L) (n_scoredmath n_scoredela)
			}
			if `year'==2016 {
				rename (I J) (n_scoredmath n_scoredela)
			}
		destring n_scoredmath n_scoredela, replace i(*)
		reshape long n_scored, i(district_id) j(subject) string
		gen year = `year'
		keep district_id n_scored subject year
		save ``year'', replace
			restore
		}
		clear
		foreach year in 2019 2018 2017 2016 {
			append using ``year''
		}
		save `xtemp', replace
		
		
		import excel "${datapath_raw_statescore}/west virginia/WV_AssessmentResults_SY15-to-SY21.xlsx", clear case(lower) sheet("# Students Tested 2021") 
		keep A C E G H 
		rename (A C E G H) (district_id school population n_scored_math n_scored_ela)
		replace population = lower(population)
		keep if population == "total population"
		keep if school == "999"
		destring n_scored_math n_scored_ela, replace i(*)
		reshape long n_scored_, i(district_id) j(subject) string
		rename n_scored_ n_scored
		gen year = 2021
		destring district_id, replace
		tostring district_id, replace
		keep district_id n_scored subject year
		append using `xtemp'
		merge 1:1 district_id year subject using "${datapath_clean}/west_virginia_scores", assert(1 2 3) keep(2 3) nogen
		save "${datapath_clean}/west_virginia_scores", replace
end

program clean_wisconsin

	clear
	
	tempfile xtemp
	save `xtemp', emptyok replace
	
	foreach year in 15 16 17 18 20 {
	
		local i=`year'+1
		insheet using "${datapath_raw_statescore}/wisconsin/forward_certified_20`year'-`i'.csv", clear 

		keep if school_name=="[Districtwide]"
		keep if grade_level>=3 & grade_level<=8
		rename test_subject subject
	
		replace subject = "math" if subject=="Mathematics"
		replace subject = "ela" if subject=="ELA"
	
		keep if subject=="math" | subject=="ela"
	
		destring student_count group_count, replace force
		
		gen below = student_count if test_result == "Below Basic"
		gen approaching = student_count if test_result == "Basic"
		gen proficient = student_count if test_result == "Proficient"
		gen advanced = student_count if test_result == "Advanced"
		gen passing = student_count if test_result=="Proficient" | test_result=="Advanced"
		gen participate = student_count if test_result~="No Test"

		rename district_code district_id
	
		collapse (sum) passing participate below approaching proficient advanced student_count, by(district_id district_name subject grade_level)
	
	gen pass = passing/student_count
	foreach var in below approaching proficient advanced {
		gen cts_pass_`var' = (`var' / student_count) * 100
	}
	gen participation = participate/student_count
	gen year = 2000+`i'
	gen state="WI"	
	rename grade_level grade
	keep pass participation district_id district_name subject year state grade cts*
	replace pass = pass * 100
	replace participation = participation * 100
	tostring district_id, replace
	append using `xtemp'
	save `xtemp', replace
}


		save "${datapath_clean}/wisconsin_scores", replace
end

program clean_wyoming 
	import excel "${datapath_raw_statescore}/wyoming/WY_PAWSPublicDistrictLevel.xlsx", clear case(lower) sheet("PAWSPublicDistrictLevel") cellrange(A7) firstrow
	gen year = substr(schoolyear, strlen(schoolyear)-1,.)
	gen n_tested = substr(numberofstudentstested, 1, strpos(numberofstudentstested,"-")-1)
	destring year grade perc* n_tested participationrate, i("<" "=" "%" ">") replace 
	 
	keep if year >=16 & !mi(year)
	replace year = year + 2000
	replace subject = lower(subject)
	replace subject = "ela" if inlist(subject, "english language arts (ela)", "reading")
	keep if inlist(subject, "ela", "math")
	rename (districtname percentproficientandadvanced) (district_name pass)
	rename participationrate participation
	rename (percentbelowbasic percentbasic percentproficient percentadvanced) (cts_pass_below cts_pass_approaching cts_pass_proficient cts_pass_advanced)
	keep district_name year grade subject pass n_tested participation cts*
	isid district_name subject grade year
	gen state = "WY"
	merge m:1 district_name using "${datapath_raw_statescore}/wyoming/WY_ID.dta", nogen keep(3)
	* drop WY prior to 2017-2018 because of testing change
	drop if state == "WY" & year < 2018
	
	save "${datapath_clean}/wyoming_scores", replace
end 

program grade_level
	clear
	foreach state in $state_clean_list {
		di as error "`state'"
		use "${datapath_clean}/`state'_scores", clear
		capture confirm variable grade
		if _rc {
			save "${datapath_clean}/`state'_scores_re", replace
		}
		
		else  {
		use "${datapath_clean}/`state'_scores", clear
		cap gen n_scored=.
		cap	gen participation=.
		gen cts_dum=0
		
		keep district_name district_id grade pass state subject year n_scored participation cts_*
	
		keep if inrange(grade, 3, 8)
		bysort district_id year subject: egen all_participation=mean(participation)
		bysort district_id year subject: egen all_pass=mean(pass)
		bysort district_id year subject: egen all_n_scored=sum(n_scored)
		drop n_scored
		
		foreach v of varlist cts_* {
			bysort district_id year subject: egen all_`v'=mean(`v')
		}
		drop cts_*
		duplicates tag district_id year grade subject, g(tag)
		drop if tag==1 & pass==.
		drop tag
		isid district_id year grade subject
		reshape wide pass participation, i(district_id year subject) j(grade)
		rename all_* *
		
		save "${datapath_clean}/`state'_scores_re", replace
		}
	}
	
	
end

program cleanup_cts 

	use "$learning_model", clear
	rename StateAbbrev state
	drop if Charter=="Yes"
	foreach state in $state_clean_list {
		di as error "`state'"
		tempfile `state'_lm
		preserve 
			keep if state == "${`state'_abbrev}"
			rename state StateAbbrev
			
				drop if mi(LearningModel)
				gen period_length = PeriodEndDate - PeriodStartDate + 1
				
				gen holiday=inrange(date("12/24/2020", "MDY", 2050), PeriodStartDate, PeriodEndDate)
				replace holiday=holiday+1 if inrange(date("12/31/2020", "MDY", 2050), PeriodStartDate, PeriodEndDate)
				replace holiday=holiday+1 if inrange(date("11/26/2020", "MDY", 2050), PeriodStartDate, PeriodEndDate)
				replace period_length=period_length-(holiday*7)
				replace period_length=0 if period_length<0
				
				gen inperson = LearningModel == "In-person"
				gen virtual = LearningModel == "Virtual"
				gen hybrid = LearningModel == "Hybrid"
				gen total_student_days = period_length*EnrollmentTotal
				foreach var in inperson virtual hybrid { 
					gen `var'_student_days = period_length * `var' * EnrollmentTotal
				}
		
		collapse (sum)  *days (firstnm) DistrictName NCESDistrictID, by(StateAssignedDistrictID)
		rename StateAssignedDistrictID district_id
		
		foreach var in inperson virtual hybrid { 
					gen share_`var' = `var'_student_days/total_student_days
				}
		gen not_inperson = share_virtual + share_hybrid
		
		
		duplicates drop district_id, force
		merge 1:m district_id using "${datapath_clean}/`state'_scores_re", gen(merge_lm)
	
		cap replace district_name = lower(district_name)
		cap gen n_scored = .
		cap gen participation = .
		destring n_scored, i("<" "*" "," "x") replace
		save ``state'_lm', replace
		restore 
	}
	clear 
	
	foreach state in $state_clean_list {
		di "`state'"
		append using ``state'_lm', keep(state district_* subject NCESDistrictID pass* n_scored merge_lm year *days participat* share* cts*)
	}
	
	tab merge_lm
	keep if merge_lm == 3
	drop if mi(pass)
	capture drop cts_pass_approaching cts_pass_proficient cts_pass_partially cts_pass_passing cts_pass_accelerated
	save "${datapath_clean}/final_scores_cts", replace
			
end

program make_weights 
	use "$learning_model", clear
	rename NCESDistrictID leaid
	foreach state in $state_clean_list {
		di "`state'"
		tempfile `state'
		preserve 
			keep if StateAbbrev == "${`state'_abbrev}"
			if inlist("`state'",  "wisconsin", "arizona", "mississippi", "nevada", "rhode_island" ) {
				drop if mi(EnrollmentTotal)
				duplicates drop leaid StateAssignedSchoolID, force
				collapse (sum) EnrollmentTotal, by(leaid)
			}
			else {
				duplicates drop leaid, force
				collapse (sum) EnrollmentTotal, by(leaid)
			}
			gen state = "${`state'_abbrev}"
			save ``state'', replace
		restore 
	}
	clear
	foreach state in $state_clean_list {
		append using ``state''
	}
	save "${datapath_clean}/weights", replace
end

program clean_nces 
	use ${datapath_raw_other}/nces_school_2015_2020.dta, clear
	rename free_or_reduced_price_lunch lunch
	drop if year==2020
	replace year=2020 if year==2019
	replace lunch=. if lunch<0
	bysort leaid year (lunch) : gen missing_lunch = mi(lunch[1])
	collapse (sum) lunch (min) missing_lunch, by(leaid year)
	replace lunch=. if missing_lunch==1
	destring leaid, replace
	replace year=year+1
	save "${datapath_clean}/nces_2020", replace
	
	use ${datapath_raw_other}/nces_district_2015_2020.dta, clear
	keep leaid english_language_learners year enrollment
	destring leaid, replace
	rename english_language_learners ELL
	replace enrollment=. if enrollment<0
	rename enrollment ELL_enrollment
	replace ELL=. if ELL<0
	drop if year>=2019
	expand 2 if year==2018, g(dup)
	replace year=2020 if dup==1
	drop dup
	replace year=year+1
	merge 1:1 leaid year using "${datapath_clean}/nces_2020", assert(1 2 3) keep(1 2 3) nogen
	save "${datapath_clean}/nces_2020", replace
	
	use ${datapath_raw_other}/nces_district_grade_2015_2020.dta, clear
	destring leaid, replace
	replace year=year+1
	keep if race==99
	drop race
	preserve
	tempfile enroll
	keep if inrange(grade, 3, 8)
	replace enrollment=. if enrollment<0
	collapse (sum) enrollment, by(fips leaid year)
	rename enrollment participate_denom 
	save `enroll', replace
	restore
	
	tempfile west_virginia_nces
	keep if fips == 54
	keep if inrange(grade, 3, 8) | grade == 11
	replace enrollment=. if enrollment<0
	collapse (sum) enrollment, by(fips leaid year)
	rename enrollment participate_denom 
	save `west_virginia_nces', replace
	use `enroll', clear
	drop if fips == 54
	append using `west_virginia_nces'
	merge 1:1 leaid year using "${datapath_clean}/nces_2020", assert(1 2 3) keep(1 2 3) nogen
	save "${datapath_clean}/nces_2020", replace
	
	use ${datapath_raw_other}/nces_district_grade_2015_2020.dta, clear
	destring leaid, replace
	replace year=year+1
	keep if grade==99
	drop grade
	keep if inrange(race,1,3) | race==99
	replace enrollment=. if enrollment<0
	egen id=group(leaid year)
	reshape wide enrollment, i(id) j(race)
	rename enrollment1 white
	rename enrollment2 black
	rename enrollment3 hisp
	rename enrollment99 enroll_total
	merge 1:1 leaid year using "${datapath_clean}/nces_2020", assert(1 2 3) keep(1 2 3) nogen
	
	foreach var in black white hisp lunch {
		gen share_`var' = `var' / enroll_total
		replace share_`var' = 1 if share_`var' > 1 & !mi(share_`var')
	}
	gen share_other = 1 - (share_white + share_black + share_hisp)
	replace share_other = 0 if share_other < 0 
	replace share_other = 1 if share_other > 1 & !mi(share_other)
	replace share_lunch=. if missing_lunch==1
	replace missing_lunch=1 if share_lunch==.
	gen share_lunch_updated = share_lunch
	replace share_lunch_updated = 99 if share_lunch==.
	gen share_ELL=ELL/ELL_enrollment
	replace share_ELL = 1 if share_ELL > 1 & !mi(share_ELL)
	gen missing_ELL = share_ELL==.
	gen share_ELL_updated = share_ELL
	replace share_ELL_updated = 99 if share_ELL==.
	drop id
	
	save "${datapath_clean}/nces_2020", replace


end

program clean_case_data 
	import delimited "${datapath_raw_other}/covid_case_rates.csv", delim("|") clear
	isid leaid start_date end_date
	gen start_dt = date(start_date, "DMY")
	gen end_dt = date(end_date, "DMY")
	gen diff = start_dt - end_dt
	drop if start_dt <= td("01aug2020")
	gen month = month(start_dt)
	gen cases_aug = case_rate_per100k_zip if month == 8
	collapse (mean) case_rate_per100k_zip cases_aug (max) max_cases = case_rate_per100k_zip, by(leaid)
	save "${datapath_clean}/cases", replace
end

program clean_commuting_zones
	tempfile xtemp
	
	import excel "${datapath_raw_other}/commuting_zones.xls", clear case(lower) firstrow
	keep fips commutingzoneid2000
	sort fips
	save `xtemp', replace
	
	import excel "${datapath_raw_other}/District_NCES_Zip_Crosswalk.xlsx", clear case(lower) sheet(District_Zip_Crosswalk) firstrow
	rename ncesdistrictid leaid 
	rename countyfips fips
	keep leaid fips 
	sort fips
	merge m:1 fips using `xtemp', assert(1 2 3) keep(3) nogen
	rename commutingzoneid2000 commute_zone
	duplicates drop leaid, force
	destring leaid, replace force
	sort leaid 
	rename fips countyfips
	destring countyfips, replace
	save "${datapath_clean}/commutezone.dta", replace
	
end

program clean_trump_vote
	import delimited "${datapath_raw_other}/Vote_share_2020_data.csv", clear
	capture confirm numeric variable votes_gop
    if _rc == 1 {
		destring votes_gop, replace
    }	
	gen trump_votes = votes_gop
	capture confirm numeric variable votes_dem
    if _rc == 1 {
		destring votes_dem, replace
    }		
	gen biden_votes = votes_dem
	gen trump_vote_share = (trump_votes/total_votes) * 100
	gen biden_vote_share = (biden_votes/total_votes) * 100
	drop votes_dem votes_gop diff per_gop per_dem per_point_diff
	rename county_fips countyfips
	save "${datapath_clean}/Merged_Trump_Vote_Dataset_School_District.dta", replace
	
end

program clean_unemployment
	 import delimited "${datapath_raw_other}/county_unemployment.txt", clear
	 keep if year>2014
	 replace series_id=subinstr(series_id, " ", "",.)
	 gen series=substr(series_id, -1,.)
	 keep if series=="3"
	 gen countyfips=substr(series_id, 6, 5)
	 destring period, replace i("M")
	 replace year=year+1 if period>5
	 drop if period==13
	 keep if inrange(year, 2016, 2021)
	 destring value, replace i("-")
	 rename value unemployment
	 collapse (mean) unemployment, by(countyfips year)
	 destring countyfips, replace
	 save "${datapath_clean}/unemployment.dta", replace
end

program create_final_dataset 
	use "${datapath_clean}/final_scores_cts", clear
	drop if year <= 2015
	rename NCES leaid 
	merge m:1 leaid year using "${datapath_clean}/nces_2020", assert(1 2 3) keep(1 3) nogen

	replace participation = (n_scored / participate_denom) * 100 if mi(participation)
	replace participation = 100 if participation > 100 & !mi(participation)
	* assuming MA participating rates are 100 prior to 2021 since missing grade level enrollment in NCES
	replace participation = 100 if state == "MA" & year <= 2019

	merge m:1 leaid using "${datapath_clean}/weights",  assert(1 2 3) keep(3) keepusing(EnrollmentTotal) nogen
	merge m:1 leaid using "${datapath_clean}/cases", assert(1 2 3) keep(1 3) nogen
	merge m:1 leaid using "${datapath_clean}/commutezone", assert(1 2 3) keep(1 3) nogen	
	merge m:1 countyfips using "${datapath_clean}/Merged_Trump_Vote_Dataset_School_District", assert(1 2 3) keep(1 3) nogen keepusing(trump_vote_share biden_vote_share)
	merge m:1 countyfips year using "${datapath_clean}/unemployment.dta", assert(1 2 3) keep(1 3) nogen

	foreach var in pass pass3 pass4 pass5 pass6 pass7 pass8 cts_pass_below cts_pass_advanced {
	replace `var'=`var' / 100 
	}
	
	keep state district_id leaid cts_* unemployment year share* pass* subject EnrollmentTotal case_rate_per100k_zip cases_aug max_cases participation trump_vote_share biden_vote_share commute_zone missing* countyfips participate_denom
	drop cts_dum cts_pass_passing
	
	lab var state "state"
	lab var district_id "state assigned district id"
	lab var leaid "district id from the NCES"
	lab var cts_pass_below "share of students whose test performance is in the lowest score category as defined by states"
	lab var cts_pass_partially "share of students whose test performance is partially proficient as defined by states"
	lab var cts_pass_approaching "share of students whose tests performance is approaching proficiency as defined by states"
	lab var cts_pass_proficient "share of students whose test performance is proficient as defined by states"
	lab var cts_pass_advanced "share of students whose test performance is advanced as defined by states"
	lab var unemployment "county-level unemployment rates from the Bureau of Labor Statistics averaged over the school year"
	lab var year "year"
	lab var share_inperson "share of school days in-person during 2020-2021 school year calculated from the CSDH learning model data"
	lab var share_virtual "share of school days virtual during 2020-2021 school year calculated from the CSDH learning model data"
	lab var share_hybrid "share of school days hybrid during 2020-2021 school year calculated from the CSDH learning model data"
	lab var share_black "share of students who are Black calculated from NCES data"
	lab var share_white "share of students who are white calculated from NCES data"
	lab var share_hisp "share of students who are Hispanic calculated from NCES data"
	lab var share_other "share of students who are not white, Black, or Hispanic calculated from NCES data"
	lab var share_lunch "share of students who received free and reduced price lunch (FRPL) calculated from NCES data"
	lab var share_lunch_updated "share of students who received free and reduced price lunch (FRPL) calculated from NCES data, missing coded as 99"
	lab var share_ELL "share of students who are english language learners (ELL) calculated from NCES data"
	lab var share_ELL_updated "share of students who are english language learners (ELL) calculated from NCES data"
	lab var pass "average pass rate across grades weighted by enrollment"
	lab var pass3 "pass rate for 3rd grade"
	lab var pass4 "pass rate for 4th grade"
	lab var pass5 "pass rate for 5th grade"
	lab var pass6 "pass rate for 6th grade"
	lab var pass7 "pass rate for 7th grade"
	lab var pass8 "pass rate for 8th grade"
	lab var subject "test subject -- either ELA or math"
	lab var EnrollmentTotal "student enrollment counts from the NCES data"
	lab var case_rate_per100k_zip "average covid-19 cases per 100k across weeks"
	lab var cases_aug "covid-19 cases per 100k in august"
	lab var max_cases "maximum covid-19 cases per 100k across weeks"
	lab var participation "test participation rate"
	lab var trump_vote_share "republican vote share in 2020 presidential election" 
	lab var biden_vote_share "democrat vote share in 2020 presidential election" 
	lab var commute_zone "commuting zone"
	lab var missing_lunch "dummy for missing free and reduced price lunch data in NCES"
	lab var missing_ELL "dummy for missing ELL data in NCES"
	lab var countyfips "county fips code"
	lab var participate_denom "denominator used to calculate participation rate (Grades 3-8 enrollment counts)"

	save "${datapath_clean}/state_score_data", replace

end

main
