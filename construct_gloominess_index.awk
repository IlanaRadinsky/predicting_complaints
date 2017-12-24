#! /usr/bin/gawk -f
#
# construct different "gloominess indices" to measure if a day is a gloomy day
# gloomy_today -> overcast for 10 or more hours today
# gloomy_past_two_days -> overcast for 10 or more hours today and yesterday
# gloomy_past_three_days -> overcast for 10 or more hours today, yesterday, and the day before
#
# usage: gawk -f construct_gloominess_index.awk
#
# dependencies:
# weather_features.csv
#

BEGIN{
    
    FS=","
    OFS=","
    HOURS_OVERCAST = 5
    
    two_days_ago = 0 # two days ago
    yesterday = 0 # yesterday

    while( (getline < "weather_features.csv") > 0 ) {
	if ($HOURS_OVERCAST ~ /[0-9]+/) {
	    gloomy_today = 0
	    gloomy_past_two_days = 0
	    gloomy_past_three_days = 0

	    # compute gloominess indices
	    gloomy_today = ($5 >= 10)
	    gloomy_past_two_days = gloomy_today && yesterday
	    gloomy_past_three_days = gloomy_today && yesterday && two_days_ago

	    # print append gloominess indices to the end of the line
	    # and print to stdout
	    print $0, gloomy_today, gloomy_past_two_days, gloomy_past_three_days

	    # update variables for gloominess yesterday and two days ago
	    two_days_ago = yesterday
	    yesterday = gloomy_today
	    
	}
    }

    if(close("weather_features.csv")) print "Error closing file: weather_features.csv" > "/dev/stderr"
}
