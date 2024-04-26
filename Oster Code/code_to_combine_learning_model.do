clear
cap log close
cap program drop _all

global state_files "../Data/Raw/learningmodel"
global output_file "../Data/Raw"

program append_data
	clear
	save xtemp, replace emptyok

	local School_state_list "Mississippi RhodeIsland Wisconsin" 

	local District_state_list "Colorado Connecticut Massachusetts Minnesota Ohio Virginia WestVirginia Wyoming" 
	
	foreach level in "District" "School" {
	
	foreach state of local `level'_state_list {
	
	di "`state'"
	
	import excel using "$state_files\\`state'_`level's_LearningModelData_Final.xlsx", firstrow
	
	capture confirm string variable TimePeriodStart
            if !_rc {
				gen PeriodStartDate =date(TimePeriodStart,"MDY",2050)

                }
			else {
				gen PeriodStartDate = TimePeriodStart

			}

	capture confirm string variable TimePeriodEnd
            if !_rc {
				gen PeriodEndDate =date(TimePeriodEnd,"MDY",2050)
                }
			else {
				gen PeriodEndDate = TimePeriodEnd
			}
	drop TimePeriodEnd TimePeriodStart

	capture confirm string variable NCESDistrictID
		if !_rc {
			destring NCESDistrictID, replace
		}

	capture confirm string variable NCESSchoolID
		if !_rc {
			destring NCESSchoolID, replace
		}
		
	format NCESSchoolID %14.0g
	format NCESDistrictID %12.0g
	foreach var in StateAssignedSchoolID StateAssignedDistrictID{
		capture confirm numeric variable `var'
			if !_rc {
				format `var' %16.0g
			}
	}

foreach var in SchoolName DistrictType SchoolType StateAssignedSchoolID  LearningModel LearningModelGrK5 LearningModelGr68 LearningModelGr912 LearningModelStateCat LearningModelStateCatGrK5 LearningModelStateCatGr68 LearningModelStateCatGr912 StateAssignedDistrictID {		
	capture confirm string variable `var'
		if _rc {
			tostring `var', replace usedisplayformat
		}		
	}
	
	

foreach var in SchoolName SchoolType StateAssignedSchoolID  LearningModel LearningModelGrK5 LearningModelGr68 LearningModelGr912 LearningModelStateCat LearningModelStateCatGrK5 LearningModelStateCatGr68 LearningModelStateCatGr912 {
		replace `var'="" if `var'=="."
}

foreach var in EnrollmentTotal EnrollmentInPerson EnrollmentHybrid EnrollmentVirtual StaffCount StaffCountInPerson {		
	capture confirm string variable `var'
		if !_rc {
			destring `var', i(",") replace
		}		
	}

drop if SchoolName=="" & DistrictName==""

	order StateName StateAbbrev DataLevel Charter SchoolName SchoolType NCESSchoolID StateAssignedSchoolID DistrictName DistrictType NCESDistrictID StateAssignedDistrictID TimePeriodInterval PeriodStartDate PeriodEndDate EnrollmentTotal LearningModel LearningModelGrK5 LearningModelGr68 LearningModelGr912 LearningModelStateCat LearningModelStateCatGrK5 LearningModelStateCatGr68 LearningModelStateCatGr912 EnrollmentInPerson EnrollmentHybrid EnrollmentVirtual StaffCount StaffCountInPerson
	
		
	append using xtemp
	save xtemp, replace
	clear	
	
}
	}

	use xtemp, clear
	replace LearningModel="In-person" if LearningModel=="In-Person"
	save "$output_file/schooling_mode_data.dta", replace

end

append_data





