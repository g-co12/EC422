clear
cd "C:\Users\Cletus\OneDrive\Desktop\EC 422\Project Data\168843-V1"

import excel "C:\Users\Cletus\Downloads\Ec 422 Project Test Data.xlsx", firstrow
save good_data, replace

use good_data, clear
gen primary_modality = "In Person" if share_inperson >= share_hybrid & share_inperson >= share_virtual
replace primary_modality = "Hybrid" if share_hybrid >= share_inperson & share_hybrid >= share_virtual
replace primary_modality = "Remote" if share_virtual >= share_inperson & share_virtual >= share_hybrid

tab state primary_modality
tab primary_modality year
	
*Number of districts using each type of learning
sort year
egen count_inperson = sum(primary_modality == "In Person"), by(year)
egen count_hybrid = sum(primary_modality == "Hybrid"), by(year)
egen count_virtual = sum(primary_modality == "Remote"), by(year)

*Side-by-side bar chart
graph bar count_inperson count_hybrid count_virtual, over(year) ///
    title("District Learning Modalities by Year") ///
	ytitle("Number of Districts")
    legend(label(1 "In-Person") label(2 "Hybrid") label(3 "Remote")) 
graph export modalities.png, as(png)	replace	



* Calculate pass rates for "In Person" modality for pre-pandemic and pandemic years
egen pass8_in_person_pre = mean(cond(primary_modality == "In Person" & year == 2019, pass8, .)), by(year)
egen pass8_in_person_pandemic = mean(cond(primary_modality == "In Person" & year == 2021, pass8, .)), by(year)

* Calculate the change in pass rates
gen pass_change = .

* Fill in the pass_change variable only if both pre-pandemic and pandemic pass rates are available
replace pass_change = pass8_in_person_pandemic - pass8_in_person_pre if !missing(pass8_in_person_pre) & !missing(pass8_in_person_pandemic)

* Generate a scatter plot for the change in pass rates
scatter pass_change year, ///
    title("Change in Pass Rates for In-Person Modality (2019 to 2021)") ///
    xtitle("Year") ytitle("Change in Pass Rate (%)")




*Regressions
*Eighth grade standardized test pass rates on covid 
eststo: regress pass8 share_inperson share_virtual share_hybrid if inrange(year, 2016, 2019)
eststo: regress pass8 share_inperson share_virtual share_hybrid if year == 2021

* Display results as a table
esttab, cells(b(star fmt(3)) se(fmt(3)))  /// 
    label nodepvars nonotes nomtitles title("Regression Results") 
esttab using "grade_eight_learn.txt", replace label noconstant b(3) se(3) r2(3) fragment

*Eighth grade pass rates on demographics and socioeconomic factors
eststo clear
eststo: regress pass8 share_lunch share_black share_white share_hisp share_other share_ELL_updated case_rate_per100k_zip if inrange(year, 2016, 2019)
eststo: regress pass8 share_lunch share_black share_white share_hisp share_other share_ELL_updated case_rate_per100k_zip if year == 2021

* Display results as a table
esttab, cells(b(star fmt(3)) se(fmt(3)))  /// 
    label nodepvars nonotes nomtitles title("Regression Results") 
esttab using "grade_eight_dem_reg.txt", replace label noconstant b(3) se(3) r2(3) fragment

