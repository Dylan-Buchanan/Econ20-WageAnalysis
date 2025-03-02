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
browse



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

drop if perwt >= 400

tab statefip, gen(state_dummy)


gen female = (sex==2)
tab raced, gen(race_dummy)
tab educd, gen(educ_dummy)
tab empstat, gen(emp_dummy)
gen lnwage = ln(incwage)
gen post_wage_increase = (year >= 2007)

sum emp_dummy* if year < 2007 & statefip == 8
sum emp_dummy* if year >= 2007 & statefip == 8
sum emp_dummy* if year < 2007 & statefip == 49
sum emp_dummy* if year >= 2007 & statefip == 49

sum age if year < 2007 & statefip == 8
sum age if year >= 2007 & statefip == 8
sum age if year < 2007 & statefip == 49
sum age if year >= 2007 & statefip == 49

sum perwt if year < 2007 & statefip == 8
sum perwt if year >= 2007 & statefip == 8
sum perwt if year < 2007 & statefip == 49
sum perwt if year >= 2007 & statefip == 49

sum sex if year < 2007 & statefip == 8
sum sex if year >= 2007 & statefip == 8
sum sex if year < 2007 & statefip == 49
sum sex if year >= 2007 & statefip == 49

sum educ_dummy* if year < 2007 & statefip == 8
sum educ_dummy* if year >= 2007 & statefip == 8
sum educ_dummy* if year < 2007 & statefip == 49
sum educ_dummy* if year >= 2007 & statefip == 49

sum incwage if year < 2007 & statefip == 8
sum incwage if year >= 2007 & statefip == 8
sum incwage if year < 2007 & statefip == 49
sum incwage if year >= 2007 & statefip == 49

sum race_dummy* if year < 2007 & statefip == 8
sum race_dummy* if year >= 2007 & statefip == 8
sum race_dummy* if year < 2007 & statefip == 49
sum race_dummy* if year >= 2007 & statefip == 49

capture log close
