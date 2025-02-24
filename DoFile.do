clear all
set more off
cap log close

// Get the current user's username
local os = c(os)
local user = c(username)

display `user'

// Set the working directory based on the username
if "`user'" == "Dylan" {
    cd "C:\Users\dylan\Desktop\Dartmouth\ECON 20\Group Project"
}
else if "`user'" == "user2" {
    cd "D:/Research/DataFolder"
}
else if "`user'" == "user3" {
    cd "E:/Work/Project"
}
else if "`user'" == "user4" {
    cd "C:/Projects/SharedFolder"
}
else {
    display as error "User not recognized. Please update the do-file with your path."
}

// Open Data Sets Below


// Table Champion's champion code


capture log close
