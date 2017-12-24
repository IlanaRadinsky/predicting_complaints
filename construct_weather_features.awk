#! /usr/bin/gawk -f
#
# Construct environmental features that will be used to predict subjective complaints 
#
# usage: gawk -f construct_features.awk
#
# dependencies:
# weather_data.csv
#
# notes:
#
# Weather:
# FG = fog
# TS = thunder
# PL = ice pellets, sleet, snow pellets or small hail
# GR = hail
# GL = glaze or rime
# DU = dust, volcanic ash, blowing dust, blowing sand, or blowing obstruction
# HZ = smoke or haze
# BLSN = blowing or drifting snow
# FC = tornado, water spout, or funnel cloud
# WIND = high or damaging winds
# BLPY = blowing spray
# BR = mist
# DZ = drizzle
# FZDZ = freezing drizzle
# RA = rain
# FZRA = freezing rain
# SN = snow, snow pellets, snow grains, or ice crystals
# UP = unknown precipitation
# MIFG = ground fog
# FZFG = ice fog or freezing fog
#
# Conclusion: Any weather is bad weather
#
# Sky Conditions:
# CLR = clear sky
# FEW = few clouds
# SCT = scattered clouds
# BKN = broken clouds
# OVC = overcast
# VV = obscured sky
# 10 = partially obscured sky

# round.awk --- do normal rounding
# https://www.gnu.org/software/gawk/manual/html_node/Round-Function.html
function round(x,   ival, aval, fraction)
{
    ival = int(x)    # integer part, int() truncates

    # see if fractional part
    if (ival == x)   # no fraction
	return ival   # ensure no decimals

    if (x < 0) {
	aval = -x     # absolute value
        ival = int(aval)
	fraction = aval - ival
	if (fraction >= .5)
	    return int(x) - 1   # -2.5 --> -3
	else
	    return int(x)       # -2.3 --> -2
    } else {
	fraction = x - ival
        if (fraction >= .5)
	    return ival + 1
	else
	    return ival
    }
}

BEGIN {

    FS = ","
    OFS = ","
    file = "weather_data.csv"
    DATE = 6
    HOURLYSkyConditions = 8
    DAILYMaxTemp = 27
    DAILYMinTemp = 28
    DAILYAvgTemp = 29
    DAILYSunrise = 36
    DAILYSunset = 37
    DAILYWeather = 38

     while ( (getline < file) > 0 ) {
	 if ($DATE ~ /[0-9]+/) {
	 # extract dmy from date-time
	 match($DATE, /([0-9]{4}-[0-9]{2}-[0-9]{2})/, dmy)
	 date = dmy[1]

	 # extract average temperature
	 if ($DAILYAvgTemp && ! weather[date]["avg_temp"] ) 
	     weather[date]["avg_temp"] = $DAILYAvgTemp

	 # calculate daylight hours
	 # date must be in format YYYY MM DD HH MM S
	 newDate = date
	 gsub(/-/, " ", newDate)
	 sunset = mktime(newDate " " substr($DAILYSunset,1,2) " " substr($DAILYSunset,3,2) " 0")
	 sunrise = mktime(newDate " " substr($DAILYSunrise,1,2) " " substr($DAILYSunrise,3,2) " 0")
	 daylight_hours = round((sunset-sunrise)/(60*60))

	 if ( ! weather[date]["daylight_hours"] ) 
	     weather[date]["daylight_hours"] = daylight_hours

	 # add whether or not there was bad weather that day
	 if ($DAILYWeather && ! weather[date]["bad_weather"] ) 
	     weather[date]["bad_weather"] = 1

	 match($DATE, /([0-9]{2}):[0-9]{2}/, time)
	 hour = time[1]

	 # count the number of hours it was overcast
	 if ($HOURLYSkyConditions ~ /(OVC|VV|10)/)
	     weather[date]["hours_overcast"][hour] = 1
	 }
     }

     for (d in weather) {
	 # if "bad_weather" hadn't been initialized, initialize it
	 weather[d]["bad_weather"]

	 # count up the number of hours overcast
	 weather[d]["hours_overcast"]["total"] = 0
	 for (h in weather[d]["hours_overcast"]) {
	     if (! (h ~ "total")) weather[d]["hours_overcast"]["total"]++
	 }

	 # print weather features to stdout
	 print d, weather[d]["avg_temp"], weather[d]["daylight_hours"], weather[d]["bad_weather"], weather[d]["hours_overcast"]["total"]
     }

    if ( close(file) > 0 ) print "Error closing file: " file > "/dev/stderr"
}
