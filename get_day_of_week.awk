#! /usr/bin/gawk -f

{
    FS = ","
    date = $1
    if (date ~ /[0-9]+/) {
	gsub(/\-/, " ", date)
	time = mktime(date " 00 00 00")
	print $1 "," strftime("%a", time)
    }
}
