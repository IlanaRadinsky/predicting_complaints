#! /usr/bin/gawk -f
BEGIN{
    
    FS=","
    OFS=","
    two_days_ago = 0 # two days ago
    yesterday = 0 # yesterday

    while( (getline < "features.csv") > 0 ) {
	if ($5 ~ /[0-9]+/) {
	    gloomy_today = 0
	    gloomy_past_two_days = 0
	    gloomy_past_three_days = 0
	    
	    # a day is considered "gloomy" if it has been overcast
	    # for 10 or more hours for the past 3 days (the current
	    # day and the previous 2 days)
	    gloomy_today = ($5 >= 10)
	    gloomy_past_two_days = gloomy_today && yesterday
	    gloomy_past_three_days = gloomy_today && yesterday && two_days_ago

	    print $0, gloomy_today, gloomy_past_two_days, gloomy_past_three_days

	    two_days_ago = yesterday
	    yesterday = gloomy_today
	    
	}
    }
}
