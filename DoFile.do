clear all
set more off
cap log close

// Get the current user's username
local os = c(os)
local user = c(username)

display "`user'"

// Set the working directory based on the username
if "`user'" == "dylan" {
    cd "C:\Users\dylan\Desktop\Dartmouth\ECON 20\Group Project"
}
else if "`user'" == "camerondailey" {
    cd "/Users/camerondailey/Desktop/ECON020/final project"
}
else if "`user'" == "arshdeepsingh" {
    cd "/Users/arshdeepsingh/Documents/ECON 20 Group Project"
}
else if "`user'" == "sebastianmanon" {
    cd "/Users/sebastianmanon/Documents/Econ 20"
}
else {
    display as error "User not recognized. Please update the do-file with your path."
}

// Open Data Sets Below And Clean Up 

use usa_00003, clear

drop if year == 1850
drop if year == 1860
drop if year == 1870
drop if year == 1880
drop if year == 1900
drop if year == 1910
drop if year == 1920
drop if year == 1930
drop if year == 1940
drop if year == 1950
drop if year == 1960
drop if year == 1970
drop if year == 1980
drop if year == 1990
drop if year == 2000
drop if year == 2023


drop sample
drop serial 
drop cbserial
drop gq 
drop pernum
drop citizen
drop race
drop educ
drop empstatd
drop if empstat == 0


// drop if N/A -> dont think we need to drop because ommitted anyway when empty
// drop if wkswork2 == 0

tab statefip, gen(state_dummy)

gen treated = (statefip == 8)
gen female = (sex==2)
tab raced, gen(race_dummy)
tab educd, gen(educ_dummy)
tab empstat, gen(emp_dummy)
gen lnwage = ln(incwage)
gen post = (year >= 2007)
gen treated_post = treated * post

// midpoint of usual wkswork
gen total_weeks = 7 if wkswork2 == 1
replace total_weeks = 20 if wkswork2 == 2
replace total_weeks = 33 if wkswork2 == 3
replace total_weeks = 43.5 if wkswork2 == 4
replace total_weeks = 48.5 if wkswork2 == 5
replace total_weeks = 51 if wkswork2 == 6


gen lnhrlywge = ln(incwage / (uhrswork * total_weeks))


