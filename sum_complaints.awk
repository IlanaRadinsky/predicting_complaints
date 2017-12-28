#! /usr/bin/gawk -f

BEGIN {
    noise = 0
    other = 0
    total = 0
    FS = ","

    while( (getline < "noise_complaints_by_date.csv") > 0) {
	noise += $2
	other += $3
	total += $4
    }

    print noise/total, noise/(noise+other)
}
