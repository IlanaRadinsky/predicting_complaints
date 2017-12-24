#! /usr/bin/gawk -f
#
# Count the number of noise complaints and non-noise complaints per day.
#
# usage: gawk -f count_noise_complaints_by_date.awk
#
# dependencies:
# 311_Service_Requests.csv.gz
#

BEGIN {

    FS = ","
    OFS = ","

    file = "311_Service_Requests.csv.gz"
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

    # for each date,
    for (d in complaints) {
	if (d ~ /[0-9]+/) {
	    noise_complaints = 0
	    total = complaints[d]["total"]

	    # add up the number of complaints for each complaint type
	    # that contains the word "NOISE"
	    for (c in complaints[d])
		if (c ~ /NOISE/) noise_complaints += complaints[d][c]

	    # print totals to stdout
	    other_complaints = total - noise_complaints
	    print d, noise_complaints, other_complaints, total
	}
    }

    if (close(cmd)) print "Error closing command " cmd > "/dev/stderr"

}