// note, looked up syntax for exporting to excel
putexcel set summary.xlsx, replace
putexcel A1 = "State"
putexcel B1 = "Year Condition"
putexcel C1 = "Variable"
putexcel D1 = "Mean"
putexcel E1 = "SD"
putexcel F1 = "Min"
putexcel G1 = "Max"
local row = 2
foreach state in 8 49 {  
    foreach condition in 2007 2005 {
        foreach variable of varlist emp_dummy* age perwt sex educ_dummy* lnhrlywge race_dummy* {
            if `condition' == 2007 {
                quietly summarize `variable' if year >= 2007 & statefip == `state'
                local mean = r(mean)
                local sd = r(sd)
                local min = r(min)
                local max = r(max)
                local n = r(N)
                local cond_text "year >= 2007"
            }
            else {
                quietly summarize `variable' if year < 2007 & statefip == `state'
                local mean = r(mean)
                local sd = r(sd)
                local min = r(min)
                local max = r(max)
                local n = r(N)
                local cond_text "year < 2007"
            }
         
            if `n' > 0 {
                putexcel A`row' = `state'
                putexcel B`row' = "`cond_text'"
                putexcel C`row' = "`variable'"
                putexcel D`row' = `mean'
                putexcel E`row' = `sd'
                putexcel F`row' = `min'
                putexcel G`row' = `max'
                local row = `row' + 1
            }
        }
    }
}




// for employment 
gen employed = emp_dummy1
preserve
collapse (mean) employment_rate=employed [pweight=perwt], by(statefip year)
keep if statefip == 8 | statefip == 49
gen state_name = "colorado" if statefip == 8
replace state_name = "utah" if statefip == 49
twoway (connected employment_rate year if statefip == 8) (connected employment_rate year if statefip == 49), xline(2007, lpattern(dash) lcolor(red)) xlabel(2003(1)2010) ylabel(0.65(0.05)0.8) ytitle("Employment Rate") xtitle("Year") title("Employment Trends in Colorado (Treat) vs Utah (Control)") subtitle("Vertical line indicates policy change in 2007") legend(order(1 "Colorado (Treat)" 2 "Utah (Control)"))
graph export "employment_trends.png", replace
restore

// for lnhrlywge
preserve
collapse (mean) mean_lnhrlywge=lnhrlywge [pweight=perwt], by(statefip year)
keep if statefip == 8 | statefip == 49
gen state_name = "Colorado" if statefip == 8
replace state_name = "Utah" if statefip == 49
twoway (connected mean_lnhrlywge year if statefip == 8) (connected mean_lnhrlywge year if statefip == 49), xline(2007, lpattern(dash) lcolor(red)) xlabel(2003(1)2010) ytitle("Avg Log Hrly Wage") xtitle("Year") title("Log Hrly Wage Trends in Colorado (Treat) vs Utah (Control)") subtitle("Vertical line indicates policy change in 2007") legend(order(1 "Colorado (Treat)" 2 "Utah (Control)"))
graph export "log_wage_trends.png", replace
restore

// Basic DiD regression
reg employed treated post treated_post, robust
outreg2 using employment_results_np.doc, replace ctitle(Basic DiD) keep(treated post treated_post) addtext(Year FE, No, Controls, No) title(Effect of Colorado Policy Change on Employment (No Perwt))
reg employed treated post treated_post [pweight=perwt], robust
outreg2 using employment_results.doc, replace ctitle(Basic DiD) keep(treated post treated_post) addtext(Year FE, No, Controls, No) title(Effect of Colorado Policy Change on Employment)

// DiD with fixed effects
reg employed age i.sex i.educd i.raced treated post treated_post, robust
outreg2 using employment_results_np.doc, append ctitle(With FE) keep(treated treated_post) addtext(Year FE, No, Controls, Yes)
reg employed age i.sex i.educd i.raced treated post treated_post [pweight=perwt], robust
outreg2 using employment_results.doc, append ctitle(With FE) keep(treated treated_post) addtext(Year FE, No, Controls, Yes)

// DiD with year fixed effects
reg employed age i.sex i.educd i.raced i.year treated treated_post, robust
outreg2 using employment_results_np.doc, append ctitle(With FE) keep(treated treated_post) addtext(Year FE, Yes, Controls, Yes)
reg employed age i.sex i.educd i.raced i.year treated treated_post [pweight=perwt], robust
outreg2 using employment_results.doc, append ctitle(With FE) keep(treated treated_post) addtext(Year FE, Yes, Controls, Yes)

// Income Basic DiD regression
reg lnhrlywge treated post treated_post, robust
outreg2 using lnwage_results_np.doc, replace ctitle(Basic DiD) keep(treated post treated_post) addtext(Year FE, No, Controls, No) title(Effect of Colorado Policy Change on Hourly Wage (No Perwt))
reg lnhrlywge treated post treated_post [pweight=perwt], robust
outreg2 using lnwage_results.doc, replace ctitle(Basic DiD) keep(treated post treated_post) addtext(Year FE, No, Controls, No) title(Effect of Colorado Policy Change on Hourly Wage)

// Income DiD with fixed effects
reg lnhrlywge age i.sex i.educd i.raced treated post treated_post, robust
outreg2 using lnwage_results_np.doc, append ctitle(With FE) keep(treated treated_post) addtext(Year FE, No, Controls, Yes)
reg lnhrlywge age i.sex i.educd i.raced i.statefip i.year treated treated_post [pweight=perwt], robust
outreg2 using lnwage_results.doc, append ctitle(With FE) keep(treated treated_post) addtext(Year FE, No, Controls, Yes)

// Income DiD with year fixed effects
reg lnhrlywge age i.sex i.educd i.raced treated post treated_post, robust
outreg2 using lnwage_results_np.doc, append ctitle(With FE) keep(treated treated_post) addtext(Year FE, Yes, Controls, Yes)
reg lnhrlywge age i.sex i.educd i.raced i.statefip i.year treated treated_post [pweight=perwt], robust
outreg2 using lnwage_results.doc, append ctitle(With FE) keep(treated treated_post) addtext(Year FE, Yes, Controls, Yes)

gen young = (age <= 25)
gen young_treated = young * treated
gen young_post = young * post
gen young_post_treated = young * post * treated

// Long regression with DDD
reg employed age i.sex i.educd i.raced i.year treated treated_post young_treated young_post young_post_treated, robust
outreg2 using employment_results_np.doc, append ctitle(With FE) keep(treated treated_post young young_post young_treated young_post_treated) addtext(Year FE, Yes, Controls, Yes)
reg employed age i.sex i.educd i.raced i.year treated treated_post young_treated young_post young_post_treated [pweight=perwt], robust
outreg2 using employment_results.doc, append ctitle(With FE) keep(treated treated_post young young_post young_treated young_post_treated) addtext(Year FE, Yes, Controls, Yes)

// Income long regression with DDD
reg lnhrlywge age i.sex i.educd i.raced i.year treated treated_post young_treated young_post young_post_treated, robust
outreg2 using lnwage_results_np.doc, append ctitle(With FE) keep(treated treated_post young young_post young_treated young_post_treated) addtext(Year FE, Yes, Controls, Yes)
reg lnhrlywge age i.sex i.educd i.raced i.statefip i.year treated_post young_treated young_post young_post_treated [pweight=perwt], robust
outreg2 using lnwage_results.doc, append ctitle(With FE) keep(treated treated_post young young_post young_treated young_post_treated) addtext(Year FE, Yes, Controls, Yes)

capture log close
