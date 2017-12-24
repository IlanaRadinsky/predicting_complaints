#! /usr/bin/gawk -f
#
# extract day of week for each date in input file.
#
# usage: gawk -f get_date_of_week.awk
#
# dependencies:
# noise_complaints_by_date.csv

{
    FS = ","
    dmy = $1
    if (dmy ~ /[0-9]+/) {
	# put date in format YYYY MM DD
	gsub(/\-/, " ", dmy)

	# create a day-time object for that date
	date = mktime(dmy " 00 00 00")

	# print day of week for that date to stdout
	print $1 "," strftime("%a", date)
    }
}
