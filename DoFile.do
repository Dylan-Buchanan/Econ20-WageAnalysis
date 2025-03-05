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

use usa_00001, clear

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
drop hrswork1
drop if empstat == 0

tab statefip, gen(state_dummy)


gen treated = (statefip == 8)
gen female = (sex==2)
tab raced, gen(race_dummy)
tab educd, gen(educ_dummy)
tab empstat, gen(emp_dummy)
gen lnwage = ln(incwage)
gen post = (year >= 2007)
gen treated_post = treated * post

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
        foreach variable of varlist emp_dummy* age perwt sex educ_dummy* incwage race_dummy* {
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
twoway (connected employment_rate year if statefip == 8) (connected employment_rate year if statefip == 49), xline(2007, lpattern(dash) lcolor(red)) xlabel(2003(1)2010) ylabel(0.65(0.05)0.8) ytitle("Employment Rate") xtitle("Year") title("Employment Trends in Colorado (Treatment) vs Utah (Control)") subtitle("Vertical line indicates policy change in 2007") legend(order(1 "Colorado (Treatment)" 2 "Utah (Control)"))
graph export "employment_trends.png", replace
restore

// for lnwage
preserve
collapse (mean) mean_lnwage=lnwage [pweight=perwt], by(statefip year)
keep if statefip == 8 | statefip == 49
gen state_name = "Colorado" if statefip == 8
replace state_name = "Utah" if statefip == 49
twoway (connected mean_lnwage year if statefip == 8) (connected mean_lnwage year if statefip == 49), xline(2007, lpattern(dash) lcolor(red)) xlabel(2003(1)2010) ytitle("Average Log Wage") xtitle("Year") title("Log Wage Trends in Colorado (Treatment) vs Utah (Control)") subtitle("Vertical line indicates policy change in 2007") legend(order(1 "Colorado (Treatment)" 2 "Utah (Control)"))
graph export "log_wage_trends.png", replace
restore

// Basic DiD regression
reg employed treated post treated_post, robust
outreg2 using employment_results_np.doc, replace ctitle(Basic DiD) keep(treated post treated_post) addtext(State FE, No, Year FE, No) title(Effect of Colorado Policy Change on Employment (No Perwt))
reg employed treated post treated_post [pweight=perwt], robust
outreg2 using employment_results.doc, replace ctitle(Basic DiD) keep(treated post treated_post) addtext(State FE, No, Year FE, No) title(Effect of Colorado Policy Change on Employment)

// DiD with state and year fixed effects
reg employed treated_post age i.sex i.educd i.raced i.statefip i.year, robust
outreg2 using employment_results_np.doc, append ctitle(With FE) keep(treated_post) addtext(State FE, Yes, Year FE, Yes, Controls, Yes)
reg employed treated_post age i.sex i.educd i.raced i.statefip i.year [pweight=perwt], robust
outreg2 using employment_results.doc, append ctitle(With FE) keep(treated_post) addtext(State FE, Yes, Year FE, Yes, Controls, Yes)

gen young = (age <= 25)
gen young_treated = young * treated
gen young_post = young * post
gen young_post_treated = young * post * treated

reg employed treated_post age i.sex i.educd i.raced i.statefip i.year lnwage young young_treated young_post young_post_treated, robust
outreg2 using employment_results_np.doc, append ctitle(With FE) keep(treated_post young young_post young_treated young_post_treated) addtext(State FE, Yes, Year FE, Yes, Controls, Yes)
reg employed treated_post age i.sex i.educd i.raced i.statefip i.year lnwage young young_treated young_post young_post_treated [pweight=perwt], robust
outreg2 using employment_results.doc, append ctitle(With FE) keep(treated_post young young_post young_treated young_post_treated) addtext(State FE, Yes, Year FE, Yes, Controls, Yes)

areg employed treated_post age i.sex i.educd i.raced lnwage young young_treated young_post young_post_treated, absorb(year) robust
outreg2 using employment_results_np.doc, append ctitle(Absorb Year) keep(treated_post young young_post young_treated young_post_treated) addtext(State FE, Yes, Year FE, Yes, Controls, Yes)
areg employed treated_post age i.sex i.educd i.raced lnwage young young_treated young_post young_post_treated [pweight=perwt], absorb(year) robust
outreg2 using employment_results.doc, append ctitle(Absorb Year) keep(treated_post young young_post young_treated young_post_treated) addtext(State FE, Yes, Year FE, Yes, Controls, Yes)
test treated_post young_treated young_post young_post_treated

capture log close
