#! /usr/bin/gawk -f
#
# Count the number of complaints per day, total and by complaint type.
#
# usage: ./perc_noise_by_date.awk
#
# dependencies:
# 311_Service_Requests.csv.gz
#

BEGIN {

    FS = ","
    OFS = ","

    file = "/home/iradinsky/project/311_Service_Requests.csv.gz"
    cmd = "zcat " file

    CREATED_DATE = 2
    COMPLAINT_TYPE = 6

    while ( (cmd|getline) > 0){

	# extract date from date-time
	match($CREATED_DATE, /([0-9]{2})\/([0-9]{2})\/([0-9]{4})/, mdy)

	# convert date from MM/DD/YYYY to YYYY-MM-DD to match weather_data.csv
	date = mdy[3] "-" mdy[1] "-" mdy[2]

	complaints[date][toupper($COMPLAINT_TYPE)]++
	complaints[date]["total"]++
    }

    for (d in complaints) {
	if (d ~ /[0-9]+/) {
	    noise_complaints = 0
	    total = complaints[d]["total"]
	    
	    for (c in complaints[d])
		if (c ~ /NOISE/) noise_complaints += complaints[d][c]
	}

	perc_complaints = noise_complaints/total
	print d, perc_complaints
    }

    if (close(cmd)) print "Error closing command " cmd > "/dev/stderr"

}
