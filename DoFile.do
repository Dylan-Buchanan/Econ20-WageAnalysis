clear all
set more off
cap log close

// Get the current user's username
local user = c(username)

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
    cd "C:/Projects/SharedFolder"
}
else {
    display as error "User not recognized. Please update the do-file with your path."
}

// Open Data Sets Below

use usa_00001.dta, clear
browse

// Table Champion's champion code


capture log close

